global with sharing class AW_ImportCSV_Batch implements Database.batchable<List<string>>, Database.Stateful
{
   private String csvData; 
   private static final Integer SCOPE_SIZE = 100;
   private AW_CSVReader csvReader;
   public static Advance_Workflow__c advWorkflow; 
   private String refimpRule;
   private String aweId;
   private String objectName;
   private Set<String> successRuleNames;
   private Map<String, String> failureRuleNamesWithReason;
   public AW_ImportCSV_Batch(String csvData , String refimpRule , String objectName,String aweId){
   	this.csvData = csvData;
   	this.refimpRule = refimpRule;
   	this.objectName = objectName; 
   	this.successRuleNames = new Set<String>();
   	this.failureRuleNamesWithReason = new Map<String , String>();
   	this.aweId = aweId;
   } 
   global List<List<string>> start(Database.batchableContext batchableContext)
   { 
   	  csvReader = new AW_CSVReader(csvData, false);
   	  List<List<String>> csvRows = new List<List<String>>();
   	  String[]  csvInCols = csvReader.readLine(); 
   	  while(csvInCols != null && csvInCols.size() > 0){
   	  	if(csvInCols != null){
   	  		csvRows.add(csvInCols);
   	  	}
   	  	csvInCols = csvReader.readLine();
   	  }
      return csvRows; 
   }
   global void execute(Database.BatchableContext batchableContext, List<List<string>> scope)  
   { 
       String csvFile = '';
       try{
       	AW_ParseCSVTo_AdvanceWorkflow_Util.prepareWorkflowWrapperMapBulk(scope , refimpRule , objectName);
       	for(String rName : AW_ParseCSVTo_AdvanceWorkflow_Util.ruleNames){
       		if(AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.containsKey(rName.trim())){
                failureRuleNamesWithReason.put(rName.trim() , AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.get(rName.trim()).Error_Description__c);
            }else{
                if(AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.containsKey(objectName)){
                         failureRuleNamesWithReason.put(rName.trim() , AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.get(objectName).Error_Description__c);    
                }
                else{   
                        successRuleNames.add(rName);
                } 
            }
       	}
       }catch(Exception ex){
	       	Error_Log__c errorLog = new Error_Log__c(Error_Description__c = ex.getMessage(), import_code__c = refimpRule , ErrorSource__c = 'csvFormat');
			insert errorLog;
			for(String rName : AW_ParseCSVTo_AdvanceWorkflow_Util.ruleNames){
	       		failureRuleNamesWithReason.put(rName.trim() , ex.getMessage());
	       	}
			System.debug('::errorLog'+errorLog);
       }finally{
       		System.debug('::ruleErrorMap'+AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap);
       		System.debug('::AW_ParseCSVTo_AdvanceWorkflow_Util.ruleNames'+AW_ParseCSVTo_AdvanceWorkflow_Util.ruleNames);
       		for(String rKey : AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.keySet()){
       			String errorMsg =  AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.get(rKey).Error_Description__c;
       			if(AW_ParseCSVTo_AdvanceWorkflow_Util.ruleNames.contains(rKey) || errorMsg.contains('Rule Object is different')){
       				failureRuleNamesWithReason.put(rKey.trim() , AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.get(rKey).Error_Description__c);
       			}
       		}
       		System.debug('::failureRuleNamesWithReason'+failureRuleNamesWithReason);
       		
       }
   }
   global void finish(Database.BatchableContext batchableContext){
   		List<Attachment> attachments = new List<Attachment>();
   		
	   	if(!successRuleNames.isEmpty()){
	   		String csvBody = '"Rule Name"\n';
	   		for(String rName : successRuleNames){
	   			csvBody += '"' + rName + '"\n';
	   		}
	   		Attachment successFile     =   new Attachment();
            successFile.Name           =   objectName +'-Success'+'-'+datetime.now() + '.csv';
            successFile.Body           =   Blob.valueOf(csvBody);
            successFile.ParentId       =   aweId;
            attachments.add(successFile);
	   	}
	   	if(!failureRuleNamesWithReason.isEmpty()){
	   		String csvBody = '"Rule Name","Error Message"\n';
	   		for(String rName : failureRuleNamesWithReason.keySet()){
	   			csvBody += '"' + rName + '"," ' + failureRuleNamesWithReason.get(rName) +'"\n';
	   		}
	   		Attachment failureFile     =   new Attachment();
            failureFile.Name           =   objectName +'-Error'+'-'+datetime.now() + '.csv';
            failureFile.Body           =   Blob.valueOf(csvBody);
            failureFile.ParentId       =   aweId;
            attachments.add(failureFile);
	   	}
	   	if(!attachments.isEmpty()){
	   		insert attachments;
	   	}
   }
}
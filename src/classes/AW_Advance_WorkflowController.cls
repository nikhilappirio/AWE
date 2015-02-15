// 
// (c) 2012 Appirio, Inc.
//
//  AW_Advance_WorkflowController                                                     
//
// This class is used to define Execution Plan 
//
// 18 Nov 2012     Peter Babalis     Original
// 01 May 2014     Peter Babalis     Added Create Field for AweTracking
  
//  
public with sharing class AW_Advance_WorkflowController {
     
    public Advance_Workflow__c newruleexecutionplan {get;set;} 
    public String obj {get;set;}
    public List<SelectOption> objOptions {get;set;}
    public boolean edit {get;set;}
    public boolean ruleAssigned {get;set;}
    public String AWFId;
    
    public List<MetadataService.AsyncResult> AsyncResults {get;set;}
    /**
    * Constructor
    */    
    public AW_Advance_WorkflowController(Apexpages.StandardController stdcon){
        String ruleexecutionplanId;
        ruleexecutionplanId = stdcon.getId();
        AWFId=ruleexecutionplanId;
        newruleexecutionplan = new Advance_Workflow__c();
        objOptions = new List<SelectOption>();
        edit=false;
        ruleAssigned = false;
         
        Map<String, Schema.SObjectType> mapObj = Schema.getGlobalDescribe();
        for(String objname:mapObj.keySet()){
            Schema.SObjectType sobj = mapObj.get(objname);
            Schema.DescribeSObjectResult descRes = sobj.getDescribe();
            if(!descRes.isCustomSetting() && descRes.isAccessible() && (descRes.isCreateable() || descRes.isUpdateable())){
             //if(!descRes.isCustomSetting() && descRes.isCustom()){
                String objLabel = descRes.getLabel();
                objOptions.add(new SelectOption(descRes.getName(),objLabel + ' (' + descRes.getName() + ')'));
            }
        }
      /*
        for(SelectOption op: objOptions){        	
                system.debug('---------> List of Objects' + op);
        }
      */
      //  objOptions.sort();
          sortSelectListOnLabel(objOptions);
        if(ruleexecutionplanId != null){
            edit = true;
            newruleexecutionplan = [SELECT name,object__c,
            							   Description__c ,
            							   Enabled__c,
            							   Advance_Rule_Stamp__c,
            							   Enable_Execution_History__c,
            							   CountRulesassociatedtoAdvanceWorkflow__c 
            					   FROM Advance_Workflow__c 
            					   WHERE id =: ruleexecutionplanId];
            if(newruleexecutionplan != null){
                obj = newruleexecutionplan.object__c;
                ruleAssigned = (newruleexecutionplan.CountRulesassociatedtoAdvanceWorkflow__c == null || newruleexecutionplan.CountRulesassociatedtoAdvanceWorkflow__c > 0) ?true:false;
            }
        }
    }
 /**
     * Sort on the basis of Label
     */
    private void sortSelectListOnLabel(List<SelectOption> options){
        Map<String,List<SelectOption>> mapping = new Map<String,List<SelectOption>>();
        for(Selectoption opt : options) {
            List<SelectOption> optList = new List<SelectOption>();
            if(mapping.containsKey(opt.getLabel())){
                optList = mapping.get(opt.getLabel());
            }
            else{
                mapping.put(opt.getLabel(),optList);
            }
            optList.add(opt);
        }
        List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        options.clear();
        for (String key : sortKeys) {
            options.addAll(mapping.get(key));
        }
    }          
  
   public PageReference returnPage()
   {
      
     return new PageReference('/apex/AW_ImportExport_VF?id='+AWFId);
   } 
   
    /**
    * Save and New Action
    */
    public PageReference saveAndNewRule(){
        newruleexecutionplan.object__c = obj;
        edit = false;
        try{
        	if(newruleexecutionplan.Advance_Rule_Stamp__c)deployFields();
            upsert newruleexecutionplan;
            
            newruleexecutionplan = new Advance_Workflow__c();
            return (new PageReference('/apex/AW_Advance_Workflow_VF'));
        }catch(Exception e){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0));
            ApexPages.addMessage(msg);
            return null;
        }
        
    }
		
  	/**
  	* Save Action
  	*/
	public PageReference saveRule(){
        newruleexecutionplan.object__c = obj;
        try{
            if(newruleexecutionplan.Advance_Rule_Stamp__c)deployFields();
            upsert newruleexecutionplan;
            
            return (new PageReference('/'+newruleexecutionplan.id));
        }catch(Exception e){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0));
            ApexPages.addMessage(msg);
            return null;
        }        
    }
    
    /**
      @Sneha 
      DT:- 22/4/14
      Method that uses metadata api to create two custom fields 
      in the object associated with the advance workflow
    */
    private void deployFields(){
    	Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(newruleexecutionplan.object__c).getDescribe().fields.getMap();
    	
    	if(objectFields.get('AWE_Rule__c')!=null && objectFields.get('AWE_RuleURL__c')!=null){
    		//do nothing
    		return;
    	}
    	
    	String sobj =  newruleexecutionplan.object__c.tolowerCase()=='task'?'Activity':newruleexecutionplan.object__c;
    	
    	MetadataService.MetadataPort service = createService();
    	// Define Metadata item to create a Custom Field on the above object
	    MetadataService.CustomField customField1 = new MetadataService.CustomField();
	   // customField1.fullName = newruleexecutionplan.object__c+'.AWE_Rule__c';
	     customField1.fullName = sobj+'.AWE_Rule__c';
	     customField1.label = 'AWE Rule';
	     customField1.type_x = 'Text';
	     customField1.length=255;
//		customField1.trackHistory=true;
	    // Define Metadata item to create a Custom Field on the above object
	    MetadataService.CustomField customField2 = new MetadataService.CustomField();
	   // customField2.fullName = newruleexecutionplan.object__c+'.AWE_RuleURL__c';
	     customField2.fullName = sobj+'.AWE_RuleURL__c';
	     customField2.label = 'AWE Rule';
	     customField2.type_x = 'Text';	    	   
	   // customField2.formula='HYPERLINK(SUBSTITUTE(AWE_Rule__c, AWE_Rule__c,LEFT(AWE_Rule__c, FIND(\'~\',AWE_Rule__c)-1)), SUBSTITUTE(AWE_Rule__c, AWE_Rule__c,RIGHT(AWE_Rule__c,FIND(\'~\', AWE_Rule__c)-1)))';
        customField2.formula='HYPERLINK(SUBSTITUTE(AWE_Rule__c, AWE_Rule__c,LEFT(AWE_Rule__c, FIND(\'~\', AWE_Rule__c)-1)), SUBSTITUTE(AWE_Rule__c, LEFT(AWE_Rule__c, FIND(\'~\',AWE_Rule__c)) , \'\')  )';
	        // customField2.formula='HYPERLINK(\'/apex/AW_RecordRuleExecutionHistory_VF?recordId=\' & Id, SUBSTITUTE(AWE_Rule__c, LEFT(AWE_Rule__c, FIND(\'~\',AWE_Rule__c)), \'\') )';
      
          AsyncResults = service.create(new List<MetadataService.Metadata> { customField1,customField2 });
    	
    }
    
    
    
    private MetadataService.MetadataPort createService()
	{ 
	    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
	    service.SessionHeader = new MetadataService.SessionHeader_element();
	    service.SessionHeader.sessionId = UserInfo.getSessionId();
	    return service;     
	}    
    
}
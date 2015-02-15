//
// (c) 2012 Appirio, Inc.
// AW_ImportExport_Controller                                                     
// This class is used to parse Advance Workflow in XML format
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2012     Peter Babalis     Added Status and Version  for Rules
// 29 Mar 2013     Peter Babalis     Determines Import/Export Action and replaces the special character
//  
//
public with sharing class AW_ImportExport_Controller {

public  Boolean     chkImport   {get;set;}
    public  String      AWFId       {get;set;}
    public  String      option      {get;set;}
    public  String      ruleOpt     {get;set;}
    public String       fileFormat    {get;set;} //Appirio JDC 
    public  Boolean     initOption  {get;set;}
    public  Blob        xmlFile     {get;set;}
    public String objectName {get;set;}
    private String  refRule;
    public Boolean isBulkMode{get;set;}
   public AW_ImportExport_Controller(){
        this.chkImport  =   false;
        this.option     =   '';
        this.ruleOpt    =   '';
        this.initOption =   false;
        this.xmlFile    =   null;
        this.AWFId      =   ApexPages.currentPage().getParameters().get('id');
        this.objectName  =  ApexPages.currentPage().getParameters().get('Obj');
        this.isBulkMode = true; 
    }
    
    public AW_ImportExport_Controller(ApexPages.standardController stdController){
        this.chkImport  =   false;
        this.option     =   '';
        this.ruleOpt    =   '';
        this.initOption =   false;
        this.xmlFile    =   null;
        this.AWFId      =   stdController.getId();
        this.isBulkMode = true;
   }
    public  Pagereference   checkAction(){
        initOption  =   true;
        chkImport   =   (option == '0')?true:false;
        return null;
    }   
    
    
    public  Pagereference cancel(){
        PageReference currPage  =   ApexPages.currentPage();
        String  returnURL;
        if( AWFId != null){
            returnURL = currPage.getURL().substringBefore('apex') + AWFId;
        }else{
            Schema.SobjectType sobjType = Schema.getGlobalDescribe().get('Advance_Workflow__c');
            if(sobjType != null){
                returnURL = currPage.getURL().substringBefore('apex') + sobjType.getDescribe().getkeyPrefix();
            }else{
                returnURL = currPage.getURL().substringBefore('apex') + 'home/home.jsp';
            }
        }
        return new Pagereference(returnURL);
    }
    public  Pagereference   start(){
        if(AWFId == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please select valid Advance Workflow rule before start'));
            return null;
        }
        if(fileFormat == null || fileFormat == ''){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please  select a file type'));
            return null;
        }
        //if(fileFormat == 'XML'){
            if(option == '0')
                return importProcess();
            else
                return exportProcess();
        /*}else if(fileFormat == 'CSV'){
            if(option == '0'){
                
            }
        }*/
    }   
    public  List<SelectOption> getRadioOptions() {
        transient   List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('0','Import')); 
        options.add(new SelectOption('1','Export')); 
        return options; 
    }   
    
    public List<SelectOption> getFileFormatOptions(){
        transient   List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption('CSV','CSV')); 
            options.add(new SelectOption('XML','XML')); 
        return options; 
    }
    public  List<SelectOption> getRuleOptions() {
        transient   List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('0','--None--')); 
        options.add(new SelectOption('1','Draft')); 
        options.add(new SelectOption('2','Active'));
        options.add(new SelectOption('3','Draft & Active'));
        return options; 
    }   
    
        public static String charsToescapechars(String str){
          if(str!=null){    
            if(str.contains('&amp;')){
              
                str = str.replace('&amp;', '&');
                }
             if(str.contains('&euro;')){
                str = str.replace('&euro;', '€');
             }
             if(str.contains('&lt;')){
                    str = str.replace('&lt;', '<');
             }
             if(str.contains('&gt;')){
                    str = str.replace('&gt;', '>');
             }
          }       
            return str; 
        }
        
        public static String escapecharsTochars(String str){
        
        if(str!=null){       
            if(str.contains('&')){
                str = str.replace('&', '&amp;');
                }
            if(str.contains('€')){
                str = str.replace('€', '&euro;');
            }
            if(str.contains('<')){
                str = str.replace('<', '&lt;');
            }
            if(str.contains('>')){
                str = str.replace('>', '&gt;');
            }
        }
        return str;
    } 
     
    
    public Pagereference importProcess(){
    	 Pagereference pageRef;
        if(xmlFile == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please, select a '+ fileFormat + ' File.'));
            xmlFile =   null;
            return null;
        }
       
        // Start Bug Fix : Import Rule from CSV -Kirti Sahni (August 27 2014)
        system.debug('--->importProcess '+ AW_ImportExportHelper.blobToString(xmlFile , 'ISO 8859-2'));
        //End Bug Fix : Import Rule from CSV -Kirti Sahni (August 27)
        refRule =   String.valueOf( Datetime.now() + Crypto.getRandomInteger());
       
         try{
             if(fileFormat == 'XML'){
                AW_ParseXMLTo_AdvanceWorkflow_Util.parser(xmlFile.toString(), refRule, AWFId);
                xmlFile = null;
             }else if(fileFormat == 'CSV'){
                if(objectName == null){
                    List<Advance_Workflow__c>   currentAWF  =   [Select Object__c, Name, Enabled__c, Description__c From Advance_Workflow__c where Id =: AWFId];
                    if(currentAWF.size() > 0 && currentAWF.get(0).Object__c != null){
                        objectName = currentAWF.get(0).Object__c;
                    }
                } 
                String csvFile = AW_ImportExportHelper.blobToString(xmlFile , 'ISO 8859-2');
                
                //AW_ParseCSVTo_AdvanceWorkflow_Util.importAWECSV(csvFile, refRule, objectName);  
                if(isBulkMode){
	                Advance_Workflow_Limits__c advWorkflowLimit = Advance_Workflow_Limits__c.getInstance('importCSVRecSize');
	                Integer batch_size = advWorkflowLimit != null && advWorkflowLimit.value__c != null ? Integer.valueOf(advWorkflowLimit.value__c) : 10;
	                AW_ImportCSV_Batch csvBatch = new AW_ImportCSV_Batch(csvFile, refRule, objectName,AWFId);
					Id JobId = Database.executeBatch(csvBatch , batch_size);
					pageRef = Page.AW_ImportCSVJobProcessing;
					pageRef.getParameters().put('id', AWFId);
					pageRef.getParameters().put('refRule', refRule);
					pageRef.getParameters().put('jobId', jobId);
					return  pageRef;//new Pagereference('/apex/AW_ImportCSVJobProcessing?id='+ AWFId +'&refRule='+refRule +'&jobId='+JobId) ;
                }else{
                	AW_ParseCSVTo_AdvanceWorkflow_Util.importAWECSV(csvFile, refRule, objectName); 
                }
             }
         }catch(Exception ex){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,ex.getMessage()));
             xmlFile =   null;
            return null;
         } 
        pageRef = Page.AW_AdvanceWorkflowImportResult_VF;
		pageRef.getParameters().put('id', AWFId);
		pageRef.getParameters().put('refRule', refRule);
		return pageRef; //new Pagereference('/apex/AW_AdvanceWorkflowImportResult_VF?id=' + AWFId + '&refRule=' + refRule);        
    }
    public Pagereference   exportProcess(){
    	PageReference pageRef;
        transient   Boolean     success =   false;
        //String          
        if(ruleOpt == '0'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please, select an export option.'));
            xmlFile =   null;
            return null;
        }        
        List<Advance_Workflow__c>   currentAWF  =   [Select Object__c, Name, Enabled__c, Description__c From Advance_Workflow__c where Id =: AWFId];
        if(currentAWF.size() > 0 && currentAWF != null && !currentAWF.isEmpty()){   
            success =   true;   
            try{
                List<Rule__c> rules = loadRules(currentAWF.get(0).Object__c);
                List<RuleCriteria__c> ruleCriteriaList = AW_CSVGenerator.loadRuleCriteriaList(rules);
                List<RuleAction__c> ruleActionList = AW_CSVGenerator.loadRuleActionList(rules);
                string body;
            
                if(fileFormat == 'XML'){
                    String  awfHeader   =   '<?xml version="1.0" encoding="ISO-8859-1" ?>'  +   '\n' +
                                            '<DVANCE_WORKFLOW>' + '\n' +
                                                '<DVANCE_WORKFLOW_NAME  name="' + currentAWF[0].Name + '">' + '\n' +
                                                    '<DESCRIPTION>' + currentAWF[0].Description__c + '</DESCRIPTION>' + '\n' +
                                                    '<OBJECT>' + currentAWF[0].Object__c + '</OBJECT>' +    '\n' +
                                                    '<ENABLED>' + currentAWF[0].Enabled__c + '</ENABLED>' +     '\n';
                    String  awfBody     =   createXMLBody(rules , ruleCriteriaList , ruleActionList);
                    String  awfFooter   =       '</DVANCE_WORKFLOW_NAME>' +     '\n' +  
                                            '</DVANCE_WORKFLOW>';   
                    body = awfHeader + awfBody + awfFooter;
                }else if(fileFormat == 'CSV'){
                    
                    AW_CSVGenerator csvGenerator = new AW_CSVGenerator();
                    body =  csvGenerator.exportInCSVForm(rules, ruleCriteriaList, ruleActionList); 
                }
    
                    Attachment fileAttached     =   new Attachment();
                    fileAttached.Name           =   currentAWF[0].Name+'-'+datetime.now() + '.'+fileFormat.toLowerCase();
                    fileAttached.Body           =   Blob.valueOf(body);
                    fileAttached.ParentId       =   currentAWF[0].Id;
                    insert fileAttached;
                    AW_SendEmailUtil.sendEmailwithAttachment(fileAttached);            
                    pageRef = Page.AW_AdvanceWorkflowExportResult_VF;
                    pageRef.getParameters().put('success' , String.valueOf(success)); 
                    pageRef.getParameters().put('id' , AWFId);                                
                    return pageRef;//new Pagereference('/apex/AW_AdvanceWorkflowExportResult_VF?success=' + success + '&id=' + AWFId);  
            }catch(Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
                xmlFile =   null;
                return null;
            }
        }
        else{
        	pageRef = Page.AW_AdvanceWorkflowExportResult_VF;
            pageRef.getParameters().put('success' , String.valueOf(success)); 
            pageRef.getParameters().put('id' , AWFId); 
            return pageRef;//new Pagereference('/apex/AW_AdvanceWorkflowExportResult_VF?success=' + success + '&id=' + AWFId);  
        }
         }
      
    private List<Rule__c> loadRules(String relatedObject){
        String soqlQuery = AW_CSVGenerator.generateQuery('Rule__c' , 'Advance_Workflow__c', new Map<String, String>()); 
        if(ruleOpt == '1'){
            soqlQuery += ' Where Object__c = :relatedObject AND Status__c in ('+ '\'Draft\''+')';
        }else if(ruleOpt == '2'){
            soqlQuery += ' Where advance_workflow__c = : AWFId AND Status__c in ('+ '\'Active\''+')';
        }else if(ruleOpt == '3'){
            soqlQuery += ' Where Object__c = :relatedObject  AND Status__c in ('+ '\'Draft\''+','+'\'Active\'' +')';
        }
        System.debug('::soqlQuery'+soqlQuery);
        return Database.query(soqlQuery);  
    }
    
    
  
     
    private String  createXMLBody(List<Rule__c> rules , List<RuleCriteria__c> criterias, List<RuleAction__c> actions){
        String  body = '';
        map<Id,list<Values_for_Action_Insert_Record__c>>    mapa            =   new map<Id,list<Values_for_Action_Insert_Record__c>> ();
        set<Id>                                             ruleActionID    =   new set<id>();
        Map<String, List<RuleCriteria__c>>                  criteriaMap     =   new Map<String, List<RuleCriteria__c>>();
        Map<String, List<RuleAction__c>>                    actionMap       =   new Map<String, List<RuleAction__c>>();
        Map<String, Map<String, String>>                    referenceFieldMap = new Map<String, Map<String, String>>();
        for(RuleCriteria__c rc : criterias){            
            if(criteriaMap.get(rc.Rule__c) == null){
                List<RuleCriteria__c> listCrit  =   new List<RuleCriteria__c>();                
                criteriaMap.put(rc.Rule__c, listCrit);
            }
            criteriaMap.get(rc.Rule__c).add(rc);            
        }   
        for(RuleAction__c ra : actions){            
            if(actionMap.get(ra.Rule__c) == null){
                List<RuleAction__c> listAct =   new List<RuleAction__c>();              
                actionMap.put(ra.Rule__c, listAct);
            }
            // for Reference 
            if(ra.User_Owner_Id__c != null && ra.User_Owner_Id__c.startsWith(AW_Rule_Constants.USER_KEYPREFIX)){
            	if(!referenceFieldMap.containsKey('User')){
            		referenceFieldMap.put('User' , new Map<String, String>{ra.User_Owner_Id__c => null});
            	}else{
            		referenceFieldMap.get('User').put(ra.User_Owner_Id__c, null);
            	}
            }
            if(ra.User_Owner_Id__c != null && ra.User_Owner_Id__c.startsWith(AW_Rule_Constants.GROUP_KEYPREFIX)){
            	if(!referenceFieldMap.containsKey('Group')){
            		referenceFieldMap.put('Group' , new Map<String, String>{ra.User_Owner_Id__c => null});
            	}else{
            		referenceFieldMap.get('Group').put(ra.User_Owner_Id__c , null);
            	}
            }
            
            mapa.put(ra.id , ra.Values_for_Action_Insert_Record__r);
            actionMap.get(ra.Rule__c).add(ra);
            
        }  
        if(!referenceFieldMap.isEmpty()){
        	referenceFieldMap = AW_ImportExportHelper.loadReferenceIds(referenceFieldMap, 'Id', 'Name');
        }      
        if(rules.size() > 0 && rules != null && !rules.isEmpty()){  
            for(Rule__c r : rules){
                body += '<RULE_NAME name="\'' + r.Name + '">' + '\n';
                body += '<EVALUATION_RULE>' + r.Evaluation_Rule__c + '</EVALUATION_RULE>' + '\n';
                body += '<RULE_STATUS>' + r.Status__c + '</RULE_STATUS>' + '\n';
                body += '<RULE_VERSION>' + r.Version__c + '</RULE_VERSION>' + '\n';
                body += '<RULE_DESCRIPTION>' + escapecharsTochars(r.Description__c) + '</RULE_DESCRIPTION>' + '\n';
                body += '<DISPLAYFILTERLOGIC>' + escapecharsTochars(r.DisplayfilterLogic__c)  + '</DISPLAYFILTERLOGIC>' + '\n';    
            
                body += '<FILTER_LOGIC>' + r.Filter_Logic__c + '</FILTER_LOGIC>' + '\n';    
                             
                Integer iterator = 1;
                if(criteriaMap.get(r.Id) != null){                  
                    body += '<RULE_CRITERIA_SECTION>' + '\n';
                    for(RuleCriteria__c rc : criteriaMap.get(r.Id)){
                        body +=  '<CRITERIA num=' +'"'+ iterator +'"'+ '>' + '\n';
                        body +=  '<CRITERIA_FIELD_NAME>'+rc.field_name__c+'</CRITERIA_FIELD_NAME>' + '\n';
                        body +=  '<CRITERIA_FIELD_API_NAME>'+rc.field_api_name__c+'</CRITERIA_FIELD_API_NAME>' + '\n';
                        body +=  '<CRITERIA_FIELD_TYPE>'+rc.field_type__c+'</CRITERIA_FIELD_TYPE>' + '\n';
                        body +=  '<CROSSFORMULA>'+rc.CrossFormula__c+'</CROSSFORMULA>' + '\n';
                        body +=  '<MATCHING_TYPE>'+rc.Matching_Type__c+'</MATCHING_TYPE>' + '\n';
                        body +=  '<MATCHING_VALUE>'+ rc.Matching_Value__c +'</MATCHING_VALUE>' + '\n';
                        body +=  '<MAXIMUM_VALUE>'+rc.Maximum_Value__c+'</MAXIMUM_VALUE>' + '\n';
                        body +=  '<MINIMUM_VALUE>'+rc.Minimum_Value__c+'</MINIMUM_VALUE>' + '\n';
                        body +=  '<RECORDTYPEID>'+rc.Record_Type_Id__c+'</RECORDTYPEID>' + '\n';
                        body +=  '<RELATED_OBJECT_CRITERIA>'+rc.Related_Object__c+'</RELATED_OBJECT_CRITERIA>' + '\n';
                        body +=  '</CRITERIA>' + '\n';
                        iterator++;                 
                    }                   
                    body +=  '</RULE_CRITERIA_SECTION>' + '\n';
                }
                iterator = 1;
                if(actionMap.get(r.Id) != null){ 
                    body += '<RULE_ACTION_SECTION>' + '\n';
                    for(RuleAction__c ra : actionMap.get(r.Id)){
                        body +=  '<ACTION num=' +'"'+iterator+'"'+ '>' + '\n';
                        if( ra.Related_Object__c !=null )body +=  '<RELATED_OBJECT_ACTION>'+ra.Related_Object__c+'</RELATED_OBJECT_ACTION>' + '\n';
                           else body +=  '<RELATED_OBJECT_ACTION>'+'</RELATED_OBJECT_ACTION>' + '\n';
                        if( ra.Type__c !=null )body +=  '<ACTION_TYPE>'+ra.Type__c+'</ACTION_TYPE>' + '\n';
                            else body +=  '<ACTION_TYPE>'+'</ACTION_TYPE>' + '\n';
                        if( ra.Field_Name__c !=null ) body +=  '<ACTION_FIELD_NAME>'+ra.Field_Name__c+'</ACTION_FIELD_NAME>' + '\n';
                            else body +=  '<ACTION_FIELD_NAME>'+'</ACTION_FIELD_NAME>' + '\n';
                        if( ra.Field_TYPE__c !=null )body +=  '<ACTION_FIELD_TYPE>'+ra.Field_TYPE__c+'</ACTION_FIELD_TYPE>' + '\n';
                            else body +=  '<ACTION_FIELD_TYPE>'+'</ACTION_FIELD_TYPE>' + '\n';
                        if( ra.Field_API_Name__c !=null ) body +=  '<ACTION_FIELD_API_NAME>'+ra.Field_API_Name__c+'</ACTION_FIELD_API_NAME>' + '\n';
                            else body +=  '<ACTION_FIELD_API_NAME>'+'</ACTION_FIELD_API_NAME>' + '\n';
                        if( ra.Value__c !=null ) body +=  '<VALUE_for_Update>'+ra.Value__c+'</VALUE_for_Update>' + '\n';
                            else body +=  '<VALUE_for_Update>'+'</VALUE_for_Update>' + '\n';
                        if( ra.Long_Value__c !=null )body +=  '<LONG_VALUE>'+ra.Long_Value__c+'</LONG_VALUE>' + '\n';
                            else body +=  '<LONG_VALUE>'+'</LONG_VALUE>' + '\n';
                        body +=  '<NOTIFY_USER>'+ra.Notify_User__c+'</NOTIFY_USER>' + '\n';
                        if( ra.CrossObjectField__c !=null ) body +=  '<CROSSOBJECTFIELD>'+ra.CrossObjectField__c+'</CROSSOBJECTFIELD>' + '\n';
                            else body +=  '<CROSSOBJECTFIELD>'+'</CROSSOBJECTFIELD>' + '\n';
                        if( ra.Reference_Id__c !=null ) body +=  '<REFERENCE_ID>'+ra.Reference_Id__c+'</REFERENCE_ID>' + '\n';
                           else body +=  '<REFERENCE_ID>'+'</REFERENCE_ID>' + '\n';
                        if( ra.User_Owner_Id__c != null )
                        	body +=  '<ACTION_USER_OWNER>'+ra.User_Owner_Id__c+'</ACTION_USER_OWNER>' + '\n';
                        else
                        	body += '<ACTION_USER_OWNER>'+ra.User_Owner_Id__c+'</ACTION_USER_OWNER>' + '\n';
                        if( ra.EmailTemplateName__c !=null )body +=  '<EMAIL_TEMPLATE_NAME>'+ra.EmailTemplateName__c+'</EMAIL_TEMPLATE_NAME>' + '\n';
                           else body += '<EMAIL_TEMPLATE_NAME>'+'</EMAIL_TEMPLATE_NAME>' + '\n';
                        if( ra.Email_Template__c !=null )body +=  '<EMAIL_TEMPLATE>'+ra.Email_Template__c+'</EMAIL_TEMPLATE>' + '\n';
                            else body += '<EMAIL_TEMPLATE>'+'</EMAIL_TEMPLATE>' + '\n';
                       
                      
                        if( ra.Additional_Emails__c !=null )body +=  '<ADDITIONAL_EMAILS>'+ra.Additional_Emails__c+'</ADDITIONAL_EMAILS>' + '\n';
                             else body += '<ADDITIONAL_EMAILS>'+'</ADDITIONAL_EMAILS>' + '\n';
                        if( ra.Apex_Job_Class__c !=null )body +=  '<APEX_JOB_CLASS>'+ra.Apex_Job_Class__c+'</APEX_JOB_CLASS>' + '\n';
                             else body += '<APEX_JOB_CLASS>'+'</APEX_JOB_CLASS>' + '\n';
                        if( ra.CallOut_Action__c !=null )body +=  '<CALLOUT_ACTION>'+ra.CallOut_Action__c+'</CALLOUT_ACTION>' + '\n';
                             else body += '<CALLOUT_ACTION>'+'</CALLOUT_ACTION>' + '\n';
                        if( ra.Callout_Method__c !=null )body +=  '<CALLOUT_METHOD>'+ra.Callout_Method__c+'</CALLOUT_METHOD>' + '\n';
                             else body += '<CALLOUT_METHOD>'+'</CALLOUT_METHOD>' + '\n';
                        if( ra.Callout_Timeout__c !=null )body +=  '<CALLOUT_TIMEOUT>'+ra.Callout_Timeout__c+'</CALLOUT_TIMEOUT>' + '\n';
                             else body += '<CALLOUT_TIMEOUT>'+'</CALLOUT_TIMEOUT>' + '\n';
                        if( ra.Lookup_Where_Fields__c !=null )body +=  '<LOOKUP_WHERE_FIELDS>'+ra.Lookup_Where_Fields__c+'</LOOKUP_WHERE_FIELDS>' + '\n';
                             else body += '<LOOKUP_WHERE_FIELDS>'+'</LOOKUP_WHERE_FIELDS>' + '\n';
                        if( ra.End_Point__c !=null )body +=  '<END_POINT>'+ra.End_Point__c+'</END_POINT>' + '\n';
                             else body += '<END_POINT>'+'</END_POINT>' + '\n';
                       if( ra.Endpoint_URL__c !=null )body +=  '<ENDPOINT_URL>'+ra.Endpoint_URL__c+'</ENDPOINT_URL>' + '\n';
                            else body += '<ENDPOINT_URL>'+'</ENDPOINT_URL>' + '\n';
                       if( ra.Input_Parameters__c !=null ) body +=  '<INPUT_PARAMETERS>'+ra.Input_Parameters__c+'</INPUT_PARAMETERS>' + '\n';
                             else body += '<INPUT_PARAMETERS>'+'</INPUT_PARAMETERS>' + '\n';
                       if( ra.Lookup_Field_API_Name__c !=null ) body +=  '<LOOKUP_FIELD_API_NAME>'+ra.Lookup_Field_API_Name__c+'</LOOKUP_FIELD_API_NAME>' + '\n'; 
                            else body += '<LOOKUP_FIELD_API_NAME>'+'</LOOKUP_FIELD_API_NAME>' + '\n';
                       if( ra.Lookup_Field_Name__c !=null ) body +=  '<LOOKUP_FIELD_NAME>'+ra.Lookup_Field_Name__c+'</LOOKUP_FIELD_NAME>' + '\n'; 
                            else body += '<LOOKUP_FIELD_NAME>'+'</LOOKUP_FIELD_NAME>' + '\n';
                       if( ra.Lookup_Object__c !=null ) body +=  '<LOOKUP_OBJECT>'+ra.Lookup_Object__c+'</LOOKUP_OBJECT>' + '\n'; 
                            else body += '<LOOKUP_OBJECT>'+'</LOOKUP_OBJECT>' + '\n';
                       if( ra.Output_Parameters__c !=null ) body +=  '<OUTPUT_PARAMETERS>'+ra.Output_Parameters__c+'</OUTPUT_PARAMETERS>' + '\n'; 
                            else body += '<OUTPUT_PARAMETERS>'+'</OUTPUT_PARAMETERS>' + '\n';
                       if( ra.Request_Parameter__c !=null ) body +=  '<REQUEST_PARAMETER>'+ra.Request_Parameter__c+'</REQUEST_PARAMETER>' + '\n'; 
                            else body += '<REQUEST_PARAMETER>'+'</REQUEST_PARAMETER>' + '\n';
                       if( ra.Response_Parameter__c !=null ) body +=  '<RESPONSE_PARAMETER>'+ra.Response_Parameter__c+'</RESPONSE_PARAMETER>' + '\n'; 
                            else body += '<RESPONSE_PARAMETER>'+'</RESPONSE_PARAMETER>' + '\n';
                      body +=  '<BULK_API>'+ra.Bulk_API__c+'</BULK_API>' + '\n';
                      if( ra.User_Owner_Id__c != null ){
                        	body +=  '<USER_OWNER_ID>'+ra.User_Owner_Id__c+'</USER_OWNER_ID>' + '\n';
                        	if(ra.User_Owner_Id__c != null && ra.User_Owner_Id__c.startsWith(AW_Rule_Constants.USER_KEYPREFIX) 
                        					&& referenceFieldMap.containsKey('User') && referenceFieldMap.get('User').get(ra.User_Owner_Id__c) != null){
                        		body +='<USER_NAME>' + referenceFieldMap.get('User').get(ra.User_Owner_Id__c) + '</USER_NAME>' + '\n';
                        		body +='<GROUP_NAME>' + '</GROUP_NAME>' + '\n';				
                        	}else if(ra.User_Owner_Id__c != null && ra.User_Owner_Id__c.startsWith(AW_Rule_Constants.GROUP_KEYPREFIX) 
                        					&& referenceFieldMap.containsKey('Group') && referenceFieldMap.get('Group').get(ra.User_Owner_Id__c) != null){
                        		body +='<USER_NAME>' + '</USER_NAME>' + '\n';
                        		body +='<GROUP_NAME>' + referenceFieldMap.get('Group').get(ra.User_Owner_Id__c) + '</GROUP_NAME>' + '\n';
                        	}	
                        }else{
                        	body += '<USER_OWNER_ID>'+ra.User_Owner_Id__c+'</USER_OWNER_ID>' + '\n';
                        	body +='<USER_NAME>' + '</USER_NAME>' + '\n';
                        	body +='<GROUP_NAME>' + '</GROUP_NAME>' + '\n';	
                        	
                        }
                        if(mapa.containsKey(ra.Id)){
                            body +=  '<INSERT_RELATED_OBJECT_SECTION>' + '\n';                          
                            Integer iterator2 = 1;
                            for(Values_for_Action_Insert_Record__c vAction : mapa.get(ra.Id)){  
                                body +=  '<Insert_Field>'+iterator+'</Insert_Field>' + '\n';
                                body +=  '<Field_Name_Insert>'+vAction.name+'</Field_Name_Insert>' + '\n';
                                body +=  '<Value_For_Insert>'+vAction.Value__c+'</Value_For_Insert>' + '\n'; 
                                iterator2++;                
                            }
                            body +=  '</INSERT_RELATED_OBJECT_SECTION>' + '\n';
                        }                       
                        
                        body +=  '</ACTION>' + '\n';
                        iterator++;                 
                    }                   
                    body +=  '</RULE_ACTION_SECTION>' + '\n';
                }               
                body += '</RULE_NAME>' + '\n';          
            } 
        }
        system.debug('-->XMLBODY '+body);
        return body;
        
    }
    
    
}
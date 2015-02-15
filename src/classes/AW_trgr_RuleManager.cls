// 
// (c) 2012 Appirio, Inc.
//
// AW_trgr_RuleManager                                                     
//
// Trigger is used to populate the count of rule in an Advance Workflow    
//
//  
// 26 Jan 2013     Processing regarding Active, Draft and Archive Rule Status
public with sharing class AW_trgr_RuleManager {
 
  //Variable to make sure that the Rule insert, update  delete  is happening only once.
  public static Boolean RULE_FLOW_CONTROLLER = true;
 
  public static void afterInsertRule( List<Rule__c> newList){
  Set<Id> executionWorkflowIds = new Set<Id>();  
     for(Rule__c rule : newList){
            if(rule.Advance_Workflow__c != null){
                executionWorkflowIds.add(rule.Advance_Workflow__c);
                 
            }
    }           
    if (executionWorkflowIds.size()>0  ) CountRulesassociatedtoAdvanceWorkflow(executionWorkflowIds);
    RULE_FLOW_CONTROLLER = false;
}

 // public static void afterUpdateRule(List<Rule__c> newList, Map<Id, Rule__c> oldMap ){
  public static void afterUpdateRule(List<Rule__c> newList,List<Rule__c> oldList  ){
    Set<Id> executionWorkflowIds = new Set<Id>();
    Set<Id> ruleIds = new Set<Id>();
    Set<Id> activedraftruleIds = new Set<Id>();
   
     
    for(Integer i = 0; i < oldList.size(); i++){
        system.debug('-- for(Integer i: ' +  i );
        Rule__c newRule = newlist[i];
        Rule__c oldRule = oldlist[i];
        
        system.debug('-- NEW RULE ' +newRule +'  -- OLD RULE ' + oldRule );
         
        system.debug('-- NEW Status ' +newRule.Status__c + '-- OLD Status ' + oldRule.Status__c);
         
    //     NOT POSSIBLE ONLY ONE ADVANCE WORKFLOW PER OBJECT
        if(newRule.Advance_Workflow__c != oldRule.Advance_Workflow__c){
            if(newRule.Advance_Workflow__c != null ){
                     executionWorkflowIds.add(newRule.Advance_Workflow__c);
             } else{
                     executionWorkflowIds.add(oldRule.Advance_Workflow__c);
             }
             if (executionWorkflowIds.size()>0  ) CountRulesassociatedtoAdvanceWorkflow(executionWorkflowIds);
        }
         
        //if(newRule.Status__c != oldRule.Status__c && newRule.Id != null){
        if(newRule.Status__c != oldRule.Status__c  ){
        
                /* If status change from Active to Draft  update status to archive, reset  order & asscociate to advance workflow  */
                
                if( oldRule.Status__c == 'Active' &&  newRule.Status__c == 'Draft'   ){
                           activedraftruleIds.add(newRule.Id);
                           system.debug('--- from Active to Draft draftarchiveruleIds '+ activedraftruleIds); 
                           if (activedraftruleIds.size()>0   ) updateRuleActive_To_Draft(activedraftruleIds);
               }
                /* If status change from Active to Archive insert a record Rule_Archive object and Delete Rule */
                  else  if(( oldRule.Status__c == 'Active' ) && (  newRule.Status__c == 'Archived' && oldRule.Total_Actions__c > 0 && oldRule.Total_Criteria__c > 0)){
                            ruleIds.add(newRule.Id);
                            system.debug('--- from Active to Archive draftarchiveruleIds '+ ruleIds); 
                            if (ruleIds.size()>0  ) {
                                  updateRuleActiveDraft_To_Archive(ruleIds,newList,oldRule.Status__c);
                             }
                /* If status change from Draft to Archive insert a record Rule_Archive object and Delete Rule */
                 } else  if (   oldRule.Status__c == 'Draft' && newRule.Status__c == 'Archived'   && oldRule.Total_Actions__c > 0 && oldRule.Total_Criteria__c > 0 ) {
                           ruleIds.add(newRule.Id);
                           system.debug('--- from Draft to Archive draftarchiveruleIds '+ ruleIds); 
                             if (ruleIds.size()>0  ) {
                                  updateRuleActiveDraft_To_Archive(ruleIds,newList,oldRule.Status__c);
                                //  afterInsertDeleteRule(newList);
                            }
                       }  
               }   
          }
     RULE_FLOW_CONTROLLER = false;  
   }

 
  public static void afterDeleteRule(List<Rule__c> oldList){
    system.debug('-- AW_trgr_RuleManafer afterDeleteRule OLD LIST SIZE  ' +oldList.size() );
     Set<Id> executionWorkflowIds = new Set<Id>();
     
     for(Rule__c rule : oldList){
     system.debug('--AW_trgr_RuleManafer afterDeleteRule RULE STATUS   ' +rule.Status__c );
         
        if ( rule.Status__c=='Active') {
        // || ( rule.Status__c=='Draft' && rule.Total_Actions__c  >0 && rule.Total_Criteria__c>0 ) ) 
            executionWorkflowIds.add(rule.Advance_Workflow__c);
        }
      }
     if (executionWorkflowIds.size()>0  ) CountRulesassociatedtoAdvanceWorkflow(executionWorkflowIds);
     RULE_FLOW_CONTROLLER = false;  
        
    }
   
  public static void CountRulesassociatedtoAdvanceWorkflow( Set<Id> Ids){
  /* 
  * Get all the childs of Advance Workflow and then update
  * CountRulesassociatedtoAdvanceWorkflow__c  field
  */ 
  system.debug('-- CountRulesassociatedtoAdvanceWorkflow   ' +Ids );
    
    Map<id,Advance_Workflow__c> executionWorkflowMap = new Map<id,Advance_Workflow__c>([select id,(select id from Rules__r where Status__c='Active' ) from Advance_Workflow__c where id IN :Ids]);
    for(Id flowId: executionWorkflowMap.keyset()){
        Advance_Workflow__c workflow = executionWorkflowMap.get(flowId);
        workflow.CountRulesassociatedtoAdvanceWorkflow__c = workflow.Rules__r.size();
    }
    update executionWorkflowMap.values();      
   }   

/**
    * If status change from Active to Draft Update Rule fields :
     Blank Order, Advance orkflow, 
     Set Status to Draft
     Increase Version
  */  
public static void updateRuleActive_To_Draft( Set<Id> Ids){  

 system.debug('-- updateRuleActive_To_Draft   ' +Ids );
  
  if (Ids.size()>0  ) {
         Map<id,Rule__c> ruleMap = new Map<id,Rule__c>([SELECT id,
                                                           Status__c,
                                                            Version__c 
                                                     FROM Rule__c 
                                                     WHERE id IN :Ids]);
        for(Id ruleId: ruleMap.keyset()){
              Rule__c rule = ruleMap.get(ruleId);
              rule.Advance_Workflow__c =null;
              rule.Order__c =null;
              rule.Execution_Behavior__c =null;
              rule.Status__c ='Draft';
              if (rule.Version__c != null ) rule.Version__c =rule.Version__c+1;else rule.Version__c=1;
              update ruleMap.values();    
            
       } 
    }
}

/**
* If status change from Active or Draft to Archive insert a record 
* Rule_Archive object and Delete Rule  
*/  
public static void updateRuleActiveDraft_To_Archive( Set<Id> Ids,List<Rule__c> newList,String PriorStatus){ 
    system.debug('-- updateRuleActiveDraft_To_Archive   ' +Ids );
    
    String result='' ;
    if (Ids.size()>0  ) {
         List<Rule_Archive__c>  insertArchiveRuleList = new List<Rule_Archive__c>();
         List<Rule__c> lstRulesToDelete = new List<Rule__c>();
         for(Rule__c rl : newList) {
             Rule__c rlDel = new Rule__c(Id=rl.Id);
             if(PriorStatus=='Active' || ( PriorStatus=='Draft' && rl.Total_Actions__c>0 && rl.Total_Criteria__c >0))  {
                 lstRulesToDelete.add(rlDel);
             }
             Rule_Archive__c   rulearchiveList = new Rule_Archive__c();
                   
            // rulearchiveList.Rule__c= rl.Id; 
             rulearchiveList.Rule_Reference_Id__c=rl.Id; 
             rulearchiveList.Rule_Name__c =rl.Name;
             rulearchiveList.Description__c= rl.Description__c; 
             rulearchiveList.Status__c= rl.Status__c; 
             rulearchiveList.Object__c= rl.Object__c; 
             rulearchiveList.Status__c= rl.Status__c; 
             rulearchiveList.Order__c= rl.Order__c; 
             rulearchiveList.Evaluation_Rule__c= rl.Evaluation_Rule__c; 
             rulearchiveList.Version__c= rl.Version__c; 
             if(PriorStatus=='Active') {
                rulearchiveList.Prior_Status__c='Active';
                // Start code for generating  xml body
                List<Rule__c> rules = new List<Rule__c>();
                rules.add(rl);
                rulearchiveList.Body__c= createXML(rules);
                // End code for generating  xml body  
                insertArchiveRuleList.add(rulearchiveList);
              }
             if(PriorStatus=='Draft' && rl.Total_Actions__c>0  && rl.Total_Criteria__c >0) {
               rulearchiveList.Prior_Status__c='Draft';
              
              // result=XMLWriteDemo.getXml();
              // rulearchiveList.Body__c=result;
              // rulearchiveList.Body__c='Body for Rule ( From Draft to Archive   ) is generated ...';  
             // Start code for generating  xml body
                List<Rule__c> rules = new List<Rule__c>();
                rules.add(rl);
                rulearchiveList.Body__c= createXML(rules);
                
             // End code for generating  xml body 
             insertArchiveRuleList.add(rulearchiveList);
           }
             
            // insertArchiveRuleList.add(rulearchiveList);
       }
       if (insertarchiveruleList.size() >0 ) insert insertarchiveruleList;
       System.debug(':::::::::::::::::::::::insertarchiveruleList  :'+insertarchiveruleList);
       //convert the data of rule actions and criteria into XML format 
      // system.debug('lstRulesToDelete.size() ' + lstRulesToDelete.size()) ;
      // if (lstRulesToDelete.size() >0 ) delete lstRulesToDelete;
      }
}

 public static string createXML(List<Rule__c> rules){
                List<RuleCriteria__c> ruleCriteriaList = AW_CSVGenerator.loadRuleCriteriaList(rules);
                List<RuleAction__c> ruleActionList = AW_CSVGenerator.loadRuleActionList(rules);
                string body; 
                String  awfHeader   =   '<?xml version="1.0" encoding="ISO-8859-1" ?>'  +   '\n' ;
                                           /* '<DVANCE_WORKFLOW>' + '\n' +
                                                '<DVANCE_WORKFLOW_NAME  name="' + currentAWF[0].Name + '">' + '\n' +
                                                    '<DESCRIPTION>' + currentAWF[0].Description__c + '</DESCRIPTION>' + '\n' +
                                                    '<OBJECT>' + currentAWF[0].Object__c + '</OBJECT>' +    '\n' +
                                                    '<ENABLED>' + currentAWF[0].Enabled__c + '</ENABLED>' +     '\n';*/
                String  awfBody     =   createXMLBody(rules , ruleCriteriaList , ruleActionList);
                String  awfFooter   =  '';     /*'</DVANCE_WORKFLOW_NAME>' +     '\n' +  
                                            '</DVANCE_WORKFLOW>';*/   
                body = awfHeader + awfBody + awfFooter;
                return body;
  }
  
  private static String  createXMLBody(List<Rule__c> rules , List<RuleCriteria__c> criterias, List<RuleAction__c> actions){
        String  body = '';
        map<Id,list<Values_for_Action_Insert_Record__c>>    mapa            =   new map<Id,list<Values_for_Action_Insert_Record__c>> ();
        map<Id, list<OwnerPrioritization__c>>   mapOwnerPrioritization 		=   new map<Id, list<OwnerPrioritization__c>>();
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
            mapOwnerPrioritization.put(ra.id , ra.Owner_Prioritization__r);
            actionMap.get(ra.Rule__c).add(ra);
            
        }  
        if(!referenceFieldMap.isEmpty()){
            referenceFieldMap = AW_ImportExportHelper.loadReferenceIds(referenceFieldMap, 'Id', 'Name');
        }      
        if(rules.size() > 0 && rules != null && !rules.isEmpty()){  
            for(Rule__c r : rules){
                body += '<RULE_NAME name="\'' + r.Name.escapeXML() + '">' + '\n';
                body += '<EVALUATION_RULE>' + r.Evaluation_Rule__c + '</EVALUATION_RULE>' + '\n';
                body += '<RULE_STATUS>' + r.Status__c + '</RULE_STATUS>' + '\n';
                body += '<RULE_VERSION>' + r.Version__c + '</RULE_VERSION>' + '\n';
                body += '<RULE_DESCRIPTION>' + AW_ImportExport_Controller.escapecharsTochars(r.Description__c) + '</RULE_DESCRIPTION>' + '\n';
                body += '<DISPLAYFILTERLOGIC>' + AW_ImportExport_Controller.escapecharsTochars(r.DisplayfilterLogic__c)  + '</DISPLAYFILTERLOGIC>' + '\n';    
            
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
                       /* //Start Bug Fix: Add ; as a delimeter for picklist values in export to xml  -Kirti Sahni [10-Sept-14]
                         if(rc.field_type__c == 'PICKLIST'){
                           rc.Matching_Value__c = rc.Matching_Value__c.replace('|', ';');
                         }
                        //End Bug Fix: Add ; as a delimeter for picklist values in export to xml  -Kirti Sahni [10-Sept-14]*/
                        body +=  '<MATCHING_VALUE>'+(rc.Matching_Value__c != null ? rc.Matching_Value__c.escapeXML() : '')+'</MATCHING_VALUE>' + '\n';
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
                        if( ra.Value__c !=null ) body +=  '<VALUE_for_Update>'+ra.Value__c.escapeXML()+'</VALUE_for_Update>' + '\n';
                            else body +=  '<VALUE_for_Update>'+'</VALUE_for_Update>' + '\n';
                        if( ra.Long_Value__c !=null )body +=  '<LONG_VALUE>'+ra.Long_Value__c.escapeXML()+'</LONG_VALUE>' + '\n';
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
                       // Megha
                       if(ra.Email_Template_Folder__c != null) body += '<EMAIL_TEMPLATE_FOLDER>'+ra.Email_Template_Folder__c+'</EMAIL_TEMPLATE_FOLDER>'+'\n';
                      		else body += '<EMAIL_TEMPLATE_FOLDER>'+'</EMAIL_TEMPLATE_FOLDER>'+'\n';
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
                        body += ra.Prioritization_Method__c != null ? '<PRIORITIZATION_METHOD>' + ra.Prioritization_Method__c + '</PRIORITIZATION_METHOD>' :  '<PRIORITIZATION_METHOD></PRIORITIZATION_METHOD>';
                        
                        if(mapa.containsKey(ra.Id)){
                            body +=  '<INSERT_RELATED_OBJECT_SECTION>' + '\n';                          
                            Integer iterator2 = 1;
                            for(Values_for_Action_Insert_Record__c vAction : mapa.get(ra.Id)){  
                                body +=  '<Insert_Field>'+iterator+'</Insert_Field>' + '\n';
                                body +=  '<Field_Name_Insert>'+vAction.name+'</Field_Name_Insert>' + '\n';
                                body +=  '<Value_For_Insert>'+(vAction.Value__c != null ? vAction.Value__c.escapeXML() : '')+'</Value_For_Insert>' + '\n'; 
                                iterator2++;                
                            }
                            body +=  '</INSERT_RELATED_OBJECT_SECTION>' + '\n';
                        }   
                        if(mapOwnerPrioritization.containsKey(ra.Id)){
                            body +=  '<OWNER_PRIORITIZAZTION>' + '\n'; 
                             Integer iteratorOP = 1;                         
                            for(OwnerPrioritization__c op : mapOwnerPrioritization.get(ra.Id)){  
                            	body +=  '<OWNER_PRI>' + iteratorOP + '</OWNER_PRI>';
                                body +=  '<USER_QUEUE_GROUP>'+op.User_Queue_Group__c+'</USER_QUEUE_GROUP>' + '\n';
                                body +=  '<USER_QUEUE_GROUP_ID>'+op.User_Queue_Group_Id__c+'</USER_QUEUE_GROUP_ID>' + '\n';
                                body +=  '<PRIORITY>'+op.Priority__c+'</PRIORITY>' + '\n'; 
                                body +=  '<WEIGHT>'+op.Weight__c+'</WEIGHT>' + '\n'; 
                                body +=  '<PERCENT>'+op.Percent__c+'</PERCENT>' + '\n'; 
                                body +=  '<ASSIGNED>'+op.Assigned__c+'</ASSIGNED>' + '\n'; 
                                iteratorOP++;
                                         
                            }
                            body +=  '</OWNER_PRIORITIZAZTION>' + '\n';
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
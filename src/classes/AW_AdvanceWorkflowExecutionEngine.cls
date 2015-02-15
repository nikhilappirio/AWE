// (c) 2012 Appirio, Inc.
// AW_AdvanceWorkflowExecutionEngine                                                     
// This class is used to process rules assigned to an execution plan 
// and performs the associated actions
//
// 18 Nov 2012     Peter Babalis     Original (Update,Insert actions)
// 07 Feb 2013     Peter Babalis     Executes Cross field Objects and Tasks and email Templates
// 10 May 2013     Peter Babalis     IsChangedFrom To
// 10 May 2013     Peter Babalis     IsChanged
// 25 May 2013     Peter Babalis     Http Call outs
// 25 May 2013     Peter Babalis     Apex Class Execution  
// 01 Jun 2013     Peter Babalis     String & Date Functions as Actions 
// 05 Jun 2013     Peter Babalis     Send Email To Distribution List
// 12 Jul 2013     Peter Babalis     Add Click event Processing
// 04 Sep 2013     Peter Babalis     Upsert Related Object 
// 12 Dec 2013     Peter Babalis     Refactoring of Class to move methods in 
//                                   helper classes AW_ExecutionActionHelper,AW_FormulaExpressionHelper,AW_CriteriaEvaluationComparisonHelper  
// 24 Dec 2013     Peter Babalis     Refactoring of Class to move methods   
//                                   getValidfields_from_Actions,apex_execution_params,
//                                   apex_execution_outputupdate,applyInsertChildActions
//                                   updateFieldfrom from AW_AdvanceWorkflowExecutionEngine 
//                                   to  helper class  AW_ExecutionActionHelper
// 02 May 2014     Peter Babalis     Stamp each record that a rule was applied with AWE rule and Transaction stamp
// 16 July 2014    Peter Babalis     Changes for Simulation 
// 12 Oct 2014     Peter Babalis     Added logic to detect for crossformula object from task  if parent is lead/contact or other sfdc std objects or custom objects

global class AW_AdvanceWorkflowExecutionEngine{ 
    
    //required to stop the trigger to start
    global static Boolean EvaluationIsRunning=false;
    
    //Variable to hold the advance workflow
    public static Advance_Workflow__c advWorkflow;
    
    //required for trigger chaining every trigger that calls this class will add it self to this set so 
    //that the same sobject trigger does not start evaluation running
    global static Set<String> EvaluationRunningFor = new Set<String>();
    
    //stores the fields that needs to be quired
    public static Map<String,Set<String>> criteriaFields;  
    
    //field map of the object
    public static Map<String,Map<String,Schema.SObjectField>> fieldMap;
    
     //store the global describe result
     public static Map<String, Schema.SObjectType> gd = new Map<String, Schema.SObjectType>();
     
    //store all the relationships names
    public static Map<String,String> relationshipNames = new Map<String,String>();
     
    //store the valid relationship names in the object
    public static Map<String,Set<String>> validRelationShips= new Map<String,Set<String>>();
    
    //store the rule Id for Record is created or edited and did not previously meet the rule criteria
    static Map<Id,Set<Id>> rulesExecuted = new Map<Id,Set<Id>>();
    
    public  static List<Rule_Execution_History__c> historyToInsert = new  List<Rule_Execution_History__c>();
    
    //variable to hold the execution time stamp
    static DateTime transactiontamp; 
    
   // External salesforce url
    public static string sfURL = URL.getSalesforceBaseUrl().toExternalForm();    
   
    // Map of Object API Name and Label
    private static Map<String,String> objectLabels = new Map<String,String>();
    
    // Child object to be inserted
    public static List<SObject> childObjectList = new List<SObject>();
    
    // Map of Rule Action Id and Insert Related Record Info object as child 
    public static Map<Id,RuleAction__c> insertedRelatedRecordInfo = new Map<Id,RuleAction__c>();
    
   // Map of child relationship name and field in child for parent
    public static Map<String,String> childParentRelationshipField = new Map<string,String>();
    
    public static Set<Id> validRuleIds = new Set<Id>();
    public static Map<Id,SObject> toUpdateSObject;
    public static List<Object_Action_Execution__c> bulkObjectUpdates= new List<Object_Action_Execution__c>();
    
    // List to capture values before simulation
    //public static List<SObject>   lstSObjectforUpdateSimulation       {get; set;} 
    
    // Boolean to notify user 
    public static boolean notifyUser = false; 
    public static String concatop='&';
    public static String templateId;  
    public static Boolean isAsyncProcessRunning = false;
    
    
    
    /*this variable handles bulk operation for actions:- */
    public static Boolean bulkOperation;
    public static Set<Id> bulkactionIds;
    
    
    /** added this variable to hold the oldRecords in case of update **/
    //public static List<Sobject> oldSobjectList = new List<Sobject>();
    public static  Map<Id,SObject> oldListMap = new Map<Id,SObject>();
    public static Boolean isUpdate=false;
    
    
    //@added on 31 may
    public static RuleAction__c actionInContext;
    public static user userInContext;
     //adding a new variable that will store all the rules that are valid for onclick event as they have to displayes     
    public static List<Rule__c> displayClickEventValidRules = new List<Rule__c>(); 
    
    /**
    * this method starts the processing engine for evaluation the rules
    * params : 
    * recordIds : ids of the object records that needs to be evaluated 
    * sobjectName : object(Account,Contact)
    * action : update/insert 
    
    **** Updating the method to fix the issue of evaluation rule criteria ***
     
  
    */
    //@future
    global static void startRulesProcessing(Set<Id> recordIds,String sobjectName,Boolean isInsert){
        String mode='';
        bulkOperation =false;
        isUpdate = !isInsert;
        
        //get the advance workflow
       
        List<Advance_Workflow__c> workflows =Database.query('SELECT id,Advance_Rule_Stamp__c,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true');
        
        if(workflows.size()==0) return;
        advWorkflow = workflows[0];
        
        // get the rules get all types of rules
        String query ='Select Id,Evaluation_Rule__c,Object__c FROM Rule__c WHERE Object__c=\''+sobjectName+'\' AND Status__c=\'Active\' AND Evaluation_Rule__c!=\'On Click Event\'  ';
        
        if(!isInsert){
            query+=' AND Evaluation_Rule__c!=\'Record is created\'';
        }
        query += ' AND Advance_Workflow__c in (SELECT id from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true)';
        
        //list of rules
        List<Rule__c> rules = database.query(query);
        if(rules.size()==0) return;
        
        Set<String> executedIds = new Set<String>();
        
        //get the history need later to check whether the rule needs to be evaluated or not
        /*
        for(Rule_Execution_History__c h : [SELECT Rule_ID__c,Rule__c,
                                                  Record_ID__c 
                                           FROM   Rule_Execution_History__c 
                                           WHERE Record_ID__c IN:recordIds])
                                           {               
            Set<Id> ruleIds = rulesExecuted.get(h.Record_ID__c)!=null ? rulesExecuted.get(h.Record_ID__c): new Set<Id>();
            ruleIds.add(h.Rule__c);
            rulesExecuted.put(h.Record_ID__c,ruleIds);
        }
         */
         Set<Id> processRules = new Set<Id>();
        //now there is a condition :-
        for(Rule__c r :rules ){
            processRules.add(r.Id); 
        }
        //start
    // Megha - 11/10/2014
         AdvanceWorkflowConf__c advWFConf = AdvanceWorkflowConf__c.getInstance(sobjectName);
         Integer batchSizeAsyncThreshold;
         
         if(advWFConf != null && advWFConf.Threshold_for_Async_Invocation__c != null){
            batchSizeAsyncThreshold = Integer.valueOf(advWFConf.Threshold_for_Async_Invocation__c);
         }else{
            batchSizeAsyncThreshold = recordIds.size();
         } 
         
         if(recordIds.size() <= batchSizeAsyncThreshold){
             evaluateRules(processRules,recordIds,sobjectName,mode);
         }else{
            evaluateRulesAsync(processRules,recordIds,sobjectName,mode);
            // evaluateRules(processRules,recordIds,sobjectName,mode);
         }
    }
   
    
    /**
    * this method starts the processing engine for simulation of Advanced Workflow  
    */
   
    global static void startRulesProcessingOnSimulation(Set<Id> recordIds,String sobjectName,Boolean isInsert,String mode){
        //String mode='Simulation';
         bulkOperation =false;
        isUpdate = !isInsert;
       //get the advance workflow
        List<Advance_Workflow__c> workflows =Database.query('SELECT id,Advance_Rule_Stamp__c ,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true');
        if(workflows.size()==0) return;
        advWorkflow = workflows[0];
          // get the rules get all types of rules
        String query ='Select Id,Evaluation_Rule__c,Object__c FROM Rule__c WHERE Object__c=\''+sobjectName+'\' AND Status__c=\'Active\' AND Evaluation_Rule__c!=\'On Click Event\'  ';
        
        if(!isInsert){
            query+=' AND Evaluation_Rule__c!=\'Record is created\'';
        } 
        query += ' AND Advance_Workflow__c in (SELECT id from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true)';
        
        //list of rules
        List<Rule__c> rules = database.query(query);
        if(rules.size()==0) return;
        
        Set<String> executedIds = new Set<String>();
        
          Set<Id> processRules = new Set<Id>();
          
        //now there is a condition :-
        for(Rule__c r :rules ){
            processRules.add(r.Id); 
        }
        //start
        system.debug('--> recordIds '+ recordIds);
        system.debug('-->processRules   '+ processRules);
        system.debug('--> mode '+ mode);
                     
        evaluateRules(processRules,recordIds,sobjectName,mode);
    }
     
    /**
    * this method starts the processing engine for evaluation the rules  for click events  
    */
    global static void startRulesProcessingOnClick(Set<Id> recordIds,String sobjectName){
        bulkOperation =false;
        String mode='';
        //get the advance workflow
        List<Advance_Workflow__c> workflows  =Database.query('SELECT id,Advance_Rule_Stamp__c ,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true');
        if(workflows.size()==0) return;
        advWorkflow = workflows[0];
        // get the rules get all types of rules
        String query ='Select Id,Evaluation_Rule__c,Object__c FROM Rule__c WHERE Object__c=\''+sobjectName+'\' AND Status__c=\'Active\' ';                
        query+=' AND Evaluation_Rule__c=\'On Click Event\'';
        
        /**
        * CC: Added filter for execution plan
        */
        query += ' AND Advance_Workflow__c in (SELECT id from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true)';
        
        //list of rules
        List<Rule__c> rules = database.query(query);
        if(rules.size()==0) return;
        
        Set<Id> processRules = new Set<Id>();
        //now there is a condition :-
        for(Rule__c r :rules ){
            processRules.add(r.Id); 
        }
        //start
        system.debug('Start of execution On Click Event');
        evaluateRules(processRules,recordIds,sobjectName,mode);
    }

    /**
    * this method given a set of rules ids will evaluate the object records for
    * criteria ,if the record matches the criteria then it will perform the associated action
    * with that rule
    
    *** Updated the method to fix issue of evalution rule ***
    
    */
       
     public static void evaluateRulesbulk(Set<Id> ruleIds,Set<Id> recordIds,String sobjectName,Set<Id> ActionIds,Map<String,Object_Action_Execution__c> actionrecs){
      
        system.debug('--->EVALUATERULES BULK ruleIds'+ruleIds); 
        system.debug('--->EVALUATERULES BULK recordIds'+recordIds);
        system.debug('--->EVALUATERULES BULK sobjectName'+sobjectName);   
        system.debug('--->EVALUATERULES BULK ActionIds'+ActionIds);   
        system.debug('--->EVALUATERULES BULK actionrecs'+actionrecs);   
        
         
       List<Advance_Workflow__c> workflows  =Database.query('SELECT id,Advance_Rule_Stamp__c ,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true');
       if(workflows.size()==0) return;
       advWorkflow = workflows[0];
          
      //first thing is to check if the rule ids exist (just a validation)
       if(ruleIds.size()==0) return; //nothing to process :) 
        transactiontamp = Datetime.now(); 
        try{
           //get the list of criteria for the given set of rule Ids:-
                // Megha - 07/16/2014 - Added boolean for Simulation
                List<Rule__c> rules = AW_AdvanceWorkflowExecutionHelper.getActiveCriteria(ruleIds,sobjectName, false);
                  
                 EvaluationIsRunning = true; 
                 EvaluationRunningFor.add(sobjectName);
                 List<Rule__c> lstValidRules = getValidRules(rules,sobjectName);
                 if(criteriaFields.size() == 0){
                    return;
                } 
                
                //update : if bulk get subset of actions
                // Megha - 07/16/2014 - Added boolean for Simulation
                system.debug('->lstValidRules BULK '+lstValidRules);
                system.debug('->bulkOperation '+bulkOperation);
                
                Map<Id,Rule__c> ruleActions = bulkOperation ? AW_AdvanceWorkflowExecutionHelper.getActiveRuleActionsSubset(ruleIds,sobjectName,bulkactionIds, false) : AW_AdvanceWorkflowExecutionHelper.getActiveRuleActions(ruleIds,sobjectName,false);  
                system.debug('->ruleActions BULK'+ruleActions);
               
                /**
                * By Cloud Challenger
                * Get all the insert related record info of rule
                */
                insertedRelatedRecordInfo = bulkOperation ? AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfoForActions(bulkactionIds): AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfo(ruleIds);
              // Cloud Challenger Upsert Changes Start
                Map<Id,RuleAction__c> upsertRelatedRecordInfo =  AW_AdvanceWorkflowExecutionHelper.getUpsertRelatedRecordInfo(ruleIds);                  
                if(upsertRelatedRecordInfo.size() > 0){
                    insertedRelatedRecordInfo.putAll(upsertRelatedRecordInfo);
                }
                // Cloud Challenger Upsert Changes End
                
                /** 
                * here the logic is now encapsulated in a method
                * the method first add the valid fields to be updated in the criteria field list
                * also check if the value is a valid object field/reference field so that you cann
                * add it to list to query
                */
                
                AW_ExecutionActionHelper.getValidfields_from_Actions(ruleActions.values(),sobjectName);
             
                
                Set<String> parentFields = criteriaFields.get(sobjectName.toLowerCase());      
                
                if(parentFields.size()==0  || !parentFields.contains('id'))
                    parentFields.add('id');
                
                if(sobjectName.tolowerCase()!='task' && sobjectName.tolowerCase()!='case' && (parentFields.size()==0 || !parentFields.contains('name')))
                    parentFields.add('name');
                    
                if(sobjectName.tolowerCase()=='task' && (parentFields.size()==0 || !parentFields.contains('subject')))
                    parentFields.add('subject');
                
                                    
                if(sobjectName.tolowerCase()=='case' && (parentFields.size()==0 || !parentFields.contains('casenumber')))
                    parentFields.add('casenumber'); 
                    
                String fields = AW_AdvanceWorkflowExecutionHelper.joinSet(parentFields,',');
                system.debug('-->BULK from joinset fields:' + fields);
               // if(fields!=null && fields.trim()!='') fields= fields+',';
                
                if(fields!=null && fields.trim()!='' && ! fields.contains('id')) fields= fields+', Id ';
                 
                /* PGB101914 BULK    */   
                String fieldswithwhoid='';
                String fields_no_whoid ='';
                         
                String qrySOQL='';
                qrySOQL='SELECT  ' + fields +' ';
                 //now add the child queries also as they need to be evaluated in the query :)
                  
                for(String obj:criteriaFields.keySet()){
                         
                    if(obj.equalsIgnoreCase(sobjectName)) continue;
                    if(obj.equalsIgnoreCase('task')  )
                    { 
                     
                      fieldswithwhoid=AW_AdvanceWorkflowExecutionHelper.joinSetTaskWhoIdsOnly(parentFields, criteriaFields.get(obj),',');
                    
                      fields_no_whoid=AW_AdvanceWorkflowExecutionHelper.joinSetTask_No_WhoIds(criteriaFields.get(obj),',');
                     // system.debug('--->joinSetTask NO WhoIds  AFTER fields_no_whoid:   ' + fields_no_whoid);
                      
                     } 
                     else  
                     { 
                          system.debug('--->joinSet ELSE BEFORE object '+obj +'   fields '+fields );
                          fields_no_whoid =AW_AdvanceWorkflowExecutionHelper.joinSet(criteriaFields.get(obj),',');
                          system.debug('--->joinSet ELSE AFTER object '+obj +'   fields '+fields_no_whoid );
                    
                     }
                      system.debug('--->fields: forming BULK' + fields);
                      system.debug('--->fieldswithwhoid:  forming BULK ' + fieldswithwhoid);
                      system.debug('--->fields_no_whoid: forming BULK ' + fields_no_whoid);
                    
                     // status,last_detail__c,description,leadsource,lead_source__c
                     
                     system.debug('--->relationshipNames: forming BULK ' + relationshipNames);
                     
                      // if(fields!= null && fields != ''){
                       if(fields_no_whoid!= null && fields_no_whoid != ''){
                        if (fields_no_whoid.contains('Id') || fields_no_whoid.contains('id')) 
                        //if (fields.contains('Id') || fields.contains('id')) 
                           qrySOQL+=' , (SELECT  ' + fields_no_whoid +' FROM '+relationshipNames.get(obj)+')';
                          // qrySOQL+=' , (SELECT  ' + fields +' FROM '+relationshipNames.get(obj)+')';
                         else
                           qrySOQL+=' , (SELECT  ' + fields_no_whoid +',Id  FROM '+relationshipNames.get(obj)+')';
                          // qrySOQL+=' , (SELECT  ' + fields +',Id  FROM '+relationshipNames.get(obj)+')';
                       
                         system.debug('--->qrySOQL: forming BULK ' + qrySOQL);
                     }
                }
                
                 
                 qrySOQL+=' FROM '+sobjectName+' WHERE Id IN : recordIds';
                 system.debug('--->qrySOQL:BULK ' + qrySOQL);
                //system.debug('--->recordIds:' + recordIds);
                List<SObject> sobjectRecords = database.query(qrySOQL);     
                 Map<Id,SObject> recordBeforeUpdate = new Map<Id,SObject>(Database.query(qrySOQL));
              
               
                 system.debug('--->sobjectRecords: BULK' + sobjectRecords);
                toUpdateSObject= new Map<Id,SObject>();
                childObjectList = new List<SObject>(); 
                Map<String,List<SObject>> toUpdateChildObjects = new Map<String,List<SObject>>();
                Map<Id,List<SObject>> validRecords= new Map<Id,List<SObject>>();
                /* defining variables to handle the send email action */
                 
                Map<String,Map<String,List<RuleAction__c>>> usersInSendEmailAction =new Map<String,Map<String,List<RuleAction__c>>> ();
                Map<String,Map<String,List<RuleAction__c>>> grpsInSendEmailAction = new Map<String,Map<String,List<RuleAction__c>>> ();
                /**
                * Instead of iterating to the map, iterate to the list just to maintain the order of rules
                */
               for(Rule__c rule : lstValidRules){
               
                   
                   Rule__c r = ruleActions.get(rule.Id);
                   // system.debug('r--->'+r);
                    if(r.Rule_Actions__r.size()==0) continue;
                  
                    //for every sobject record that matched the rule we need to apply the action
                    List<RuleAction__c> actions= r.Rule_Actions__r;
                    boolean isValidCriteria = true;
                    
                      string objaction='';
                             
                    
                    for(SObject o:sobjectRecords) {
                        SObject oldRecord = recordBeforeUpdate.get((String)o.get('id'));
                        
                        //system.debug('---Record---'+o);
                         string objectaction='';
                         system.debug( ' Have Criteria for Rule: '+r.Name+ ' Met '+ isValidCriteria);
                       
                        if(isValidCriteria){
                           // if ruleid and object exist in objectexecutionaction  creation add to   
                          system.debug('-->actionrecs'+actionrecs);
                            List<SObject> matched = validRecords.get(rule.Id)!=null ? validRecords.get(rule.Id) :new List<SObject>();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          matched.add(o);
                            //store the objects that passed this rule -
                            validRecords.put(rule.Id,matched);
                             
                            //  for(Object_Action_Execution__c action : actions){
                            for(RuleAction__c action : actions){
                       
                                objectaction= o.id;
                                objectaction= objectaction+action.id;
                                String actionObject = action.Related_Object__c.toLowerCase();
                                
                                notifyUser = action.Notify_User__c;
                                templateId=action.Email_Template__c;
                                system.debug('->action obj BULK--> '+actionObject);
                                actionInContext = action; 
                                if(relationshipNames.get(actionObject)!= null || action.Type__c == 'Insert Related Object'  || action.Type__c == 'Upsert Related Object'){
                                      if(action.Type__c == 'Update Field'){ 
                                        //itz a action on the child object:-
                                        SObject[] childRecordsFromParent = toUpdateChildObjects.get(actionObject)!=null? toUpdateChildObjects.get(actionObject):o.getSObjects(relationshipNames.get(actionObject)); //child object
                                        if(childRecordsFromParent!=null){                                       
                                            for (Integer i=0;i<childRecordsFromParent.size();i++){ 
                                                SObject beforeAction = childRecordsFromParent[i];
                                                childRecordsFromParent[i] = applyActions(action,childRecordsFromParent[i]); 
                                                toUpdateSObject.put(childRecordsFromParent[i].Id,childRecordsFromParent[i]);                                
                                                historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,childRecordsFromParent[i],beforeAction,o));
                                            
                                            }
                                            //system.debug('childRecordsFromParent'+childRecordsFromParent);
                                            toUpdateChildObjects.put(actionObject,childRecordsFromParent);
                                        }
                                    } 
                                   
                                    /**
                                    * By Cloud Challenger
                                    * Below Code apply related record info on child
                                    */
                                    else if(action.Type__c == 'Insert Related Object' || action.Type__c == 'Upsert Related Object' ){
                                        
                                   
                                        
                                        system.debug(childParentRelationshipField+'--'+action.Related_Object__c.tolowerCase());
                                        String parentFieldName = childParentRelationshipField.get(action.Related_Object__c.tolowerCase());
                                        /**
                                        * Dynamically create child instance
                                        */
                                        Type t = Type.forName(action.Related_Object__c);
                                        SOBject newObj = (SObject)t.newInstance();
                                       
                                   
                                        if(action.Related_Object__c.tolowerCase()=='task'){
                                            if(o.Id.getSObjectType() == User.SobjectType){
                                                parentFieldName='OwnerId';
                                            }else  if(o.Id.getSObjectType() == Contact.SobjectType || o.Id.getSObjectType() == Lead.SobjectType){
                                                parentFieldName='WhoId';
                                            }else if (o.Id.getSObjectType() != Contact.SobjectType || o.Id.getSObjectType() != Lead.SobjectType){
                                                parentFieldName='WhatId';
                                            }
                                        }
                                       // newObj = updateField(action.Related_Object__c,parentFieldName,o.Id,newObj);
                                          if (parentFieldName!= null ) newObj = AW_ExecutionActionHelper.updateField(action.Related_Object__c,parentFieldName,o.Id,newObj);
                                      
                                        /**
                                        * Apply rest of the fields
                                        */
                                        //childObjectList.add(applyInsertChildActions(action,newObj,o));
                                         newObj = AW_ExecutionActionHelper.applyInsertChildActions(action,newObj,o);
                                        // Cloud Challenger Upsert Changes Start  
                                          if(action.Type__c == 'Upsert Related Object'){
                                                boolean isPresentRec = false;
                                                if(action.External_field_api_name__c != null && newObj.get(action.External_field_api_name__c) != null){
                                                    String query = 'Select id from ' + action.Related_Object__c + ' where ' + action.External_field_api_name__c + '=\'' + newObj.get(action.External_field_api_name__c) + '\'';
                                                    List<SObject> lstSobj = Database.query(query);
                                                    if(lstSobj != null && lstSobj.size() > 0){
                                                        for(Sobject cObj : lstSobj){
                                                            Sobject newCObj = newObj.clone();
                                                            newCObj.id = cObj.id;
                                                            childObjectList.add(newCObj);
                                                            system.debug('newCObj'+newCObj);
                                                            isPresentRec = true;
                                                        }
                                                    }   
                                                }else{
                                                    String parentAPIName = childParentRelationshipField.get(action.Related_Object__c.tolowerCase());
                                                    String query = 'Select id from ' + action.Related_Object__c + ' where ' + parentAPIName + '=\'' + o.id + '\'';                                                  
                                                    List<SObject> lstSobj = Database.query(query);
                                                    if(lstSobj != null && lstSobj.size() > 0){
                                                        for(Sobject cObj : lstSobj){
                                                            Sobject newCObj = newObj.clone();
                                                            newCObj.id = cObj.id;
                                                            childObjectList.add(newCObj);
                                                            isPresentRec = true;
                                                        }
                                                    }   
                                                }
                                                if(!isPresentRec){
                                                    childObjectList.add(newObj);
                                                     historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,newObj,null,o));
                                                
                                                }
                                            }
                                            else{
                                                childObjectList.add(newObj);     
                                                historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,newObj,null,o));      
                                                
                                            }
                                        // 
                                    }
                                   
                                }//end if                                
                                else{
                                    system.debug('---------->482:');
                                    o = applyActions(action,o);
                                    historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,o,oldRecord,o));
                             
                                }
                              // }  //if (actionrecs.get(objectactio                      
                             }//end for  
                             /* updating the code to include advance transactiontamp enhancement */
                            system.debug('-->advWorkflow.Advance_Rule_Stamp__c '+advWorkflow.Advance_Rule_Stamp__c);
                            system.debug('-->recordIds.contains(o.Id) '+ recordIds.contains(o.Id));
                            // if(advWorkflow.Advance_Rule_Stamp__c && recordIds.contains(o.Id)){
                             if(advWorkflow.Advance_Rule_Stamp__c  ){
                                //the update the applied rule id
                                 o.put('awe_rule__c', '/'+rule.id+'~'+rule.name+'~'+transactiontamp.format('MM-dd-yy HH:mm:ss'));
                              } 
                              
                            toUpdateSObject.put(o.Id,o);
                        }
                    }
                    /**
                    * CC: if execution behavour is exit then exit from loop
                    */  
                    if(rule.Execution_Behavior__c == 'Execute Rule and Exit'  && isValidCriteria){
                        break;
                    }
                    
               }
              
                // Start By Cloud Challenger
                /**
                /* Insert child records
                 /* Update Records and Insert child records */ 
            //    List<SObject> recordBeforeUpdate = Database.query(qrySOQL);
                boolean processstatus;
                if(toUpdateSObject.size()>0 || childObjectList.size() >0){
                     processstatus= AW_AdvanceWorkflowTransactionProcessing.performDMLOperations(toUpdateSObject,childObjectList );
                    //finally add that these records are processed in a history object
                   if(advWorkflow.Enable_Execution_History__c){
                             //processstatus= AW_AdvanceWorkflowTransactionProcessing.addRecordstoExecutionHistory(lstValidRules,validRecords,recordBeforeUpdate,toUpdateSObject);
                            //system.debug(historyToInsert);
                             upsert historyToInsert; 
                      }
                }
        
         }//end try
             catch(Exception e){
                throw e;
                system.debug(e);
                String msg = string.valueOf(e);
                List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','isvalid','AW_AdvanceWorkflowExecutionEngine.cls','evaluateRules','Advance_Workflow__c');
                 
            } 
            EvaluationIsRunning=false;//once everything is done mark false          
            
     }
  
   public static void evaluateRulesAsync(Set<Id> ruleIds,Set<Id> recordIds,String sobjectName,String mode){
         
         AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap = new Map<String,Map<String,List<RuleAction__c>>>();
        
         //initialize or clear 
        rulesExecuted = new Map<Id,Set<Id>>();
           AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap = new Map<String,Map<String,List<RuleAction__c>>>();
        
        List<Advance_Workflow__c> workflows  =Database.query('SELECT id,Advance_Rule_Stamp__c ,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjectName+'\' and Enabled__c = true');
        if(workflows.size()==0) return;
        advWorkflow = workflows[0];
         //initialize or clear 
        rulesExecuted = new Map<Id,Set<Id>>();
        childObjectList = new List<SObject>();
        bulkObjectUpdates= new List<Object_Action_Execution__c>();
        toUpdateSObject = new Map<Id,SObject> ();
        relationshipNames = new Map<String,String>();
        boolean isValidCriteria = false;
        try{
       //get the list of criteria for the given set of rule Ids:-
                // Megha - 07/16/2014 - Added boolean for Simulation
                List<Rule__c> rules = AW_AdvanceWorkflowExecutionHelper.getActiveCriteria(ruleIds,sobjectName , (mode == 'Simulation'));
                system.debug('--->rules ASYNC'+rules);   
                EvaluationIsRunning = true; 
                EvaluationRunningFor.add(sobjectName);
                                                              
                List<Rule__c> lstValidRules = getValidRules(rules,sobjectName);
                String ruleIdConcat = '';
                for(Rule__c rule : lstValidRules){
                        ruleIdConcat += rule.id + ',';
                }
                if(ruleIdConcat != ''){  
                    if(ruleIdConcat.endsWith(',')){
                        ruleIdConcat = ruleIdConcat.subString(0, ruleIdConcat.lastIndexOf(','));
                    }
                    for(String rId : recordIds){
                        Object_Action_Execution__c objAction = new Object_Action_Execution__c(Action__c = lstValidRules.get(0).id,  RuleIds__c = ruleIdConcat,Status__c = 'New',Value__c = '',Record_Id__c = rId, Type__c='Async', SobjectType__c = sobjectName);
                        bulkObjectUpdates.add(objAction);
                    }
                    /*for(Rule__c rule : lstValidRules){
                        
                   
                        
                    } */
                    insert  bulkObjectUpdates;
                    System.debug('::::isAsyncProcessRunning'+isAsyncProcessRunning);
                    if(!recordIds.isEmpty() && !isAsyncProcessRunning){ 
                        System.debug('::::'+sobjectName);
                        //AW_AdvanceWorkflowTransactionProcessing.processAsync(sobjectName, mode, recordIds);
                        AW_AdvanceWorkflowExecutionHelper.processAsync(sobjectName, mode, recordIds); 
                        
                    }
                }
          }
       catch(Exception e){
                throw e;
                system.debug(e);
                String msg = string.valueOf(e);
                List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','isvalid','AW_AdvanceWorkflowExecutionEngine.cls','evaluateRules','Advance_Workflow__c');
                 
        } 
        EvaluationIsRunning=false;//once everything is done mark false     
   }
   public static void evaluateRules(Set<Id> ruleIds,Set<Id> recordIds,String sobjectName,String mode){
        
        system.debug('--->EVALUATERULES ruleIds'+ruleIds);  
            
        AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap = new Map<String,Map<String,List<RuleAction__c>>>();
        
         //initialize or clear 
        rulesExecuted = new Map<Id,Set<Id>>();
        childObjectList = new List<SObject>();
        bulkObjectUpdates= new List<Object_Action_Execution__c>();
        toUpdateSObject = new Map<Id,SObject> ();
        relationshipNames = new Map<String,String>();
        boolean isValidCriteria = false;
                    
        
       
          
        //first thing is to check if the rule ids exist (just a validation)
        
        if(ruleIds.size()==0) return; //nothing to process :) 
        userInContext =[Select Id,Name,Profile.Name,UserRole.Name FROM User WHERE Id=:UserInfo.getUserId()];
      
        transactiontamp = Datetime.now(); 
        
            try{
                //get the list of criteria for the given set of rule Ids:-
                // Megha - 07/16/2014 - Added boolean for Simulation
                
                List<Rule__c> rules = AW_AdvanceWorkflowExecutionHelper.getActiveCriteria(ruleIds,sobjectName , (mode == 'Simulation'));
                system.debug('--->rules '+rules);   
                EvaluationIsRunning = true; 
                EvaluationRunningFor.add(sobjectName);
                system.debug('--->rules '+rules);                                               
                   
                
               
                List<Rule__c> lstValidRules = getValidRules(rules,sobjectName);
                 system.debug('---->lstValidRules:' + lstValidRules);
                system.debug('---->criteriaFields:' + criteriaFields);
                if(criteriaFields.size() == 0){
                    return;
                }
               
               
                //update : if bulk get subset of actions
                // Megha - 07/16/2014 - Added boolean for Simulation
                Map<Id,Rule__c> ruleActions = bulkOperation ? AW_AdvanceWorkflowExecutionHelper.getActiveRuleActionsSubset(ruleIds,sobjectName,bulkactionIds, (mode == 'Simulation')) : AW_AdvanceWorkflowExecutionHelper.getActiveRuleActions(ruleIds,sobjectName, (mode == 'Simulation'));  
                system.debug('---->ruleActions:' + ruleActions);
               
                /**
                * By Cloud Challenger
                * Get all the insert related record info of rule
                */
                insertedRelatedRecordInfo = bulkOperation ? AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfoForActions(bulkactionIds): AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfo(ruleIds);
               system.debug('-->insertedRelatedRecordInfo '+ insertedRelatedRecordInfo);
        
              // Cloud Challenger Upsert Changes Start
                Map<Id,RuleAction__c> upsertRelatedRecordInfo = AW_AdvanceWorkflowExecutionHelper.getUpsertRelatedRecordInfo(ruleIds);                  
                if(upsertRelatedRecordInfo.size() > 0){
                    insertedRelatedRecordInfo.putAll(upsertRelatedRecordInfo);
                }
                // Cloud Challenger Upsert Changes End
                
                /** 
                * here the logic is now encapsulated in a method
                * the method first add the valid fields to be updated in the criteria field list
                * also check if the value is a valid object field/reference field so that you cann
                * add it to list to query
                */
                  system.debug('-->ruleActions.values()  '+ruleActions.values() );
                  system.debug('-->sobjectName  '+sobjectName );
                
                AW_ExecutionActionHelper.getValidfields_from_Actions(ruleActions.values(),sobjectName);
                 //Fetch all the information for owner prioritization:@todo in bulkoperation instance
                 system.debug('-->relationshipNames  '+relationshipNames );
                if(!bulkOperation)AW_OwnerPrioritizationHelper.getOwnerPrioritizationRecords(ruleIds);
              
                
                Set<String> parentFields = criteriaFields.get(sobjectName.toLowerCase());      
                system.debug('---->parentFields:' + parentFields);
                 if(parentFields.size()==0  || !parentFields.contains('id'))
                    parentFields.add('id');
                
                if(sobjectName.tolowerCase()!='task' && sobjectName.tolowerCase()!='case' && (parentFields.size()==0 || !parentFields.contains('name')))
                    parentFields.add('name');
                    
                if(sobjectName.tolowerCase()=='task' && (parentFields.size()==0 || !parentFields.contains('subject')))
                    parentFields.add('subject');
                    
                if(sobjectName.tolowerCase()=='case' && (parentFields.size()==0 || !parentFields.contains('casenumber')))
                    parentFields.add('casenumber'); 
                String fields='';
               
                if(sobjectName.tolowerCase()=='task' && parentFields.size()>=0   ) {
                     system.debug('if(sobjectName.tolowerCase()==' );
                     fields=AW_AdvanceWorkflowExecutionHelper.joinSetTask_No_WhoIds(parentFields,',');
                        
                }else
                {
                     fields = AW_AdvanceWorkflowExecutionHelper.joinSet(parentFields,',');
                }
                
                system.debug('-->from joinset Parent fields:' + fields);
                   
                if(fields!=null && fields.trim()!='' && ! fields.contains('id') && mode!='Simulation') fields= fields+', Id ';
                if(fields!=null && fields.trim()!='' && ! fields.contains('id') && mode=='Simulation') fields= fields+', Id  ';
                    
                String fieldswithwhoid='';
                String fields_no_whoid ='';
                         
                String qrySOQL='';
                qrySOQL='SELECT  ' + fields +' ';
                 //now add the child queries also as they need to be evaluated in the query :)
                  
                for(String obj:criteriaFields.keySet()){
                        system.debug('--->obj: forming ' + obj);
                        system.debug('--->sobjectName: forming ' + sobjectName);
                   // if(   obj.equalsIgnoreCase(sobjectName)  && !obj.equalsIgnoreCase('task') ) continue;
                    if(   obj.equalsIgnoreCase(sobjectName)   ) continue;
                    if(obj.equalsIgnoreCase('task')  )
                    { 
                     system.debug('--->joinSetTaskWhoIdsOnly BEFORE fields '+fields );
                     system.debug('--->joinSetTaskWhoIdsOnly BEFORE criteriaFields '+criteriaFields );
                     system.debug('--->AFTER 1 criteriaFields.get(obj):   ' + criteriaFields.get(obj));
                    // fieldswithwhoid='';
                     fieldswithwhoid=AW_AdvanceWorkflowExecutionHelper.joinSetTaskWhoIdsOnly(parentFields, criteriaFields.get(obj),',');
                     system.debug('--->joinSetTaskWhoIdsOnly AFTER fieldswithwhoid:   ' + fieldswithwhoid);
                      system.debug('--->joinSetTaskWhoIdsOnly AFTER object '+obj +' Qryfields '+qrySOQL );
                      //fields=fields +','+fieldswithwhoid;
                     // if(fieldswithwhoid != null && fieldswithwhoid != '')  qrySOQL=qrySOQL+','+fieldswithwhoid+' ';
                       system.debug('--->AFTER 2 criteriaFields.get(obj):   ' + criteriaFields.get(obj));
                      
                   
                      //fields_no_whoid ='';
                      fields_no_whoid=AW_AdvanceWorkflowExecutionHelper.joinSetTask_No_WhoIds(criteriaFields.get(obj),',');
                      system.debug('--->joinSetTask NO WhoIds  AFTER fields_no_whoid:   ' + fields_no_whoid);
                     
                     //status,last_detail__c,description,leadsource,lead_source__c
                     
                      
                     //AFTER fields:   id,last_detail__c,status,name , leadsource
                     
                     } 
                     else  
                     { 
                          system.debug('--->joinSet ELSE BEFORE object '+obj +'   fields '+fields );
                          fields_no_whoid =AW_AdvanceWorkflowExecutionHelper.joinSet(criteriaFields.get(obj),',');
                          system.debug('--->joinSet ELSE AFTER object '+obj +'   fields '+fields_no_whoid );
                    
                     }
                      system.debug('--->fields: forming ' + fields);
                      system.debug('--->fieldswithwhoid:  forming ' + fieldswithwhoid);
                      system.debug('--->fields_no_whoid: forming  ' + fields_no_whoid);
                    
                     // status,last_detail__c,description,leadsource,lead_source__c
                     
                     system.debug('--->relationshipNames: forming ' + relationshipNames);
                     
                      // if(fields!= null && fields != ''){
                       if(fields_no_whoid!= null && fields_no_whoid != ''){
                        if (fields_no_whoid.contains('Id') || fields_no_whoid.contains('id')) 
                        //if (fields.contains('Id') || fields.contains('id')) 
                           qrySOQL+=' , (SELECT  ' + fields_no_whoid +' FROM '+relationshipNames.get(obj)+')';
                          // qrySOQL+=' , (SELECT  ' + fields +' FROM '+relationshipNames.get(obj)+')';
                         else
                           qrySOQL+=' , (SELECT  ' + fields_no_whoid +',Id  FROM '+relationshipNames.get(obj)+')';
                          // qrySOQL+=' , (SELECT  ' + fields +',Id  FROM '+relationshipNames.get(obj)+')';
                       
                         system.debug('--->qrySOQL: forming ' + qrySOQL);
                     }
                }
              
                qrySOQL+=' FROM '+sobjectName+' WHERE Id IN : recordIds';
                system.debug('--->qrySOQL:' + qrySOQL);
                system.debug('--->recordIds:' + recordIds);
                
                List<SObject> sobjectRecords =new  List<SObject>();
                Map<Id,SObject> recordBeforeUpdate = new Map<Id,SObject>(Database.query(qrySOQL));
              
                if (mode!='Simulation') {
                   sobjectRecords = database.query(qrySOQL);  
                   system.debug('->no simulation qrySOQL' +qrySOQL);   
                 // lstSObjectforUpdateSimulation =sobjectRecords;  
                } else {
                      // system.debug('---->AW_SimulateWorkflowCapture.recordinput:' + AW_SimulateWorkflowCapture.recordinput);
                      sobjectRecords.add(AW_SimulateWorkflowCapture.recordinput) ;
                       system.debug('---->AW_SimulateWorkflowCapture.recordinput');
                }
                system.debug('---->sobjectRecords:' + sobjectRecords);
                  
                toUpdateSObject= new Map<Id,SObject>();
                childObjectList = new List<SObject>(); 
                Map<String,List<SObject>> toUpdateChildObjects = new Map<String,List<SObject>>();
                Map<Id,List<SObject>> validRecords= new Map<Id,List<SObject>>();
                 
                /* defining variables to handle the send email action */
                Map<String,Map<String,List<RuleAction__c>>> usersInSendEmailAction =new Map<String,Map<String,List<RuleAction__c>>> ();
                Map<String,Map<String,List<RuleAction__c>>> grpsInSendEmailAction = new Map<String,Map<String,List<RuleAction__c>>> ();
                
 
                         
                /**
                * Instead of iterating to the map, iterate to the list just to maintain the order of rules
                */
                for(Rule__c rule : lstValidRules){
                     
                    Rule__c r = ruleActions.get(rule.Id);
                    system.debug('r--->'+r);
                    if(r.Rule_Actions__r.size()==0) continue;
                  
                    //for every sobject record that matched the rule we need to apply the action
                    List<RuleAction__c> actions= r.Rule_Actions__r;
                   // boolean isValidCriteria = false;
                    
                             
                    
                    for(SObject o:sobjectRecords) {
                        SObject oldRecord = recordBeforeUpdate.get((String)o.get('id'));
                        
                         system.debug('o--->'+o);
                        //if(rule.Evaluation_Rule__c.equals('Record is created or edited and did not previously meet the rule criteria')){
                            //if(rulesExecuted.get(o.Id)!=null &&  rulesExecuted.get(o.Id).contains(rule.Id)){
                            //    continue;
                            //}
                            
                            //we will use thsi block later of new evaluation :Record created/edited rule triggered once when criteria met
                            
                        //}
                        system.debug('---Record---'+o);
                     //314  isValidCriteria = bulkOperation ? true : evaluateSingleRule(rule,o,sobjectName,mode);
                        isValidCriteria =  evaluateSingleRule(rule,o,sobjectName,mode);
                         system.debug( ' Have Criteria for Rule: '+r.Name+ ' Met '+ isValidCriteria);
                       //system.debug('Have Criteria for Rule Met '+ isValidCriteria);
                         if(isValidCriteria){
                            
                            /* adding a block for click event handling */
                            if(rule.Evaluation_Rule__c.equalsIgnoreCase('On Click Event')){
                                displayClickEventValidRules.add(r);
                                break;
                            }
                            validRuleIds.add(rule.id);
                            List<SObject> matched = validRecords.get(rule.Id)!=null ? validRecords.get(rule.Id) :new List<SObject>();
                            matched.add(o);
                            //store the objects that passed this rule -
                            validRecords.put(rule.Id,matched);
                            system.debug('-->LOOP ACTIONS '+actions);
                            for(RuleAction__c action : actions){
                                String actionObject = action.Related_Object__c.toLowerCase();
                                notifyUser = action.Notify_User__c;
                                templateId=action.Email_Template__c;
                                system.debug('-->action obj-->'+actionObject);
                                actionInContext = action; 
                               if(action.Type__c == 'Send Email'){ 
                                    //sending email :-
                                    Id sendTo = action.User_Owner_Id__c !=null ? Id.valueof(action.User_Owner_Id__c):UserInfo.getUserId();
                                    //now that we have the user ids that need to be sent email:-
                                    //temp replace the merge field in the action additional email field
                                    //List<String> emails = action.additional_email__c!=null?action.additional_email__c.split(','):new List<String>();
                                    if(action.additional_emails__c!=null){
                                        action.additional_emails__c = AW_FormulaExpressionHelper.doMerge(action,action.additional_emails__c.replaceAll(',','&'),o);
                                        action.additional_emails__c = action.additional_emails__c.replaceAll(' ',',');
                                    }
                                      //temp replace the merge field in the action additional email field
                                    //List<String> emails = action.additional_email__c!=null?action.additional_email__c.split(','):new List<String>();
                                    if(action.additional_emails__c!=null){
                                        action.additional_emails__c = AW_FormulaExpressionHelper.doMerge(action,action.additional_emails__c.replaceAll(',','&'),o);
                                        action.additional_emails__c = action.additional_emails__c.replaceAll(' ',',');
                                    }
                                    if(sendTo.getSObjectType() == User.SobjectType ){
                                        //usersInSendEmailAction=AW_AdvanceWorkflowExecutionHelper.buildListForEmail(usersInSendEmailAction,sendTo,templateId,o.Id);                                       
                                        usersInSendEmailAction=AW_AdvanceWorkflowExecutionHelper.buildListForEmail(usersInSendEmailAction,sendTo,action,o.Id);
                                    }else if(sendTo.getSObjectType() == Group.SobjectType){
                                        //grpsInSendEmailAction=AW_AdvanceWorkflowExecutionHelper.buildListForEmail(grpsInSendEmailAction,sendTo,templateId,o.Id);
                                        grpsInSendEmailAction=AW_AdvanceWorkflowExecutionHelper.buildListForEmail(grpsInSendEmailAction,sendTo,action,o.Id);
                                    }
                                    
                                    //If the action has additional emails that need to be sent
                                    
                                }else if(action.Type__c.equalsIgnoreCase('Execute an Apex Job')){
                                        //execute apex class:- instantiate a class
                                        
                                         String namespace = '';
                                        String className = '';
                                        if(action.Apex_job_Class__c.contains('#')){
                                            List<String> lstClassParts = action.Apex_job_Class__c.split('#');
                                            namespace = lstClassParts[0];
                                            className = lstClassParts[1];
                                        }
                                        else
                                        {
                                            className = action.Apex_job_Class__c;
                                        }
                                        //execute apex class:- instantiate a class
                                        Type t = Type.forName(namespace,className);
                                        AW_RuleActionInterface job = (AW_RuleActionInterface)t.newInstance();
                                         
                                        //Type t = Type.forName(action.Apex_job_Class__c);
                                       // AW_RuleActionInterface job = (AW_RuleActionInterface)t.newInstance();
                                        
                                        //get the input parameter map:-
                                        Map<String,String> inputParams = AW_ExecutionActionHelper.apex_execution_params(action,action.input_parameters__c,o);
                                        Map<String,String> outputParams = job.runAction(inputParams);
                                         
                                        //here finally dump the result of execution :-
                                        AW_ExecutionActionHelper.apex_execution_outputupdate(action,outputParams,o);
                                        historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,o,oldRecord,o));
                                          
                                        continue;
                                } 
                                else if(action.Type__c.equalsIgnoreCase('Apex Callout-HTTP')){                                  
                                    //set up http call out:
                                    if(bulkOperation){ 
                                         Map<String,String> inputParams = AW_ExecutionActionHelper.apex_execution_params(action,action.input_parameters__c,o);
                                          //call helper method to do the callout:-
                                          AW_AdvanceWorkflowHTTPHandler httpHandle = new AW_AdvanceWorkflowHTTPHandler();
                                          Map<String,String> outputParams = httpHandle.doHTTPCallout(action,inputParams); 
                                          AW_ExecutionActionHelper.apex_execution_outputupdate(action,outputParams,o); 
                                    }else 
                                    AW_AdvanceWorkflowHTTPHandler.setHTTPCallout(action.id,o.Id);   
                                }                                
                                 else if(relationshipNames.get(actionObject)!= null || action.Type__c == 'Insert Related Object'  || action.Type__c == 'Upsert Related Object' ||
                                    action.Type__c == 'Insert Unrelated Object'  || action.Type__c == 'Upsert Unrelated Object'){
                                      if(action.Type__c == 'Update Field'){  
                                        //itz a action on the child object:-
                    /*     New Code BEGINS for updating  5000 records of child objects like contacts issue*/
             /*
                    if(toUpdateChildObjects.get(actionObject)!=null){
    List<Sobject> childRecordsFromParent = new List<Sobject>();
    for(SObject child: toUpdateChildObjects.get(actionObject)){
        child = applyActions(action,child); 
        toUpdateSObject.put(child.Id,child);
        childRecordsFromParent.add(child);
    }
    //system.debug('childRecordsFromParent'+childRecordsFromParent);
    toUpdateChildObjects.put(actionObject,childRecordsFromParent);
}
else{
    List<Sobject> childRecordsFromParent = new List<Sobject>();
    for(SObject child: o.getSObjects(relationshipNames.get(actionObject))){
        child = applyActions(action,child); 
        toUpdateSObject.put(child.Id,child);
        childRecordsFromParent.add(child);
    }
    //system.debug('childRecordsFromParent'+childRecordsFromParent);
    toUpdateChildObjects.put(actionObject,childRecordsFromParent);
}
                  //  New Code ENDS
           */          
                      
                    /*5000 contacts issue
                   */ 
                 
                                       System.debug('--->toUpdateChildObjects.get(actionObject)!=null: 817:' + toUpdateChildObjects.get(actionObject)!=null);
                                        SObject[] childRecordsFromParent = toUpdateChildObjects.get(actionObject)!=null? toUpdateChildObjects.get(actionObject):o.getSObjects(relationshipNames.get(actionObject)); //child object
                                         system.debug('--->childRecordsFromParent'+childRecordsFromParent);
                                           
                                        if(childRecordsFromParent!=null){                                       
                                            for (Integer i=0;i<childRecordsFromParent.size();i++){ 
                                                childRecordsFromParent[i] = applyActions(action,childRecordsFromParent[i]); 
                                                system.debug('-->child-action.Bulk_api__c-->'+action.Bulk_api__c);
                                                 system.debug('-->child-bulkOperation  -->'+bulkOperation);
                                                  if(!action.Bulk_Api__c && !bulkOperation){
                                                     toUpdateSObject.put(childRecordsFromParent[i].Id,childRecordsFromParent[i]); 
                                                 }                                 
                                            }
                                            //system.debug('childRecordsFromParent'+childRecordsFromParent);
                                              if(!action.Bulk_Api__c && !bulkOperation){
                                                   toUpdateChildObjects.put(actionObject,childRecordsFromParent);
                                              }   
                                        }
                                    } 
                                   
                                    /**
                                    * By Cloud Challenger
                                    * Below Code apply related record info on child
                                    */
                                   else if(action.Type__c == 'Insert Related Object' || action.Type__c == 'Upsert Related Object' ||
                                        action.Type__c == 'Insert Unrelated Object'  || action.Type__c == 'Upsert Unrelated Object'){
                                         if(action.Bulk_Api__c && !bulkOperation){
                                            //314 bulkObjectUpdates.add(new Object_Action_Execution__c(Action__c=action.Id,Status__c='New',Value__c='',Type__c='Bulk API'));
                                                  bulkObjectUpdates.add(new Object_Action_Execution__c(Action__c=action.Id,Status__c='New',Value__c='',Record_Id__c=o.Id,Type__c='Bulk API'));
                                           
                                       
                                            continue;
                                        }
                                        
                                        system.debug('childParentRelationshipField--> '+childParentRelationshipField+'--'+action.Related_Object__c.tolowerCase());
                                        String parentFieldName = childParentRelationshipField.get(action.Related_Object__c.tolowerCase());
                                        /**
                                        * Dynamically create child instance
                                        */
                                        Type t = Type.forName(action.Related_Object__c);
                                        SOBject newObj = (SObject)t.newInstance();
                                       
                                         /**
                                        * Populate parentField on Child
                                        */
                                        
                                        if(action.Related_Object__c.tolowerCase()=='task'){
                                            if(o.Id.getSObjectType() == User.SobjectType){
                                                parentFieldName='OwnerId';
                                            }else  if(o.Id.getSObjectType() == Contact.SobjectType || o.Id.getSObjectType() == Lead.SobjectType){
                                                parentFieldName='WhoId';
                                            }else if(o.Id.getSObjectType() != Contact.SobjectType || o.Id.getSObjectType() != Lead.SobjectType){
                                                parentFieldName='WhatId';
                                            }
                                             
                                        }
                                        
                                         // newObj = updateField(action.Related_Object__c,parentFieldName,o.Id,newObj);
                                           if (parentFieldName!= null && !(action.Type__c == 'Insert Unrelated Object' || action.Type__c == 'Upsert Unrelated Object')) newObj = AW_ExecutionActionHelper.updateField(action.Related_Object__c,parentFieldName,o.Id,newObj);
                                         
                                        /**
                                        * Apply rest of the fields
                                        */
                                        //childObjectList.add(applyInsertChildActions(action,newObj,o));
                                         newObj = AW_ExecutionActionHelper.applyInsertChildActions(action,newObj,o);
                                         system.debug('-->newobj'+newobj);
                                        // Cloud Challenger Upsert Changes Start  
                                           if(action.Type__c == 'Upsert Related Object' || action.Type__c == 'Upsert Unrelated Object'){
                                              boolean isPresentRec = false;
                                                if(action.External_field_api_name__c != null && newObj.get(action.External_field_api_name__c) != null){
                                                    // Megha 
                                                    String fieldSet;
                                                    if(mode == 'Simulation' && insertedRelatedRecordInfo.containsKey(action.id)){
                                                        fieldSet = AW_SimulationExecution.getUpsertFields(insertedRelatedRecordInfo.get(action.id));
                                                        
                                                    }
                                                    String query = 'Select id ' +(fieldSet != null && fieldSet.length() > 0 ? ', ' + fieldSet : '') + ' from ' + action.Related_Object__c + ' where ' + action.External_field_api_name__c + '=\'' + newObj.get(action.External_field_api_name__c) + '\'';
                                                    List<SObject> lstSobj = Database.query(query);
                                                    if(lstSobj != null && lstSobj.size() > 0){
                                                        for(Sobject cObj : lstSobj){
                                                            Sobject newCObj = newObj.clone();
                                                            newCObj.id = cObj.id;
                                                            childObjectList.add(newCObj);
                                                            system.debug('newCObj'+newCObj); 
                                                            //Megha
                                                            if(mode == 'Simulation' && AW_SimulationExecution.mapUpsertBeforeSobjects != null){
                                                                AW_SimulationExecution.mapUpsertBeforeSobjects.put(action.id+'~Before', cObj);
                                                                AW_SimulationExecution.mapUpsertBeforeSobjects.put(action.id+'~After', newCObj);
                                                            }
                                                            isPresentRec = true;
                                                        }
                                                    }   
                                                }else{
                                                    String parentAPIName = childParentRelationshipField.get(action.Related_Object__c.tolowerCase());
                                                    if(!(action.Type__c == 'Insert Unrelated Object' || action.Type__c == 'Upsert Unrelated Object')){
                                                        String fieldSet;
                                                        if(mode == 'Simulation' && insertedRelatedRecordInfo.containsKey(action.id)){
                                                            fieldSet = AW_SimulationExecution.getUpsertFields(insertedRelatedRecordInfo.get(action.id));
                                                        
                                                        }
                                                        String query = 'Select id ' +(fieldSet != null && fieldSet.length() > 0 ? ', ' + fieldSet : '')  +' from ' + action.Related_Object__c + ' where ' + parentAPIName + '=\'' + o.id + '\'';                                                    
                                                        List<SObject> lstSobj = Database.query(query);
                                                    //    system.debug('******query:' + query);
                                                    //  system.debug('$$$$$$$:' + lstSobj);
                                                            if(lstSobj != null && lstSobj.size() > 0){
                                                                for(Sobject cObj : lstSobj){
                                                                   Sobject newCObj = newObj.clone();
                                                                   newCObj.id = cObj.id;
                                                                   childObjectList.add(newCObj);
                                                                   isPresentRec = true;
                                                                   if(mode == 'Simulation' && AW_SimulationExecution.mapUpsertBeforeSobjects != null){
                                                                        AW_SimulationExecution.mapUpsertBeforeSobjects.put(action.id +'~Before', newObj);
                                                                    }
                                                               }
                                                         }
                                                    }        
                                                }
                                               // system.debug('$$$$$$$:isPresentRec ' + isPresentRec);
                                                      
                                                if(!isPresentRec){
                                                    if(mode == 'Simulation' && AW_SimulationExecution.mapUpsertBeforeSobjects != null){
                                                        AW_SimulationExecution.mapUpsertBeforeSobjects.put(action.id +'~After', newObj);
                                                    }
                                                        childObjectList.add(newObj);
                                                        historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,newObj,null,o));
                                                     }
                                            }
                                            else{
                                                if(mode == 'Simulation' && AW_SimulationExecution.mapUpsertBeforeSobjects != null){
                                                    AW_SimulationExecution.mapUpsertBeforeSobjects.put(action.id +'~After', newObj);
                                                }
                                                      childObjectList.add(newObj); 
                                                      system.debug('rule '+rule);
                                                      system.debug('newobj '+newobj);
                                                      system.debug('o '+o);
                                                       
                                                      historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,newObj,null,o));      
                                              
                                            }
                                        // 
                                    }
                                   
                                }//end if                                
                                else{
                                    o = applyActions(action,o);
                                    
                                    system.debug('-->action.Bulk_api__c   ' +action.Bulk_api__c);
                                    system.debug('-->bulkOperation   ' +bulkOperation);
                                    if (!action.Bulk_api__c && !bulkOperation ){
                                         historyToInsert.add(AW_AdvanceWorkflowTransactionProcessing.createHistoryInstance(transactiontamp,rule,o,oldRecord,o));
                                    }
                                }
                             }//end for  
                            /* updating the code to include advance transactiontamp enhancement */
                           // system.debug('-->advWorkflow.Advance_Rule_Stamp__c '+advWorkflow.Advance_Rule_Stamp__c);
                            system.debug('-->recordIds.contains(o.Id) '+ recordIds.contains(o.Id));
                             if(advWorkflow != null && advWorkflow.Advance_Rule_Stamp__c && recordIds.contains(o.Id)){
                                //the update the applied rule id
                                //o.put('awe_rule__c', '/'+rule.id+'~'+rule.name+'~'+Datetime.now().format('MMddyy HH:mm:ss'));
                                o.put('awe_rule__c', '/'+rule.id+'~'+rule.name+'~'+transactiontamp.format('MM-dd-yy HH:mm:ss'));
                            }  
                               
                            toUpdateSObject.put(o.Id,o);
                        }
                    }
                    /**
                    * CC: if execution behavour is exit then exit from loop
                    */  
                    if(rule.Execution_Behavior__c == 'Execute Rule and Exit'  && isValidCriteria){
                        break;
                    }
                     
                    
                }           
 
              
                
                  
                // Start By Cloud Challenger
                /**
                * Insert child records
                */ 
                
           //HEREPGB
            boolean processstatus;
           if (mode=='Simulation' ) {
                system.debug('-->Simulation toUpdateSObject' + toUpdateSObject);
                system.debug('-->Simulation childObjectList' + childObjectList);
            //  if(toUpdateSObject.size()>0 || childObjectLiisValidCriteriast.size() >0)           
             if(toUpdateSObject.size()>0 || childObjectList.size() >0)           
                   processstatus= AW_SimulationExecution.performSimulationOperations(toUpdateSObject,childObjectList,isValidCriteria);
            
            
            }
            else { 
                
               //no longer needed ?? List<SObject> recordBeforeUpdate = Database.query(qrySOQL);
                
                   /** Update Records and Insert child records */ 
                
                system.debug('-->childObjectList'+childObjectList);
                if(toUpdateSObject.size()>0 || childObjectList.size() >0) {
                     processstatus= AW_AdvanceWorkflowTransactionProcessing.performDMLOperations(toUpdateSObject,childObjectList );
                    //finally add that these records are processed in a history object
                      if(advWorkflow.Enable_Execution_History__c){
                            //processstatus= AW_AdvanceWorkflowTransactionProcessing.addRecordstoExecutionHistory(timestamp,lstValidRules,validRecords,recordBeforeUpdate,toUpdateSObject);
                            //system.debug(historyToInsert);
                             upsert historyToInsert; 
                      }
               
                }
                
                system.debug('-->bulkObjectUpdates'+bulkObjectUpdates);
            
                /** Insert records for lookupObjectProcessing & bulk processing **/
                if(bulkObjectUpdates.size()>0 && !bulkOperation)
                     AW_AdvanceWorkflowTransactionProcessing.processLookupUpdatesAndBulkAPi(bulkObjectUpdates,mode);
                
                
                if(AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap!=null && AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.size()>0){
                         Map<Id,User> userDetails = AW_AdvanceWorkflowExecutionHelper.getUserDetails(AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.keySet());
                         new AW_SendEmailUtil().sendEmail(userDetails ,AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap);
               }
                 
               if(grpsInSendEmailAction!=null & grpsInSendEmailAction.size()>0){
                    //get the list of users in that group:-
                    List<Group> grps =[Select Id,(Select UserOrGroupId FROM GroupMembers) FROM Group WHERE Id IN:grpsInSendEmailAction.keySet()];
                    
                    for(Group g:grps){
                         for(GroupMember gm:g.GroupMembers){
                                for( String objId : grpsInSendEmailAction.get(g.Id).keySet()){
                                        
                                       for(RuleAction__c template :  grpsInSendEmailAction.get(g.Id).get(objId)){
                                            usersInSendEmailAction= AW_AdvanceWorkflowExecutionHelper.buildListForEmail(usersInSendEmailAction, gm.UserOrGroupId, template,objId);
                                       }  
                                        
                                }
                         }
                    }
                    
               }
               
               //finally sending emails :-
               if(usersInSendEmailAction!=null &&   usersInSendEmailAction.size()>0){
                      Map<Id,User> userDetails = AW_AdvanceWorkflowExecutionHelper.getUserDetails(usersInSendEmailAction.keySet());
                      new AW_SendEmailUtil().sendEmail(userDetails ,usersInSendEmailAction);
               }                             
            } //PGBHERE
                if(!sobjectRecords.isEmpty() && isASyncProcessRunning){
                    update sobjectRecords;
                }  
            }//end try
             catch(Exception e){
                throw e;
                system.debug(e);
                String msg = string.valueOf(e);
                List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','isvalid','AW_AdvanceWorkflowExecutionEngine.cls','evaluateRules','Advance_Workflow__c');
                 
            } 
            EvaluationIsRunning=false;//once everything is done mark false          
        }        
        
        /**
        * this method checks that rules are valid before executing them
        */
        private static List<Rule__c> getValidRules(List<Rule__c> rules ,String sobjectName){
             system.debug('--->getValidRules '+sobjectName); 
            gd = Schema.getGlobalDescribe(); 
             
            Schema.DescribeSObjectResult R =gd.get(sobjectName).getDescribe();
             
            objectLabels.put(sobjectName,R.getLabel());
             
            //check which of these criteria are valid which needs to be ignored
            fieldMap = new Map<String,Map<String,Schema.SObjectField>>();
            fieldMap.put(sobjectName.toLowerCase(),R.fields.getMap());
             
            /* Rules can have criteria from its related object also */
            Set<String> objectDefinedInCriteria = new Set<String>();
            for (Integer i=0;i<rules.size();i++){
                for(RuleCriteria__c criteria : rules[i].Rule_Criteria__r){
                    if(!objectDefinedInCriteria.contains(criteria.Related_Object__c.toLowerCase())){
                        objectDefinedInCriteria.add(criteria.Related_Object__c.toLowerCase());      
                    }
                } 
            }
           
            /* get all the related child objects for this object of the rule */
            for(Schema.ChildRelationship child: R.getChildRelationships()){
                Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                String objname =descRes.getName().toLowerCase();
                if(objname.equalsIgnoreCase(sobjectName))continue;
                if(objectDefinedInCriteria.contains(objname)){     
                    relationshipNames.put(objname,child.getRelationshipName());
                    fieldMap.put(objname,descRes.fields.getMap());
                }
            }
            criteriaFields = new Map<String,Set<String>>();
            Boolean isValid=true;
             
            //Map<Id,Rule__c> validRules = new Map<Id,Rule__c>();
            List<Rule__c> lstValidRules = new List<Rule__c>();
             
            /* ow starts the validation process*/
            for (Integer i=0;i<rules.size();i++){
                //under that rule check for criteria :-   
                isValid = true; 
                /**
                * all the field defined in the criteria are now checked that they
                * are valid fields either the field belongs to the parent field
                * or child objects
                * Also here we will then build the list of the fields 
                * that are involved
                */         
                for(RuleCriteria__c criteria : rules[i].Rule_Criteria__r){
                    /*Map<String,Schema.SObjectField> fieldList = fieldMap.get(criteria.Related_Object__c.toLowerCase());
                    if(fieldList!=null && (fieldList.containsKey(criteria.Field_API_Name__c)==true ||  fieldMap.containsKey(criteria.Field_API_Name__c.toLowerCase())==true)){
                        Set<String> fieldToAdd = criteriaFields.get(criteria.Related_Object__c.toLowerCase())!=null ? criteriaFields.get(criteria.Related_Object__c.toLowerCase()): new Set<String>(); 
                        fieldToAdd.add(criteria.Field_API_Name__c.toLowerCase());
                        criteriaFields.put(criteria.Related_Object__c.toLowerCase(),fieldToAdd);
                    }
                    else {                                                                     
                        isValid=false;//remove the rule if that field name isn't a valid field on sobject
                        break;
                    } */
                    
                    Map<String,Schema.SObjectField> fieldList = fieldMap.get(criteria.Related_Object__c.toLowerCase());                    
                     if(fieldList!=null){
                         Set<String> fieldToAdd = criteriaFields.get(criteria.Related_Object__c.toLowerCase())!=null ? criteriaFields.get(criteria.Related_Object__c.toLowerCase()): new Set<String>(); 
                         if(criteria.Field_API_Name__c.toLowerCase() =='crossformula') fieldToAdd.add(criteria.CrossFormula__c.toLowerCase());
                         else if(criteria.Field_API_Name__c.startsWithIgnoreCase('globalvariable-')){}                       
                              else if(fieldList.containsKey(criteria.Field_API_Name__c)==true ||  fieldMap.containsKey(criteria.Field_API_Name__c.toLowerCase())==true){
                             fieldToAdd.add(criteria.Field_API_Name__c.toLowerCase());
                             
                             // Criteria Merge Field Changes
                             // Start
                             if(criteria.Matching_Value__c != null && criteria.Matching_Value__c.startsWith('{!')){
                                String field = criteria.Matching_Value__c.substringBetween('{!','}');
                                if(field != null){
                                    field = field.trim();
                                    if(fieldList.containsKey(field) ||  fieldMap.containsKey(field.toLowerCase())){
                                        fieldToAdd.add(field.toLowerCase());
                                    }
                                }
                             }
                             if(criteria.Field_API_Name__c.equalsIgnoreCase('OwnerId')){
                                fieldToAdd.add('Owner.Name');
                             } 
                             //End
                         }
                         else {
                             isValid=false;//remove the rule if that field name isn't a valid field on sobject
                             break;
                         }
                         criteriaFields.put(criteria.Related_Object__c.toLowerCase(),fieldToAdd);
                     }else {                                                                     
                        isValid=false;//remove the rule if that field name isn't a valid field on sobject
                        break;
                    }    
                                  
                }//end of criteria loop
                if (isValid){
                    lstValidRules.add(rules[i]);
                }
            }
            return  lstValidRules;
        }
        /*
          this method evaluates a single rule on the object
        */
         private static Boolean evaluateSingleRule(Rule__c rule,SObject obj,string sobjectName, String mode){
             
            //IN MAP STORE THE BOOLEAN RESULT
            Map<Integer,Integer> evaluationResult= new Map<Integer,Integer>();
            Integer i=1;
            //system.debug('--->'+obj);
            Boolean evaluateRule = true;
              
            Map<String,Schema.SObjectField> ruleObjfieldMap = fieldMap.get(rule.Object__c.toLowerCase());
          
            if(isUpdate  && rule.Evaluation_Rule__c.equals('Record is created or edited and did not previously meet the rule criteria')){
                evaluateRule =false;
                if(oldListMap != null && oldListMap.size()>0 && oldListMap.get(obj.Id)!=null){
                   SOBject so= oldListMap.get(obj.Id);
                   for(RuleCriteria__c criteria: rule.Rule_Criteria__r){
                        /* For cross formula fields the evaluation created or edited and did not previously meet does not work 
                           cross formula fields are located in other objects and we do not have a way to trap the change*/
                            
                        if(criteria.Field_API_Name__c.equalsIgnoreCase('crossformula') || 
                            !(ruleObjfieldMap != null && ruleObjfieldMap.containsKey(criteria.Field_API_Name__c))){
                            continue;
                        }
                        if(so.get(criteria.Field_API_Name__c) != obj.get(criteria.Field_API_Name__c)){
                            evaluateRule = true;
                            break;
                        }
                   } 
                }           
            }
            
            if(!evaluateRule ) return false; 
            
            for(RuleCriteria__c cr :rule.Rule_Criteria__r){
                
                cr=AW_FormulaExpressionHelper.resolveCriteriaFormulaExpressions(cr);
                  
                String fieldname=cr.Field_API_Name__c; 
                String fieldtype=cr.Field_Type__c.toLowerCase();
                String comparisonValue = cr.Matching_Value__c;
                //criteria is on object
                String cobj = cr.Related_Object__c.toLowerCase();
                 system.debug('--->'+cobj);
                 
                Boolean result=false;
                
                /*
                    if the criteria object is the child object then evaluate the criteria 
                    against all the child records and if all the child records
                    match the criteria then criteria is evaluated as true
                */ 
                 SOBject so= oldListMap.get(obj.Id);
                 if(relationshipNames.get(cobj)!=null && !cobj.equalsIgnoreCase(sobjectName)){
                    //then we need to evaluate the child object in the criteria
                    SObject[] childRecordsFromParent = obj.getSObjects(relationshipNames.get(cobj)); //child object
                    
                    if(childRecordsFromParent==null || childRecordsFromParent.size()==0){
                        if(cr.Evaluate_Criteria_Result_To__c=='True - If no child record found')
                            result=true;                        
                    }
                    else
                    if(childRecordsFromParent!=null){
                        for (SObject childRecord : childRecordsFromParent){                           
                             //adding cross formula
                            String recordFieldValue = fieldname=='CrossFormula' ? AW_FormulaExpressionHelper.getCrossFormulaValue(childRecord,cr.CrossFormula__c):string.valueOf(childRecord.get(fieldname));
                              //for child records we do not consider IsChanged & IsChangedFromTo                         
                            result = AW_CriteriaEvaluationComparisonHelper.doComparison(recordFieldValue,comparisonValue,fieldtype,cr);
                            if(cr.Evaluate_ChildCriteria_Using__c=='AND' && result==false)break;//if any record does not match for and
                            if(cr.Evaluate_ChildCriteria_Using__c=='OR' && result==true)break; //if any record does not match for or
                        }
                    }
                 
                 }else{             
                    String recordFieldValue;
                    system.debug('--->obj '+obj);
                  if(!fieldname.startsWithIgnoreCase('GlobalVariable') && !fieldName.equalsIgnoreCase('OwnerName'))
                        recordFieldValue =  fieldname=='CrossFormula' ? AW_FormulaExpressionHelper.getCrossFormulaValue(obj,cr.CrossFormula__c): string.valueOf(obj.get(fieldname));                   
                    else if(fieldname.startsWithIgnoreCase('GlobalVariable')){
                        String var = fieldname.split('-')[1];
                        if(var=='User')
                            recordFieldValue = userInContext.Name;
                        if(var=='Profile')
                            recordFieldValue=userInContext.profile.name;
                        else if(var=='UserRole')
                            recordFieldValue=userInContext.UserRole.Name;
                        else if(var=='Organization'){
                            recordFieldValue =  UserInfo.getOrganizationName();
                        }
                   }
                    if(fieldname.equalsIgnoreCase('OwnerName')){
                        try{
                            Id value = Id.valueOf(comparisonValue);
                            comparisonValue = value;
                        }
                        catch(Exception ex){
                            recordFieldValue = (String)obj.getSobject('Owner').get('Name');
                        }
                        
                   }
                   system.debug('recordFieldValue-->'+recordFieldValue);
                     result = AW_CriteriaEvaluationComparisonHelper.doComparison(recordFieldValue,comparisonValue,fieldtype,cr);
                   
                   // Cloud Challenger
                   // Megha Add method for Simulation
                   if(cr.Matching_Type__c == 'IsChanged'){
                        if(mode == 'Simulation'){
                         result = AW_CriteriaEvaluationComparisonHelper.isChanged_onSimulation(fieldname, obj, so);
                        }else{
                         result = AW_CriteriaEvaluationComparisonHelper.isChanged(obj.Id,fieldname);
                        }
                    }
                    else if(cr.Matching_Type__c == 'ChangedFromTo'){
                        if(mode == 'Simulation'){
                         result = AW_CriteriaEvaluationComparisonHelper.isChangedFromTo_OnSimulation(cr, (String)obj.get(cr.Field_API_Name__c), ( so != null ? (String)so.get(cr.Field_API_Name__c) : null));
                        }else{
                         result = AW_CriteriaEvaluationComparisonHelper.isChangedFromTo(obj.Id,cr);   
                        }
                    } 
                    else{ 
                        result = AW_CriteriaEvaluationComparisonHelper.doComparison(recordFieldValue,comparisonValue,fieldtype,cr);
                    }
                            
               }                                                              
                 Integer res = result ? 1:0;
                 evaluationResult.put(i,res); i++;   //dump the result for later stage                           
             }
             
            //finally apply the filter logic:-
             
            /*
               if the user has not defined the filter logic then we need to
               add all the criteria
            */
            if(rule.Filter_Logic__c==null){
                Set<String> criteriaLogic = new Set<String>();
                for(Integer j=1;j<=rule.Total_Criteria__c;j++)
                    criteriaLogic.add(string.valueof(j));
                
                rule.Filter_Logic__c = AW_AdvanceWorkflowExecutionHelper.joinSet(criteriaLogic,'and') ;                       
            }
            AW_ExpressionEvaluation_Helper evaluate = new AW_ExpressionEvaluation_Helper();
            return evaluate.evaluateExpression(rule.Filter_Logic__c,evaluationResult);
        } 
     
    
   
                 
    /* apply a action - helper */
    private static SObject applyActions(RuleAction__c action,SObject o){
        SObject o1 =  action.Field_Name__c=='CrossObject' &&  !action.CrossObjectField__c.startsWithIgnoreCase('What') ? o.getSObject(action.CrossObjectField__c.split('\\.')[0]): o;
        
        system.debug('--->applyActions action-->'+action);
        system.debug('--->applyActions record -->'+o);
        system.debug('--->applyActions record o1 -->'+o1);
          
        if(o1!=null && action.Type__c == 'Update Field'){
            system.debug('applyActions action-->'+action);
            
            //8-12-13 SH bug fix - to use most recent instance of the object for update
            o1= toUpdateSObject.get(String.valueof(o1.get('id'))) ==null?
                o1 : toUpdateSObject.get(String.valueof(o1.get('id')));
            
            String value = AW_AdvanceWorkflowExecutionHelper.getValueForUpdateAction(action);
            String fieldToUpdate = action.Field_Name__c=='CrossObject' ? action.CrossObjectField__c.split('\\.')[1] :action.Field_Name__c;
                         
            if(value!=null) value = AW_FormulaExpressionHelper.resolveValueFetched (action,value,o,fieldMap);       
             system.debug('-->1fieldToUpdate  -->'+fieldToUpdate);
             system.debug('-->2action.Bulk_api__c-->'+action.Bulk_api__c);
             system.debug('-->3action.Field_Name__c  -->'+action.Field_Name__c);
             system.debug('-->4fieldToUpdate  -->'+fieldToUpdate);
             system.debug('-->5value -->'+value);
             system.debug('-->6bulkOperation  -->'+bulkOperation);
        
        
       
           
           if(action.Field_Name__c=='CrossObject' && action.CrossObjectField__c.startsWithIgnoreCase('What')){
                //get the what id from task & update the parent:-
                SObject taskObj = Database.query('Select WhatId,Whoid FROM Task WHERE Id =\''+String.valueof(o1.get('id'))+'\'');   
                system.debug('-->SObject  ' +taskObj);
                //once task object if fetched
                String whatid= String.valueOf(taskObj.get('WhatId'));
                system.debug('-->SObject.whatid  ' +whatid);
                String whoid= String.valueOf(taskObj.get('WhoId'));
                system.debug('-->SObject.whoid  ' +whoid);
                
                //finnaly get the parent object & field update will then be spl
                if (whatid!=null)  
                   o1 = toUpdateSObject.get(whatid);
                else o1 = toUpdateSObject.get(whoid);
                
                 
                
                if(o1==null){
                    //now get the sobject:-
                    //  o1 =Database.query('Select '+fieldToUpdate+' FROM '+String.valueof(Id.valueOf(whoid).getSObjectType())+' WHERE Id=\''+whoid+'\'');
                  if (whatid!=null) 
                        o1 =Database.query('Select '+fieldToUpdate+' FROM '+String.valueof(Id.valueOf(whatid).getSObjectType())+' WHERE Id=\''+whatid+'\'');
                  else  o1 =Database.query('Select '+fieldToUpdate+' FROM '+String.valueof(Id.valueOf(whoid).getSObjectType())+' WHERE Id=\''+whoid+'\'');
                    
                }
           }
            
           if(action.Field_Name__c=='OwnerPrioritization'){
                fieldToUpdate='OwnerId';
                system.debug('OwnerPrioritization '+action.Prioritization_Method__c);
                value = action.Prioritization_Method__c=='Weighted Calculation'? AW_OwnerPrioritizationHelper.assign_basedonWeightedCalculation(action):AW_OwnerPrioritizationHelper.assign_basedonRoundRobin(action);
           }
              
           if(fieldToUpdate!='LookupObjectField' && (action.Bulk_api__c==false || bulkOperation)) {
             
                 o1 = AW_ExecutionActionHelper.updateField(action.Related_Object__c,fieldToUpdate,value,o1);
            } 
             else  if(fieldToUpdate!='LookupObjectField' && (action.Bulk_api__c  && !bulkOperation)) {
                   //if(action.Bulk_api__c && !bulkOperation) {
                    system.debug('-->BULK INSERT Object_Action_Execution');
                    system.debug('-->BULK Action__c=action.Id '+ action.Id);
                    system.debug('-->BULK Status__c '+'New');
                    system.debug('-->BULK Value__c '+value);
                    system.debug('-->BULK Record_Id__c '+o.Id);
                    
                     
                    bulkObjectUpdates.add(new Object_Action_Execution__c(Action__c=action.Id,Status__c='New',Value__c=value,Record_Id__c=o.Id,Type__c='Bulk API'));
                    system.debug('-->BULK INSERT Object_Action_Execution' +bulkObjectUpdates);
         // bulkObjectUpdates.add(new Object_Action_Execution__c(Action__c=action.Id,Status__c='New',Value1__c=value,Record_Id__c=o.Id,Type__c='Bulk API'));
        
           }else if(fieldToUpdate=='LookupObjectField' && (action.Bulk_api__c  &&  !bulkOperation)){
                    //process the lookup object action                  
                   //   system.debug('-->BULK LOOKUP ' +bulkObjectUpdates);
                   value = AW_ExecutionActionHelper.executeLookupObjectAction(action, o);
                    system.debug('-->ExecuteLookupObjectAction BULK'+value);
                    bulkObjectUpdates.add(new Object_Action_Execution__c(Action__c=action.Id,Status__c='New',Value__c=value,Record_Id__c=o.Id,Type__c='Bulk API'));
                    system.debug('-->BULK INSERT Object_Action_Execution' +bulkObjectUpdates);
        
           }else if(fieldToUpdate=='LookupObjectField' && (action.Bulk_api__c==false || bulkOperation )){
                    //process the lookup object action    
                     system.debug('BEFORE ---> value '+value);              
                    value = AW_ExecutionActionHelper.executeLookupObjectAction(action, o);
                     system.debug('AFTER ---> value '+value);              
                     system.debug('---> o1 '+o1);
                     system.debug('---> action.Lookup_Field_Name__c, '+action.Lookup_Field_Name__c);
                   
                    o1.put(action.Lookup_Field_Name__c,value );
                   // o1 = AW_ExecutionActionHelper.updateField(action.Related_Object__c,fieldToUpdate,value,o1);
           
           }     
            
        }
        
        //8-12-13 SH @bug fix : allowing multiple cross object in same rule
        if(action.Field_Name__c=='CrossObject' && o1!=null)
            toUpdateSObject.put(String.valueof(o1.get('id')),o1);
            
            //toUpdateSObject.put(UserInfo.getUserId(),o1);
        return action.Field_Name__c=='CrossObject' ? o :o1;
    
    }  
}
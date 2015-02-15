// (c) 2012 Appirio, Inc.
// AW_AdvanceWorkflowExecutionHelper                                                     
//
// This class is  helper class for the RuleExecution class
// and performs the associated actions 
//
// 5  Dec 2012     Peter Babalis     Original
// 20 Dec 2012     Cloud Challenger
// 07 Feb 2013     Peter Babalis Added email templates,cross formula fields,insert tasks
// 24 Sep 2013     Peter Babalis Added upsertrelatedinfo to capture records to be upserted
// 14 Dec 2013     Peter Babalis Refactor Class 
// 16 July 2014    Changed getActiveCriteria ,getActiveRuleActionsSubset,getActiveRuleActions methods and added Draft status also if rngine run from Simulation
// 12 Oct  2014    Add logic ( joinSetTask_No_WhoIds,joinSetTaskWhoIdsOnly ) to handled reference fields ( whoid ) for task object 
 
public class AW_AdvanceWorkflowExecutionHelper {
    /** 
     * List of all static variables 
     */     
                
    // Map of user id and content to be send on mail        
    //public static Map<String,List<String>> userIdMailContentMap = new Map<String,List<String>>();
     //SH :-updating Map of user id and record id with template id to be send on mail      
     public static Map<String,Map<String,List<RuleAction__c>>> userIdMailContentMap = new Map<String,Map<String,List<RuleAction__c>>>();
    //cloudchallenger
     public static Boolean isBatchProcess = false;

   public static String joinSetTask_No_WhoIds(Set<String> values,String joinUsing) {
    
    List<String> valueCopy = new List<String>();
             
   try{ 
   	         Set<String> valueset = new Set<String>(); 
   
         	  system.debug('-->joinSetTask_No_WhoIds.Values  '+values);  
              values.remove('CrossObject');
         	  values.remove('LookupObjectField');
         	    
              for (String val : values) {
                 if (val.startswith('whoid.') )  continue;
                 if (val.startswith('whatid.') ) continue;
                 if (valueset.add(val)) {
                    valueCopy.add(val);
                 }
               }
               system.debug('-->joinSetTask_No_WhoIds.valueCopy  '+ valueCopy);
               return String.join(valueCopy,joinUsing);
            }
           catch(Exception e){
                 String msg = string.valueOf(e);
                 List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                 AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','joinSet','AW_AdvanceWorkflowExecutionHelper.cls','joinSet','RuleAction__c');
                 //other wise it is an invlaid operator on this datatype:-                   
              return null;
            } 
   	
   }
   
   public static String joinSetTaskWhoIdsOnly(Set<String> existingSelectedFieldSet ,Set<String> values,String joinUsing) {
      
      List<String> valueCopy = new List<String>();
     
      try{ 
      	     Set<String> valueset = new Set<String>(); 
    
             system.debug('-->joinSetTaskWhoIdsOnly.Values  '+values);  
             values.remove('CrossObject');
         	 values.remove('LookupObjectField');
         	     
              for (String val : values) {
              if (val.startswith('whoid.') ){ 
              	   String s1;
              	   val= val.substringAfter('whoid.');
              	   system.debug(' s1 '+ val);
               if (!existingSelectedFieldSet.contains(val)) {
                    valueCopy.add(val);
                }
              }
             
              if (val.startswith('whatid.') ){ 
              	   String s1;
              	   val= val.substringAfter('whatid.');
              	   system.debug(' s1 '+ val);
               if (!existingSelectedFieldSet.contains(val)) {
                    valueCopy.add(val);
                }
              } 
               
              }
                     
              return String.join(valueCopy,joinUsing);
            }
           catch(Exception e){
                 String msg = string.valueOf(e);
                 List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                 AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','joinSet','AW_AdvanceWorkflowExecutionHelper.cls','joinSet','RuleAction__c');
                 //other wise it is an invlaid operator on this datatype:-                   
              return null;
            } 
     
    	
    }
      /*
      * @author Sneha
      * @date 30/7/2012
      * @description method joins a set using                             
    */
    public static String joinSet(Set<String> values,String joinUsing) {
    String vallowercase='';
    try{
         	  system.debug('-->joinSet.Values  '+values);  
       	      values.remove('CrossObject');
         	  values.remove('LookupObjectField');
         	     
             // List<String> valueCopy = new List<String>(values);
              List<String> valueCopy = new List<String>();
               
               Set<String> valueset = new Set<String>(); 
              
              for (String val : values) {
              if (val.startswith('whoid.') ){ 
              	   String s1;
              	   val= val.substringAfter('whoid.');
              	   system.debug(' s1 '+ val);
               
              }
              vallowercase=val.toLowerCase();
              if (valueset.add(vallowercase)) {
                    valueCopy.add(val);
                }
                 
              }
                system.debug('-->joinset.valueCopy  '+ valueCopy);
                //system.debug('-->joinset1.valueCopy1  '+ valueCopy1);
         
                
              return String.join(valueCopy,joinUsing);
            }
           catch(Exception e){
                 String msg = string.valueOf(e);
                 List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                 AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecutionHelper.cls','joinSet','AW_AdvanceWorkflowExecutionHelper.cls','joinSet','RuleAction__c');
                 //other wise it is an invlaid operator on this datatype:-                   
              return null;
            } 
     }
    
    
    /**
    * By Cloud Challenger
    * THis method fetch user's email id
    */
    public static Map<Id,User> getUserDetails(Set<String> userIds){
        return new Map<Id,User>([Select Name, FirstName,LastName,Id,Email from User where Id in: userIDs]);
    }
     
    
    /**
    * lets not depend on the caller that ther are providing entire details of
    * the rules & criteria lets fetch by our self       
    */
    public static List<Rule__c> getActiveCriteria(Set<Id> ruleIds,String sobjectName, boolean isSimulaiton){
    	// Megha - 07/16/2014 - Changed query and added Draft status also if rule run from Simulation
    	
    	String soqlQuery = 'Select Id,Name,Object__c,Order__c,Version__c,Advance_Workflow__c,DisplayActions__c,DisplayfilterLogic__c,Execution_Behavior__c,Evaluation_Rule__c,Filter_Logic__c,Total_Actions__c,Total_Criteria__c, (Select Id,Field_API_Name__c,Field_Type__c ,Record_Type_Id__c,Matching_Type__c,Matching_Value__c,Maximum_Value__c,Minimum_Value__c,Related_Object__c,CrossFormula__c,Evaluate_Criteria_Result_To__c,Evaluate_ChildCriteria_Using__c FROM Rule_Criteria__r ORDER BY Name ASC) FROM Rule__c WHERE ';
    	  
    	if(!isSimulaiton){
    		soqlQuery += ' Status__c =\'Active\'' ;
    	}else{
    		soqlQuery += ' Status__c in (\'Active\' , \'Draft\')' ;
    	}
    	soqlQuery +=  'AND Total_Actions__c >0 AND Object__c=:sobjectName AND Id IN :ruleIds order by Order__c';
        List<Rule__c> lstRules = Database.query(soqlQuery);
      
        for(Rule__c rul: lstRules){
        	if(rul.getSObjects('Rule_Criteria__r') != null){
        		for(RuleCriteria__c rulCrt : rul.getSObjects('Rule_Criteria__r')){
        			if(rulCrt.Field_API_Name__c.equalsIgnoreCase('RecordTypeId')){
                  		rulCrt.Matching_Value__c = rulCrt.Record_Type_Id__c;                  		
                  	}
        		}
        	}
        }
        return lstRules;
    }
    
    public static void processAsync(String sobjectType , String mode, Set<Id> recordIds){
         AdvanceWorkflowBatchStatus__c awBatchStatus =  AdvanceWorkflowBatchStatus__c.getInstance(sobjectType); 
         if(awBatchStatus == null){
              awBatchStatus = new AdvanceWorkflowBatchStatus__c(Name=sobjectType,Is_Batch_Running__c = true);
              insert awBatchStatus;
         }
       //
        system.debug('-->Number of Job Running '  +AW_AdvanceWorkflowExecutionHelper.noScheduleAWEJobs());    
       
       if(AW_AdvanceWorkflowExecutionHelper.noScheduleAWEJobs()  <1) {
                // AW_AdvanceWorkflowExecutionHelper.startQueueWorker(System.now(),'Object_Action_Execution__c');
           AW_AdvanceWorkflowExecutionHelper.startAsyncAWESchedular(System.now(),sobjectType,mode, recordIds);
       }        
    }
    
    
    /**
    * get all the actions for given set of rule
    * returns all the actions that are active
    */
    public static Map<Id,Rule__c> getActiveRuleActions(Set<Id> ruleIds,String sobjectName, boolean isSimulation){
    	// Megha - 07/16/2014 - Changed query and added Draft status also if rule from Simulation
    	String soqlQuery = 'Select Id,Name,Object__c,(Select Id,Name,Action_Label__c,Prioritization_Method__c,Notified_User__c,Reference_Id__c,Field_Type__c,Field_Name__c,Lookup_Field_Name__c,Type__c,Value__c,Long_Value__c,Related_Object__c,Notify_user__c,Email_Template__c,User_Owner_Id__c,CrossObjectField__c,Bulk_api__c,Lookup_Object__c,Lookup_field_api_name__c,lookup_where_fields__c,Apex_job_Class__c,Input_Parameters__c,output_parameters__c,Endpoint_URL__c,Callout_Method__c,Callout_timeout__c,Rule__c,Additional_Emails__c,External_Field_API_Name__c,externalid__c FROM Rule_Actions__r  ORDER BY Name ASC) FROM Rule__c  WHERE ';
    	if(!isSimulation){
    		soqlQuery += 'Status__c = \'Active\' ';
    	}else{
    		soqlQuery += ' Status__c in (\'Active\' , \'Draft\') ' ;
    	}
    	soqlQuery += ' AND Total_Actions__c >0 AND Object__c=:sobjectName AND Id IN :ruleIds';
        Map<Id,Rule__c> ruleActions = new Map<Id, Rule__c>((List<Rule__c>)Database.query(soqlQuery)); //[Select Id,Name,Object__c,(Select Id,Name,Action_Label__c,Prioritization_Method__c,Notified_User__c,Reference_Id__c,Field_Type__c,Field_Name__c,Lookup_Field_Name__c,Type__c,Value__c,Long_Value__c,Related_Object__c,Notify_user__c,Email_Template__c,User_Owner_Id__c,CrossObjectField__c,Bulk_api__c,Lookup_Object__c,Lookup_field_api_name__c,lookup_where_fields__c,Apex_job_Class__c,Input_Parameters__c,output_parameters__c,Endpoint_URL__c,Callout_Method__c,Callout_timeout__c,Rule__c,Additional_Emails__c,External_Field_API_Name__c,externalid__c FROM Rule_Actions__r  ORDER BY Name ASC) FROM Rule__c  WHERE Status__c='Active' AND  Total_Actions__c >0 AND Object__c=:sobjectName AND Id IN :ruleIds ]);                       
        return ruleActions;
    }
     
     public static Map<Id,Rule__c> getActiveRuleActionsSubset(Set<Id> ruleIds,String sobjectName,Set<Id> actionIds,  boolean isSimulation){
     	// Megha - 07/16/2014 - Changed query and added Draft status also if rule from Simulation
     	String soqlQuery = 'Select Id,Name,Object__c,(Select Id,Name,Action_Label__c,Prioritization_Method__c,Notified_User__c,Reference_Id__c,Field_Type__c,Lookup_Field_Name__c,Field_Name__c,Type__c,Value__c,Long_Value__c,Related_Object__c,Notify_user__c,Email_Template__c,User_Owner_Id__c,CrossObjectField__c,Bulk_api__c,Lookup_Object__c,Lookup_field_api_name__c,lookup_where_fields__c,Apex_job_Class__c,Input_Parameters__c,output_parameters__c,Rule__c,Endpoint_URL__c,Callout_Method__c,Callout_timeout__c,Additional_Emails__c,External_Field_API_Name__c,externalid__c FROM Rule_Actions__r WHERE Id IN : actionIds  ORDER BY Name ASC) FROM Rule__c  WHERE ';
     	if(!isSimulation){
     		soqlQuery += ' Status__c = \'Active\'';
     	}else{
     		soqlQuery += ' Status__c in (\'Active\' , \'Draft\')';  
     	}
     	soqlQuery += ' AND Total_Actions__c >0 AND Object__c=:sobjectName AND Id IN :ruleIds ';
        Map<Id,Rule__c> ruleActions = new Map<Id, Rule__c>((List<Rule__c>)Database.query(soqlQuery));                       
        return ruleActions;
    }
      /**
    * By Cloud Challenger
    * Fetch InsertRelatedRecord info 
    */
    
     public static Map<Id,RuleAction__c> getInsertRelatedRecordInfo(Set<Id> ruleIds){
        return new Map<Id,RuleAction__c>([Select Id,(Select Name, Value__c,Reference_Id__c From Values_for_Action_Insert_Record__r ) from RuleAction__c where Rule__c in: ruleIds and (Type__c = 'Insert Related Object' or Type__c ='Upsert Related Object' OR Type__c = 'Insert Unrelated Object' or Type__c ='Upsert Unrelated Object')]);
    }
    
    public static Map<Id,RuleAction__c> getInsertRelatedRecordInfoForActions(Set<Id> actionIds){
        return new Map<Id,RuleAction__c>([Select Id,(Select Name, Value__c,Reference_Id__c From Values_for_Action_Insert_Record__r ) from RuleAction__c where Id in: actionIds and (Type__c = 'Insert Related Object' or Type__c ='Upsert Related Object' OR Type__c = 'Insert Unrelated Object' or Type__c ='Upsert Unrelated Object')]);
    }
     
     
    public static Map<Id,RuleAction__c> getUpsertRelatedRecordInfo(Set<Id> ruleIds){
        return new Map<Id,RuleAction__c>([Select Id,(Select Name, Value__c,Reference_Id__c From Values_for_Action_Insert_Record__r ) from RuleAction__c where Rule__c in: ruleIds and Type__c = 'Upsert Related Object']);
    }
        /**
         * This method will sort the option list on there label values
         */
        public static void sortSelectListOnLabel(List<SelectOption> options){
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
     
    public static Map<String,Map<String,List<RuleAction__c>>> buildListForEmail(Map<String,Map<String,List<RuleAction__c>>> usersInSendEmailAction,String referenceId,RuleAction__c a,String objId){
        if(!usersInSendEmailAction.containsKey(referenceId)){
            //if no                       
            List<RuleAction__c> temp = new List<RuleAction__c>{a};
            Map<String ,List<RuleAction__c>> objTemp=  new Map<String ,List<RuleAction__c>>();
            objTemp.put(objId,temp);
            usersInSendEmailAction.put(referenceId,objTemp);
        }
        else{
            Map<String ,List<RuleAction__c>> objTemp = usersInSendEmailAction.get(referenceId);
            if(!objTemp.containsKey(objId))
                objTemp.put(objId,new List<RuleAction__c>{a});
            else

                objTemp.get(objId).add(a);
                
            usersInSendEmailAction.put(referenceId,objTemp);
        }
        return usersInSendEmailAction;
    }
      
    public static Integer noScheduleAWEJobs() {
 
    List<CronJobDetail> listCronjobs  = [SELECT 
                                            Id, Name 
                                            FROM CronJobDetail 
                                            WHERE  Name 
                                            LIKE 'AWE BULK Scheduled Job%'  OR Name 
                                            LIKE 'AWE Async Scheduled Job%' ];
                                   
         System.debug('#### Number of scheduled jobs: '+listCronjobs.size());                                                        
                 
        /* for (CronTrigger aCronTrigger : listCronTrigger)
                       {
                               System.abortJob(aCronTrigger.Id);
                               System.debug('#### deleted Job details :' + String.valueOf(aCronTrigger));
                       }
          */                    
           return listCronjobs.size(); 
  }
      
      public static void StartAWSchedular(DateTime dt,String sobjType,String mode){
            
           
            AdvanceWorkflowConf__c conf = AdvanceWorkflowConf__c.getInstance('WorkflowConf');
            Integer delayTime = 0;
           
            if(conf == null){
                conf = new AdvanceWorkflowConf__c(name='WorkflowConf',Delay_Time__c=5,Batch_Size__c=100);
                insert conf;
            }
            if(conf != null && conf.Delay_Time__c >= 0){
                delayTime = Integer.valueOf(conf.Delay_Time__c);
            }
            
            
            DateTime thisTime = dt.addMinutes(delayTime);            
            integer minute = thisTime.minute();
            integer second = thisTime.second();
            integer hour = thisTime.hour();
            integer year = thisTime.year();
            integer month = thisTime.month();
            integer day = thisTime.day();
                    
            String timeStamp = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
            String cronJobID = System.schedule('AWE BULK Scheduled Job' + System.now(),timeStamp, new AW_Advance_WorkflowScheduler(sobjType,dt,mode));
      }
    // AsyncApexJob  object to retrieve the current job's information.
     public static Integer noScheduledAWEJobsRunning() {
 		Integer runningWorker=0;
 		 runningWorker = [SELECT COUNT() 
        						FROM AsyncApexJob
                                WHERE JobType = 'BatchApex'
                                AND ApexClass.Name = 'AW_Advance_WorkflowBatch'
                                AND Status IN ('Processing')];
          return runningWorker;
   }    
   
   
                  
    
     
     public static void handleError(Exception e){
         system.debug(e);
         String msg = string.valueOf(e);
         List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
         AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecution.cls','applyInsertChildActions','AW_AdvanceWorkflowExecution.cls','LogEmail','');
        

     }
      
     public static String getValueForUpdateAction(RuleAction__c action){
            /**
              * For Long Text Area
              */
                 
              String value=null;
                system.debug('-->getValueForUpdateAction--> action.Field_Type__c '+action.Field_Type__c );
                system.debug('-->getValueForUpdateAction--> action.value '+action.value__c +' value'+ value );
              
              if((action.Field_Type__c == 'datetime1' || action.Field_Type__c == 'date1') && action.value__c  != null && action.value__c  != ''){ } 
                 else if(action.Field_Type__c == 'REFERENCE' && action.Reference_Id__c != null && action.Reference_Id__c != ''){
                  value = action.Reference_Id__c;
              }
              else if(action.Value__c == null && action.Long_Value__c != null){
                  value = action.Long_Value__c;
              }
              else{
                  value = action.value__c;
              }
           //   system.debug('getValueForUpdateAction--> action '+action.value__c +' value'+ value );
              
              return value ;
        }  
    
     public static void startAsyncAWESchedular(DateTime dt,String sobjType,String mode, Set<Id> recordIds){
             
           
            AdvanceWorkflowConf__c conf = AdvanceWorkflowConf__c.getInstance(sobjType);
            Integer delayTime = 0;
            if(conf != null && conf.Delay_Time__c >= 0){
                delayTime = Integer.valueOf(conf.Delay_Time__c);
            }
            if(conf != null){
            
                DateTime thisTime = dt.addMinutes(delayTime);            
                integer minute = thisTime.minute();
                integer second = thisTime.second();
                integer hour = thisTime.hour();
                integer year = thisTime.year();
                integer month = thisTime.month();
                integer day = thisTime.day();
                        
                String timeStamp = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
                String cronJobID = System.schedule('AWE Async Scheduled Job' + System.now(),timeStamp, new AW_AdvanceWorkflowAsyncScheduler(sobjType,dt,mode, recordIds));
            }
            
        }
        
        // AsyncApexJob  object to retrieve the current job's information. Megha
     public static Integer noScheduledAWEAsyncJob() {
        Integer runningWorker=0;
         runningWorker = [SELECT COUNT() 
                                FROM AsyncApexJob
                                WHERE JobType = 'BatchApex'
                                AND ApexClass.Name = 'AW_AdvanceWorkflowAsyncBatch'
                                AND Status IN ('Processing')];
          return runningWorker;
   }   
    
    
}
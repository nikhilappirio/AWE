// 
// (c) 2012 Appirio, Inc.
// AW_AdvanceWorkflowTransactionProcessing                                                     
//
// This class is  helper class for the RuleExecution class
// and performs the associated actions
//
// 08  Feb 2013     Peter Babalis     Original
// 24  Sep 2013     Peter Babalis     Added Upsert Operation
//  

public class AW_AdvanceWorkflowTransactionProcessing {
     public static   boolean performDMLOperations(Map<Id,SObject> toupdateSobj,List<SObject> insertrelatedobj ){
                     
        Savepoint sp = Database.setSavepoint();
        if (insertrelatedobj.size()>0 ){
           try {
              system.debug('--BEGIN INSERT/UPSERT TRANSACTION ....');
              
              //insert insertrelatedobj;
               // Cloudchallenger : same method now can be used for insert related object and upsert related object
               //upsert insertrelatedObj;
               // Upsert cannot be done on sobject so separating record on the basis of id
               List<SObject> lstSObjectforInsert = new List<SObject>();
               List<SObject> lstSObjectforUpdate = new List<SObject>();

               for(SObject sobj: insertrelatedobj){
 
               		if(sobj != null){
	               		if(sobj.id == null){
	               			lstSObjectforInsert.add(sobj);
	               		}else{
	               			lstSObjectforUpdate.add(sobj);
	               		}
               		}
               }
              
               if(lstSObjectforInsert.size() > 0){
              		system.debug('--Number of Record to Be  INSERTED/UPSERTED :'+ lstSObjectforInsert.size());
               		system.debug('-- Record to Be  INSERTED/UPSERTED : '+ lstSObjectforInsert );
               		insert lstSObjectforInsert;
               }
               if(lstSObjectforUpdate.size() > 0){
               	    system.debug('--Number of Record to Be  UPDATED/UPSERTED :'+ lstSObjectforUpdate.size());
               		system.debug('-- Record to Be  UPDATED/UPSERTED : '+ lstSObjectforUpdate );
               		update lstSObjectforUpdate;
               }
               //insert insertrelatedobj; 
               system.debug('--END  INSERT/UPSERT TRANSACTION .... ');  
            }
            catch(DMLException e) {

            Database.rollback(sp);
            return false;
            }  
         }
        if (toupdateSobj.size()>0 ){
            // Create a savepoint  
            try {
               
               system.debug('--BEGIN UPDATE TRANSACTION ....');
               system.debug('--Number of Record to Be  Updated :'+ toupdateSobj.size());
               system.debug('-- Record to Be UPDATED : '+ toupdateSobj );
               update toupdateSobj.values();
               system.debug('--END  UPDATE TRANSACTION .... ');  
               return true;    
            }
            catch(DMLException e) {

            Database.rollback(sp);
            return false;
            }  
            
         } 
         return true;      
    }
    
         public static void processLookupUpdatesAndBulkAPi(List<Object_Action_Execution__c> records,String mode){
    	 //insert the records in DB & fire batch process :- 
    	 
    	  //insert the records in DB & fire batch process :- 
    	 List<Object_Action_Execution__c> recordsToUpdate = new List<Object_Action_Execution__c> ();
    	 List<Object_Action_Execution__c> recordsToInsert = new List<Object_Action_Execution__c> ();
    	 			 
    	 system.debug('-->records (BULK)  '+records);
    	 for(Object_Action_Execution__c obj: records){
               if(obj.get('Id') == null) 
                    recordsToInsert.add(obj);
                else 
                    recordsToUpdate.add(obj);
         }
         system.debug('-->recordsToInsert (BULK)  '+recordsToInsert);
         system.debug('-->recordsToUpdate (BULK) '+recordsToUpdate);
         
        Savepoint sp = Database.setSavepoint();
        if (records.size()>0  ){
        try {
         if (recordsToUpdate.size()>0  ){
               update recordsToUpdate;
         }  
           if (recordsToInsert.size()>0  ){
              insert recordsToInsert;
         }     
        } catch(DMLException e) {

            Database.rollback(sp);
            
            }
        }          
      AdvanceWorkflowBatchStatus__c awBatchStatus =  AdvanceWorkflowBatchStatus__c.getInstance('Object_Action_Execution__c'); 
         if(awBatchStatus == null){
                  awBatchStatus = new AdvanceWorkflowBatchStatus__c(Name='Object_Action_Execution__c',Is_Batch_Running__c = true);
                 insert awBatchStatus;
            }
       
        system.debug('-->Number of Job Running '  +AW_AdvanceWorkflowExecutionHelper.noScheduleAWEJobs());    
       
       if(AW_AdvanceWorkflowExecutionHelper.noScheduleAWEJobs()  <1) {
                // AW_AdvanceWorkflowExecutionHelper.startQueueWorker(System.now(),'Object_Action_Execution__c');
                 AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now(),'Object_Action_Execution__c',mode);
                 }    
            
    	 
    	 
    	   
    }
    
      
      /*
      adding helper method which initialize a history records & returns
      it
    */
    public static Rule_Execution_History__c createHistoryInstance(Datetime tstamp,Rule__c rule,Sobject o,Sobject old,SObject parentObj){
    	
    	String sobjName= String.valueof(parentObj.getSObjectType()).tolowerCase();
    	system.debug('sobjName '+sobjName);
    	system.debug('parentObj '+parentObj);
    	
    	String recordName =  sobjName=='task' ? string.valueof(parentObj.get('subject')): sobjName=='event' ? string.valueof(parentObj.get('subject')): (sobjName=='case' ? string.valueof(parentObj.get('casenumber')) : string.valueof(parentObj.get('name')));
    	Rule_Execution_History__c h = new Rule_Execution_History__c();
        String externalid = rule.id+'-'+string.valueof(o.get('id'));
        h.Rule_ID__c=externalid;
        h.Rule__c =rule.id;    
        h.Record_ID__c=string.valueof(parentObj.get('id'));
        h.Criteria__c= rule.DisplayfilterLogic__c;
        h.Actions__c=rule.DisplayActions__c;
        h.RuleName__c=rule.Name;
        h.Evaluation__c=rule.Evaluation_Rule__c;
        h.Execution__c=rule.Execution_Behavior__c;
        h.Rule_object__c=rule.Object__c;
        h.Rule_Version__c=String.valueof(rule.Version__c);
        h.Advance_Workflow__c=rule.Advance_Workflow__c;
        if(old!=null)h.Record_Before_Action_Applied__c=JSON.serialize(old);
        if(o!=null)h.Record_After_Action_Applied__c=JSON.serialize(o);
        h.Rule_Execution_Status__c='Success';
        h.Record_Name__c=recordName;
        h.Transaction_Stamp__c=String.valueof(tstamp.format('MM-dd-yy HH:mm:ss'));
        return h;
    }
    
   
   
    public static void processBulkAPiTransactions(List<Object_Action_Execution__c> records,String mode){
    	 			 
    /*
    	314 //insert the records in DB & fire batch process :- 
    	 insert records;
    	 
    	 AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now(),'Object_Action_Execution__c',mode);
       	 AdvanceWorkflowBatchStatus__c awBatchStatus = new AdvanceWorkflowBatchStatus__c(Name='Object_Action_Execution__c',Is_Batch_Running__c = true);
         insert awBatchStatus;    
   */
    	 //insert the records in DB & fire batch process :- 
    	 			 
    	 system.debug('-->records  '+records);
     	 insert records;
         AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now(),'Object_Action_Execution__c',mode);
       	 AdvanceWorkflowBatchStatus__c awBatchStatus =  AdvanceWorkflowBatchStatus__c.getInstance('Object_Action_Execution__c'); 
         if(awBatchStatus == null){
                 awBatchStatus = new AdvanceWorkflowBatchStatus__c(Name='Object_Action_Execution__c',Is_Batch_Running__c = true);
              insert awBatchStatus;
           }   
    
    }
    
    public static void handleError(Exception e){
        String msg = string.valueOf(e);
        List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
        AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowTransactionProcessing.cls','addRecordstoExecutionHistory','AW_AdvanceWorkflowTransactionProcessing.cls','LogEmail','Rule_Execution_History__c');
    }
    
    static testmethod void testHandleError(){
         Opportunity o= new Opportunity();
         try{ insert o;}
         catch(Exception e){
              handleError(e);
         }
    }
    
}
// 
// (c) 2012 Appirio, Inc.
// AW_AdvanceWorkflowAsyncScheduler                                                    
// This class is used to schedule bulk API calls
//
// 14 November 2014 Megha
//  
//
// 
global  with sharing class AW_AdvanceWorkflowAsyncScheduler  implements Schedulable {
    Integer MAX_BATCHES = 5;
    DateTime dt = null;
    String sobjType = '';
    String mode = '';
    Set<Id> recordIds = new Set<Id>();
    public AW_AdvanceWorkflowAsyncScheduler(String sobjType, Datetime dt,String mode){}
    public AW_AdvanceWorkflowAsyncScheduler(String sobjType, Datetime dt,String mode, Set<Id> recordIds){
        this.dt = dt;
        this.sobjType = sobjType;
        this.mode=mode;
        this.recordIds = recordIds;
        string  query = 'Select Id,Action__c, ruleIds__c , Value__c,Record_Id__c, Type__c FROM  Object_Action_Execution__c where  Type__c = \'Async\' AND record_Id__c in : recordIds AND CreatedDate >=:dt limit 1';
        List<SObject> lstObj = Database.query(query);
        if(lstObj == null && lstObj.size() == 0){
            AdvanceWorkflowBatchStatus__c awBatchStatus = AdvanceWorkflowBatchStatus__c.getInstance(sobjType);
            if(awBatchStatus != null){
                delete awBatchStatus;
            }
        }        
    }
    
    global void execute(SchedulableContext shdCtx){     
         system.debug('--------->SchedulableContext dt:' + dt + '::::'+recordIds);
          
        Integer batchSize;  
         
        AdvanceWorkflowConf__c conf = AdvanceWorkflowConf__c.getInstance(sobjType);
        if(conf != null){
            batchSize = conf.batch_Size__c != null ? Integer.valueOf(conf.batch_Size__c) : 10;
    if ( AW_AdvanceWorkflowExecutionHelper.noScheduledAWEAsyncJob() < 1){
                Database.executeBatch(new AW_AdvanceWorkflowAsyncBatch(dt,sobjType,mode, recordIds),batchSize);
              
         /**
         * We dont want a execute schedular record to be present in the schedule job queue
         */
         System.abortJob(shdCtx.getTriggerId());
         }
    else {
        AW_AdvanceWorkflowExecutionHelper.startAsyncAWESchedular(system.now(),sobjType,mode, recordIds);
       }
          
    }
}
}
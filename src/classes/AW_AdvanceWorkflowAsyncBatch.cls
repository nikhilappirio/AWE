global with sharing class AW_AdvanceWorkflowAsyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private string query = '';
    private string sobjType = '';
    private DateTime dtnew = null;
    private DateTime dt = null;
    private String mode='' ;
    private Set<Id> recordIds;
    public AW_AdvanceWorkflowAsyncBatch (DateTime dt1,String sobjType, String mode1, Set<Id> recordIds){
        this.sobjType = sobjType;
        this.dt = dt1;   
        this.mode = mode1;  
        this.recordIds = recordIds;
        
         
        query = 'Select Id,Action__c, ruleIds__c , Value__c,Record_Id__c, Type__c FROM  Object_Action_Execution__c where  Type__c = \'Async\' AND sobjectType__c in  ( \''+ sobjType+'\' ) ';//where CreatedDate >=:dt 
    // query = 'Select Id,Action__c, ruleIds__c , Value__c,Record_Id__c, Type__c FROM  Object_Action_Execution__c where  Type__c = \'Async\' AND sobjectType__c in : sobjType';//where CreatedDate >=:dt 
       
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
       system.debug('locatorquery '+query);
        dtnew = system.now();
        return Database.getQueryLocator(query);
        /**
         * Setting the date context for next execute
         */     
    }
   
   //executeBatch(new AW_Advance_WorkflowBatch(dt,sobjType),batchSize,mode);       
      
    global void execute(Database.BatchableContext BC, List<Object_Action_Execution__c> scope ){
        Set<Id> ruleIds = new Set<Id>();
        Set<Id> sobjectRecordIds = new Set<Id>();
        Map<String,String> actionValue = new Map<String,String>();      
        Map<String,Object_Action_Execution__c> actionrecords = new Map<String,Object_Action_Execution__c>();
         
        for(Object_Action_Execution__c o: scope){
            if(o.ruleIds__c != null){
                ruleIds.addAll((List<Id>)o.ruleIds__c.split(','));
            }
            sobjectRecordIds.add(o.Record_Id__c);
        }
        List<Advance_Workflow__c> workflows =Database.query('SELECT id,Advance_Rule_Stamp__c,Enable_Execution_History__c from Advance_Workflow__c where object__c = \''+sobjType+'\' and Enabled__c = true');
        
      AW_AdvanceWorkflowExecutionEngine.isAsyncProcessRunning = true; 
      AW_AdvanceWorkflowExecutionEngine.bulkOperation = false;   
      AW_AdvanceWorkflowExecutionEngine.evaluateRules(ruleIds,sobjectRecordIds,sobjType, mode);
      if (scope.size()>0) delete scope;
       
    }
     
    global void finish(Database.BatchableContext BC) {
        String soqlQuery = query + ' limit 1';
        
        List<SObject> lstObj = Database.query(query);
         if(!lstObj.isEmpty()){
          if ( AW_AdvanceWorkflowExecutionHelper.noScheduledAWEAsyncJob()< 1 )
           AW_AdvanceWorkflowExecutionHelper.startAsyncAWESchedular(system.now(),sobjType,mode, recordIds);
          else{
            AdvanceWorkflowBatchStatus__c awBatchStatus = AdvanceWorkflowBatchStatus__c.getInstance(sobjType);
            if(awBatchStatus != null){
                delete awBatchStatus;
            }
        }
    }

}
}
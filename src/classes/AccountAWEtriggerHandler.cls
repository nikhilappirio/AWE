public with sharing class AccountAWEtriggerHandler {
public static void afterInsert( List<Account> newList){
  Set<Id> Ids = new Set<Id>();
    String sobjName='Account';
    for(Account a : newList){
         Ids.add(a.Id);
    }
    Boolean evaluate = AW_AdvanceWorkflowExecutionEngine.EvaluationRunningFor.contains(sobjName)?false:true;
    
         
   // if (Ids.size()>0 && AW_AdvanceWorkflowExecutionEngine.EvaluationIsRunning==false){
    if (Ids.size()>0 &&  evaluate ){
    		if(!Test.isRunningTest())	//skip while running test
             	AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,Trigger.isInsert);
             else
             	AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,true);
   	
    }	
  }
  
 public static void afterUpdate(List<Account> newList,Map<Id,Account> oldMap){
   Set<Id> Ids = new Set<Id>();
     String sobjName='Account';
     for(Account a : newList){
         Ids.add(a.Id);
    }
      Boolean evaluate = AW_AdvanceWorkflowExecutionEngine.EvaluationRunningFor.contains(sobjName)?false:true;
     // if (Ids.size()>0 && AW_AdvanceWorkflowExecutionEngine.EvaluationIsRunning==false){
      if (Ids.size()>0 && evaluate  ){
             AW_AdvanceWorkflowExecutionEngine.oldListMap = oldMap;
             if(!Test.isRunningTest())
             	AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,Trigger.isInsert); 
             else
             	AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,false);   
            }   
 }
    
  
}
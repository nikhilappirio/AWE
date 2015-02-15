// (c) 2012 Appirio, Inc.
//
// User_aInsertaUpdate                                                     
//
// Trigger is used to Send that list of created or updated account to the Rule Engine class for evaluation  
//
// 18 Nov 2012     Peter Babalis     Original
//
trigger User_aInsertaUpdate on User (after insert,after update) {
    
    
    Set<Id> Ids=new Set<Id>();
    
    //add all the accountids in the set
    for (User a:trigger.new){
        Ids.add(a.Id);
    }//for

    //Send that list of created or updated account to the Rule Engine class for evaluation
    system.debug('--- AW_AdvanceWorkflowExecutionEngine Future method already called? '+AW_AdvanceWorkflowExecutionEngine.EvaluationIsRunning);
    if (AW_AdvanceWorkflowExecutionEngine.EvaluationIsRunning==false){
        //Integer limit1 = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
        //if (limit1>0){//don't call the method if the limit is reached            
        if(Trigger.isUpdate)
                AW_AdvanceWorkflowExecutionEngine.oldListMap = Trigger.oldMap;
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'User',Trigger.isInsert);    
        //}    
    }   
    
}
// 
// (c) 2012 Appirio, Inc.
//
// Lead_aInsertaUpdate                                                     
//
// Trigger is used to Send that list of created or updated account to the Rule Engine class for evaluation  
//
// 18 Nov 2012     Peter Babalis     Original
//
trigger Lead_aInsertaUpdate on Lead (after insert, after update) {

    Set<Id> Ids=new Set<Id>();
    String sobjName='Lead';
    
    
    //add all the accountids in the set
    for (Lead a:trigger.new){
        Ids.add(a.Id);
    }//for 

	
	//decide whether we need to start the process:- changing here for trigger chaining @sneha
	//Boolean evaluate = !AW_AdvanceWorkflowExecutionEngine.EvaluationIsRunning ? true : AW_AdvanceWorkflowExecutionEngine.EvaluationRunningFor.contains(sobjName)?false:true;
	Boolean evaluate = AW_AdvanceWorkflowExecutionEngine.EvaluationRunningFor.contains(sobjName)?false:true;
	
    //Send that list of created or updated account to the Rule Engine class for evaluation
    system.debug('--- AW_AdvanceWorkflowExecutionEngine running for '+sobjName+' ? '+evaluate);
    if (evaluate){       
           if(Trigger.isUpdate)
                AW_AdvanceWorkflowExecutionEngine.oldListMap = Trigger.oldMap;
             AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,Trigger.isInsert);    
        
    }   
    
}
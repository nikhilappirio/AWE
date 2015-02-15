// 
// (c) 2012 Appirio, Inc.
//
// Account_aInsertaUpdate                                                     
//
// Trigger is used to Send that list of created or updated account to the Rule Engine class for evaluation  
//
// 18 Nov 2012     Peter Babalis     Original
// 21 Apr  2013    Peter Babalis     Pass the old map for  rule evaluation update and did not meet criteria   
// 13 Nov  2013    Peter Babalis  Trigger Chain

trigger Account_aInsertaUpdate on Account (after insert,after update) 
{  
   // Call AWE  after Insert
    if(trigger.isAfter && trigger.isInsert){
        AccountAWEtriggerHandler.afterInsert(Trigger.new);
    }
   // Call AWE  after Update
    if(trigger.isAfter && trigger.isUpdate){
        AccountAWEtriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
    }
}
/*
http://theblogreaders.com/how-to-get-the-salesforce-instance-server-url-from-apex-trigger/#.UqM40dJDv7U
if(trigger.isBefore == true && (trigger.isInsert == true || trigger.isUpdate == true)) {
URL currentURL = URL.getCurrentRequestUrl();
URL comparisonURL = new URL(URL.getSalesforceBaseUrl().toExternalForm() + Page.YOUR_VF_PAGE_URL.getUrl());
system.<span class="r1it7qhke5" id="r1it7qhke5_6">debug</span>('currentURL:::'+ currentURL);
system.debug('comparisonURL:::'+ comparisonURL);
boolean knownPath = currentURL.getPath() == comparisonURL.getPath();
 
if(knownPath == true) {
// Currently You comming from Custom VF Page ("YOUR_VF_PAGE_URL")
} else {
// Currently You Comming from Standard Account Page Creation.
}
 
}
*/

  /*
 trigger Account_aInsertaUpdate on Account (after insert, after update) {

   
    Set<Id> Ids=new Set<Id>();
    String sobjName='Account';
    
    
    //add all the accountids in the set
    for (Account a:trigger.new){
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
*/
// 
// (c) 2012 Appirio, Inc.
//
// AW_AdvanceWorkflowMain                                                     
//
// Trigger is used to validate only one AdvanceWorkflow per object  
//
// 02 Feb 2013     Peter Babalis     Original
//
trigger AW_AdvanceWorkflowMain on Advance_Workflow__c (before insert, before update) {
     //1. On Before Insert, calling the class validate only one AdvanceWorkflow per object 	
 	if ( Trigger.isBefore && Trigger.isInsert && AW_trgr_AdvanceWorkflowManager.ADVANCEWORKFLOW_FLOW_CONTROLLER )
        AW_trgr_AdvanceWorkflowManager.beforeInsertAdvanceWorkflow(Trigger.new) ;
	
 	//2. On Before Update, calling the class validate only one AdvanceWorkflow per object 
 	 if ( Trigger.isBefore && Trigger.isUpdate && AW_trgr_AdvanceWorkflowManager.ADVANCEWORKFLOW_FLOW_CONTROLLER )
        AW_trgr_AdvanceWorkflowManager.beforeUpdateAdvanceWorkflow(Trigger.new,Trigger.old);
     
}
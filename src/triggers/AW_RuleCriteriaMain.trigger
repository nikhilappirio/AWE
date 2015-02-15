// 
// (c) 2012 Appirio, Inc.
//
// AW_RuleCriteriaMain                                                     
//
// Trigger is used to populate count of rule in an Advance Workflow    
//
// 26 Jan 2013     Peter Babalis     Original
//
trigger AW_RuleCriteriaMain on RuleCriteria__c (after delete, after insert, after update) {
	
//Variable to make sure that the Account Merge is happening only once.
	 
	//1. On After Insert, calling the actual Merge Account call (for Master and Slave Account)	
	if ( Trigger.isAfter && Trigger.isInsert && AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER )
        AW_trgr_RuleCriteriaManager.afterInsertRuleCriteria(Trigger.new) ;
	
 	//2. On After Update, calling the actual merge account call depending on field values	
 	 if ( Trigger.isAfter && Trigger.isUpdate && AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER )
        AW_trgr_RuleCriteriaManager.afterUpdateRuleCriteria(Trigger.new, Trigger.old);
    
    //3. On After Delete, calling the actual Merge Account call (for Master and Slave Account)	
	 if ( Trigger.isAfter && Trigger.isDelete && AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER )
        AW_trgr_RuleCriteriaManager.afterDeleteRuleCriteria(Trigger.old) ;
	  	
}
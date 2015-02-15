// 
// (c) 2012 Appirio, Inc.
//
// AW_RuleArchiveMain                                                     
//
// Trigger is used to  delete rule criteria and actions and
//                 to     reset order, execution behavior and  evaluation rule
//           
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2013     Processing regarding Active, Draft and Archive Status
 trigger AW_RuleArchiveMain on Rule_Archive__c ( after insert ) {
//Variable to make sure that the Account Merge is happening only once.
	 
	//1. On After Insert, calling the actual Merge Account call (for Master and Slave Account)	
	if ( Trigger.isAfter && Trigger.isInsert && AW_trgr_RuleArchiveManager.RULEARCHIVE_FLOW_CONTROLLER )
        AW_trgr_RuleArchiveManager.afterInsertRuleArchive(Trigger.new) ;
 	  	
}
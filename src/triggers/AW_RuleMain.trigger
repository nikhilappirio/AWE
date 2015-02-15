// 
// (c) 2012 Appirio, Inc.
//
// AW_RuleMain                                                     
//
// Trigger is used to populate the count of rule in an Advance Workflow    
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2013     Processing regarding Active, Draft and Archive Status
trigger AW_RuleMain on Rule__c (  after insert, after update, after delete, before delete) {
//Variable to make sure that the Account Merge is happening only once.
     
    //1. On After Insert, calling the class for Processing regarding Active, Draft and Archive Status   
    if ( Trigger.isAfter && Trigger.isInsert && AW_trgr_RuleManager.RULE_FLOW_CONTROLLER )
        AW_trgr_RuleManager.afterInsertRule(Trigger.new) ;
    
    //2. On After Update, calling the class for Processing regarding Active, Draft and Archive Status
     if ( Trigger.isAfter && Trigger.isUpdate && AW_trgr_RuleManager.RULE_FLOW_CONTROLLER )
          //    AW_RuleMainManager.afterUpdateRule(Trigger.new, Trigger.oldMap);
            AW_trgr_RuleManager.afterUpdateRule(Trigger.new, Trigger.old);
    
    //3. On After Delete, calling the class for Processing regarding Active, Draft and Archive Status
    if ( Trigger.isAfter && Trigger.isDelete && AW_trgr_RuleManager.RULE_FLOW_CONTROLLER )
        AW_trgr_RuleManager.afterDeleteRule(Trigger.old) ;
    //4. On Insert or Update Check if the Workflow Limits are met 
    //if(Trigger.isInsert || Trigger.isUpdate){
    //  new AW_Limit_Handler().validateRule(Trigger.new);
    //}
    //if(Trigger.isBefore && Trigger.isDelete && AW_trgr_RuleManager.RULE_FLOW_CONTROLLER)
    //    AW_trgr_RuleManager.beforeDeleteRule(Trigger.old);
        
}
// 
// (c) 2012 Appirio, Inc.
//
// AW_trgr_RuleArchiveManager                                                     
//
// Handler Class to process event for trigger AW_RuleArchiveMain
//Inserts records in the rule archive object and delete rule
// 
//  
// 26 Jan 2013    Original Peter Babalis
//
public with sharing class AW_trgr_RuleArchiveManager {
//Variable to make sure that the Rule insert, update  delete  is happening only once.
  public static Boolean RULEARCHIVE_FLOW_CONTROLLER = true;
 
	
  public static void afterInsertRuleArchive( List<Rule_Archive__c> newlist){
  Set<Id> ruledeleteIds = new Set<Id>();  
  List<Rule__c> lstRulesToDelete = new List<Rule__c>();
 // List<Rule__c>  deleteRuleList = new List<Rule__c>();
  
  system.debug('-- afterInsertRuleArchive NEW LIST SIZE  ' +newlist.size() +'NEW LIST ' + newlist);

 for(Rule_Archive__c rulearchive :  newList){
 	if( rulearchive.Status__c=='Archived' && rulearchive.Rule_Reference_Id__c != null){
 		ruledeleteIds.add(rulearchive.Rule_Reference_Id__c);
    }
 }
  system.debug('-- afterInsertRuleArchive   LIST SIZE of ruledeleteIds   ' +ruledeleteIds.size() +'  LIST  ruledeleteIds' + ruledeleteIds);
 if (ruledeleteIds.size() >0 ) {  
 for(Rule__c r  : [Select Id 
                   From Rule__c 
                   WHERE  id in: ruledeleteIds]) {
                   lstRulesToDelete.add(r);   
   }
    
system.debug('-- afterInsertRuleArchive   LIST lstRulesToDelete  ' +lstRulesToDelete  );    
system.debug('-- afterInsertRuleArchive   LIST lstRulesToDelete  SIZE  ' +lstRulesToDelete.size() );    
if (lstRulesToDelete.size() >0 ) delete lstRulesToDelete;
system.debug('-- afterInsertRuleArchive   DELETE AFTER   '  );    

}         	     
RULEARCHIVE_FLOW_CONTROLLER = false;
 }
}
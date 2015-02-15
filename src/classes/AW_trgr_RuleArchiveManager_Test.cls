// 
// (c) 2012 Appirio, Inc.
// AW_trgr_RuleArchiveManager_Test                                                     
// This test class tests AW_trgr_RuleArchiveManager  functionality   
//
// 04 Feb 2013     Peter Babalis       Original
//  
//  
//
@isTest
public class AW_trgr_RuleArchiveManager_Test {

static testMethod void testRuleArchive() {
String ruleid;
Set<Id>  deletedruleIds = new Set<Id>();  
List<Rule_Archive__c> testListArch  = new List<Rule_Archive__c>();
List<Rule__c> testListdelete  = new List<Rule__c>();
      
Rule__c rl = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Order__c=10,Version__c=1,Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
insert rl;

RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rl.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
insert ruleCriteria ;
RuleAction__c ruleaction = new RuleAction__c(rule__c=rl.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
insert ruleaction;

ruleid=rl.Id;
Rule_Archive__c rlarch = new Rule_Archive__c(Prior_Status__c='Active',Order__c= rl.Order__c,Object__c= rl.Object__c,Status__c= 'Archived',Rule_Name__c =rl.Name,Rule_Reference_Id__c=rl.Id,Description__c= rl.Description__c );
insert rlarch;
testListArch = [ Select Id,Status__c,Rule_Reference_Id__c from Rule_Archive__c where Rule_Reference_Id__c = :ruleid ];
AW_trgr_RuleArchiveManager.afterInsertRuleArchive(testListArch);
     
testListdelete = [ Select Id from Rule__c where id =:ruleid ];
for (integer i=0; i<testListdelete.size();i++   ){ 
  	 deletedruleIds.add(testListdelete[i].Id);
}

System.assert(deletedruleIds.size() == 0 );
System.assert(AW_trgr_RuleArchiveManager.RULEARCHIVE_FLOW_CONTROLLER == false );
     
}

}
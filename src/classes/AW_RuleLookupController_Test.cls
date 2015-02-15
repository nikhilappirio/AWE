/**
 * Test Class of AW_RuleLookupController
 */
@isTest
private class AW_RuleLookupController_Test {

    static testMethod void testRuleLookup() {
       Advance_Workflow__c wfToInsert = AW_TestUtil.createWorkflow( 'WFAccount', 'Account', true,  'WF Description',true);
       List<Rule__c> rules = new List<Rule__c>();
       for(Integer i = 0 ; i < 30 ; i++){
       	rules.add( new Rule__c(Name = 'How to enter merge values as criteria Contact_test' + i,
                                        Status__c = 'Draft',
                                        Object__c = 'Contact', 
                                        Version__c = 1,
                                        Description__c = 'Rule 1 Description',
                                        Evaluation_Rule__c='Record is created or edited'
                                        //,Advance_Workflow__c = advanceWF.id
                                        ));
       }
       insert rules;
	    RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rules.get(0), 'Contact', 'Equals', 'Test', 'LastName', 'LastName', 'STRING', true);     
	    
	    RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rules.get(0), 'Contact', True, 'FirstName', 'Update Field', 'FirstName', true);
	    Apexpages.currentPage().getParameters().put('objName', 'Contact');
	    Apexpages.currentPage().getParameters().put('sText', 'How');
	    AW_RuleLookupController ruleLookup = new AW_RuleLookupController();
	    
	    ruleLookup.search();
	    System.assert(ruleLookup.searchedSobject.size() > 0);
	    System.assert(ruleLookup.hasNext);
	    ruleLookup.next();
	    System.assert(ruleLookup.hasPrevious);
	    ruleLookup.previous();
	    System.assert(ruleLookup.pageSize != 0);
    }
}
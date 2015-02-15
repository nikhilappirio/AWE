// 
// (c) 2012 Appirio, Inc.
//
//  AW_AdvanceWorkflowExecutionHelper_Test                                                    
//
// This class contains test methods for AW_AdvanceWorkflowExecutionHelper class 
//
// 26 March 2014     Peter Babalis     Original

@isTest
private class AW_AdvanceWorkflowExecutionHelper_Test {

    static testMethod void testJoinSet() {
    	Set<String> setValuesToBeJoin = new Set<String>{'FirstString','SecondString'};
        String connectedString = AW_AdvanceWorkflowExecutionHelper.joinSet(setValuesToBeJoin, ',');
        System.assertEquals(connectedString, 'FirstString,SecondString');
        
        connectedString = AW_AdvanceWorkflowExecutionHelper.joinSet(setValuesToBeJoin, null);
    }
    
    
    static testMethod void testRecordInfoMethods() {
    	
    	Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    	User user = AW_TestUtil.createUser('user1@pao.com', 'user1@acme.com', 'firstName', 'lastName', 'usr1', profile.Id, true);
    	Rule__c rule = AW_TestUtil.createRule('Test Account', 'Account', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Account', 'Equals', '0001111', 'RecordTypeId', 'RecordTypeId', 'String', false);
        ruleCriteria.Record_Type_Id__c = '88888888';
        insert ruleCriteria;
        RuleAction__c ruleaction = AW_TestUtil.createRuleAction(rule, 'Account', false, 'Name', 'Upsert Related Object', 'TestUpdate', true);
        RuleAction__c ruleaction2 = AW_TestUtil.createRuleAction(rule, 'Account', false, 'Type', 'Upsert Related Object', 'Prospect', true);
        rule.Status__c = 'Active';
        update rule; 
    	
		Test.startTest();    	
			// getUserDetails method testing
	    	Set<String> userIds = new Set<String>{user.id};
	    	Map<Id,User> userMap = AW_AdvanceWorkflowExecutionHelper.getUserDetails(userIds);
	    	System.assert(userMap.containsKey(user.id), 'User map should contain userid of the test user.');
	    	
	    	Set<Id> ruleIds = new Set<Id>{ Rule.Id };
	    	List<Rule__c> lstRules = AW_AdvanceWorkflowExecutionHelper.getActiveCriteria(ruleIds,'Account', false);
	    	ruleCriteria = (RuleCriteria__c)lstRules[0].getSObjects('Rule_Criteria__r')[0];
	    	System.assertEquals(ruleCriteria.Record_Type_Id__c, ruleCriteria.Matching_Value__c,'Matching value should be equal to record type id.');
	    	
	    	// getActiveRuleActions method testing
	    	Map<Id,Rule__c> ruleMap = AW_AdvanceWorkflowExecutionHelper.getActiveRuleActions(ruleIds,'Account', false);
	    	System.assert(ruleMap.containsKey(rule.id), 'Rule map should contains key for rule id');
	    	
	    	// getActiveRuleActions method testing
	    	ruleMap = AW_AdvanceWorkflowExecutionHelper.getActiveRuleActionsSubset(ruleIds,'Account', new Set<Id>{ruleaction.id}, false);
	    	System.assert(ruleMap.containsKey(rule.id), 'Rule map should contains key for rule id');
	    	
	    	// getInsertRelatedRecordInfo method testing
	    	Map<Id,RuleAction__c> mapRuleAction = AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfo(ruleIds);
	    	System.assert(mapRuleAction.containsKey(ruleaction.id), 'RuleAction map should contains key for RuleAction id');
	    	
	    	// getInsertRelatedRecordInfoForActions method testing
	    	mapRuleAction = AW_AdvanceWorkflowExecutionHelper.getInsertRelatedRecordInfoForActions(new Set<Id>{ruleaction.id});
	    	System.assert(mapRuleAction.containsKey(ruleaction.id), 'RuleAction map should contains key for RuleAction id');
	    	
	    	// getUpsertRelatedRecordInfo method testing
	    	mapRuleAction = AW_AdvanceWorkflowExecutionHelper.getUpsertRelatedRecordInfo(ruleIds);
	    	System.assert(mapRuleAction.containsKey(ruleaction.id), 'RuleAction map should contains key for RuleAction id');
	    	
	    	// buildListForEmail method testing
	    	Map<String,Map<String,List<RuleAction__c>>> usersInSendEmailAction = new Map<String,Map<String,List<RuleAction__c>>>();
	    	
	    	usersInSendEmailAction = AW_AdvanceWorkflowExecutionHelper.buildListForEmail(usersInSendEmailAction, user.id, ruleaction, rule.id);
	    	usersInSendEmailAction = AW_AdvanceWorkflowExecutionHelper.buildListForEmail(usersInSendEmailAction, user.id, ruleaction2, rule.id);
	    	system.assert(usersInSendEmailAction.containsKey(user.id));
	    	Map<String ,List<RuleAction__c>> objTemp=  usersInSendEmailAction.get(user.id);
	    	system.assert(objTemp.containsKey(rule.id));
	    	system.assert(objTemp.get(rule.id).size() == 2);
	    	
    	Test.stopTest();
    	
    }
    
     static testMethod void testHandleError() {
     	
     	try{
     		Account account = new Account();
     		insert account; // insert account without name to genrate a exception
     	}
     	catch(Exception ex){
     		AW_AdvanceWorkflowExecutionHelper.handleError(ex);
     	}
     }
     
     static testMethod void testGetValueForUpdateAction(){
     	
     	Rule__c rule = AW_TestUtil.createRule('Test Account', 'Account', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Account', 'Equals', '0001111', 'RecordTypeId', 'RecordTypeId', 'String', true);
     	RuleAction__c ruleaction = AW_TestUtil.createRuleAction(rule, 'Account', false, 'Name', 'Upsert Related Object', 'TestUpdate', true);
     	ruleaction.Field_Type__c = 'String';
     	
     	String value = AW_AdvanceWorkflowExecutionHelper.getValueForUpdateAction(ruleaction);
     	system.assertEquals(value, 'TestUpdate');
     	
     	ruleaction.Value__c = null;
     	ruleaction.Long_Value__c = 'long value';
     	value = AW_AdvanceWorkflowExecutionHelper.getValueForUpdateAction(ruleaction);
     	//system.assertEquals(value, 'long value');
     	
     	ruleaction.Field_Type__c = 'REFERENCE';
     	ruleaction.Reference_Id__c = ruleaction.id;
     	value = AW_AdvanceWorkflowExecutionHelper.getValueForUpdateAction(ruleaction);
     	system.assertEquals(value, ruleaction.id);
     	
     }
}
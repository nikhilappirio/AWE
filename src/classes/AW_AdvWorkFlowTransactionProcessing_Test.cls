// 
// (c) 2012 Appirio, Inc.
// AW_AdvWorkFlowTransactionProcessing_Test                                                     
// This test class tests AW_AdvanceWorkflowTransactionProcessing functionality   
//
// 24 March 2014     Peter Babalis       Original
//  
//  
//
@isTest
private class AW_AdvWorkFlowTransactionProcessing_Test {
	
	static string ruleactionid;
	static string ruleid;
    static testMethod void testPerformDMLOperations() {
        
        List<SObject> listSObjects = new List<SObject>();
        
        Rule__c ruleToInsert = AW_TestUtil.createRule('Test Rule1', 'Rule__c', 'Draft', 'Record is created or edited', 'Rule 1 Description', false);
        Rule__c ruleToUpdate = AW_TestUtil.createRule('Test Rule2', 'Rule__c', 'Draft', 'Record is created or edited', 'Rule 2 Description', true);
        listSObjects.add(ruleToInsert);
        listSObjects.add(ruleToUpdate);
        
        Map<Id,SObject> toupdateSobj = new Map<Id, SObject>();
        toupdateSobj.put(ruleToUpdate.id, ruleToUpdate);
        
        Test.startTest();
        	ruleToUpdate.Description__c = 'Updated description';
        	Boolean result = AW_AdvanceWorkflowTransactionProcessing.performDMLOperations(toupdateSobj, listSObjects);
        	system.assertEquals(result, true, 'If method executed sucessfully then should return true');
        	
        Test.stopTest();
    }
    
     /*
     static testMethod void testAddRecordstoExecutionHistory() {
     	
     	Account acc1 = AW_TestUtil.createAccount('Test Account1', false);
                                                                                                                                                                                                                                                    
        Account acc2 = AW_TestUtil.createAccount('Test Account2', false);
         
         insert new List<Account>{acc1,acc2};     
        //insert new List<Account>{acc1,acc2}; 
         List<SObject> lstSObject = new List<SObject>();
     	lstSObject.add(acc1);
     	lstSObject.add(acc2);
     	List<Sobject> recordBeforeUpdate = new List<SObject>();
        recordBeforeUpdate.add(acc1);
        
        Map<Id,SObject> recordsAfterUpdate = new Map<Id,SObject>();
        recordsAfterUpdate.put(acc1.id, acc1);
       
       // setupData();
     	// insert new List<Account>{acc1,acc2};     
       // Rule__c ruleToInsert = AW_TestUtil.createRule('Test Rule1', 'Rule__c', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
     	Rule__c rule = AW_TestUtil.createRule('Test Account', 'Account', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
        
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Account', 'Equals', 'Apparel', 'Industry', 'Name', 'Picklist', true);     
        
        RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rule, 'Account', True, 'Type', 'Update Field', 'TestUpdate', true);
        
        rule.Status__c = 'Active';
        update rule;
     	List<Rule__c> lstValidRules = new List<Rule__c>();
     	lstValidRules.add(rule);
     	 
     	
     	Map<Id,List<SObject>> validRecords = new Map<Id,List<SObject>>();
     	validRecords.put(rule.id, lstSObject);
     	        
     	Boolean result = AW_AdvanceWorkflowTransactionProcessing.addRecordstoExecutionHistory(lstValidRules,validRecords,recordBeforeUpdate,recordsAfterUpdate);
     //	Boolean result = AW_AdvanceWorkflowTransactionProcessing.addRecordstoExecutionHistory(validRecords);
     	//system.assertEquals(result, true, 'If method executed sucessfully then should return true');
     	
     	List<Rule_Execution_History__c> ruleExecutionHistory = [SELECT Id FROM Rule_Execution_History__c WHERE Rule__c =:rule.Id];
     	system.assertEquals(ruleExecutionHistory.size(), 1, 'Should have 1 rule execution history record.');
     	
     	
     }
     */
     
     static testMethod void testProcessLookupUpdatesAndBulkAPi(){
     	setupData();
     	Account acc1 = AW_TestUtil.createAccount('Test Account1', false);
        Account acc2 = AW_TestUtil.createAccount('Test Account2', false);
        insert new List<Account>{acc1,acc2};     
    
        Object_Action_Execution__c ObjActionExec1 = AW_TestUtil.createObjectActionExecution(acc1.id, 'New', 'Bulk API', acc1.Name, ruleactionid, false);
        Object_Action_Execution__c ObjActionExec2 = AW_TestUtil.createObjectActionExecution(acc2.id, 'New', 'Bulk API', acc2.Name, ruleactionid, false);
        
        List<Object_Action_Execution__c> lstObjectActionExecution = new List<Object_Action_Execution__c>{ObjActionExec1, ObjActionExec2};
     	AW_AdvanceWorkflowTransactionProcessing.processLookupUpdatesAndBulkAPi(lstObjectActionExecution, 'rule');
     	System.assert(ObjActionExec1.id != null, 'Object Action Execution record should be inserted.');
     	System.assert(ObjActionExec2.id != null, 'Object Action Execution record should be inserted.');
     }
     
     
     static testMethod void testProcessBulkAPiTransactions(){
     	setupData();
     	Account acc1 = AW_TestUtil.createAccount('Test Account1', false);
        Account acc2 = AW_TestUtil.createAccount('Test Account2', false);
        insert new List<Account>{acc1,acc2};     
    	
        Object_Action_Execution__c ObjActionExec1 = AW_TestUtil.createObjectActionExecution(acc1.id, 'New', 'Bulk API', acc1.Name, ruleactionid, false);
        Object_Action_Execution__c ObjActionExec2 = AW_TestUtil.createObjectActionExecution(acc2.id, 'New', 'Bulk API', acc2.Name, ruleactionid, false);
       
        List<Object_Action_Execution__c> lstObjectActionExecution = new List<Object_Action_Execution__c>{ObjActionExec1, ObjActionExec2};
     	AW_AdvanceWorkflowTransactionProcessing.processBulkAPiTransactions(lstObjectActionExecution, 'rule');
     	System.assert(ObjActionExec1.id != null, 'Object Action Execution record should be inserted.');
     	System.assert(ObjActionExec2.id != null, 'Object Action Execution record should be inserted.');
     }
     
     static testMethod void testHandleError(){
     	try{
     		// Inserting account without name to genrate exception
     		Account account = new Account();
     		insert account;
     	}
     	catch(Exception ex){
     		AW_AdvanceWorkflowTransactionProcessing.handleError(ex);
     	}
     }
     
     static void setupData() {
        
        Rule__c rule = AW_TestUtil.createRule('Test Account', 'Account', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
        
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Account', 'Equals', 'Apparel', 'Industry', 'Name', 'Picklist', true);     
        
        RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rule, 'Account', True, 'Type', 'Update Field', 'TestUpdate', true);
        
        rule.Status__c = 'Active';
        update rule;
        ruleactionid=ruleaction1.Id;
        ruleid=rule.Id;
     }
}
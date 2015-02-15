@isTest
public with sharing class AW_SimulateWorkflowCapture_Test {
	
	private static Id workflowId;
	private static Rule__c rule1;
	private static Rule__c rule2;
	private static Rule__c rule3;
	
	/*
	*	SetupTest Data
	*/
	private static void setUpData(){
		workflowId = Database.insert(new Advance_Workflow__c(Name='Test Workflow',Object__c='Account',Enabled__c=true,Description__c='This is a test workflow')).getId();
		
		// Create rules 
		
        rule1  = new Rule__c(Name = 'Test rule 1',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule1 ;
        RuleCriteria__c ruleCriteria1 = new RuleCriteria__c(rule__c=rule1.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria1 ;
        RuleAction__c ruleaction1 = new RuleAction__c(rule__c=rule1.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate1');
        insert ruleaction1;
        
        rule2  = new Rule__c(Name = 'Test rule 2',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 2 Description');
        insert rule2 ;
        RuleCriteria__c ruleCriteria2 = new RuleCriteria__c(rule__c=rule2.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria2 ;
        RuleAction__c ruleaction2 = new RuleAction__c(rule__c=rule2.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate2');
        insert ruleaction2;
        
        rule3  = new Rule__c(Name = 'Test rule 3',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 3 Description');
        insert rule3 ;
        RuleCriteria__c ruleCriteria3 = new RuleCriteria__c(rule__c=rule3.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria3 ;
        RuleAction__c ruleaction3 = new RuleAction__c(rule__c=rule3.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate3');
        insert ruleaction3;
        
        
		
		rule1.Order__c=10;
        rule1.Status__c = 'Active';
        rule1.Execution_Behavior__c='Execute and Exit';
        rule1.Advance_Workflow__c=workflowId;
        update rule1;
        
		rule2.Order__c=20;
        rule2.Status__c = 'Active';
        rule2.Execution_Behavior__c='Execute and Exit';
        rule2.Advance_Workflow__c=workflowId;
        update rule2;
        
        rule3.Order__c=30;
        rule3.Status__c = 'Active';
        rule3.Execution_Behavior__c='Execute and Exit';
        rule3.Advance_Workflow__c=workflowId;
        update rule3;
	}
	
	/*
	*	SetupTest Account Data for test
	*/
	private static void setUpAccountData(){
		List<Account> accountsList = new List<Account>{	new Account(Name='Test Account 1'),
														new Account(Name='Test Account 2'),
														new Account(Name='Test Account 3'),
														new Account(Name='Test Account 4')
													  };
		insert accountsList;
	}
	
	/*
	*	test Constructor
	*/
	static testMethod void test_Constructor(){
		Test.startTest();
		setUpData();
		Advance_Workflow__c workflow = [SELECT Id, Name FROM Advance_Workflow__c WHERE Id=:workflowId LIMIT 1];
		System.Test.setCurrentPageReference(new PageReference('/apex/x?id='+workflowId));
		AW_SimulateWorkflowCapture cls = new AW_SimulateWorkflowCapture(new ApexPages.standardController(workflow));
		System.assertNotEquals(true,cls.showInputBlock);
		System.assertEquals('workflow',cls.selectedMode);
		System.assertNotEquals(1,cls.fieldsList.size());
		Test.stopTest();
	}
	
	/*
	*	test simulateWorkflow method	
	*/
	static testMethod void test_simulateWorkflow(){
		Test.startTest();
		setUpData();
		setUpAccountData();
		Advance_Workflow__c workflow = [SELECT Id, Name FROM Advance_Workflow__c WHERE Id=:workflowId LIMIT 1];
		System.Test.setCurrentPageReference(new PageReference('/apex/x?id='+workflowId));
		AW_SimulateWorkflowCapture  cls = new AW_SimulateWorkflowCapture(new ApexPages.standardController(workflow));
		
		cls.selectedMode = 'rule';
		cls.operationType = 'update';
		cls.recordName = 'Test Account 1,Test Account 2,Test Account 3';
		cls.ruleCriterias();
		PageReference pReference = cls.simulateWorkflow();
		Test.stopTest();
	
	}
	
	
	/*
	*	test getRules method
	*/
	static testMethod void test_getRules(){
		Test.startTest();
		setUpData();
		Advance_Workflow__c workflow = [SELECT Id, Name FROM Advance_Workflow__c WHERE Id=:workflowId LIMIT 1];
		System.Test.setCurrentPageReference(new PageReference('/apex/x?id='+workflowId));
		AW_SimulateWorkflowCapture  cls = new AW_SimulateWorkflowCapture(new ApexPages.standardController(workflow));
		System.assertEquals(3,cls.getRules().size());
		Test.stopTest();
	}
	
	/*
	*	test checkSelectedMode method
	*/
	static testMethod void test_checkSelectedMode(){
		Test.startTest();
		setUpData(); 
		Advance_Workflow__c workflow = [SELECT Id, Name FROM Advance_Workflow__c WHERE Id=:workflowId LIMIT 1];
		System.Test.setCurrentPageReference(new PageReference('/apex/x?id='+workflowId));
		AW_SimulateWorkflowCapture cls = new AW_SimulateWorkflowCapture(new ApexPages.standardController(workflow));
		cls.checkSelectedMode();
		
		// Test with value
		cls.selectedMode = 'workflow';
		cls.operationType = 'create';
		cls.checkSelectedMode();
		System.assertEquals(3,cls.criteriaList.size());
		Test.stopTest();
	}
	
	/*
	*	test ruleCriterias method
	*/
	static testMethod void test_ruleCriterias(){
		Test.startTest();
		setUpData();
		Advance_Workflow__c workflow = [SELECT Id, Name FROM Advance_Workflow__c WHERE Id=:workflowId LIMIT 1];
		System.Test.setCurrentPageReference(new PageReference('/apex/x?id='+workflowId));
		AW_SimulateWorkflowCapture cls = new AW_SimulateWorkflowCapture(new ApexPages.standardController(workflow));
		
		// Test with value
		cls.selectedMode = 'rule';
		cls.operationType = 'update';
		cls.ruleCriterias();
		
		// Test selected mode is null
		List<Apexpages.Message> messages = ApexPages.getMessages();
		System.assertEquals(1, messages.size());
		System.assertNotEquals(true, cls.showInputBlock);
		Test.stopTest();
	}
}
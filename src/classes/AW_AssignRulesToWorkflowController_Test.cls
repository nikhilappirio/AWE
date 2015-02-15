// 
// (c) 2012 Appirio, Inc.
// Name             : AW_AssignRulesToWorkflowController_Test                                                     
// This is the test classs for AssignRuleToRuleExtPlanController
//
// 18 Nov 2012     Peter Babalis     Original
//  
//  
@isTest
public class AW_AssignRulesToWorkflowController_Test{

    static Rule__c rule;
    static Rule__c rule2;
    
    /**
    * Create setup data
    */
    static void setupData(){
        
        rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
                
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
        insert a1;
        //rule.Available__c = true;
        rule.Status__c = 'Draft';
        
        update rule;
        
        rule2 = new Rule__c(Name = 'Test Test Account2',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 2 Description');
        //rule2 = new Rule__c(Name = 'Test Test Account2',Object__c = 'Account');
        insert rule2;
        RuleCriteria__c ruleCriteria2 = new RuleCriteria__c(rule__c=rule2.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria2 ;
        RuleAction__c a2 = new RuleAction__c(rule__c=rule2.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
        insert a2;
       // rule2.Available__c = true;
        rule2.Status__c = 'Draft';
        update rule2;
        
    }
    
       
    /*
    'Order number Not Zero'
    */
    public static TestMethod void updateRuleTestOrderNotZero(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        
        rule.Order__c=0;
        AW_AssignRulesToWorkflowController  controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        
        PageReference page = controller.updateRule();
        Test.stopTest();
       // system.assertEquals(null,page);
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    
    /*
    'Order number already used'
    */
    public static TestMethod void updateRuleTestOrderNumberUsed(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        rule2.Order__c=10;
        rule2.Status__c = 'Active';
        rule2.Execution_Behavior__c='Execute and Exit';
        rule2.Advance_Workflow__c=plan.id;
        update rule2;
        rule.Order__c=10;
        AW_AssignRulesToWorkflowController  controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        PageReference page = controller.updateRule();
        Test.stopTest();
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    /**
    * Test updateRule method
    */
     public static TestMethod void updateRuleTest(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        AW_AssignRulesToWorkflowController  controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        PageReference page = controller.updateRule();
        Test.stopTest();
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    
    /**
    * Test updateRule with validation error
    */    
    public static TestMethod void updateRuleValidationTest(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        rule2.Advance_Workflow__c = plan.Id;
        update rule2;
        plan.Enabled__c = true;
        update plan;
        AW_AssignRulesToWorkflowController controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        controller.updateRule();
        Test.stopTest();
    }
    
    /**
    * Test createRuleExecutionPlan method
    */    
    public static TestMethod void createRuleExecutionPlanTest(){
        setupData();
        AW_AssignRulesToWorkflowController controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        controller.createRuleExecutionPlan();
        Test.stopTest();
        system.assertNotEquals(0,[Select Id from Advance_Workflow__c where Object__c =: rule.Object__c].size());   
    }
    
    
    
    /**
    * Test getExecutionBehavior method
    */    
    public static TestMethod void getExecutionBehaviorTest(){
        setupData();
        AW_AssignRulesToWorkflowController controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        List<SelectOption> options = controller.getExecutionBehavior();
        Test.stopTest();
        system.assertNotEquals(0,options.size());   
    }
    
    /**
    * Test Cancel method
    */    
    public static TestMethod void cancelTest(){
        setupData();
        AW_AssignRulesToWorkflowController controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        PageReference page = controller.cancel();
        Test.stopTest();
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    
     public static TestMethod void updateRule1TestOrderNotZero(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        
        rule.Order__c=0;
        AW_AssignRulesToWorkflowController  controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        
        PageReference page = controller.updateRule1();
        Test.stopTest();
       // system.assertEquals(null,page);
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    
    public static TestMethod void updateRule1TestOrderNumberUsed(){
        setupData();
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c=True;
        insert plan;
        rule2.Order__c=10;
        rule2.Status__c = 'Active';
        rule2.Execution_Behavior__c='Execute and Exit';
        rule2.Advance_Workflow__c=plan.id;
        update rule2;
        rule.Order__c=10;
        AW_AssignRulesToWorkflowController  controller = new AW_AssignRulesToWorkflowController(new ApexPages.standardController(rule));
        Test.startTest();
        PageReference page = controller.updateRule1();
        Test.stopTest();
        system.assertEquals('/'+rule.id,page.getUrl());   
    }
    
}
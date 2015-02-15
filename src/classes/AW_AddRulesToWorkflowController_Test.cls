// 
// (c) 2012 Appirio, Inc.
// AW_AddRulesToWorkflowController_Test                                                     
// This test class tests AddRulesToRuleExePlanController functionality   
//
// 18 Nov 2012     Peter Babalis       Original
//  
//  
//

@isTest
public class AW_AddRulesToWorkflowController_Test{
    
    static Advance_Workflow__c plan;
    static Rule__c rule2;
    
    /**
    * Create setup data
    */
    static void setupData(){
        plan = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c =True;
        insert plan;
        
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a1;
        //rule.Available__c = true;
        rule.Status__c = 'Active';
        update rule;
        
        rule2 = new Rule__c(Name = 'Test Test Account2',Object__c = 'Account',Evaluation_Rule__c='Record is created or edited', Status__c='Draft',Description__c='Rule 2 Description');
        insert rule2;
        RuleCriteria__c ruleCriteria2 = new RuleCriteria__c(rule__c=rule2.id,related_object__c='Account',  Matching_Type__c='Equals', Matching_Value__c='Test',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria2 ;
        RuleAction__c a2 = new RuleAction__c(rule__c=rule2.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a2;
       // rule2.Available__c = true;
        rule.Status__c = 'Active';
        update rule2;
        
    }

    /**
    * Test addRule method
    */    
    public static TestMethod void addRuleTest(){
        setupData();
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
        
        controller.listAddRulesPerObject[0].isAdd = true;
        controller.listAddRulesPerObject[0].Rules.Order__c = 10;
        Test.startTest();
        PageReference page = controller.addRule();
        Test.stopTest();
    //  system.assertEquals(page.getURL(),'/'+plan.id);
        system.assertEquals(page.getURL(),'/apex/AW_ListRules_VF?id='+plan.id);
    }
    
    /**
    * Test addRule method
    */    
    public static TestMethod void addRuleOrderZeroTest(){
        setupData();
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
       
        controller.listAddRulesPerObject[0].isAdd = true;
        controller.listAddRulesPerObject[0].Rules.Order__c = 0;
        Test.startTest();
        PageReference page = controller.addRule();
        Test.stopTest();
        system.assertEquals(null,page);
    }
    
     /**
    * Test addRule method
    */    
    public static TestMethod void addRuleOrderNullTest(){
        setupData();
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
       
        controller.listAddRulesPerObject[0].isAdd = true;
        Test.startTest();
        PageReference page = controller.addRule();
        Test.stopTest();
        system.assertEquals(null,page);
    }
    
    /**
    * Test getExecutionBehavior 
    */
    public static TestMethod void getExecutionBehaviorTest(){
        setupData();
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
       Test.startTest();
        List<SelectOption> result = controller.getExecutionBehavior();
        Test.stopTest();
        system.assertNotEquals(0,result.size());
    }
    
    /**
    * Test cancel method
    */
    public static TestMethod void cancelTest(){
        setupData();
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
        Test.startTest();
        PageReference page = controller.Cancel();
        Test.stopTest();
       // system.assertEquals(page.getURL(),'/'+plan.id);
        system.assertEquals(page.getURL(),'/apex/AW_ListRules_VF?id='+plan.id);
     }
    
    /**
    * Test add Rule when Execution Plan is active
    */
    public static TestMethod void addRuleInAvailablePlanTest(){
        setupData();
        rule2.Advance_Workflow__c = plan.Id;
        
       
        update rule2;
        plan.Enabled__c = true;
        update plan;
        AW_AddRulesToWorkflowController controller = new AW_AddRulesToWorkflowController(new ApexPages.standardController(plan));
         for(AW_AddRulesToWorkflowController.RulesPerObject obj:controller.listAddRulesPerObject){
            obj.isAdd = true;
            obj.Rules.Order__c = 10;
        }
        Test.startTest();
        PageReference page = controller.addRule();
        Test.stopTest();
        system.assertEquals(null,page);
    }
}
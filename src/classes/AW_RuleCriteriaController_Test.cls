// 
// (c) 2012 Appirio, Inc.
//
//  AW_RuleCriteriaController_Test	                                                  
//
// This class contains test methods for AW_RuleCriteriaController_Test class
//
// 10 Oct 2012     Peter Babalis     Original
// 
@isTest

public class AW_RuleCriteriaController_Test{

    public static testMethod void testConstructor(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        Test.startTest();
            AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        Test.stopTest();
        system.assertNotEquals(manageRC.objType,null);
        
    }
    
    public static testMethod void testConstructorNew(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,Matching_type__c='equals',Matching_Value__c='test');
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleCriteria);
        Test.startTest();
            AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        Test.stopTest();
        system.assertNotEquals(manageRC.objType,null);
        
    }
    
    public static testMethod void testGetFieldNames(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        ApexPages.currentPage().getParameters().put('parentName','Account');
        Test.startTest();
            manageRC.getFieldNames();
        Test.stopTest();
        system.assertEquals(manageRC.fieldOption.size()>0,true);
    }
    
    public static testMethod void testSetFieldAPIName(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        ApexPages.currentPage().getParameters().put('fieldName','Name');
        Test.startTest();
            manageRC.setFieldApiName();
        Test.stopTest();
        system.assertEquals(manageRC.newRuleCriteria.field_API_name__c,'Name');
    }
    
    public static testMethod void testAdditionalMethods(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        ApexPages.currentPage().getParameters().put('fieldName','Industry');
        Test.startTest();
            manageRC.setFieldApiName();
            manageRC.getFieldOperators();
            manageRC.getPickListValues();
            
           ApexPages.currentPage().getParameters().put('fieldName','AnnualRevenue');
           manageRC.setFieldApiName(); 
           manageRC.getFieldOperators();
        Test.stopTest();
        system.assertEquals(manageRC.newRuleCriteria.field_API_name__c,'AnnualRevenue');
    }
    
    public static testMethod void testCrossFormulaOperator(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        ApexPages.currentPage().getParameters().put('fieldName','CrossFormula');
        Test.startTest();
            manageRC.setFieldApiName();
            manageRC.getFieldOperators();
        Test.stopTest();
        
    }
    
    public static testMethod void testSaveRuleCriteria(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        manageRC.fieldType = 'Name';
        Test.startTest();
        PageReference page = manageRC.saveRuleCriteria();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/'+ruleC.Rule__c);
    }
    
    public static testMethod void testSaveAndNewRuleCriteria(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        manageRC.fieldType = 'Name';
        Test.startTest();
        PageReference page = manageRC.saveAndNewRuleCriteria();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleCriteria_VF');
    }
    
    public static testMethod void testSaveRuleCriteriaFailure(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        manageRC.fieldType = null;
        Test.startTest();
        PageReference page = manageRC.saveRuleCriteria();
        Test.stopTest();
        system.assertEquals(page,null);
    }
    
    public static testMethod void testSaveAndNewRuleCriteriaFailure(){
        RuleCriteria__c ruleC = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleC);
        AW_RuleCriteriaController manageRC = new AW_RuleCriteriaController(stdcon);
        manageRC.fieldType = null;
        Test.startTest();
        PageReference page = manageRC.saveAndNewRuleCriteria();
        Test.stopTest();
        system.assertEquals(page,null);
    }
    public static RuleCriteria__c setupData(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text',Matching_type__c='equals',Matching_Value__c='test');
        insert ruleCriteria ;
        return ruleCriteria ;
    }
}
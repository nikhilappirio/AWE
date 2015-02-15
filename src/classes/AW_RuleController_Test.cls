// 
// (c) 2012 Appirio, Inc.
//
//  AW_RuleController_Test                                                    
//
// This class contains test methods for AW_RuleController class Apex classes
//
// Unit tests are class methods that verify whether a particular piece
// of code is working properly. Unit test methods take no arguments,
// commit no data to the database, and are flagged with the testMethod
// keyword in the method definition.
//
// All test methods in an organization are executed whenever Apex code is deployed
// to a production organization to confirm correctness, ensure code
// coverage, and prevent regressions. All Apex classes are
// required to have at least 75% code coverage in order to be deployed
// to a production organization. In addition, all triggers must have some code coverage.
// 
// The @isTest class annotation indicates this class only contains test
// methods. Classes defined with the @isTest annotation do not count against
// the organization size limit for all Apex scripts.
//
// See the Apex Language Reference for more information about Testing and Code Coverage.
//
// 10 Oct 2012     Peter Babalis     Original
//  
//
/** 
 * This class contains test methods for ManageRules class
 */

@isTest
public class AW_RuleController_Test{
    
    public static testmethod void testConstructor(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
            AW_RuleController manageRules = new AW_RuleController(stdcon);
        Test.stopTest();
        System.assertEquals(manageRules.objOptions.size()>0,true);    
    }
    
    public static testmethod void testSaveRule(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
            AW_RuleController manageRules = new AW_RuleController(stdcon);
            manageRules.newRule.name = 'Test Rule Edited';
            Pagereference page = manageRules.saveRule();
       Test.stopTest();
       system.assertEquals(page.getURL(),'/'+manageRules.newRule.id);   
    }
    
    public static testmethod void testSaveAndNewRule(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
             AW_RuleController manageRules = new AW_RuleController(stdcon);
             manageRules.newRule.name = 'Test Rule Edited';
            Pagereference page = manageRules.saveAndNewRule();
       Test.stopTest();
       system.assertEquals(page.getURL(),'/apex/AW_Rule_VF');   
    }
    
    public static testmethod void testSaveRuleFailure(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Version__c=1,Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
            AW_RuleController manageRules = new AW_RuleController(stdcon);
            manageRules.newrule.Version__c=-1;
            manageRules.newrule.Name=null;
            manageRules.newrule.Description__c  =null;
            
            Pagereference page = manageRules.saveRule();
       Test.stopTest();
       system.assertEquals(page,null);   
    }
    
    public static testmethod void testSaveAndNewRuleFailure(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
            AW_RuleController manageRules = new AW_RuleController(stdcon);
            //manageRules.newRule.Available__c= true;
            manageRules.newRule.Status__c= 'Active';
            manageRules.newrule.Name=null;
          
            Pagereference page = manageRules.saveAndNewRule();
       Test.stopTest();
       system.assertEquals(page,null);   
    }
    
    public static testmethod void testGetEvalRule(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
             AW_RuleController manageRules = new AW_RuleController(stdcon);
             List<selectOption> options = manageRules.getEvalRule();
       Test.stopTest();
       system.assert(options.size() > 0);   
    }
    
    public static testmethod void testGetStatusRule(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Active',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
             AW_RuleController manageRules = new AW_RuleController(stdcon);
             manageRules.SearchStatusRule ='Draft';
             List<selectOption> options = manageRules.getStatusRule();
             
             manageRules.SearchStatusRule ='Archived';
             List<selectOption> options1 = manageRules.getStatusRule();
             
             manageRules.SearchStatusRule ='Active';
             List<selectOption> options2 = manageRules.getStatusRule();
             
       Test.stopTest();
       system.assert(options.size() > 0);      
    }
    
    public static testMethod void testConstructorIfElse(){
        //.AW_AdvanceWorkflowExecutionEngine_Test
        Rule__c rule = new Rule__c();
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
        AW_RuleController manageRules = new AW_RuleController(stdcon);

        Test.stopTest();
    }
    
     public static testMethod void testConstructorIfElse2(){
        //.AW_AdvanceWorkflowExecutionEngine_Test
        Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
        ApexPages.standardController stdcon = new ApexPages.StandardController(rule);
        Test.startTest();
        AW_RuleController manageRules = new AW_RuleController(stdcon);

        Test.stopTest();
    }
    
   

}
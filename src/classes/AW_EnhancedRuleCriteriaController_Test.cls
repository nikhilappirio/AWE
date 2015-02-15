@isTest
public with sharing class AW_EnhancedRuleCriteriaController_Test {

 public static testMethod void Rule (){ 
 
    rule__C testRule=new rule__C(name='test',
                             Object__c='Account',
                             Description__c='test',
                             Evaluation_Rule__c='Record is created');
                             
    List<string> operatorList = new List<string>{'STARTS With','ENDS With','Contains','Between','Greater Than','Not Equal To','Less or Equal','Greater or Equal','Equals','Less Than','REGEX','IS NULL',' IS NOT NULL','INCLUDES','EXCLUDES','IN','IN !','=','='};
    Test.startTest();
    PageReference pageRef = Page.AW_EnhancedCriteriaManager_VF;
    Test.setCurrentPage(pageRef);
    
    insert testRule;
     Apexpages.currentPage().getParameters().put('ruleId',testRule.id);
    ApexPages.StandardController std1 = new ApexPages.standardController(testRule);
    AW_EnhancedRuleCriteriaController testManager=new AW_EnhancedRuleCriteriaController(std1);
    list<rule__C> testRule1=[Select id,name from rule__C where id=:testRule.id];
    system.assertequals(1,testRule1.size());
    
    list<RuleCriteria__c> RuleCriteriaList = new list<RuleCriteria__c>();
    
    for(integer i =0;i<operatorList.size();i++){
    
    
    
    RuleCriteria__c RuleCriteriaTest=new RuleCriteria__c(Rule__c=testRule.id,Related_Object__c=testRule.Object__c,
                                                          Field_Name__c='CreatedById',
                                                          Matching_Type__c = operatorList.get(i),
                                                          Matching_Value__c='1');
                                                          
                                                          
                                                      
    if(RuleCriteriaTest.Matching_Type__c =='Between'){
            RuleCriteriaTest.Maximum_value__c='sample';
            RuleCriteriaTest.Minimum_value__c='sample';  
            RuleCriteriaTest.Field_Name__c='CreatedDate';
            

           
        
    }
       if(i==operatorList.size()-1){
            RuleCriteriaTest.Related_Object__c='Contact';
            RuleCriteriaTest.Field_Name__c='LeadSource';
            }
    
    RuleCriteriaList.add(RuleCriteriaTest);
    }
    insert  RuleCriteriaList;
    AW_EnhancedRuleCriteriaController.filterwrap TestFw = new AW_EnhancedRuleCriteriaController.filterwrap(false,'',RuleCriteriaList.get(0),1);
   
                                                     
    Apexpages.currentPage().getParameters().put('Id',testRule.id);
    ApexPages.StandardController std = new ApexPages.standardController(testRule);
    AW_EnhancedRuleCriteriaController testManage=new AW_EnhancedRuleCriteriaController(std);
    
    
    testManage.index=':0:';
    testManage.ParentField='Cross Formula';
    testManage.ParentOperator='=';
     system.debug( testManage.index+    testManage.ParentField+    testManage.ParentOperator);
     testManage.ParentObj='Account';
     testManage.index1=':0:';
    testManage.populateFields();
    testManage.populateOperator();  
    system.debug( testManage.index+    testManage.ParentField+    testManage.ParentOperator);
    testManage.index=':0:';
    testManage.togglebtw();
   

         TestFw.newRuleCriteria.Matching_Type__c='=';
         testManage.RuleRecord.Filter_Logic__c='1AND2';
         testManage.Save();
   
  
    testManage.index=':0:';
     testManage.RuleRecord.Filter_Logic__c='1asd2'; 
     testManage.Validate();
    testManage.validatefilterCritera(); 
    testManage.RuleRecord.Filter_Logic__c='1AND2';
    testManage.validatefilterCritera(); 
    testManage.RuleRecord.Filter_Logic__c='1 '; 
    testManage.validatefilterCritera(); 
   testManage.RuleRecord.Filter_Logic__c='(1AND2';
    testManage.validatefilterCritera(); 
    testManage.index=':0:';
   testManage.ParentOperator='=';
   testManage.parentfield='CreatedDate';
   testManage.populateOperator();
   

    testManage.addmorefilter();
    testManage.toremovecounter=2;
    testManage.deletefilter(); 
    testManage.RuleRecord.Filter_Logic__c='(1 AND 2 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 OR 9 OR 10 OR 11 OR 12 OR 13 OR 14 OR 15 OR 16 OR 18 OR 19)';
      testManage.Save();   
   
    testManage.Cancel();
    Test.stopTest();           
}

	public static testmethod void isChangedTest(){
		  Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
		  PageReference pageRef = Page.AW_EnhancedCriteriaManager_VF;
    	  Test.setCurrentPage(pageRef);
          Apexpages.currentPage().getParameters().put('ruleId',rule.id);
          ApexPages.StandardController std = new ApexPages.standardController(rule);
          AW_EnhancedRuleCriteriaController testManage = new AW_EnhancedRuleCriteriaController(std);
          Test.startTest();
          testManage.ParentObj='Account';
		  testManage.index1=':0:';
		  testManage.FilterWrapper[0].newRuleCriteria.Matching_Type__c = 'IsChanged';
		  testManage.populateFields();
		  testManage.index=':0:';
		  testManage.parentOperator = 'IsChanged';
		  testManage.populateOperator();
		  testManage.parentOperator = 'IsChanged';  
		  testManage.index=':0:';
		  testManage.togglebtw();
		  testManage.Save();
		  System.assertNotEquals(null, testManage.FilterWrapper[0].newRuleCriteria.Id);
		  Test.stopTest();  
	}
	
	public static testmethod void changedFromToTest(){
		  Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
		  PageReference pageRef = Page.AW_EnhancedCriteriaManager_VF;
    	  Test.setCurrentPage(pageRef);
          Apexpages.currentPage().getParameters().put('ruleId',rule.id);
          ApexPages.StandardController std = new ApexPages.standardController(rule);
          AW_EnhancedRuleCriteriaController testManage = new AW_EnhancedRuleCriteriaController(std);
          Test.startTest();
          testManage.ParentObj='Account';
		  testManage.index1=':0:';
		  testManage.parentField = 'Name';
		  testManage.FilterWrapper[0].newRuleCriteria.Matching_Type__c = 'ChangedFromTo';
		  testManage.populateFields();
		  testManage.index=':0:';
		  testManage.FilterWrapper[0].newRuleCriteria.Matching_Type__c = 'ChangedFromTo';
		  testManage.parentOperator = 'ChangedFromTo';
		  testManage.populateOperator();
		  testManage.FilterWrapper[0].newRuleCriteria.Matching_Value__c = '';
		  testManage.index=':0:';
		  testManage.togglebtw();
		  testManage.Save();
		  System.assertNotEquals(null, testManage.FilterWrapper[0].newRuleCriteria.Id);  
		  Test.stopTest();
	}
	
	public static testmethod void testSaveCriteria(){
		  Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
		  PageReference pageRef = Page.AW_EnhancedCriteriaManager_VF;
    	  Test.setCurrentPage(pageRef);
    
         
          Apexpages.currentPage().getParameters().put('ruleId',rule.id);
          ApexPages.StandardController std = new ApexPages.standardController(rule);
          AW_EnhancedRuleCriteriaController ct = new AW_EnhancedRuleCriteriaController(std);
          ct.save();
	}

}
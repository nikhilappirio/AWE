public with sharing class AW_RuleDetailController {
		
		String ruleId;
		public String delCriteria{get;set;}
		
		public AW_RuleDetailController(ApexPages.StandardController ctrl){
			 ruleId = ctrl.getId();
		}
		
		
		
		public List<RuleCriteria__c> getCriterias(){
			return [Select Rule__c,Id,Name,Related_Object__c,Field_Name__c,Field_API_Name__c,Matching_Type__c,Matching_Value__c,Field_Type__c FROM RuleCriteria__c WHERE Rule__c=:ruleId ORDER BY Name ASC];
		}
		
		public void deleteCriteria(){
			RuleCriteria__c cr =[Select Id FROM RuleCriteria__c WHERE Id=:delCriteria];
			delete cr;
		}
		
		/*
		public static testmethod void testRuleDetailController(){
			  
			  Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
			  Test.startTest();
			    PageReference pageRef = Page.AW_RUleDetail_VF;
			    Test.setCurrentPage(pageRef);
			    
			    Apexpages.currentPage().getParameters().put('id',rule.id);
          		ApexPages.StandardController std = new ApexPages.standardController(rule);  
			    
			    AW_RuleDetailController ctrl= new AW_RuleDetailController(std);
			    List<RuleCriteria__c> cr = ctrl.getCriterias();
			    
			    
			    ctrl.delCriteria=cr[0].Id;
			    ctrl.deleteCriteria();
			    
			  Test.stopTest();
		}
		*/
}
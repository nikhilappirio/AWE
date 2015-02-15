// 
// (c) 2012 Appirio, Inc.
// Test Class for  AW_RuleCriteriaMain_test  Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_RuleCriteriaMain_test {
  static Advance_Workflow__c aw;
  static Rule__c rl ;
  static String ruleid;	
	
static testMethod void RuleUpdate() {

setupData('Draft') ;	
List<Rule__c> testOldListrule  = new List<Rule__c>();
List<Rule__c> testNewListrule  = new List<Rule__c>();
List<RuleCriteria__c> testOldListcriteria   = new List<RuleCriteria__c>();
List<RuleCriteria__c> testNewListcriteria   = new List<RuleCriteria__c>();

testOldListcriteria = [ Select Id, Name,
							rule__c, related_object__c, CrossFormula__c,Maximum_Value__c,Minimum_Value__c,Matching_Type__c,Matching_Value__c,
							field_name__c, field_API_Name__c,  Field_Type__c 
                            From   RuleCriteria__c where rule__r.Id = :ruleid];
 testNewListcriteria = [ Select Id, Name,
							rule__c, related_object__c, CrossFormula__c,Maximum_Value__c,Minimum_Value__c,Matching_Type__c,Matching_Value__c,
							field_name__c, field_API_Name__c,  Field_Type__c 
                            From   RuleCriteria__c where rule__r.Id = :ruleid];
  
 
for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 testNewListcriteria[i].Matching_Value__c= 'Test2';
     
}
 
for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 testNewListrule[i].Status__c= 'Active';
     
}
  update  testNewListrule;
  
AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER  =true;
AW_trgr_RuleCriteriaManager.afterUpdateRuleCriteria(testNewListcriteria,testOldListcriteria);
System.assert(AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER == false );	
    
AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER  =true;
	delete testNewListcriteria;	
System.assert(AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER == false );
}
	
public static void setupData(String RuleStatus){
//String RlStatus= RuleStatus ;
aw = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
aw.Object__c  = 'Account';
aw.Description__c = 'Test Desc';
aw.Enabled__c =True;
 
insert aw;
 
rl = new Rule__c(Name = 'Test Test Account',Object__c = 'Account',  Version__c=1,Status__c=RuleStatus,Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');

insert rl;
ruleid=rl.Id;
RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rl.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
insert ruleCriteria ;
RuleAction__c ruleaction = new RuleAction__c(rule__c=rl.id,related_object__c='Account',Reference_Id__c=Userinfo.getUserId(),
                                                            field_name__c='Industry',Type__c='Update Field',Value__c='Apparel');
insert ruleaction;

if (RuleStatus=='Active') {
	rl.Advance_Workflow__c=aw.Id;
   update rl;
}
 
}		
}
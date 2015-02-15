// 
// (c) 2013 Appirio, Inc.
// AW_trgr_RuleCriterianManager_Test                                                     
// This test class tests AW_trgr_RuleActionManager  functionality   
//
// 04 Feb 2013     Peter Babalis       Original
//  
//  
//
@isTest
public class AW_trgr_RuleCriterianManager_Test {
static Advance_Workflow__c aw;
static Rule__c rl ;
static String ruleid;
/**  Create setup data */
static void setupData(){
//Advance_Workflow__c aw = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
aw = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
aw.Object__c  = 'Account';
aw.Description__c = 'Test Desc';
aw.Enabled__c =True;
insert aw;

rl = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Order__c=10,Version__c=1,Status__c='Active',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
insert rl;

RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rl.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
insert ruleCriteria ;
RuleAction__c ruleaction = new RuleAction__c(rule__c=rl.id,related_object__c='Account',Reference_Id__c=Userinfo.getUserId(),
                                                            field_name__c='Industry',Type__c='Update Field',Value__c='Apparel');
insert ruleaction;
ruleid=rl.Id;
rl.Advance_Workflow__c = aw.Id;
update rl;

aw.Enabled__c = true;
update aw;
}	

static testMethod void testInsertRuleCriteria() {

List<RuleCriteria__c> testNewListcriteria  = new List<RuleCriteria__c>();

setupData();

RuleCriteria__c rulecriteria1 = new RuleCriteria__c(rule__c=rl.id,related_object__c='Account',
                                                           Matching_Type__c='Starts With', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');

insert rulecriteria1;
    
testNewListcriteria = [ Select Id,
  							   Matching_Type__c,
  							   Matching_Value__c,
  							   field_name__c,
  							   field_API_Name__c,
  							   Field_Type__c,Rule__c,
  							   rule__r.object__c 
  					     FROM  RuleCriteria__c  where rule__c = :ruleid ];

AW_trgr_RuleCriteriaManager.afterInsertRuleCriteria(testNewListcriteria);
System.assert(AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER == false );	
}

static testMethod void testUpdateRuleCriteria() {
 
setupData();
List<RuleCriteria__c> testNewListcriteria  = new List<RuleCriteria__c>();
List<RuleCriteria__c> testOldListcriteria  = new List<RuleCriteria__c>();

testOldListcriteria = [ Select Id,
  							   Matching_Type__c,
  							   Matching_Value__c,
  							   field_name__c,
  							   field_API_Name__c,
  							   Field_Type__c,Rule__c,
  							   rule__r.object__c 
  					     FROM  RuleCriteria__c  where rule__c = :ruleid ];
 
testNewListcriteria=testOldListcriteria;
 
for (integer i=0; i<testNewListcriteria.size();i++   ){ 
  	 testNewListcriteria[i].Matching_Value__c= 'Finance';
}

update testNewListcriteria;

AW_trgr_RuleCriteriaManager.afterUpdateRuleCriteria(testNewListcriteria,testOldListcriteria);
System.assert(AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER == false );	
	
}

static testMethod void testDeleteRuleCriteria() {


List<RuleCriteria__c> testOldListcriteria  = new List<RuleCriteria__c>();

setupData();

RuleCriteria__c rulecriteria1 = new RuleCriteria__c(rule__c=rl.id,related_object__c='Account',
                                                           Matching_Type__c='Starts With', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');

insert rulecriteria1;
     
testOldListcriteria =   [ Select Id,
  							   Matching_Type__c,
  							   Matching_Value__c,
  							   field_name__c,
  							   field_API_Name__c,
  							   Field_Type__c,Rule__c,
  							   rule__r.object__c 
  					     FROM  RuleCriteria__c  where rule__c = :ruleid ];
AW_trgr_RuleCriteriaManager.afterdeleteRuleCriteria(testOldListcriteria);
System.assert(AW_trgr_RuleCriteriaManager.RULECRITERIA_FLOW_CONTROLLER == false );	
}
 	
  
 

}
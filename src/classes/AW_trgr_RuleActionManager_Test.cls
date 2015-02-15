// 
// (c) 2012 Appirio, Inc.
// AW_trgr_RuleActionManager_Test                                                     
// This test class tests AW_trgr_RuleActionManager  functionality   
//
// 04 Feb 2013     Peter Babalis       Original
//  
//  
//
@isTest
public class AW_trgr_RuleActionManager_Test {

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

static testMethod void testInsertRuleAction() {

List<RuleAction__c> testNewListaction  = new List<RuleAction__c>();

setupData();

RuleAction__c ruleaction1 = new RuleAction__c(rule__c=rl.id,related_object__c='Account', Reference_Id__c=Userinfo.getUserId(),
                                                            field_name__c='Industry',Type__c='Update Field',Value__c='Finance');
insert ruleaction1;
    
testNewListaction = [ Select Id,Field_Name__c,Type__c,Reference_Id__c,
                                   User_Owner_Id__c,Notify_User__c,
                                   Email_Template__c ,Long_Value__c,
                                   Related_Object__c,Rule__c,Value__c ,
                                   rule__r.object__c from RuleAction__c  where rule__c = :ruleid ];

AW_trgr_RuleActionManager.afterInsertRuleAction(testNewListaction);
System.assert(AW_trgr_RuleActionManager.RULEACTION_FLOW_CONTROLLER == false );	
}

static testMethod void testUpdateRuleAction() {
 
setupData();
List<RuleAction__c> testNewListaction  = new List<RuleAction__c>();
List<RuleAction__c> testOldListaction  = new List<RuleAction__c>();

 
testOldListaction = [ Select Id,Field_Name__c,Type__c,Reference_Id__c,
                                   User_Owner_Id__c,Notify_User__c,
                                   Email_Template__c ,Long_Value__c,
                                   Related_Object__c,Rule__c,Value__c ,
                                   rule__r.object__c from RuleAction__c  where rule__c = :ruleid ];
testNewListaction=testOldListaction;
 
for (integer i=0; i<testNewListaction.size();i++   ){ 
  	 testNewListaction[i].Value__c= 'Finance';
}


update testNewListaction;
AW_trgr_RuleActionManager.afterUpdateRuleAction(testNewListaction,testOldListaction);
System.assert(AW_trgr_RuleActionManager.RULEACTION_FLOW_CONTROLLER == false );	
	
}

static testMethod void testDeleteRuleAction() {


List<RuleAction__c> testOldListaction  = new List<RuleAction__c>();

setupData();

RuleAction__c ruleaction1 = new RuleAction__c(rule__c=rl.id,related_object__c='Account', Reference_Id__c=Userinfo.getUserId(),
                                                            field_name__c='Industry',Type__c='Update Field',Value__c='Finance');
insert ruleaction1;
     
testOldListaction = [ Select Id,Field_Name__c,Type__c,Reference_Id__c,
                                   User_Owner_Id__c,Notify_User__c,
                                   Email_Template__c ,Long_Value__c,
                                   Related_Object__c,Rule__c,Value__c ,
                                   rule__r.object__c from RuleAction__c  where rule__c = :ruleid ];
AW_trgr_RuleActionManager.afterDeleteRuleAction(testOldListaction);
System.assert(AW_trgr_RuleActionManager.RULEACTION_FLOW_CONTROLLER == false );	
}
 	
 
}
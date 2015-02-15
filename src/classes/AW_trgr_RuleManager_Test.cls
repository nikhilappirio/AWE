// 
// (c) 2013 Appirio, Inc.
// AW_trgr_RuleManager_Test                                                     
// This test class tests AW_trgr_RuleManager_Test  functionality   
//
// 04 Feb 2013     Peter Babalis       Original
//  
//  
//
@isTest
public class AW_trgr_RuleManager_Test {

static Advance_Workflow__c aw;
static Rule__c rl ;
static String ruleid;

/**  Create setup data */
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

static testMethod void testafterInsertRule() {
List<Rule__c> testNewListrule  = new List<Rule__c>();
setupdata('Draft');

testNewListrule = [ Select Id,Name ,Advance_Workflow__c
                   FROM Rule__c  
                   WHERE  Name = :ruleid ];
                   
 AW_trgr_RuleManager.afterInsertRule(testNewListrule);	
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	
 
}
 public static void testafterUpdateRule(){
AW_trgr_RuleManager.RULE_FLOW_CONTROLLER=true;
setupData('Draft');
List<Rule__c> testOldListrule  = new List<Rule__c>();
//Rule__c testNewListrule   = new Rule__c ();
List<Rule__c> testNewListrule  = new List<Rule__c>();

testOldListrule = [ Select Id,
							Name,
							Status__c ,
							Advance_Workflow__c,
							Total_Actions__c,
							Total_Criteria__c 
                    From    Rule__c  where Id = :ruleid ];
testNewListrule = [ Select Id,
							Name,
							Advance_Workflow__c,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c 
                    From    Rule__c  where Id = :ruleid ];
 
for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 testNewListrule[i].Status__c= 'Active';
     
}
//update updateListrule;
update testNewListrule;
 
//System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == true );	
AW_trgr_RuleManager.afterUpdateRule(testNewListrule,testOldListrule);
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	

}

 
static testMethod void testafterDeleteRule() {
//AW_trgr_RuleManager.afterDeleteRule(oldList)
List<Rule__c> testOldListrule  = new List<Rule__c>();
setupdata('Active');

testOldListrule = [ Select Id,Name,Advance_Workflow__c 
                   FROM Rule__c  
                   WHERE  Name = :ruleid ];
for (integer i=0; i<testOldListrule.size();i++   ){ 
  	 testOldListrule[i].Status__c= 'Active';
     
}
update testOldListrule;                   
AW_trgr_RuleManager.afterDeleteRule(testOldListrule);	
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	
 
}

static testMethod void testupdateRuleActive_To_Draft() {
setupData('Active');
List<Rule__c> testNewListrule  = new List<Rule__c>();
List<Rule__c> testOldListrule  = new List<Rule__c>();

testOldListrule = [ Select Id,
							Name,
							Advance_Workflow__c,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c 
                    From    Rule__c  where Id = :ruleid ];

testNewListrule = [ Select Id,
							Name,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c
                    From    Rule__c  where Id = :ruleid ];                    
for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 testNewListrule[i].Status__c= 'Draft';
}
update testNewListrule;
AW_trgr_RuleManager.afterUpdateRule(testNewListrule,testOldListrule);
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	

}
 
static testMethod void testupdateRuleActive_To_Archive() {
setupData('Active');
List<Rule__c> testNewListrule  = new List<Rule__c>();
List<Rule__c> testOldListrule  = new List<Rule__c>();

testOldListrule = [ Select Id,
							Name,
							Advance_Workflow__c,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c
                    From    Rule__c  where Id = :ruleid ];
                    
testNewListrule = [ Select Id,
							Name,
							Advance_Workflow__c,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c
                    From    Rule__c  where Id = :ruleid ];                    
for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 testNewListrule[i].Status__c= 'Archived';
}
update testNewListrule;
AW_trgr_RuleManager.afterUpdateRule(testNewListrule,testOldListrule);
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	


}

 
static testMethod void testupdateRuleDraft_To_Archive() {
setupData('Draft');
List<Rule__c> testNewListrule  = new List<Rule__c>();
List<Rule__c> testOldListrule  = new List<Rule__c>();

testOldListrule = [ Select Id,
							Advance_Workflow__c,
							Name,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c 
                    From    Rule__c  where Id = :ruleid ];
testNewListrule = [ Select Id,
							Name,
							Advance_Workflow__c,
							Status__c ,
							Total_Actions__c,
							Total_Criteria__c
                    From    Rule__c  where Id = :ruleid ];                    
//testOldListrule=testNewListrule;

for (integer i=0; i<testNewListrule.size();i++   ){ 
  	 //testNewListrule[i].Id= testOldListrule[i].Id;
   	 testNewListrule[i].Status__c= 'Archived';
}
 
 
update testNewListrule;
AW_trgr_RuleManager.afterUpdateRule(testNewListrule,testOldListrule);
System.assert(AW_trgr_RuleManager.RULE_FLOW_CONTROLLER == false );	


}

static testMethod void CountRulesassociatedtoAdvanceWorkflow() {
//AW_trgr_RuleManager.CountRulesassociatedtoAdvanceWorkflow(Ids)
}
}
// 
// (c) 2013 Appirio, Inc.
// Name 			: AW_CloneUtil_Test	                                                  
// This class clones a rule, its criteria and ations
// 12 June 2013    Peter Babalis     Original
//
//The top class needs to be global as this need to be accessible for API call

@isTest(SeeAllData=true)
private class AW_CloneUtil_Test {
    static Id accountId;
    static Integer RuleRecCount = 15;
    static List<Rule__c> rules;
    static Advance_Workflow__c plan;
    	
static testMethod void testClone() {    
        //Create account test data
        Account myAccount = new Account(name='CloneToolTestAccount');
        
        Insert myAccount;
        //Create contact test data
        Contact myContact1 = new Contact(Lastname = 'Lee', AccountId = myAccount.Id);
        Contact myContact2 = new Contact(Lastname = 'Lee', AccountId = myAccount.Id);
        
        Insert myContact1;
        Insert myContact2;
   
      //Create Attachment test data
        Blob b = Blob.valueOf('Test Data');  
        Attachment myAttachment = new Attachment(name='CloneToolTestAttachment',Parentid=myAccount.Id,Body=b);
        Insert myAttachment;
       
       //Create Note test data
         String b1 = 'Test Data' ;  
        Note myNote = new Note(Parentid=myAccount.Id,Body=b1,Title='SomeTitle');
        Insert myNote;
       
         PageReference pageRef = new PageReference('Page.AW_Clone_VF');
        Test.setCurrentPage(pageRef); 
            
       ApexPages.currentPage().getParameters().put('ID', myAccount.id);
        AW_ClonePage_Controller clonePage = new AW_ClonePage_Controller();

        List<string> selectObjs = new list<string>();
         selectObjs.add('Contact');
         clonePage.getItems();
        
        clonePage.objects = selectObjs;
        
        clonePage.chainClone();
                
         Account clonedAccount = [select Id, Name from Account where Name like 'CloneToolTestAccount%' order by CreatedDate desc limit 1];                
          system.debug('clonedAccount'+clonedAccount.Id );
         system.debug('clonedAccount'+clonedAccount.Name );
           System.assert(myAccount.Id <> clonedAccount.Id);
           
         
      //  System.assert(myAccount.Id <> clonedAccount.Id && myAccount.Name == clonedAccount.Name);
        
      //  Integer contactCount = [select count() from contact where AccountID=:clonedAccount.id];                
       // System.assertEquals(2, contactCount);       
    }
 static testMethod void testRulesClone() {    
       
         
        //Create Rule test data
        Rule__c rule = AW_TestUtil.createRule('CloneToolTestRule', 'Account', 'Draft', 'Record is created or edited', 'Rule 1 Description', true);
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Account', 'Equals', 'Apparel', 'Industry', 'Name', 'Picklist', true);     
        RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rule, 'Account', True, 'Type', 'Update Field', 'TestUpdate', true);
        RuleAction__c ruleaction2 = AW_TestUtil.createRuleAction(rule, 'Account', True, 'Type', 'Insert Record', 'TestInsert', true);
        Values_for_Action_Insert_Record__c info1 = AW_TestUtil.createInsertValues(ruleaction2.Id, 'Body', '12345', true);
        Values_for_Action_Insert_Record__c info2 = AW_TestUtil.createInsertValues(ruleaction2.Id, 'testtxt', 'Name', true);
        
        
        rule.Status__c = 'Active';
        update rule;  
       
        PageReference pageRef = new PageReference('Page.AW_Clone_VF');
        Test.setCurrentPage(pageRef); 
            
       ApexPages.currentPage().getParameters().put('ID', rule.id);
        AW_ClonePage_Controller clonePage = new AW_ClonePage_Controller();

        List<string> selectObjs = new list<string>();
        selectObjs.add('Values_for_Action_Insert_Record__c');            
       //  selectObjs.add('Rule__c');
         clonePage.getItems();
        
        clonePage.objects = selectObjs;        
        clonePage.chainClone();        
          Test.startTest();	
         Rule__c clonedRule = [select Id, Name from Rule__c where Name like 'CloneToolTestRule%' order by CreatedDate desc limit 1];                
         
           System.assert(rule.Id <> clonedRule.Id);
       Test.stopTest();
      //  System.assert(myAccount.Id <> clonedAccount.Id && myAccount.Name == clonedAccount.Name);
        
      //  Integer contactCount = [select count() from contact where AccountID=:clonedAccount.id];                
       // System.assertEquals(2, contactCount);
    }
 
    
     
    static testMethod void testSuperClone() {    
        //Create account test data
        Account myAccount = new Account(name='CloneToolTestAccount');
        
        Insert myAccount;
        //Create contact test data
        Contact myContact1 = new Contact (lastname='Lee', AccountId = myAccount.id);
        Contact myContact2 = new Contact (lastname='Lee', AccountId = myAccount.id);
        
        Insert myContact1;
        Insert myContact2;
        
        Blob b = Blob.valueOf('Test Data');  
        Attachment myAttachment = new Attachment(name='CloneToolTestAttachment',Parentid=myAccount.Id,Body=b);
        Insert myAttachment;
        
        List<String> contacts = new list<String>();
        //contacts.add('Contact');
        contacts.add('Attachment');
   		try{
        AW_CloneUtil myClone = new AW_CloneUtil(String.valueof(myAccount.Id), contacts);
        
        Account clonedAccount = [select Id, Name from Account where Name = 'CloneToolTestAccount' order by CreatedDate desc limit 1];                
        System.assert(myAccount.Id <> clonedAccount.Id && myAccount.Name == clonedAccount.Name); 
   		}catch(Exception e){
   			System.debug(e.getMessage());
   		}      
    }
 

 
}
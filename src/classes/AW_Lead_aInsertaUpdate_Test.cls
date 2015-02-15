// 
// (c) 2012 Appirio, Inc.
// Test Class for AW_Lead_aInsertaUpdate_Test Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_Lead_aInsertaUpdate_Test {

static List<Account> testListAcc;
static List<Lead> testListLead;

  
 //Test Method to check the populatin of SalesRep__c field when Account is converted to Partner
    static testMethod void testRuleEngine() {
      
       integer numOfAccs=10;
       integer numOfLeads=10;
       Set<Id> Ids=new Set<Id>();
       createTestDataForRuleEngine();
       testListlead = [ Select Id, LastName,City  from Lead limit 10 ];
     
        for (integer i=0; i<testListLead.size();i++   )
        { 
        	 Ids.add(testListLead[i].Id);
        }

     //Calling Rule Engine Service
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'Lead',true);
        
       System.assert(testListLead.size() == 10);
     
    }
    	
//Method to create Test Data
static testMethod void createTestDataForRuleEngine()
{
      integer numOfAccounts=1;     
      integer numOfLeads=10;    
       
      List<Account> accountsList = new List<Account>();
      for(integer i = 1; i <= numOfAccounts; i++){  
        Account account = new Account();
        account.Name='Test Account'+ i;
        account.Industry='Technology';
        account.TickerSymbol='SomeTickerSymbol';
        accountsList.add(account);
      }
		 
		try{ insert accountsList; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Accounts - inside createTestDataForAccountRuleEgine()'+e.getMessage()); }
	   
      
      
      List<Lead> LeadList = new List<Lead>();
      for(integer i = 1; i <= numOfLeads; i++){  
        Lead ld = new Lead();
        ld.LastName='ABC'+i;
        ld.City='Test City'+ i;
        ld.Company='ABCCO';
        
        LeadList.add(ld);
      }
		 
		try{ insert LeadList; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Leads - inside createTestDataForRuleEngine()'+e.getMessage()); }
	   
}  
}
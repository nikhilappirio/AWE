// 
// (c) 2012 Appirio, Inc.
// Test Class for  Account_aInsertaUpdate  Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_Account_aInsertaUpdate_Test {

static List<Account> testListAcc;

  
 //Test Method to check the populatin of SalesRep__c field when Account is converted to Partner
    static testMethod void testRuleEngine() {
        //Creating the non-Partner Account
       //Id Ids ;
       integer numOfAccs=10;
       Set<Id> Ids=new Set<Id>();
       createTestDataForRuleEngine();
       testListAcc = [ Select Id, TickerSymbol,Industry   from Account limit 10 ];
     
        for (integer i=0; i<testListAcc.size();i++   )
        { 
        	 Ids.add(testListAcc[i].Id);
        }

     //Calling Rule Engine Service
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'Account',true);
        
       System.assert(testListAcc.size() == 10);
     
    }
    	
//Method to create Test Data
static testMethod void createTestDataForRuleEngine()
{
      integer numOfAccounts=10;     
      
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
	   
}  
}
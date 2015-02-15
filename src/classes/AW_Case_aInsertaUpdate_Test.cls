// 
// (c) 2012 Appirio, Inc.
// Test Class for  AW_Case_aInsertaUpdate_Test  Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_Case_aInsertaUpdate_Test {

static List<Case> testListCases;

  
 //Test Method to check the populatin of SalesRep__c field when Account is converted to Partner
    static testMethod void testRuleEngine() {
        //Creating the non-Partner Account
       //Id Ids ;
       integer numOfCases=10;
       Set<Id> Ids=new Set<Id>();
       createTestDataForRuleEngine();
       testListCases = [ Select Id, Origin,Status   from Case limit 10 ];
     
        for (integer i=0; i<testListCases.size();i++   )
        { 
        	 Ids.add(testListCases[i].Id);
        }

     //Calling Rule Engine Service
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'Case',true);
        
       System.assert(testListCases.size() == 10);
     
    }
    	
//Method to create Test Data
static testMethod void createTestDataForRuleEngine()
{
      integer numOfCases=10;     
      integer numOfAccounts=1;     
      Account account = new Account();
      account.Name='Test Account' ;
      account.Industry='Technology';
      account.TickerSymbol='SomeTickerSymbol';
    //  accountsList.add(account);
      try{ insert account; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Accounts - inside createTestDataForRuleEgine()'+e.getMessage()); }
	        
     
      List<Case> casessList = new List<Case>();
      for(integer i = 1; i <= numOfCases; i++){  
        Case cs = new Case();
       // cs.Name='Test Case'+ i;
        cs.AccountId=account.Id;
        cs.Status='New';
        cs.Origin='Phone';
        casessList.add(cs);
      }
		 
		try{ insert casessList; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Cases - inside createTestDataForCasetRuleEgine()'+e.getMessage()); }
	   
}  
}
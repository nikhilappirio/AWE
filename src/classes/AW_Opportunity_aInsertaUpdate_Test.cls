// 
// (c) 2012 Appirio, Inc.
// Test Class for AW_Opportunity_aInsertaUpdate_Test Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_Opportunity_aInsertaUpdate_Test {

static List<Account> testListAcc;
static List<Opportunity> testListOpp;

  
 //Test Method to check the populatin of SalesRep__c field when Account is converted to Partner
    static testMethod void testRuleEngine() {
        //Creating the non-Partner Account
       //Id Ids ;
       integer numOfAccs=10;
       integer numOfOpptys=10;
       Set<Id> Ids=new Set<Id>();
       createTestDataForRuleEngine();
        testListOpp = [ Select Id, StageName,Name,CloseDate   from Opportunity limit 10 ];
     
        for (integer i=0; i<testListOpp.size();i++   )
        { 
        	 Ids.add(testListOpp[i].Id);
        }

     //Calling Rule Engine Service
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'Opportunity',true);
        
       System.assert(testListOpp.size() == 10);
     
    }
    	
//Method to create Test Data
static testMethod void createTestDataForRuleEngine()
{
      integer numOfAccounts=1;     
      integer numOfOpptys=10;    
       
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
	   
      
      
      List<Opportunity> OpportunityList = new List<Opportunity>();
      for(integer i = 1; i <= numOfOpptys; i++){  
        Opportunity opty = new Opportunity();
        opty.AccountId = accountsList[0].Id;
        opty.Name='Test Opportunity'+ i;
        opty.StageName='Open';
        opty.CloseDate = Date.today();
     
           OpportunityList.add(opty);
      }
		 
		try{ insert OpportunityList; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Opportunities - inside createTestDataForOpportunityRuleEgine()'+e.getMessage()); }
	   
}  
}
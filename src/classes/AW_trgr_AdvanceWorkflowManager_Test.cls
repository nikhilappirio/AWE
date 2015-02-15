// 
// (c) 2013 Appirio, Inc.
// AW_trgr_AdvanceWorkflowManager_Test                                                     
// This test class tests AW_trgr_RuleManager_Test  functionality   
//
// 04 Feb 2013     Peter Babalis       Original
//  
//  
//
 
	@isTest
	public class AW_trgr_AdvanceWorkflowManager_Test {
	static Advance_Workflow__c aw;
	static Advance_Workflow__c aw1;
	static String AW_id,AW1_id;
	 
	/**  Create setup data */
	static void setupData(){
	//String RlStatus= RuleStatus ;
	aw = new Advance_Workflow__c(Name = 'Test Account  Advance Workflow');
	aw.Object__c  = 'Account';
	aw.Description__c = 'Test Account Desc';
	aw.Enabled__c =True;
	insert aw;
	  
	AW_id=aw.Id; 
	
	aw1 = new Advance_Workflow__c(Name = 'Test Opportunity Advance Workflow');
	aw1.Object__c  = 'Opportunity';
	aw1.Description__c = 'Test Opportunity Desc';
	aw1.Enabled__c =True;
	insert aw1;
	  
	AW1_id=aw1.Id; 
	}	
	
	
	static testMethod void testbeforeInsertAdvanceWorkflow(){
	setupData();
	
	List<Advance_Workflow__c> testNewListaw = new List<Advance_Workflow__c>();
	Advance_Workflow__c adv_wf =new Advance_Workflow__c();
	  
	testNewListaw = [ Select Id,Name ,Object__c,Description__c
	                   FROM Advance_Workflow__c  
	                   WHERE  Name = :AW_id ];
	
	adv_wf.Name='Test Another Advance Workflow';
	adv_wf.Object__c='Account';
	adv_wf.Description__c = 'Test Desc';
	adv_wf.Enabled__c =True;
	
	insert adv_wf;
	
	testNewListaw = [ Select Id,Name,Object__c,Description__c 
	                   FROM Advance_Workflow__c  
	                    ];
	//                  WHERE  Name = :AW_id ];
	
	AW_trgr_AdvanceWorkflowManager.beforeInsertAdvanceWorkflow(testNewListaw);	
	System.assert(AW_trgr_AdvanceWorkflowManager.ADVANCEWORKFLOW_FLOW_CONTROLLER == false );	
	 
	}
	
		
	static testMethod void testbeforeUpdateAdvanceWorkflow() {
	setupData();
	List<Advance_Workflow__c> testNewListaw = new List<Advance_Workflow__c>();
	List<Advance_Workflow__c> testoldLitsaw = new List<Advance_Workflow__c>();
	
	
	testoldLitsaw = [ Select Id,Name ,Object__c,Description__c
	                   FROM Advance_Workflow__c  
	                   WHERE  Object__c = 'Account' ];
	
	testNewListaw = [ Select Id,Name ,Object__c,Description__c
	                   FROM Advance_Workflow__c  
	                   WHERE  Object__c = 'Account' ];
	
	for (integer i=0; i<testNewListaw.size();i++   ){ 
	  	 testNewListaw[i].Object__c= 'Opportunity';
	     
	}
	update testNewListaw;
	
	AW_trgr_AdvanceWorkflowManager.beforeUpdateAdvanceWorkflow(testNewListaw,testoldLitsaw);	
	System.assert(AW_trgr_AdvanceWorkflowManager.ADVANCEWORKFLOW_FLOW_CONTROLLER == false );	
	
	
	}
	
	static testMethod void testAccountAWETriggerHandler(){
		
		List<Account> accountList = new List<Account>();
		Map<Id,Account> oldMap = new Map<Id,Account> ();
		for(integer i=0;i<5;i++){
    		Account account = new Account(Name='Test Contact'+i,AnnualRevenue=2000.0,Industry='Agriculture');
    		accountList.add(account);
    	}
		
		Test.startTest();
		insert accountList;
		
		AccountAWEtriggerHandler.afterInsert(accountList);
		for(Account a :accountList){
			oldMap.put(a.id,a);
		}		
		for(Account a :accountList){
			integer i = 1;
			a.Name = 'Updated Name'+i;
			i++;			
		}
		update accountList;
		AccountAWEtriggerHandler.afterUpdate(accountList, oldMap);
		Test.stopTest();
		
	}	
	 
	}
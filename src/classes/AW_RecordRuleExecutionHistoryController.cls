// 
// (c) 2014 Appirio, Inc.
//
//  AW_RecordRuleExecutionHistoryController                                                     
//
// This controller fetches data from
//		  execution history for a specific record id 
//		  based on last execution transactiontamp found on that object		   
//		  
// 18 Jul 2014     Peter Babalis     Original
//
public with sharing class AW_RecordRuleExecutionHistoryController {
		
		
		
		//variable to store the record id
		String recordId;
		
		public string recordName {get;set;}
		SObject recordInContext {get;set;}
		
		
		public AW_RecordRuleExecutionHistoryController(){
			recordId = ApexPages.currentPage().getParameters().get('recordId');
			fetchRecordDetails();
		}
		
		
		void fetchRecordDetails(){
			String objName=String.valueof(Id.valueof(recordId).getSObjectType());
			system.debug('-->objName '+objName);
		 
			String query='';
			if ( objName =='Case' )  query='Select Id,casenumber,AWE_Rule__c FROM '+objName+' WHERE Id=\''+recordId+'\'';
			else if  ( objName =='Task' ) query='Select Id,Name,AWE_Rule__c FROM '+objName+' WHERE Id=\''+recordId+'\'';
			else query='Select Id,Name,AWE_Rule__c FROM '+objName+' WHERE Id=\''+recordId+'\'';
			 
			objName=objName.tolowerCase();
			
			List<SObject> record =Database.query(query);
			if(record.size()>0){
				recordInContext= record[0];
				system.debug('-->recordInContext '+recordInContext);
				// recordName = (String)recordInContext.get('Name');
				  recordName =  objName=='task' ? string.valueof(recordInContext.get('subject')): (objName=='case' ? string.valueof(recordInContext.get('casenumber')) : string.valueof(recordInContext.get('name')));
    	       
    	       system.debug('-->recordName '+recordName);
    	       
			}
			
		}
		
		//method to get the history
		public List<Rule_Execution_History__c> getHistory(){
			List<Rule_Execution_History__c> history = new List<Rule_Execution_History__c>();
			if(recordInContext!=null){
				String last_time_stamp_value = (String)recordInContext.get('AWE_Rule__c');
				if(last_time_stamp_value!=null){
					String transactiontamp = last_time_stamp_value.split('~')[2];
					system.debug('transactiontamp ' +transactiontamp ) ;
					history=[Select Id,Rule__c,Advance_Workflow__c,Criteria__c,	Actions__c,Evaluation__c,Execution__c,Record_ID__c,Record_Name__c,RuleName__c,Rule_Execution_Status__c,	Rule_object__c,	Rule_Version__c,Transaction_Stamp__c FROM Rule_Execution_History__c WHERE Transaction_Stamp__c=:transactiontamp];				
				}
			}
			return history;
		}
		
					
}
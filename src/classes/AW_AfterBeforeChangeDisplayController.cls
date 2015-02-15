// 
// (c) 2014 Appirio, Inc.
//
//  AW_AfterBeforeChangeDisplayController                                                     
//
//			This controllerController used for the inline visualforce page that will
//			provide a better UI for showing the display change sets
//		  
// 18 Jul 2014     Peter Babalis     Original
//
public with sharing class AW_AfterBeforeChangeDisplayController {
		 
		/*
			Controller used for the inline visualforce page that will
			provide a better UI for showing the display change sets
		*/
		
	    String historyId;
		 
		public AW_AfterBeforeChangeDisplayController(Apexpages.StandardController ctrl){
			historyId = ctrl.getId();
		}
		
		public List<Changes> getRecordChanges(){
			
			Rule_Execution_History__c record=[Select Record_After_Action_Applied__c,Record_Before_Action_Applied__c FROM Rule_Execution_History__c WHERE Id=:historyId];
			
			List<Changes> changedValues= new List<Changes>();
			Map<String,String> oldFieldValues = new Map<String,String>();
			Map<String,String> newFieldValues = new Map<String,String>();
			if(record.Record_After_Action_Applied__c!=null){
				newFieldValues=parseRecord(record.Record_After_Action_Applied__c);
			} 
			if(record.Record_Before_Action_Applied__c!=null){						
      			oldFieldValues =parseRecord(record.Record_Before_Action_Applied__c);      			 
			}
				
			for(String field:newFieldValues.keySet()){
				Changes cg= new Changes();
				cg.field=field;
				cg.beforeValue=oldFieldValues.get(field);
				cg.afterValue=newFieldValues.get(field);
				if(cg.beforeValue!=cg.afterValue)
					changedValues.add(cg);
			}
				
			
			return changedValues;
			
		}
		
		private Map<String,String> parseRecord(String dataStr){
			 Map<String,String> result = new Map<String,String>();
			 JSONParser parser = JSON.createParser(dataStr);
			 while (parser.nextToken() != null) {
	            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
	                (parser.getText() != 'attributes') && parser.getText() != 'attributes' && parser.getText() != 'type' && parser.getText()!='url') {
	                	String key = parser.getText();
	                	// Get the value.
	               	    parser.nextToken();
	               	    String value= parser.getText();
	                    result.put(key,value);
	            }
	        }
	        return result;
		}
		
		/*
		  wrapper class that saves the changes
		*/
		public class Changes{
			public string field {get;set;}
			public string beforeValue{get;set;}
			public string afterValue{get;set;}
		}
		
}
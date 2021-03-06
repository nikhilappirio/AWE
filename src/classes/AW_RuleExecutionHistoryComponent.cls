// 
// (c) 2014 Appirio, Inc.
//
//  AW_RuleExecutionHistoryComponent                                                     
//
// This class is used to render information in the Historty Page
//
// 18 Jul 2014     Peter Babalis     Original
   
//
public with sharing class AW_RuleExecutionHistoryComponent {
	
	
	public ApexPages.StandardSetController ssc {get; set;}
	public List<String> fieldNames {get; set;}
	public Map<String,String> fieldAlignMap {get; set;}
	public Map<String,String> nameLabelMap {get; set;}
	transient Schema.DescribeSObjectResult objectDescribe;
	public Id deleteRecordId {get; set;}
	public String sortByField {get; set;}
	public Map<String,String> fieldSortDirectionMap {get; set;}
	
	//----Variables set from attributes defined in the component----	
	public String filter {get; set;}
	public String orderByFieldName {get; set;}
	public String sortDirection {get; set;}
	public Integer pageSize {get; set;} 
	
	public List<Rule_Execution_History__c> getRecords(){
		if(ssc == null){
			//Do validation to ensure required attributes are set and attributes have correct values
			//fieldList or fieldsCSV must be defined
			Boolean validationPass = true;
							
			//Ensure sortDirection attribute has value of 'asc' or 'desc'
			if(sortDirection != null && sortDirection != 'asc' && sortDirection != 'desc'){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'sortDirection attribute must have value of "asc" or "desc"'));
				validationPass = false;
			}
			
			//Proceed with returning the related list if validation passed
			if(validationPass == false){
				return null;
			}else{
				//Build the query string dynamically
				String queryString = 'SELECT Advance_Workflow__c,Evaluation__c,Execution__c,RuleName__c';
				queryString += ' ,Rule_Execution_Status__c,Rule_Version__c,Transaction_Stamp__c,Record_Name__c,Record_ID__c,Rule_object__c';
				
			
				//add from object and parent criteria
				queryString += ' FROM Rule_Execution_History__c WHERE Id!=\'\'' ;
				
				
				//Add any addtional filter criteria to query string if it was defined in component
				if(filter != null){
					queryString += 'AND ' + filter;				
				}
				
				//Add order by field to query if defined in component
				//If sortByField != null then user has clicked a header and sort by this field
				if(sortByField != null){
					queryString += 'order by ' + sortByField;
				}else if(orderByFieldName != null){
					queryString += 'order by ' + orderByFieldName;
				}
				
				//If sortByField != null then user has clicked a header, sort based on values stored in map
				if(sortByField != null){
					/*Use a map to store the sort direction for each field, on first click of header sort asc
					and then alternate between desc*/
					if(fieldSortDirectionMap == null){
						fieldSortDirectionMap = new Map<String,String>();					
					}
					
					String direction = '';
					
					//check to see if field has direction defined, if not or it is asc, order by asc 
					if(fieldSortDirectionMap.get(sortByField) == null || fieldSortDirectionMap.get(sortByField) == 'desc' ){
						direction = 'asc';
						fieldSortDirectionMap.put(sortByField,'asc');
					}else{
						direction = 'desc';
						fieldSortDirectionMap.put(sortByField,'desc');
					}
					
					queryString += ' ' + direction;	
				}else if(sortDirection != null){
					//Add sort direction to query if defined in component
					queryString += ' ' + sortDirection;				
				}
				
				//Add limit clause to end of the query
				queryString += ' limit ' + (Limits.getLimitQueryRows() - Limits.getQueryRows());		
				
				//Query records and setup standard set controller for pagination
				ssc = new ApexPages.StandardSetController(Database.query(queryString));
				
				//Check to see if more than 10,000 records where return, if so display warning as standard set controller can only process 10,000 recores
				if(ssc.getCompleteResult() == false){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'There were more related records than could be processed. This is a partially complete list.'));
				}
				
				//Set pagination size based on value set in component
				if(pageSize != null){
					ssc.setPageSize(pageSize);
				}		
					
				/*For the fields that will be displayed identify the field type and set styleClass for
				cell alignment. Numbers, Currency, %, etc should align right in table. put in map FieldName -> class name*/
				//Get the meta data info for the fields is the related object
				Map<String, Schema.SObjectField> fieldMap = getObjectDescribe().fields.getMap(); 
				
				//For the fields in the related list populate fieldAlignMap map with the name of the correct style class. Also populate name->label map for header display
				fieldAlignMap = new Map<String,String>();
				nameLabelMap = new Map<String,STring>();
				for(String fld : fieldNames){
					String fieldType = fieldMap.get(fld).getDescribe().getType().name();	

					if(fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT' || fieldType == 'INTEGER'){
						fieldAlignMap.put(fld,'alignRight');
					}else{
						fieldAlignMap.put(fld,'alignLeft');
					}	
					
					//Add to name->label map
					String label = fieldMap.get(fld).getDescribe().getLabel();
					nameLabelMap.put(fld,label);
				}
			}
		}
		return ssc.getRecords();
	}
	
	
	
	public DescribeSObjectResult getObjectDescribe(){
		/*Returns object describe for related list object. This is used in many places so we are using a dedicated method that only invokes 
		Schema describe calls once as these count against Apex limits. Because this method returns a DescribeSObjectResult all the get 
		methods for this object can be used directly in Visualforce: {!objectDescribe.label}*/
		if(objectDescribe == null){
			objectDescribe = Schema.getGlobalDescribe().get('Rule_Execution_History__c').getDescribe();	
		}
		return objectDescribe;
	}
	
	public void sortByField(){
		//Making ssc variable null will cause getRecords method to requery records based on new sort by field clicked by user
		ssc = null;
	}
	
	
}
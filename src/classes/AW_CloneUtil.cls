// 
// (c) 2013 Appirio, Inc.
// Name 			: AW_CloneUtil	                                                  
// This class clones a rule, its criteria and ations
// 12 June 2013     Peter Babalis     Original
//
//The top class needs to be global as this need to be accessible for API call
global with sharing class AW_CloneUtil { 
   
   //New Parent Record ID for API call
   global string newParentRecordID {get;private set;}
    
    public class MyException extends Exception {}
    
    public Map<String,String> chidlObjAPIName_FieldAPIName = new Map<String,String>{};

	//CC
	boolean doCloneRelatedRec = false;
   //standard constructor
   global AW_CloneUtil(){
   		
   }

   //quick clone constructor
   global AW_CloneUtil(String parentRecordID,List<String> childObjAPINames){
   		newParentRecordID=startsClone(parentRecordID,childObjAPINames);
   }
   
   //excute clone and returns new parent record id
   public string startsClone(String parentRecordID,List<String> childObjAPINames){        
        string fieldsNames=''; 
		system.debug('-----32:' + childObjAPINames);
        //Loop through all child object names
        for(string objAPIName: childObjAPINames) {
            //Check if current child object has records linked with the parent record            
            //Handle Note and Attachement in different way as they use "ParentID" in the query
            if(objAPIName == 'Note' || objAPIName == 'Attachment') {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ParentId =\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
                SObject result = Database.query(queryString); 

                //Find note and attachment records, add note & attachment into the list
                if((Integer)result.get('total') > 0)
                    fieldsNames = fieldsNames + objAPIName + ',';
            }else if(objApiName == 'Values_for_Action_Insert_Record__c'){
            	doCloneRelatedRec = true;
            	continue;
            	
            }
            else {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ' + String.escapeSingleQuotes(chidlObjAPIName_FieldAPIName.get(objAPIName)) + '=\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
                SObject result = Database.query(queryString);                   

                //Find child object records linked with the parent record, add the child object API name into the list
                if((Integer)result.get('total') > 0)
                    fieldsNames = fieldsNames + objAPIName + ',';
            }
        }
        
        //Create Child Object API Name and creatable fields map
        Map<String, list<String>> objFields = New Map<String, list<String>>{};
        if(fieldsNames.length()>0) {
            //getCreatableFields(objAPIName) returns all creatable fields name for a given child obj API name        
            for(String objAPIName:fieldsNames.split(','))
                objFields.put(objAPIName,getCreatableFields(objAPIName));
            
        }

        //Clone parent record
        String newParentRecordID = cloneParentRecord(returnAPIObjectName(parentRecordID),getCreatableFields(returnAPIObjectName(parentRecordID)),parentRecordID);
        system.debug('-->newParentRecordID '+newParentRecordID);
        system.debug('-->ParentRecordID '+ParentRecordID);
        
        //Clone all selected child records
        for(String childObjAPIName:objFields.keySet())
            cloneChildRecords(childObjAPIName, objFields.get(childObjAPIName), returnAPIObjectName(parentRecordID), newParentRecordID,parentRecordID);
        
        return newParentRecordID;    
    }

    //Get all child object (which have records linked with the parent record) API name
  /*
    private void getFieldAPINames (String[] objects,String parentObjAPIName,String parentRecordID){
        string fieldsNames = '';
        for(string s: objects) {            
            String objAPIName=getAllChildObjNames(parentObjAPIName,parentRecordID).get(s);            
            if(objAPIName == 'Note' || objAPIName == 'Attachment') {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ParentId =\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
                SObject result = Database.query(queryString); 
                if((Integer)result.get('total')>0)
                    fieldsNames = fieldsNames + objAPIName + ',';
            }
            else {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ' + String.escapeSingleQuotes(chidlObjAPIName_FieldAPIName.get(objAPIName)) + '=\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
                SObject result = Database.query(queryString);
                if((Integer)result.get('total')>0)
                    fieldsNames = fieldsNames + objAPIName + ',';                   
            }
        }
    }
*/
     
    //Clone all child records
    public void cloneChildRecords(String objAPIName, list<String> createableFields, String parentObjAPIName, string newParentRecordID, string parentRecordID){
        String fields = '';
        for(string s:createableFields)
            fields = fields + s + ',';

        fields=fields.substring(0, fields.lastIndexOf(','));

        String queryString = 'select ' + String.escapeSingleQuotes(fields) + ' from ' + String.escapeSingleQuotes(objAPIName) + ' where ' + String.escapeSingleQuotes(chidlObjAPIName_FieldAPIName.get(objAPIName)) + '=\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
        list<SObject> result = Database.query(queryString);         
        list<SObject> copy = result.deepclone(false);       
        for(SObject obj :copy)
            obj.put(chidlObjAPIName_FieldAPIName.get(objAPIName), newParentRecordID);
        insert copy;
     //   system.debug('-------------->117:' + objAPIName);
         if(objAPIName == 'RuleAction__c' && doCloneRelatedRec){
        	List<String> lstRelatedObjCreatableFields = getCreatableFields('Values_for_Action_Insert_Record__c');
        	fields = '';
        	for(string s:lstRelatedObjCreatableFields)
            	fields = fields + s + ',';
            
            fields=fields.substring(0, fields.lastIndexOf(','));
            String strIds = '';
            for(SObject sobj: result){
	            if(strIds == ''){            	
	                strIds = '\''+ string.escapeSingleQuotes(sobj.id) +'\'';
	            }else
	            {
	            	strIds = strIds + ',' +'\''+ string.escapeSingleQuotes(sobj.id) +'\'';
	            }            
	        }  
        	strIds = '(' + strIds + ')'; 
            
        	String query = 'Select id,(Select ' + String.escapeSingleQuotes(fields) + ' From Values_for_Action_Insert_Record__r) from RuleAction__c where ID In ' + strIds;
        	list<SObject> lstRuleAction = Database.query(query);
        	if(lstRuleAction != null && lstRuleAction.size() > 0){
        		list<SObject> lstAllRelObj = new list<Sobject>();
        		integer copyCount = 0;
        		for(SObject sobj: lstRuleAction){
        			List<SObject> lstObjts = sobj.getSObjects('Values_for_Action_Insert_Record__r');
        			//system.debug('-------------->142:' + lstObjts);
        			if(lstObjts != null && lstObjts.size() > 0){
        				List<Sobject> lstCloneObj = lstObjts.deepclone(false);
        				for(SObject cloneObj: lstCloneObj){
        					cloneObj.put('Rule_Action__c',copy[copyCount].id);
        				}
        				lstAllRelObj.addAll(lstCloneObj);        				
        			}
        			copyCount++;
        		}
        	//	system.debug('-------------->148:' + lstAllRelObj);
        		if(lstAllRelObj.size() > 0){
        			insert lstAllRelObj;
        		}
        	}
        	
        }
    }

    //Clone parent record and return new parent record ID
    public String cloneParentRecord(String objAPIName, List<String> createableFields,string parentRecordID) {
        String fields = '';
         String NewParentNameVal='';
         for(string s:createableFields) {
        	  
            if ((s.contains('__pc') == false))
                fields = fields + s + ','; 
             }
        fields = fields.substring(0, fields.lastIndexOf(','));

        String queryString = 'select ' + String.escapeSingleQuotes(fields) + ' from ' + String.escapeSingleQuotes(objAPIName) + ' where id=\'' + String.escapeSingleQuotes(parentRecordID) + '\'';
        SObject result = Database.query(queryString);
       
       Schema.SObjectType t = Schema.getGlobalDescribe().get(objAPIName);
       Schema.DescribeSObjectResult r = t.getDescribe();
       Schema.DescribeFieldResult f = r.fields.getMap().get('Name').getDescribe();
      // system.debug('--->>f.getType()'+f.getType());
       if (f.getType()== Schema.DisplayType.String){
        NewParentNameVal=String.valueOf(result.get('Name'))+ '-'+  String.valueOf(datetime.now());
        result.put('Name', NewParentNameVal );
       }
       if (objAPIName=='Rule__c' ) result.put('Version__c', 1);
       Sobject copy = result.clone(false, true);
       
        insert copy;
        return copy.id ;
    }
     //Return the object API name for a given record
    public String returnAPIObjectName (string myRecordID){
        String objectName = '';
        
        String prefix = myRecordID.substring(0,3);
    
        Map<String, Schema.SObjectType> gd = Schema.getglobalDescribe();

        for(SObjectType s :gd.values()) {
            DescribeSObjectResult r = s.getDescribe();     
            if(r.getKeyPrefix()!=null) {
                if(r.getLocalName()!=null && r.getKeyPrefix().equals(prefix)) {
                    objectName=r.getLocalName();
                    break;
                } 
             }
        }        
        return objectName;
    }
    
    
    //Get all creatable fields for a given object
    public list<String> getCreatableFields(String objAPIName){
        Map<string,string> childFieldsName = new Map<string,string>{};
        
        Map<String, Schema.SObjectType> gd = Schema.getglobalDescribe();
        SObjectType sot = gd.get(objAPIName);
      
        //Get all non-creatable fields name except
        //Get the field tokens map
        Map<String, SObjectField> fields = new Map<String, SObjectField>{};
        if(sot.getDescribe().fields.getMap().keyset().size()>0)
            fields = sot.getDescribe().fields.getMap();
        
        //And drop those tokens in a List
        List<SObjectField> fieldtokens = fields.values();
        
        List<string> objectFields = new List<String>();
        
        for(SObjectField fieldtoken:fieldtokens) {
            DescribeFieldResult dfr = fieldtoken.getDescribe();
            
            if(dfr.isCreateable())
                objectFields.add(dfr.getLocalName());                       
        }
        
        return objectFields;
    }
    
    // The following Standard SObjects should be excluded
   // when searching for Child Relationships
     public static final Set<String> ExcludedObjects = new Set<String>{
      'Rule_Execution_History__c',
      'ProcessInstance',
      'ProcessInstanceHistory',
      'ContentVersion',
      'ContentDocument',
      'ActivityHistory',
      'OpenActivity',
      'Event',
      'Task',
      'User',
      'FeedComment',
      'FeedItem', 
      'FeedPost',
      'EntitySubscription',
      'NoteAndAttachment',
      'UserRole',
      'Partner',
      'CampaignMemberStatus'
    };
    
    //Get all child object API names for a given parent object API name
    //return Map<object label,object local name>,
    public Map<string,string> getAllChildObjNames(String parentObj,String parentRecordID) {        
        Map<string,string> childFieldsName = new Map<string,string>{};        
        Map<String, Schema.SObjectType> gd = Schema.getglobalDescribe();
        SObjectType sot = gd.get(ParentObj);
       
       //Get all child fields
        Schema.DescribeSObjectResult fieldResult2 = sot.getDescribe();
        List<Schema.ChildRelationship> children = fieldResult2.getChildRelationships();
        for(Schema.ChildRelationship child:children) {
           // Get the Local Name of the Child SObject
            String localName = child.getChildSObject().getDescribe().getLocalName();
             //Exclude following objects
             system.debug('-->localName '+localName);
              if(!ExcludedObjects.contains(localName)
               //Do not take parent record which is the same object
                  && localName <> returnAPIObjectName(parentRecordID)
               //exclude obj created for sharing purpose
                  && localName <> returnAPIObjectName(parentRecordID) + 'share'
                  && !localName.endsWith('__Share')
              //has to be creatable
                  && child.getChildSObject().getDescribe().isCreateable() == true)
                 {
                    chidlObjAPIName_FieldAPIName.put(localName, string.valueof(child.getField()));
                    childFieldsName.put(child.getChildSObject().getDescribe().getLabel(), localName);
              
                 }
        }

        return childFieldsName;
    }
}
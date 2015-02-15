// 
// (c) 2013 Appirio, Inc.
// Name 			: AW_ClonePage_Controller	                                                  
// This controller initiates the  clone function 
// 12 June 2013     Peter Babalis     Original
// 03 Oct  2013     Peter Babalis     Added copy of insert realted info object
//
//The top class needs to be global as this need to be accessible for API call
 
global with sharing class AW_ClonePage_Controller {
    
    private AW_CloneUtil cc=new AW_CloneUtil();
    
    //New Parent Record ID for API call
    private string newParentRecordID; 

    public Integer numberOfItems {get;private set;}
    
    public Boolean hasChildRecords {get;private set;}

    private Map<String,String> chidlObjAPIName_FieldAPIName {get;private set;}

    private string fieldsNames{get;private set;}
    
    //Parent record id
    private string recordId;
    
    //Parent object API name
    private string objName;
    
    //selected child objects
    public String[] objects {
        get {
            if (objects == null)
                objects = new String[]{};
            return objects;
        }
        set;    
    }
   
    //Constructor
    public AW_ClonePage_Controller(){ 
        chidlObjAPIName_FieldAPIName = new Map<String,String>{};
        this.recordId = apexpages.currentPage().getParameters().get('id');
        objname=cc.returnAPIObjectName(this.recordId);
        getItems();  
         
    }
      
    //Clone parent and selected child objects, redirect to the new parent record page after cloning
    public pagereference chainClone() {
        fieldsNames = '';
        list<String> selectedChildObjAPINames=New list<String>();
        //system.debug('------------>52:' + objects);
        for(string s: objects) {    
        	if(s.equalsIgnoreCase('Values_for_Action_Insert_Record__c')){
        		selectedChildObjAPINames.add('Values_for_Action_Insert_Record__c');
        		continue;
        	}        
            String objAPIName=cc.getAllChildObjNames(objname, this.recordid).get(s);            
            if(objAPIName == 'Note' || objAPIName == 'Attachment') {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ParentId =\'' + String.escapeSingleQuotes(this.recordID) + '\'';
                SObject result = Database.query(queryString); 
                if((Integer)result.get('total')>0)
                    fieldsNames = fieldsNames + objAPIName + ',';
            }
            else {
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ' + String.escapeSingleQuotes(cc.chidlObjAPIName_FieldAPIName.get(objAPIName)) + '=\'' + String.escapeSingleQuotes(this.recordID) + '\'';
                SObject result = Database.query(queryString);
                if((Integer)result.get('total')>0)
                    fieldsNames = fieldsNames + objAPIName + ',';                   
            }
        }
        
        
        if(fieldsNames.length()>0) {
            for(String childObjAPIName:fieldsNames.split(',')) 
                selectedChildObjAPINames.add(childObjAPIName);
        }
        
        PageReference pr = new PageReference('/'+cc.startsClone(this.recordid,selectedChildObjAPINames));             
        return pr;
    }

    
    //Populate child object checkbox/picklist on the vf page
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
    
        Map<string,string> childFieldsName = cc.getAllChildObjNames(objname,this.recordId);
        
        Map<String, Schema.SObjectType> gd = Schema.getglobalDescribe();
        SObjectType sot = gd.get(cc.returnAPIObjectName(this.recordID));

        Map<String,Schema.SObjectField> fieldsNameValue = sot.getDescribe().fields.getMap();
        
        for(String objLabel :childFieldsName.keyset()) {
            String objAPIName = childFieldsName.get(objLabel);              
            List<Note> notes=new list<Note>();
            List<Attachment> attachments=new list<Attachment>();
    
            //Check note and attachment obj
            if(objAPIName == 'Note') {
                notes = [select id from Note where parentid = :this.recordid];
                if(notes.size() > 0)
                    options.add(new SelectOption('Note','Note'));
            } else if(objAPIName == 'Attachment') {
                attachments = [select id from Attachment where parentid = :this.recordid];
                if(attachments.size() > 0)
                    options.add(new SelectOption('Attachment', 'Attachment'));
            }
            else {
                system.debug('objAPIName:'+objAPIName);
                system.debug('chidlObjAPIName_FieldAPIName.get(objAPIName):'+ chidlObjAPIName_FieldAPIName.get(objAPIName));
             
                String queryString = 'select count(id) total from ' + String.escapeSingleQuotes(objAPIName) + ' where ' + String.escapeSingleQuotes(cc.chidlObjAPIName_FieldAPIName.get(objAPIName)) + '=\'' + String.escapeSingleQuotes(this.recordID) + '\'';
                system.debug('-->queryString:'+queryString);
                
                SObject result = Database.query(queryString);
                if((Integer)result.get('total') > 0)
                    options.add(new SelectOption(objLabel,objLabel));

				//Cloudchallenger
				/**
				 * We know that RuleAction is going to have info as child so directly quering the rule action to check if have
				 * related entity record
				 */
				if(objApiName.equalsIgnoreCase('RuleAction__c')){
        			String query = 'Select id,(Select Id From Values_for_Action_Insert_Record__r) from RuleAction__c where Rule__c' + '=\'' + String.escapeSingleQuotes(this.recordID) + '\'';  
        			List<RuleAction__c> lstRuleAct = Database.query(query);
        			if(lstRuleAct != null && lstRuleAct.size() > 0){
        				for(RuleAction__c ruleAct : lstRuleAct){
	        				if(ruleAct.getSObjects('Values_for_Action_Insert_Record__r') != null){
	        					options.add(new SelectOption('Values_for_Action_Insert_Record__c','Related Object Info'));
	        					break;
	        				}
        				}
        			}
				}  
            }
        }
        
        //Visualforce page use these to manage its elements on the UI
        if(options.size() > 0) {
            hasChildRecords = true;
            numberOfItems = options.size();
        }

        return options;
    }
    
    public PageReference cancel(){
    	return new PageReference('/' + this.recordId);	
    }
}
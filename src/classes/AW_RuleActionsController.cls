// 
// (c) 2012 Appirio, Inc. 
//
//  AW_RuleActionsController                                                      
// 
// This class is used for creating and editing Rule Actions
//
// 10 Oct 2012     Peter Babalis     Original
// 06 Feb 2013     Peter Babalis     Cross Object Field and Email Templates (Challenge 2020)
// 24 Sep 2013     Peter Babalis     Upsert Action (Challenge 2790)
// 29 Dec 2013     Peter Babalis     Inser/Upsert Unrelated Objects (Challenge 3251)
// 30 Dec 2013     Peter Babalis     Send HTML Notifications
// 31 Dec 2013     Peter Babalis     Account Team Share & Memebers
// 07 Jan 2014     Peter Babalis     Account Owner Prortization ( Round-Robin)
//
//

public with sharing class AW_RuleActionsController {  
 
    public RuleAction__c newRuleAction{get;set;}
    public String sendEmailUserName{get;set;}
    public Rule__c rule ;
    public String objType   {get;set;}
    public String fieldType {get;set;}
    Set<String> objectToExclude = new Set<String>{'Advance_Workflow__c','Values_for_Action_Insert_Record__c','Rule__c','RuleAction__c','RuleCriteria__c','Rule_Archive__c','Rule_Execution_History__c'};
   
    
    public List<SelectOption> objOptions    {get;set;}
    public List<SelectOption> allObjectOptions    {get;set;}
    public List<SelectOption> unrelatedObjectOptions    {get;set;}
   
    public List<SelectOption> apexJobsOptions{get;set;}
    Set<String> setRelatedObjName;
    
    public List<SelectOption> fieldOption   {get;set;} 
    public List<SelectOption> lkObjectFieldOptions{get;set;} 
  
    //25/12 adding new variable to hold id-name for email options
    Map<Id,String> user_queue_names = new Map<Id,String>();
    public List<List<SelectOption>> emailoptions  {get;set;}
    public List<List<SelectOption>> emailTemplateOptions  {get;set;}
    
    String ruleActionId;
    public boolean edit {get;set;}
    public String helpTextMF{get;set;}
    
    Map<String, Schema.SObjectField> mapField;
    Map<String, Schema.SObjectField> maplookupField;
    String ruleObjType;
    Map<String,String> requiredFields{get;set;}
    Map<String,String> parentFieldNameInChild{get;set;}
    public Boolean isCrossFormula{ get; set;}
    public Boolean isOwnerPriority{ get; set;}
    public Boolean isObjectField{ get; set;}
    public String sendEmailToString{ get; set;}
    Map<Id,EmailTemplate> emailTemplates{get;set;}
    
    /**
     * Cloud challenger
     */
    public String selectedField {get;set;}
    public String calculateFormulaForReference{get;set;}//added 4jan
    public String value {get;set;}
    public List<Values_for_Action_Insert_Record__c> lstInsRelRec {get;set;}
    public String selectedRecordId {get;set;}
    private Set<String> setFieldNames = new Set<String>();
    
    Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    
    public Sobject sobjInstance{get;set;}
  
    public static final String VALUE_ERROR ='Both Value field & user/queue field cannot be specified together ';
    public static String MERGE_ERROR ='Invalid syntax for merge field provided';
    public static String LOOKUPFIELD_ERROR ='One or more input fields for LookupObjectField are Invalid';
    public static String INSERTRELATEDOBJECT_ERROR ='One or more input fields for Insert Related Object Action are Invalid';
    public static String SENDEMAIL_ERROR ='Invalid Syntax for Distribution List field provided';
   
    
    public string selectedRefName{get;set;}
    public string nameField {get;set;}
    // Cloud Challenger Start
    /**
     * This list stores the list of all valid data type that can be supported and shown using input field
     */
    public static Set<String> setAvailableDataTypes = new Set<String>{'CHECKBOX','CURRENCY','DATE','DATETIME','EMAIL','INTEGER','PERCENT','PHONE','PICKLIST','MULTIPICKLIST','TEXT','TEXTAREA','DOUBLE','ENCRYPTEDSTRING','URL','STRING','BOOLEAN','REFERENCE','COMBOBOX'};
    /**
     * This field will decide if the input field should be rendered on the UI or not
     */
    public Boolean renderValueField {get;set;}
    private Set<String> setRelObjApiName = new Set<String>();
    public Boolean renderValueFieldForFormula {get;set;}
    
    /**
     * This set will have all set of audit field which will not be displayed on the UI
     */
    private Set<String> setAuditFields = new Set<String> {'CREATEDBYID','CREATEDDATE','LASTMODIFIEDBYID','LASTMODIFIEDDATE','SYSTEMMODSTAMP'};
    // Cloud Challenger Upsert Changes Start - created external id option list 
    public List<SelectOption> externalFieldsList{get;set;}
   /* store priortity records */
    public Map<String,OwnerPrioritization__c> ownerPriorityList {get;set;}
    //one record
    public OwnerPrioritization__c ownerPriority {get;set;}

    public AW_RuleActionsController(Apexpages.StandardController stdcon){
        emailoptions = new List<List<SelectOption>>();
        renderValueFieldForFormula = true;
        parentFieldNameInChild = new Map<String,String>();
        requiredFields = new Map<String,String>();
        system.debug( '-->ownerPriorityList 1');
        ownerPriorityList= new Map<String,OwnerPrioritization__c>();
        system.debug( '-->ownerPriorityList 2');
        ownerPriority = new OwnerPrioritization__c();
        system.debug( '-->ownerPriorityList 3');
        helptextMF='{!ObjectRelationShipName.Field} Eg:- {!Cases__r.Subject},{!Account.Phone},{!Owner.Id}';
 
        lstInsRelRec = new List<Values_for_Action_Insert_Record__c>();
        
        ruleActionId = stdcon.getId();
        newRuleAction = (RuleAction__c)stdcon.getRecord();
        newRuleAction.Type__c='Update Field';
     //   newRuleAction.external_field_api_name__c='Id';
        Schema.DescribeSObjectResult objinfo = null;
        objOptions = new List<SelectOption>();
        edit=false;
        isCrossFormula=false;  
        isObjectField=false;
        if(ruleActionId!=null){
         /** 
          * Edit existing Record
          */ 
           
          
            edit=true;
            newRuleAction = [SELECT Name,
                                   Field_Name__c,Type__c,Reference_Id__c,
                                   User_Owner_Id__c,
                                   Notify_User__c,
                                   Email_Template__c,
                                   Long_Value__c,
                                   Related_Object__c,
                                   Rule__c,Value__c ,
                                   CrossObjectField__c,
                                   Field_API_Name__c,
                                   rule__r.object__c,
                                   lookup_object__c,
                                   lookup_field_name__c,
                                   lookup_field_api_name__c,
                                   Lookup_Where_Fields__c,
                                   Apex_Job_Class__c,
                                   Bulk_API__c,
                                   Input_Parameters__c,
                                   Output_Parameters__c,
                                   CallOut_Action__c,
                                   Callout_Method__c,
                                   Callout_Timeout__c,
                                   Endpoint_URL__c,
                                   notified_user__c,
                                   Email_template_folder__c,
                                   additional_emails__c,
                                   Field_Type__c,
                                   Action_Label__c,
                                   External_Field_API_Name__c,
                                   Prioritization_Method__c,
                                   ExternalId__c
                             FROM  RuleAction__c
                             WHERE id=:ruleActionId];
                             
           
            objType = newRuleAction.Related_Object__c;
            ruleObjType=newRuleAction.rule__r.object__c;
            if(newRuleAction.Type__c=='Send Email'){
                Apexpages.currentPage().getParameters().put('folderId',newRuleAction.Email_template_folder__c);
                getTemplates(); 
            } 
            
          
            if(newRuleAction.Type__c == 'Insert Related Object' || newRuleAction.Type__c == 'Upsert Related Object' ||
                newRuleAction.Type__c == 'Insert Unrelated Object' || newRuleAction.Type__c == 'Upsert Unrelated Object'){
                populatedRelatedRecInfo(newRuleAction.Id);
            }
             system.debug('--->OwnerPrioritization '+newRuleAction.Field_API_Name__c );
             if(newRuleAction.Field_API_Name__c == 'OwnerPrioritization'){
                //load the records:-
                populatedOwnerPriorityInfo(newRuleAction.Id);
            }
            // Megha - added Chatter Notification also 
            if((newRuleAction.Type__c=='Send Email' || newRuleAction.Type__c == 'Chatter Notification' ) && newRuleAction.User_Owner_Id__c!=null){
                Id sendTo = Id.valueof(newRuleAction.User_Owner_Id__c);                       
                if(sendTo.getSObjectType() == User.SobjectType ) sendEmailToString='User';
                else if(sendTo.getSObjectType() == Group.SobjectType) sendEmailToString='Queue';
                else if(sendTo.getSObjectType() == CollaborationGroup.SobjectType) sendEmailToString='Chatter Groups'; 
                ApexPages.currentPage().getParameters().put('sendemailto',sendEmailToString);
                buildEmailOptionsValues();
           } 
           
           if(newRuleAction.Field_API_Name__c=='CrossObject')isCrossFormula=true; 
           if(newRuleAction.Field_API_Name__c=='LookupObjectField')isObjectField=true; 
           system.debug('isCrossFormula--->'+isCrossFormula);
           if(isObjectField) populatelookupobjfields(newRuleAction.lookup_object__c);   
                    
         }
        else{
         /**
          * New Record
          */
          system.debug('-->NEW RECORD');
             String action = ApexPages.currentPage().getParameters().get('action');
             edit=false;
             if(action!=null && action!='')newRuleAction.Type__c=action;
                
             rule = [SELECT  object__c 
                     FROM    Rule__c 
                     WHERE id=:newRuleAction.rule__c];
             if(rule!=null){
                newRuleAction.related_object__c = rule.object__c;
                objType = rule.object__c;
                ruleObjType = objType;
                
            }
         } 
            
         if(objType!= null){     
             system.debug('-->objType!= null 1 ');              
            /**
             * Get list of child objects of object on which rule is defined
             **/
            Map<String, Schema.SObjectType> mapObj = Schema.getGlobalDescribe();
            Schema.SObjectType sobj = mapObj.get(ruleObjType);//removed objType and used ruleObjType
            objinfo =sobj.GetDescribe();
            allObjectOptions = new List<SelectOption>();
            unrelatedObjectOptions = new List<SelectOption>();
           
           /* allObjectOptions.add(new SelectOption('',''));
           
            for(String o:mapObj.keySet()){
                Schema.DescribeSObjectResult descRes = mapObj.get(o).getDescribe();
                if(!descRes.isCustomSetting() && descRes.isAccessible() && (descRes.isCreateable() || descRes.isUpdateable())){
                    allObjectOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                }
            }
            allObjectOptions.sort();
            */
             system.debug('-->objType!= null 2 ');  
            objOptions.add(new SelectOption(objInfo.getName(), objInfo.getLabel() + ' (' + objInfo.getName() + ')'));
            unrelatedObjectOptions.add(new SelectOption(objInfo.getName(), objInfo.getLabel() + ' (' + objInfo.getName() + ')'));
         //cloud challenger start
            setRelObjApiName.add(objInfo.getName());
            List<Schema.ChildRelationship> listChild = sobj.getDescribe().getChildRelationships();
            for(Schema.ChildRelationship child: listChild){
                Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                if(descRes.isCreateable() && !setRelObjApiName.contains(descRes.getName())){
                    objOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                    setRelObjApiName.add(descRes.getName());
                }
                //cloud challenger end
                //parentFieldNameInChild.put(descRes.getName().toLowercase(),child.getRelationshipName());
                parentFieldNameInChild.put(descRes.getName().toLowercase(),child.getField().getDescribe().getName().toLowercase());
            } system.debug('-->objType!= null 3 ');  
             allObjectOptions.add(new SelectOption('',''));
            for(String o:mapObj.keySet()){
                Schema.DescribeSObjectResult descRes = mapObj.get(o).getDescribe();
                if(!descRes.isCustomSetting() && descRes.isAccessible() && (descRes.isCreateable() || descRes.isUpdateable())){
                    allObjectOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                     if(!setRelObjApiName.contains(descRes.getName()) && !objectToExclude.contains(descRes.getName())){
                           unrelatedObjectOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                    }
                }
                
            }
             system.debug('-->objType!= null 4 ');  
            
            allObjectOptions.sort();
             system.debug('-->objType!= null 5 '+ allObjectOptions);  
            populateFields(objType);
        }
        sortSelectListOnLabel(unrelatedObjectOptions);
        sortSelectListOnLabel(objOptions);
        
      // system.debug('-->displayAssignmentPanel.CONSTRUCTOR');
        displayAssignmentPanel();
        actionChanged();
        if(edit){
            system.debug('-->edit');
            if(newRuleAction.Field_Type__c!= null &&   newRuleAction.Field_Type__c.equalsIgnoreCase('textarea')){
            //  if(newRuleAction.Field_Type__c.equalsIgnoreCase('textarea')){
                sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.Long_Value__c);
            }
            else{
                system.debug('-->NEW newRuleAction.Field_Type__c'  +newRuleAction.Field_Type__c);
                try{
                     if(newRuleAction.Field_Type__c!= null && newRuleAction.Field_Type__c.equalsIgnoreCase('reference')){
                //     if(newRuleAction.Field_Type__c.equalsIgnoreCase('reference')){
                        //here making small change with refernce :-
                        if(newRuleAction.Reference_Id__c != null && newRuleAction.Reference_Id__c.startsWith('{!')) calculateFormulaForReference = newRuleAction.Reference_Id__c;
                        else
                          sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.Reference_Id__c);
                    //}else if(newRuleAction.Field_Type__c.equalsIgnoreCase('BOOLEAN')){  
                    }else if(newRuleAction.Field_Type__c!= null && newRuleAction.Field_Type__c.equalsIgnoreCase('BOOLEAN')){
                        sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.value__c!=null?Boolean.valueOf(newRuleAction.value__c):false);
                   // }else if(newRuleAction.Field_Type__c.equalsIgnoreCase('INTEGER')){
                    }else if(newRuleAction.Field_Type__c!= null && newRuleAction.Field_Type__c.equalsIgnoreCase('INTEGER')){
                        sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.value__c!=null?Integer.valueOf(newRuleAction.value__c):null);
               //     }else if(newRuleAction.Field_Type__c.equalsIgnoreCase('CURRENCY')){
                     }else if(newRuleAction.Field_Type__c!= null && newRuleAction.Field_Type__c.equalsIgnoreCase('CURRENCY')){
                       sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.value__c!=null?Decimal.valueOf(newRuleAction.value__c):null);
                    }else if(newRuleAction.Field_Type__c!= null && newRuleAction.Field_Type__c.equalsIgnoreCase('DATE')){
                         //if(newRuleAction.value__c.startsWithIgnoreCase('today(') || newRuleAction.value__c.startsWithIgnoreCase('now('))
                         //calculateFormulaForReference = newRuleAction.value__c;
                         //else 
                         sobjInstance.put(newRuleAction.Field_API_Name__c,Date.valueof(newRuleAction.value__c));
                    }else{
                         if(newRuleAction.Field_API_Name__c!='CrossObject' && newRuleAction.Field_API_Name__c!='LookupObjectField')
                         {
                             system.debug('->>>newRuleAction.Field_API_Name__c'+  newRuleAction.Field_API_Name__c );
                             sobjInstance.put(newRuleAction.Field_API_Name__c,newRuleAction.value__c);
                           }
                    }
                }//end try
                catch(Exception e){
                    calculateFormulaForReference = newRuleAction.value__c;
                }
            }            
        }
     }
  
    public PageReference  getFieldNames(){
         system.debug('->getfieldNames');
         objType= Apexpages.currentPage().getParameters().get('parentName');
         system.debug('->getfieldNames objType' +objType);
         lstInsRelRec = new List<Values_for_Action_Insert_Record__c>();
         requiredFields = new Map<String,String>();
         fieldType = null;
         newRuleAction.Field_API_Name__c = '';
         populateFields(objType);
         //if(newRuleAction.Type__c == 'Insert Related Object'){
            
         //}    
         return null; 
    }
    
    public void getLookupFields(){
        populatelookupobjfields(newRuleAction.Lookup_Object__c); 
        //newRuleAction.Lookup_Object__c = ApexPages.currentPage().getParameters().get('selectedLookupObject');
    }
    
    
    public void populatelookupobjfields(String lkobjType){
             
         Schema.SObjectType sobjTypeParent = gd.get(lkobjType.tolowercase());  
         
         Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
         maplookupField = parentObjFields.fields.getMap();
         lkObjectFieldOptions = new List<SelectOption>();
         for(String fieldname:maplookupField.keySet()){
            Schema.SObjectField sfield = maplookupField.get(fieldname);
            Schema.DescribeFieldResult descResField = sfield.getDescribe();
            String fieldLabel = descResField.getLabel();
            
            if(descResField.isCalculated() || !descResField.isCreateable()){ 
                continue;
            }
            
           lkObjectFieldOptions.add(new SelectOption(descResField.getName(),fieldLabel));
            
         }
         
    }
    
    
         /**
     * Getting all the related record configuration from rule action
     */
    public void populatedOwnerPriorityInfo(Id ruleActionId){
       
        if(ownerPriorityList.size() == 0){
            
            for(OwnerPrioritization__c rec: [select Priority__c,User_Queue_Group__c,Name,RuleAction__c,User_Queue_Group_Id__c,Assigned__c,Weight__c,Percent__c from OwnerPrioritization__c where RuleAction__c =: ruleActionId]){
                ownerPriorityList.put(rec.Id,rec);
            }
        }
    }
    
     //set the action id for the owner records & then upsert them
    private void upsertOwnerPrioritizationRec(Id ruleActionId){
        List<OwnerPrioritization__c> rec = ownerPriorityList.values();
        for(OwnerPrioritization__c info: rec){            
            if(info.RuleAction__c == null){
                info.RuleAction__c = ruleActionId;
            }
        }       
        upsert rec;
    }
    
   
    /** 
     * This method is used to populate the fields of given Object
     */
    public void populateFields(String objType){
         system.debug('-->POPULATE FIELDS');
         renderValueField = true;
         populatedRelatedRecInfo(ruleActionId);
         fieldOption= new List<SelectOption>();
         // Cloud Challenger Upsert Changes Start - Initialize Instance
         externalFieldsList = new List<SelectOption>();
         // Cloud Challenger Upsert Changes End

         string parent = objType;
         
         Schema.SObjectType sobjTypeParent = gd.get(parent.tolowercase());
         //system.debug('-->>sobjInstance  before ' +sobjInstance);  
         sobjInstance = sobjTypeParent.newSObject();
        // system.debug('-->>sobjInstance  after ' +sobjInstance); 
         
         Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
         mapField = parentObjFields.fields.getMap();
       system.debug('-->parentFieldNameInChild->'+parentFieldNameInChild);
         for(String fieldname:mapField.keySet()){
            Schema.SObjectField sfield = mapField.get(fieldname);
            Schema.DescribeFieldResult descResField = sfield.getDescribe();
            String fieldLabel = descResField.getLabel();
            
            system.debug('-->>fieldname ' +fieldname);
            
           system.debug('-->>parentFieldNameInChild.get(objType.tolowerCase()) ' +parentFieldNameInChild.get(objType.tolowerCase()));
            
            
          /* system.debug('-->>parentFieldNameInChild' +parentFieldNameInChild);
            system.debug('-->>objType.tolowerCase()' +objType.tolowerCase());
            system.debug('-->>fieldname ' +fieldname);
            system.debug('-->>parentFieldNameInChild.get(objType.tolowerCase())' +parentFieldNameInChild.get(objType.tolowerCase()));
            system.debug('-->>parentFieldNameInChild.get(objType.tolowerCase()).equalsIgnoreCase(fieldname)' +parentFieldNameInChild.get(objType.tolowerCase()).equalsIgnoreCase(fieldname));
           */
            if(parentFieldNameInChild != null && objType != null && parentFieldNameInChild.get(objType.tolowerCase())!=null && parentFieldNameInChild.get(objType.tolowerCase()).equalsIgnoreCase(fieldname))
                  continue;
            
            if(descResField.isNameField()){
                nameField = descResField.getName();
            }
            if(descResField.isCalculated() || !descResField.isCreateable()){ 
                continue;
            }
            //Cloud challenger start
             
            if(!setAvailableDataTypes.contains(String.valueOf(descResField.getType()))){
                system.debug('Reason----'+String.valueOf(descResField.getType()));
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'This object is not supported for insert now.');
                ApexPages.addMessage(msg);
                renderValueField = false;
                fieldOption = new List<SelectOption>();
                fieldOption.add(new SelectOption('Not Supported','----Not Supported----'));
                break;
            }
            // cloud challenger end
            
            if(!setFieldNames.contains(descResField.getName()) && 
                    !setAuditFields.contains(descResField.getName().toUpperCase())){
                if(fieldType == null){
                    fieldType = descResField.getName();
                }               
                fieldOption.add(new SelectOption(descResField.getName(),fieldLabel));
            }
            if(descResField.isCreateable() && !descResField.isNillable() && !descResField.isDefaultedOnCreate()){
                requiredFields.put(descResField.getName().tolowerCase(),descResField.getLabel());
            }
             // Cloud Challenger Upsert Changes Start - Add External Id in select List
            if(descResField.isExternalID()){
                externalFieldsList.add(new SelectOption(descResField.getName(),fieldLabel));
            }
            // Cloud Challenger Upsert Changes End
        }
        system.debug('--fieldOption-'+fieldOption);
        if(newRuleAction.Type__c == 'Update Field' || newRuleAction.Type__c == '' ||  newRuleAction.Type__c == null){
            fieldOption.add(new SelectOption('CrossObject','Cross Object Field'));
            fieldOption.add(new SelectOption('LookupObjectField','Lookup Object Field'));
            fieldOption.add(new SelectOption('OwnerPrioritization','Owner Prioritization'));
       }
        sortSelectListOnLabel(fieldOption);
        
        //if(newRuleAction.Type__c == 'Update Field')
        //added 17june : fix a issue since both Field_Name__c && Field_API_Name__C refer to api name so should not create a issue;
         system.debug('-->>>HERE newRuleAction.Field_Name__c '+ newRuleAction.Field_Name__c);
         system.debug('-->>>HERE newRuleAction.field_API_Name__c '+ newRuleAction.field_API_Name__c);
         
        String fieldName = newRuleAction.Field_Name__c!=null ? newRuleAction.Field_Name__c:newRuleAction.field_API_Name__c;
        system.debug('-->>>HERE fieldName '+ fieldName);
        if(fieldName != null && fieldName != ''){
            //newRuleAction.field_name__c = fieldType;
            fieldType = fieldName;
            newRuleAction.Field_API_Name__C = fieldType;
        } 
       
        //system.debug('-->>>HERE displayAssignmentPanel.populateFields ');
        displayAssignmentPanel();
        
    }
public void buildEmailOptionsValues(){
      
        system.debug('-->>>buildEmailOptionsValues 1 ');
        emailoptions= new List<List<SelectOption>>();
        
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--Select--'));
        System.debug('::sendEmailToString'+sendEmailToString);
        if(sendEmailToString == null || sendEmailToString == ''){ 
        	sendEmailToString = Apexpages.currentPage().getParameters().get('sendemailto');
        }
        System.debug('::sendEmailToString after'+sendEmailToString);
        if(sendEmailToString == 'User'){
  //          for(User u :[Select Id,Name FROM User WHERE IsActive=true]){
  			if(newRuleAction.User_Owner_Id__c != null && newRuleAction.User_Owner_Id__c != '' && newRuleAction.User_Owner_Id__c.startsWith('005')){
  				for(User u : [select id , Name from User where id = : newRuleAction.User_Owner_Id__c]){
  					sendEmailUserName = u.Name;
  				}
  			}
              /*for(User u :[Select Id,Name FROM User where profileId in (Select id from Profile where not  (Name LIKE 'Chatter%')) and IsActive = true]){
  	            //emailoptions.add(new SelectOption(u.Id,u.Name));
                 options.add(new SelectOption(u.Id,u.Name));
                 user_queue_names.put(u.Id,u.Name);
                 if(options.size() == 1000){
                    emailoptions.add(options);
                    options = new List<SelectOption>();
                }
            }*/
        
        }else if(sendEmailToString == 'Chatter Groups'){
        	Advance_Workflow_Limits__c awLimits = Advance_Workflow_Limits__c.getInstance('NumCollaborationGrpPerQuery');
            Integer rowLimit = 2000;
            if(awLimits != null && awLimits.Value__c != null){
            	rowLimit = Integer.valueOf(awLimits.Value__c);
            }
            for(CollaborationGroup  u :[Select Id,Name FROM CollaborationGroup Limit :rowLimit]){
                //emailoptions.add(new SelectOption(u.Id,u.Name));
                options.add(new SelectOption(u.Id,u.Name));
                user_queue_names.put(u.Id,u.Name);
                if(options.size() == 1000){
                    emailoptions.add(options);
                    options = new List<SelectOption>();
                }
            }
        
        }else if(sendEmailToString == 'UserRole'){
        	for(UserRole usrRole : [select id , Name from UserRole]){
        		options.add(new SelectOption(usrRole.Id,usrRole.Name));
        		user_queue_names.put(usrRole.Id,usrRole.Name);
                if(options.size() == 1000){
                    emailoptions.add(options);
                    options = new List<SelectOption>();
                }
        	}
        }
        else{
            String query =' Select Id,Name FROM Group';
            if(sendEmailToString == 'Queue')query += ' WHERE Type=\'Queue\'';
            else query += ' WHERE Type=\'Regular\'';
            
            List<Group> grp=Database.query(query);
            for(Group g:grp){
                options.add(new SelectOption(g.Id,g.Name));
                user_queue_names.put(g.Id,g.Name);
                if(options.size() == 1000){
                    emailoptions.add(options);
                    options = new List<SelectOption>();
                }
                //emailoptions.add(new SelectOption(g.Id,g.Name));
            }
        }
        if(options.size() > 0){
            emailoptions.add(options);
        }
}       

/*
      method added by SH
      handles whether the object can be assigned to user,queue
    */
    public void displayAssignmentPanel(){
         
           system.debug('---->fieldType:' + fieldType);
           isCrossFormula=false;
           isObjectField=false;
           isOwnerPriority=false;
           calculateFormulaForReference='';
           if(fieldType=='CrossObject'){
               isCrossFormula=true;
               newRuleAction.Field_Type__c = 'string';
               newRuleAction.Field_API_Name__c = 'CrossObject';
           }else 
           if(fieldType=='LookupObjectField'){
               isObjectField=true;
               newRuleAction.Field_Type__c = 'string';
               newRuleAction.Field_API_Name__c = 'LookupObjectField';
           }else 
           if(fieldType=='OwnerPrioritization'){               
               newRuleAction.Field_Type__c = 'string';
               newRuleAction.Field_API_Name__c = 'OwnerPrioritization';
               isOwnerPriority=true;
           }else
           if(fieldType != null && mapField.containsKey(fieldType.toLowerCAse())){
               Schema.SObjectField field =  mapField.get(fieldType.toLowerCAse());    
               Schema.DescribeFieldResult F = field.getDescribe();
               
               String fieldDataType = String.valueOf(field.getDescribe().getType());
               newRuleAction.Field_Type__c = fieldDataType;
               newRuleAction.Field_API_Name__c = field.getDescribe().getName();
        }else if(fieldType == null || fieldType == ''){
            renderValueField = false;
            newRuleAction.Field_API_Name__c = '';
        }
        system.debug('---->displayAssignmentPanel END:' + newRuleAction.Field_API_Name__c );
    } 
    
    public List<SelectOption> getapexClasses(){
            Advance_Workflow_Limits__c awLimits = Advance_Workflow_Limits__c.getInstance('NumApexClassPerQuery');
	        Integer rowLimit = 2000;
	        if(awLimits != null && awLimits.Value__c != null){
	        	rowLimit = Integer.valueOf(awLimits.Value__c);
        	}
            List<ApexClass> classes =[Select Id,Name FROM ApexClass WHERE Status='Active' Limit :rowLimit];
            list<SelectOption> opts = new list<SelectOption>();
            opts.add(new SelectOption('','--Select--'));
             for(ApexClass cls : classes){
                try{
                   // RuleActionInterface f = (RuleActionInterface)((Type.forName(cls.Name)).newInstance());
                    if (!edit ) AW_RuleActionInterface  f = (AW_RuleActionInterface )((Type.forName(cls.Name)).newInstance());
                   // system.debug('--Class Name--'+cls.Name);
                    opts.add(new SelectOption(cls.name,cls.name));
                }
                catch(Exception ex){
                    system.debug(ex.getMEssage()+'--message--'+cls.Name);
                }
            }
           
            return opts;
    }
    
     public List<SelectOption> getvfPages(){
        List<ApexPage> pages =[Select Id,Name FROM ApexPage ];
        list<SelectOption> opts = new list<SelectOption>();
            opts.add(new SelectOption('','--Select--'));
        for(ApexPage cls : pages){
            opts.add(new SelectOption(cls.name,cls.name));
        }
        return opts;
     }
    
    private string selectedRecordName(string selectedId){
        if(mapField.containsKey(fieldType.toLowerCAse())){
           Schema.SObjectField field =  mapField.get(fieldType.toLowerCAse());    
           system.debug('--selectedRecordName.field '+ mapField.get(fieldType.toLowerCAse()));
          
           Schema.DescribeFieldResult F = field.getDescribe();
           system.debug('--selectedRecordName.Schema.DescribeFieldResul'+ field.getDescribe());
           List <Schema.sObjectType> sobjTypeList = f.getReferenceTo();
           system.debug('--selectedRecordName.sobjTypeList )'+f.getReferenceTo() );
          
           if(sobjTypeList != null && sobjTypeList.size() > 0){
            List<Sobject> sobjList = new List<Sobject>();
            Id referenceId = Id.valueof(selectedId);
            system.debug('--selectedRecordName.referenceId '+Id.valueof(selectedId)  );
            
            String objectToQuery =sobjTypeList[0].getDescribe().getName();
            system.debug('--selectedRecordName.sobjList '+sobjTypeList[0].getDescribe().getName()  );
          //   if(referenceId.getSObjectType() != User.SobjectType)
         //       objectToQuery ='User';
           
            if(referenceId.getSObjectType() == User.SobjectType)
                 objectToQuery ='User';
            sobjList = Database.query('select Name from '+objectToQuery +' where id = \''+selectedId+'\'');//+namefield+
          //  system.debug('--selectedRecordName.sobjList'+sobjList  );
           // system.debug('--selectedRecordName.sobjList'+sobjList[0].get('Name')  );
            
            if(sobjList != null && sobjList.size()>0){
                return (String)sobjList[0].get('Name');//namefield
            }
            
           }
           

        }   
        return '';
    }
    
    public PageReference saveRuleAction(){
              if(!doSave())
                return null;
            return(new PageReference('/'+newRuleAction.Rule__c));
          
    }
    public PageReference saveAndNewRuleAction(){
            if(!doSave())
                return null;
                
            newRuleAction = new RuleAction__c(rule__c=newRuleAction.rule__c,type__c='Update Field'  );
            objType = ruleObjType;
            
            return(new PageReference('/apex/AW_RuleActions_VF'));
                   
    }
    
    private Boolean doLimitValidations(){
        AggregateResult[] groupedResults =[Select Type__c,Count(ID) FROM RuleAction__c  WHERE Rule__c =: newRuleAction.Rule__c GROUP BY Type__c];
        
        Map<String,Advance_Workflow_Limits__c> lims = Advance_Workflow_Limits__c.getAll();
        
        for (AggregateResult ar : groupedResults)  {
             
            if(String.valueOf(ar.get('Type__c'))=='Execute Apex Job' && lims.get('NumApexJobsperRule')!=null && lims.get('NumApexJobsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.FATAL,'Apex Job Limit of '+lims.get('NumApexJobsperRule').Value__c+' Exceeded'));
                    return false;
            }
            
            if(ar.get('Type__c')=='Send Email' && lims.get('NumEmailActionsperRule')!=null && lims.get('NumEmailActionsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Email : Limit of '+lims.get('NumEmailActionsperRule').Value__c+' Exceeded'));
                    return false;
            }
            
            if(ar.get('Type__c')=='Update Field' && lims.get('NumUpdateActionsperRule')!=null && lims.get('NumUpdateActionsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Update Field : Limit of '+lims.get('NumUpdateActionsperRule').Value__c+' Exceeded'));
                    return false;
            }
            
            if(ar.get('Type__c')=='Insert Related Object' && lims.get('NumInsertActionsperRule')!=null && lims.get('NumInsertActionsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insert Related Object : Limit of '+lims.get('NumInsertActionsperRule').Value__c+' Exceeded'));
                    return false;
            }   
            if(ar.get('Type__c')=='Apex Callout-HTTP' && lims.get('NumApexCalloutperRule')!=null && lims.get('NumApexCalloutperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Apex Callout-HTTP: Limit of '+lims.get('NumApexCalloutperRule').Value__c+' Exceeded'));
                    return false;
            }   
            
                        
        }
        
        AggregateResult[] groupedResults2 =[Select Field_API_Name__c,Count(ID) FROM RuleAction__c  WHERE Rule__c =: newRuleAction.Rule__c GROUP BY Field_API_Name__c];
        for (AggregateResult ar : groupedResults2)  {
                if(ar.get('Field_API_Name__c')=='CrossObject' && lims.get('NumUpdateCrossReferencefieldsperRule')!=null && lims.get('NumUpdateCrossReferencefieldsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Cross Object Field Limit of '+lims.get('NumUpdateCrossReferencefieldsperRule').Value__c+' Exceeded'));
                    return false;
                }
                
                if(ar.get('Field_API_Name__c')=='LookupObjectField' && lims.get('NumUpdateLookupReferencefieldsperRule')!=null && lims.get('NumUpdateLookupReferencefieldsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Cross Object Field Limit of '+lims.get('NumUpdateLookupReferencefieldsperRule').Value__c+' Exceeded'));
                    return false;
                }
        }
        return true;
    }
    
    private Boolean doSave(){
            // Added fieldType null check to resolve null pointer exception
            
            if(fieldType != null && fieldType.trim()=='LookupObjectField' && !validateLookupObjectQuery()){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.LOOKUPFIELD_ERROR)); 
                   return false;
            }
             
            newRuleAction.Related_Object__c = objtype;
            newRuleAction.Field_Name__c =  fieldType;
            system.debug('--->doSave Related_Object__c ' +objtype);
            system.debug('--->doSave fieldType ' +fieldType);
            //updated the logic..instead calling validate merge field we directly call isValidValue to allow bo
             
            if(fieldType != null && fieldType.trim()=='CrossObject'){
                    String crossobject = newRuleAction.CrossObjectField__c.startsWith('{!')? newRuleAction.CrossObjectField__c.substringBetween('{!','}'):newRuleAction.CrossObjectField__c;
                    if(!validateMergeField(crossobject)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.MERGE_ERROR));
                        return false;
                    }
            }
            
            if(newRuleAction.Type__c == 'Update Field' && fieldType != null &&  fieldType.trim()!='CrossObject' &&  fieldType.trim()!='OwnerPrioritization' && fieldType.trim()!='LookupObjectField'){
                  if(newRuleAction.Field_Type__c.equalsIgnoreCase('textarea') ){
                    newRuleAction.Value__c = '';
                    newRuleAction.Long_Value__c  = calculateFormulaForReference== null || calculateFormulaForReference=='' ? String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c)):calculateFormulaForReference;
                  
                }else{
                    newRuleAction.Long_Value__c = '';
                    if(newRUleAction.Field_Type__c.equalsIgnoreCase('reference')){
                        
                        //newRuleAction.Reference_Id__c = calculateFormulaForReference==''?String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c)):calculateFormulaForReference;
                        //newRuleAction.Value__c =  calculateFormulaForReference==''?selectedRecordName(newRuleAction.Reference_Id__c):calculateFormulaForReference;    
                         if (calculateFormulaForReference== null || calculateFormulaForReference=='') {
                               newRuleAction.Reference_Id__c  =String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c));
                               newRuleAction.Value__c =selectedRecordName(newRuleAction.Reference_Id__c);
                          }
                         else {
                          newRuleAction.Reference_Id__c =calculateFormulaForReference;
                          newRuleAction.Value__c =calculateFormulaForReference;
                         }
                    }
                    else if(!newRUleAction.Field_Type__c.equalsIgnoreCase('string') ){
                       newRuleAction.Value__c =  calculateFormulaForReference== null || calculateFormulaForReference=='' ? String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c)):calculateFormulaForReference;
                    }
                    else{
                        system.debug('-->newRuleAction.field_API_Name__c '+newRuleAction.field_API_Name__c);
                        system.debug('-->newRuleAction.Value__c '+newRuleAction.Value__c);
                         
                         newRuleAction.Value__c = String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c));
                        // newRuleAction.Value__c = String.valueOf(sobjInstance.get(newRuleAction.Value__c));
                    }   
                    
                    selectedRefName = '';
                  
                }
                
                //* Enahancement - adding validations if maths expression are used like + - / *
                if(newRuleAction.Value__c != null && (newRuleAction.Value__c.contains('*') || newRuleAction.Value__c.contains('+') || newRuleAction.Value__c.contains('-') || newRuleAction.Value__c.contains('/')) && !validateExpressionIfAny(newRuleAction.Value__c,newRUleAction.Field_Type__c)){
                    //error 
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.MERGE_ERROR));
                     return false;
                }
                
            }// Logic of new Send Emai type starts here ---- 
            else if (newRuleAction.Type__c == 'Send Email' &&!ValidateSendEmailParams()) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.SENDEMAIL_ERROR));
                        return false;
            }// Logic of new action type added starts here ---- cloud challenger
           // Cloud Challenger Upsert Changes Start - Added Upsert Related Object in if condition
            else if(newRuleAction.Type__c == 'Insert Related Object' ||  newRuleAction.Type__c == 'Upsert Related Object' || newRuleAction.Type__c == 'Apex Callout-HTTP'  || newRuleAction.Type__c == 'Execute An Apex Job'){
                
                    if((newRuleAction.Type__c == 'Insert Related Object' ||  newRuleAction.Type__c == 'Upsert Related Object') && !isValidateInsertObject()){
                                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.INSERTRELATEDOBJECT_ERROR));
                        return false;
                    }
                    
                    if((newRuleAction.Type__c == 'Apex Callout-HTTP' || newRuleAction.Type__c == 'Execute An Apex Job') && !validateInputOutputParams()){
                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.MERGE_ERROR));
                        return false;
                    }
                    
                  
                
                newRuleAction.Value__c = '';
                newRuleAction.Field_Name__c = '';
                newRuleAction.Long_Value__c = '';
            }
            
           
             edit=false;
            
            //finally save the email template name if any
            if(newRuleAction.Email_Template__c!=null && newRuleAction.Email_Template__c!='' && emailTemplates.get(Id.valueof(newRuleAction.Email_Template__c))!=null ) 
                newRuleAction.EmailTemplateName__c = emailTemplates.get(Id.valueof(newRuleAction.Email_Template__c)).Name;
            
            Savepoint sp = Database.setSavepoint();
            try{
            
                //Here let us add the validation for merge field
                String value = newRuleAction.Field_Type__c.toLowerCase()=='textarea'? newRuleAction.Long_Value__c:newRuleAction.Value__c;
                System.debug(';;newRuleAction'+newRuleAction);
                if(newRuleAction.Field_Type__c != 'INTEGER' && newRuleAction.Field_Type__c != 'CURRENCY' && newRuleAction.Field_Type__c != 'DOUBLE' && !isValidValue(value)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,AW_RuleActionsController.MERGE_ERROR));
                    return false;
                }
               
                    
                Database.upsert(newRuleAction);
                 if(newRuleAction.Type__c == 'Insert Related Object' || newRuleAction.Type__c == 'Upsert Related Object' ||
                    newRuleAction.Type__c == 'Insert Unrelated Object' || newRuleAction.Type__c == 'Upsert Unrelated Object'){
                    upsertRelateRec(newRuleAction.Id);
                }
                 if(newRuleAction.Field_API_Name__c=='OwnerPrioritization'){
                    //insert records
                    upsertOwnerPrioritizationRec(newRuleAction.Id);
                }
                
                 //before save doALl the necessary validations:-
                 if(!doLimitValidations()){
                        Database.rollback(sp);
                        return false;
                 }
                
                
            }
            catch(Exception e){
                ApexPages.addMessages(e);
                Database.rollback(sp);
                return false;
            }
            return true;
    }
    
    /* this method is used to validate the lookup object */
    private boolean validateLookupObjectQuery(){
        try{
            string query = 'select '+newRuleAction.Lookup_Field_API_Name__c+' from '+newRuleAction.Lookup_Object__c;
            if(newRuleAction.Lookup_Where_fields__c != null){
	            String mergedWhereFields = newRuleAction.Lookup_Where_fields__c;
	            // Megha - Lookup object Update 
		        String mergeField = '';
		        while(mergedWhereFields.contains('{!')){
	                String whereMergeField = AW_ExecutionActionHelper.mergeField(mergedWhereFields , newRuleAction.Related_Object__c);
	                if(whereMergeField != null){
	                	mergeField += whereMergeField + ',';
	                } 
	                mergedWhereFields = mergedWhereFields.contains('{!' + newRuleAction.Related_Object__c + '.' + whereMergeField + '}')  ? mergedWhereFields.replace('{!' + newRuleAction.Related_Object__c + '.' + whereMergeField + '}', '') :  mergedWhereFields.replace('{!' + whereMergeField + '}', '');
	        	}
	        	
		        system.debug('--mergeField--'+mergeField);
		        system.debug('--mergedWhereFields--'+mergedWhereFields);
		        if(mergeField != null){
		        	  if(mergeField.trim().endsWith(',')){
		        	  	mergeField = mergeField.subString(0, mergeField.lastIndexOf(','));
		        	  } 
		        	  query='SELECT '+mergeField +  ' FROM '+newRuleAction.Related_Object__c;
	                     }  else
		          query += ' where '+ newRuleAction.Lookup_Where_Fields__c;
            } 
            system.debug('--query--'+query);
            DataBase.query(query+'  limit 1');
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Not valid query: '+ex.getMessage()));
            return false;
        }
        return true;
    }
    
     public boolean validateExpressionIfAny(String expr, String fieldtype){ 	
    	 
    	system.debug('--> validateExpressionIfAny.fieldtype '+fieldtype);
    	system.debug('--> validateExpressionIfAny.expr '+expr);
    	if( fieldtype.equalsIgnoreCase('reference') || fieldtype.equalsIgnoreCase('URL') ) return true;
    	AW_ExpressionEvaluation_Helper util = new AW_ExpressionEvaluation_Helper();
    	//if expression contains max & min operator
    	String exprEquation = expr.tolowercase() ;
    	if( fieldtype.equalsIgnoreCase('INTEGER') || fieldtype.equalsIgnoreCase('CURRENCY') || fieldtype.equalsIgnoreCase('DOUBLE')){
	    	if(exprEquation.startswithignorecase('max(') || exprEquation.startswithignorecase('min(')){
	               String startString = exprEquation.startswith('max(') ? 'max(':'min('; 
	               Boolean fieldValue1 = validateExpressionIfAny(exprEquation.substringBetween(startString,','),'');
	               Boolean fieldValue2 = validateExpressionIfAny(exprEquation.substringBetween(',',')'),'');       
	               return fieldValue2 && fieldValue1;
	       }
    	
    	
	    	String[] postfix =util.convertInfixToPostfix(expr); 
	    	
	    	system.debug('--> validateExpressionIfAny.expr '+postfix);
	    	system.debug('--> validateExpressionIfAny.postfix ' + postfix);
	    	Set<String> s1 = new Set<String>{'+', '-','*','/','(',')'};
	    	List<String> mergeFields=new List<String>();
	    	for(String exprSym: postfix){
	    		if(!s1.contains(exprSym)){
	    			//then check wether it is valid
	    			String fld = exprSym.startsWith('{!')?exprSym.substringBetween('{!','}'):exprSym;
	    			if(fld != exprSym){
	    				system.debug(fld);
		    			boolean check = pattern.matches('[a-zA-Z]+',fld);
		    			if(check)mergeFields.add(fld);
	    			}
	    			//other wise we are assuming it to be a constant number
	    		}
	    	}
	    	
	    	if(mergeFields.size()>0){
	               return validateMergeField(String.join(mergeFields,','));           
	        }
        }
	    return true;
        
    }
    
    /* this method validates the input/output params */ 
    private boolean validateSendEmailParams(){
        boolean result =true;
         
        if (newRuleAction.Additional_Emails__c!=null && newRuleAction.Additional_Emails__c.containsAny(';')) result= false;
        if (newRuleAction.Additional_Emails__c!=null && newRuleAction.Additional_Emails__c.containsAny(' ')) result= false;
        
        return result;
    }
    /* this method validates the input/output params */ 
    private boolean validateInputOutputParams(){
        
         //get all the fields defined in the input output params :)
         if(newRuleAction.Input_Parameters__c==null && newRuleAction.output_Parameters__c==null)
            return true;
            
         List<String> input = newRuleAction.Input_Parameters__c!=null? newRuleAction.Input_Parameters__c.split(','):new List<String>();
         List<String> output = newRuleAction.output_Parameters__c!=null? newRuleAction.output_Parameters__c.split(','):new List<String>();
         
         Set<String> fieldList = new Set<STring>();
         if(input.size()>0){
            for(String pair : input){
                List<String> keyValue = pair.split(':');
                if(!keyValue[1].startsWith('{!')) continue;
                String mergeField = keyValue[1].substringBetween('{!','}');
                if(!fieldList.contains(mergeField))
                    
                    fieldList.add(mergeField);

            }
         }
         if(output.size()>0){
            for(String pair : output){
                List<String> keyValue = pair.split(':');
                if(!keyValue[1].startsWith('{!')) continue;
                String mergeField = keyValue[1].substringBetween('{!','}');
                if(!fieldList.contains(mergeField))
                    fieldList.add(mergeField);

            }
         }
         if(!fieldList.isEmpty()){ // Megha fixed the issue QueryException because no field in query
             String soql='SELECT '+String.join(new List<STring>(fieldList),',')+
                           ' FROM '+newRuleAction.Related_Object__c+' LIMIT 1';
            try{
                System.debug(':::soql'+soql);
                List<SObject> record = database.query(soql);
            }catch(Exception e){
                AW_RuleActionsController.MERGE_ERROR =e.getMessage();
                return false;
            }
         }  
        return true;
    }
    
    
    /**
    * This method is used to validate insert related object 
    * It checks whether all the required fields are added in it or not 
    */
    private boolean isValidateInsertObject(){
        system.debug('---isValidateInsertObject parentFieldNameInChild --->'+parentFieldNameInChild );
        Set<String> tempFieldsRequired = new Set<String>();
        tempFieldsRequired.addAll(requiredFields.keySet());
        system.debug('---isValidateInsertObject tempFieldsRequired --->'+tempFieldsRequired );
      
        for(Values_for_Action_Insert_Record__c info: lstInsRelRec){
            if(info.value__c != null && info.value__c != ''){
                tempFieldsRequired.remove(info.Name.toLowerCase());
            }
        }
        if(parentFieldNameInChild != null && newRuleAction.Related_Object__c != null && 
            parentFieldNameInChild.get(newRuleAction.Related_Object__c.tolowerCase()) != null){
            string fieldName = parentFieldNameInChild.get(newRuleAction.Related_Object__c.tolowerCase()).tolowercase();
            if(tempFieldsRequired.contains(fieldName)){ 
                tempFieldsRequired.remove(fieldName);
            }
        }
        
        if(tempFieldsRequired.size() > 0){
            List<String> fieldList = new List<String>();
            for(String field: tempFieldsRequired){
                fieldList.add(requiredFields.get(field));   
            }
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Cannot enabled record because required field missing:'+String.join(fieldList,', ')));
            return false;
        }   
        return true;
    }
    /**
     * Temporartily storing the related record configuration in the list ---- cloud challenger
     */
    public void createRelateRec(){
        Values_for_Action_Insert_Record__c insRelRec = new Values_for_Action_Insert_Record__c();
        insRelRec.Name = fieldType;
        if(newRUleAction.Field_Type__c.equalsIgnoreCase('reference')){
            /*
            system.debug('--1AA createRelateRec.field_API_Name__c '+newRuleAction.field_API_Name__c );
            system.debug('--2BB createRelateRec.Reference_Id__c '+String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c)) );
            system.debug('--3CC createRelateRec.Value__c '+newRuleAction.field_API_Name__c );
            */
            if (calculateFormulaForReference== null || calculateFormulaForReference==''){
                          insRelRec.Reference_Id__c  =String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c));
                          insRelRec.Value__c  =selectedRecordName(insRelRec.Reference_Id__c);
                         // insRelRec.Value__c  =selectedRecordName(newRuleAction.Reference_Id__c);
            }
            else
            {
                 insRelRec.Reference_Id__c=calculateFormulaForReference;
                 insRelRec.Value__c  =calculateFormulaForReference;
            }
                           
           // insRelRec.Reference_Id__c = calculateFormulaForReference==''? (String)sobjInstance.get(newRuleAction.field_API_Name__c):calculateFormulaForReference;
           // insRelRec.Value__c = calculateFormulaForReference==''? selectedRecordName(insRelRec.Reference_Id__c):calculateFormulaForReference;    
            
        }
        else{           
            if(calculateFormulaForReference != null && calculateFormulaForReference.trim() != ''){
                insRelRec.Value__c  = calculateFormulaForReference;
            }else{
                insRelRec.Value__c  = String.valueOf(sobjInstance.get(newRuleAction.field_API_Name__c));
            }
        }
        sobjInstance.put(newRuleAction.field_API_Name__c,null);
       
        lstInsRelRec.add(insRelRec);
        for(Values_for_Action_Insert_Record__c rec: lstInsRelRec){
            setFieldNames.add(rec.Name);
        }
        system.debug('-->populateFields');
        populateFields(objType);
        system.debug('-->displayAssignmentPanel.createRelateRec');
        displayAssignmentPanel();
    }
    /**
     * Getting all the related record configuration from rule action ---- cloud challenger
     */
    public void populatedRelatedRecInfo(Id ruleActionId){
       // renderValueField = false;
        if(lstInsRelRec.size() == 0){
            lstInsRelRec = [select Value__c,Name,Rule_Action__c from Values_for_Action_Insert_Record__c where Rule_Action__c =: ruleActionId];
            for(Values_for_Action_Insert_Record__c rec: lstInsRelRec){
                setFieldNames.add(rec.Name);
            }
        }
    }
    /**
     * Setting the value of rule action if for all the related object record fields ---- cloud challenger
     */
    private void upsertRelateRec(Id ruleActionId){
        for(Values_for_Action_Insert_Record__c info: lstInsRelRec){
            if(info.Rule_Action__c == null){
                info.Rule_Action__c = ruleActionId;
            }
        }       
        upsert lstInsRelRec;
    }
    /**
     * This funtion will be use to delete the record from the related when rule action is
     * insert related object ---- cloud challenger
     */
    public void deleteRec(){        
        if(selectedRecordId != null && selectedRecordId != ''){
            Integer selectedIndex = -1;
            for(selectedIndex = 0; selectedIndex < lstInsRelRec.size() ;selectedIndex++){
                Values_for_Action_Insert_Record__c info = lstInsRelRec[selectedIndex];
                if(info.Name == selectedRecordId){
                    if(setFieldNames.contains(info.Name)){
                        setFieldNames.remove(info.Name);
                    }
                    break;
                }
            }
            Values_for_Action_Insert_Record__c info = lstInsRelRec[selectedIndex];
            if(info.Id != null){
                Values_for_Action_Insert_Record__c delRec = new Values_for_Action_Insert_Record__c(id= info.Id);
                Database.delete(delRec,false);
                lstInsRelRec = new List<Values_for_Action_Insert_Record__c>();
                populatedRelatedRecInfo(newruleAction.Id);
            }
            else{
                lstInsRelRec.remove(selectedIndex);
            }
            populateFields(objType);
        }
    }
    
    public void sortSelectListOnLabel(List<SelectOption> options){
        Map<String,List<SelectOption>> mapping = new Map<String,List<SelectOption>>();
        for(Selectoption opt : options) {
            List<SelectOption> optList = new List<SelectOption>();
            if(mapping.containsKey(opt.getLabel())){
                optList = mapping.get(opt.getLabel());
            }
            else{
                mapping.put(opt.getLabel(),optList);
            }
            optList.add(opt);
        }
        List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        options.clear();
        for (String key : sortKeys) {
            options.addAll(mapping.get(key));
        }
    }
    
     /*
    returns a list of Email templates
    @access : public
    @params : none
    @retrun : List<SelectOption>
    */
    public void getTemplates() {
        String FolderId= ApexPages.currentPage().getParameters().get('folderId');
        emailTemplateOptions = new List<List<SelectOption>>();
        emailTemplates = new Map<Id,EmailTemplate>([Select Id, Name  FROM EmailTemplate WHERE FolderId=:FolderId]);
        
        //List<EmailTemplate> ets = [Select Id, Name  FROM EmailTemplate ];
        //emailTemplateOptions.add(new SelectOption('','--None--'));
        List<SelectOption> options = new List<SelectOption>{new SelectOption('','--None--')};
        for (EmailTemplate et: emailTemplates.values()){
            options.add(new SelectOption(et.Id, et.Name));
            if(options.size() == 1000){
                emailTemplateOptions.add(options);
                options = new List<SelectOption>();
            }
        }
        if(options.size() > 0){
            emailTemplateOptions.add(options);
        }
        
        //return options;
    }
    
    /* return list of folders */
    public List<SelectOption> getFolders(){
        
        List<SelectOption> options = new List<SelectOption>();
        Map<Id,Folder> folders= new Map<Id,Folder>([Select Id, Name  FROM FOLDER WHERE Type='Email' ]);
        //List<EmailTemplate> ets = [Select Id, Name  FROM EmailTemplate ];
        options.add(new SelectOption('','--None--'));
        system.debug('--folders '+folders);
        for (Folder et: folders.values()){
            options.add(new SelectOption(et.Id, et.Name));
        }
        return options;
    }
    
    public void actionChanged(){
    apexJobsOptions = new List<SelectOption>();
     if(newRuleAction.TYpe__c == 'Execute an Apex Job'){
        List<ApexClass> apexClsList = [select name from ApexClass];
        for(ApexClass cls : apexClsList){
            try{
               // RuleActionInterface f = (RuleActionInterface)((Type.forName(cls.Name)).newInstance());
                 if (!edit ) {
                 
                        AW_RuleActionInterface  f = (AW_RuleActionInterface )((Type.forName(cls.Name)).newInstance());
                        /*system.debug('--Class Name--'+cls.Name);
                        system.debug('-------------->848:' + f.getImplementedObjApiName());
                        system.debug('-------------->849:' + rule.Object__c);
                        system.debug('-------------->851:' + setRelatedObjName);
                        */
                        if(f.getImplementedObjApiName() != null && 
                        (f.getImplementedObjApiName().equalsIgnoreCase(rule.Object__c) || 
                            setRelatedObjName.contains(f.getImplementedObjApiName().toUpperCase()))){
                        apexJobsOptions.add(new SelectOption(cls.name,cls.name));
                       }
                   }

            }
            catch(Exception ex){
                system.debug(ex.getMEssage()+'--message--'+cls.Name);               
            }
        }
     }
   }
    /*
      validate if the value as merge fields in it 
    */
    private Boolean isValidValue(String value){
        String concatOp ='&';
        AW_RuleActionsController.MERGE_ERROR ='Invalid syntax for merge field provided';
        system.debug('value===>'+value);
       // value===>{!Whoid.Last_Detail__c}
        
        if(value==null || value=='' || (!value.contains(concatOp) && !value.contains('{!'))) return true;
        
        if(value.startsWith(concatOp) || value.endsWith(concatOp)) return false;
        List<String> splitValue= value.split(concatOp );
         
         system.debug('splitValue===>'+splitValue);
       
        List<string> mergeFields = new List<string>();
        //checking
        for(String s : splitValue){
           system.debug(s);
            s = s.trim();
            if(!s.contains('{!')){
            	continue;
            }
            if(s.startsWith('\'')){
                //then it shuld end with '
                if(!s.endsWith('\''))
                    return false;
                    
                if(s.contains('{!'))
                    return false;    
                    
            }
            
            if(s.startsWith('{!')){
                //then it shuld end with }
                if(!s.endsWith('}'))
                    return false;
            }
            
            if(!s.startsWith('{!') && !s.startsWith('\'')){
               return false;
            }
            if(s.startsWith('{!'))
                mergeFields.add(s.substringBetween('{!','}'));
        }
        
        if(mergeFields.size()>0){
               return validateMergeField(String.join(mergeFields,','));
            
        }
        
        return true;
    }
   
   public void addOwnerPriority(){
    	if(ownerPriority.User_Queue_Group_Id__c==null){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please select one of this user/queue/public group'));	
    		return;
    	}
    	if(Id.valueof(ownerPriority.User_Queue_Group_Id__c).getSObjectType() == UserRole.getSObjectType()){
    		for(User u : [select id , Name from User where userRoleId = : ownerPriority.User_Queue_Group_Id__c AND isActive = true]){
    			ownerPriorityList.put(String.valueOf(math.random()),
                  new OwnerPrioritization__c(Priority__c=ownerPriority.priority__c,
					  User_Queue_Group_Id__c = u.Id,
					  User_Queue_Group__c =u.name	
                  )
                 );
    		}
    	}else if(Id.valueof(ownerPriority.User_Queue_Group_Id__c).getSObjectType()!=User.getSObjectType()){
    		//get all the members:-
    		List<User> usersingroup =[Select Id,Name FROM User WHERE Id IN (Select UserOrGroupId FROM GroupMember WHERE GroupId=:ownerPriority.User_Queue_Group_Id__c)];
    		for(User u : usersingroup){
    			ownerPriorityList.put(String.valueOf(math.random()),
    			                      new OwnerPrioritization__c(Priority__c=ownerPriority.priority__c,
    									  User_Queue_Group_Id__c = u.Id,
    									  User_Queue_Group__c =u.name	
    			                      )
    			                     );
    		}
    	}else{    	
	    	ownerPriority.User_Queue_Group__c = sendEmailUserName;
	    	ownerPriorityList.put(String.valueOf(math.random()),ownerPriority);
    	}
    	ownerPriority = new OwnerPrioritization__c();
    }
    
    public void deleteOwnerPriority(){
        OwnerPrioritization__c rec= ownerPriorityList.get(selectedRecordId);
        if(rec.Id!=null) delete rec;
        ownerPriorityList.remove(selectedRecordId);   
    }
   
   private Boolean validateMergeField(String field){
        
        system.debug('---> validateMergeField ' +field);
        //adding a fix for what id
        if(newRuleAction.Related_Object__c.toLowerCase()=='task' && ( field.startsWith('What') ||  field.startsWith('Who')) ){
            //then return true - without validation as poly reference field throw exceptions 
            return true;
        }
         
        
        String soql='SELECT '+field+
                       ' FROM '+newRuleAction.Related_Object__c+' LIMIT 1';
            try{
                List<SObject> record = database.query(soql);
            }catch(Exception e){
                AW_RuleActionsController.MERGE_ERROR =e.getMessage();
                return false;
            }  
        return true;
    }
    
    // cloudchallenger
    public void showHideValueField(){
        if(renderValueFieldForFormula){
            renderValueFieldForFormula = false; 
        }else{
            renderValueFieldForFormula = true;
        }
    }
    
}
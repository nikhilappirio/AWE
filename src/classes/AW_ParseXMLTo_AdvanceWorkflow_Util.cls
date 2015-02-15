//
// (c) 2012 Appirio, Inc.
// AW_ParseXMLTo_AdvanceWorkflow_Util                                                     
// This class is used to parse Advance Workflow in XML format
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2012     Peter Babalis     Added Status and Version  for Rules
// 29 Mar 2013     Peter Babalis     Detect invalid objects and fields during the import process
// 12 Jun 2013     Peter Babalis     Fix Null issue in rule actions
//
// Steps to Add New Node 
// 1)  Define node<---> in AW_ParseXML_Action_Helper or AW_ParseXML_Criteria_Helper
// 2)  Enhance AW_ImportExport_Controller to include in SOQL  ruleCriteriaQuery or ruleactionQuery the new field for Retrieval 
// 3)  Enhance AW_ImportExport_Controller to include in the appropriate section ( Criteria, Action etc ) statment like  body +=  '<NODE_NAME>'+rc/ra.nodename__c+'</NODE_NAME>' + '\n';
// 4)  Enhance  AW_ParseXMLTo_AdvanceWorkflow_Util to map the retrieved field from object to helper function e.g criteria.field_name__c         =   cr.criteriaName;
// 5)  Enhance  AW_ParseXMLTo_AdvanceWorkflow_Util to mape tag of node to actual field eg. ...(node.getName()   == 'RULE_DESCRIPTION'){
                                                    
//
//

public with sharing class AW_ParseXMLTo_AdvanceWorkflow_Util {

    
    static  AW_ParseXML_Rule_Helper                 wfRule              =   null;
    static  AW_ParseXML_Workflow_Helper             wFAdvance           =   null;
    static  AW_ParseXML_Criteria_Helper             auxCriteria         =   null;
    static  AW_ParseXML_Action_Helper               auxAction           =   null;
    static  AW_ParseXML_RelatedAction_Helper        auxRelatedAction    =   null;   
    static  String codeImport =null;
    static  String idWFAdvance = null;
    static  Integer ruleNumber =    0;

    static  Map<String, Schema.SObjectType> gd      =   null;
    static  Map<String,Error_Log__c> invalidObjectMap = null;
    static  Map<String, Set<String>> referenceFieldObjectMap = new Map<String, Set<String>>(); // Megha
    static Map<String,Map<String, Schema.SObjectField>> fieldsMap = new Map<String, Map<String , Schema.SobjectField>>();
    static  Map<String, Map<String, String>>         referenceFieldMap = new Map<String, Map<String, String>>(); //used
    
    public static String  parser(String xmlFromFile, String ruleRef, String id){
        
        DOM.Document doc    =   new DOM.Document();    
        codeImport          =   ruleRef; 
        idWFAdvance         =   id;
        gd                  =   Schema.getGlobalDescribe(); 
        invalidObjectMap    =   new Map<String,Error_Log__c>();
        
        
        try {
            //doc.load(xmlFromFile);  
            doc.load(escapecharsTochars(xmlFromFile ));    
            DOM.XMLNode root = doc.getRootElement();
            walkThrough(root);
 
            //System.debug('\n--->Descripcion object: '+wFAdvance);
            //Insert XML (RULE) in salesforce
            insertarObjetoAuxilar(wfAdvance);
            return null;
        }catch (System.XMLException e) {  // invalid XML
            
            return e.getMessage();
        }
    }

    public static String charsToescapechars(String str){
         if(str.contains('&amp;')){
             str = str.replaceall('&amp;', '&');
         }
        //Add here more 'if conditions' if you want to scape more characteres
        return str;
        }
        
    public static String escapecharsTochars(String str){
         if(str.contains('&')){
            str = str.replace('&','&amp;');
            }
       
        //Add here more 'if conditions' if you want to scape more characteres
        return str;
    }
    
     
    
    public static Boolean validateRules(AW_ParseXML_Workflow_Helper wfAdvanceObject){
       
          //field map of the object
          Map<String,Map<String,Schema.SObjectField>> fieldMap;
            
         //store the global describe result
          gd = new Map<String, Schema.SObjectType>();
             
         //store all the relationships names
         Map<String,String> relationshipNames = new Map<String,String>();
         Map<String,Set<String>> validRelationShips= new Map<String,Set<String>>();   
         
         String sobjectName = wfAdvanceObject.objeto;
         
         gd = Schema.getGlobalDescribe(); 
         Schema.DescribeSObjectResult R =gd.get(sobjectName).getDescribe();
         
         Map<String,Set<String>> criteriaFields = new Map<String,Set<String>>();
        
         for(AW_ParseXML_Rule_Helper rule : wfAdvanceObject.listaRules){
              /* Rules can have criteria from its related object also */
              Set<String> objectDefinedInCriteria = new Set<String>();
             for(AW_ParseXML_Criteria_Helper cr : rule.criterias){  
                        if(!objectDefinedInCriteria.contains(cr.criteriarelatedObject.toLowerCase())){
                            objectDefinedInCriteria.add(cr.criteriarelatedObject.toLowerCase());      
                        }
             }
             
              for(AW_ParseXML_Action_Helper ac : rule.actions){  
                        if(!objectDefinedInCriteria.contains(ac.actionrelatedObject.toLowerCase())){
                            objectDefinedInCriteria.add(ac.actionrelatedObject.toLowerCase());      
                        }
             }
             
              /* get all the related child objects for this object of the rule */
              for(Schema.ChildRelationship child: R.getChildRelationships()){
                    Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                    String objname =descRes.getName().toLowerCase();
                    if(objname.equalsIgnoreCase(sobjectName))continue;
                    if(objectDefinedInCriteria.contains(objname)){     
                        relationshipNames.put(objname,child.getRelationshipName());
                        
                        Map<String,Schema.SObjectField> fieldList = descRes.fields.getMap();    
                        for(String f: fieldList.keySet()){
                            Schema.DescribeFieldResult FR =fieldList.get(f).getDescribe();
                            system.debug('getRelationshipName-->'+FR.getRelationshipName());
                            if(FR.getRelationshipName()!=null){
                                Set<String> validRN = validRelationShips.get(objname.toLowerCase())!=null ? validRelationShips.get(objname.toLowerCase()): new Set<String>();
                                validRN.add(FR.getRelationshipName());
                                validRelationShips.put(objname.toLowerCase(),validRN);
                            }
                        }
                        
                    }
                }
             
             
             
             if(!rule.criterias.isEmpty()){
             	system.debug('rule.criterias '+ rule.criterias);
                for(AW_ParseXML_Criteria_Helper cr : rule.criterias){
                     Set<String> fieldToAdd = criteriaFields.get(cr.criteriarelatedObject.toLowerCase())!=null ? criteriaFields.get(cr.criteriarelatedObject.toLowerCase()): new Set<String>(); 
                     if(cr.criteriafieldapiname.toLowerCase() =='crossformula')
                      	 fieldToAdd.add(cr.crossFormula.toLowerCase());   
                     else if (!fieldToAdd.contains(cr.criteriafieldapiname.toLowerCase())) {
                               fieldToAdd.add(cr.criteriafieldapiname.toLowerCase());   
         //                     system.debug('-->fieldtoAdd '+fieldToAdd);
                              criteriaFields.put(cr.criteriarelatedObject.toLowerCase(),fieldToAdd);      
                     }
                  }
             } 
             
             if(!rule.actions.isEmpty()){
                  for(AW_ParseXML_Action_Helper ac : rule.actions){   
                         if(ac.typeAction=='Update Field'){
                             Set<String> fieldToAdd = criteriaFields.get(ac.actionrelatedObject.toLowerCase())!=null ? criteriaFields.get(ac.actionrelatedObject.toLowerCase()): new Set<String>(); 
                             /*
                             String fieldToUpdate = action.fieldName=='CrossObject' ? action.CrossObjectField__c: action.fieldName.toLowerCase();
                             */
                             if(!fieldToAdd.contains(ac.actionfieldAPIName.toLowerCase())){
                                    fieldToAdd.add(ac.actionfieldAPIName.toLowerCase());
                             }
                             
                             String value = ac.actionlongValue!=null && ac.actionlongValue.trim()!=''? ac.actionlongValue:ac.actionvalue;
                             if(value!=null && (value.contains('&') || value.startsWith('{!'))){
                                List<String> splitVaue = value.split('&');
                                for(String s:splitVaue){
                                    s=s.trim();
                                    if(s.startsWith('{!')){
                                        String mergeField= s.substringBetween('{!','}');
                                        fieldToAdd.add( mergeField.toLowerCase());
                                    }
                                }
                             }else  if(value != null && value.contains('.')){
                                //then validate:- as we can have . in value field as well for www.koncero.com could be a value
                                List<String> splitReference = value.split('\\.');
                                Set<String> validRN = validRelationShips.get(ac.actionrelatedobject.toLowerCase())!=null ? validRelationShips.get(ac.actionrelatedobject.toLowerCase()): new Set<String>();
                                if(validRN.contains(splitReference[0])){
                                    fieldToAdd.add( value.toLowerCase());
                                }
                            }
                             
                             criteriaFields.put(ac.actionrelatedObject.toLowerCase(),fieldToAdd);   
                         }                         
                  }
             }
         }
         
         Set<String> parentFields = criteriaFields.get(sobjectName.toLowerCase());  
         Set<String> parentUniqueFields = new Set<String>();          
         for (String parentField : parentFields) {
	 		if ( !parentUniqueFields.contains(parentField.toLowerCase()))  {  
	    			parentUniqueFields.add(parentField);
    			//	System.debug('parentUniqueFields  is:  ' + parentUniqueFields);
	    	}
 		}		 
  
        // String fields = AW_AdvanceWorkflowExecutionHelper.joinSet(parentFields,',');
         String fields = AW_AdvanceWorkflowExecutionHelper.joinSet(parentUniqueFields,',');
         String qrySOQL='SELECT ' + fields +',Id ';
         	//System.debug('--->AW_ParseXML_fields  ' + fields);
        
            //now add the child queries also as they need to be evaluated in the query :)
            for(String obj:criteriaFields.keySet()){
                if(obj.equalsIgnoreCase(sobjectName)) continue;
                fields =AW_AdvanceWorkflowExecutionHelper.joinSet(criteriaFields.get(obj),',');
                qrySOQL+=' , (SELECT ' + fields +',Id FROM '+relationshipNames.get(obj)+')';                        
            }
      
        qrySOQL+=' FROM '+sobjectName+' LIMIT 1';
       // system.debug('--->AW_ParseXML_fields.qrySOQL '+qrySOQL);
        try{
            List<SObject> sobjectRecords = database.query(qrySOQL);   
        }catch(Exception e){
            errorInsert(e,codeImport,'');
            return false;
        }
        return true;
    } 
     
    static Map<String,STring> insertedRuleIds = new Map<String,STring>();
    
    public static void insertarObjetoAuxilar(AW_ParseXML_Workflow_Helper wfAdvanceObject){
    
           /*if(invalidObjectMap.values().size() > 0){
                insert invalidObjectMap.values();   
                return;
           }*/
           
           if(!validateRules(wfAdvanceObject ))
                        return;
            
           if(wfAdvanceObject ==null ||  wfAdvanceObject.listaRules.isEmpty())
                return;
            
           
           Savepoint sp = Database.setSavepoint();
           try{
           		if(!referenceFieldMap.isEmpty()){
           			referenceFieldMap = AW_ImportExportHelper.loadReferenceIds(referenceFieldMap, 'Name', 'Id');
           		}
                List<Rule__c> rules = insertRules(wfAdvanceObject);//first create rules
                
                for(Rule__c r : rules)
                    insertedRuleIds.put(r.Name,r.Id);   
                
                //nsert criterias
                List<RuleCriteria__c> rulesCriteria = insertCriteria(wfAdvanceObject);
                
                //insert action
                List<RuleAction__c> ruleActions = insertActions(wfAdvanceObject);
                
           }catch(Exception e){
                Database.rollback(sp);
                errorInsert(e,codeImport,'Inserting Rules/Criteria/Actions');
           }
    }
    
    static List<Rule__c> insertRules(AW_ParseXML_Workflow_Helper wfAdvanceObject){
        List<Rule__c> ruleToInsert = new List<Rule__c>();
        for(AW_ParseXML_Rule_Helper rule : wfAdvanceObject.listaRules){
                Rule__c ruleSF                  =   new Rule__c();
                if (rule.rulestatus=='Active'){
                    ruleSF.Version__c               =   rule.ruleversion;                              
                    ruleSF.Status__c                =   rule.rulestatus;
                //  ruleSF.Advance_Workflow__c      =   idWFAdvance;
                }else{
                    ruleSF.Version__c               =   1;                              
                    ruleSF.Status__c                =   'Draft';
                }
                //ruleSF.Advance_Workflow__c      =   idWFAdvance;
                //ruleSF.Version__c               =   1;                              
               // ruleSF.Status__c                =   'Draft';
                ruleSF.Name                     =   rule.ruleName;
                ruleSF.Object__c                =   wfAdvanceObject.objeto;
                ruleSF.Description__c           =   rule.description;
                ruleSF.Evaluation_Rule__c       =   rule.evaluationRule;
                ruleSF.DisplayfilterLogic__c    =   rule.ruleCriteria;
                ruleSF.Order__c                 =   rule.orderRule;
                ruleSF.Execution_Behavior__c    =   rule.executionBehavior;
                ruleSF.Filter_Logic__c          =   rule.filterLogic;
                ruleSF.import_code__c           =   codeImport;

                ruleToInsert.add(ruleSF);
        }
        
         insert ruleToInsert;
         return ruleToInsert;
    }
    
     private static List<RuleCriteria__c> insertCriteria(AW_ParseXML_Workflow_Helper wfAdvanceObject){
            
            List<RuleCriteria__c > toInsertCr = new List<RuleCriteria__c >();
            for(AW_ParseXML_Rule_Helper rule : wfAdvanceObject.listaRules){
                if(rule.criterias.isEmpty())
                    continue;
                    
                for(AW_ParseXML_Criteria_Helper cr : rule.criterias){   
                    RuleCriteria__c criteria        =   new RuleCriteria__c();
                    criteria.field_name__c          =   cr.criteriaName;
                    criteria.field_api_name__c      =   cr.criteriafieldapiname;
                    criteria.field_type__c          =   cr.critetriafieldtype;
                    criteria.CrossFormula__c        =   cr.crossFormula;
                    criteria.Matching_Type__c       =   cr.matchingType;
                    criteria.Matching_Value__c     =   cr.matchingValue1;
                    criteria.Maximum_Value__c       =   cr.maximumValue;
                    criteria.Minimum_Value__c       =   cr.minimumValue;
                    criteria.Related_Object__c      =   cr.criteriarelatedObject;
                    criteria.Record_Type_Id__c      =   cr.recordtypeid;
                    criteria.Rule__c                =   insertedRuleIds.get(rule.ruleName);
                    toInsertCr .add(criteria);
                }
            }
            
            if(toInsertCr.size()>0) insert toInsertCr;
            
            return toInsertCr;
    }
    
    private static List<RuleAction__c> insertActions(AW_ParseXML_Workflow_Helper wfAdvanceObject){
        List<RuleAction__c > toInsertAction = new List<RuleAction__c >();
        Integer num= 100;
        Map<String,AW_ParseXML_Action_Helper>  actionList = new  Map<String,AW_ParseXML_Action_Helper>();
        for(AW_ParseXML_Rule_Helper rule : wfAdvanceObject.listaRules){ 
                if(rule.actions.isEmpty())
                    continue;
                                
                
                for(AW_ParseXML_Action_Helper ac : rule.actions){   
                    RuleAction__c action            =   new RuleAction__c();
                    
                    if (ac.actionrelatedObject!=null)     action.Related_Object__c        =   ac.actionrelatedObject;
                    if (ac.typeAction!=null)              action.Type__c                  =   ac.typeAction;
                    if (ac.actionfieldName!=null)         action.Field_Name__c            =   ac.actionfieldName;
                    if (ac.actionfieldAPIName!=null)      action.Field_API_Name__c        =   ac.actionfieldAPIName;
                    if (ac.actionfield_Type!=null)        action.Field_Type__c            =   ac.actionfield_Type;
                    if (ac.actionvalue!=null)             action.Value__c                 =   ac.actionvalue;
                    if (ac.actionlongValue!=null)         action.Long_Value__c            =   ac.actionlongValue;
                    if (ac.actionEmailTemplateName!=null) {
                    	action.EmailTemplateName__c     =   ac.actionEmailTemplateName;
                    	// populate Email Template Id through reference
                    	if(referenceFieldMap.containsKey('EmailTemplate') && referenceFieldMap.get('EmailTemplate').get(action.EmailTemplateName__c) != null){
                    		action.Email_Template__c    =   referenceFieldMap.get('EmailTemplate').get(action.EmailTemplateName__c);
                    	}
                    }
                    //if (ac.actionemailTemplate_ID!=null)  action.Email_Template__c        =   ac.actionemailTemplate_ID;
                    
                    if (ac.actionlongValue!=null)         action.Long_Value__c            =   ac.actionlongValue;
                    if (ac.actionReference_Id!=null)      action.Reference_Id__c          =   ac.actionReference_Id;
                    if (ac.actionCrossObjectField!=null)  action.CrossObjectField__c      =   ac.actionCrossObjectField;
                    if (ac.actionUser_Owner!=null)        action.User_Owner_Id__c         =   ac.actionUser_Owner;
                    if(ac.actionnotifyUser == 'TRUE')     action.Notify_User__c = true;
                    if(ac.actionBulkAPI == 'TRUE')     action.Bulk_API__c = true;
                    if (ac.actionAdditionalEmails!=null) action.Additional_Emails__c=  ac.actionAdditionalEmails;
  					if (ac.actionApexJobClass!=null) action.Apex_Job_Class__c=  ac.actionApexJobClass;
  					if (ac.actionCallOutAction!=null) action.CallOut_Action__c=  ac.actionCallOutAction;
  					if (ac.actionCalloutMethod!=null) action.Callout_Method__c=  ac.actionCalloutMethod;
  					if (ac.actionCalloutTimeout!=null) action.Callout_Timeout__c=  ac.actionCalloutTimeout;
  					if (ac.actionLookupWhereFields!=null) action.Lookup_Where_Fields__c=  ac.actionLookupWhereFields;
  					if (ac.actionEndPoint!=null) action.End_Point__c=  ac.actionEndPoint;
					if (ac.actionEndpointURL!=null) action.Endpoint_URL__c=  ac.actionEndpointURL;
  					if (ac.actionInputParameters!=null) action.Input_Parameters__c=  ac.actionInputParameters;
  					if (ac.actionLookupFieldAPIName!=null) action.Lookup_Field_API_Name__c=  ac.actionLookupFieldAPIName;
  					if (ac.actionLookupFieldName!=null) action.Lookup_Field_Name__c=  ac.actionLookupFieldName;
  					if (ac.actionLookupObject!=null) action.Lookup_Object__c=  ac.actionLookupObject;
  					if (ac.actionOutputParameters!=null) action.Output_Parameters__c=  ac.actionOutputParameters;
  					if (ac.actionRequestParameter!=null) action.Request_Parameter__c=  ac.actionRequestParameter;
  					if (ac.actionResponseParameter!=null) action.Response_Parameter__c=  ac.actionResponseParameter;
  					// populate User Owner Id by reference
  					if(ac.user_Name != null && referenceFieldMap.containsKey('User') && referenceFieldMap.get('User').get(ac.user_Name) != null){
  						action.User_Owner_Id__c =  referenceFieldMap.get('User').get(ac.user_Name);
  					}else if(ac.group_Name != null && referenceFieldMap.containsKey('Group') && referenceFieldMap.get('Group').get(ac.group_Name) != null){
  						action.User_Owner_Id__c =  referenceFieldMap.get('Group').get(ac.group_Name);
  					}else{
  						action.User_Owner_Id__c =  null;
  					}
   					// if (ac.actionUserOwnerId!=null) action.User_Owner_Id__c=  ac.actionUserOwnerId;
                    // reference Field checking - JDC
                    if(action.Related_Object__c != null && action.Field_Type__c != null && action.Field_Type__c.equalsIgnoreCase('Reference') 
	                			&& action.value__c != null && action.Field_API_Name__c != null 
	                			&& referenceFieldObjectMap.containsKey(action.Related_Object__c+'.'+action.Field_API_Name__c)){
	                	for(String sobjName  : referenceFieldObjectMap.get(action.Related_Object__c+'.'+action.Field_API_Name__c)){
		                	System.debug(':::referenceFieldMap.get(sobjName)'+referenceFieldMap.get(sobjName) +'::'+referenceFieldMap.get(sobjName).containsKey(action.value__c));
		                	if(referenceFieldMap.containsKey(sobjName) && referenceFieldMap.get(sobjName).containsKey(action.value__c) && referenceFieldMap.get(sobjName).get(action.value__c) != null){
		                		action.Reference_Id__c = referenceFieldMap.get(sobjName).get(action.value__c); 
		                		break;
		                	}
		                }
	                }
                    /*if(action.Field_Type__c == 'REFERENCE' && action.Related_Object__c != null && action.Field_API_Name__c != null && action.Value__c != null){
                    	if(referenceFieldObjectMap.containsKey(action.Related_Object__c +'.'+action.Field_API_Name__c)){
                    		for(String sobj : referenceFieldObjectMap.get(action.Related_Object__c +'.'+action.Field_API_Name__c)){
                    			if(!)
                    		}
                    	}
                    }*/
                    action.Rule__c                  =   insertedRuleIds.get(rule.ruleName);
                    action.Unique_Import_Code__c = String.valueof(num);
                    actionList.put(String.valueof(num),ac);
                    num++;
                    toInsertAction.add(action);
                }
        }
        
        if(toInsertAction.size()>0) insert toInsertAction;
        
        Map<String,STring> actionIds = new Map<String,STring>();
        for(RuleAction__c ac:toInsertAction)
            actionIds .put(ac.Unique_Import_Code__c,ac.Id);
        
        List<Values_for_Action_Insert_Record__c> relatedInfo = new List<Values_for_Action_Insert_Record__c>();
        num =100;
        for(String key : actionList.keySet()){
            AW_ParseXML_Action_Helper ac1 = actionList.get(key);
            if(!ac1.listaRAction.isEmpty()){
                for(AW_ParseXML_RelatedAction_Helper ra : ac1.listaRAction){
                    Values_for_Action_Insert_Record__c relatedAction    =   new Values_for_Action_Insert_Record__c();
                    relatedAction.Rule_Action__c    =   actionIds.get(key);
                    relatedAction.Name              =   ra.FieldName;
                    relatedAction.Value__c          =   ra.value;
                    relatedInfo.add(relatedAction);
                }
            }
        }
        
        if(relatedInfo.size()>0) insert relatedInfo;

        return toInsertAction;
    }

    
    public static void errorInsert(Exception e,String code,String name){
        Error_Log__c        error   =   new Error_Log__c();         
        error.Error_Description__c  =   String.valueOf(e);
        error.import_code__c        =   code;
        error.ErrorSource__c =  name;
        insert error;   
    }
    
    
    //Se mapea el XML en objeto auxliar WFAdvance
    public static void walkThrough(DOM.XMLNode node) {
        
        String result = '\n';
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            
            
            /*--------WORKFLOW SECTION NAME  --------*/
            if(node.getName() == 'DVANCE_WORKFLOW_NAME'){
                wfAdvance   =   new AW_ParseXML_Workflow_Helper();
                wfAdvance.name  =   node.getAttributeValue('name', null);
            }
            /*--------GENERAL SECTION  ---------*/
            if(node.getName() == 'DESCRIPTION'){
                wfAdvance.description   =   node.getText();
            }else if(node.getName() == 'OBJECT'){
                wfAdvance.objeto    =   node.getText();
            }else if(node.getName() == 'ENABLED'){
                wfAdvance.enabled   =   node.getText();
            }           
            
            /*---------RULE SECTION ---------*/
            if(node.getName()       == 'RULE_NAME'){    
                ruleNumber++;           
                wfRule              =   new AW_ParseXML_Rule_Helper();
                wfRule.ruleNumber   =   ruleNumber;
                wfRule.ruleName     =   node.getAttribute('name', null);
                wFAdvance.listaRules.add(wfRule);
            }
            else if(node.getName()  == 'RULE_DESCRIPTION'){
                wfRule.description  =   charsToescapechars(node.getText());
            }else if(node.getName()  == 'RULE_STATUS'){
                wfRule.rulestatus  =   node.getText();
            }else if(node.getName()  == 'RULE_VERSION' && node.getText() != null && node.getText() != 'null'){
            	 wfRule.ruleversion   = integer.valueOf(node.getText());
            }else if(node.getName() == 'ORDER' && node.getText() != null && node.getText() != 'null'){
                wfRule.orderRule    =   integer.valueOf(node.getText());
            }else if(node.getName() == 'EVALUATION_RULE'){
                wfRule.evaluationRule   =   node.getText();
            }else if(node.getName() == 'EXECUTION_BEHAVIOR'){
                wfRule.executionBehavior    =   node.getText();
            }else if(node.getName() == 'DISPLAYFILTERLOGIC'){
                wfRule.ruleCriteria =   charsToescapechars(node.getText());
            }else if(node.getName() == 'FILTER_LOGIC'){
                wfRule.filterLogic  =   node.getText();
            }
            
            
            /*----- CRITERIA SECTION-------------*/
            else if(node.getName() == 'CRITERIA'){
                auxCriteria         =   new AW_ParseXML_Criteria_Helper();
                wfRule.criterias.add(auxCriteria);
            }else if(node.getName() == 'CRITERIA_FIELD_NAME'){
                auxCriteria.criteriaName    =   node.getText();
            }else if(node.getName() == 'CRITERIA_FIELD_API_NAME'){
                auxCriteria.criteriafieldapiname    =   node.getText();
            }else if(node.getName() == 'CRITERIA_FIELD_TYPE'){
                auxCriteria.critetriafieldtype  =   node.getText();
            }else if(node.getName() == 'CrossFormula'){
                auxCriteria.crossFormula    =   node.getText();
            }else if(node.getName() == 'MATCHING_TYPE'){
                auxCriteria.matchingType    =   node.getText();
            }else if(node.getName() == 'MATCHING_VALUE'){
                auxCriteria.matchingValue1  =   charsToescapechars(node.getText());
               
            }else if(node.getName() == 'MAXIMUM_VALUE'){
                auxCriteria.maximumValue    =   node.getText();
            }else if(node.getName() == 'MINIMUM_VALUE'){
                auxCriteria.minimumValue    =   node.getText();
            }else if(node.getName() == 'RELATED_OBJECT_CRITERIA'){
                auxCriteria.criteriarelatedObject   =   node.getText();
            }    
            else if(node.getName() == 'RECORDTYPEID'){ 
                  auxCriteria.recordtypeid =   charsToescapechars(node.getText());
             }  
            
            /*---- ACTION SECTION ----------------*/
            else if(node.getName() == 'ACTION'){
                auxAction       =       new AW_ParseXML_Action_Helper();
                wfRule.actions.add(auxAction);
            }else if(node.getName() == 'RELATED_OBJECT_ACTION'){
                auxAction.actionrelatedObject = node.getText();
            }else if(node.getName() == 'ACTION_TYPE'){
                auxAction.typeAction = node.getText();
            }else if(node.getName() == 'ACTION_FIELD_NAME'){
                auxAction.actionfieldName = node.getText();
            }else if(node.getName() == 'ACTION_FIELD_API_NAME'){
                auxAction.actionfieldAPIName = node.getText();
            }else if(node.getName() == 'VALUE_FOR_UPDATE'){
                auxAction.actionvalue = node.getText();
                checkReferenceField(auxAction);
            }else if(node.getName() == 'LONG_VALUE'){
                auxAction.actionlongValue = node.getText();
            }else if(node.getName() == 'NOTIFY_USER'){
                auxAction.actionnotifyUser = node.getText();
            }else if(node.getName() == 'ACTION_FIELD_TYPE'){
                auxAction.actionfield_Type = node.getText();
            }else if(node.getName() == 'REFERENCE_ID'){
                auxAction.actionReference_Id = node.getText();
            }else if(node.getName() == 'CROSSOBJECTFIELD'){
                auxAction.actionCrossObjectField = node.getText();
            }else if(node.getName() == 'ACTION_USER_OWNER'){
                auxAction.actionUser_Owner = node.getText();
            }else if(node.getName() == 'EMAIL_TEMPLATE'){
                auxAction.actionemailTemplate_ID = node.getText();
            }else if(node.getName() == 'EMAIL_TEMPLATE_NAME'){
                auxAction.actionEmailTemplateName = node.getText();
                if(auxAction.actionEmailTemplateName != null){
            		populateReferenceMap(auxAction.actionEmailTemplateName , 'EmailTemplate'); // Appirio JDC
            	}
            }else if(node.getName() == 'ADDITIONAL_EMAILS'){
                auxAction.actionAdditionalEmails = node.getText();    
   			}else if(node.getName() == 'APEX_JOB_CLASS'){
                auxAction.actionApexJobClass = node.getText();    
 		    }else if(node.getName() == 'CALLOUT_ACTION'){
                auxAction.actionCallOutAction = node.getText();    
   			}else if(node.getName() == 'CALLOUT_METHOD'){
                auxAction.actionCalloutMethod = node.getText();    
		    }else if(node.getName() == 'CALLOUT_TIMEOUT'){
                auxAction.actionCallOutTimeOut = node.getText();    
    		}else if(node.getName() == 'LOOKUP_WHERE_FIELDS'){
                auxAction.actionLookupWhereFields = node.getText();    
     		}else if(node.getName() == 'END_POINT'){
                auxAction.actionEndPoint = node.getText();    
    		}else if(node.getName() == 'ENDPOINT_URL'){
                auxAction.actionEndpointURL = node.getText();    
    		}else if(node.getName() == 'INPUT_PARAMETERS'){
                auxAction.actionInputParameters = node.getText();    
  			}else if(node.getName() == 'LOOKUP_FIELD_API_NAME'){
                auxAction.actionLookupFieldAPIName = node.getText();    
    		}else if(node.getName() == 'LOOKUP_FIELD_NAME'){
                auxAction.actionLookupFieldName = node.getText();    
     		}else if(node.getName() == 'LOOKUP_OBJECT'){
                auxAction.actionLookupObject = node.getText();    
		    }else if(node.getName() == 'OUTPUT_PARAMETERS'){
                auxAction.actionOutputParameters = node.getText();    
            }else if(node.getName() == 'REQUEST_PARAMETER'){
                auxAction.actionRequestParameter = node.getText();    
         	}else if(node.getName() == 'RESPONSE_PARAMETER'){
                auxAction.actionResponseParameter = node.getText();    
            }else if(node.getName() == 'BULK_API'){
                auxAction.actionBulkAPI = node.getText();    
            }else if(node.getName() == 'USER_OWNER_ID'){
                auxAction.actionUserOwnerId = node.getText();    
            }else if(node.getName() == 'USER_NAME'){
            	System.debug('::auxAction.user_Name '+auxAction.user_Name);
            	auxAction.user_Name = node.getText();
            	if(auxAction.user_Name != null){
            		populateReferenceMap(auxAction.user_Name , 'User'); //Appirio JDC
            	}
            }else if(node.getName() == 'USER_GROUP'){
            	auxAction.group_Name = node.getText();
            	if(auxAction.group_Name != null){
            		populateReferenceMap(auxAction.group_Name , 'Group'); //Appirio JDC
            	}
            }
            
            /*----SECCION RELATEDOBJECT-ACTION--*/
            else if(node.getName() == 'Insert_Field'){
                auxRelatedAction    =   new AW_ParseXML_RelatedAction_Helper();
                auxAction.listaRAction.add(auxRelatedAction);
            }else if(node.getName() == 'Field_Name_Insert'){
                auxRelatedAction.fieldName = node.getText();
            }else if(node.getName() == 'Value_For_Insert'){
                auxRelatedAction.value = node.getText();
            }
            for (Dom.XMLNode child: node.getChildElements()) {
              system.debug('-->>child '+child);
              walkThrough(child);
            }
                        
        }
        
    }
    
    /* populate the reference Map */
    private static void populateReferenceMap(String refNameValue , String objectName){
    	if(!referenceFieldMap.containsKey(objectName)){
			referenceFieldMap.put(objectName, new Map<String, String>{refNameValue  => null});
		}else{
			referenceFieldMap.get(objectName).put(refNameValue , null);
		}
		System.debug(':referenceFieldMap'+referenceFieldMap);
    }
    
    private static void checkReferenceField(AW_ParseXML_Action_Helper actionWrapper){
    	System.debug('::actionWrapper'+actionWrapper);
    	if(actionWrapper.actionField_Type == 'REFERENCE' && actionWrapper.actionrelatedObject != null && actionWrapper.actionfieldAPIName != null && actionWrapper.actionvalue != null){
        	if(!referenceFieldObjectMap.containsKey(actionWrapper.actionrelatedObject +'.'+actionWrapper.actionfieldAPIName)){
        		if(!fieldsMap.containsKey(actionWrapper.actionrelatedObject) && gd.get(actionWrapper.actionrelatedObject) != null){
        			fieldsMap.put(actionWrapper.actionrelatedObject , gd.get(actionWrapper.actionrelatedObject).getDescribe().fields.getMap());
        		}
        		if(fieldsMap.containsKey(actionWrapper.actionrelatedObject) && fieldsMap.get(actionWrapper.actionrelatedObject).containsKey(actionWrapper.actionfieldAPIName)){
	        		List<Schema.Sobjecttype>  sobjTypes = fieldsMap.get(actionWrapper.actionrelatedObject).get(actionWrapper.actionfieldAPIName).getDescribe().getReferenceTo();
	        		if(!sobjTypes.isEmpty()){
	        			referenceFieldObjectMap.put(actionWrapper.actionrelatedObject +'.'+actionWrapper.actionfieldAPIName, new Set<String>());
	        			for(Schema.Sobjecttype sobjType : sobjTypes){
	            			referenceFieldObjectMap.get(actionWrapper.actionrelatedObject +'.'+actionWrapper.actionfieldAPIName).add(sobjType.getDescribe().getName());
	        			} 
	        		}
        	  }
          }
          if(referenceFieldObjectMap.containsKey(actionWrapper.actionrelatedObject +'.'+actionWrapper.actionfieldAPIName)){
        	for(String sobj : referenceFieldObjectMap.get(actionWrapper.actionrelatedObject +'.'+actionWrapper.actionfieldAPIName)){
        		populateReferenceMap(actionWrapper.actionvalue , sobj);
        	} 
         }
      } 
    }
    
    @isTest
    static void MyTest() {
        
       String xmlString = '<DVANCE_WORKFLOW>' + '\n' +
                                '<DVANCE_WORKFLOW_NAME  name="ADVANCE WORKFLOW NAME ACCOUNT 3'+datetime.now()+'">' + '\n' +
                                    '<DESCRIPTION>ACCOUNT  - Sample  Description of Advance Workflow </DESCRIPTION>' +
                                    '<OBJECT>Account</OBJECT>' +    
                                    '<ENABLED>True</ENABLED>' +
                                    '<RULE_NAME name="Account Rule NAME A 2'+datetime.now()+'">' +
                                        '<EVALUATION_RULE> Record is created or edited and did not previously meet the rule criteria</EVALUATION_RULE>' +
                                        '<EXECUTION_BEHAVIOR> excution</EXECUTION_BEHAVIOR>' +
                                        '<FILTER_LOGIC> filterLogic</FILTER_LOGIC>' +
                                        '<RULE_DESCRIPTION>DESCRIPTION FIELD SAMPLE ACOUNT RULE  WITH 1 FILTER CRITERIA ( Cross Formula )  AND 1 ACTION </RULE_DESCRIPTION>' +
                                        '<DISPLAYFILTERLOGIC>Account.CrossFormula = Inside Sales AND Account.BillingCountry  !=  USA </DISPLAYFILTERLOGIC>' +                                   
                                    '</RULE_NAME>' +                                                            
                                    '<RULE_NAME name="Account Rule NAME B 2'+datetime.now()+'">' +
                                        '<RULE_DESCRIPTION>DESCRIPTION FIELD SAMPLE ACOUNT RULE  WITH 2 FILTER CRITERIA AND 6 ACTION </RULE_DESCRIPTION>' + 
                                        '<EVALUATION_RULE> Record is created or edited and did not previously meet the rule criteria</EVALUATION_RULE>' +
                                        '<DISPLAYFILTERLOGIC>Account.CrossFormula = Inside Sales AND Account.BillingCountry  !=  USA </DISPLAYFILTERLOGIC>' +                                   
                                        '<RULE_CRITERIA_SECTION name="Account Rule NAME A 2'+datetime.now()+'">' +
                                            '<CRITERIA name="1'+datetime.now()+'">' +
                                                '<CRITERIA_FIELD_NAME>CrossFormula</CRITERIA_FIELD_NAME>' +
                                                '<CRITERIA_FIELD_API_NAME>CrossFormula</CRITERIA_FIELD_API_NAME>' +
                                                '<RELATED_OBJECT_CRITERIA>Account</RELATED_OBJECT_CRITERIA>' +
                                                '<CrossFormula>Owner.Name</CrossFormula>' +
                                                '<MATCHING_VALUE>Inside Sales</MATCHING_VALUE>' +
                                                '<MATCHING_TYPE>Equals</MATCHING_TYPE>' +
                                                '<MAXIMUM_VALUE>Maximo</MAXIMUM_VALUE>' +
                                                '<MINIMUM_VALUE>Minimo</MINIMUM_VALUE>' +
                                            '</CRITERIA>' +
                                            '<CRITERIA name="2'+datetime.now()+'">' +
                                                '<RELATED_OBJECT_CRITERIA>Account</RELATED_OBJECT_CRITERIA>' +
                                                '<CRITERIA_FIELD_NAME>BillingCountry</CRITERIA_FIELD_NAME>' +
                                                '<CRITERIA_FIELD_API_NAME>BillingCountry</CRITERIA_FIELD_API_NAME>' +
                                                '<MATCHING_VALUE>Inside Sales</MATCHING_VALUE>' +
                                                '<MATCHING_TYPE>Equals</MATCHING_TYPE>' +
                                            '</CRITERIA>' +                                     
                                        '</RULE_CRITERIA_SECTION>' +
                                        '<RULE_ACTION_SECTION name="Account Rule NAME A 2'+datetime.now()+'">' +
                                            '<ACTION name="1'+datetime.now()+'">' +
                                                '<RELATED_OBJECT_ACTION>Account</RELATED_OBJECT_ACTION>' +
                                                '<ACTION_TYPE>Update Field</ACTION_TYPE>' +
                                                '<ACTION_FIELD_NAME>Website</ACTION_FIELD_NAME>' +
                                                '<ACTION_FIELD_API_NAME>Website</ACTION_FIELD_API_NAME>' +
                                                '<VALUE_for_Update>{!Owner.Name}</VALUE_for_Update>' +
                                                '<LONG_VALUE></LONG_VALUE>' +
                                                '<NOTIFY_USER>notify</NOTIFY_USER>' +
                                                '<EMAIL_TEMPLATE>Email Template</EMAIL_TEMPLATE>' +  
                                                '<REFERENCE_ID>1233</REFERENCE_ID>' +                                               
                                                '<ACTION_USER_OWNER>1233</ACTION_USER_OWNER>' + 
                                            '</ACTION>' + 
                                            '<ACTION name="1'+datetime.now()+'">' +
                                                '<RELATED_OBJECT_ACTION>Contact</RELATED_OBJECT_ACTION>' +
                                                '<ACTION_TYPE>Update Field</ACTION_TYPE>' +
                                                '<ACTION_FIELD_NAME>Phone</ACTION_FIELD_NAME>' +
                                                '<ACTION_FIELD_API_NAME>Phone</ACTION_FIELD_API_NAME>' +
                                                '<VALUE_for_Update>Account.Fax</VALUE_for_Update>' +
                                                 '<CROSSOBJECTFIELD>Account.Fax</CROSSOBJECTFIELD>' +
                                                '<LONG_VALUE></LONG_VALUE>' +
                                                '<NOTIFY_USER>notify</NOTIFY_USER>' +
                                                '<EMAIL_TEMPLATE>Email Template</EMAIL_TEMPLATE>' +   
                                                '<EMAIL_TEMPLATE_NAME>Email Template</EMAIL_TEMPLATE_NAME>'+                                               
                                            '</ACTION>' + 
                                            
                                            '<ACTION name="2'+datetime.now()+'">' +
                                                '<ACTION_RELATED_OBJECT>Task</ACTION_RELATED_OBJECT>' +
                                                '<INSERT_RELATED_OBJECT_SECTION>' +
                                                    '<Insert_Field>1</Insert_Field>' +
                                                    '<Field_Name_Insert>Subject</Field_Name_Insert>' +
                                                    '<Value_For_Insert>Barr</Value_For_Insert>' +
                                                    '<Insert_Field>2</Insert_Field>' +
                                                    '<Field_Name_Insert>Department</Field_Name_Insert>' +
                                                    '<Value_For_Insert>Finance</Value_For_Insert>' +
                                                '</INSERT_RELATED_OBJECT_SECTION>' +                                    
                                            '</ACTION>' +                                                                       
                                        '</RULE_ACTION_SECTION>' +              
                                    '</RULE_NAME>' +                            
                                '</DVANCE_WORKFLOW_NAME>' +
                            '</DVANCE_WORKFLOW>';    
                
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf');
        insert advanceWF;
        
        AW_ParseXMLTo_AdvanceWorkflow_Util.parser(xmlString, 'test',advanceWF.Id);  
     
    }   
        



}
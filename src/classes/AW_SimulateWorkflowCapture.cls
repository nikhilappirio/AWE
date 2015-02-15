// 
// (c) 2012 Appirio, Inc.
//
//  AW_SimulateWorkflowCapture                                                    
//criteriaList
// Class for Simulation Workflow Page
//
// 17 Dec 2013     Peter Babalis     Original
// 22 Dec 2013     Peter Babalis     Misc Issues fixed from Original Version
// 24 Dec 2013     Peter Babalis     Added ability to insert fields in simulation panel
// 31 Dec 2013     Peter Babalis     Added ability to capture results from simulation
// 30 Jun 2014     Peter Babalis     Added Before/After Panel and Lookup field for records  
   
public with sharing class AW_SimulateWorkflowCapture {
 
    
    private String 						       	aweId               {get; set;}
    public String                               selectedMode                {get; set;}
    public String                               operationType               {get; set;}
    public String                               recordName                  {get; set;}
    
    
    public List<RuleCriteria>                   criteriaList                {get; set;}
    public Map<Id, List<RuleAction__c>>         ruleActionMap               {get;set;}
    public String                               selectedRule                {get; set;}
    public Boolean                              showInputBlock              {get; set;}
    public String                               toremovecounter             {get; set;}
    public List<SelectOption>                   fieldsList                  {get {
                                                                                 if (fieldsList != null) return fieldsList;
                                                                                 fieldsList = new List<SelectOption>();
                                                                                 if (!String.isBlank(workFlow.Object__c)){
                                                                                    for (Schema.sObjectField objField : Schema.getGlobalDescribe().get(workFlow.Object__c.toLowerCase()).getDescribe().fields.getMap().values()){
                                                                                        if (objField.getDescribe().getName().toLowerCase() != 'id'){
                                                                                            fieldsList.add(new SelectOption(objField.getDescribe().getName().toLowerCase(), objField.getDescribe().getLabel() ));
                                                                                        //  fieldsList.add(new SelectOption(  objField.getDescribe().getType().name(), objField.getDescribe().getName().toLowerCase() ));
                                                                                        }
                                                                                    }
                                                                                    fieldsList = selectOptionSortByLabel(fieldsList);
                                                                                 }
                                                                                 return fieldsList;
                                                                            }set;}
                                                                            
    public static sObject                       recordinput;                 
    public Sobject 								recordInputCapture {get;set;}
   
    public Map<String, ResultInfo>                 mapResultInfo {get;set;} 
    public Advance_Workflow__c workFlow{get;set;}
    
    public List<filterwrap> FilterWrapper{get;set;}
    public string parentField{set;get;}          
    public string index {get;set;}
    private Map<String, Schema.SObjectField> mapField = new map<string,Schema.SObjectField>();
    public List<SelectOption> objectFields {get;set;}
    private Map<String,Schema.SObjectType> gd;
    public List<SelectOption> recordOptions{get;set;}
    public String recKeyPrefix{get;set;}
    public Map<String, Map<Id, ResultInfoOther>> mapOtherActions{get;set;}
    public Map<String, List<ResultInfo>> childObjectFields{get;set;}
    public Map<String, Map<String, ResultInfoOther>> mapOtherObjResultInfo{get;set;}
    public String refId{get;set;}
    public String refObjectField{get;set;}
    public String ruleName {get;set;}
    public Set<String> allFields;
    private Set<String> mainfields;
    private Map<String, Map<String, Sobject>> referenceObjects;
    public Boolean isResultPanel{
    	get{
    		if(!mapResultInfo.isEmpty() || !mapOtherActions.isEmpty() || !childObjectFields.isEmpty() || !mapOtherObjResultInfo.isEmpty()){
    			return true;
    		}
    		return false;
    	}set;
    }
    public Boolean isOtherObjResultPanel{
    	get{
    		if(mapOtherObjResultInfo != null && !mapOtherObjResultInfo.isEmpty()){
    			return true;
    		}
    		return false;
    	}set; 
    }
    
    public Boolean isOtherActionResultPanel{
    	get{
    		if(mapOtherActions != null && !mapOtherActions.isEmpty()){
    			return true;
    		}
    		return false;
    	}set; 
    }
    
    /*
    *   Constructor taking standard controller as a parameter
    */
    public AW_SimulateWorkflowCapture(ApexPages.Standardcontroller controller){ 
        aweId = controller.getId();
        workFlow = [SELECT Object__c FROM Advance_Workflow__c WHERE Id=:aweId LIMIT 1];
        showInputBlock = false;
        selectedMode = 'workflow';
        criteriaList = new List<RuleCriteria>();
       	allFields = new Set<String>();
       	mainfields = new Set<String>();
        gd = Schema.getGlobalDescribe();    
        objectFields = populateField();
        recordinput = gd.get(workFlow.Object__c.toLowerCase()).newSObject();
        recordInputCapture = gd.get(workFlow.Object__c.toLowerCase()).newSObject();
        recKeyPrefix = gd.get(workFlow.Object__c.toLowerCase()).getDescribe().getKeyPrefix();
        ruleActionMap = new Map<Id, List<RuleAction__c>>(); 
        initialize();
  
     }
    
    private void initialize(){
    	recordOptions = new List<SelectOption>();
    	childObjectFields = new Map<String, List<ResultInfo>>();
        mapOtherObjResultInfo = new Map<String, Map<String, ResultInfoOther>>();
        mapResultInfo = new Map<String, ResultInfo>();
        mapOtherActions = new Map<String, Map<Id, ResultInfoOther>> ();
        isResultPanel = false;
    }
    
    /*
    *   Get all the rules for the current workflow
    *   return List<SelectOption> all the rules records
    */
    public List<SelectOption> getRules(){
        List<SelectOption>  options = new List<SelectOption>();
        List<Rule__c> rsRules = [SELECT Id,Name FROM Rule__c WHERE (Advance_Workflow__c =:aweId  AND Status__c  = 'Active') OR (Object__c = : workFlow.Object__c AND Status__c = 'Draft') ORDER BY Name LIMIT 2000];
        
        // If the object is not null
        if (!rsRules.isEmpty()){
            for (Rule__c rule : rsRules){
            	options.add(new SelectOption(rule.Id, rule.Name));
            }
        }
        return options;
    }
    
    /*
    *   Check if the workflow execution mode is selected, 
    *   if it is not selected throw the error
    *
    *   return PageReference    null
    */
    public PageReference checkSelectedMode(){
        ruleCriterias();
        //afterValue = '';
        //beforeValue = '';
        return null;
    }
    
     /*
	    *   Call When changed the mode
    */
    public PageReference changeMode(){
        return null;
    }
    
    /*
    *   Get the rule criteria records for the workflow currenly being referenced 
    *
    *   return PageReference    null
    */
    public PageReference ruleCriterias(){
    	mapResultInfo = new Map<String, ResultInfo>(); 
    	//recordInputCapture = gd.get(workFlow.Object__c.toLowerCase()).newSObject();
        criteriaList = new List<RuleCriteria>();
        String query = '';
        try{
            // Get the null values
            // Check the selected mode
            if (!String.isBlank(selectedMode) && ((!String.isBlank(operationType) || !String.isBlank(recordName)))){
                
                // Check rule is selected if and if only selected mode equals rule
                if (selectedMode == 'rule' && String.isBlank(selectedRule)){
                    showInputBlock = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Rule is required.'));
                    return null;
                }
                if(operationType == 'Create' || (recordInputCapture != null && recordInputCapture.id != null)){
                	showInputBlock = true;
                }else{
                	showInputBlock = false;
                }
                // Create a dynamic query
                query = 'SELECT Id, Name, (SELECT Id FROM Rules__r ';
                if (selectedMode == 'rule' && !String.isBlank(selectedRule)) query += 'WHERE Id=\''+selectedRule.trim()+'\' AND Status__c = \'Active\'';
                if (selectedMode == 'workflow') query += 'WHERE Status__c = \'Active\'';
                query += ') FROM Advance_Workflow__c WHERE Id=\'' + aweId + '\' LIMIT 1';
                
                // Get the workflow record with its associated Rules
                Advance_Workflow__c workFlow = Database.query(query);
                List<Rule__c> workflowRules = new List<Rule__c>();
                if(selectedMode == 'rule'){
                	workflowRules.add(new Rule__c(id = selectedRule));
                }else{
                	workflowRules.addAll(workFlow.Rules__r);
                }
                // Get the rules and rule criteria
                if (workFlow != null && !workflowRules.isEmpty()){
                    List<Rule__c> rsRules = [SELECT Id, Name, Filter_Logic__c, Object__c,(SELECT Id, Name, Related_Object__c, Maximum_Value__c, Field_API_Name__c,CrossFormula__c, Field_Type__c, Matching_Value__c, Field_Name__c,
                                                                    Minimum_Value__c, Matching_Type__c FROM Rule_Criteria__r WHERE Field_Name__c != 'Name' AND Field_Name__c != 'Id' AND Field_API_Name__c != 'Name' 
                                                                    AND Field_API_Name__c != 'Id'), (Select id , Field_API_Name__c ,User_Owner_Id__c,Additional_Emails__c,Email_Template_Folder__c,EmailTemplateName__c,Action_Label__c,Input_Parameters__c,Apex_Job_Class__c,Output_Parameters__c, Related_Object__c, Value__c, Type__c, Reference_Id__c, Long_Value__c,CrossObjectField__c from  Rule_Actions__r ) FROM Rule__c WHERE Id in: workflowRules];
                    for (Integer i=0;i<rsRules.size();i++){
                        // Get the Rule IDs
                        System.debug('::rsRules[i].Rule_Criteria__r'+rsRules[i].Rule_Criteria__r);
                        List<RuleCriteria__c> ruleCriteriaList = new List<RuleCriteria__c>();
                        // Check rule criuteria to remove the duplicate fields
                        for (RuleCriteria__c ruleCriteria : rsRules[i].Rule_Criteria__r){
                            if (!String.isBlank(ruleCriteria.Field_Name__c) && ruleCriteria.Field_Name__c.toLowerCase() != 'id' && ruleCriteria.Field_Name__c.toLowerCase() != 'name'){
                                ruleCriteriaList.add(AW_FormulaExpressionHelper.resolveCriteriaFormulaExpressions(ruleCriteria));
                            }
                            if (rsRules[i].Object__c == ruleCriteria.Related_Object__c && !String.isBlank(ruleCriteria.Field_Name__c) && ruleCriteria.Field_Name__c != 'CrossFormula' && !ruleCriteria.Field_Name__c.containsIgnoreCase('globalvariable')) {
                   				System.debug('::rule Criteria fields'+ruleCriteria.Field_Name__c);
                   				mainFields.add(ruleCriteria.Field_Name__c.trim().toLowerCase());
                			}
			                if(rsRules[i].Object__c == ruleCriteria.Related_Object__c && ruleCriteria.Field_Name__c == 'CrossFormula' && !String.isBlank(ruleCriteria.CrossFormula__c)){
			                	System.debug('::rule Criteria Related_Object__c'+ruleCriteria.CrossFormula__c);
                   				mainFields.add(ruleCriteria.CrossFormula__c.toLowerCase());
			                }
                        }
                        criteriaList.add(new RuleCriteria(rsRules[i], ruleCriteriaList,i+1));
                         System.debug('::rsRules[i].Rule_Actions__r'+rsRules[i].Rule_Actions__r);
                        for (RuleAction__c action : rsRules[i].Rule_Actions__r){
                        	System.debug('::action'+action);
                        	if(action.Type__c == 'Update Field'){
				                if (rsRules[i].Object__c == action.Related_Object__c && (!String.isBlank(action.Field_API_Name__c) && action.Field_API_Name__c != AW_Rule_Constants.CROSSOBJECT  &&
				    				action.Field_API_Name__c != AW_Rule_Constants.LOOKUPOBJECTFIELD && action.Field_API_Name__c != AW_Rule_Constants.OWNERPRIORITIZATION )){
				                     System.debug('::rule action  Field'+action.Field_API_Name__c);
				                     mainFields.add(action.Field_API_Name__c.replace('{','').replace('}','').toLowerCase()); 
				               	}
				               	if (rsRules[i].Object__c == action.Related_Object__c && action.Field_API_Name__c == AW_Rule_Constants.CROSSOBJECT && !String.isBlank(action.CrossObjectField__c)){
				                     System.debug('::rule action  Field 1'+action.CrossObjectField__c);
				                     mainFields.add(action.CrossObjectField__c.replace('{','').replace('}','').toLowerCase());
				               	}
				               	if (rsRules[i].Object__c == action.Related_Object__c && action.Field_API_Name__c == AW_Rule_Constants.OWNERPRIORITIZATION){
				                     mainFields.add('ownerid');
				               	}
                        	}
            			}
                        ruleActionMap.put(rsRules[i].id , rsRules[i].Rule_Actions__r);
                    }
                      
                }
            } 
            FilterWrapper = new list<filterwrap>();
            Set<String> duplicateFields = new Set<String>();
            if(selectedMode == 'workflow'){
                selectedRule = !criteriaList.isEmpty() ? criteriaList.get(0).rule.Id : selectedRule;
                System.debug('::selectedRule Criteria'+selectedRule);
            }
            for (RuleCriteria rule : criteriaList){
                for (Criteria criteria : rule.ruleCriteriaList){   
                	if(!duplicateFields.contains(criteria.ruleCriteria.Field_Name__c) && criteria.ruleCriteria.Field_Name__c != null && criteria.ruleCriteria.Field_Name__c != AW_Rule_Constants.CROSSFORMULA &&  !criteria.ruleCriteria.Field_API_Name__c.trim().contains(AW_Rule_Constants.GLOBAL_VARIABLE)){                 
	                    filterwrap objfilterwrap= new filterwrap(FilterWrapper.size() + 1);
	                    objfilterwrap.Field_Name = criteria.ruleCriteria.Field_Name__c;
	                    objfilterwrap.field_type = criteria.ruleCriteria.Field_Type__c;
	                    FilterWrapper.add(objfilterwrap);
	                    index = String.ValueOf(FilterWrapper.size() - 1);
	                    parentField=  criteria.ruleCriteria.Field_Name__c;
	                    duplicateFields.add(criteria.ruleCriteria.Field_Name__c);
                	}
                    populateOperator();
                }  
            }        
            
            system.debug('-------------- criteriaList-----------------'+criteriaList);
            system.debug('-------------- FilterWrapper-----------------'+FilterWrapper);
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
        }
        return null;
    }
    
    public void populateOperator(){
	    Schema.SObjectType sobjTypeParent = gd.get(workflow.object__c);
	     Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
	     mapField = parentObjFields.fields.getMap();
	     System.debug('::index'+index);
	     if(index != null && index.contains(':')){
		     index=index.substringBeforeLast(':');
		     index=index.substringAfterLast(':');    
	     }     
        system.debug('----------- index---------------------'+index);
        system.debug('----------- parentField---------------------'+parentField);
            if(index=='' || index==null || parentField=='' || parentField==null )
                return;
        		system.debug('----------- parentField---------------------'+parentField);
                Integer listindex = integer.Valueof(index);
                if((mapField.get(parentField))==null && !parentField.equalsIgnoreCase('OwnerName')){
               	   system.debug('----------- mapField---------------------'+mapField);
                   return;
               }
               if(FilterWrapper.size() <=  listindex){
               		return;
               }
               FilterWrapper.get(listindex).Field_Name=parentField;  
               if(mapField.get(parentField) != null){
               		Schema.DescribeFieldResult fieldResult = mapField.get(parentField).getDescribe();
               		System.debug('::fieldResult'+fieldResult);
               		if(fieldResult.isCreateable() == false && fieldResult.isUpdateable() == false){
               			FilterWrapper.get(listindex).isEditable = false;
               		}else{
               			FilterWrapper.get(listindex).isEditable = true;
               		}
               		FilterWrapper.get(listindex).field_type = string.valueof(fieldResult.getType());
               	}else{
               		FilterWrapper.get(listindex).isEditable = false;
             		FilterWrapper.get(listindex).field_type = 'String';
               	} 
               	system.debug('----------- parentField'+parentField);   
               	mainFields.add(parentField.toLowerCase());            
               system.debug('----------- FilterWrapper.get(listindex)'+FilterWrapper.get(listindex));                 
    			
        //}//end operators
      }
      
      public PageReference populateReferenceFields(){
      	System.debug('::refId::'+refId);	
      	System.debug('::refObjectField::'+refObjectField);
      	if(refId != null && refObjectField != null){
      		String refObjectName = getRelatedFieldDescribe(Workflow.object__c , refObjectField);
      		String relationShipFieldAPI = refObjectField.endsWith('__c') ? refObjectField.replace('__c' , '__r').toLowerCase() : (refObjectField.endsWith('id') ? refObjectField.replace('id' , '').toLowerCase() : '');
      		Set<String> refFieldSet = new Set<String>();
      		if(relationShipFieldAPI != ''){
      			for(String mainfd : mainFields){
      				System.debug('::mainfd'+mainfd);
      				if(mainfd.contains(relationShipFieldAPI+'.')){
      					refFieldSet.add(mainfd.replaceFirst(relationShipFieldAPI+'\\.' , '').toLowerCase());
      				}
      			}
      			if(!refFieldSet.contains('id')){
      				refFieldSet.add('id');
      			}
      			String refFields = joinListToString(refFieldSet, ',');
      			String soqlQuery = 'select '+refFields + ' FROM ' + refObjectName + ' WHERE id = : refId';
      			System.debug('::soqlQuery'+soqlQuery);	
      			For(Sobject sobj : Database.query(soqlQuery)){
      				recordInputCapture.putSobject(relationShipFieldAPI , sobj);
      			}
      			System.debug('::recordInputCapture.getSobject(relationShipFieldAPI)::'+recordInputCapture.getSobject(relationShipFieldAPI));	
      		}
      		
      	}
      	return null;
      }
    
    private String getRelatedFieldDescribe(String objectName, String fieldName){
    	System.debug(':::mapField'+mapField);
    	System.debug(':::fieldName'+fieldName);
    	System.debug(':::objectName'+objectName);
			Schema.DescribeFieldResult fieldDescribe = mapField.get(fieldName).getDescribe();
			if(fieldDescribe != null && fieldDescribe.getType() == Schema.Displaytype.REFERENCE){
				return  fieldDescribe.getReferenceTo()[0].getDescribe().getName();
			}
			return  null;
		}
		
		 public List<SelectOption> getRecordTypeOptions(String sObjName){
            List<SelectOption> options = new List<SelectOption>();
            for(RecordType recType : [select id, name from RecordType where SobjectType =: sObjName ]){
                options.add(new SelectOption(recType.Id,recType.Name));
                //mapRectypeIdRecName.put(recType.Id,recType.Name);
            }
            return options;
        }
		private static list<SelectOption> getPicklistValues(sObjectType objtyp, String fld)
       {
              list<SelectOption> opt = new list<SelectOption>();
              
              Schema.DescribeSObjectResult objDescrib = objTyp.getDescribe();       
              map<String, Schema.SObjectField> fieldMaps = objDescrib.fields.getMap(); 
              list<Schema.PicklistEntry> values = fieldMaps.get(fld).getDescribe().getPickListValues();
              for (Schema.PicklistEntry a : values)
              { 
                opt.add(new SelectOption(a.getLabel(), a.getValue())); 
              }
              return opt;
        } 
        
        private List<SelectOption> populateField(){
         	 String parent = workflow.object__c;       	  
             List<SelectOption> fieldOption= new List<SelectOption>();
            
             Schema.SObjectType sobjTypeParent = gd.get(parent);
            
             Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
             mapField = parentObjFields.fields.getMap();
             fieldOption.add(new SelectOption('','--Select--'));
             
             for(String fieldname:mapField.keySet()){
                Schema.SObjectField sfield = mapField.get(fieldname);
                Schema.DescribeFieldResult descResField = sfield.getDescribe();
                String fieldLabel = descResField.getLabel();
                //fieldOption.add(new SelectOption(descResField.getName(),fieldLabel));
                String fieldAPIName = descResField.getName();
                if(fieldAPIName.equalsIgnoreCase('RecordTypeID')){
                    fieldOption.add(new SelectOption('Record Type Name',fieldAPIName));
                }
                // Owner name change
                // Start
            	else if(fieldAPIName.equalsIgnoreCase('ownerid')){
            		fieldOption.add(new SelectOption('Owner Name','OwnerName'));
            		fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
            	}
                else{
                    fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                }
                System.debug('::field options '+fieldAPIName);
                allFields.add(fieldAPIName.toLowerCase());
                // End
                
                //to add field types
                
               // Fieldtypemap.put(descResField.getName(),string.valueof(sfield.getDescribe().gettype()));
            }
            
            if(parent!=null)
            	fieldOption.SORT();
            
            List<SelectOption> sortedfieldOption= new List<SelectOption>();
            for(SelectOption opt : fieldOption){
               sortedfieldOption.add(new SelectOption(opt.getLabel(),opt.getValue())); 
            }
            system.debug('------------------ sortedfieldOption ---------------------'+sortedfieldOption);
            return sortedfieldOption;
            //FilterWrapper.get(pos).fieldOptions.addall(sortedfieldOption);
        }
       public void addmorefilter(){
       		filterwrap objfilterwrap=new filterwrap();
       		FilterWrapper.add(objfilterwrap);  
            system.debug('------------------ FilterWrapper.size ---------------------'+FilterWrapper.size());
        }
        
        public void deletefilter(){
            if(toremovecounter != null && toremovecounter != ''){
            	Integer counterVal = Integer.valueOf(toremovecounter);
            	System.debug('::toremovecounter'+counterVal +'::FilterWrapper'+FilterWrapper);
            	if((counterVal - 2) < FilterWrapper.size() && counterVal >= 2 ){
            		FilterWrapper.remove(counterVal - 2);
            	}
            }
        }
         
    /*
    *   Create a filter based on the recordNames
    *
    *   return String   filter based on the recordNames
    */
    private String  filterQuery(){
        String filterQuery = '';
        // Check if the recordName is empty
        system.debug('----------------------------- recordName---------------------------'+recordName);
        if (!String.isBlank(recordName)){
            List<String> recordNames = recordName.split(',');
            for (String rName : recordNames){
                filterQuery += (filterQuery == '' ? 'Name LIKE \'%'+ String.escapeSingleQuotes(rName) +'%\'' : ' OR Name LIKE \'%'+ String.escapeSingleQuotes(rName) +'%\'');
            }
        }
        return filterQuery;
    }
    
    
    public PageReference populateFields(){
    	initialize();
        System.debug('::allFields'+allFields.contains('RegionLookUp__c'));
        System.debug('::allFields'+mainFields.contains('RegionLookup__c'));
        String mainField = workflow.Object__c == 'Case' ? 'CaseNumber': 'Name';
        String recId = recordInputCapture.get('Id') != null ? (Id) recordInputCapture.get('Id') : '' ;
        recordName = recordInputCapture.get(mainField) != null && ((String)recordInputCapture.get(mainField)).trim() != '' ? (String)recordInputCapture.get(mainField) +'%' : '';
        allFields.addAll(mainFields);
        string ForQuery = joinListToString(allFields , ',').replace('{','').replace('}','');
        if(workflow.Object__c != 'Case' && !allFields.contains('name')){
       	 	forQuery += ', name '; 
        }else if(workflow.object__c == 'Case' && !allFields.contains('casenumber')){
        	forQuery += ', casenumber '; 	
        } 
		if(!allFields.contains('id')){
			forQuery += ',id ';
		}
        String s = 'SELECT '+ ForQuery +' FROM '+workFlow.Object__c;
	    if(recordInputCapture.get('Id') != null && recordInputCapture.get('Id') != ''){
	    	s += ' Where id = : recId ';
	    }else if(recordName != ''){
	       s += ' Where '+ mainField +' like : recordName ';
	       
	    }
	    system.debug('-->query  '+s);
	    //  Get the before values 
	    if(s.contains(' Where ')){
		    
		    List<Sobject> sobjects = Database.query(s);
		    if(sobjects.size() == 0){
		    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Record found'));
		        return null;
		    }
		    if(sobjects.size() > 1){
		    	for(Sobject sobj : sobjects){
		    		recordOptions.add(new SelectOption((String)sobj.get('id'), (String)sobj.get(mainField)));
		    	}
		    	 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'There are more than one Matching records'));
		    	 return null;
		    }
		    for(SObject sobj : sobjects){
	    		recordInputCapture = sobj;
	        }
	        showInputBlock = true; 
	        ruleCriterias();
	         
	    }else{
	    	showInputBlock = false;
	    }
        return null;
    }
    
    public PageReference simulateWorkflow(){
        Boolean hasError = false;
        Sobject beforeRecord;
        Map<Id, Sobject> recordBefore = new Map<Id, Sobject>();
        recordOptions = new List<SelectOption>();
        String errorMsg = '';
        Set<Id> recordIds  = new Set<Id>();
        String afterValue;
        //Map<Id,SObject>  recordAfter;
       // beforeValue = '';
        //afterValue = '';
        mapResultInfo = new Map<String, ResultInfo>();
        AW_SimulationExecution.lstSObjectforUpdateSimulation = null;
        Savepoint sp = Database.setSavepoint();
        String mainField = workflow.Object__c == 'Case' ? 'CaseNumber': 'Name';
        try{
            // Check operation type is selected
            if (String.isBlank(operationType)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Select either create record or update record option.'));
                hasError = true;
            }            
            if ((recordInputCapture.get(mainField) == null ||  recordInputCapture.get(mainField) == '') && operationType == 'update'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Atleast one record Name is required.'));
                hasError = true;
            }
            if (!String.isBlank(errorMsg)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Found duplicate fields in the field Section : '+errorMsg));
                hasError = true;
            }
            if (hasError) return null;

            // Simulation for Record Update

            if (recordInputCapture.get(mainField) != null && operationType == 'update' && !String.isBlank(workFlow.Object__c)){
                    System.debug('::recordInputCapture.getID'+recordInputCapture.get('Id'));
                    //system.debug('-->getFieldNames '+getFieldNames());
                    String recId = recordInputCapture.get('Id') != null ? (Id) recordInputCapture.get('Id') : '' ;
                    recordName = recordInputCapture.get(mainField) != null && ((String)recordInputCapture.get(mainField)).trim() != '' ? (String)recordInputCapture.get(mainField) +'%' : '';
                    string ForQuery = joinListToString(allFields , ',').replace('{','').replace('}','');
			        if(workflow.Object__c != 'Case' && !allFields.contains('name')){
			        	forQuery += ', name '; 
			        }else if(workflow.object__c == 'Case' && !allFields.contains('casenumber')){
			        	forQuery += ', casenumber '; 	
			        } 
					if(!allFields.contains('id')){
						forQuery += ',id ';
					}
			        String s = 'SELECT '+ ForQuery +' FROM '+workFlow.Object__c;
                    if(recordInputCapture.get('Id') != null && recordInputCapture.get('Id') != ''){
                    	s += ' Where id = : recId ';
                    }
                    system.debug('-->query  '+s);
                    //  Get the before values 
                    recordBefore = new Map<Id,SObject>(Database.query(s));
                    if(recordBefore.size() == 0){
                    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Record found'));
                        return null;
                    }
                    //recordAfter = new Map<Id,SObject>();
					//recordAfter.putAll(recordBefore);
					recordIds.addAll(recordBefore.keySet());
					beforeRecord = recordBefore.values().get(0).clone();
					system.debug('------>beforeRecord '+beforeRecord); 
                    list<sObject> listLead = recordBefore.values();
                    sObject oldSobj = listLead.get(0);
                    if(recordInputCapture.get('Id') == null || recordInputCapture.get('Id') == ''){
                    	recordInputCapture.put('Id', oldSobj.id);
                    }
                    system.debug('-->recordBefore  '+recordBefore);
                    // Get the records to be updated values 
                    // Remove Id 
                     //beforeValue = removeIdFromRecord(String.valueOf(recordBefore));
                     system.debug('-->listLead  '+listLead);
                     system.debug('-->oldSobj  '+oldSobj);
                     //system.debug('-->beforeValue  '+beforeValue);
                 	 system.debug('-->beforeRecord  '+beforeRecord);
                 	 system.debug('-->recordinput  '+recordinput);
                 	 system.debug('-->recordInputCapture  '+recordInputCapture);
                 	 system.debug('-->recordBefore  '+recordBefore);
                	////   Get the AFTER values
                
                    recordinput = oldSobj ;//new Sobject(oldSobj);
                    system.debug('-->recordinput1  '+recordinput +'::FilterWrapper'+FilterWrapper);
                    for(filterwrap objfilterwrap:FilterWrapper){
                    	System.debug('::objfilterwrap'+objfilterwrap);
                        if(objfilterwrap.field_Name != null && objfilterwrap.isEditable == true){
                            recordinput.put(objfilterwrap.field_Name , recordInputCapture.get(objfilterwrap.field_Name));
                            if(objfilterwrap.field_type == 'REFERENCE' && recordInputCapture.get(objfilterwrap.field_Name) != null && objfilterwrap.field_Name != 'RecordTypeId'){
                                String relationShipFieldAPI = objfilterwrap.field_Name.endsWithIgnoreCase('__c') ? objfilterwrap.field_Name.replaceFirst('__c' , '__r').toLowerCase() : (objfilterwrap.field_Name.endsWithIgnoreCase('Id') ? objfilterwrap.field_Name.replace('Id' , '').toLowerCase() : objfilterwrap.field_Name);
                                recordinput.putSobject(relationShipFieldAPI, recordInputCapture.getSobject(relationShipFieldAPI));
                                System.debug('::record input rel '+recordinput.get(objfilterwrap.field_Name));
                            }
                        }
                    }
                
                AW_AdvanceWorkflowExecutionEngine.oldListMap = new Map<Id , Sobject>();
                AW_AdvanceWorkflowExecutionEngine.oldListMap.put((Id)recordBefore.values().get(0).get('id') , beforeRecord);
                }else if(operationType == 'create'){
                	AW_AdvanceWorkflowExecutionEngine.oldListMap = new Map<Id, Sobject>();
                	recordinput = Schema.getGlobalDescribe().get(workFlow.Object__c).newsObject();
        			 system.debug('-->recordinput1  '+recordinput);
        			for(filterwrap objfilterwrap:FilterWrapper){ 
                        if(objfilterwrap.isEditable == true){
                            recordinput.put(objfilterwrap.field_Name , recordInputCapture.get(objfilterwrap.field_Name));
                        }
                        if(objfilterwrap.field_type == 'REFERENCE' && recordInputCapture.get(objfilterwrap.field_Name) != null && objfilterwrap.field_Name != 'RecordTypeId'){
                            String relationShipFieldAPI = objfilterwrap.field_Name.endsWithIgnoreCase('__c') ? objfilterwrap.field_Name.replaceFirst('__c' , '__r').toLowerCase() : (objfilterwrap.field_Name.endsWithIgnoreCase('Id') ? objfilterwrap.field_Name.replace('Id' , '').toLowerCase() : objfilterwrap.field_Name);
                            recordinput.putSobject(relationShipFieldAPI, recordInputCapture.getSobject(relationShipFieldAPI));
                            System.debug('::record input rel '+recordinput.get(objfilterwrap.field_Name));
                        }
                    }
        			beforeRecord =  recordInputCapture.clone();  
		     				    
		 		 } 
                //}
            system.debug('------>calling engine recordBefore'+recordBefore);
            system.debug('------>recordinput after wrapper fields '+recordinput) ; 
            system.debug('------>calling engine AW_AdvanceWorkflowExecutionEngine.oldListMap'+AW_AdvanceWorkflowExecutionEngine.oldListMap);
            system.debug('------>calling engine workFlow.Object__c'+workFlow.Object__c);
           // recordinput.put( 'firstname', 'Lalitsfs');
             ////   INITIATE SIMULATION
              
             system.debug('------>beforeRecord before simulation '+beforeRecord);
             //  AW_AdvanceWorkflowExecutionEngine.evaluateRules(workflowrules,recordIds,workFlow.Object__c,'Simulation');
            if(selectedMode == 'workflow'){
            	selectedRule = criteriaList.get(0).rule.Id;
            	AW_AdvanceWorkflowExecutionEngine.startRulesProcessingOnSimulation(recordIds,workFlow.Object__c,(operationType == 'create'),'Simulation');
            }else if(selectedMode == 'rule' && selectedRule != null){
            	for(Rule__c rule : [select id , Name , Advance_Workflow__c ,Advance_Workflow__r.Name, Advance_Workflow__r.Advance_Rule_Stamp__c from Rule__c where id  = : selectedRule limit 1]){
            		AW_AdvanceWorkflowExecutionEngine.advWorkflow = rule.Advance_Workflow__r;
            	} 
            	AW_AdvanceWorkflowExecutionEngine.bulkOperation = false;
            	AW_AdvanceWorkflowExecutionEngine.evaluateRules(new Set<Id> {selectedRule} , recordIds , workflow.Object__c , 'Simulation');
            }
                 
            system.debug('-->output lstSObjectforUpdateSimulation '+AW_SimulationExecution.lstSObjectforUpdateSimulation);
               if  ( String.valueOf(AW_SimulationExecution.lstSObjectforUpdateSimulation) <> null &&  AW_SimulationExecution.lstSObjectforUpdateSimulation.size() > 0) {
                     afterValue = String.valueOf(AW_SimulationExecution.lstSObjectforUpdateSimulation).replace('null','');
                 }
               else if  ( String.valueOf(AW_SimulationExecution.SimulationInvalidCriteriaMessage) <> null ) {
                    afterValue =  AW_SimulationExecution.SimulationInvalidCriteriaMessage;
                }
                //lstSObjectforUpdateSimulation 
            //system.debug('------>beforeValue '+beforeValue);    
            system.debug('------>afterValue '+afterValue);   
            if(afterValue == null || afterValue == ''  ||  afterValue == 'Record did not meet the criteria'){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Record did not meet the criteria'));
            	return null;
            }
            system.debug('------>beforeRecord after simulation '+beforeRecord);
            resultInfo objresultInfo = new resultInfo();  
            mapResultInfo = getResultGrid(AW_SimulationExecution.lstSObjectforUpdateSimulation, beforeRecord); 
                         
            if(operationType == 'create'){
            	Database.rollback(sp);
            } 
     }
         catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
        }
        return null;
    }
    
    
 
 public static  SObject InputRecord(Map<Id,SObject> recdBefore, Advance_Workflow__c advworkflow, List<ObjectFields> additonalFields) {
   //List<SObject> record;
   // SObject   record;
    String RecVal='' ;
    string recId='';
    List<String> listParamValues ;
    
    sObject sobj = Schema.getGlobalDescribe().get(advworkFlow.Object__c).newsObject();
    
    system.debug('->recdBefore  '+recdBefore);
    system.debug('->additonalFields  '+additonalFields);
    
    for (String fieldName : recdBefore.keySet()){
      system.debug('recdBefore.get(fieldName) '+ recdBefore.get(fieldName) +' - '+fieldName);
     recId=fieldName;
     RecVal=  String.valueOf(recdBefore.get(fieldName));
       }
    // Get the additional fields 
    if (!additonalFields.isEmpty()){
      for (ObjectFields objField : additonalFields){
        if (( RecVal.toLowerCase().contains(objField.selectedField )) && (!RecVal.toLowerCase().contains(objField.selectedField+'='+objField.searchValue) )) {
                 integer startpos=RecVal.toLowerCase().indexOf(objField.selectedField, 0);
                 string RecVal_srting1 =RecVal.substring(0, startpos);
                 integer endpos=RecVal.indexOf(',', startpos);
                 string RecVal_srting2=RecVal.substring(endpos);
                 
                 system.debug('startpos '+startpos);
                 system.debug('RecVal_srting1 '+RecVal_srting1);
                 system.debug('startpos '+startpos);
                 system.debug('RecVal_srting2 '+RecVal_srting2);
                 
                 RecVal='';
                 RecVal=RecVal_srting1+objField.selectedField+'='+objField.searchValue+RecVal_srting2;
                 system.debug('--->RecVal 2  '+RecVal);
                             
            }             
     }  
    listParamValues=RecVal.split(',', 0); 
    for(Integer a = 0; a < listParamValues.size(); a++){
       List<String> fieldvalues=listParamValues[a].split('=');         
          system.debug('--->fieldvalue 2  '+fieldvalues[0] + '  - ' +fieldvalues[1]);         
          
      string fieldAPIName=fieldvalues[0];
      string fieldvalue=fieldvalues[1];
      String fieldval='';
      String fieldAPI='';
      
      if (fieldvalue.contains('}') )
      {
        fieldval=fieldvalue.substring(0, fieldvalue.indexOf('}'));
       } else fieldval= fieldvalue;
      system.debug('---->fieldval '+fieldval);
      if (fieldAPIName.contains('{') )
      {
       
      system.debug('----->fieldAPIName '+fieldAPIName.substring(1+fieldAPIName.indexOf('{')));
      fieldAPI= fieldAPIName.substring(1+fieldAPIName.indexOf('{'));
      } else fieldAPI= fieldAPIName;
      system.debug('------>fieldAPI '+fieldAPI+'|');
       
       String trimfieldAPI= fieldAPI.trim();
       String trimfieldval= fieldval.trim();
      if  (fieldAPI.contains('annualrevenue')) {
        system.debug('------> if fieldAPI '+fieldAPI);
      }
      else   sobj.put(trimfieldAPI ,trimfieldval);
      
                                      
     }
                                 
    }
    //record=sobj;
    //return  record;
     system.debug('------>SOBJ '+sobj);
     return  sobj;
     
    }
    
      // Remove Id 
    /*
    * @description : takes an Sobject includin its ID as input 
    * @return  removes the Id valie from the Sobject 
    */
     public static String removeIdFromRecord( String recordWithId){
       string recordWithNoId;
       if (!String.isBlank(recordWithId)){
           List<String> recordValues = recordWithId.split(',');
               for (String value : recordValues){
                   if (!value.contains('Id=')){
                     // beforeValue += (beforeValue == '' ? value.replace('null','') : ','+value.replace('null',''));
                     recordWithNoId += (recordWithNoId == '' ? value.replace('null','') : ','+value.replace('null',''));
                    }
                }
        }
    return recordWithNoId;
}               
    /*
    * @description : Sort the select options by its label  
    * @return List<SelectOption>  sorted selected options by its label
    */
    public static List<selectOption> selectOptionSortByLabel(List<selectOption> selectOptionsToSort) {
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
        
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getLabel() <= pivotValue.getLabel()){
                lessSelectOption.add(SO);
            }else if(SO.getLabel() > pivotValue.getLabel()){
                greaterSelectOption.add(SO);   
            }
        }
        List<selectOption> sortedSelectOptions = new List<selectOption>(); 
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return SortedSelectOptions;
    }
    
    
    /*
    *   Wrapper Class for rule 
    */
    public class RuleCriteria{
        public Rule__c                  rule                {get; set;}
        public List<Criteria>           ruleCriteriaList    {get; set;}
        public Integer                  counter             {get; set;}
        
        public RuleCriteria(Rule__c rule, List<RuleCriteria__c> ruleCriterias, Integer counter){
            ruleCriteriaList = new List<Criteria>();
            this.rule = rule;
            this.counter = counter;
            for (RuleCriteria__c criteria : ruleCriterias){
                ruleCriteriaList.add(new Criteria(criteria));
            }
        }
    } 
    
    /*
    *   Wrapper Class for criteria
    */
    public class Criteria{
        public RuleCriteria__c      ruleCriteria        {get; set;}
        public String               fieldName           {get; set;}
        public String               matchingFromValue   {get; set;}
        public String               matchingToValue     {get; set;}
        
        public Criteria(RuleCriteria__c ruleCriteria){
            this.ruleCriteria = ruleCriteria;
            this.fieldName = (!String.isBlank(ruleCriteria.Field_Name__c) ? ruleCriteria.Field_Name__c.toLowerCase().trim() : '');
            this.matchingFromValue = '';
            this.matchingToValue = '';
        }
    }
    
    /*
    *   Wrapper Class for more fields
    */
    public class ObjectFields {
        public String                       selectedField       {get; set;}
        //public List<SelectOption>           fieldsList          {get; private set;}
        public String                       selectedOperator    {get; set;}
       // public List<SelectOption>           operatorList        {get; private set;}
        public String                       searchValue         {get; set;}
        public String                       fieldType           {get; set;}
        public Integer                      counter             {get; set;}
        
        public ObjectFields(Integer counter){
            this.selectedField = '';
            //this.fieldsList = fieldsList;
            this.selectedOperator = '';
            //this.operatorList = OperatorsList();
            this.searchValue = '';
            this.fieldType = '';
            this.counter = counter;
        }
        
    }
    
      public Map<String, ResultInfo> getResultGrid(List<Sobject> resultSobjects, Sobject beforeRecord){
            //(Lead:{RecordTypeId=012300000013mgYAAQ, CurrencyIsoCode=GBP, FirstName=LalitTestedPassed, Id=00QV0000004DotPMAS, ALT_Department__c=test})
            Map<String , ResultInfo> sobjResultInfo = new Map<String , ResultInfo>();
            Map<String, SObject> lookupObjects = new Map<String, Sobject>();
            Map<String, Set<String>> lookupObjectFields = new Map<String, Set<String>>();
            SObject originalResultSobject;
             system.debug('--------------- resultSobjects-------------'+resultSobjects +'::'+recordInputCapture);
            try{
                Map<String , Set<String>> fieldRelationshipMap = new Map<String, Set<String>>();
                referenceObjects = new Map<String , Map<String, Sobject>>();
                if(resultSobjects.size() == 1){
                    originalResultSobject = resultSobjects.get(0);
                }else{
                    for(Sobject sobj : resultSobjects){
                        if(sobj.get('Id') == recordInputCapture.get('Id')){
                            originalResultSobject = sobj;
                        }else{
                            String sobjName = sobj.getSObjectType().getDescribe().getName();
                            lookupObjects.put(sobjName ,sobj);
                        }
                    }
                }
                System.debug('::originalResultSobject'+originalResultSobject);
                System.debug('::lookupObjects'+lookupObjects);
                Set<String> fieldsWithSameValue = new Set<String>();
                for(String objFd : mainFields){
                    objFd = objFd.trim();
                    String lookupObjfield;
                    if(objFd.contains('.')){
                        System.debug('::objFd'+objFd);
                        String[] tempObjFd = objFd.split('\\.');
                        if(tempObjFd[0].trim().contains('__r')){
                            tempObjFd[0] = tempObjFd[0].replace('__r','__c');
                        }else{
                            tempObjFd[0] += 'Id';
                        }
                        objFd = tempObjFd[0];
                        lookupObjfield = tempObjFd[1];
                    }
                    if(objFd != 'Id' && objFd != 'AWE_Rule__c' && objFd!=  'CurrencyIsoCode'){
                        sobjResultInfo.put(objFd, new ResultInfo(objFd));
                        sobjResultInfo.get(objFd).afterValue = originalResultSobject.get(objFd);
                        if(beforeRecord.get(objFd) != null){
                            sobjResultInfo.get(objFd).beforeValue = beforeRecord.get(objFd);
                        }
                    }
                    if(sobjResultInfo.get(objFd).afterValue == sobjResultInfo.get(objFd).beforeValue){
                    	fieldsWithSameValue.add(objFd);
                    	continue;
                    }
                    if(objFd == 'ownerid'){
                    	System.debug('::sobjResultInfo.get(objFd).afterValue'+sobjResultInfo.get(objFd).afterValue);
                        if(sobjResultInfo.get(objFd).afterValue != null && String.valueOf(sobjResultInfo.get(objFd).afterValue).startsWith('005')){
                            if(!fieldRelationshipMap.containsKey('ownerid')){
                                fieldRelationshipMap.put('ownerid' ,new set<String> {'User'});
                            }else{
                                fieldRelationshipMap.get('ownerid').add('User');
                            } 
                        }else if(sobjResultInfo.get(objFd.trim()).afterValue != null  && String.valueOf(sobjResultInfo.get(objFd).afterValue).startsWith('00G')){
                            if(!fieldRelationshipMap.containsKey('ownerid')){
                                fieldRelationshipMap.put('ownerid' ,new set<String> {'Group'});
                            }else{
                                fieldRelationshipMap.get('ownerid').add('Group');
                            }
                        }
                        if(sobjResultInfo.get(objFd).beforeValue != null && String.valueOf(sobjResultInfo.get(objFd).beforeValue).startsWith('005')){
                            if(!fieldRelationshipMap.containsKey('ownerid')){
                                fieldRelationshipMap.put('ownerid' ,new set<String> {'User'});
                            }else{
                                fieldRelationshipMap.get('ownerid').add('User');
                            }
                        }else if(sobjResultInfo.get(objFd.trim()).beforeValue != null  && String.valueOf(sobjResultInfo.get(objFd).beforeValue).startsWith('00G')){
                            if(!fieldRelationshipMap.containsKey('ownerid')){
                                fieldRelationshipMap.put('ownerid' ,new set<String> {'Group'});
                            }else{
                                fieldRelationshipMap.get('ownerid').add('Group');
                            }
                        }
                                    
                    }
                    if(!fieldRelationshipMap.containsKey(objFd)){
                        String crossObject = getRelatedFieldDescribe(workFlow.object__c, objFd);
                        System.debug('::crossObject'+crossObject);
                        if(crossObject != null){
                            fieldRelationshipMap.put(objFd , new Set<String>{crossObject});
                        }
                        if(!lookupObjectFields.containsKey(crossObject) && lookupObjfield != null){
                            lookupObjectFields.put(crossObject,new Set<String>{lookupObjfield});
                        }else if(lookupObjfield != null){
                            lookupObjectFields.get(crossObject).add(lookupObjfield);
                        }
                    }
                    System.debug('::lookupObjectFields'+lookupObjectFields);
                    System.debug('::fieldRelationshipMap'+fieldRelationshipMap);
                    if(fieldRelationshipMap.containsKey(objFd)){
                        
                        for(String objName : fieldRelationshipMap.get(objFd)){
                            if(!referenceObjects.containsKey(objName)){
                                referenceObjects.put(objName, new Map<String, Sobject>());
                            }
                            if(sobjResultInfo.get(objFd).afterValue != null){
                                referenceObjects.get(objName).put(String.valueOf(sobjResultInfo.get(objFd).afterValue).trim() , null);
                            }
                            if(sobjResultInfo.get(objFd).beforeValue != null){
                                referenceObjects.get(objName).put(String.valueOf(sobjResultInfo.get(objFd).beforeValue).trim() , null);
                            }
                        }
                   }
                    
                }
                if(!fieldsWithSameValue.isEmpty()){
                	for(String fd : fieldsWithSameValue)
                	sobjResultInfo.remove(fd);
                }
                // load other Accounts 
                Map<Id, List<Values_for_Action_Insert_Record__c>>  valuesForActionIRs = loadValueInsertRecords(AW_AdvanceWorkflowExecutionEngine.validRuleIds);
                loadOtherActions(AW_AdvanceWorkflowExecutionEngine.validRuleIds, valuesForActionIRs); 
                 if(!referenceObjects.isEmpty()){
                    // populate Reference Field Name
                    referenceObjects = loadReferenceSObjects(referenceObjects, 'Id' , lookupObjectFields);
                    for(ResultInfo ri : sobjResultInfo.values()){
                        if(fieldRelationshipMap.containsKey(ri.fieldLabel)){
                            for(String objName : fieldRelationshipMap.get(ri.fieldLabel)){
                                System.debug(':ri.afterValue'+ri.afterValue);
                                System.debug(':::lookupObjects.get(objName).get(fd)'+lookupObjects.get(objName));
                                System.debug(':::lookupObjectFields.get(objName)'+lookupObjectFields.get(objName));
                                System.debug(':::referenceObjects.get(objName).get(fd)'+referenceObjects.get(objName));
                                if(ri.afterValue != null && referenceObjects.containsKey(objName) && referenceObjects.get(objName).containsKey(String.valueOf(ri.afterValue).trim()) && referenceObjects.get(objName).get(String.valueOf(ri.afterValue).trim()) != null){
                                    ri.afterRefId = String.valueOf(ri.afterValue);
                                    ri.afterValue = referenceObjects.get(objName).get(String.valueOf(ri.afterValue).trim()).get('Name');
                                    if(lookupObjectFields.containsKey(objName) && lookupObjects.containsKey(objName) && lookupObjects.get(objName).id == referenceObjects.get(objName).get(String.valueOf(ri.afterRefId).trim()).id){
                                        ri.lookupResults = new List<ResultInfo>();
                                        for(String fd : lookupObjectFields.get(objName)){
                                            System.debug(':::referenceObjects.get(objName).get(fd)'+referenceObjects.get(objName).get(String.valueOf(ri.afterRefId).trim()).get(fd));
                                            ri.lookupResults.add(new ResultInfo(fd, referenceObjects.get(objName).get(String.valueOf(ri.afterRefId).trim()).get(fd) , lookupObjects.get(objName).get(fd)));
                                        }
                                    }
                                }
                                if(ri.beforeValue != null && referenceObjects.containsKey(objName) && referenceObjects.get(objName).containsKey(String.valueOf(ri.beforeValue).trim()) && referenceObjects.get(objName).get(String.valueOf(ri.beforeValue).trim()) != null){
                                    ri.beforeRefId = String.valueOf(ri.beforeValue);
                                    ri.beforeValue = referenceObjects.get(objName).get(String.valueOf(ri.beforeValue).trim()).get('Name');
                                }
                                
                                
                                
                            }
                        }
                    }
                    populateReferenceFieldsInOtherActions();
                }
                system.debug('--------------- sobjResultInfo  5-------------'+sobjResultInfo); 
            }
            
            catch(exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            }
            return sobjResultInfo;
    }
    
    /*
    * load Reference Names
    */
   private Map<String , Map<String, Sobject>> loadReferenceSObjects(Map<String , Map<String, Sobject>> referenceFieldNameMap , String keyField, Map<String , Set<String>> objFields){
        for(String objName : referenceFieldNameMap.keySet()){
            Set<String> ids = referenceFieldNameMap.get(objName).keySet();
            String soqlQuery = ' SELECT Id ,' +  (objName != 'Case' ? 'Name' : 'CaseNumber');
            if(objFields.containsKey(objName)){
            	for(String str : objFields.get(objName)){
            		if(str != 'Name' || (objName == 'Case' && str != 'CaseNumber')){
            			soqlQuery += ', ' + str;
            		}
            	}
            }
            soqlQuery += ' FROM '+ objName  + ' WHERE  ' + keyField + ' in : ids';
            for(Sobject sobj : Database.query(soqlQuery)){
                referenceFieldNameMap.get(objName).put((String)sobj.get(keyField) ,sobj);
            } 
        }
        return referenceFieldNameMap;
    }
    
    private Map<Id, List<Values_for_Action_Insert_Record__c>> loadValueInsertRecords(Set<Id> ruleIds){
    	Map<Id, List<Values_for_Action_Insert_Record__c>> valueForInsertRecords = new Map<Id , List<Values_for_Action_Insert_Record__c>>();
    	for(Values_for_Action_Insert_Record__c vair : [select id , Name , Reference_Id__c ,Value__c, Rule_Action__c from Values_for_Action_Insert_Record__c where rule_Action__r.Rule__c in : ruleIds order by rule_Action__c]){
    		if(!valueForInsertRecords.containsKey(vair.Rule_Action__c)){
    			valueForInsertRecords.put(vair.Rule_Action__c, new List<Values_for_Action_Insert_Record__c>{vair});
    		}else{
    			valueForInsertRecords.get(vair.Rule_Action__c).add(vair);
    		}
    	}
    	return valueForInsertRecords;
    }
    private void populateReferenceFieldsInOtherActions(){
    	Set<String> actionTypes = new Set<String>{'Send Email' , 'Chatter Notification'};
    	for(String actype : actionTypes){
    		if(mapOtherActions.containsKey(actype)){
    			for(ResultInfoOther rio : mapOtherActions.get(actype).values()){
    				if(rio.resultInfos.containsKey('Recipient') || rio.resultInfos.containsKey('User')){
    					ResultInfo rInfo = rio.resultInfos.containsKey('Recipient') ? rio.resultInfos.get('Recipient') : rio.resultInfos.get('User');
    					if(rInfo != null && rInfo.afterValue != null){
    						String afterValue = (String)rInfo.afterValue;
    						String objType = afterValue.startsWith('005') ? 'User' : (afterValue.startsWith('00G') ? 'Group' : (afterValue.startsWith('0F9') ? 'CollaborationGroup' : null));
			    			if(objType != null){
								if(referenceObjects.containsKey(objType) && referenceObjects.get(objType).containsKey(afterValue.trim()) && referenceObjects.get(objType).get(afterValue.trim()) != null){
		                			rInfo.afterRefId = afterValue;
                					rInfo.afterValue = referenceObjects.get(objType).get(afterValue).get('Name');
		                		}// ref if end
    					    }// obj Type if end
    				   }//rInfo if end
    						
    			}// contains if end 
    			if(rio.resultInfos.containsKey('Folder') && rio.resultInfos.get('Folder').afterValue != null){
    				String afterValue = (String)rio.resultInfos.get('Folder').afterValue;
    				if(referenceObjects.containsKey('Folder') && referenceObjects.get('Folder').containsKey(afterValue.trim()) && referenceObjects.get('Folder').get(afterValue.trim()) != null){
            			rio.resultInfos.get('Folder').afterRefId = String.valueOf(afterValue);
    					rio.resultInfos.get('Folder').afterValue = referenceObjects.get('Folder').get(afterValue.trim()).get('Name');
            		}
    			}
    		}// inner for loop end
    	}// act type contains if end
       }// outer for end
    }
    
    private void loadOtherActions(Set<Id> ruleIds, Map<Id, List<Values_for_Action_Insert_Record__c>>  valuesForActionIRs){
    	mapOtherActions  = new Map<String , Map<Id, ResultInfoOther>>();
    	for(String rId : ruleIds){
    		if(ruleActionMap.containsKey(rId)){
	    		for(RuleAction__c ra : ruleActionMap.get(rId)){
	    			System.debug('::ra'+ra);
	    			if(AW_Rule_Constants.simulateOtherActions.contains(ra.Type__c.trim())){
	    				ResultInfoOther tempRIO = new ResultInfoOther(new Map<String,ResultInfo>());
	    				if(!mapOtherActions.containsKey(ra.Type__c.trim())){
	    					mapOtherActions.put(ra.Type__c.trim(), new Map<Id,ResultInfoOther>());
	    				}
	    				if(ra.Type__c == 'Send Email' || ra.Type__c == 'Chatter Notification'){
	    					String objType = (ra.User_Owner_Id__c != null ? (ra.User_Owner_Id__c.startsWith('005') ? 'User' : (ra.User_Owner_Id__c.startsWith('00G') ? 'Group' : (ra.User_Owner_Id__c.startsWith('0F9') ? 'CollaborationGroup' : null))) : null);
	    					if(objType != null){
	    						if(!referenceObjects.containsKey(objType)){
                        			referenceObjects.put(objType, new Map<String, Sobject>());
                        		}
		                    	referenceObjects.get(objType).put(ra.User_Owner_Id__c.trim() , null);
		                    	
	    					}
	    				}
	    				if(ra.Type__c == 'Send Email'){
	    					tempRIO.resultInfos.put('Recipient',new ResultInfo('Recipient',null, ra.User_Owner_Id__c));
	    					tempRIO.resultInfos.put('Additional Recipients', new ResultInfo('Additional Recipients',null, ra.Additional_Emails__c));
	    					tempRIO.resultInfos.put('Folder', new ResultInfo('Folder',null, ra.Email_Template_Folder__c));
	    					if(ra.Email_Template_Folder__c != null){
	    						if(!referenceObjects.containsKey('Folder')){
                        			referenceObjects.put('Folder', new Map<String, Sobject>());
                        		}
		                    	referenceObjects.get('Folder').put(ra.Email_Template_Folder__c.trim() , null);
		                    	
	    					}
	    					tempRIO.resultInfos.put('Template', new ResultInfo('Template', null, ra.EmailTemplateName__c));
	    				}else if(ra.Type__c == 'Chatter Notification'){
	    					tempRIO.resultInfos.put('Label', new ResultInfo('Label',null, ra.Action_Label__c));
	    					tempRIO.resultInfos.put('Message', new ResultInfo('Message',null, ra.Input_Parameters__c));
	    					tempRIO.resultInfos.put('User', new ResultInfo('User',null, ra.User_Owner_Id__c));
	    				}else if(ra.Type__c == 'Execute an Apex Job'){
	    					tempRIO.resultInfos.put('Apex Class', new ResultInfo('Apex Class',null, ra.Apex_Job_Class__c));
	    					tempRIO.resultInfos.put('Output Parameters', new ResultInfo('Output Parameters',null, ra.Output_Parameters__c));
	    				}else if(ra.Type__c == 'Apex Callout-HTTP'){
	    					tempRIO.resultInfos.put('Apex Class', new ResultInfo('Apex Class',null, ra.Apex_Job_Class__c));
	    					tempRIO.resultInfos.put('Output Parameters', new ResultInfo('Output Parameters',null, ra.Output_Parameters__c));
	    				}
	    				mapOtherActions.get(ra.Type__c.trim()).put(ra.id, tempRIO);
	    			}
	    			else if(ra.Type__c == 'Update Field' && ra.Field_API_Name__c != AW_Rule_Constants.CROSSOBJECT && ra.Field_API_Name__c != AW_Rule_Constants.LOOKUPOBJECT && ra.Related_Object__c != workflow.Object__c){
	    				if(!childObjectFields.containsKey(ra.Related_Object__c)){
	    					childObjectFields.put(ra.Related_Object__c , new List<ResultInfo>{new ResultInfo( ra.Field_API_Name__c, null , (ra.Value__c != null ? ra.value__c : (ra.Long_Value__c != null ? ra.Long_Value__c : '' )))});
	    				}else{
	    					childObjectFields.get(ra.Related_Object__c).add(new ResultInfo(ra.Field_API_Name__c, null , (ra.Value__c != null ? ra.value__c : (ra.Long_Value__c != null ? ra.Long_Value__c : '' ))));
	    				}
	    			}else if(AW_Rule_Constants.simulateInsertUpsertActions.contains(ra.Type__c)){
	    				// need to write insert /upsert code
	    				ResultInfoOther tempRIO = new ResultInfoOther(new Map<String,ResultInfo>());
	    				tempRIO.objectName = ra.Related_Object__c;
	    				if(valuesForActionIRs.containsKey(ra.id)){
	    					Sobject beforeSobj;
	    					Sobject afterSobj;
	    					if(AW_SimulationExecution.mapUpsertBeforeSobjects.containsKey(ra.id +'~Before')){
	    						beforeSobj = AW_SimulationExecution.mapUpsertBeforeSobjects.get(ra.id +'~Before');
	    					}
							if(AW_SimulationExecution.mapUpsertBeforeSobjects.containsKey(ra.id +'~After')){
	    						afterSobj = AW_SimulationExecution.mapUpsertBeforeSobjects.get(ra.id +'~After');
	    					}
	    					System.debug('::beforeSobj'+beforeSobj);
	    					System.debug('::afterSobj'+afterSobj);
	    					for(Values_for_Action_Insert_Record__c vair : valuesForActionIRs.get(ra.id)){
	    						tempRIO.resultInfos.put(vair.Name,new ResultInfo(vair.Name, null, (afterSobj != null && ((vair.Reference_Id__c != null && vair.Reference_Id__c.trim().startsWith('{!')) || (vair.Value__c != null && vair.Value__c.contains('{!')))   ? afterSobj.get(vair.Name) : vair.Value__c)));
	    						tempRIO.resultInfos.get(vair.Name).afterRefId = vair.Reference_Id__c != null && !vair.Reference_Id__c.trim().startsWith('{!') ? vair.Reference_Id__c : null;
	    						
	    						//AW_FormulaExpressionHelper.resolveValueFetched (action,value,o,fieldMap);
	    						if(beforeSobj != null && beforeSobj.get(vair.Name) != null){
	    							tempRIO.resultInfos.get(vair.Name).beforeValue = beforeSobj.get(vair.Name); 
	    						}
	    					}
	    				}
	    				if(!mapOtherObjResultInfo.containsKey(ra.Type__c.trim())){
	    					mapOtherObjResultInfo.put(ra.Type__c.trim(), new Map<String,ResultInfoOther>());
	    				}
	    				mapOtherObjResultInfo.get(ra.Type__c.trim()).put(ra.id, tempRIO);
	    			}
	    		}
    		} 
    	}
    	System.debug('::mapOtherActions'+mapOtherActions);
    	System.debug('::mapOtherObjResultInfo'+mapOtherObjResultInfo);
    }
    
    private String joinListToString(Set<String> strSet , String delim){
    	List<String> fieldsList = new List<String>();
        fieldsList.addAll(strSet);
        return String.join(fieldsList, delim);
    }
    
    public class ResultInfo{
    	public String fieldLabel {get;set;}
        public Object beforeValue{get;set;}
        public String beforeRefId{get;set;}
        public String afterRefId{get;set;}
        public Object afterValue{get;set;}
        public List<ResultInfo> lookupResults{get;set;}
        public ResultInfo(String fieldLabel, Object beforeValue , Object afterValue){
        	this.fieldLabel = fieldLabel;
        	this.beforeValue = beforeValue;
        	this.afterValue = afterValue;
        	//this.lookupResults = new List<ResultInfo>();
        }
        public ResultInfo(){
        	this.lookupResults = new List<ResultInfo>();
        }
        public ResultInfo(String fieldLabel){
        	this.fieldLabel = fieldLabel;
        }
   }
   
   public class ResultInfoOther{
   		public String objectName{get;set;}
   		public Map<String, ResultInfo> resultInfos{get;set;}
   		public ResultInfoOther(Map<String, ResultInfo> resultInfos){
   			this.resultInfos = resultInfos;
   		}
   }
    
    public class FilterWrap{
            
            public integer sno{set;get;}            
            public String  Field_Name{set;get;}
            //public String  field_API_name{set;get;}
            public String  field_type{set;get;}
            public String field_Value{set;get;}
            public boolean  isEditable{set;get;}
            public Boolean checkBox{get;set;} 
            public List<String> referenceTo{get;set;}          
            public filterwrap(integer no){                                   
                    this.sno=no;
            }     
            public filterwrap(){}        
    }
    
}
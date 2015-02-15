// 
// (c) 2013 Appirio, Inc.
// AW_ExecutionActionHelper                                                     
// A helper class for execution of actions
//
// 12 Dec 2013     Peter Babalis     Original  
// 24 Dec 2013     Peter Babalis     Added  getValidfields_from_Actions,apex_execution_params,
//                                          apex_execution_outputupdate,applyInsertChildActions
//                                          updateFieldfrom AW_AdvanceWorkflowExecutionEngine 
// 14 Oct 2014     Peter Babalis      Added Lookup action to accept merge fields e.g ZIP_code_value__c={!Lead.PostalCode} AND {!Lead.Industry='Agriculture'}
 
public  class AW_ExecutionActionHelper {
		
		private static String concatop='&';
		private static String apostrophe='\'';
		
		public static void configureUpdateFieldAction(RuleAction__c action){
                Set<String> fieldToAdd = AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase())!=null ? AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase()): new Set<String>(); 
                  
                //updating for ownerprioritization 
                if(action.Field_Name__c=='OwnerPrioritization') return; 
                      
                //modifying for crossobject
                if(action.Field_Name__c!='LookupObjectField'){
                    String fieldToUpdate = action.Field_Name__c=='CrossObject' ? action.CrossObjectField__c: action.Field_Name__c.toLowerCase();
                    if(!fieldToAdd.contains(fieldToUpdate) && !fieldToUpdate.startsWithIgnoreCase('What')){
                        fieldToAdd.add(fieldToUpdate);
                    }
                }
                //Megha - 15/10/2014 - add Merge field
                if(action.Field_Name__c == 'LookupObjectField' && action.Lookup_Where_Fields__c != null && action.Lookup_Where_Fields__c.contains('{!')){
                	String whereMergeFields = action.Lookup_Where_Fields__c;
                	while(whereMergeFields.contains('{!')){
	                    String whereMergeField = mergeField(whereMergeFields , action.Related_Object__c);
	                    if(whereMergeField != null && !fieldToAdd.contains(whereMergeField)){
	                    	fieldToAdd.add(whereMergeField);
	                    } 
	                    whereMergeFields = whereMergeFields.contains('{!' + action.Related_Object__c + '.' + whereMergeField + '}')  ? whereMergeFields.replace('{!' + action.Related_Object__c + '.' + whereMergeField + '}', '') :  whereMergeFields.replace('{!' + whereMergeField + '}', '');
	                    System.debug('::whereMergeFields' +whereMergeFields);
                	}
                }
                    
                // now modify the section of code here:-
                String value = AW_AdvanceWorkflowExecutionHelper.getValueForUpdateAction(action);
                
                Map<String,Schema.SObjectField> fieldList = AW_AdvanceWorkflowExecutionEngine.fieldMap.get(action.Related_Object__c.toLowerCase());
                
                if(value != null && fieldList!= null && (fieldList.containsKey(value)==true ||  AW_AdvanceWorkflowExecutionEngine.fieldMap.containsKey(value.toLowerCase())==true)){
                    if(!fieldToAdd.contains(value.toLowerCase()))
                        fieldToAdd.add(value.toLowerCase());        
                }
                 else{
                    String field = AW_FormulaExpressionHelper.fetchFieldFromString(action,value,AW_AdvanceWorkflowExecutionEngine.validRelationShips);
                    //adding an additional line to avaoid errors                    
                    if(field!=null){
                         for(String fld : field.split(','))
                               if(fld!=null && !fieldToAdd.contains(fld.toLowerCase()))
                                    fieldToAdd.add(fld.toLowerCase());
                    }
                }
                
                //finally add the fields back
            //     system.debug('-->configureUpdateFieldAction.fieldToAdd before exit 1'+fieldToAdd);
                AW_AdvanceWorkflowExecutionEngine.criteriaFields.put(action.Related_Object__c.toLowerCase(),fieldToAdd);   
        }
        
        //@SH:allow merge fields in additional emails
        public static void configureSendEmailAction(RuleAction__c action){
           Set<String> fieldToAdd = AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase())!=null ? AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase()): new Set<String>(); 
                
           if(action.Additional_Emails__c!=null){
                List<String> emails = action.Additional_Emails__c!=null? action.Additional_Emails__c.split(','):new List<String>();
                for(String email : emails){
                    String field = AW_FormulaExpressionHelper.fetchFieldFromString(action,email,AW_AdvanceWorkflowExecutionEngine.validRelationShips); 
                    //adding an additional line to avaoid errors                    
                    if(field!=null){
                         for(String fld : field.split(','))
                                if(!fieldToAdd.contains(fld.toLowerCase()))
                                    fieldToAdd.add(fld.toLowerCase());
                    }
                    
                }
            }
             //finally add the fields back
            AW_AdvanceWorkflowExecutionEngine.criteriaFields.put(action.Related_Object__c.toLowerCase(),fieldToAdd);  
        }
        
        public static void configureJobAction(RuleAction__c action){
            Set<String> fieldToAdd = AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase())!=null ? AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(action.Related_Object__c.toLowerCase()): new Set<String>(); 
            
            if(action.Input_Parameters__c!=null){
                List<String> input = action.Input_Parameters__c!=null? action.Input_Parameters__c.split(','):new List<String>();
                for(String pair : input){
                    List<String> keyValue = pair.split(':');
                    
                    //SH:updating to add support for constants
                    if(!keyValue[1].startsWith('{!')) continue;
                	String mergeField = keyValue[1].substringBetween('{!','}');
                    
                    if(!fieldToAdd.contains(mergeField) && !fieldToAdd.contains(mergeField.toLowerCase()))
                        fieldToAdd.add(mergeField.toLowerCase());
                }
            }
            
            if(action.output_Parameters__c!=null){
                List<String> output = action.output_Parameters__c!=null? action.output_Parameters__c.split(','):new List<String>();
                for(String pair : output){
                    List<String> keyValue = pair.split(':');
                    //SH:updating to add support for constants
                    if(!keyValue[1].startsWith('{!')) continue;
                	String mergeField = keyValue[1].substringBetween('{!','}');
                	
                    if(!fieldToAdd.contains(mergeField) && !fieldToAdd.contains(mergeField.toLowerCase()))
                        fieldToAdd.add(mergeField.toLowerCase());
                }
            }
            //finally add the fields back
            AW_AdvanceWorkflowExecutionEngine.criteriaFields.put(action.Related_Object__c.toLowerCase(),fieldToAdd);   
                    
        }
        
        public static void configureInsertRelatedObjectAction(Rule__c rule,RuleAction__c action){
                if(AW_AdvanceWorkflowExecutionEngine.insertedRelatedRecordInfo.containsKey(action.Id)){
                  for(Values_for_Action_Insert_Record__c info: AW_AdvanceWorkflowExecutionEngine.insertedRelatedRecordInfo.get(action.Id).Values_for_Action_Insert_Record__r){
                      
                      /**
                      * if reference then add field to parent object
                      */
                      Set<String> fieldToAdd = AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(rule.Object__c.toLowerCase())!=null ? AW_AdvanceWorkflowExecutionEngine.criteriaFields.get(rule.Object__c.toLowerCase()): new Set<String>();
                      
                        //adding merge fields in value evaluation
                       String field = AW_FormulaExpressionHelper.fetchFieldFromString(action,info.Value__c,AW_AdvanceWorkflowExecutionEngine.validRelationShips); 
                       system.debug('--> field 854'+field);
                        if(field!=null){
                         List<String> fieldelements = field.split('\\.');                       
                         for(String fld : field.split(',')){
                            if  (fieldelements.size()>1 ){
                                     if ( (fieldToAdd.contains(fieldelements[1])) &&(rule.Object__c.toLowerCase()== fieldelements[0]) )
                                      fieldToAdd.remove(fieldelements[1]);
                                 }
                          
                                if(!fieldToAdd.contains(fld.toLowerCase()))
                                    fieldToAdd.add(fld.toLowerCase());
                           }            
                        }
                  }
              }
        }
		
		public static String executeLookupObjectAction(RuleAction__c action, Sobject o){
       
	        String query ='Select Id,'+action.Lookup_Field_Api_Name__c+' FROM '+action.lookup_object__c;
	        
	        String mergedWhereFields = action.Lookup_Where_fields__c;
	        if(mergedWhereFields != null){
		        while(mergedWhereFields.contains('{!')){
			        String mergeField = mergeField(mergedWhereFields, action.related_Object__c);
			        if(mergeField != null){
			        	String filterValue = getFilterValue(action.Related_Object__c , mergeField, o);
			        	if(mergedWhereFields.contains('{!' + action.Related_Object__c +'.' + mergeField + '}')){
		                	mergedWhereFields = mergedWhereFields.replace('{!' + action.Related_Object__c +'.' + mergeField + '}' , filterValue);
		                }else if(mergedWhereFields.contains('{!' + mergeField +'}')){
		                	mergedWhereFields = mergedWhereFields.replace('{!' + mergeField +'}' , filterValue);
		                }
		             }
		        }
		        if(mergedWhereFields != null)
		            query+=' WHERE '+mergedWhereFields;
		                            
		       System.debug('::query'+query);
		        List<SObject> sobjList = Database.query(query+' limit 1');
		        if(sobjList != null && sobjList.size() > 0 && sobjList[0].get(action.Lookup_Field_API_Name__c)!=null){
		               return String.valueof(sobjList[0].get(action.Lookup_Field_API_Name__c));
		        }
		      }
	        return null;
	    }
	    
	    /***
	    	* added by Megha 10/15/2014
	    	* method that will return the merge field
	    **/  
	    
	    public static String mergeField(String whereMergeFields , String relatedObject){
	    	String mainField;
	    	 if (whereMergeFields.contains('{!')){
	    	 	 mainField =  whereMergeFields.substringBetween('{!','}');
                 Integer result = whereMergeFields.indexOf('{!');
                 String wherefield =  whereMergeFields.subString(0,result);
                 system.debug('-->wherefield ' +wherefield);
                 system.debug('-->mainField ' +mainField);
                 if(mainField != null){
                     mainField = mainField.trim();
                 if(mainField.startsWith(relatedObject + '.')){
                 	mainField = mainField.replace(relatedObject + '.' , '');
                 }
              }
           }
           return mainField;
	    }
	    /***
	    	* added by Megha 10/15/2014
	    	* method that will return the value of the merge field 
	    **/ 
	    
	    private static String getFilterValue(String relatedObject, String field , Sobject o){
	    	Schema.DisplayType fieldType;
	    	String filterValue;
	    	if(AW_AdvanceWorkflowExecutionEngine.fieldMap != null && AW_AdvanceWorkflowExecutionEngine.fieldMap.containsKey(relatedObject) && AW_AdvanceWorkflowExecutionEngine.fieldMap.get(relatedObject).containsKey(field)){
	    	 	fieldType = AW_AdvanceWorkflowExecutionEngine.fieldMap.get(relatedObject).get(field).getDescribe().getType();
	    	 }else{
	    	 	fieldType = Schema.getGlobalDescribe().get(relatedObject).getDescribe().fields.getMap().get(field).getDescribe().getType();
	    	 }
	    	 if(o.get(field) != null){
	    		 if(fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Email || fieldType == Schema.DisplayType.EncryptedString || fieldType == Schema.DisplayType.Id || fieldType == Schema.DisplayType.MultiPicklist || fieldType == Schema.DisplayType.Phone  || fieldType == Schema.DisplayType.Picklist || fieldType == Schema.DisplayType.Reference || fieldType == Schema.DisplayType.URL || fieldType == Schema.DisplayType.TextArea){
	                filterValue =  '\'' + (String)o.get(field) + '\'' ;    
	            }else if(fieldType == Schema.DisplayType.Date){
	            	Date mergeDateField = Date.valueOf(o.get(field));
	            	filterValue = mergeDateField.year() + '-' + mergeDateField.month() + '-' + mergeDateField.day();    
	            }else if(fieldType == schema.DisplayType.DateTime){
	            	DateTime mergeDateTimeField = DateTime.valueOf(o.get(field));
	            	filterValue =  mergeDateTimeField.formatGMT('yyyy-MM-dd') + 'T' + mergeDateTimeField.formatGMT('hh:mm:ss') + 'Z';  
	            }else{
	            	filterValue = '' + o.get(field) +'';
	            }
	    	 }else{
	    	 	filterValue = 'null';
	    	 }
            return filterValue;
	    }
      
        /**
        * @added by SH 1/10/2012
        * method that will initialize valid action fields so that we can add it
        * in field list that will be queried
        */
        public static void getValidfields_from_Actions(List<Rule__c> rules ,String sobjectName){
            Schema.DescribeSObjectResult R =AW_AdvanceWorkflowExecutionEngine.gd.get(sobjectName).getDescribe();
               
            /**
            * set all the object on which the action has been defined
            */
            Set<String> objectDefinedInAction = new Set<String>();
            for (Integer i=0;i<rules.size();i++){
                for(RuleAction__c action : rules[i].Rule_Actions__r){
                    if(!objectDefinedInAction.contains(action.Related_Object__c.toLowerCase())){
                        objectDefinedInAction.add(action.Related_Object__c.toLowerCase());      
                    }                       
                } 
            }
            
            /**
            * the objects that are defined in the criteria a valid child relation ships
            */
            for(Schema.ChildRelationship child: R.getChildRelationships()){
                Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                String objname =descRes.getName().toLowerCase();
                /**
                * Below line by Cloud Challenger
                * This populated parent field name in childParentRelationshipField Map
                */                  
                AW_AdvanceWorkflowExecutionEngine.childParentRelationshipField.put(objname,child.getField().getDescribe().getName());
                /**
                * if the object is object defined in action process the next steps
                */
                if(objectDefinedInAction.contains(objname) && AW_AdvanceWorkflowExecutionEngine.fieldMap.get(objname)==null){     
                    
                    //add the field in relationship map
                    AW_AdvanceWorkflowExecutionEngine.relationshipNames.put(objname,child.getRelationshipName());   

                    //get the fields in the list
                    Map<String,Schema.SObjectField> fieldList = descRes.fields.getMap();            
                    AW_AdvanceWorkflowExecutionEngine.fieldMap.put(objname,fieldList);

                    /**
                    * for all the valid fields in the child object
                    * check if it has a relation ship name if yes then add it for future use
                    */
                    for(String f: fieldList.keySet()){
                        Schema.DescribeFieldResult FR =fieldList.get(f).getDescribe();
                        system.debug('getRelationshipName-->'+FR.getRelationshipName());
                        if(FR.getRelationshipName()!=null){
                            Set<String> validRN = AW_AdvanceWorkflowExecutionEngine.validRelationShips.get(objname.toLowerCase())!=null ? AW_AdvanceWorkflowExecutionEngine.validRelationShips.get(objname.toLowerCase()): new Set<String>();
                            validRN.add(FR.getRelationshipName().toLowerCase());
                            AW_AdvanceWorkflowExecutionEngine.validRelationShips.put(objname.toLowerCase(),validRN);
                        }
                    }
                }
            }
            //add this rule fields also to criteria field set as they need to be updated
            for(Rule__c rule : rules){
                for(RuleAction__c action : rule.Rule_Actions__r){
                    if(action.Type__c=='Update Field'){
                        AW_ExecutionActionHelper.configureUpdateFieldAction(action);                     
                    }//end  action.Type__c=='Update Field'
                    else if(action.Type__c=='Send Email'){
                        AW_ExecutionActionHelper.configureSendEmailAction(action);                     
                    }
                     else if(action.Type__c == 'Insert Related Object' || action.Type__c == 'Upsert Related Object'){
                         /**
                        * By Cloud Challenger
                        * Below code iterate to Values_for_Action_Insert_Record__c records to get reference field for query
                        */
                        AW_ExecutionActionHelper.configureInsertRelatedObjectAction(rule,action);
                    }// end action.Type__c == 'Insert Related Object'
                    if(action.Type__c=='Execute An Apex Job' || action.Type__c=='Apex Callout-HTTP'){
                        AW_ExecutionActionHelper.configureJobAction(action);                     
                    }//end  action.Type__c=='Execute An Apex Job'
                }//end action
            }//end rule
            
        }//end method
        
    public static Map<String,String> apex_execution_params(RuleAction__c action,String params,SOBject o){
        Map<String,String> param_map= new Map<String,String>();
        if(params==null) return param_map;
        List<String> input = params.split(',');
        
        for(String s:input){
            List<String> keyValue = s.split(':');
            String value=keyValue[1]!=null ? AW_FormulaExpressionHelper.resolveValueFetched(action,keyValue[1],o,AW_AdvanceWorkflowExecutionEngine.fieldMap):'';
            param_map.put(keyValue[0],value);
        }
        
        return param_map;
    }
    
    public static void apex_execution_outputupdate(RuleAction__c action,Map<String,String> params,SOBject o){
        if(action.output_parameters__c==null) return;
        
        List<String> input = action.output_parameters__c.split(',');
        
        for(String s:input){
            SObject o1 =  AW_AdvanceWorkflowExecutionEngine.toUpdateSObject.get(o.Id)!=null?AW_AdvanceWorkflowExecutionEngine.toUpdateSObject.get(o.Id):o;
            List<String> keyValue = s.split(':');
            String value=params.get(keyValue[0]);
            if(value==null) continue;
            
            //otherwise start the processing
            
            String fieldToUpdate = keyValue[1];
            if(fieldToUpdate.startsWith('{!'))
            fieldToUpdate= fieldToUpdate.substringBetween('{!','}');
            
            if(fieldToUpdate==null || fieldToUpdate.trim()=='') continue;
            
            if(fieldToUpdate.contains('.')){
                List<String> reference = value.split('\\.'); 
                fieldToUpdate = reference[reference.size()-1];
                o1 = o.getSObject( reference[0]);   
                o1 =  AW_AdvanceWorkflowExecutionEngine.toUpdateSObject.get(o1.Id)!=null?AW_AdvanceWorkflowExecutionEngine.toUpdateSObject.get(o1.Id):o;    
                continue ;              
            }
            o1 = updateField(action.Related_Object__c,fieldToUpdate,value,o1);
            AW_AdvanceWorkflowExecutionEngine.toUpdateSObject.put(o1.Id,o1);      
        }
    }
    
     /**
    * By Cloud Challenger
    * Required one more parameter parent 
    */
    public static SObject applyInsertChildActions(RuleAction__c action,SObject sobj,Sobject parent){  
        /**
        * By Cloud Challenger
        * Below code apply Insert Related Record Info record  and create sobject for insertion
        */
        try{
         if(action.Type__c == 'Insert Related Object' || action.Type__c == 'Upsert Related Object' ||
        	action.Type__c == 'Insert Unrelated Object' || action.Type__c == 'Upsert Unrelated Object'){
          system.debug('-->insertedRelatedRecordInfo '+AW_AdvanceWorkflowExecutionEngine.insertedRelatedRecordInfo);
          system.debug('-->action.Id '+action.Id);
           if(AW_AdvanceWorkflowExecutionEngine.insertedRelatedRecordInfo.containsKey(action.Id)){
                for(Values_for_Action_Insert_Record__c info: AW_AdvanceWorkflowExecutionEngine.insertedRelatedRecordInfo.get(action.Id).Values_for_Action_Insert_Record__r){
                    system.debug('-->info'+info);
                    //bug fix : when the field is type of reference it is passing record name instead of the id
                    String toupdatevalue= info.Reference_Id__c!=null? info.Reference_Id__c : info.Value__c;
                    // Cloud Challenge: Date expression in insert related object
                    // Start
                   system.debug('-->toupdatevalue'+toupdatevalue);
                    if(AW_AdvanceWorkflowExecutionEngine.fieldmap.get(String.valueof(sobj.getSObjectType()).toLowerCase())==null){
                        AW_AdvanceWorkflowExecutionEngine.fieldmap.put(String.valueof(sobj.getSObjectType()).toLowerCase(),AW_AdvanceWorkflowExecutionEngine.gd.get(String.valueof(sobj.getSObjectType())).getDescribe().fields.getMap());
                    }
                    Schema.Sobjectfield field = AW_AdvanceWorkflowExecutionEngine.fieldmap.get(String.valueof(sobj.getSObjectType()).toLowerCase()).get(info.Name.tolowercase()); 
                    Schema.Describefieldresult fieldDesc = field.getDescribe();
                    String fldType = fieldDesc.getType().name();
                    
                    if((fldType.equalsIgnoreCase('datetime') || fldType.equalsIgnoreCase('date')) && toupdatevalue != null && toupdatevalue != ''){
                        Matcher conMatcher = Pattern.compile('(?i)(today\\(\\))\\s*([\\+\\-]\\s*(\\d)+d\\s*)?').matcher(toupdatevalue);
                        if(conMatcher.matches()){
                            toupdatevalue = conMatcher.group(2);
                            string valuetosave = System.now()+'';
                            if(toupdatevalue != null){
                                valuetosave = String.valueof(AW_FormulaExpressionHelper.dateFuntionality(System.now(),toupdatevalue.replaceAll('[\\+ ]','')));
                            }
                            sobj = updateField(action.Related_Object__c,info.Name.tolowercase(),valuetosave,sobj);
                            continue;
                        }
                        else{
                            conMatcher = Pattern.compile('(?i)(yesterday\\(\\))\\s*([\\+\\-]\\s*(\\d)+d\\s*)?').matcher(toupdatevalue);
                            if(conMatcher.matches()){
                                toupdatevalue = conMatcher.group(2);
                                string valuetosave = System.now().addDays(-1)+'';
                                if(toupdatevalue != null){
                                    valuetosave = String.valueof(AW_FormulaExpressionHelper.dateFuntionality(System.now().addDays(-1),toupdatevalue.replaceAll('[\\+ ]','')));
                                }
                                sobj = updateField(action.Related_Object__c,info.Name.tolowercase(),valuetosave,sobj);
                                continue;
                            }
                        }
                    }
                    //End
                    //adding merge field logic here
                     // if(toupdatevalue!=null && ( (toupdatevalue.contains(concatop) && toupdatevalue.contains(apostrophe)  )||  toupdatevalue.startsWith('{!'))){
                    //PGB 52214
                    if(toupdatevalue!=null && ( (toupdatevalue.contains(concatop) && toupdatevalue.contains(apostrophe) && toupdatevalue.contains('{!') )||  toupdatevalue.startsWith('{!'))){
                           system.debug('->toupdatevalue '+toupdatevalue);
                           system.debug('->parent '+parent);
                           
                           String valuetosave=AW_FormulaExpressionHelper.doMerge(action,toupdatevalue,parent);
                            // Cloud Challenge: Date expression in insert related object
                            // Start
                            if(valuetosave != null && valuetosave != ''){
                                if(fldType.equalsIgnoreCase('datetime') || fldType.equalsIgnoreCase('date')){
                                    String[] splitVal = toupdatevalue.split(' ');
                                    if(splitVal != null && splitVal.size() >= 2){
                                        valuetosave = String.valueof(AW_FormulaExpressionHelper.dateFuntionality(Datetime.valueof(valuetosave),splitVal[1].replaceAll('[\\+ ]','')));
                                    }
                                }
                                sobj = updateField(action.Related_Object__c,info.Name.tolowercase(),valuetosave,sobj);
                            }
                            //End
                    }
                    else if(toupdatevalue!=null && ( toupdatevalue.contains('.') && toupdatevalue.contains('{!')  )){
                    	
                        String valuetosave = AW_FormulaExpressionHelper.fetchCrossformulaValue(action,toupdatevalue,parent);
                        
           //             system.debug('valuetosave-->'+valuetosave);
                        sobj = updateField(action.Related_Object__c.tolowercase(),info.Name.tolowercase(),valuetosave,sobj);  
                    }
                    else{
                        sobj = updateField(action.Related_Object__c.tolowercase(),info.Name.tolowercase(),toupdatevalue,sobj);
                    }
                }
            }
        }  
        return sobj;
      }
      catch(Exception e){         
         AW_AdvanceWorkflowExecutionHelper.handleError(e);   
         throw e;                   
         return null;
      }       
       
    }
     /* update a field - helper */
    public static Sobject updateField(String obj,String fieldname ,String value,SObject toUpdate){
      system.debug('->obj '+obj);
      system.debug('->fieldname '+fieldname);
      system.debug('->value '+value);
      system.debug('->toUpdate  '+toUpdate );
      system.debug('->toUpdate.getSObjectType() '+toUpdate.getSObjectType());
      system.debug('->toUpdate.getSObjectType() '+toUpdate.getSObjectType().getDescribe());
      system.debug('->toUpdate.getSObjectType() '+toUpdate.getSObjectType().getDescribe().fields);
      system.debug('->toUpdate.getSObjectType() '+toUpdate.getSObjectType().getDescribe().fields.getMap());
     system.debug('->AW_AdvanceWorkflowExecutionEngine.fieldmap '+AW_AdvanceWorkflowExecutionEngine.fieldmap);
    
       
        if(AW_AdvanceWorkflowExecutionEngine.fieldmap.get(String.valueof(toUpdate.getSObjectType()).toLowerCase())==null) {
     	       AW_AdvanceWorkflowExecutionEngine.fieldmap.put(String.valueof(toUpdate.getSObjectType()).toLowerCase(),AW_AdvanceWorkflowExecutionEngine.gd.get(String.valueof(toUpdate.getSObjectType())).getDescribe().fields.getMap());
          system.debug('->toUpdate.getSObjectType()  HERE');
        }
      //  Schema.Sobjectfield field = AW_AdvanceWorkflowExecutionEngine.fieldmap.get(String.valueof(toUpdate.getSObjectType()).toLowerCase()).get(fieldname); 
        Schema.Sobjectfield field = AW_AdvanceWorkflowExecutionEngine.fieldmap.get(String.valueof(toUpdate.getSObjectType()).toLowerCase()).get(fieldname.toLowerCase()); 
       system.debug('->field  '+field );
         Schema.Describefieldresult fieldDesc = field.getDescribe();

       
         
        String fldType = fieldDesc.getType().name();
        //value = String.escapeSingleQuotes(value);     
        // PGB Comment it out on 5/23/14
        // if(value!=null)value = value.replaceAll('\'','');
                    
        /**
        * Start
        * By Cloud Challenger
        * Below code will add reference id to map and the mail body to be sent only if the reference type is user
        * and  NotifyUser is true
        */
        if(fldType.equalsIgnoreCase('reference')){
            try{
                 //updating to use the tempalte id
               // Id referenceId = Id.valueof(value);
                Id referenceId;
                if(value!=null)referenceId = Id.valueof(value);
                if(referenceId != null && referenceId.getSObjectType() == User.SobjectType && AW_AdvanceWorkflowExecutionEngine.notifyUser){
                      //String mailBody = 'You are assigned as '+ fieldDesc.getLabel() + ' for '+objectLabels.get(obj) +' <a href="'+sfURL+'/'+toUpdate.Id+'">Record</a>';
                    if(!AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.containsKey(referenceId)){
                        //if no                       
                        List<RuleAction__c> temp = new List<RuleAction__c>{AW_AdvanceWorkflowExecutionEngine.actionInContext};
                        Map<String ,List<RuleAction__c>> objTemp=  new Map<String ,List<RuleAction__c>>();
                        objTemp.put(toUpdate.Id,temp);
                        AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.put(referenceId,objTemp); 
                    }
                    else{
                        Map<String ,List<RuleAction__c>> objTemp = AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.get(referenceId);
                        if(!objTemp.containsKey(toUpdate.Id))
                            objTemp.put(toUpdate.Id,new List<RuleAction__c>{AW_AdvanceWorkflowExecutionEngine.actionInContext});
                        else
                            objTemp.get(toUpdate.Id).add(AW_AdvanceWorkflowExecutionEngine.actionInContext);
                            
                        AW_AdvanceWorkflowExecutionHelper.userIdMailContentMap.put(referenceId,objTemp);
                    }
                }
            }
            catch(Exception ex){throw ex;
            }
            toUpdate.put(fieldname,value);
            /**
            * End 
            */
        }else if(fldType.equalsIgnoreCase('string') || fldType.equalsIgnoreCase('picklist')|| fldType.equalsIgnoreCase('email') || fldType.equalsIgnoreCase('url')|| fldType.equalsIgnoreCase('multipicklist')|| fldType.equalsIgnoreCase('phone')){       
            toUpdate.put(fieldname,value);
        }else if(fldType.equalsIgnoreCase('boolean')){   
            toUpdate.put(fieldname,Boolean.valueOf(value));
        }else if(fldType.equalsIgnoreCase('double') || fldType.equalsIgnoreCase('currency')|| fldType.equalsIgnoreCase('percent')){   
            toUpdate.put(fieldname,Decimal.valueOf(value));
        }else if(fldType.equalsIgnoreCase('integer')|| fldType.equalsIgnoreCase('number')){   
            toUpdate.put(fieldname,Integer.valueOf(value));
        }else  if(fldType.equalsIgnoreCase('date')){   
            toUpdate.put(fieldname,Date.valueOf(value));
        }else  if(fldType.equalsIgnoreCase('datetime')){   
            toUpdate.put(fieldname,Datetime.valueOf(value));
        }  
        else if(fldType.equalsIgnoreCase('base64') && value != null){   
            toUpdate.put(fieldname,Blob.valueof(value));
        }
        else{
            //system.debug('------------>fldType:1514:' + fldType);
            toUpdate.put(fieldname,value);
        }                 
        return toUpdate;
    }       
    
      
   	
}
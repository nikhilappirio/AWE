/*********************************************************************************
Name : AW_EnhancedRuleCriteriaController
Created By : Appirio   [Peter Babalis]
Created Date : 20 April 2013
Purpose : controller for AW_EnhancedRuleCriteria_VF  page

9/1/2013    Added Evaluate_Criteria_Result_To__c picklist to control behavior
            for evaluation if no child record found 
 10/5/2013  Record Typr Name 
 12/31/2013 Added Owner name in addition to Owner Id
 05/01/2014 Added CrossFormula Validation
 08/10/2014 Fixed the default value load for existing criteria
 10/04/2014 Change the Sharing based on CheckMarx
 *********************************************************************************/
 public with sharing class AW_EnhancedRuleCriteriaController{
      
         public List<filterwrap> FilterWrapper{get;set;}
         public list<filterwrap> deletewrapper;
         
         Map<String, Schema.SObjectField> mapField=new map<string,Schema.SObjectField>();
         private  map< String,string> Fieldtypemap=new map<string,string>();
         private Map<String,Schema.SObjectType> gd;
         
         public string parentOperator{set;get;}
         public string parentObj{set;get;}
         public string parentField{set;get;}
         public string globalVar{set;get;}
         public string index {get;set;}
         public string index1 {get;set;}
         public Rule__c ruleRecord{set;get;}
         public integer toremovecounter{set;get;}
         public String ownerId{get;set;}
         public static String CROSSFORMULA_ERROR ='Invalid syntax for CrossFormula field provided';
   
         public List<SelectOption> objOptions    {get;set;}
         private Map<String,String> mapRectypeIdRecName {get;set;}
 
         public static String splitdelimeter =';';
         public static String escsapeplitdelimeter ='\\;';

         String ruleId;
         String oldFilterValue = '';
         
         public AW_EnhancedRuleCriteriaController(ApexPages.StandardController std){
            mapRectypeIdRecName = new Map<String,String>();
            FilterWrapper = new List<filterwrap>();
            deletewrapper  = new List<filterwrap>();
            ruleId=Apexpages.currentPage().getParameters().get('ruleId'); 
            parentOperator ='';parentObj ='';parentField ='';index ='';index1='';
            toremovecounter = -1;
            objOptions = new List<SelectOption>();
            gd = Schema.getGlobalDescribe();
            if(ruleId==null){
                 list<RuleCriteria__C> RCid = [select id, Rule__c from RuleCriteria__C where id=:std.getId()];
                 if(RCid.size()>0){
                    ruleId=RCid[0].Rule__c;
                }
                 else{
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid ID'));
                 }
               }
            loadfilter(ruleId); 
            if(RuleRecord.Filter_Logic__c == null || RuleRecord.Filter_Logic__c == ''){
                RuleRecord.Filter_Logic__c = '1';
                oldFilterValue = '1';
            }
            addDefaultFilterLogic();
            
         }
         
         private void loadfilter(String ruleId){
             Schema.DescribeSObjectResult   objinfo = null;
             List<Rule__c> rule=[Select id, name,Object__c, Filter_Logic__c ,Description__c,Evaluation_Rule__c
                    From Rule__c
                    Where id=:ruleId LIMIT 1];
              if(rule.size() > 0){
                 ruleRecord= rule[0];    
              } 
              
              if(  ruleRecord.Object__c!=null &&  ruleRecord.Object__c!=''){
                    Map<String, Schema.SObjectType> mapObj = Schema.getGlobalDescribe();
                    Schema.SObjectType sobj = mapObj.get(ruleRecord.Object__c);
                    objinfo =sobj.GetDescribe();
                    
                     List<Schema.ChildRelationship> listChild = sobj.getDescribe().getChildRelationships();
                     objOptions.add(new SelectOption(objInfo.getName(), objInfo.getLabel() + ' (' + objInfo.getName() + ')'));
                   
                   //building the child object dropdown
                     if(ruleRecord.Evaluation_Rule__c != 'Record is created or edited and did not previously meet the rule criteria'){
                       for(Schema.ChildRelationship child: listChild){
                          Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                          objOptions.add(new SelectOption(descRes.getName(),descRes.getLabel()+  ' (' + descRes.getName() + ')'));
                       }
                     }
              }  //end if
              
              // Sorting Objects based on label
              AW_AdvanceWorkflowExecutionHelper.sortSelectListOnLabel(objOptions);
              //fetch all the criteria
              list<RuleCriteria__C> criterias =getRuleCriteria();
              
              if(criterias.size()==0){
                 FilterWrapper.add(new filterwrap(true,'',new RuleCriteria__c (),FilterWrapper.size()+1));
                 populateField(objInfo.getName(),0); 
                 return;
              }
              
              for(RuleCriteria__C rc:criterias ){
                   if(rc.Field_API_Name__c != null && rc.Field_API_Name__c.equalsIgnoreCase('RecordTypeId')){
                      rc.Matching_Value__c = rc.Record_Type_Id__c;                      
                  }

                   //Boolean deleteAllow = FilterWrapper.size()==0 ?false:true;
                   Boolean deleteAllow = FilterWrapper.size()==0 ?true:true;
                   FilterWrapper.add(new filterwrap(deleteAllow,'',rc,FilterWrapper.size()+1));
                   populatefield(rc.Related_Object__c,FilterWrapper.size()-1);
                    
                   parentField=rc.Field_Name__c;
                   index=':'+string.valueof(FilterWrapper.size()-1)+':';
                   parentOperator=rc.Matching_Type__c;

                   populateOperator();                   
                   index=':'+string.valueof(FilterWrapper.size()-1)+':';
                   togglebtw();
                    
                   Integer i =FilterWrapper.size()-1;
                   if((FilterWrapper[i].ismultiselect || FilterWrapper[i].isPicklist || FilterWrapper[i].isGlobalVariable) && FilterWrapper[i].newrulecriteria.Matching_Value__c!=null){
                        //lets deal it later
                        system.debug('newrulecriteria.Matching_Value__c-->'+FilterWrapper[i].newrulecriteria.Matching_Value__c);
                         //  pgb??  list<string> valueList = FilterWrapper[i].newrulecriteria.Matching_Value__c.split(',',20);
                        // list<string> valueList = FilterWrapper[i].newrulecriteria.Matching_Value__c.split(escsapeplitdelimeter,20);
                           list<string> valueList = FilterWrapper[i].newrulecriteria.Matching_Value__c.split(escsapeplitdelimeter);
                        for(string c:valueList){
                            c=c.trim();
                            FilterWrapper[i].picklistvalues.add(c);
                        }
                        system.debug('picklistvalues-->'+FilterWrapper[i].picklistvalues);
                   }
                   
              }//end for
             system.debug('FilterWrapper-->'+FilterWrapper);
         }
         
         private list<RuleCriteria__C>  getRuleCriteria(){
             return [select id,Rule__c,RuleObjectType__c, Related_Object__c,Field_API_Name__c, Field_Name__c, Record_Type_Id__c,
                                     CrossFormula__c,Matching_Type__c,Minimum_Value__c,Maximum_Value__c, Matching_Value__c ,Evaluate_Criteria_Result_To__c
                                     ,Evaluate_ChildCriteria_Using__c 
                                     from RuleCriteria__C 
                                     where Rule__c=:ruleId order by Name, CreatedDate ASC];
         }
         
       public Pagereference Cancel(){
            pagereference pg = new pagereference ('/'+RuleId);
            return pg;
       }
       
       public PageReference renderOnly(){ 
         index=index.substringBeforeLast(':');
        index=index.substringAfterLast(':');
        FilterWrapper.get(integer.valueof(index)).newRuleCriteria.CrossFormula__c = parentField;
        return null;
       }
         
        public void populateFields(){
            index1=index1.substringBeforeLast(':');
            index1=index1.substringAfterLast(':');
            if(index1!=''&&index1!=null)
                populateField(parentObj,integer.valueof(index1));
        }
        
        public void populateOwnerName(){
            index=index.substringBeforeLast(':');
            index=index.substringAfterLast(':');
            System.debug('::FilterWrapper'+FilterWrapper);
            System.debug('::index'+index);
            System.debug(':OwnerId:'+ownerId);
            if(FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Api_Name__c != null && FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Api_Name__c.equalsIgnorecase('ownerName') && ownerId != null){
                for(User usr : [select id, Name from User where id = : ownerId AND isActive = true]){
                    FilterWrapper.get(integer.valueof(index)).ownerName = usr.Name;
                }
            }
            System.debug('::FilterWrapper after'+FilterWrapper);
            if(OwnerId != null){
                FilterWrapper.get(integer.valueof(index)).sobj.put('ownerId' , ownerId);
            }

        }

     private map<string, SObjectField>getLowerMapKeys(map<string, SObjectField> sampleMap){
            map<string, SObjectField> lowerKeyMap = new map<string, SObjectField>();
             for(String keyL : sampleMap.keyset()){
               /* system.debug('-->keyL '+keyL);
                system.debug('-->sampleMap.get(keyL) '+sampleMap.get(keyL));
                system.debug('-->sampleMap.get(keyL).toLowerCase() '+sampleMap.get(keyL));
                */
                Schema.SObjectField sfield = sampleMap.get(keyL.toLowerCase());
                Schema.DescribeFieldResult descResField = sfield.getDescribe();
                String fieldAPIName = descResField.getName().toLowerCase();
                lowerKeyMap.put(fieldAPIName, sampleMap.get(keyL));
             }
            return lowerKeyMap;
        }
       
        private void populateField(string parent, integer pos ){

             List<SelectOption> fieldOption= new List<SelectOption>();
             Schema.SObjectType sobjTypeParent = gd.get(parent);
             //new line -added .toLowerCase bug start
             if (sobjTypeParent == null){
                sobjTypeParent = gd.get(parent.toLowerCase());
             }
             
             Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
            // mapField = parentObjFields.fields.getMap();
              mapField = getLowerMapKeys(parentObjFields.fields.getMap());
             
             fieldOption.add(new SelectOption('','--Select--'));
             for(String fieldname:mapField.keySet()){
                Schema.SObjectField sfield = mapField.get(fieldname.toLowerCase());
                Schema.DescribeFieldResult descResField = sfield.getDescribe();
                String fieldLabel = descResField.getLabel();
                String fieldAPIName = descResField.getName();
                 
                 
                if(fieldAPIName.equalsIgnoreCase('RecordTypeID')){
                  //pgb11 fieldOption.add(new SelectOption('Record Type Name',fieldAPIName));
                   if(fieldOption.size() == 1000){
                    fieldOption.add(new SelectOption('Record Type Name',fieldAPIName));
                    fieldOption = new List<SelectOption>();
                   } else  fieldOption.add(new SelectOption('Record Type Name',fieldAPIName));
                   
                }

                // Owner name change
                // Start
              else if(fieldAPIName.equalsIgnoreCase('ownerid')){
                   if(fieldOption.size() == 1000){
                    fieldOption.add(new SelectOption('Owner Name','OwnerName'));
                    fieldOption = new List<SelectOption>();
                    fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                 }else 
                 {
                   fieldOption.add(new SelectOption('Owner Name','OwnerName'));
                     if(fieldOption.size() == 1000){
                       fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                       fieldOption = new List<SelectOption>();
                     }else fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                 }
              }
                else{
                  if(fieldOption.size() == 1000){
                       fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                       fieldOption = new List<SelectOption>();
                  } else  fieldOption.add(new SelectOption(fieldLabel,fieldAPIName));
                }
                // End
           
                //to add field types
               // Fieldtypemap.put(descResField.getName(),string.valueof(sfield.getDescribe().gettype()));
                 Fieldtypemap.put(descResField.getName().toLowerCase(),string.valueof(sfield.getDescribe().gettype()));
          
            }
            if(parent!=null)
             FilterWrapper.get(pos).newRuleCriteria.Related_Object__c=parent;
            FilterWrapper.get(pos).fieldOptions.clear();
            fieldOption.add(new SelectOption('Cross Formula','CrossFormula'));
            fieldOption.add(new SelectOption('Global Variable - User','GlobalVariable-User'));
            fieldOption.add(new SelectOption('Global Variable - Profile','GlobalVariable-Profile'));
            fieldOption.add(new SelectOption('Global Variable - UserRole','GlobalVariable-UserRole'));
            fieldOption.add(new SelectOption('Global Variable - Organization','GlobalVariable-Organization'));
            fieldOption.SORT();
            List<SelectOption> sortedfieldOption= new List<SelectOption>();
            for(SelectOption opt : fieldOption){
               sortedfieldOption.add(new SelectOption(opt.getLabel(),opt.getValue())); 
            }
            FilterWrapper.get(pos).fieldOptions.addall(sortedfieldOption);
        }
        
         public  void togglebtw(){
            index=index.substringBeforeLast(':');
            index=index.substringAfterLast(':');
            if(index!=''){
              // Reset isBetween to false
              FilterWrapper.get(integer.valueof(index)).isBetween = false;
                String fieldName=FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Api_Name__c;
                // Added condition
                // Owner name change

                if(fieldName!='CrossFormula' && !fieldName.startsWith('GlobalVariable') && !fieldName.equalsIgnoreCase('OwnerName')){
                
                 //   DisplayType fieldtype=mapField.get(fieldName.toLowerCase()).getDescribe().gettype();
                   DisplayType fieldtype=mapField.get(FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Api_Name__c.toLowerCase()).getDescribe().gettype();
                    system.debug('-->togglebtw 4 fieldtype '+ fieldtype );
                    if(fieldType==Schema.DisplayType.MultiPicklist||fieldType==Schema.DisplayType.Picklist){
                        FilterWrapper.get(integer.valueof(index)).isPicklist = true;
                    }
                    if(fieldType==Schema.DisplayType.Boolean){
                        FilterWrapper.get(integer.valueof(index)).isBoolean = true;
                    }

                }else if(fieldName.startsWith('GlobalVariable')){
                     FilterWrapper.get(integer.valueof(index)).isGlobalVariable = true;
                }
            }
            if(index!='' && (parentOperator=='Between' || parentOperator=='Not Between')){
                   FilterWrapper.get(integer.valueof(index)).isBetween=true;  
            }
           else if(index!='' && parentOperator.equalsIgnoreCase('ChangedFromTo')){
               if(FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Matching_Value__c == ''){
                  FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Matching_Value__c = 'old value,new value';  
               }
               FilterWrapper.get(integer.valueof(index)).isPicklist = false;
                FilterWrapper.get(integer.valueof(index)).ismultiselect=false;
                FilterWrapper.get(integer.valueof(index)).isBoolean = false;
            }
              // Do not show value for is null and is not null
             else if(index!='' && (parentOperator.equalsIgnoreCase('isChanged') || parentOperator.equalsIgnoreCase('Is Null') || parentOperator.equalsIgnoreCase('Is Not Null'))){
               FilterWrapper.get(integer.valueof(index)).isPicklist = false;
                FilterWrapper.get(integer.valueof(index)).ismultiselect=false;
                FilterWrapper.get(integer.valueof(index)).isbetween = false;
                FilterWrapper.get(integer.valueof(index)).isCrossFormula = FilterWrapper.get(integer.valueof(index)).isCrossFormula; // fixed Crossformula issue Megha
                FilterWrapper.get(integer.valueof(index)).isGlobalVariable =false;
                FilterWrapper.get(integer.valueof(index)).isBoolean = false;
                FilterWrapper.get(integer.valueof(index)).isOwnerField = false;
               
            }
            else if(index!=''&&(parentOperator =='='||parentOperator=='!=')&& FilterWrapper.get(integer.valueof(index)).isPicklist==true){
                FilterWrapper.get(integer.valueof(index)).ismultiselect=false;
                FilterWrapper.get(integer.valueof(index)).isPicklist = true;
          }
            else if(index!=''&&(parentOperator!='='||parentOperator!='!=')&&FilterWrapper.get(integer.valueof(index)).isPicklist==true){
                FilterWrapper.get(integer.valueof(index)).ismultiselect=true;
            }
            else if(index!=''&&(parentOperator =='Not Equal To'||parentOperator=='Equals') && (
              FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Name__c.equalsIgnoreCase('OwnerName') || FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Field_Name__c.equalsIgnoreCase('OwnerId'))
            ){
                FilterWrapper.get(integer.valueof(index)).isOwnerField = true;
                if(FilterWrapper.get(integer.valueof(index)).sobj == null)
                    FilterWrapper.get(integer.valueof(index)).sobj = gd.get(ruleRecord.Object__c.toLowerCase()).newSObject();
            }
            else if(index!=''&&index!=null){
              FilterWrapper.get(integer.valueof(index)).isBetween=false; 
              FilterWrapper.get(integer.valueof(index)).ismultiselect=false;
             // 8-15-14 To fix the issue of not displaying correctly the checkbox during update criteria
             // FilterWrapper.get(integer.valueof(index)).isBoolean=false;
          
            }
            if(index!='' && (parentOperator!='Between' && parentOperator !='Not Between')){                
                FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Minimum_Value__c = '';
                FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Maximum_Value__c = '';                
            }
            FilterWrapper.get(integer.valueof(index)).newRuleCriteria.Matching_Type__c=parentOperator;
            system.debug('Wrapper: '+FilterWrapper.get(integer.valueof(index)));
        }   
   
        public void addmorefilter(){
            RuleCriteria__c rc = new RuleCriteria__c();
            FilterWrapper.add(new filterwrap(true,'',rc,FilterWrapper.size()+1));
            populateField(ruleRecord.Object__c,FilterWrapper.size()-1);
            //verified=TRUE;
            addDefaultFilterLogic();
        }
         
        
        public void deletefilter(){
            if(toremovecounter>0){
                deletewrapper.add(FilterWrapper.get(toremovecounter-2));
                FilterWrapper.remove(toremovecounter-2);
                addDefaultFilterLogic();
            }
        }
        
        private void addDefaultFilterLogic(){
            if(oldFilterValue == RuleRecord.Filter_Logic__c){
                    Integer criteriaCount  = FilterWrapper.size();
                    String filterLogic = '1';
                    for(Integer i = 1;i<criteriaCount;i++){
                        filterLogic += ' AND ' + (i+1);  
                    }
                    RuleRecord.Filter_Logic__c = filterLogic; 
                    oldFilterValue = RuleRecord.Filter_Logic__c;                                
                }  
        }
        
        public void populateOperator(){

            index=index.substringBeforeLast(':');
            index=index.substringAfterLast(':');
        
            if(index=='' || index==null || parentField=='' || parentField==null)
                return;
                Integer listindex = integer.Valueof(index);
                List<SelectOption> options = new List<SelectOption>();
                if(parentField=='CrossFormula' || parentField.startsWith('GlobalVariable')){
                    FilterWrapper.get(listindex).isCrossFormula = parentField=='CrossFormula'? true:false;
                    FilterWrapper.get(listindex).isGlobalVariable = parentField.startsWith('GlobalVariable')?true:false;
                    FilterWrapper.get(listindex).isPicklist = false;
                    FilterWrapper.get(listindex).isOwnerField = false;
                    FilterWrapper.get(listindex).isMultiselect = false;
                    FilterWrapper.get(listindex).isbetween = false;
                    FilterWrapper.get(listindex).isBoolean = false;
                    
                    options.add(new selectOption('Equals','Equals')); 
                    options.add(new selectOption('Not Equal To','Not Equal To'));
                    options.add(new selectOption('Is Null','Is Null'));
                    options.add(new selectOption('Is Not Null','Is Not Null'));
                    options.add(new selectOption('Contains','Contains')); 
                    options.add(new selectOption('Does Not Contain','Does Not Contain')); 
                    options.add(new selectOption('Starts With','Starts With')); 
                    options.add(new selectOption('Ends With','Ends With')); 
                    options.add(new selectOption('Does Not Start With','Does Not Start With')); 
                    options.add(new selectOption('Does Not End With','Does Not End With')); 
                    options.add(new selectOption('Includes','Includes')); 
                    options.add(new selectOption('Excludes','Excludes')); 
                    //options.add(new selectOption('Regular Expression','Regular Expression')); 
                    FilterWrapper.get(listindex).operators.clear();
                    FilterWrapper.get(listindex).operators.addall(options);
                    FilterWrapper.get(listindex).newRuleCriteria.Field_Name__c=parentField;
                    FilterWrapper.get(listindex).newRuleCriteria.field_API_name__c = parentField;
                    FilterWrapper.get(listindex).newRuleCriteria.field_type__c =  'String';

                  /*
                     if(parentField=='CrossFormula')
                        FilterWrapper.get(listindex).newRuleCriteria.matching_value__c=  '';
                    */
                    //if the field is global variable 
                    if(parentField.startsWith('GlobalVariable') ){
                           FilterWrapper.get(listindex).newRuleCriteria.GlobalVariable__c = parentField.split('-')[1];    
                           FilterWrapper.get(listindex).ValueOption.clear();                      
                           FilterWrapper.get(listindex).ValueOption.addall(getGlobalVarValues(FilterWrapper.get(listindex).newRuleCriteria.GlobalVariable__c));
                           FilterWrapper.get(listindex).isGlobalVariable=true;
                             
                    }
                    return;
                }
             
               // Owner name change
               // Added condition
               //Start
                 system.debug('-->parentField  '+parentField);
               system.debug('-->mapField  '+mapField);
               system.debug('-->mapField.get(parentField.toLowerCase()) '+mapField.get(parentField.toLowerCase()));
               system.debug(':::::::::::::::parentObj::::::'+parentObj);
                system.debug(':::::::::::::::FilterWrapper.get(listindex).newRuleCriteria::::::'+FilterWrapper.get(listindex).newRuleCriteria); 
                if((mapField.get(parentField.toLowerCase()))==null && !parentField.equalsIgnoreCase('OwnerName')){
              // if((mapField.get(parentField))==null && !parentField.equalsIgnoreCase('OwnerName')){
                    return;
               }
               String DisplayMatchingType='';
               DisplayType fieldtype;  
               if(!parentField.equalsIgnoreCase('OwnerName')){
                  //fieldtype = mapField.get(parentField).getDescribe().gettype();
                  fieldtype = mapField.get(parentField.toLowerCase()).getDescribe().gettype();
               }
               else{
                 fieldType = Schema.DisplayType.Reference;
               }
                // End
                if (FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c !=null ) DisplayMatchingType=FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c;
                if (fieldType!=Schema.DisplayType.anyType && fieldType!=Schema.DisplayType.base64  && fieldType!=Schema.DisplayType.EncryptedString && fieldType!=Schema.DisplayType.Id )
                {
                      FilterWrapper.get(listindex).isCrossFormula = false;
                      if (DisplayMatchingType != '' ) options.add(new selectOption(DisplayMatchingType, DisplayMatchingType)); 
                      if (DisplayMatchingType != 'Equals') options.add(new selectOption('Equals','Equals')); 
                      if (DisplayMatchingType != 'Not Equal To') options.add(new selectOption('Not Equal To','Not Equal To')); 
                      if (DisplayMatchingType != 'Is Null') options.add(new selectOption('Is Null','Is Null')); 
                      if (DisplayMatchingType != 'Is Not Null') options.add(new selectOption('Is Not Null','Is Not Null')); 
                     
                      // CC
                      if (DisplayMatchingType != 'IsChanged') options.add(new selectOption('IsChanged','IsChanged')); 
                      if (DisplayMatchingType != 'ChangedFromTo') options.add(new selectOption('ChangedFromTo','ChangedFromTo')); 
                    
                      FilterWrapper.get(listindex).isPicklist = false;
                      FilterWrapper.get(listindex).isMultiselect = false;
                      FilterWrapper.get(listindex).isBoolean = false;
                      FilterWrapper.get(listindex).isOwnerField = false;
                      if(fieldType==Schema.DisplayType.Boolean)
                        FilterWrapper.get(listindex).isBoolean = true;
                      if ( fieldType!=Schema.DisplayType.String && fieldType!=Schema.DisplayType.MultiPicklist  && fieldType!=Schema.DisplayType.Email && fieldType!=Schema.DisplayType.Boolean && fieldType!=Schema.DisplayType.Picklist && fieldType!=Schema.DisplayType.Reference && fieldType!=Schema.DisplayType.TextArea){
                          //boolean can't use the below, but the others can
                          if (DisplayMatchingType != 'Greater Than') options.add(new selectOption('Greater Than','Greater Than')); 
                          if (DisplayMatchingType != 'Less Than') options.add(new selectOption('Less Than','Less Than')); 
                          if (DisplayMatchingType != 'Greater or Equal') options.add(new selectOption('Greater or Equal','Greater or Equal')); 
                          if (DisplayMatchingType != 'Less or Equal') options.add(new selectOption('Less or Equal','Less or Equal')); 
                          if (DisplayMatchingType != 'Between') options.add(new selectOption('Between','Between')); 
                          if (DisplayMatchingType != 'Not Between') options.add(new selectOption('Not Between','Not Between')); 
                        if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c == 'Between' || FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c == 'Not Between'){
                            FilterWrapper.get(listindex).isbetween = true;
                          }
                      }
                      else{
                          FilterWrapper.get(listindex).isbetween = false;
                      }
                      
                      if ( fieldType==Schema.DisplayType.String || fieldType==Schema.DisplayType.Email ||fieldType==Schema.DisplayType.Reference|| fieldType==Schema.DisplayType.ComboBox ||fieldType==Schema.DisplayType.Picklist ||fieldType==Schema.DisplayType.email|| fieldType==Schema.DisplayType.Phone||fieldType==Schema.DisplayType.url || fieldType==Schema.DisplayType.TextArea ){//if 4
                           //these opOption are for string type fields
                            if (DisplayMatchingType != 'Contains') options.add(new selectOption('Contains','Contains')); 
                            if (DisplayMatchingType != 'Does Not Contain') options.add(new selectOption('Does Not Contain','Does Not Contain')); 
                            if (DisplayMatchingType != 'Starts With') options.add(new selectOption('Starts With','Starts With')); 
                            if (DisplayMatchingType != 'Ends With') options.add(new selectOption('Ends With','Ends With')); 
                            if (DisplayMatchingType != 'Does Not Start With') options.add(new selectOption('Does Not Start With','Does Not Start With')); 
                            if (DisplayMatchingType != 'Does Not End With') options.add(new selectOption('Does Not End With','Does Not End With')); 
                            if (DisplayMatchingType != 'Includes') options.add(new selectOption('Includes','Includes')); 
                            if (DisplayMatchingType != 'Excludes') options.add(new selectOption('Excludes','Excludes')); 
                            
                            //options.add(new selectOption('Regular Expression','Regular Expression')); 
                            
                            if(fieldType==Schema.DisplayType.Phone){
                                 if (DisplayMatchingType != 'Greater Than')  options.add(new selectOption('Greater Than','Greater Than')); 
                                 if (DisplayMatchingType != 'Greater or Equal') options.add(new selectOption('Greater or Equal','Greater or Equal')); 
                            }
                            
                      }
                     
                       if(fieldType==Schema.DisplayType.MultiPicklist||fieldType==Schema.DisplayType.Picklist ){
                          //Start Bug Fix: Values on appearing for Product Interest& object got changed
                          //commented the line below as name of Related_Object__c should not change but used .toLowerCase for indexing FilterWrapper
                         // FilterWrapper.get(listindex).newRuleCriteria.Related_Object__c = FilterWrapper.get(listindex).newRuleCriteria.Related_Object__c.toLowerCase();
                          
                          if(gd.get(FilterWrapper.get(listindex).newRuleCriteria.Related_Object__c.toLowerCase())!=null){   
                              FilterWrapper.get(listindex).ValueOption.clear();                      
                              FilterWrapper.get(listindex).ValueOption.addall(getPicklistValues(gd.get(FilterWrapper.get(listindex).newRuleCriteria.Related_Object__c.toLowerCase()), ParentField));
                         //End Bug Fix: Values on appearing for Product Interest& object got changed     
                              FilterWrapper.get(listindex).isPicklist=true;
                          }    
                      }
                   }  
               
                // Owner name change
                // Start
                if(parentField.equalsIgnoreCase('ownerid')){
                    FilterWrapper.get(listindex).isPicklist = false;   
                    FilterWrapper.get(listindex).isOwnerField = true;
                    if(FilterWrapper.get(listindex).sobj == null)
                        FilterWrapper.get(listindex).sobj = gd.get(ruleRecord.Object__c.toLowerCase()).newSObject();  
                    if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c != null && FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c != '' && FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c.startsWith('005')){
                        FilterWrapper.get(listindex).sobj.put('ownerId' , FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c);
                    }            
                    FilterWrapper.get(listindex).ValueOption.clear();                      
                    //FilterWrapper.get(listindex).ValueOption.addall(getGlobalVarValues('User.Id'));
                }
                else if(parentField.equalsIgnoreCase('ownername') && (parentOperator =='Not Equal To'||parentOperator=='Equals')){
                    FilterWrapper.get(listindex).isPicklist = false;
                    FilterWrapper.get(listindex).isOwnerField = true;
                    if(FilterWrapper.get(listindex).sobj == null)
                        FilterWrapper.get(listindex).sobj = gd.get(ruleRecord.Object__c.toLowerCase()).newSObject();
                    if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c != null && FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c != ''){
                        for(User usr : [select id from User where Name = : FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c]){
                            FilterWrapper.get(listindex).sobj.put('ownerId' , usr.id);
                        }
                    }
                    FilterWrapper.get(listindex).ValueOption.clear();                      
                    //FilterWrapper.get(listindex).ValueOption.addall(getGlobalVarValues('User'));
                }
                //End
                   FilterWrapper.get(listindex).operators.clear();
                   FilterWrapper.get(listindex).operators.addall(options);
                   FilterWrapper.get(listindex).newRuleCriteria.Field_Name__c=parentField;
                   FilterWrapper.get(listindex).newRuleCriteria.field_API_name__c = parentField;
                   FilterWrapper.get(listindex).newRuleCriteria.field_type__c =  string.valueof(fieldType);
                   
                if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c == 'ChangedFromTo'){
                      FilterWrapper.get(listindex).isPickList = false; 
                      FilterWrapper.get(listindex).ismultiselect = false;
                      FilterWrapper.get(listindex).isBoolean = false;
                      if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c == ''){
                      FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c = 'old value,new value';  
                   } 
                   }
                   else if(FilterWrapper.get(listindex).newRuleCriteria.Matching_Type__c == 'IsChanged'){
                        FilterWrapper.get(listindex).isPicklist = false;
                        FilterWrapper.get(listindex).ismultiselect=false;
                        FilterWrapper.get(listindex).isbetween = false;
                        FilterWrapper.get(listindex).isCrossFormula =false;
                        FilterWrapper.get(listindex).isBoolean = false;
                   }
                   if(parentField.equalsIgnoreCase('recordtypeid')){
                        FilterWrapper.get(listindex).isPicklist = true;
                        FilterWrapper.get(listindex).ValueOption.clear();                      
                           FilterWrapper.get(listindex).ValueOption.addall(getRecordTypeOptions(FilterWrapper.get(listindex).newRuleCriteria.Related_Object__c));
                   }
                   //one imp thing
                   if(ApexPages.currentPage().getParameters().get('AJAXREQUEST')!=null)
                       FilterWrapper.get(listindex).newRuleCriteria.Matching_Value__c='';
        }//end operators
        
         // cc - 30th Sep
        
        public List<SelectOption> getRecordTypeOptions(String sObjName){
            List<SelectOption> options = new List<SelectOption>();
            for(RecordType recType : [select id, name from RecordType where SobjectType =: sObjName ]){
                options.add(new SelectOption(recType.Id,recType.Name));
                mapRectypeIdRecName.put(recType.Id,recType.Name);
            }
            return options;
        }
        
      public Boolean ValidateCrossFormulafields(){
        String soql='SELECT ';
        String field='';
        String obj ='';
            
        try{
            for(filterwrap fw: filterwrapper){
        //  system.debug('-->ValidateCrossFormulafieldsPGB1  '+fw);
       //   system.debug('-->ValidateCrossFormulafieldsPGB1  '+fw.newRuleCriteria.Field_API_Name__c);
           if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('CrossFormula')){
        //      system.debug('-->CrossFormula'+fw.newRuleCriteria.CrossFormula__c);
       //       system.debug('-->CrossFormula Related_Object__c'+fw.newRuleCriteria.Related_Object__c);
                if ( obj== null || obj=='' ) obj= fw.newRuleCriteria.Related_Object__c;
                if ( field== null || field=='') field= fw.newRuleCriteria.CrossFormula__c;
              // else field=field+','+fw.newRuleCriteria.CrossFormula__c;
              else if  (!field.contains(fw.newRuleCriteria.CrossFormula__c) ) field=field+','+fw.newRuleCriteria.CrossFormula__c;
            soql=soql+field+ ' FROM '+obj+' LIMIT 1';
                 system.debug('->soql' +soql);
                List<SObject> record = database.query(soql);
                 soql='SELECT ';
               } 
            }
           }catch(Exception e){
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Cross Formula value is not supported. Check WSDL '));
                return false;
            } 
     return true;
    }
  
        //add methods
        
         public pagereference save(){
            addDefaultFilterLogic();
             if(!validatefilterCritera() || !CreateFilterDisplay() || !doLimitValidations() || !ValidateCrossFormulafields()){
                return null;
            }
             List<RuleCriteria__c> toInsert = new List<RuleCriteria__c>();
            List<RuleCriteria__c> toDelete = new List<RuleCriteria__c>();
            
            for(filterwrap fw: filterwrapper){
                  if(fw.newRuleCriteria.rule__c==NULL)
                      fw.newRuleCriteria.rule__c=RuleRecord.id;
                        
                  if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('RecordTypeId')){
                      fw.newRuleCriteria.Record_Type_Id__c = fw.newRuleCriteria.Matching_Value__c;
                      //pgb??     List<String> lstRecIdList = fw.newRuleCriteria.Record_Type_Id__c.split(',');
                         List<String> lstRecIdList = fw.newRuleCriteria.Record_Type_Id__c.split(escsapeplitdelimeter);
                   String machingVal = '';
                      if(lstRecIdList != null && lstRecIdList.size() >0){
                        for(String recId: lstRecIdList){
                          //machingVal += mapRectypeIdRecName.get(recId) + ',';
                            machingVal += mapRectypeIdRecName.get(recId) + splitdelimeter;  
                              
                        }
                        machingVal = machingVal.substring(0,machingVal.length()-1);
                        fw.newRuleCriteria.Matching_Value__c = machingVal;
                      }
                      
                  }
                  if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('ownerId') && fw.isOwnerField){
                     fw.newRuleCriteria.Matching_Value__c = (String)fw.sobj.get('OwnerId');
                  }
                  if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('ownerName') && fw.isOwnerField){
                    fw.newRuleCriteria.Matching_Value__c = fw.ownerName != null ? fw.ownerName : (String)fw.sobj.get('OwnerId');
                  }
                  if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('ownerId') && fw.isOwnerField){
                     fw.newRuleCriteria.Matching_Value__c = (String)fw.sobj.get('OwnerId');
                  }
                  if(fw.newRuleCriteria.Field_API_Name__c.equalsIgnoreCase('ownerName') && fw.isOwnerField){
                    fw.newRuleCriteria.Matching_Value__c = fw.ownerName != null ? fw.ownerName : (String)fw.sobj.get('OwnerId');
                  }
                  toInsert.add(fw.newRuleCriteria);
              }
              
              if(deletewrapper!=null && deletewrapper.size()>0){
                  for(filterwrap fw: deletewrapper){
                     if(fw.newRuleCriteria.id!=null)
                          toDelete.add(fw.newRuleCriteria);
                  }
                  delete toDelete;
              }
              
            try{
                upsert toInsert;
                String formatedFilterLogic=ruleRecord.Filter_Logic__c;
                ruleRecord.Filter_Logic__c= Convert(formatedFilterLogic);
                for(integer i =toInsert.size(); i>0;i--){
                   formatedFilterLogic= formatedFilterLogic.replace(string.valueof(i),' #'+string.valueof(i)+'# ');
                }
               for(integer i =toInsert.size(); i>0;i--){
                  formatedFilterLogic= formatedFilterLogic.replace(' #'+string.valueof(i)+'# ',' '+(toInsert[i-1].id)+' ');
               }
               ruleRecord.formattedFilterLogic__c=formatedFilterLogic;
                update ruleRecord;
                pagereference  pg = new pagereference('/'+ruleRecord.id);
                return pg;
            }catch(Exception e){
                ApexPages.addMessages(e);
            }
            return null;
        }
        
        public Boolean doLimitValidations(){
            Integer Count =[Select Count() FROM RuleCriteria__c  WHERE Rule__c =: ruleId ];
            Count = Count+filterwrapper.size();
            Map<String,Advance_Workflow_Limits__c> lims = Advance_Workflow_Limits__c.getAll();
            
            if( lims.get('NumCriteriaperRule')!=null && lims.get('NumCriteriaperRule').Value__c < Decimal.valueOf(Count)){
                        ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.FATAL,'Criteria Limit of '+lims.get('NumCriteriaperRule').Value__c+' Exceeded'));
                        return false;
            }                       
            
            AggregateResult[] groupedResults2 =[Select Field_API_Name__c,Count(ID) FROM RuleCriteria__c  WHERE Rule__c =: ruleId GROUP BY Field_API_Name__c];
            for (AggregateResult ar : groupedResults2)  {
                    if(ar.get('Field_API_Name__c')=='CrossFormula' && lims.get('NumCriteriaCrossFormulafieldsperRule')!=null && lims.get('NumCriteriaCrossFormulafieldsperRule').Value__c < Decimal.valueOf(String.valueOf(ar.get('expr0')))){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Cross Formula Field Limit of '+lims.get('NumCriteriaCrossFormulafieldsperRule').Value__c+' Exceeded'));
                        return false;
                    }                                       
            }
            return true;
        }
        //add methods

        public boolean validatefilterCritera(){
                string patterns;
                if(RuleRecord.Filter_Logic__c=='' || RuleRecord.Filter_Logic__c==null ){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please define a filter criteria!'));
                    return false;
                }
                
               //original  Pattern listPattern = Pattern.compile('(\\(\\([0-9]|\\([0-9]|[0-9]|[1-9][0-9]|[0-9]|[0-9]\\)\\)|[0-9]\\))(((\\s(AND|OR)\\s)|(AND|OR))(\\(\\([0-9]|\\([0-9]|[0-9]|[1-9][0-9]|[1-9]|[0-9]\\)\\)|[0-9]\\)))*(\\))*');
                Pattern listPattern = Pattern.compile('((\\()*[1-9][0-9]|[1-9][0-9]|(\\()*[1-9]|[1-9]|[1-9](\\))*|[1-9][0-9](\\))*)(((\\s(AND|And|Or|OR|and|or)\\s)|(AND|And|Or|OR|and|or))((\\()*[1-9][0-9]|[1-9][0-9]|(\\()*[1-9]|[1-9]|[1-9](\\))*|[1-9][0-9](\\))*))*(\\))*');
                RuleRecord.Filter_Logic__c = RuleRecord.Filter_Logic__c.replaceAll('and','AND');
                RuleRecord.Filter_Logic__c = RuleRecord.Filter_Logic__c.replaceAll('or','OR');
                
                patterns=RuleRecord.Filter_Logic__c.trim();
                patterns = patterns.replaceall(' ','');
                Matcher matcher = listPattern.matcher(patterns);
                
                //error encountered
                if(matcher.matches()== false){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Wrong Format! Follow  format eg:1AND(3OR4)'));
                    return false;
                }
                
                if(ruleRecord.Filter_Logic__c.countMatches('(')!=RuleRecord.Filter_Logic__c.countMatches(')')){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Left and Right Parethisis not correct!'));
                        return false;
                } 
                if(RuleRecord.Filter_Logic__c!=''&&RuleRecord.Filter_Logic__c!=null)
                {
                    string NumberPattern ='(ANDOR )';
                    for(integer i=1;i<=FilterWrapper.size();i++){
                                NumberPattern +=i;
                    }
                    if(RuleRecord.Filter_Logic__c.indexOfAnyBut(NumberPattern)< 0){
                            Boolean valuechk=true;
                            for(filterwrap fw:FilterWrapper){
                              // Megha - added isChanged also in this
                                 if( fw.newRuleCriteria.Matching_Value__c==null  && !( fw.newRuleCriteria.Matching_Type__c=='Is Not Null'||fw.newRuleCriteria.Matching_Type__c=='Is Null' || fw.newRuleCriteria.Matching_Type__c == 'IsChanged') && ((fw.newRuleCriteria.Maximum_Value__c=='' ||fw.newRuleCriteria.Maximum_Value__c==NULL) && fw.newRuleCriteria.Minimum_Value__c==''))
                                 {
                                    system.debug('-->Field_Name__c  '+fw.newRuleCriteria.Field_Name__c ); 
                                    system.debug('--> Matching_Type__c '+ fw.newRuleCriteria.Matching_Type__c);
                                   system.debug('-->Inside  Matching_Value__c '+fw.newRuleCriteria.Matching_Value__c );
                                   
                                     valuechk=false; break;
                                     if(fw.newRuleCriteria.Field_Name__c==null||fw.newRuleCriteria.Field_Name__c=='None')
                                     {
                                         valuechk=false; break;
                                        if(fw.newRuleCriteria.Matching_Type__c==null||fw.newRuleCriteria.Matching_Type__c=='None'){
                                            valuechk=false; break;
                                        }  
                                     }   
                                 }
                            }
                            if(valuechk==false){
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Rule Criteria Value, Operator and field Cannot be blank!! '));          return false;
                            }
                            
                            if(!Test.isrunningtest()){
                                 for(integer i=1;i<=FilterWrapper.size();++i){
                                    NumberPattern +=i;
                                    if(RuleRecord.Filter_Logic__c.indexof(string.valueof(i)) < 0){
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ' All Rule Criteria need to be referenced in filter logic '));
                                        return false;
                                    }
                                    if(filterWrapper[i-1].newRuleCriteria.Matching_Type__c != null && filterWrapper[i-1].newRuleCriteria.Matching_Type__c.equalsIgnoreCase('ChangedFromTo')){
                                        if(filterWrapper[i-1].newRuleCriteria.Matching_value__c != null && !filterWrapper[i-1].newRuleCriteria.Matching_value__c.contains(',')){
                                             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Expected from and to (old value,new value) in value for Changed From To operator'));
                                             return false;
                                        }
                                    }
                                }
                            }
                            
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Syntax verified! '));
                    }
                    else{
                             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Number associated to the Rule Criteria not found! '));
                             return false;
                        }
                }
                 return true; 
       } 
       
          /*Function to create a proper formatted filter logic and display filter logic based on the filter criteria written by user.*/
    private boolean CreateFilterDisplay(){

        system.debug('-->CreateFilterDisplay 1' );
        string formatedFilterLogic;
        string DisplayFilterLogic;
        String fullRuleCriteria;
        List<string> formattedlist = new List<string>();
        Set<string> formattedSet = new Set<string>();
        for(filterwrap fw: filterwrapper)
        {
            if(fw.picklistvalues!=null && (fw.isPicklist==true || fw.ismultiselect==true || fw.isGlobalVariable==true)){
               system.debug('--->fw.picklistvalues'+fw.picklistvalues);
               //pgb??  fw.newRuleCriteria.Matching_Value__c = String.join(fw.picklistvalues,',');
              // fw.newRuleCriteria.Matching_Value__c = String.join(fw.picklistvalues,'|');
               fw.newRuleCriteria.Matching_Value__c = String.join(fw.picklistvalues,splitdelimeter);
            }
            if(fw.newRuleCriteria.Field_Name__c=='Cross Formula'){
                formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.CrossFormula__c +' = ' +fw.newRuleCriteria.Matching_Value__c;
            }
            
            else{ 
                if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('isChanged')){
                    formatedFilterLogic= fw.newRuleCriteria.Matching_Type__c + '('+fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +')';
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('ChangedFromTo')){
                    formatedFilterLogic= fw.newRuleCriteria.Matching_Type__c+'('+fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +'(old value,new value) - ('+fw.newRuleCriteria.Matching_Value__c+'))';
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Equals')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' = ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Not Equal To')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' != ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Starts With')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' LIKE ' +fw.newRuleCriteria.Matching_Value__c+'%';
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Ends With')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' LIKE '+'%' +fw.newRuleCriteria.Matching_Value__c;
                }
                 else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Does Not Start With')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' NOT LIKE ' +fw.newRuleCriteria.Matching_Value__c+'%';
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Does Not End With')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' NOT LIKE '+'%' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Contains')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' LIKE ' +'%'+fw.newRuleCriteria.Matching_Value__c+'%';
                }
                 else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Does not Contain')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' LIKE ' +'%'+fw.newRuleCriteria.Matching_Value__c+'%';
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Less than')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' < ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Greater Than')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' > ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Less or Equal')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' <= ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Greater or Equal')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' >= ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if (fw.newRuleCriteria.Matching_Type__c=='Between'){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' BETWEEN ' +fw.newRuleCriteria.Maximum_Value__c+' AND '+fw.newRuleCriteria.Maximum_Value__c;
                }
                else if (fw.newRuleCriteria.Matching_Type__c=='Not Between'){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' NOT BETWEEN ' +fw.newRuleCriteria.Maximum_Value__c+' AND '+fw.newRuleCriteria.Maximum_Value__c;
                }
                else if (fw.newRuleCriteria.Matching_Type__c=='IN'){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' IN ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c=='NOT IN'){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' NOT IN' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if (fw.newRuleCriteria.Matching_Type__c=='REGEX'){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c +' LIKE ' +fw.newRuleCriteria.Matching_Value__c;
                }
                else if(fw.newRuleCriteria.Matching_Type__c=='INCLUDES') {
                 
                  if(fw.newRuleCriteria.Matching_Value__c != null && fw.newRuleCriteria.Matching_Value__c != ''){
                    String trimedMatValue = '';
                    Boolean insertComma = false;
                //    system.debug('-->INCLUDES remove fw.newRuleCriteria.Matching_Value__c '+fw.newRuleCriteria.Matching_Value__c);
                     
                    //for(String value : fw.newRuleCriteria.Matching_Value__c.split(',')){
                  //  for(String value : fw.newRuleCriteria.Matching_Value__c.split('\\!')){  
                      for(String value : fw.newRuleCriteria.Matching_Value__c.split(escsapeplitdelimeter)){
                      if(insertComma){
                        //trimedMatValue += ',';  
                         trimedMatValue += splitdelimeter;
                               
                      }else{
                        insertComma = true;
                      }
                      // trimedMatValue += value.trim();     
                       trimedMatValue += value ;  
                     //   system.debug('after trim trimedMatValue remove '+trimedMatValue );                 
                   }
                   fw.newRuleCriteria.Matching_Value__c = trimedMatValue;
                  }
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' IN ' +fw.newRuleCriteria.Matching_Value__c;
                 }
                else if (fw.newRuleCriteria.Matching_Type__c=='EXCLUDES'){
                    
                  if(fw.newRuleCriteria.Matching_Value__c != null && fw.newRuleCriteria.Matching_Value__c != ''){
                    String trimedMatValue = '';
                    Boolean insertComma = false;
                     //pgb for(String value : fw.newRuleCriteria.Matching_Value__c.split(',')){
                    //    for(String value : fw.newRuleCriteria.Matching_Value__c.split('\\|')){
                          for(String value : fw.newRuleCriteria.Matching_Value__c.split(escsapeplitdelimeter)){
                      
                      
                      if(insertComma){
                        // trimedMatValue += ',';  
                          trimedMatValue += splitdelimeter;  
                      }else{
                        insertComma = true;
                      }
                       //trimedMatValue += value.trim();    
                       trimedMatValue += value ;                  
                   }
                   fw.newRuleCriteria.Matching_Value__c = trimedMatValue;
                  }
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' NOT IN ' +fw.newRuleCriteria.Matching_Value__c;
                 }
                else if (fw.newRuleCriteria.Matching_Type__c.equalsIgnoreCase('Is Null')){
                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' = NULL';
                }
                else if(fw.newRuleCriteria.Matching_Type__c=='IS NOT NULL'){

                    formatedFilterLogic=fw.newRuleCriteria.Related_Object__c+'.'+fw.newRuleCriteria.field_API_name__c + ' != NULL';
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Unknown Operator!'));
                    return false;
                }
            }
            System.debug(':::formatedFilterLogic'+formatedFilterLogic);
            String formatedFC = (formatedFilterLogic.contains('CrossFormula') && fw.newRuleCriteria.Crossformula__c != null ? formatedFilterLogic.replace('CrossFormula' , fw.newRuleCriteria.Crossformula__c) : formatedFilterLogic);
            System.debug(':::formatedFC'+formatedFC);
            if(!formattedSet.contains(formatedFC)){
            	formattedlist.add(formatedFilterLogic);
                formattedSet.add(formatedFC);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Duplicate Criteria'));
                return false;
            }
        }
        
        formatedFilterLogic = RuleRecord.Filter_Logic__c;
        for(integer i =1;i<=formattedlist.size();i++){
            formatedFilterLogic=formatedFilterLogic.replace(string.valueof(i),' '+formattedlist.get(i-1)+' ');
        }
        
        RuleRecord.DisplayfilterLogic__c =formatedFilterLogic;
        return true;
    }
    
    public pagereference Validate(){
        validatefilterCritera();
        return null;
    }
        
       
    public static List<SelectOption> getGlobalVarValues(String variable){
            
            List<Advance_Workflow_Limits__c> lstAdvWorkflowLimits = Advance_Workflow_Limits__c.getAll().values();
			Map<String,Integer> mapAdvWorkflowLimits = new Map<String,Integer>();
			Integer rowLimit = Limits.getLimitDMLRows(); 
			if(lstAdvWorkflowLimits != null && lstAdvWorkflowLimits.size() > 0){
				for(Advance_Workflow_Limits__c advRec : lstAdvWorkflowLimits){
					mapAdvWorkflowLimits.put(advRec.name,Integer.valueOf(advRec.value__c));
				}
			}
            
            list<SelectOption> opt = new list<SelectOption>();
            system.debug('variable-->'+variable);
            if(variable=='User'){
                for(User u:[Select Id,Name FROM User Where IsActive=true]){
                    opt.add(new SelectOption(u.Name, u.Name));  
                }   
            }
            // Owner name change
            // Start
            else if(variable=='User.Id'){
                for(User u:[Select Id,Name FROM User Where IsActive=true]){
                    opt.add(new SelectOption(u.Id, u.Id));    
                }   
            }
            // End
            else if(variable=='Profile'){
                if(mapAdvWorkflowLimits.containsKey('NumProfilesPerQuery') && 
            			mapAdvWorkflowLimits.get('NumProfilesPerQuery') != null){
            			rowLimit = mapAdvWorkflowLimits.get('NumProfilesPerQuery');
            	}
                for(Profile u:[Select Id,Name FROM Profile Limit :rowLimit]){
                    opt.add(new SelectOption(u.Name, u.Name));  
                }   

            }else if(variable=='UserRole'){
            	if(mapAdvWorkflowLimits.containsKey('NumUserRolePerQuery') && 
            			mapAdvWorkflowLimits.get('NumUserRolePerQuery') != null){
            			rowLimit = mapAdvWorkflowLimits.get('NumUserRolePerQuery');
            	}
                for(UserRole u:[Select Id,Name FROM UserRole Limit :rowLimit]){
                    opt.add(new SelectOption(u.Name, u.Name));  
                }   

            }else if(variable=='Organization'){
            	if(mapAdvWorkflowLimits.containsKey('NumOrganizationPerQuery') && 
            			mapAdvWorkflowLimits.get('NumOrganizationPerQuery') != null){
            			rowLimit = mapAdvWorkflowLimits.get('NumOrganizationPerQuery');
            	}
                for(Organization u:[Select Id,Name FROM Organization  Limit :rowLimit]){
                    opt.add(new SelectOption(u.Name, u.Name));  
                }   
            }
            return opt;
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
    
    
           private String Convert(string filteredlogic){
                String condition = null;
                String convertfilterLogic=filteredlogic;
                 // creating the operator map
                  map<string,string> matchingtypesmap = new map<string,string>();
                  matchingtypesmap.put('Equals',' = ');
                  matchingtypesmap.put('Not Equal To',' != ');
                  matchingtypesmap.put('Contains',' LIKE %');
                  matchingtypesmap.put('Does Not Contain',' Not LIKE %');
                  matchingtypesmap.put('Greater Than',' > ');
                  matchingtypesmap.put('Greater Or Equal',' >= ');
                  matchingtypesmap.put('Less Than',' < ');
                  matchingtypesmap.put('Less Or Equal',' <= ');
                  matchingtypesmap.put('Includes',' In');
                  matchingtypesmap.put('Excludes',' Not In ');
                  matchingtypesmap.put('Starts With',' LIKE % ');
                  matchingtypesmap.put('Ends With',' LIKE %');
                  matchingtypesmap.put('Between',' Between ');
                  matchingtypesmap.put('Not Between',' Not Between ');
                  matchingtypesmap.put('Regular Expression',' LIKE ');
                 for (filterwrap cWrap:filterwrapper) {
                         if(cWrap.newRuleCriteria.Matching_Type__c == 'Between')
                              condition = cWrap.newRuleCriteria.Related_Object__c+'.'+cWrap.newRuleCriteria.Field_API_Name__c +matchingtypesmap.get(cWrap.newRuleCriteria.matching_Type__c)+'('+cWrap.newRuleCriteria.Maximum_Value__c+' AND '+cWrap.newRuleCriteria.Minimum_Value__c+')';
                         else if(cWrap.newRuleCriteria.Matching_Type__c == 'Not Between')
                              condition = cWrap.newRuleCriteria.Related_Object__c+'.'+cWrap.newRuleCriteria.Field_API_Name__c +matchingtypesmap.get(cWrap.newRuleCriteria.matching_Type__c)+'('+cWrap.newRuleCriteria.Maximum_Value__c+' AND '+cWrap.newRuleCriteria.Minimum_Value__c+')';
                         else
                              condition = cWrap.newRuleCriteria.Related_Object__c+'.'+cWrap.newRuleCriteria.Field_API_Name__c +matchingtypesmap.get(cWrap.newRuleCriteria.matching_Type__c)+cWrap.newRuleCriteria.Matching_Value__c;
                              // condition = cWrap.newRuleCriteria.Related_Object__c+'.'+cWrap.newRuleCriteria.Field_API_Name__c +matchingtypesmap.get(cWrap.newRuleCriteria.matching_Type__c)+cWrap.newRuleCriteria.Matching_Value__c;
                         if((cWrap.newRuleCriteria.Matching_Type__c == 'Starts With')||(cWrap.newRuleCriteria.Matching_Type__c == 'Contains')||(cWrap.newRuleCriteria.Matching_Type__c == 'Does Not Contain'))
                                    condition +='%';
                               convertfilterLogic =  convertfilterLogic.replaceAll(cWrap.newRuleCriteria.Id ,condition);
                           
                    }
                    return convertfilterLogic;
       }
         
        public class filterwrap{
            
            public integer sno{set;get;}
            public Sobject sobj{get;set;}
            
            public RuleCriteria__c newRuleCriteria{get; set;}
            public boolean iseditable{set;get;}
            public boolean isbetween{set;get;}
            public boolean isPicklist{set;get;}
            public boolean isBoolean{set;get;}
            public boolean isCrossFormula{set;get;}
            public boolean isGlobalVariable{set;get;}
            public boolean ismultiselect{set;get;}
            public boolean isdeleteable{set;get;}
            public boolean isOwnerField{set;get;}
            
            public list<string> picklistvalues{set;get;}
            public List<SelectOption> operators  {get;set;} 
            public List<SelectOption> fieldOptions {get;set;} 
            public List<SelectOption> ValueOption {get;set;} 
            public String ownerName{get;set;}
            
            
            public filterwrap(boolean delet, string fld,RuleCriteria__c RuleCriteria, integer no ){
                    this.isdeleteable=delet;
                    this.isbetween=false;
                    this.newRuleCriteria=RuleCriteria ;
                    this.isCrossFormula=false;
                    this.isGlobalVariable=false;
                    this.isBoolean=false;
                    this.isPicklist=false;
                    this.ismultiselect=false;
                    this.sno=no;
                    this.isOwnerField = false;
                    picklistValues = new List<string>();
                    operators = new List<SelectOption>();
                    operators.add(new selectoption('None','None'));
                    fieldOptions = new List<SelectOption>();
                    FieldOptions.add(new selectoption('None','None'));
                    ValueOption =new List<SelectOption>();
            }
   
    
    } 
        
}
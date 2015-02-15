// 
// (c) 2012 Appirio, Inc.
//
//  AW_RuleCriteriaController                                                     
//
//  This class is used to create and edit Rule Criteria 
//
//
// 10 Oct 2012     Peter Babalis     Original
//  
//
public with sharing class AW_RuleCriteriaController{

    //fields added by SH
    public Boolean isPicklist{ get; set;} 
    public Boolean isInput{ get; set; }
    public Boolean isCheckbox{ get; set;}
    public Boolean isMinMax{ get; set;}
    public Boolean isCrossFormula{ get; set;}
    private Map<String,Schema.SObjectField> fieldMap = new Map<String,Schema.SObjectField>();

    public RuleCriteria__c newRuleCriteria{get;set;}
    public Rule__c rule ;
    public String objType {get;set;}
    public boolean edit {get;set;}
    /*public String getObjType(){
     system.debug('---in getter---'+this.objType);
     return this.objType;
    }
    public void setObjType(String s){
     this.objType = s;
    }*/
    public String fieldType {get;set;}
    public List<SelectOption> objOptions    {get;set;}
    public List<SelectOption> fieldOption   {get;set;} 
    public string parentName {get;set;}
    public string fieldApiName {get;set;}
    String ruleCriteriaId;
    Map<String, Schema.SObjectField> mapField;
    public String ruleObjType {get;set;}
    
    //Cloud challenger start
    private Set<String> setRelObjApiName = new Set<String>();
    public AW_RuleCriteriaController(Apexpages.StandardController stdcon){
        ruleCriteriaId = stdcon.getId();
        newRuleCriteria = (RuleCriteria__c)stdcon.getRecord();
        objOptions = new List<SelectOption>();
        Schema.DescribeSObjectResult objinfo = null;
        isCrossFormula=false;   
        isMinMax=false;
        //if(ruleCriteriaId==null)initCriteriaParams();  
          
        if(ruleCriteriaId!=null){
              /** 
              * Edit existing Record
              */ 
              edit=true;
              newRuleCriteria = [SELECT name,
                                        Field_API_Name__c,
                                        Field_Name__c,
                                        Field_Relation__c,
                                        Field_Type__c,
                                        Matching_Type__c,
                                        Rule__c,
                                        Matching_Value__c,
                                        Maximum_Value__c,
                                        Minimum_Value__c,
                                        Related_Object__c,
                                        RuleObjectType__c,
                                        CrossFormula__c
                                  FROM  RuleCriteria__c 
                                  WHERE id=:ruleCriteriaId];
                                    
              objType = newRuleCriteria.Related_Object__c;
              ruleObjType=newRuleCriteria.RuleObjectType__c;
              
              if(newRuleCriteria .Field_API_Name__c=='CrossFormula')isCrossFormula=true; 
              if(newRuleCriteria .Matching_Type__c=='Between')isMinMax=true;
              
         }
        else{
          /**
          * New Record
          */
              edit=false;
              rule = [select object__c from Rule__c where id=:newRuleCriteria.rule__c];
              if(rule!=null){
                    newRuleCriteria.related_object__c = rule.object__c;
                    objType = rule.object__c;
                    ruleObjType = objType;
              }
         } 
         initCriteriaParams(); 
         //if(isMinMax)isInput=false; 
         if(objType!= null){
            populateFields(objType);
            /**
             * Get list of child objects of object on which rule is defined
             **/
             Map<String, Schema.SObjectType> mapObj = Schema.getGlobalDescribe();
            Schema.SObjectType sobj = mapObj.get(objType);
            objinfo =sobj.GetDescribe();
            System.debug('PGB objinfo ' + objInfo.getName() + '['+objInfo.getLabel()+']'); 
            List<Schema.ChildRelationship> listChild = sobj.getDescribe().getChildRelationships();            
            objOptions.add(new SelectOption(objInfo.getName(), objInfo.getLabel() + ' (' + objInfo.getName() + ')'));
            setRelObjApiName.add(objInfo.getName());
            for(Schema.ChildRelationship child: listChild){
                Schema.DescribeSObjectResult descRes = child.getChildSObject().getDescribe();
                if(!setRelObjApiName.contains(descRes.getName())){
                    system.debug(' PGB Children ' + descRes.getName());
                    system.debug(' PGB Children ' + descRes.getLabel());
                    objOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                    setRelObjApiName.add(descRes.getName());
                }
            }
        }
    }
  
    public PageReference  getFieldNames(){
         
         objType= Apexpages.currentPage().getParameters().get('parentName');
         populateFields(objType);
         return null;
    }
    
    /** 
     * This method is used to populate the fields of given Object
     */
    public void populateFields(String objType){
         fieldOption= new List<SelectOption>();
         Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
         string parent = objType;
         Schema.SObjectType sobjTypeParent = gd.get(parent);
         Schema.DescribeSObjectResult parentObjFields= sobjTypeParent.getDescribe();
         mapField = parentObjFields.fields.getMap();
         fieldOption.add(new SelectOption('',''));
         for(String fieldname:mapField.keySet()){
            Schema.SObjectField sfield = mapField.get(fieldname);
            Schema.DescribeFieldResult descResField = sfield.getDescribe();
            String fieldLabel = descResField.getLabel();
        // fieldOption.add(new SelectOption(descResField.getName(),fieldLabel));
           fieldOption.add(new SelectOption(descResField.getLocalName(),fieldLabel));
          
            
        }
        AW_AdvanceWorkflowExecutionHelper.sortSelectListOnLabel(fieldOption);
        //add cross reference
        fieldOption.add(new SelectOption('CrossFormula','Cross Formula'));
        
        fieldType= newRuleCriteria.field_name__c;
       
    }
    
     //initialize the other params like operator & picklist values if the select field is picklist
        public void initCriteriaParams(){
            isPicklist=false;
            isCheckbox=false;
            isInput=true;//default make it a input field
            
            if(isCrossFormula)return;            
            
            if(newRuleCriteria.Field_API_Name__c==null || newRuleCriteria.Field_API_Name__c=='' || objType==null || objType=='')
                return;
                                              
            //else set the necessary params :- 
            //if(fieldMap==null || fieldMap.size() ==0)          
               fieldMap =Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap();
            
            String fieldName = newRuleCriteria.Field_API_Name__c;
            system.debug('===fieldName==='+fieldName);
            
            //now get the field object
            if(fieldMap.get(fieldName).getDescribe().getType()==Schema.DisplayType.Picklist){
                isPicklist=True;
            }else if(fieldMap.get(fieldName).getDescribe().getType()==Schema.DisplayType.Boolean){
                isCheckbox=True;
            }//end else if block
             
            system.debug('-- isPicklist--'+isPicklist);
             
            isInput=!(isPicklist|| isCheckbox);
                                         
        }
        
        public List<SelectOption> getFieldOperators(){
               
               List<selectOption> options=new List<selectOption>();
                options.add(new selectOption('','--None--')); 
               if(isCrossFormula){
                    options.add(new selectOption('Equals','Equals')); 
                    options.add(new selectOption('Not Equal To','Not Equal To'));
                    options.add(new selectOption('Is Null','Is Null'));
                    options.add(new selectOption('Is Not Null','Is Not Null'));
                    options.add(new selectOption('Greater Than','Greater Than')); 
                    options.add(new selectOption('Less Than','Less Than')); 
                    options.add(new selectOption('Greater or Equal','Greater or Equal')); 
                    options.add(new selectOption('Less or Equal','Less or Equal')); 
                    options.add(new selectOption('Between','Between'));
                    options.add(new selectOption('Contains','Contains')); 
                    options.add(new selectOption('Does Not Contain','Does Not Contain')); 
                    options.add(new selectOption('Starts With','Starts With')); 
                    options.add(new selectOption('Ends With','Ends With')); 
                    options.add(new selectOption('Does Not Start With','Does Not Start With')); 
                    options.add(new selectOption('Does Not End With','Does Not End With')); 
                    options.add(new selectOption('Includes','Includes')); 
                    options.add(new selectOption('Excludes','Excludes')); 
                    options.add(new selectOption('Regular Expression','Regular Expression')); 
                    return options;
               }
               
               //validate 
               if(objType==null || objType=='')
                     return options;   
               
               if(fieldMap==null || fieldMap.size() ==0)          
                  fieldMap =Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap();  
               
               DisplayType fieldType;
               Boolean typeSelected=False;
                
               Schema.SObjectField fieldToken=fieldMap.get(newRuleCriteria.Field_API_Name__c); 
               
               try{
                  fieldType=fieldToken.getDescribe().getType();
                  typeSelected=true;
               }catch (Exception e){}//exception happens when changing type as the other picklist hasn't had a chance to refresh yet   
               
               if(!typeSelected)
                   return options;
                
               //only add an operator if a valid field type is chosen.  Otherwise, leave it blank.
               if (fieldType!=Schema.DisplayType.anyType && fieldType!=Schema.DisplayType.base64  && fieldType!=Schema.DisplayType.EncryptedString && fieldType!=Schema.DisplayType.Id ){
                  //the above types are not supported
                  options.add(new selectOption('Equals','Equals')); 
                  options.add(new selectOption('Not Equal To','Not Equal To')); 
                  options.add(new selectOption('Is Null','Is Null'));
                  options.add(new selectOption('Is Not Null','Is Not Null'));
                  if ( fieldType!=Schema.DisplayType.String  && fieldType!=Schema.DisplayType.Email&&fieldType!=Schema.DisplayType.Boolean&&fieldType!=Schema.DisplayType.Picklist &&fieldType!=Schema.DisplayType.Reference&&fieldType!=Schema.DisplayType.TextArea){
                      //boolean can't use the below, but the others can
                      options.add(new selectOption('Greater Than','Greater Than')); 
                      options.add(new selectOption('Less Than','Less Than')); 
                      options.add(new selectOption('Greater or Equal','Greater or Equal')); 
                      options.add(new selectOption('Less or Equal','Less or Equal')); 
                      options.add(new selectOption('Between','Between'));
                  }
                  
                  if ( fieldType==Schema.DisplayType.String || fieldType==Schema.DisplayType.Email ||fieldType==Schema.DisplayType.Reference|| fieldType==Schema.DisplayType.MultiPicklist  || fieldType==Schema.DisplayType.ComboBox ||fieldType==Schema.DisplayType.Picklist ||fieldType==Schema.DisplayType.email||fieldType==Schema.DisplayType.encryptedString||fieldType==Schema.DisplayType.Phone||fieldType==Schema.DisplayType.url || fieldType==Schema.DisplayType.TextArea ){//if 4
                       //these options are for string type fields
                       options.add(new selectOption('Contains','Contains')); 
                       options.add(new selectOption('Does Not Contain','Does Not Contain')); 
                       options.add(new selectOption('Starts With','Starts With')); 
                       options.add(new selectOption('Ends With','Ends With'));
                       options.add(new selectOption('Does Not Start With','Does Not Start With')); 
                       options.add(new selectOption('Does Not End With','Does Not End With'));  
                       options.add(new selectOption('Includes','Includes')); 
                       options.add(new selectOption('Excludes','Excludes')); 
                       options.add(new selectOption('Regular Expression','Regular Expression')); 
                  }
                  
                 
                  
               }  
               return options;
        }
        
        
        public List<SelectOption> getPickListValues(){
            List<SelectOption> valuePicklistOptions = new List<SelectOption>();
            
            //there no field select dont go forward
            if(newRuleCriteria.Field_API_Name__c==null || newRuleCriteria.Field_API_Name__c=='')
                return valuePicklistOptions ;
            
            String fieldName=  newRuleCriteria.Field_API_Name__c;  
             
            if(fieldMap==null || fieldMap.size() ==0)          
               fieldMap =Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap();  
            
            try{
                Schema.DisplayType fType=fieldMap.get(fieldName).getDescribe().getType();
                if(fType==Schema.DisplayType.Picklist){
                    List<Schema.PickListEntry> picklistValues =fieldMap.get(fieldName).getDescribe().getPicklistValues();
                    for (Schema.PickListEntry pickVal: picklistValues ){
                        // create a selectoption for each pickval
                        valuePicklistOptions.add(new SelectOption(pickVal.getValue(),pickVal.getLabel()));
                    }//end picklist loop
                }
            }catch(Exception e){
                 system.debug('getPickListValueshad an error, likely due to switching between Lead & Campaign Member rules. ');
                 system.debug('Error:'+e);
            }                        
            return valuePicklistOptions ;             
        }
    
    public PageReference setFieldApiName(){
        fieldType = Apexpages.currentPage().getParameters().get('fieldName');
        if(fieldType != '' && fieldType != null){
            if(fieldType=='CrossFormula') {
                isCrossFormula = true;
                newRuleCriteria.field_API_name__c = fieldType; 
                newRuleCriteria.field_type__c ='String';
            }else{
                newRuleCriteria.field_API_name__c = fieldType;
                system.debug('fieldType' +fieldType);
                Schema.sObjectField sobjField = mapField.get(fieldType);
                newRuleCriteria.field_type__c =  String.valueOf(sobjField.getDescribe().getType());
                isCrossFormula = false;
             }
         }else{
            newRuleCriteria.field_API_name__c='';
            newRuleCriteria.field_type__c ='';  
        }
        initCriteriaParams();
        return null;
    }
    
    public void setOperator(){
        String operator= Apexpages.currentPage().getParameters().get('fieldOperator');
        isMinMax=operator=='Between' ?true:false;    
                
    }
    
    public PageReference saveRuleCriteria(){
            newRuleCriteria.Related_Object__c = objtype;
            newRuleCriteria.Field_Name__c =  fieldType;
            try{
                Database.upsert(newRuleCriteria);
               // return(new PageReference('/'+newRuleCriteria.id));
                return(new PageReference('/'+newRuleCriteria.Rule__c));
            }
            catch(Exception e){
                ApexPages.Message msg;
                msg = new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0));
                ApexPages.addMessage(msg);
                return null;
            }   
    }
     
     public PageReference saveAndNewRuleCriteria(){
            newRuleCriteria.Related_Object__c = objtype;
            newRuleCriteria.Field_Name__c =  fieldType;
             edit=false;
            try{
                Database.upsert(newRuleCriteria);
                newRuleCriteria = new RuleCriteria__c(rule__c=newRuleCriteria.rule__c);
                objType = ruleObjType;
                populateFields(objType);
                return(new PageReference('/apex/AW_RuleCriteria_VF'));
                
            }
            catch(Exception e){
                ApexPages.Message msg;
                msg = new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0));
                ApexPages.addMessage(msg);
                return null;
            }
        
        
    }
}
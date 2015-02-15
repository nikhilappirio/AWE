/*
 * Class for handling the Import CSV in AWE
 * 
 */ 
public with sharing class AW_ParseCSVTo_AdvanceWorkflow_Util{
    
    // Map of Rule Wrapper 
    public static Map<String , AW_ParseCSV_WorkflowWrapper> wfWrapperMap = new Map<String , AW_ParseCSV_WorkflowWrapper>();
    // set of Advance Workflow Name
    private static Set<String> advanceWorkflowNames = new Set<String>();
    // Map of Existing Workflows
    private static Map<String , Advance_Workflow__c>  existingAdvancedWorkflowMap = new Map<String , Advance_Workflow__c>();
    //set of Object Name 
    public static Set<String> ruleNames = new Set<String>(); 
    // Map of fields 
    private static Map<String,Map<String, Schema.SObjectField>> fieldsMap = new Map<String, Map<String , Schema.SobjectField>>();
    public static Map<String,Map<String, AW_ListRules.FieldWrapper>> fieldWrapperMap = new Map<String,Map<String, AW_ListRules.FieldWrapper>>();
    private static Map<String , Map<String, Id>> referenceFieldIdMap = new Map<String , Map<String, Id>>();
    
    public static Map<String, Error_Log__c> ruleErrorMap = new Map<String, Error_Log__c>();
    public static Map<String , Map<String, String>> ruleActionMapping = new Map<String , Map<String, String>>();
    private static Map<String, Schema.SObjectType> globalDescribe   =   null;
    //private static Map<String,Set<String>> objectFields = new Map<String,Set<String>>();
    private static Map<String, String> folderIdMap = new Map<String, String>();
    private static Map<String , LookupWrapper> lookupWrapperMap = new Map<String , LookupWrapper>();
    public static String refRule;
    private static Map<Decimal, String> orderMap;
    public static Boolean isImportExportCSV = false;
    private static final String PICKLIST_VALUE_DELIMETER = ';';
    static{ 
    Map<String, AWE_Rule_Action_Mapping__c> mappingMap = AWE_Rule_Action_Mapping__c.getAll();
     for(AWE_Rule_Action_Mapping__c raMapping : mappingMap.values()){
        if(raMapping.Object_Name__c != null && raMapping.Type__c != null){
          if(!ruleActionMapping.containsKey(raMapping.Object_Name__c +':'+raMapping.Type__c)){
            ruleActionMapping.put(raMapping.Object_Name__c +':'+raMapping.Type__c, new Map<String, String>{raMapping.Field_Name__c  => raMapping.Field_API_Name__c});
          }else{
            ruleActionMapping.get(raMapping.Object_Name__c +':'+raMapping.Type__c).put(raMapping.Field_Name__c  , raMapping.Field_API_Name__c);
          }
        }
      }
      globalDescribe = Schema.getGlobalDescribe();
   }
   
   /*
     * import CSV and create Advanced Workflow with Rules and actions
     * @param : String csvBody
     * @param : String refImpName
     * @param : String objectName
   */
    public static void importAWECSV(String csvBody, String refimpRule, String objectName){
      isImportExportCSV = true;
        System.debug('::csvBody'+csvBody);
        Map<String , Rule__c> existingRuleMap = new Map<String , Rule__c>();
       if(csvBody != null && csvBody != ''){
           refRule = refimpRule;
            prepareWorkflowWrapperMap(csvBody, objectName);
            if(!wfWrapperMap.isEmpty()){
              
                // load Existing Rules
                existingRuleMap = loadExistingRules();
                // load Existing Workflows
                existingAdvancedWorkflowMap.putAll(loadExistingAdvanceWorkflow(objectName));
                processWorkflowWrapper(existingRuleMap , objectName);
            }
            System.debug('::ruleErrorMap'+ruleErrorMap);
            if(!ruleErrorMap.isEmpty()){ 
            insert ruleErrorMap.values();
          }
        } 
   }
   
   /*
     * Prepare Workflow Wrapper Map 
     * @param : String csvBody
     * @Param : String objectName
   */
   private static void prepareWorkflowWrapperMap(String csvBody, String objectName){
       orderMap = new Map<Decimal, String>();
       lookupWrapperMap =  new Map<String , LookupWrapper>(); 
       AW_CSVReader  csvReader = new AW_CSVReader(csvBody , false); 
        if(csvBody == null || csvReader.getData().size() == 0){
         ruleErrorMap.put('ImportFailure' , new Error_Log__c(Error_Description__c ='CSV does not have any data to import or not in proper format', import_code__c = refRule , ErrorSource__c = 'parsing Import Rule'));
          return;  
       }
        String[]  csvInCols = csvReader.readLine();
        System.debug(csvInCols+':csvInCols'+csvInCols.size());
        while(csvInCols != null && csvInCols.size() > 0){
            // add Workflow Name in advanced Workflow Set
            if(csvInCols.size() >= 10){
                if(csvInCols[0] != null && csvInCols[0] != ''){
                    advanceWorkflowNames.add(csvInCols[0].trim());
                }
               // check rule object is same for advanced Workflow object or not
                if(csvInCols.size() > 1 && (csvInCols[1] == null || csvInCols[1].trim() != objectName)){
                    System.debug('Error is ::::::::::::::Rule Object is different from Adavance Workflow Object' +csvInCols[1] + '::' + objectName);
                    ruleErrorMap.put(csvInCols[2].trim() , new Error_Log__c(Error_Rule_Name__c=csvInCols[2].trim() , Object_Name__c=objectName,Error_Description__c = csvInCols[2].trim()  + ' Rule Object is different from Adavance Workflow Object', import_code__c = refRule ,Object_Method_Name__c='AW_ParseCSVTo_AdvanceWorkflow_Util.prepareWorkflowWrapperMap', ErrorSource__c = 'ImportCSVRule'));
                    csvInCols = csvReader.readLine();
                    continue;
                }
                if(!wfWrapperMap.containsKey(csvInCols[1].trim())){
                    wfWrapperMap.put(csvInCols[1].trim() , new AW_ParseCSV_WorkflowWrapper(csvInCols[1].trim() ,csvInCols[0], csvInCols[3], new Map<String, AW_ParseCSV_RuleWrapper>()));
                }
                // RuleWrapper Instance
                AW_ParseCSV_RuleWrapper ruleWrapper =  new AW_ParseCSV_RuleWrapper(new Rule__c(Name = csvInCols[2], Order__c = (csvInCols[4]  != null && csvInCols[4].trim() != '' && csvInCols[4] != 'null' ? Decimal.valueOf(csvInCols[4]) : null) ,Description__c = (csvInCols[3] != null ? csvInCols[3].replace(AW_Rule_Constants.LINE_SPLITOR , '\n').replace(AW_Rule_Constants.CARRIAGE_SPLITOR , '\r') : '' ), Object__c = csvInCols[1], import_Code__c = refRule, Filter_Logic__c = csvInCols[8] ), csvInCols[5] , csvInCols[6], csvInCols[7],csvInCols[9]);
                wfWrapperMap.get(csvInCols[1].trim()).ruleWrapperMap.put(csvInCols[2].trim() , ruleWrapper);
                ruleNames.add(csvInCols[2].trim());  
                csvInCols = csvReader.readLine();
            }else {
                throw new AW_Exception('CSV does not have proper rows and columns');
            }
        }
        System.debug(':::wfWrapperMap'+wfWrapperMap);
        System.debug(':::advanceWorkflowNames'+advanceWorkflowNames);
        
   }
   
   /*
     * Prepare Workflow Wrapper Map for bulk
     * @param : List<List<String>> csvBody
     * @Param : String refimpRule
     * @Param : String objectName
   */
   public static void prepareWorkflowWrapperMapBulk(List<List<string>> csvRows, String refimpRule , String objectName){
      Map<String , Rule__c> existingRuleMap = new Map<String , Rule__c>();
      lookupWrapperMap =  new Map<String , LookupWrapper>();
      orderMap = new Map<Decimal, String>();
      refRule = refimpRule;
      isImportExportCSV = true;
      for(List<String> csvInCols : csvRows){
        System.debug(':::size'+csvInCols.size());
        System.debug(':::csvInCols'+csvInCols);
        for(String s : csvInCols){
          System.debug('::::s'+s);
        }
        if(csvInCols.size() >= 10){
            if(csvInCols[0] != null && csvInCols[0] != ''){
              advanceWorkflowNames.add(csvInCols[0].trim());
              }
             // check rule object is same for advanced Workflow object or not
              if(csvInCols.size() > 1 && (csvInCols[1] == null || csvInCols[1].trim() != objectName)){
              ruleErrorMap.put(csvInCols[2].trim() , new Error_Log__c(Error_Rule_Name__c=csvInCols[2].trim(),Error_Description__c = csvInCols[2].trim()  + ' Rule Object is different from Adavance Workflow Object', import_code__c = refRule , ErrorSource__c = 'ImportRule'));
              continue;
            }
            if(!wfWrapperMap.containsKey(csvInCols[1].trim())){
              wfWrapperMap.put(csvInCols[1].trim() , new AW_ParseCSV_WorkflowWrapper(csvInCols[1].trim() ,csvInCols[0],  'Advance Workflow on ' + csvInCols[1].trim(), new Map<String, AW_ParseCSV_RuleWrapper>()));
            }
           // RuleWrapper Instance
AW_ParseCSV_RuleWrapper ruleWrapper =  new AW_ParseCSV_RuleWrapper(new Rule__c(Name = csvInCols[2], Order__c = (csvInCols[4]  != null && csvInCols[4].trim() != '' && csvInCols[4] != 'null' ? Decimal.valueOf(csvInCols[4]) : null) ,Description__c = (csvInCols[3] != null ? csvInCols[3].replace(AW_Rule_Constants.LINE_SPLITOR , '\n').replace(AW_Rule_Constants.CARRIAGE_SPLITOR , '\r') : ''), Object__c = csvInCols[1], import_Code__c = refRule, Filter_Logic__c = csvInCols[8]), csvInCols[5] , csvInCols[6], csvInCols[7],csvInCols[9]);
           wfWrapperMap.get(csvInCols[1].trim()).ruleWrapperMap.put(csvInCols[2].trim() , ruleWrapper);
           ruleNames.add(csvInCols[2].trim());  
        }else {
          throw new AW_Exception('CSV does not have proper rows and columns');
            
          }
      }
      if(!wfWrapperMap.isEmpty()){
          
            // load Existing Rules
            existingRuleMap = loadExistingRules();
            // load Existing Workflows
            existingAdvancedWorkflowMap.putAll(loadExistingAdvanceWorkflow(objectName));
            processWorkflowWrapper(existingRuleMap , objectName);
        }
        System.debug('::ruleErrorMap'+ruleErrorMap);
        if(!ruleErrorMap.isEmpty()){
        insert ruleErrorMap.values();
      }
     }
    /*
     * Loading Existing Rules
     */
     private static Map<String , Rule__c> loadExistingRules(){
        Map<String , Rule__c> existingRuleMap = new Map<String , Rule__c>(); 
        // generate Query for Rules
        String soqlQuery = generateQuery('Rule__c');
        for(Rule__c rule : Database.query(soqlQuery)){
          if(ruleNames.contains(rule.Name.trim())){
              existingRuleMap.put(rule.Name , rule);
              if(rule.Advance_Workflow__c != null)
                existingAdvancedWorkflowMap.put(rule.Advance_Workflow__r.Name , rule.Advance_Workflow__r);
          }
          if(rule.Order__c != null && rule.Status__c == 'Active'){
            orderMap.put(rule.Order__c, rule.Name);
          }
        }
        return existingRuleMap;
    }  
    
     /*
      * Loading Existing Workflow
     */ 
    private static Map<String , Advance_Workflow__c> loadExistingAdvanceWorkflow(String objectName){
        Map<String , Advance_Workflow__c> tempExistingAWMap = new Map<String , Advance_Workflow__c>(); 
        // generate Query for Rules
        String soqlQuery = generateQuery('Advance_Workflow__c');
        for(Advance_Workflow__c aw : Database.query(soqlQuery)){
            tempExistingAWMap.put(aw.Name , aw);
        }
        return tempExistingAWMap;
    } 
    
    /*
      * Generate Query 
      
    */
    private static String generateQuery(String objectName){
        Set<String> ruleFields = globalDescribe.get(objectName).getDescribe().Fields.getMap().keySet();
        String soqlQuery = 'SELECT ';
        for(String fs : ruleFields){
            soqlQuery +=  fs + ', ';
        }
        if(soqlQuery.contains(',')){
            soqlQuery = soqlQuery.subString(0, soqlQuery.lastIndexOf(','));
        }
        if(objectName == 'AWE__Rule__c'){
            soqlQuery += ', Advance_Workflow__r.Name , Advance_Workflow__r.Description__c, ( SELECT id FROM Rule_Criteria__r) , (SELECT id FROM Rule_Actions__r)';
        }
        soqlQuery += ' from ' +  objectName +' ' ;
        if(objectName == 'AWE__Rule__c'){
            soqlQuery +=' WHERE  Name IN : ruleNames  OR (advance_workflow__r.Name IN : advanceWorkflowNames AND Status__c = \'Active\' )'; //AND advance_workflow__r.Name IN : advanceWorkflowNames
        }else if(objectName == 'AWE__Advance_Workflow__c'){
            if(!advanceWorkflowNames.isEmpty()){
                soqlQuery +=' WHERE  Name IN : advanceWorkflowNames  ';//AND Name  NOT IN : loadedWorkflowNames
            }else{
                soqlQuery +=' WHERE  Object__c = : objectName ';
            }
        }
        System.debug('::soqlQuery'+soqlQuery);
        return soqlQuery;
    }
     
    /*
     * process Rule Wrapper
     * @param : Map<String, Rule__c> existingRules
     *
     */ 
    private static void processWorkflowWrapper(Map<String, Rule__c> existingRules, String objectName){
        Map<String, List<RuleCriteria__c>>  ruleCriteriaMap = new Map<String, List<RuleCriteria__c>>();
        List<RuleCriteria__c> deleteRuleCriterias = new List<RuleCriteria__c>();
        List<RuleAction__c> deleteRuleActions = new List<RuleAction__c>();
        Map<String, Advance_Workflow__c> advanceWorkflowMap = new Map<String, Advance_Workflow__c>();
        initailize();  
        System.debug(':existingAdvancedWorkflowMap 1>>'+existingAdvancedWorkflowMap);
        Savepoint sp = Database.setSavepoint();
        
        try{
                
          for(String objName : wfWrapperMap.keySet()){
            AW_ParseCSV_WorkflowWrapper workflowWrapper = wfWrapperMap.get(objName);
            //objectFields.put(objName , new Set<String>());
            Set<String> validFields = new Set<String>();
            Set<String> errorRules = new Set<String>();
            for(String ruleName : workflowWrapper.ruleWrapperMap.keySet()){
                AW_ParseCSV_RuleWrapper  ruleWrapper = workflowWrapper.ruleWrapperMap.get(ruleName);
                if(ruleWrapper.displayCriteria != null && ruleWrapper.displayCriteria != ''){
                  if(ruleWrapper.displayCriteria.countMatches('(')!= ruleWrapper.displayCriteria.countMatches(')')){
                           throw new AW_Exception('Left and Right Parethisis not correct!');
                        }else{
                    ruleWrapper = AW_ParseCSVTo_RuleCriteria_Util.parseRuleCriteria(ruleWrapper); 
                    System.debug('::ruleWrapper after rc'+ruleWrapper.displayCriteria);
                  }
                }else 
                  ruleWrapper.ruleCriteriaList = new List<AW_ParseCSV_RuleCriteriaWrapper>();  
                // create Rule Action instance 
                if(ruleWrapper.DisplayActions != null && ruleWrapper.DisplayActions != '')
                // validate and parse Rule Actions
                  ruleWrapper.ruleActionList = validationAndParseRuleActions(ruleWrapper); 
                else
                  ruleWrapper.ruleActionList = new List<AW_ParseCSV_RuleActionWrapper>();
                  System.debug('::ruleWrapper.ruleActionList'+ruleWrapper.ruleActionList);
                if(existingRules.containsKey(ruleName)){ 
                    System.debug('::existingRules.containsKey(ruleName)'+existingRules.get(ruleName).Order__c);
                    System.debug('::ruleWrapper.rule.Order__c'+ruleWrapper.rule.Order__c);
                    if(existingRules.get(ruleName).status__c == 'Draft' && ruleWrapper.rule.Order__c != null){
                      if(!orderMap.containsKey(ruleWrapper.rule.Order__c)){  //If rule exist  in DRAFT  STATUS  and order in CSV has value which  matches  the  orderof a rule ( for the oject WF is defined )  stored in AWE  error out the import
                         System.debug('::in existing ruleWrapper.rule.Order__c'+ruleWrapper.rule.Order__c);
                         existingRules.get(ruleName).Status__c = 'Active';
                         existingRules.get(ruleName).Order__c = ruleWrapper.rule.Order__c;
                         existingRules.get(ruleName).Version__c = (existingRules.get(ruleName).Version__c != null ? existingRules.get(ruleName).Version__c + 1 : 1);
                         if(existingAdvancedWorkflowMap.containsKey(objName) && existingAdvancedWorkflowMap.get(objName).id != null){
                           existingRules.get(ruleName).Advance_Workflow__c =  existingAdvancedWorkflowMap.get(objName).id;
                         }
                       }else{ //If rule DOES NOT exist and order in CSV has value which  matches  the  order of a rule ( for the oject WF is defined )  stored in AWE  error out the import
                         System.debug('::rule does Exist order not matched' + ruleName);
                          ruleErrorMap.put(ruleName , new Error_Log__c(Error_Rule_Name__c=ruleName, Object_Name__c=objectName, Error_Description__c ='Order in '+ ruleName +' is already matched with different rule ' +orderMap.get(ruleWrapper.rule.Order__c), import_code__c = refRule , ErrorSource__c = 'Order Mismatch'));
                          existingRules.remove(ruleName);
                          errorRules.add(ruleName);
                          continue;
                       }
                    }else if((existingRules.get(ruleName).Order__c != null && ruleWrapper.rule.Order__c != null && existingRules.get(ruleName).Order__c == ruleWrapper.rule.Order__c) || (existingRules.get(ruleName).status__c == 'Active' && ruleWrapper.rule.Order__c == null)){
                         System.debug('::rule does Exist with same order' + ruleName);
                        existingRules.get(ruleName).Version__c = (existingRules.get(ruleName).Version__c != null ? existingRules.get(ruleName).Version__c + 1 : 1);
                      }else if(existingRules.get(ruleName).Order__c != null && ruleWrapper.rule.Order__c != null ){
                        System.debug('::rule does Exist order not matched' + ruleName);
                        ruleErrorMap.put(ruleName , new Error_Log__c(Error_Rule_Name__c=ruleName, Object_Name__c=objectName,Error_Description__c ='Order is not matched in rule - '+ruleName, import_code__c = refRule , ErrorSource__c = 'Order Mismatch'));
                        existingRules.remove(ruleName);
                        errorRules.add(ruleName);
                        continue;
                      }
                    System.debug('::existingRules'+existingRules.get(ruleName));
                    existingRules.get(ruleName).Description__c = ruleWrapper.rule.Description__c;
                    existingRules.get(ruleName).Object__c = ruleWrapper.rule.Object__c;
                    existingRules.get(ruleName).Filter_logic__c = ruleWrapper.rule.Filter_Logic__c;
                    existingRules.get(ruleName).import_Code__c = ruleWrapper.rule.import_Code__c;
                    // TO DO  update the fields
                    deleteRuleCriterias.addAll(existingRules.get(ruleName).Rule_Criteria__r);
                    deleteRuleActions.addAll(existingRules.get(ruleName).Rule_Actions__r);
                  
               }else{
                 if(ruleWrapper.rule.Order__c != null){
                   //If rule DOES NOT exist  and order in CSV has value which DOES NOT match the order of a rule ( for the oject WF is defined )  stored in AWE upsert the rule  as ACTIVE with version =1
                   if(!orderMap.containsKey(ruleWrapper.rule.Order__c)){ 
                     System.debug('::order not matched'+ruleWrapper.rule.Order__c);
                     ruleWrapper.rule.Status__c = 'Active';
                     ruleWrapper.rule.Version__c = 1;
                     if(existingAdvancedWorkflowMap.containsKey(objName) && existingAdvancedWorkflowMap.get(objName).id != null){
                       ruleWrapper.rule.Advance_Workflow__c =  existingAdvancedWorkflowMap.get(objName).id;
                     }
                     System.debug('::order not matched after'+ruleWrapper.rule);
                   }else{ //If rule DOES NOT exist and order in CSV has value which  matches  the  order of a rule ( for the oject WF is defined )  stored in AWE  error out the import
                     System.debug('::rule does Exist order not matched' + ruleName);
                      ruleErrorMap.put(ruleName , new Error_Log__c(Error_Description__c ='Order in '+ ruleName +' is already matched with different rule ' +orderMap.get(ruleWrapper.rule.Order__c), import_code__c = refRule , ErrorSource__c = 'Order Mismatch'));
                      existingRules.remove(ruleName);
                      errorRules.add(ruleName);
                      continue;
                   }
                 }else{ //If rule DOES NOT exist and order in CSV is blank upsert the rule  as DRAFT   
                   ruleWrapper.rule.Status__c = 'Draft';
                   ruleWrapper.rule.order__c = null;
                 }
                  existingRules.put(ruleName , ruleWrapper.rule);
               }
               if(ruleWrapper.evaluation != null && AW_Rule_Constants.evalutionForImportMap.containsKey(ruleWrapper.evaluation.trim())){
                 existingRules.get(ruleName).Evaluation_Rule__c = AW_Rule_Constants.evalutionForImportMap.get(ruleWrapper.evaluation);
               }else if(ruleWrapper.evaluation != null  && ruleWrapper.execution.length() > 0){
                 existingRules.get(ruleName).Evaluation_Rule__c = ruleWrapper.evaluation;
               }else{
                 ruleErrorMap.put(ruleName , new Error_Log__c(Error_Description__c ='Evaluation is required in rule ' +ruleName, import_code__c = refRule , ErrorSource__c = 'Evaluation Missing'));
                existingRules.remove(ruleName);
                errorRules.add(ruleName);
                      
               }
               if(ruleWrapper.execution != null && AW_Rule_Constants.executionBehaviourForImportMap.containsKey(ruleWrapper.execution.trim())){
                 existingRules.get(ruleName).Execution_Behavior__c = AW_Rule_Constants.executionBehaviourForImportMap.get(ruleWrapper.execution);
               }else if(ruleWrapper.execution != null && ruleWrapper.execution.length() > 0){
                 existingRules.get(ruleName).Execution_Behavior__c = ruleWrapper.execution;
               }else{
                 ruleErrorMap.put(ruleName , new Error_Log__c(Error_Description__c ='Execution is required in rule ' +ruleName, import_code__c = refRule , ErrorSource__c = 'Execution Missing'));
                existingRules.remove(ruleName);
                errorRules.add(ruleName);
                      
               }
               if(existingRules.containsKey(ruleName)){
              existingRules.get(ruleName).DisplayfilterLogic__c = ruleWrapper.DisplayCriteria;
               }   
            if(existingAdvancedWorkflowMap.containsKey(workflowWrapper.name.trim())){
                  existingAdvancedWorkflowMap.get(workflowWrapper.name.trim()).Description__c = workflowWrapper.description;
                  // TO DO update fields
              }else if(workflowWrapper.name != null && workflowWrapper.name != ''){
                existingAdvancedWorkflowMap.put(workflowWrapper.name , new Advance_Workflow__c(Name = workflowWrapper.name ,
                Description__c = workflowWrapper.description , Object__c = objName));
              }
         }
         // if remove error rules from processing
         if(!errorRules.isEmpty()){
           for(String errorRule : errorRules){
             workflowWrapper.ruleWrapperMap.remove(errorRule);
           }
         }
          }
          if(!validateRules(wfWrapperMap, objectName)){
            return;
          }
          if(!lookupWrapperMap.isEmpty() && !validateLookupObjects()){
            return;
          }
          System.debug(':existingAdvancedWorkflowMap 2>>'+existingAdvancedWorkflowMap);
          if(!deleteRuleCriterias.isEmpty()){
            delete deleteRuleCriterias;
          }
          if(!deleteRuleActions.isEmpty()){
              delete deleteRuleActions;
              System.debug('::existing rule deleted');
              
          } 
          if(!existingAdvancedWorkflowMap.isEmpty() && AW_ImportCSV_Batch.advWorkflow == null){
            upsert existingAdvancedWorkflowMap.values(); 
            AW_ImportCSV_Batch.advWorkflow = existingAdvancedWorkflowMap.values().get(0);
          }
          if(!existingRules.isEmpty()){
            System.debug(':::existingRules before'+existingRules);
            existingRules = populateAdvWFInRule(existingRules);
            upsert existingRules.values();
            System.debug(':::existingRules'+existingRules);
          }
          
          if(!referenceFieldIdMap.isEmpty()){
            loadReferenceIds();
          }
          Actions(existingRules);
          Criteria(existingRules);
       
      }catch(Exception ex){
      Database.rollback(sp);
       ruleErrorMap.put(ObjectName, new Error_Log__c(Error_Rule_Name__c='NOT SPECIFIC RULE CATCH EXCEPTION', Object_Name__c=objectName,Error_Description__c = ex.getMessage() , import_code__c = refRule , ErrorSource__c = 'Error in parsing rule'));
      }
     
   }
   
   private static Map<String, Rule__c> populateAdvWFInRule(Map<String, Rule__c> existingRules){
       for(Rule__c rule : existingRules.values()){
         if(rule.Order__c != null && rule.Status__c == 'Active' && rule.Object__c != null && rule.Advance_Workflow__c == null && existingAdvancedWorkflowMap.containsKey(rule.Object__c)){
           rule.Advance_Workflow__c = existingAdvancedWorkflowMap.get(rule.Object__c).id;
         }
       }
       return existingRules;
     }
    
    /*
     * Initailize Maps
     */ 
     private static void initailize(){
        if(!wfWrapperMap.isEmpty()){
            for(String objectName : wfWrapperMap.keySet()){
                fieldsMap.put(objectName, globalDescribe.get(objectName).getDescribe().Fields.getMap());
                fieldWrapperMap.put(objectName, new Map<String, AW_ListRules.FieldWrapper>());
            }
        }
    }
    /*
     * validate and Parse Rule Actions
     */
    private static List<AW_ParseCSV_RuleActionWrapper> validationAndParseRuleActions(AW_ParseCSV_RuleWrapper ruleWrapper){
      List<AW_ParseCSV_RuleActionWrapper> ruleActions = new List<AW_ParseCSV_RuleActionWrapper>();
    if(ruleWrapper.DisplayActions == null || ruleWrapper.DisplayActions.trim() == '')
      return ruleActions;
    if(!ruleWrapper.DisplayActions.startsWith('<a')){
      ruleErrorMap.put(ruleWrapper.rule.Name , new Error_Log__c(Error_Rule_Name__c=ruleWrapper.advancedWorkflowName+ruleWrapper.rule.Name,  Object_Name__c=ruleWrapper.rule.Object__c ,Error_Description__c = 'Action is invalid and not started with <a in' + ruleWrapper.rule.Name , import_code__c = refRule , ErrorSource__c = 'Error in Rule Action CSV format' ));
      return new List<AW_ParseCSV_RuleActionWrapper>();
    }
    String[] splitRuleActions = ruleWrapper.DisplayActions.split(AW_Rule_Constants.ACTION_POSTFIX);
        for(String raStr : splitRuleActions){
          AW_ParseCSV_RuleActionWrapper ruleActionWrapper;
          System.debug('::ra Megha'+raStr);
            if(raStr.trim() != ''){
              raStr = raStr.trim().substring(2, raStr.trim().length());
              if(raStr.contains(':')){
                String actionType = raStr.subString(0, raStr.indexOf(AW_Rule_Constants.ACTION_TYPE_SEPARATOR));
                raStr = raStr.replace(actionType + AW_Rule_Constants.ACTION_TYPE_SEPARATOR, '').trim();
                System.debug(':actionType'+actionType);
                if(raStr != ''){
                  if(actionType == 'Update' || actionType == 'UpdateBulk'){
                    // process Rule Action for Field Update
                    ruleActionWrapper = processRAForFieldUpdate(ruleWrapper, raStr, actionType);
                  }else if(actionType == 'SendEmail' || actionType == 'ChatterNotification' || actionType == 'ApexJob' || actionType == 'SendEmailBulk' || actionType == 'ChatterNotificationBulk' || actionType == 'ApexJobBulk'){
                    // process Rule Action for Send Email , Chatter Notification, Apex Job
                    ruleActionWrapper = processRAForEmailAndNotification(ruleWrapper, raStr , actionType);
                    if(ruleActionWrapper.ruleAction.Related_Object__c == null){
                      ruleActionWrapper.ruleAction.Related_Object__c = ruleWrapper.rule.Object__c;
                    }
                  }else if(actionType == 'Insert' || actionType == 'InsertUnrelated' || actionType == 'Upsert' || actionType == 'UpsertUnrelated' || actionType == 'InsertBulk' || actionType == 'InsertUnrelatedBulk' || actionType == 'UpsertBulk' || actionType == 'UpsertUnrelatedBulk'){
                    // process Rule Action for Insert or upsert
                    ruleActionWrapper = processRAForInsertOrUpsert(ruleWrapper, raStr , actionType);
                  }
                  if(ruleActionWrapper.ruleAction.Type__c == null){
                    throw new AW_Exception('Action Type is not proper');
                  }
                  if(ruleWrapper.actionTypeCountMap.containsKey(ruleActionWrapper.ruleAction.Type__c.trim())){
                    ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Type__c.trim() , ruleWrapper.actionTypeCountMap.get(ruleActionWrapper.ruleAction.Type__c.trim()) + 1);
                  }else{
                    ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Type__c.trim() , 1);
                  }
                  //ruleAction.Related_Object__c = ruleWrapper.rule.Object__c;
                }
                System.debug('::raStr'+raStr +':::fieldsMap'+fieldsMap.get(ruleWrapper.rule.Object__c).containsKey('OwnerId'));
                  System.debug('::ruleActionWrapper'+ruleActionWrapper); 
                  if(ruleActionWrapper.ruleAction.Related_Object__c != null && ruleActionWrapper.ruleAction.Field_API_Name__c != null && !AW_Rule_Constants.allowedFieldSet.contains(ruleActionWrapper.ruleAction.Field_API_Name__c.trim().tolowerCase())){
                    addFieldsInWrapperMap(ruleActionWrapper.ruleAction , 'Field_API_Name__c' ,ruleActionWrapper.ruleAction.Related_Object__c.trim());
                    System.debug('::fieldWrapperMap'+fieldWrapperMap);
                    if(fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).containsKey(ruleActionWrapper.ruleAction.field_API_Name__c.toLowerCase().trim())){
                      ruleActionWrapper.ruleAction.Field_Type__c = fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(ruleActionWrapper.ruleAction.field_API_Name__c.toLowerCase().trim()).dataType;
                      if(ruleActionWrapper.ruleAction.Field_Type__c.equalsIgnoreCase('Reference') && ruleActionWrapper.ruleAction.value__c != null && !ruleActionWrapper.ruleAction.value__c.contains('{!') && !ruleActionWrapper.ruleAction.value__c.contains('}')){
                        for(String sobjName : fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(ruleActionWrapper.ruleAction.field_API_Name__c.toLowerCase().trim()).referenceToList){
                          if(!referenceFieldIdMap.containsKey(sobjName)){
                            referenceFieldIdMap.put(sobjName , new Map<String , Id>());
                          }
                          referenceFieldIdMap.get(sobjName).put(ruleActionWrapper.ruleAction.value__c.trim().toLowerCase(), null);
                        }
                      }
                    }else{
                      // ERROR 
                      System.debug('Error');
                      throw new AW_Exception('Field ' + ruleActionWrapper.ruleAction.Field_API_Name__c.trim() + ' does not exist on ' + ruleActionWrapper.ruleAction.Related_Object__c );
                    }
                  }
                  // Email Template
                  if(ruleActionWrapper.ruleAction.EmailTemplateName__c != null){
                    if(!referenceFieldIdMap.containsKey('EmailTemplate')){
                      referenceFieldIdMap.put('EmailTemplate' , new Map<String , Id>());
                    }
                    referenceFieldIdMap.get('EmailTemplate').put(ruleActionWrapper.ruleAction.EmailTemplateName__c.trim().toLowerCase(), null);
                  }
                  ruleActions.add(ruleActionWrapper); 
              }
            }
      }
      return ruleActions; 
    }
    
   /*
     * add Fields in Wrapper
     */ 
    public static void addFieldsInWrapperMap(Sobject sobj, String fieldName, String relatedObject){
      String fieldAPIName = String.valueOf(sobj.get(fieldName)).trim();
      System.debug('::relatedObject'+relatedObject);
      System.debug('::fieldAPIName'+fieldAPIName);
      if(!fieldWrapperMap.containsKey(relatedObject)){
          fieldWrapperMap.put(relatedObject , new Map<String, AW_ListRules.FieldWrapper>());
        }
        if(!fieldsMap.containsKey(relatedObject)){
          fieldsMap.put(relatedObject, globalDescribe.get(relatedObject).getDescribe().Fields.getMap());
        }
        System.debug('::fieldWrapperMap'+fieldWrapperMap +'::fieldsMap.get(relatedObject)'+fieldsMap.get(relatedObject));
      if(!fieldWrapperMap.get(relatedObject).containsKey(fieldAPIName.toLowerCase()) && fieldsMap.get(relatedObject).get(fieldAPIName.toLowerCase()) != null){
        Schema.DescribeFieldResult fieldResult = fieldsMap.get(relatedObject).get(fieldAPIName).getDescribe();
        AW_ListRules.FieldWrapper fieldWrapper = new AW_ListRules.FieldWrapper(fieldResult.getName(),fieldResult.getLabel(),fieldResult.getType().name(), fieldResult.getInlineHelpText());
        if(fieldResult.getReferenceTo() != null){ 
          for(Schema.Sobjecttype sobjType : fieldResult.getReferenceTo()){
                  fieldWrapper.referenceToList.add(sobjType.getDescribe().getName());
              } 
        }
        fieldWrapperMap.get(relatedObject).put(fieldAPIName.toLowerCase(), fieldWrapper);
      }
    }
    
 
    
    /*
     * Process Rule Atcin for Field Update
   */
    private static AW_ParseCSV_RuleActionWrapper processRAForFieldUpdate(AW_ParseCSV_RuleWrapper ruleWrapper , String actionString , String actionType){
      AW_ParseCSV_RuleActionWrapper ruleActionWrapper = new AW_ParseCSV_RuleActionWrapper(new RuleAction__c(Type__c = AW_Rule_Constants.actionTypeForImportMap.containsKey('Update') ? AW_Rule_Constants.actionTypeForImportMap.get('Update') : 'Update Field'));
      if(actionType.trim().endsWithIgnoreCase('bulk')){
        ruleActionWrapper.ruleAction.Bulk_API__c = true;
      }
      String[] splitedField = actionString.split(AW_Rule_Constants.ACTION_TYPE_SEPARATOR);
      System.debug('::splitedField'+splitedField);
      // if field update is crossObjectField
      if(splitedField.size() > 1 && splitedField[0] ==  AW_Rule_Constants.CROSSOBJECTFIELD){
        ruleActionWrapper.ruleAction.Related_Object__c = ruleWrapper.rule.Object__c;
        ruleActionWrapper.ruleAction.Field_API_Name__c = AW_Rule_Constants.CROSSOBJECT;
        ruleActionWrapper.ruleAction.Field_Name__c = AW_Rule_Constants.CROSSOBJECT;
        if(splitedField[1].contains(AW_Rule_Constants.EQUAL_SEPARATOR)){
          String[] crossSplitFd = splitedField[1].split(AW_Rule_Constants.EQUAL_SEPARATOR);
          ruleActionWrapper.ruleAction.CrossObjectField__c = (crossSplitFd.size() > 0 ? (crossSplitFd[0] != null && crossSplitFd[0].startsWith(ruleWrapper.rule.object__c +'.') ? crossSplitFd[0].replace(ruleWrapper.rule.object__c +'.' , '') : crossSplitFd[0]) : null);
          ruleActionWrapper.ruleAction.value__c = crossSplitFd.size() > 1 ? crossSplitFd[1] : null; 
        }
        ruleActionWrapper.ruleAction.Field_Type__c = 'STRING';
        if(ruleWrapper.actionTypeCountMap.containsKey(ruleActionWrapper.ruleAction.Field_API_Name__c.trim())){
          ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Field_API_Name__c.trim(), ruleWrapper.actionTypeCountMap.get(ruleActionWrapper.ruleAction.Type__c.trim()) + 1);
        }else{
          ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Field_API_Name__c.trim(), 1);
        }
        // TO DO Cross Object  
      }else if(splitedField.size() > 0 && splitedField[0] ==  AW_Rule_Constants.LOOKUPOBJECTFIELD){ // if field update is LookupObject field
        ruleActionWrapper.ruleAction.Related_Object__c = ruleWrapper.rule.Object__c;
        ruleActionWrapper.ruleAction.Field_API_Name__c = AW_Rule_Constants.LOOKUPOBJECTFIELD;
        ruleActionWrapper.ruleAction.Field_Name__c = AW_Rule_Constants.LOOKUPOBJECTFIELD;
        Map<String, String> lookupValues = new Map<String, String>();
        Integer stPoint = 1;
        if(splitedField.size() > 1){
          if(splitedField[1].trim().startsWith(ruleWrapper.rule.object__c + '.')){
            ruleActionWrapper.ruleAction.Lookup_Field_Name__c = splitedField[1].contains('.') ? splitedField[1].subString(splitedField[1].indexOf('.') + 1 , splitedField[1].length()) : splitedField[1];
            stPoint = 2;
          }
        }
        if(splitedField.size() > 2){
          for(Integer i = stPoint ; i < splitedField.size() ; i++){
            String[] sp = splitedField[i].trim().split(AW_Rule_Constants.EQUAL_SEPARATOR);
            System.debug('::sp'+sp);
            if(sp.size() > 1){
              if(sp.size() > 2){
                for(Integer j = 2 ; j < sp.size() ; j++){
                  sp[1] += '=' +sp[j];
                }
              }
              lookupValues.put(sp[0], sp[1]);
            }
          } 
          System.debug('::lookupValues'+lookupValues);
          if(!lookupValues.isEmpty()){
            if(lookupValues.containsKey(AW_Rule_Constants.LOOKUPOBJECT)){
              ruleActionWrapper.ruleAction.Lookup_Object__c = lookupValues.get(AW_Rule_Constants.LOOKUPOBJECT);
            }
            if(lookupValues.containsKey(AW_Rule_Constants.LOOKUPFIELD)){
              ruleActionWrapper.ruleAction.Lookup_Field_API_Name__c = lookupValues.get(AW_Rule_Constants.LOOKUPFIELD);
            }
            if(lookupValues.containsKey(AW_Rule_Constants.LOOKUPVALUE)){
              ruleActionWrapper.ruleAction.Value__c = lookupValues.get(AW_Rule_Constants.LOOKUPVALUE);
            }
            if(lookupValues.containsKey(AW_Rule_Constants.CONDITION)){
              ruleActionWrapper.ruleAction.Lookup_Where_Fields__c = lookupValues.get(AW_Rule_Constants.CONDITION);
            }
            if(ruleActionWrapper.ruleAction.Lookup_Object__c != null && ruleActionWrapper.ruleAction.Lookup_Field_API_Name__c  != null && ruleActionWrapper.ruleAction.Lookup_Where_Fields__c != null){
              if(!lookupWrapperMap.containsKey(ruleActionWrapper.ruleAction.Lookup_Object__c.trim())){
                lookupWrapperMap.put(ruleActionWrapper.ruleAction.Lookup_Object__c.trim() , new LookupWrapper(ruleActionWrapper.ruleAction.Lookup_Field_API_Name__c , '(' + ruleActionWrapper.ruleAction.Lookup_Where_Fields__c + ')'));
              }else{
                lookupWrapperMap.get(ruleActionWrapper.ruleAction.Lookup_Object__c.trim()).fieldsName += ' , ' + ruleActionWrapper.ruleAction.Lookup_Field_API_Name__c;
                lookupWrapperMap.get(ruleActionWrapper.ruleAction.Lookup_Object__c.trim()).whereCondition +=  ' AND (' + ruleActionWrapper.ruleAction.Lookup_Where_Fields__c + ')';
              }
            
            }
          }
          System.debug(ruleActionWrapper.ruleAction + '::lookupWrapperMap'+lookupWrapperMap);
          
        }  
        if(ruleWrapper.actionTypeCountMap.containsKey(ruleActionWrapper.ruleAction.Field_API_Name__c.trim())){
          ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Field_API_Name__c.trim(), ruleWrapper.actionTypeCountMap.get(ruleActionWrapper.ruleAction.Type__c.trim()) + 1);
        }else{
          ruleWrapper.actionTypeCountMap.put(ruleActionWrapper.ruleAction.Field_API_Name__c.trim(), 1);
        }
       }else if(splitedField.size() > 0 && splitedField[0] ==  AW_Rule_Constants.OWNERPRIORITIZATIONFIELD){ // if field is Owner Prioritization
        ruleActionWrapper = populateOwnerPrioritizationFields(ruleActionWrapper , splitedField);
        ruleActionWrapper.ruleAction.Related_Object__c = ruleWrapper.rule.Object__c;
        
      }
      else if(splitedField.size() > 0 && splitedField[0].contains(AW_Rule_Constants.EQUAL_SEPARATOR)){ // changed after managed package
        if(splitedField[0].trim().contains('.')  && !splitedField[0].trim().startsWith(ruleWrapper.rule.Object__c +'.') && !splitedField[0].trim().startsWith('whatId.')){
          String sobj = splitedField[0].trim().subString(0, splitedField[0].trim().indexOf('.'));
          if(sobj.endsWith('__r')){
            sobj = sobj.replace('__r', '__c');
          }
          ruleActionWrapper.ruleAction.Related_Object__c = sobj.trim();
        }else{
          ruleActionWrapper.ruleAction.Related_Object__c = ruleWrapper.rule.Object__c.trim();
        }
        ruleActionWrapper.ruleAction.Field_API_Name__c = splitedField[0].subString(0,splitedField[0].indexOf(AW_Rule_Constants.EQUAL_SEPARATOR)).replace(ruleActionWrapper.ruleAction.Related_Object__c +'.', '').toLowerCase();
        ruleActionWrapper.ruleAction.Field_Name__c = ruleActionWrapper.ruleAction.Field_API_Name__c;
        if(!fieldsMap.containsKey(ruleActionWrapper.ruleAction.Related_Object__c)){
          fieldsMap.put(ruleActionWrapper.ruleAction.Related_Object__c, globalDescribe.get(ruleActionWrapper.ruleAction.Related_Object__c).getDescribe().Fields.getMap());
        }
         if(fieldsMap.containsKey(ruleActionWrapper.ruleAction.Related_Object__c) && fieldsMap.get(ruleActionWrapper.ruleAction.Related_Object__c).containsKey(ruleActionWrapper.ruleAction.Field_API_Name__c.trim())){
              Schema.DescribeFieldResult fieldResult = fieldsMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(ruleActionWrapper.ruleAction.Field_API_Name__c.trim()).getDescribe();
              ruleActionWrapper.ruleAction.Field_Type__c =  fieldResult.getType().name();
              ruleActionWrapper.ruleAction.Field_API_Name__c = fieldResult.getName();
              ruleActionWrapper.ruleAction.Field_Name__c = ruleActionWrapper.ruleAction.Field_API_Name__c;
             }else{
               throw new AW_Exception(ruleActionWrapper.ruleAction.Field_API_Name__c + ' Field is not related to object :' +ruleActionWrapper.ruleAction.Related_Object__c);
             }
             String val = splitedField[0].replace(ruleActionWrapper.ruleAction.Related_Object__c + '.', '').replace(ruleActionWrapper.ruleAction.Field_API_Name__c + AW_Rule_Constants.EQUAL_SEPARATOR , '');
             // contains : in the value Eg link 
             if(splitedField.size() > 1){
               for(Integer i = 1 ; i < splitedField.size();i++){ 
                 if(splitedField[i] != ''){
                   val += AW_Rule_Constants.ACTION_TYPE_SEPARATOR + splitedField[i];
                 }
               }
             }
             if(val.contains('{!') && val.contains('}')){
               ruleActionWrapper.ruleAction.reference_Id__c = val;
             }
             if(val != '' && val.length() <= 255){
               ruleActionWrapper.ruleAction.Value__c = val;
             }else{
               ruleActionWrapper.ruleAction.Long_Value__c = val;
             }
             
        
      }
      if(ruleActionWrapper.ruleAction.Field_API_Name__c != null  && ruleActionWrapper.ruleAction.Field_API_Name__c != AW_Rule_Constants.CROSSOBJECT  &&
          ruleActionWrapper.ruleAction.Field_API_Name__c != AW_Rule_Constants.LOOKUPOBJECTFIELD 
          && ruleActionWrapper.ruleAction.Field_API_Name__c != AW_Rule_Constants.OWNERPRIORITIZATION && ruleActionWrapper.ruleAction.Related_Object__c != null){
        /*if(!objectFields.containsKey(ruleActionWrapper.ruleAction.Related_Object__c)){
          objectFields.put(ruleActionWrapper.ruleAction.Related_Object__c, new Set<String>());
        }
        objectFields.get(ruleActionWrapper.ruleAction.Related_Object__c).add(ruleActionWrapper.ruleAction.Field_API_Name__c);*/
      }
      if(ruleActionWrapper.ruleAction.value__c != null && ruleActionWrapper.ruleAction.Related_Object__c != null && (ruleActionWrapper.ruleAction.value__c.contains('&') || ruleActionWrapper.ruleAction.value__c.startsWith('{!'))){
        List<String> splitVaue = ruleActionWrapper.ruleAction.value__c.split('&');
        /*if(!objectFields.containsKey(ruleActionWrapper.ruleAction.Related_Object__c)){
          objectFields.put(ruleActionWrapper.ruleAction.Related_Object__c, new Set<String>());
        }*/
            for(String s:splitVaue){
                s=s.trim();
                if(s.startsWith('{!')){
                    String mergeField = s.substringBetween('{!','}');
                    //objectFields.get(ruleActionWrapper.ruleAction.Related_Object__c).add(mergeField.toLowerCase());
                }
            }
        }
      return ruleActionWrapper;   
    }
    
    /*
     * Process Rule Atcin for Owner Prioritization
   */
    private static AW_ParseCSV_RuleActionWrapper populateOwnerPrioritizationFields(AW_ParseCSV_RuleActionWrapper ruleActionWrapper , String[] splitedField){
    ruleActionWrapper.ruleAction.Field_API_Name__c = AW_Rule_Constants.OWNERPRIORITIZATION;
    ruleActionWrapper.ruleAction.Field_Name__c = AW_Rule_Constants.OWNERPRIORITIZATION;
    System.debug(':::splitedField'+splitedField +'::::::splitedField'+splitedField.size());
    System.debug(':::splitedField[0]'+splitedField[0] +'::::::splitedField[1]'+splitedField[1]);
    if(splitedField.size() > 2){
      String[] ownerPriorityRecords = splitedField[2].split(AW_Rule_Constants.FIELD_SEPARATOR);
      System.debug(':::ownerPriorityRecords'+ownerPriorityRecords +'::ruleActionMapping'+ruleActionMapping);
      System.debug('::ruleActionMapping >>>'+ruleActionMapping.get('OwnerPrioritization__c:' + AW_Rule_Constants.OWNERPRIORITIZATION));
      ruleActionWrapper.ruleAction.prioritization_Method__c = ownerPriorityRecords.size() > 0 && ownerPriorityRecords[0].startsWith('Method') ? splitedField[0].replace('Method=', '') : null;
      for(Integer i = 1; i < ownerPriorityRecords.size(); i++){ 
        String[] ownerPriorityFields = ownerPriorityRecords[i].split(AW_Rule_Constants.OP_SEPARATOR);
        OwnerPrioritization__c ownerPrioritization = new OwnerPrioritization__c();
        for(String opFd : ownerPriorityFields){
          System.debug('::opFd'+opFd);
          String[] params = opFd.split(AW_Rule_Constants.EQUAL_SEPARATOR);
          System.debug('::params'+params);
          if(params.size() > 1 && ruleActionMapping.containsKey('OwnerPrioritization__c:' + AW_Rule_Constants.OWNERPRIORITIZATION) && ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).containsKey(params[0].trim()) && params[1] != null){
            if(( ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).get(params[0].trim()) == 'Priority__c' || ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).get(params[0].trim()) == 'Weight__c' )){ 
              ownerPrioritization.put(ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).get(params[0].trim()) , Decimal.valueOf(params[1].trim()));
            }else if(ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).get(params[0].trim()) == 'User_Queue_Group__c'){
              ownerPrioritization.put(ruleActionMapping.get('OwnerPrioritization__c:'+ AW_Rule_Constants.OWNERPRIORITIZATION).get(params[0].trim()) , params[1].trim());
              if(!referenceFieldIdMap.containsKey('User')){
                        referenceFieldIdMap.put('User' , new Map<String , Id>());
                      }
                      referenceFieldIdMap.get('User').put(params[1].trim().toLowerCase(), null);
                      if(!referenceFieldIdMap.containsKey('Group')){
                        referenceFieldIdMap.put('Group' , new Map<String , Id>());
                      }
                      referenceFieldIdMap.get('Group').put(params[1].trim().toLowerCase(), null);
            }
          }
        } 
        ruleActionWrapper.ownerPrioritizationList.add(ownerPrioritization);
      }
    }
    return ruleActionWrapper;
    }
    
     /*
     * Process Rule Atcin for Send Email , Chatter Notificaiton, Apex Job
    */
    private static AW_ParseCSV_RuleActionWrapper processRAForEmailAndNotification(AW_ParseCSV_RuleWrapper ruleWrapper , String actionString , String actionType){
      AW_ParseCSV_RuleActionWrapper ruleActionWrapper = new AW_ParseCSV_RuleActionWrapper(new RuleAction__c());
      if(actionType.trim().endsWithIgnoreCase('Bulk')){
        ruleActionWrapper.ruleAction.Bulk_API__c = true;
        actionType = actionType.replace('Bulk' , '').replace('bulk' ,''); 
      }
      if(AW_Rule_Constants.actionTypeForImportMap.containsKey(actionType)){
        ruleActionWrapper.ruleAction.Type__c = AW_Rule_Constants.actionTypeForImportMap.get(actionType);
      }
        if(ruleActionWrapper.ruleAction.Type__c == 'Chatter Notification' && actionString.contains(AW_Rule_Constants.ACTION_TYPE_SEPARATOR)){
          ruleActionWrapper.ruleAction.Related_Object__c = actionString.subString(0,actionString.indexOf(AW_Rule_Constants.ACTION_TYPE_SEPARATOR));
          actionString = actionString.replace(ruleActionWrapper.ruleAction.Related_Object__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR, ''); 
          
        }
        System.debug(':actionString'+actionString);
      String[] splitedField = actionString.split(AW_Rule_Constants.FIELD_SEPARATOR);
      System.debug(':splitedField'+splitedField);
      for(Integer i = 0;i < splitedField.size(); i++){  
        String[] splitFd = splitedField[i].split(AW_Rule_Constants.EQUAL_SEPARATOR); 
        if(splitFd.size() == 2 && ruleActionMapping.containsKey('RuleAction__c:' +ruleActionWrapper.ruleAction.Type__c.trim()) && ruleActionMapping.get('RuleAction__c:' +ruleActionWrapper.ruleAction.Type__c.trim()).containsKey(splitFd[0].trim())){
          System.debug(':splitFd[0]'+splitFd[0] +'::splitFd[1]'+splitFd[1] +ruleActionMapping.get('RuleAction__c:' +ruleActionWrapper.ruleAction.Type__c));
          if(splitFd[0] == 'SendToGroup' || splitFd[0] == 'SendToUser' || splitFd[0] == 'User'){
            ruleActionWrapper.sendTo = splitFd[0] == 'SendToGroup' ? 'CollaborationGroup' : 'User';
          if(!referenceFieldIdMap.containsKey(ruleActionWrapper.sendTo)){
                    referenceFieldIdMap.put(ruleActionWrapper.sendTo , new Map<String , Id>());
                  }
                  ruleActionWrapper.userOwnerName = splitFd[1];
                referenceFieldIdMap.get(ruleActionWrapper.sendTo).put(splitFd[1].trim().toLowerCase(), null);
              }else if(ruleActionMapping.get('RuleAction__c:' +ruleActionWrapper.ruleAction.Type__c).containsKey(splitFd[0].trim())){
            ruleActionWrapper.ruleAction.put(ruleActionMapping.get('RuleAction__c:' +ruleActionWrapper.ruleAction.Type__c).get(splitFd[0].trim()), splitFd[1]);
            /*if(ruleActionWrapper.ruleAction.Type__c == 'Execute an Apex Job' && splitFd[0] == 'ApexClass'){
              apexClasses.add(splitFd[1]);
            }*/
          }
        }
        if(ruleActionWrapper.ruleAction.Type__c == 'Send Email' && ruleActionWrapper.ruleAction.EmailTemplateName__c != null){
              if(!referenceFieldIdMap.containsKey('EmailTemplate')){
                  referenceFieldIdMap.put('EmailTemplate' , new Map<String , Id>());
                }
                referenceFieldIdMap.get('EmailTemplate').put(ruleActionWrapper.ruleAction.EmailTemplateName__c.trim().toLowerCase(), null);
            }
      }     
      return ruleActionWrapper;  
        
    }
    
    /*
     * Process Rule Atcin for Insert and Upsert objects
    */
    public static AW_ParseCSV_RuleActionWrapper processRAForInsertOrUpsert(AW_ParseCSV_RuleWrapper ruleWrapper , String actionString , String actionType){
      AW_ParseCSV_RuleActionWrapper ruleActionWrapper = new AW_ParseCSV_RuleActionWrapper(new RuleAction__c());
      if(actionType.trim().endsWithIgnoreCase('bulk')){
        ruleActionWrapper.ruleAction.Bulk_API__c = true;
        actionType = actionType.replace('Bulk' , '').replace('bulk' ,'');
      }
      if(AW_Rule_Constants.actionTypeForImportMap.containsKey(actionType)){
        ruleActionWrapper.ruleAction.Type__c = AW_Rule_Constants.actionTypeForImportMap.get(actionType);
      } 
      if(actionType.contains('Insert') || actionType.contains('Upsert')){
        //<aInsert:Integration__c~Status__c=New~LastRun__c={!SLAExpirationDate__c} +3d/a>
        String[] splitedAction = actionString.split('~');
        if(splitedAction.size() > 0){
          if(globalDescribe.get(splitedAction[0].trim()) != null){
            ruleActionWrapper.ruleAction.Related_Object__c = splitedAction[0];
            for(Integer i = 1; i < splitedAction.size(); i++){
              String[] valueSplit = splitedAction[i].split('=');
              if(valueSplit.size() == 2){
                Values_for_Action_Insert_Record__c valAIR = new Values_for_Action_Insert_Record__c(Name = valueSplit[0].toLowerCase() , Value__c = valueSplit[1]);
                if(valAIR.value__c.contains('{!') && valAIR.value__c.contains('}')){
                  valAIR.reference_Id__c = valAIR.value__c;
                  /*if(!objectFields.containsKey(ruleWrapper.rule.Object__c)){
                    objectFields.put(ruleWrapper.rule.Object__c , new Set<String>());
                  }
                  objectFields.get(ruleWrapper.rule.Object__c).add(valAIR.value__c.substringBetween('{!','}'));*/
                }
                /*if(!objectFields.containsKey(ruleActionWrapper.ruleAction.Related_Object__c)){
                objectFields.put(ruleActionWrapper.ruleAction.Related_Object__c , new Set<String>());
              }
                objectFields.get(ruleActionWrapper.ruleAction.Related_Object__c).add(valAIR.Name);*/
                addFieldsInWrapperMap(valAIR , 'Name' ,ruleActionWrapper.ruleAction.Related_Object__c.trim());
              System.debug('::fieldWrapperMap in Child'+fieldWrapperMap); 
              if(!fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).containsKey(valAIR.Name.toLowerCase().trim())){
                throw new AW_Exception(valAIR.Name + ' field does not exist on ' + ruleActionWrapper.ruleAction.Related_Object__c); 
              }else{
                valAIR.Name = fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(valAIR.Name.toLowerCase().trim()).apiName;
              }
                      if(fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).containsKey(valAIR.Name.toLowerCase().trim()) && fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(valAIR.Name.toLowerCase().trim()).dataType.equalsIgnoreCase('Reference') && valAIR.Value__c != null && valAIR.reference_Id__c == null){
                        for(String sobjName : fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(valAIR.Name.toLowerCase().trim()).referenceToList){
                          if(!referenceFieldIdMap.containsKey(sobjName)){
                            referenceFieldIdMap.put(sobjName , new Map<String , Id>());
                          }
                          referenceFieldIdMap.get(sobjName).put(valAIR.Value__c.trim().toLowerCase(), null);
                        }
                      }
                      ruleActionWrapper.insertRecordValues.add(valAIR);
              }
            }
          }else{
            throw new AW_Exception(splitedAction[0].trim() + ' Object does not exist');  
          }
        }
      }
      return ruleActionWrapper;
      
    }
    
       /*
    * validate Rules
    */
    public static Boolean validateRules(Map<String, AW_ParseCSV_WorkflowWrapper> wfAdvanceObject, String objectName){
       
         if(wfAdvanceObject.isEmpty()){
           return true;
         }
          //field map of the object
          Map<String,Map<String,Schema.SObjectField>> fieldMap;
            
         //store all the relationships names
         Map<String,String> relationshipNames = new Map<String,String>();
         Map<String,Set<String>> validRelationShips= new Map<String,Set<String>>();   
         Map<String,Set<String>> criteriaFields = new Map<String,Set<String>>();
         
         for(String sobjectName : wfAdvanceObject.keyset()){
     AW_ParseCSV_WorkflowWrapper workflowWrapper = wfAdvanceObject.get(sobjectName);
     
         Schema.DescribeSObjectResult R = globalDescribe.get(sobjectName).getDescribe();
         
         Set<String> objectDefinedInCriteria = new Set<String>();
         Map<String,Advance_Workflow_Limits__c> lims = Advance_Workflow_Limits__c.getAll();
         for(AW_ParseCSV_RuleWrapper rule : workflowWrapper.ruleWrapperMap.values()){
              /* Rules can have criteria from its related object also */
              for(AW_ParseCSV_RuleCriteriaWrapper cr : rule.ruleCriteriaList){ 
               // related object set 
        if(cr.ruleCriteria.related_Object__c != null && !objectDefinedInCriteria.contains(cr.ruleCriteria.related_Object__c.toLowerCase())){
          objectDefinedInCriteria.add(cr.ruleCriteria.related_Object__c.toLowerCase());      
        }
             }
             
              for(AW_ParseCSV_RuleActionWrapper ac : rule.ruleActionList){  
        if(ac.ruleAction.Related_Object__c != null && !objectDefinedInCriteria.contains(ac.ruleAction.Related_Object__c.toLowerCase())){
          objectDefinedInCriteria.add(ac.ruleAction.Related_Object__c.toLowerCase());      
        }
             }
             validateActionLimits(rule , lims);
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
             
             
            for(AW_ParseCSV_RuleWrapper rule : workflowWrapper.ruleWrapperMap.values()){ 
        for(AW_ParseCSV_RuleCriteriaWrapper cr : rule.ruleCriteriaList){
           Set<String> fieldToAdd = criteriaFields.get(cr.ruleCriteria.related_Object__c.toLowerCase())!=null ? criteriaFields.get(cr.ruleCriteria.related_Object__c.toLowerCase()): new Set<String>(); 
           if(cr.ruleCriteria.Field_API_Name__c.toLowerCase() =='crossformula' && cr.ruleCriteria.Crossformula__c != null)
            fieldToAdd.add(cr.ruleCriteria.Crossformula__c.trim().toLowerCase());   
           else if(cr.ruleCriteria.Field_API_Name__c != 'OwnerName' && !cr.ruleCriteria.Field_API_Name__c.trim().contains(AW_Rule_Constants.GLOBAL_VARIABLE))
            fieldToAdd.add(cr.ruleCriteria.Field_API_Name__c.trim().toLowerCase()); 
          String value = cr.ruleCriteria.Matching_Value__c;
          if(value != null && (value.contains('&') || value.startsWith('{!'))){
            List<String> splitVaue = value.split('&');
            for(String s:splitVaue){
              s=s.trim(); 
              if(s.startsWith('{!')){  
                String mergeField= s.substringBetween('{!','}');
                fieldToAdd.add( mergeField.toLowerCase());
              }
            }
          }  
          criteriaFields.put(cr.ruleCriteria.related_Object__c.toLowerCase(),fieldToAdd);      
        }
        for(AW_ParseCSV_RuleActionWrapper ac : rule.ruleActionList){
          system.debug('::ac'+ac);   
          if(ac.ruleAction.Type__c == 'Update Field' && ac.ruleAction.Related_Object__c != null){
            Set<String> fieldToAdd = criteriaFields.get(ac.ruleAction.Related_Object__c.toLowerCase())!= null ? criteriaFields.get(ac.ruleAction.Related_Object__c.toLowerCase()): new Set<String>(); 
            if(ac.ruleAction.Field_API_Name__c != null && !AW_Rule_Constants.allowedFieldSet.contains(ac.ruleAction.Field_API_Name__c.trim().tolowerCase())){
              if(!fieldToAdd.contains(ac.ruleAction.Field_API_Name__c)){
                fieldToAdd.add(ac.ruleAction.Field_API_Name__c.trim().toLowerCase());
              }
            }else if(ac.RuleAction.Field_API_Name__c == AW_Rule_Constants.CROSSOBJECT && ac.RuleAction.crossObjectField__c != null && !ac.RuleAction.crossObjectField__c.toLowerCase().startsWith('what') && !ac.RuleAction.crossObjectField__c.toLowerCase().startsWith('task.what')){
              if(!fieldToAdd.contains(ac.ruleAction.crossObjectField__c.toLowerCase())){
                fieldToAdd.add(ac.ruleAction.crossObjectField__c.trim().toLowerCase());
              } 
            }
            String value = ac.ruleAction.value__c !=null && ac.ruleAction.value__c.trim()!=''? ac.ruleAction.value__c:ac.ruleAction.Long_Value__c;
            if(value != null && (value.contains('&') || value.startsWith('{!'))){
              List<String> splitVaue = value.split('&');
              for(String s:splitVaue){
                s=s.trim(); 
                if(s.startsWith('{!')){   
                  String mergeField= s.substringBetween('{!','}');
                  fieldToAdd.add( mergeField.toLowerCase());
                }
              }
            }
            criteriaFields.put(ac.ruleAction.Related_Object__c.toLowerCase(),fieldToAdd);   
          }                         
        }
            }
        }
         
         Set<String> parentFields = criteriaFields.get(objectName.toLowerCase());      
         if(parentFields != null && parentFields.size() > 0){
           system.debug('-->parentFields  '+parentfields);
            String fields = AW_AdvanceWorkflowExecutionHelper.joinSet(parentFields,',');
           system.debug('-->AW_PArse.fields  '+fields);
           
           String qrySOQL='SELECT ' + fields +',Id ';
          
              //now add the child queries also as they need to be evaluated in the query :)
              for(String obj:criteriaFields.keySet()){
                  if(obj.equalsIgnoreCase(objectName)) continue;
                  fields =AW_AdvanceWorkflowExecutionHelper.joinSet(criteriaFields.get(obj),',');
                  qrySOQL+=' , (SELECT ' + fields +',Id FROM '+relationshipNames.get(obj)+')';                        
              } 
        
          qrySOQL+=' FROM '+objectName+' LIMIT 1';
          system.debug(qrySOQL);
         
          try{
              List<SObject> sobjectRecords = database.query(qrySOQL);   
          }catch(Exception e){
              ruleErrorMap.put(objectName , new Error_Log__c(Error_Rule_Name__c ='CATCH EXCEPTION',Object_Name__c=objectName,Error_Description__c = e.getMessage() , import_code__c = refRule , ErrorSource__c =  'Field Not Found', Log_Execution__c=qrySOQL));
              return false;
          }
         }
        return true;
    } 
    
     /*
     * Process Rule Atcin
    */
    public static void Actions(Map<String , Rule__c> existingRules){
        Map<Integer, RuleAction__c> ruleActionsToBeInserted = new Map<Integer, RuleAction__c>();
        Map<Integer, AW_ParseCSV_RuleActionWrapper> insertChildRecordsRuleActionWrapper = new Map<Integer, AW_ParseCSV_RuleActionWrapper>();
        Integer uniqueKey = 1001;
        for(String objName : wfWrapperMap.keySet()){
          AW_ParseCSV_WorkflowWrapper wfWrapper = wfWrapperMap.get(objName);
          for(String ruleName : wfWrapper.ruleWrapperMap.keySet()){
            if(existingRules.containsKey(ruleName)){
                Id ruleId = existingRules.get(ruleName).Id;
                for(AW_ParseCSV_RuleActionWrapper ruleActionWrapper : wfWrapper.ruleWrapperMap.get(ruleName).ruleActionList){
                    ruleActionWrapper.ruleAction.Rule__c = ruleId;
                    ruleActionWrapper.uniqueKey = uniqueKey;
                    // populate Reference field
                    if(ruleActionWrapper.ruleAction.Related_Object__c != null && ruleActionWrapper.ruleAction.Field_Type__c != null && ruleActionWrapper.ruleAction.Field_Type__c.equalsIgnoreCase('Reference') 
                          && ruleActionWrapper.ruleAction.value__c != null && !ruleActionWrapper.ruleAction.value__c.contains('{!') && !ruleActionWrapper.ruleAction.value__c.contains('}') && ruleActionWrapper.ruleAction.Field_API_Name__c != null 
                          && fieldWrapperMap.containsKey(ruleActionWrapper.ruleAction.Related_Object__c) 
                          &&  fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).containsKey(ruleActionWrapper.ruleAction.Field_API_Name__c.toLowerCase().trim())){
                      for(String sobjName  : fieldWrapperMap.get(ruleActionWrapper.ruleAction.Related_Object__c).get(ruleActionWrapper.ruleAction.Field_API_Name__c.toLowerCase().trim()).referenceToList){
                        System.debug(':::referenceFieldIdMap.get(sobjName)'+referenceFieldIdMap.get(sobjName));
                        if(referenceFieldIdMap.containsKey(sobjName) && referenceFieldIdMap.get(sobjName).containsKey(ruleActionWrapper.ruleAction.value__c.trim().toLowerCase()) && referenceFieldIdMap.get(sobjName).get(ruleActionWrapper.ruleAction.value__c.trim().toLowerCase()) != null){
                          ruleActionWrapper.ruleAction.Reference_Id__c = referenceFieldIdMap.get(sobjName).get(ruleActionWrapper.ruleAction.value__c.trim().toLowerCase());
                          break;
                        }
                      }
                      if(ruleActionWrapper.ruleAction.value__c != null && !ruleActionWrapper.ruleAction.value__c.contains('{!') && !ruleActionWrapper.ruleAction.value__c.contains('}') && ruleActionWrapper.ruleAction.Reference_Id__c == null){
                        throw new AW_Exception(ruleActionWrapper.ruleAction.value__c + ' does not exist for reference field ' + ruleActionWrapper.ruleAction.Field_API_Name__c);
                      }
                    }
                    // testing debug
                    System.debug(':ruleActionWrapper.sendTo' +ruleActionWrapper.sendTo);
                    System.debug(':referenceFieldIdMap' +referenceFieldIdMap);
                    System.debug(':referenceFieldIdMap.contains' +referenceFieldIdMap.containsKey(ruleActionWrapper.sendTo));
                    System.debug(':referenceFieldIdMap.get' +referenceFieldIdMap.get(ruleActionWrapper.sendTo));
                    System.debug(':folderIdMap.get' +folderIdMap);
                    if(ruleActionWrapper.sendTo != null && ruleActionWrapper.sendTo != '' && referenceFieldIdMap.containsKey(ruleActionWrapper.sendTo) 
                          && referenceFieldIdMap.get(ruleActionWrapper.sendTo).containsKey(ruleActionWrapper.userOwnerName.trim().toLowerCase())){
                      if(referenceFieldIdMap.get(ruleActionWrapper.sendTo).get(ruleActionWrapper.userOwnerName.trim().toLowerCase()) != null){
                        ruleActionWrapper.ruleAction.User_Owner_Id__c = referenceFieldIdMap.get(ruleActionWrapper.sendTo).get(ruleActionWrapper.userOwnerName.trim().toLowerCase());      
                        }else{
                        throw new AW_Exception(ruleActionWrapper.userOwnerName + ' does not exist in ' + ruleActionWrapper.sendTo);
                       }
                    } 
                    if(ruleActionWrapper.ruleAction.EmailTemplateName__c != null && referenceFieldIdMap.containsKey('EmailTemplate') && referenceFieldIdMap.get('EmailTemplate').containsKey(ruleActionWrapper.ruleAction.EmailTemplateName__c.trim().toLowerCase()) && referenceFieldIdMap.get('EmailTemplate').get(ruleActionWrapper.ruleAction.EmailTemplateName__c.trim().toLowerCase()) != null){
                      ruleActionWrapper.ruleAction.Email_Template__c = referenceFieldIdMap.get('EmailTemplate').get(ruleActionWrapper.ruleAction.EmailTemplateName__c.trim().toLowerCase());
                      if(folderIdMap.containsKey(ruleActionWrapper.ruleAction.Email_Template__c.trim())){
                        ruleActionWrapper.ruleAction.Email_Template_Folder__c = folderIdMap.get(ruleActionWrapper.ruleAction.Email_Template__c.trim());
                      }
                    }
                    ruleActionsToBeInserted.put(uniqueKey, ruleActionWrapper.ruleAction);
                    if(ruleActionWrapper.insertRecordValues != null && ruleActionWrapper.insertRecordValues.size() > 0){
                      insertChildRecordsRuleActionWrapper.put(uniqueKey,ruleActionWrapper);
                    }
                    if(ruleActionWrapper.ownerPrioritizationList != null && ruleActionWrapper.ownerPrioritizationList.size() > 0){
                      insertChildRecordsRuleActionWrapper.put(uniqueKey,ruleActionWrapper);
                    }
                    uniqueKey++;
                }
              }
          }
        }
        System.debug('::ruleActionsToBeInserted'+ruleActionsToBeInserted); 
        if(!ruleActionsToBeInserted.isEmpty()){  
            insert ruleActionsToBeInserted.values(); 
            if(!insertChildRecordsRuleActionWrapper.isEmpty()){
              processInsertedValues(ruleActionsToBeInserted , insertChildRecordsRuleActionWrapper);
            }
        } 
        
    }
    
    /*
     * Process Action Insert Record Values
    */
    private static void processInsertedValues(Map<Integer, RuleAction__c> ruleActionsToBeInserted , Map<Integer, AW_ParseCSV_RuleActionWrapper> insertValuesRuleWrapper){
      List<Values_for_Action_Insert_Record__c> valuesForActionRecords = new List<Values_for_Action_Insert_Record__c>();
      List<OwnerPrioritization__c> ownerPrioritizationRecords = new List<OwnerPrioritization__c>();
      for(Integer key : insertValuesRuleWrapper.keySet()){
        String relSobjName = ruleActionsToBeInserted.get(key).Related_Object__c;
        
        for(Values_for_Action_Insert_Record__c valAIR : insertValuesRuleWrapper.get(key).insertRecordValues){
          valAIR.Rule_Action__c = ruleActionsToBeInserted.get(key).id;
          if(fieldWrapperMap.get(relSobjName).containsKey(valAIR.Name.toLowerCase().trim()) && fieldWrapperMap.get(relSobjName).get(valAIR.Name.toLowerCase().trim()).dataType.equalsIgnoreCase('Reference') && valAIR.Value__c != null && valAIR.reference_Id__c == null){
              Boolean isExist = false;
              for(String sobjName : fieldWrapperMap.get(relSobjName).get(valAIR.Name.toLowerCase().trim()).referenceToList){
                    System.debug(':::Value referenceFieldIdMap.get(sobjName)'+referenceFieldIdMap.get(sobjName));
                    if(referenceFieldIdMap.containsKey(sobjName) && referenceFieldIdMap.get(sobjName).containsKey(valAIR.Value__c.trim().toLowerCase()) && referenceFieldIdMap.get(sobjName).get(valAIR.Value__c.trim().trim().toLowerCase()) != null){
                      valAIR.Reference_Id__c = referenceFieldIdMap.get(sobjName).get(valAIR.Value__c.trim().toLowerCase());
                      isExist = true;
                      break;
                    }
                }
                if(!isExist){
                  throw new AW_Exception(valAIR.Value__c.trim() + ' does not exist for Lookup field '+ valAIR.Name.trim());
                }
                
              }
          valuesForActionRecords.add(valAIR);
        }
        for(OwnerPrioritization__c op : insertValuesRuleWrapper.get(key).ownerPrioritizationList){
          op.RuleAction__c = ruleActionsToBeInserted.get(key).id;
          if(op.User_Queue_Group__c != null){
            if(referenceFieldIdMap.containsKey('User') && referenceFieldIdMap.get('User').get(op.User_Queue_Group__c.toLowerCase()) != null){
              op.User_Queue_Group_Id__c = referenceFieldIdMap.get('User').get(op.User_Queue_Group__c);
            }else{
              throw new AW_Exception(op.User_Queue_Group__c + ' Owner is not exist for Owner Priortization Action ');
            }
          }
          ownerPrioritizationRecords.add(op);
        }
      }
      if(!valuesForActionRecords.isEmpty()){
        insert valuesForActionRecords;
      }
      if(!ownerPrioritizationRecords.isEmpty()){
        insert ownerPrioritizationRecords;
      }
    } 
    
    /*
     * Load Reference Id
    */
    private static void loadReferenceIds(){
      for(String objName : referenceFieldIdMap.keySet()){
        Set<String> names = referenceFieldIdMap.get(objName).keySet();
        String soqlQuery = ' SELECT Id , Name';
        if(objName == 'EmailTemplate'){ 
          soqlQuery += ', Folder.Id ';
        } 
         soqlQuery += ' FROM '+ objName  + ' WHERE  Name in : names';
        for(Sobject sobj : Database.query(soqlQuery)){
          referenceFieldIdMap.get(objName).put(((String)sobj.get('Name')).toLowerCase() ,(Id) sobj.get('Id'));
          if(objName == 'EmailTemplate' && sobj.getSobject('Folder') != null){
            folderIdMap.put((String)sobj.get('Id') ,(String)((Folder)sobj.getSobject('Folder')).get('Id'));
          }
        } 
      }
    }
    
    /*
     * Process Rule Criteria
    */
    public static void Criteria(Map<String , Rule__c> existingRules){
        List<RuleCriteria__c> ruleCriteriaToBeInserted = new List<RuleCriteria__c>();
        Map<String, Map<String, schema.recordtypeinfo>> recordTypeMap = new Map<String, Map<String, schema.recordtypeinfo>>(); 
         for(String objName : wfWrapperMap.keySet()){
          AW_ParseCSV_WorkflowWrapper wfWrapper = wfWrapperMap.get(objName);
          
          for(String ruleName : wfWrapper.ruleWrapperMap.keySet()){
              Id ruleId = existingRules.get(ruleName).Id;
              for(AW_ParseCSV_RuleCriteriaWrapper ruleCriteriaWrapper : wfWrapper.ruleWrapperMap.get(ruleName).ruleCriteriaList){
                  ruleCriteriaWrapper.ruleCriteria.Rule__c = ruleId;  
                  if(ruleCriteriaWrapper.ruleCriteria.Related_Object__c != null && ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != null && ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c == 'RecordTypeId' && ruleCriteriaWrapper.ruleCriteria.Matching_Value__c != null){
                     
                    if(!recordTypeMap.containsKey(ruleCriteriaWrapper.ruleCriteria.Related_Object__c) && globalDescribe.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c.trim()) != null){
                      recordTypeMap.put(ruleCriteriaWrapper.ruleCriteria.Related_Object__c ,globalDescribe.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c.trim()).getDescribe().getRecordTypeInfosByName());
                    }
                    if(recordTypeMap.containsKey(ruleCriteriaWrapper.ruleCriteria.Related_Object__c)){
                      String[] recTypes = ruleCriteriaWrapper.ruleCriteria.Matching_Value__c.split(PICKLIST_VALUE_DELIMETER);
                      ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c = '';
                      for(String recType : recTypes){
                        
                       if(recordTypeMap.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c).containsKey(recType.trim())){
                        ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c += recordTypeMap.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c).get(recType.trim()).getRecordTypeId() + PICKLIST_VALUE_DELIMETER;
                       }else{
                         throw new AW_Exception('Record Type ' + recType + ' does not exist on '+ruleCriteriaWrapper.ruleCriteria.Related_Object__c);
                       }
                       }
                       if(ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c != null && ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c.endsWith(PICKLIST_VALUE_DELIMETER)){
                            ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c = ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c.subString(0, ruleCriteriaWrapper.ruleCriteria.Record_Type_Id__c.lastIndexOf(PICKLIST_VALUE_DELIMETER));
                       }
                    }
                  } 
                  
                  ruleCriteriaToBeInserted.add(ruleCriteriaWrapper.ruleCriteria);
              }
          }
         }
        System.debug('::ruleCriteriaToBeInserted'+ruleCriteriaToBeInserted);
        if(!ruleCriteriaToBeInserted.isEmpty()){
            insert ruleCriteriaToBeInserted;
        }
    }
    // validate Lookup Objects in the rule actions
    private static Boolean validateLookupObjects(){
      Advance_Workflow_Limits__c lookupObjectFieldLimit = Advance_Workflow_Limits__c.getInstance('LookupObjectFieldLimit') ;
      System.debug(':;LookupWrapperMap'+LookupWrapperMap);
      Integer maxLookup = lookupObjectFieldLimit != null && lookupObjectFieldLimit.value__c != null ? Integer.valueOf(lookupObjectFieldLimit.value__c) : 10;
      if(LookupWrapperMap.size() > maxLookup) {
          ruleErrorMap.put('More Lookup Objects' , new Error_Log__c(Error_Description__c ='There are more than 10 Lookup Object related action. Please import those action saparately', import_code__c = refRule , Object_Method_Name__c='AW_ParseCSVTo_AdvanceWorkflow_Util.validateLookupObjects',ErrorSource__c = 'LookupObject'));
          return false;
      }
      try{
        for(String objectName : LookupWrapperMap.keySet()){
            string query = 'select '+LookupWrapperMap.get(objectName).fieldsName +' from '+objectName;
              if(LookupWrapperMap.get(objectName).whereCondition != null){
                  query += ' where '+ LookupWrapperMap.get(objectName).whereCondition;
              }
              System.debug('::query'+query);
              DataBase.query(query+'  limit 1');
          }
      }
        catch(Exception ex){
            ruleErrorMap.put('Lookup Object Fields Issue' , new Error_Log__c(Error_Description__c = 'Issue in Lookup Object type : '+ex.getMessage(), import_code__c = refRule , Object_Method_Name__c='AW_ParseCSVTo_AdvanceWorkflow_Util.validateLookupObjects', ErrorSource__c = 'LookupObject'));
            return false;
        }
        return true;
    }
    
    // limits check
    private static void validateActionLimits(AW_ParseCSV_RuleWrapper rule , Map<String,Advance_Workflow_Limits__c> lims){
      if(rule.actionTypeCountMap.containsKey('Execute Apex Job') && lims.get('NumApexJobsperRule')!= null && lims.get('NumApexJobsperRule').Value__c < rule.actionTypeCountMap.get('Execute Apex Job')){
           throw new AW_Exception('Apex Job Limit of ' + lims.get('NumApexJobsperRule').Value__c +' Exceeded in ' + rule.rule.Name);
        }
            
        if(rule.actionTypeCountMap.containsKey('Send Email') && lims.get('NumEmailActionsperRule')!=null && lims.get('NumEmailActionsperRule').Value__c < rule.actionTypeCountMap.get('Send Email')){
            throw new AW_Exception('Email : Limit of ' + lims.get('NumEmailActionsperRule').Value__c +' Exceeded in ' + rule.rule.Name);
        }
        
        if(rule.actionTypeCountMap.containsKey('Update Field') && lims.get('NumUpdateActionsperRule')!=null && lims.get('NumUpdateActionsperRule').Value__c < rule.actionTypeCountMap.get('Update Field')){
            throw new AW_Exception('Update Field : Limit of ' + lims.get('NumUpdateActionsperRule').Value__c +' Exceeded in ' + rule.rule.Name);
        }
        if(rule.actionTypeCountMap.containsKey('Insert Related Object') && lims.get('NumInsertActionsperRule')!=null && lims.get('NumInsertActionsperRule').Value__c < rule.actionTypeCountMap.get('Insert Related Object')){
            throw new AW_Exception('Insert Related Object : Limit of ' + lims.get('NumInsertActionsperRule').Value__c +' Exceeded in ' + rule.rule.Name);
        }   
        if(rule.actionTypeCountMap.containsKey('Apex Callout-HTTP') && lims.get('NumApexCalloutperRule')!=null && lims.get('NumApexCalloutperRule').Value__c < rule.actionTypeCountMap.get('Apex Callout-HTTP')){
            throw new AW_Exception('Apex Callout-HTTP: Limit of ' + lims.get('NumApexCalloutperRule').Value__c +' Exceeded in ' + rule.rule.Name);
        }   
        if(rule.actionTypeCountMap.containsKey('CrossObject') && lims.get('NumUpdateCrossReferencefieldsperRule')!=null && lims.get('NumUpdateCrossReferencefieldsperRule').Value__c < rule.actionTypeCountMap.get('CrossObject')){
            throw new AW_Exception('Cross Object Field Limit of '+lims.get('NumUpdateCrossReferencefieldsperRule').Value__c+' Exceeded in ' + rule.rule.Name);
        }
        
        if(rule.actionTypeCountMap.containsKey('LookupObjectField') && lims.get('NumUpdateLookupReferencefieldsperRule')!=null && lims.get('NumUpdateLookupReferencefieldsperRule').Value__c < rule.actionTypeCountMap.get('LookupObjectField')){
            throw new AW_Exception('Lookup Object Field Limit of '+lims.get('NumUpdateLookupReferencefieldsperRule').Value__c+' Exceeded in ' + rule.rule.Name);
        }
    }
    
    public class LookupWrapper{
       public String fieldsName;
       public String whereCondition;
       public LookupWrapper(String fieldsName , String whereCondition){
         this.fieldsName = fieldsName;
         this.whereCondition = whereCondition;
       }
    }   
}
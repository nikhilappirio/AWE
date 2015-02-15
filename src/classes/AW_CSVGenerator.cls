/****************************************************************************
    AW_CSVGenerator
    Generate the AWE in csv form
****************************************************************************/
public with sharing class AW_CSVGenerator {

    private static Map<String, Schema.SObjectType> globalDescribe   =   null;
    public static Map<String , Map<String, String>> ruleActionMapping = new Map<String , Map<String, String>>();
    public static Map<String, Map<Id , String>> referenceFieldIdMap = new Map<String, Map<Id, String>>(); // need to work on it
    static{
        Map<String, AWE_Rule_Action_Mapping__c> mappingMap = AWE_Rule_Action_Mapping__c.getAll();
        for(AWE_Rule_Action_Mapping__c raMapping : mappingMap.values()){
        if(raMapping.Object_Name__c != null && raMapping.Type__c != null){
            if(!ruleActionMapping.containsKey(raMapping.Object_Name__c +':'+raMapping.Type__c)){
                ruleActionMapping.put(raMapping.Object_Name__c +':'+raMapping.Type__c, new Map<String, String>{raMapping.Field_API_Name__c  => raMapping.Field_Name__c});
            }else{
                ruleActionMapping.get(raMapping.Object_Name__c +':'+raMapping.Type__c).put(raMapping.Field_API_Name__c  , raMapping.Field_Name__c);
            }
        }
     }
    }
    
    /*
     * Generate Export CSV 
     * @Param : List of Rules
    */      
    public String exportInCSVForm(List<Rule__c> rules, List<RuleCriteria__c> ruleCriteriaList , List<RuleAction__c> ruleActionList){
        globalDescribe = Schema.getGlobalDescribe();
        Map<String, List<AW_ParseCSV_RuleCriteriaWrapper>> ruleCriteriaMap = loadRuleCriteria(ruleCriteriaList);
        Map<String, List<AW_ParseCSV_RuleActionWrapper>>  ruleActionMap = loadRuleActions(ruleActionList);
        if(!referenceFieldIdMap.isEmpty()){
            loadReferenceIds();
        }
        String csv = ' "WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","FilterLogic", "Action" \n';
        for(Rule__c rule : rules){
            csv += generateCSVRow(rule, ruleCriteriaMap.get(rule.Name) , ruleActionMap.get(rule.Name)) +'\n';
        }
        if(csv.endsWith('\n')){
            csv = csv.subString(0, csv.lastIndexOf('\n'));
        }
        System.debug('::csv'+csv.split('\n').size());
        return csv;
     }    
      
     /*
     * Generate Export CSV single Row
     * @Param : Rule
     * @Param : Rule Criteria
     * @Param : Rule Actions
    */ 
     public String generateCSVRow(Rule__c rule , List<AW_ParseCSV_RuleCriteriaWrapper> ruleCriterias , List<AW_ParseCSV_RuleActionWrapper> ruleActions){
        String csvRow =  '"' + (rule.Advance_Workflow__c != null ? rule.Advance_Workflow__r.Name : '') + '","' + rule.Object__c + '","'
                        + rule.Name +'","' + (rule.Description__c != null ? rule.Description__c.replace('\n', AW_Rule_Constants.LINE_SPLITOR).replace('\r', AW_Rule_Constants.CARRIAGE_SPLITOR) : '') + '",'+rule.order__c ;
        if(rule.Evaluation_Rule__c != null && AW_Rule_Constants.evalutionForExportMap.containsKey(rule.Evaluation_Rule__c)){
            csvRow +=  ',"'+ AW_Rule_Constants.evalutionForExportMap.get(rule.Evaluation_Rule__c) +'"';
        }else if(rule.Evaluation_Rule__c != null){
            csvRow +=  ',"'+ rule.Evaluation_Rule__c +'"';
        }else{
            csvRow += ',""';
        }
        if(rule.Execution_Behavior__c != null && AW_Rule_Constants.executionBehaviourForExportMap.containsKey(rule.Execution_Behavior__c)){
            csvRow +=  ',"'+ AW_Rule_Constants.executionBehaviourForExportMap.get(rule.Execution_Behavior__c) +'"';
        }else if(rule.Execution_Behavior__c != null){
            csvRow +=  ',"'+ rule.Execution_Behavior__c +'"';
        }else{
            csvRow += ',""';
        }
        csvRow += ',"' + generateCriteriaCSV(rule , ruleCriterias) + '"';
        csvRow += ',"' + rule.Filter_Logic__c + '"';
        csvRow += ',"' + generateActionCSV(rule , ruleActions) +  ' "';
        System.debug(':::csvRow'+csvRow);
        return csvRow;
        // 
     }
    
    /*
      * load Rule Criteria
      * @Param : List of  Rules
     */
      public Map<String, List<AW_ParseCSV_RuleCriteriaWrapper>> loadRuleCriteria(List<RuleCriteria__c> ruleCriteriaList){ 
         Map<String, List<AW_ParseCSV_RuleCriteriaWrapper>> ruleCriteriaMapWithRuleName = new Map<String, List<AW_ParseCSV_RuleCriteriaWrapper>>();
         for(RuleCriteria__c ruleCriteria : ruleCriteriaList){
              if(!ruleCriteriaMapWithRuleName.containsKey(ruleCriteria.Rule__r.Name)){
                    ruleCriteriaMapWithRuleName.put(ruleCriteria.Rule__r.Name , new List<AW_ParseCSV_RuleCriteriaWrapper>());
              }
              ruleCriteriaMapWithRuleName.get(ruleCriteria.Rule__r.Name).add(new AW_ParseCSV_RuleCriteriaWrapper(ruleCriteria));
          }
          return ruleCriteriaMapWithRuleName;
      }
      
     /*
     * Generate Criteria CSV
     * @Param : Rule
     * @Param : Rule Criteria
    */  
     public String generateCriteriaCSV(Rule__c rule , List<AW_ParseCSV_RuleCriteriaWrapper> ruleCriterias){
       if(ruleCriterias == null || ruleCriterias.isEmpty())
          return '';
        String filterLogic = rule.Filter_Logic__c;
        if(filterLogic != null && filterLogic != ''){
            filterLogic = filterLogic.replace('(', ' ( ');
            filterLogic = filterLogic.replace(')', ' ) ');
            filterLogic = filterLogic.replace('AND', ' .AND. ');
            filterLogic = filterLogic.replace('OR', ' .OR. ');
        }
        Pattern isnumbers = Pattern.Compile('^[0-9]+$');
        String resultFL = '';
        for(String fl : filterLogic.split(' ')){
            if(isNumbers.matcher(fl).Matches()){
                resultFL +=  '.' + fl + '.' +  ' '; 
            }else{
                resultFL += fl + ' ';
            }
        }
        filterLogic = resultFL;
        Integer criteriaNum = 1;
        for(AW_ParseCSV_RuleCriteriaWrapper ruleCriteriaWrapper : ruleCriterias){
            String criteria = '';
            System.debug('::ruleCriteriaWrapper'+ruleCriteriaWrapper);
            if(ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != null){
                if(ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != 'CrossFormula' && !ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c.contains(AW_Rule_Constants.GLOBAL_VARIABLE)){
                    criteria += ruleCriteriaWrapper.ruleCriteria.Related_Object__c +'.'+(ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != AW_Rule_Constants.CRITERIA_RT ? ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c : AW_Rule_Constants.CSV_RT); 
                }else if(ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c == 'CrossFormula'){
                    criteria += 'CrossFormula.' + ruleCriteriaWrapper.ruleCriteria.CrossFormula__c; 
                }else if(ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c.contains(AW_Rule_Constants.GLOBAL_VARIABLE)){
                    criteria += ruleCriteriaWrapper.ruleCriteria.Related_Object__c +'.'+ ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c.replace('-', '$');
                }
            }
            System.debug('::criteria'+criteria);
            System.debug('::::ruleCriteriaWrapper.ruleCriteria.Matching_Type__c'+ruleCriteriaWrapper.ruleCriteria.Matching_Type__c +'::length' + ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.length());
            System.debug('::::ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c'+ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c);
            System.debug('::::ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c'+ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c);
            System.debug('::::contains'+AW_Rule_Constants.matchingTypeForExportMap.containsKey(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.toUpperCase()));
            if(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c != null && AW_Rule_Constants.matchingTypeForExportMap.containsKey(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.toUpperCase())){
                criteria += ' ' + AW_Rule_Constants.matchingTypeForExportMap.get(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.toUpperCase()); 
            }else if(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c != null){
              criteria += ' ' + ruleCriteriaWrapper.ruleCriteria.Matching_Type__c;
            }
            if(ruleCriteriaWrapper.ruleCriteria.Matching_Type__c != null && ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.toUpperCase().contains('BETWEEN') && ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c != null && ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c != null){
                System.debug('::;in Between');
                criteria += ' ' + ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c  + ' ' + AW_Rule_Constants.BETWEEN_OPERATOR + ' ' + ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c; 
            }else if(ruleCriteriaWrapper.ruleCriteria.Matching_Value__c != null && ruleCriteriaWrapper.ruleCriteria.Matching_Type__c.toUpperCase() != 'ISCHANGED'){
                System.debug('::;in =');
                criteria += ' ' + ruleCriteriaWrapper.ruleCriteria.Matching_Value__c;
            }
            System.debug('::criteria'+criteria +'::criteriaNum'+criteriaNum);
            filterLogic = filterLogic.replace('.' + criteriaNum + '.', ' ' +criteria + ' ');
            System.debug('::filterLogic'+filterLogic);
            criteriaNum++;
        }
        return filterLogic;
     } 
     
     /*
      * load Rule Actions
      * @Param : List of  Rules
     */ 
     public Map<String, List<AW_ParseCSV_RuleActionWrapper>> loadRuleActions(List<RuleAction__c> ruleActionList){
        Map<String, List<AW_ParseCSV_RuleActionWrapper>> ruleActionMapWithRuleName = new Map<String, List<AW_ParseCSV_RuleActionWrapper>>();
         for(RuleAction__c ruleAction : ruleActionList){
              if(!ruleActionMapWithRuleName.containsKey(ruleAction.Rule__r.Name)){
                    ruleActionMapWithRuleName.put(ruleAction.Rule__r.Name , new List<AW_ParseCSV_RuleActionWrapper>());
              }
              AW_ParseCSV_RuleActionWrapper ruleActionWrapper = new AW_ParseCSV_RuleActionWrapper(ruleAction);
              ruleActionWrapper.insertRecordValues = ruleAction.Values_for_Action_Insert_Record__r;
              ruleActionWrapper.ownerPrioritizationList = ruleAction.Owner_Prioritization__r;
              ruleActionMapWithRuleName.get(ruleAction.Rule__r.Name).add(ruleActionWrapper);
              if(ruleAction.User_Owner_Id__c != null && ruleAction.User_Owner_Id__c.startsWith(AW_Rule_Constants.USER_KEYPREFIX)){
                if(!referenceFieldIdMap.containsKey('User')){
                    referenceFieldIdMap.put('User' , new Map<Id, String>{ruleAction.User_Owner_Id__c => null});
                }else{
                    referenceFieldIdMap.get('User').put(ruleAction.User_Owner_Id__c, null);
                }
              }else if(ruleAction.User_Owner_Id__c != null && ruleAction.User_Owner_Id__c.startsWith(AW_Rule_Constants.GROUP_KEYPREFIX)){
                if(!referenceFieldIdMap.containsKey('Group')){
                    referenceFieldIdMap.put('Group' , new Map<Id, String>{ruleAction.User_Owner_Id__c => null});
                }else{ 
                    referenceFieldIdMap.get('Group').put(ruleAction.User_Owner_Id__c, null);
                }
              }
          }
          return ruleActionMapWithRuleName;
      }
      
     /*
     * Generate Action CSV
     * @Param : Rule
     * @Param : Rule Actions 
    */ 
    
    public String generateActionCSV(Rule__c rule , List<AW_ParseCSV_RuleActionWrapper> ruleActions){
      
        String ruleActionCol  ='';
        System.debug('::ruleActions'+ruleActions);
        if(ruleActions == null || ruleActions.isEmpty())
          return ''; 
        for(AW_ParseCSV_RuleActionWrapper ruleAction : ruleActions){
            if(ruleAction.ruleAction.Type__c != null && AW_Rule_Constants.actionTypeForExportMap.containsKey(ruleAction.ruleAction.Type__c)){
                ruleActionCol += AW_Rule_Constants.ACTION_PREFIX + AW_Rule_Constants.actionTypeForExportMap.get(ruleAction.ruleAction.Type__c) + (ruleAction.ruleAction.bulk_API__c == true ? 'Bulk' :'' ) + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                if(ruleAction.ruleAction.Type__c == 'Update Field' && ruleAction.ruleAction.Field_API_Name__c != null){
                    if(ruleAction.ruleAction.Field_API_Name__c == AW_Rule_Constants.CROSSOBJECT){
                        ruleActionCol += AW_Rule_Constants.CROSSOBJECTFIELD +':';
                        ruleActionCol += ruleAction.ruleAction.CrossObjectField__c + AW_Rule_Constants.EQUAL_SEPARATOR + (ruleAction.ruleAction.value__c != null && ruleAction.ruleAction.value__c != '' ? ruleAction.ruleAction.value__c : (ruleAction.ruleAction.Long_Value__c != null ? ruleAction.ruleAction.Long_Value__c : ''));
                    }else if(ruleAction.ruleAction.Field_API_Name__c == AW_Rule_Constants.OWNERPRIORITIZATION){
                        ruleActionCol += AW_Rule_Constants.OWNERPRIORITIZATIONFIELD + AW_Rule_Constants.ACTION_TYPE_SEPARATOR + (ruleAction.ruleAction.related_Object__c != null ? ruleAction.ruleAction.related_Object__c +'.OwnerId' : rule.Object__c +'.OwnerId');
                        if(ruleAction.ruleAction.Prioritization_Method__c != null){
                            ruleActionCol +=  AW_Rule_Constants.ACTION_TYPE_SEPARATOR + 'Method='+ruleAction.ruleAction.Prioritization_Method__c;
                        }else{
                            ruleActionCol += AW_Rule_Constants.ACTION_TYPE_SEPARATOR + 'Method= ';
                        }
                        for(OwnerPrioritization__c op : ruleAction.ruleAction.Owner_Prioritization__r){
                            ruleActionCol += AW_Rule_Constants.FIELD_SEPARATOR;
                            System.debug('::ruleActionMapping'+ruleActionMapping.get('OwnerPrioritization__c' +':'+'OwnerPrioritization') + ':::'+op);
                            if(ruleActionMapping.containsKey('OwnerPrioritization__c' +':'+'OwnerPrioritization')){
                                ruleActionCol += generateActionFieldsCSV(op , ruleActionMapping.get('OwnerPrioritization__c' +':'+'OwnerPrioritization') , ',');
                                ruleActionCol += AW_Rule_Constants.FIELD_SEPARATOR;
                            }
                            if(ruleActionCol.endsWith(AW_Rule_Constants.FIELD_SEPARATOR)){
                                ruleActionCol = ruleActionCol.subString(0, ruleActionCol.lastIndexOf(AW_Rule_Constants.FIELD_SEPARATOR));
                            }
                        }
                    }else if(ruleAction.ruleAction.Field_API_Name__c == AW_Rule_Constants.LOOKUPOBJECTFIELD){ // lookup check
                      ruleActionCol += AW_Rule_Constants.LOOKUPOBJECTFIELD + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                      if(ruleAction.ruleAction.Lookup_Field_Name__c != null){
                          ruleActionCol += rule.object__c + '.'+ruleAction.ruleAction.Lookup_Field_Name__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                        } 
                        if(ruleAction.ruleAction.Lookup_Object__c != null){
                          ruleActionCol += AW_Rule_Constants.LOOKUPOBJECT + AW_Rule_Constants.EQUAL_SEPARATOR + ruleAction.ruleAction.Lookup_Object__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                        }
                        if(ruleAction.ruleAction.Lookup_Field_API_Name__c != null){
                          ruleActionCol += AW_Rule_Constants.LOOKUPFIELD + AW_Rule_Constants.EQUAL_SEPARATOR + ruleAction.ruleAction.Lookup_Field_API_Name__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                        }
                        ruleActionCol += AW_Rule_Constants.LOOKUPVALUE + AW_Rule_Constants.EQUAL_SEPARATOR + (ruleAction.ruleAction.value__c != null && ruleAction.ruleAction.value__c != '' ? ruleAction.ruleAction.value__c : (ruleAction.ruleAction.Long_Value__c != null ? ruleAction.ruleAction.Long_Value__c : '')) + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                        if(ruleAction.ruleAction.Lookup_Where_Fields__c != null){
                          ruleActionCol += AW_Rule_Constants.CONDITION + AW_Rule_Constants.EQUAL_SEPARATOR + ruleAction.ruleAction.Lookup_Where_Fields__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                        }
                        if(ruleActionCol.endsWith(AW_Rule_Constants.ACTION_TYPE_SEPARATOR)){
                          ruleActionCol = ruleActionCol.subString(0, ruleActionCol.lastIndexOf(AW_Rule_Constants.ACTION_TYPE_SEPARATOR));
                        } 
                    }else{
                        ruleActionCol += ruleAction.ruleAction.Related_Object__c + '.' + ruleAction.ruleAction.Field_API_Name__c + AW_Rule_Constants.EQUAL_SEPARATOR + (ruleAction.ruleAction.value__c != null && ruleAction.ruleAction.value__c != '' ? ruleAction.ruleAction.value__c : (ruleAction.ruleAction.Long_Value__c != null ? ruleAction.ruleAction.Long_Value__c : ''));
                    }
                }else if(ruleAction.ruleAction.Type__c == 'Send Email' && ruleActionMapping.containsKey('RuleAction__c' +':'+'Send Email')){
                    String sendEmailAction = generateActionFieldsCSV(ruleAction.ruleAction , ruleActionMapping.get('RuleAction__c' +':'+'Send Email') , '~');
                    // replace Id  with Name
                    if(sendEmailAction != '' && sendEmailAction.contains('User=') 
                            && ruleAction.ruleAction.User_Owner_Id__c != null && ruleAction.ruleAction.User_Owner_Id__c.startsWith(AW_Rule_Constants.USER_KEYPREFIX)
                            && referenceFieldIdMap.containsKey('User') && referenceFieldIdMap.get('User').get(ruleAction.ruleAction.User_Owner_Id__c) != null){
                            sendEmailAction = sendEmailAction.replace('User='+ruleAction.ruleAction.User_Owner_Id__c ,'User='+referenceFieldIdMap.get('User').get(ruleAction.ruleAction.User_Owner_Id__c));
                    }else if(sendEmailAction != '' && sendEmailAction.contains('User=') 
                            && ruleAction.ruleAction.User_Owner_Id__c != null && ruleAction.ruleAction.User_Owner_Id__c.startsWith(AW_Rule_Constants.GROUP_KEYPREFIX)
                            && referenceFieldIdMap.containsKey('Group') && referenceFieldIdMap.get('Group').get(ruleAction.ruleAction.User_Owner_Id__c) != null){
                        sendEmailAction = sendEmailAction.replace('User='+ruleAction.ruleAction.User_Owner_Id__c ,'User='+referenceFieldIdMap.get('Group').get(ruleAction.ruleAction.User_Owner_Id__c));
                    }   
                    ruleActionCol += sendEmailAction; 
                }else if(ruleAction.ruleAction.Type__c == 'Chatter Notification' && ruleActionMapping.containsKey('RuleAction__c' +':'+'Chatter Notification')){
                    ruleActionCol +=  ruleAction.ruleAction.related_Object__c + AW_Rule_Constants.ACTION_TYPE_SEPARATOR;
                    String chatterAction = generateActionFieldsCSV(ruleAction.ruleAction , ruleActionMapping.get('RuleAction__c' +':'+'Chatter Notification') , '~');
                    if(chatterAction != '' && chatterAction.contains('SendToUser=') 
                            && referenceFieldIdMap.containsKey('User') && referenceFieldIdMap.get('User').get(ruleAction.ruleAction.User_Owner_Id__c) != null){
                            chatterAction = chatterAction.replace('SendToUser='+ruleAction.ruleAction.User_Owner_Id__c ,'SendToUser='+referenceFieldIdMap.get('User').get(ruleAction.ruleAction.User_Owner_Id__c));
                    }else if(chatterAction != '' && chatterAction.contains('SendToGroup=') 
                            && referenceFieldIdMap.containsKey('Group') && referenceFieldIdMap.get('Group').get(ruleAction.ruleAction.User_Owner_Id__c) != null){
                            chatterAction = chatterAction.replace('SendToGroup='+ruleAction.ruleAction.User_Owner_Id__c ,'SendToGroup='+referenceFieldIdMap.get('Group').get(ruleAction.ruleAction.User_Owner_Id__c));
                    } 
                    // replace Id  with Name
                    ruleActionCol += chatterAction; 
                }else if(ruleAction.ruleAction.Type__c == 'Execute an Apex Job' && ruleActionMapping.containsKey('RuleAction__c' +':'+'Execute an Apex Job')){
                    ruleActionCol += generateActionFieldsCSV(ruleAction.ruleAction , ruleActionMapping.get('RuleAction__c' +':'+'Execute an Apex Job') , '~');
                }else if(ruleAction.ruleAction.Type__c == 'Insert Related Object' || ruleAction.ruleAction.Type__c == 'Insert Unrelated Object' || ruleAction.ruleAction.Type__c == 'Upsert Related Object'|| ruleAction.ruleAction.Type__c == 'Upsert Unrelated Object'){
                    ruleActionCol += ruleAction.ruleAction.related_Object__c + AW_Rule_Constants.FIELD_SEPARATOR;
                    for(Values_for_Action_Insert_Record__c valObj : ruleAction.ruleAction.Values_for_Action_Insert_Record__r){
                        ruleActionCol += valObj.Name + '=' + valObj.Value__c + AW_Rule_Constants.FIELD_SEPARATOR;
                    }
                    if(ruleActionCol.endsWith(AW_Rule_Constants.FIELD_SEPARATOR)){
                        ruleActionCol = ruleActionCol.substring(0 , ruleActionCol.lastIndexOf(AW_Rule_Constants.FIELD_SEPARATOR));
                    }
                }
                ruleActionCol += AW_Rule_Constants.ACTION_POSTFIX;
            }
            
            
        }
        return ruleActionCol;
    }
      
      private String generateActionFieldsCSV(Sobject sobj , Map<String ,String> fieldMapping , String separator){
        String fdCSV  = '';
        System.debug(':::sobj'+sobj);
        System.debug(':::fieldMapping'+fieldMapping);
        for(String fdmapping : fieldMapping.keySet()){
            //String opCSV = '';
            if(fieldMapping.get(fdmapping) != null)
            	fdCSV += fieldMapping.get(fdmapping) + '=' + sobj.get(fdmapping) + separator;
            
            //fdCSV += opCSV;  
        }
        if(fdCSV.endsWith(',')){
                fdCSV = fdCSV.subString(0, fdCSV.lastIndexOf(','));
            }
        return fdCSV;
      }
   
   /*
    * load Reference Id
    */
   private void loadReferenceIds(){
        for(String objName : referenceFieldIdMap.keySet()){
            Set<Id> ids = referenceFieldIdMap.get(objName).keySet();
            String soqlQuery = ' SELECT Id , Name';
            soqlQuery += ' FROM '+ objName  + ' WHERE  id in : ids';
            for(Sobject sobj : Database.query(soqlQuery)){
                referenceFieldIdMap.get(objName).put((Id)sobj.get('Id') ,(String) sobj.get('Name'));
            } 
        }
    }
    /*
     * Load Rule Critertia
    */
    public static List<RuleCriteria__c> loadRuleCriteriaList(List<Rule__c> rules){
        String soqlQuery = AW_CSVGenerator.generateQuery('RuleCriteria__c' , 'Rule__c' , new Map<String , String>());
        soqlQuery += ' where rule__c = : rules order by rule__c, Name';
        return Database.query(soqlQuery);
    }
    
    /*
     * Load Rule Action
    */
    public static List<RuleAction__c> loadRuleActionList(List<Rule__c> rules){
        String soqlQuery = AW_CSVGenerator.generateQuery('RuleAction__c' , 'Rule__c' , new Map<String, String>{'Values_for_Action_Insert_Record__r' => 'Values_for_Action_Insert_Record__c' , 'Owner_Prioritization__r' => 'OwnerPrioritization__c'});
        soqlQuery += ' where rule__c = : rules order by rule__c, Name';
        return Database.query(soqlQuery);
    }
    
    /*
     * Generate Queries
     */
      public static String generateQuery(String objectName , String parentFieldName, Map<String, String> childRelationships ){
        Map<String, Schema.SObjectField> fieldsMap = schema.getGlobalDescribe().get(objectName).getDescribe().Fields.getMap();
        String soql = 'Select ';
        for(String fd : fieldsMap.keySet()){
            if(fd != 'lastreferenceddate'){
                soql +=  fd + ',';
            }
        }
        if(parentFieldName != null){
            soql += parentFieldName.replace('__c', '__r')+ '.Name';
        }
        if(parentFieldName == 'Advance_Workflow__c'){
            soql += ', Advance_Workflow__r.Enabled__c ';
        }
        for(String childRelationShip : childRelationships.keySet()){
            Map<String, Schema.SObjectField> childFields = schema.getGlobalDescribe().get(childRelationships.get(childRelationShip)).getDescribe().Fields.getMap();
            String childQuery = 'Select ';
            for(String fd : childFields.keySet()){
                childQuery +=  fd + ',';
            }
            if(childQuery.contains(',')){
                childQuery = childQuery.subString(0, childQuery.lastIndexOf(','));
            }
            childQuery += ' from ' + childRelationShip ;
            soql += ',( ' + childQuery +  ')';
        } 
        if(soql.endsWith(',')){
            soql = soql.subString(0, soql.lastIndexOf(','));
        }
        soql += ' from ' + objectName;
        System.debug('::soql' +objectName +':::'+soql);
        return soql;
   }
 }
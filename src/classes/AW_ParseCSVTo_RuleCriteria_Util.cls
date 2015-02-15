public with sharing class AW_ParseCSVTo_RuleCriteria_Util {
    
    private static String filterCriteria;
    private static String filterLogic;
    private static List<Integer> uniqueRuleCriteria;
    private static String ruleName;
    private static Integer highestRuleCriteriaNumber;
    public AW_ParseCSVTo_RuleCriteria_Util(){}
    
    public static AW_ParseCSV_RuleWrapper  parseRuleCriteria(AW_ParseCSV_RuleWrapper ruleWrapper){
        filterCriteria  = '';
        filterLogic = '';
        highestRuleCriteriaNumber = 0;
        ruleName = ruleWrapper.rule.Name;
        uniqueRuleCriteria = new List<Integer>();
        ruleWrapper.displayCriteria = ruleWrapper.displayCriteria.replace('|',';'); //new line
        //new line start-------------------------
        Integer i;
        String s;
        String criteria = ruleWrapper.displayCriteria;
        for(i=0; i<criteria.length() ; i++){
             if ((criteria.substring(i,i+1) == '=')  &&  (criteria.indexOf(';',i) != -1)){
                   if(!(criteria.substring(i,criteria.indexOf(';',i)).contains('INCLUDES'))  && !(criteria.substring(i,criteria.indexOf(';',i)).contains('EXCLUDES'))){
                           s = criteria.substring(i+1,criteria.length());
                           criteria = criteria.substring(0,i);
                           criteria = criteria + 'INCLUDES';
                           criteria = criteria + s;
                    }          
             }  
        }
        ruleWrapper.displayCriteria = criteria ;

        //new line end-----------------------------
        String[] spaceSplitRuleCriteria = ruleWrapper.displayCriteria.trim().split(' '); 
        //String delimitStr = 
        filterCriteria = ruleWrapper.displayCriteria;
        filterLogic = ruleWrapper.rule.Filter_Logic__c;
        uniqueRuleCriteria = filterUniqueRCNumbers();
        System.debug('::uniqueRuleCriteria'+uniqueRuleCriteria);
        // prepare Criteria List in String form
        Map<Integer , String> ruleCriteriaMap = prepareListForCriterias(spaceSplitRuleCriteria);
        // prepare Criteria List in RuleCriteriaWrapper form
        ruleWrapper.ruleCriteriaList = prepareRuleCriteriaList(ruleCriteriaMap,ruleWrapper.displayCriteria, ruleWrapper.rule.Object__c);
        System.debug('::ruleWrapper.ruleCriteriaList'+ruleWrapper.ruleCriteriaList.size());
        System.debug('::highestRuleCriteriaNumber'+highestRuleCriteriaNumber);
        
        if(ruleWrapper.ruleCriteriaList.size() != highestRuleCriteriaNumber){
            AW_ParseCSVTo_AdvanceWorkflow_Util.ruleErrorMap.put(ruleName , new Error_Log__c(Error_Rule_Name__c = ruleName, Object_Name__c= ruleWrapper.Rule.Object__c, Error_Description__c = 'Number of Rule Criteria is mismatched with Filter Logic or duplicate Rule Criteria found', import_code__c = AW_ParseCSVTo_AdvanceWorkflow_Util.refRule , Object_Method_Name__c='AW_ParseCSVTo_RuleCriteria_Util.parseRuleCriteria',ErrorSource__c = 'Filter Logic'));
            return ruleWrapper;
        }
        //new line here
        //added .replace('|',',') now just add includes functionality
        //new line end
       //ruleWrapper.rule.Filter_Logic__c =  filterLogic;//filterCriteria.replace('.','').replace('(' , ' ( ').replace(')', ' ) ');
        //ruleWrapper.rule.Filter_Logic__c = ruleWrapper.rule.Filter_Logic__c.replace('&#124','');
        ruleWrapper.displayCriteria = ruleWrapper.displayCriteria.replace('.AND.' , 'AND').replace('.OR.' , 'OR');
        
        validateRuleCriteria(ruleWrapper);
        return ruleWrapper;
    }
    
    // prepare Criteria List in String form
    private static  Map<Integer , String> prepareListForCriterias(String[] spaceSplitRuleCriteria){
        Map<Integer , String> ruleCriteriaMap  = new Map<Integer , String>();
        Map<String, Integer> logicalOperatorMap = new Map<String,Integer>();
        String singleCriteria = '';
        String tempSingleCriteria = '';
        Integer criteriaNum = 1;
        Integer maxCriteria = 1;
        Pattern listPattern = Pattern.compile('\\(+|\\)+');
        for(String ssrc : spaceSplitRuleCriteria){
            System.debug('::ssrc'+ssrc);
            Matcher matcher = listPattern.matcher(ssrc);
            // Start Bug Fix : Import Rule from CSV -Kirti Sahni (August 26)
            // check if  criteria is blank
            if (ssrc.trim() == '.'){
            continue;
            }

            // End Bug Fix : Import Rule from CSV -Kirti Sahni (August 26)
            if(AW_Rule_Constants.logicalOperatorSet.contains(ssrc.trim()) || matcher.matches()){
                //mainLogicalOperator.add(ssrc);
                if(singleCriteria.trim() != ''){
                    singleCriteria = singleCriteria.trim();
                    if(!logicalOperatorMap.containsKey(singleCriteria)){
                        logicalOperatorMap.put(singleCriteria, criteriaNum);
                        if(uniqueRuleCriteria.size() >= criteriaNum){
                            ruleCriteriaMap.put(uniqueRuleCriteria[criteriaNum - 1] ,singleCriteria );
                        }
                        criteriaNum++;
                    }
                    

                    
                    /*Integer ruleCriteriaNumber = logicalOperatorMap.containsKey(singleCriteria) ? logicalOperatorMap.get(singleCriteria) : (criteriaNum - 1);
                    System.debug('::ruleCriteriaNumber'+ruleCriteriaNumber);
                    System.debug(':::::fl'+filterCriteria.contains(tempSingleCriteria.trim())+'::::'+tempSingleCriteria);
                    if(tempSingleCriteria.contains('$') || tempSingleCriteria.contains('+') || tempSingleCriteria.contains('*') || tempSingleCriteria.contains('?') || tempSingleCriteria.contains('^')){
                        tempSingleCriteria = tempSingleCriteria.replace('$', '\\$').replace('+','\\+').replace('*','\\*').replace('?','\\?').replace('^','\\^');
                    }
                    if(tempSingleCriteria.contains('(') || tempSingleCriteria.contains(')') || tempSingleCriteria.contains('{') || tempSingleCriteria.contains('}') || tempSingleCriteria.contains('[') || tempSingleCriteria.contains(']')){
                        filterCriteria = filterCriteria.replace(tempSingleCriteria.trim() , '.' + String.valueOf(ruleCriteriaNumber) + '.');
                    }else{
                        filterCriteria = filterCriteria.replaceFirst(tempSingleCriteria.trim() , '.' + String.valueOf(ruleCriteriaNumber) + '.');


                    }*/
                    
                }
                singleCriteria = '';
                tempSingleCriteria = '';
            }else{
                if(ssrc != ''){
                    singleCriteria += ' ' + ssrc.trim(); 
                }
                tempSingleCriteria += ' ' + ssrc;
            } 
        }
        if(singleCriteria.trim() != ''){

            singleCriteria = singleCriteria.trim();
            if(!logicalOperatorMap.containsKey(singleCriteria)){
                logicalOperatorMap.put(singleCriteria, criteriaNum);
                if(uniqueRuleCriteria.size() >= criteriaNum){
                    ruleCriteriaMap.put(uniqueRuleCriteria[criteriaNum - 1] ,singleCriteria );
                }
            }
            /*Integer ruleCriteriaNumber = logicalOperatorMap.containsKey(singleCriteria) ? logicalOperatorMap.get(singleCriteria) : criteriaNum;
            System.debug('::ruleCriteriaNumber end'+ruleCriteriaNumber);
            if(tempSingleCriteria.contains('$') || tempSingleCriteria.contains('+') || tempSingleCriteria.contains('*') || tempSingleCriteria.contains('?') || tempSingleCriteria.contains('^')){
                tempSingleCriteria = tempSingleCriteria.replace('$', '\\$').replace('+','\\+').replace('*','\\*').replace('?','\\?').replace('^','\\^');
            }
            if(tempSingleCriteria.contains('(') || tempSingleCriteria.contains(')') || tempSingleCriteria.contains('{') || tempSingleCriteria.contains('}') || tempSingleCriteria.contains('[') || tempSingleCriteria.contains(']')){
                filterCriteria = filterCriteria.replace(tempSingleCriteria.trim() , '.' + String.valueOf(ruleCriteriaNumber) + '.');
            }else{
                filterCriteria = filterCriteria.replaceFirst(tempSingleCriteria.trim() , '.' + String.valueOf(ruleCriteriaNumber) + '.');

            }*/
        }


        return ruleCriteriaMap;
    }
    
    // prepare Criteria List in RuleCriteriaWrapper form
    public static List<AW_ParseCSV_RuleCriteriaWrapper> prepareRuleCriteriaList(Map<Integer , String> ruleCriteriaMap , String displayCriteria, String relatedObject){
        List<AW_ParseCSV_RuleCriteriaWrapper>  ruleCriteriaList = new List<AW_ParseCSV_RuleCriteriaWrapper>();
        String operator='';
    //  Integer criteriaNum = 1;
        //filterCriteria = displayCriteria;

        String criteria;
        for(Integer i = 1; i <= ruleCriteriaMap.size(); i++){
            if(ruleCriteriaMap.containsKey(i)){
                criteria = ruleCriteriaMap.get(i);
                if(AW_Rule_Constants.logicalOperatorSet.contains(criteria)){
                    continue;
                }
            //    filterCriteria  = filterCriteria.replace(criteria, String.valueOf(criteriaNum));
              //  criteriaNum++;    

                String[] criteriaFields = splitByOperator(criteria);
                if(criteriaFields == null){
                    criteriaFields = criteria.trim().split(' ');
                }
                //String[] criteriaFields = criteria.trim().split(' ');

                //new line starts here--------------
                //new line ends here---------------
                if(criteriaFields != null && criteriaFields.size() > 1){

                    //new line here start---------------------------------------------------
                    /*
                     if(criteriaFields[1] == '=' && criteriaFields[2].contains(';')){
                          criteriaFields[1] = 'INCLUDES';
                     }
                     */
                     //new line here end-----------------------------------------
                    operator=criteriaFields[1].trim().toUpperCase();
               
                    if(AW_Rule_Constants.matchingTypeMap.keySet().contains(operator)){
                //  if(AW_Rule_Constants.matchingTypeMap.keySet().contains(criteriaFields[1].trim().toUpperCase())){
                        System.debug(':::Operator'+AW_Rule_Constants.matchingTypeMap.get(criteriaFields[1].trim().toUpperCase()));
                        AW_ParseCSV_RuleCriteriaWrapper rcWrapper = prepareRuleCriteriaWrapper(criteriaFields,relatedObject);
                        rcWrapper.ruleCriteria.Related_Object__c = relatedObject;
                        rcWrapper.ruleCriteria.Matching_Type__c = AW_Rule_Constants.matchingTypeMap.get(criteriaFields[1].trim().toUpperCase());
                        rcWrapper = validateRuleCriteriaField(rcWrapper);
                        ruleCriteriaList.add(rcWrapper);
                    }else{
                         throw new AW_Exception(criteriaFields[1].trim() + ' is not a valid Operator (Equals, Not Equals etc ) please use proper valid Operator.');
                    }
                }
            }


        }
        return  ruleCriteriaList;
    }
    
    private static AW_ParseCSV_RuleCriteriaWrapper prepareRuleCriteriaWrapper(String[] criteriaFields, String relatedObject){
        AW_ParseCSV_RuleCriteriaWrapper ruleCriteriaWrapper = new AW_ParseCSV_RuleCriteriaWrapper(new RuleCriteria__c());
        if(criteriaFields.size() >= 2){
            // TO DO for some special 
            String value = '';

            //Start Bug Fix : Import Rule from CSV -Kirti Sahni (August 27)
            criteriaFields[0] = criteriaFields[0].trim();
            while(criteriaFields[0].startsWith('.')){
              criteriaFields[0] = criteriaFields[0].subString(1,criteriaFields[0].length()); 
              criteriaFields[0] = criteriaFields[0].trim();
            }
             //End Bug Fix : Import Rule from CSV -Kirti Sahni (August 27)


            if(criteriaFields[0].trim().startsWith(AW_Rule_Constants.CROSSFORMULA)){
                ruleCriteriaWrapper.ruleCriteria.CrossFormula__c = criteriaFields[0].trim().substring(criteriaFields[0].indexOf('.')+ 1 , criteriaFields[0].length());
                ruleCriteriaWrapper.ruleCriteria.Field_Name__c = AW_Rule_Constants.CROSSFORMULA;
                ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c = AW_Rule_Constants.CROSSFORMULA;
                ruleCriteriaWrapper.ruleCriteria.Field_Type__c = 'String';
                ruleCriteriaWrapper.isCrossFormula = true; 
            }else if(criteriaFields[0].trim().contains(AW_Rule_Constants.GLOBAL_VARIABLE_CSV)){
                String field = criteriaFields[0].trim().replace(relatedObject.trim() +'.' , '').replaceFirst('\\$' , '-');
                ruleCriteriaWrapper.ruleCriteria.Field_Name__c = field.toLowerCase();
                ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c = field.toLowerCase();
                ruleCriteriaWrapper.ruleCriteria.Field_Type__c = 'String';
                ruleCriteriaWrapper.isGlobalVariable = true;
            }else{
                if(criteriaFields[0].trim().contains('.')){
                    String[] spField = criteriaFields[0].trim().split('\\.');
                    // Start Bug Fix : Import Rule from CSV -Kirti Sahni (August 26)
                    String field = (spField[1].trim() == AW_Rule_Constants.CSV_RT ? AW_Rule_Constants.CRITERIA_RT.trim() : spField[1].trim());
                    // End Bug Fix : Import Rule from CSV -Kirti Sahni (August 26)
                    ruleCriteriaWrapper.ruleCriteria.Field_Name__c = field.toLowerCase();
                    ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c = field.toLowerCase();
                }else{
                    String field = (criteriaFields[0].trim() == AW_Rule_Constants.CSV_RT ? AW_Rule_Constants.CRITERIA_RT.trim() : criteriaFields[0].trim());
                    ruleCriteriaWrapper.ruleCriteria.Field_Name__c = field.toLowerCase();
                    ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c = field.toLowerCase();
                }
           
            }
            if (criteriaFields[1].trim()== AW_Rule_Constants.BETWEEN){
                ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c = '';
                Integer valCount = 2;
                while(criteriaFields[valCount] != AW_Rule_Constants.BETWEEN_OPERATOR && criteriaFields.size() > valCount){
                    if(criteriaFields[valCount] != ''){
                        // remove ( from Between
                        if(criteriaFields[valCount].trim().startsWith('(') && !criteriaFields[valCount].trim().contains(')')){
                            criteriaFields[valCount] = criteriaFields[valCount].trim().substring(1,criteriaFields[valCount].trim().length());
                        }
                        ruleCriteriaWrapper.ruleCriteria.Minimum_Value__c += criteriaFields[valCount] + ' ';
                    }
                    valCount++; 
                }
                ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c = '';
                if(criteriaFields.size() > 0){
                    for(valCount = valCount + 1; valCount < criteriaFields.size();valCount++){
                        ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c += criteriaFields[valCount] + '';
                    }
                    if(ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c != null  && ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c.trim().endsWith(')') && !ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c.trim().contains('(')){
                        ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c  = ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c.trim().subString(0,ruleCriteriaWrapper.ruleCriteria.Maximum_Value__c.trim().length() - 1);
                    }
                }


                
            }
            else if(criteriaFields.size() > 2){
                for(Integer i = 2; i< criteriaFields.size();i++){
                    value += criteriaFields[i] + ' ';
                }
                if(criteriaFields[1].trim() == 'ChangedFromTo'){
                    ruleCriteriaWrapper.ruleCriteria.Matching_Value__c  = value;

                }else {
                    ruleCriteriaWrapper.ruleCriteria.Matching_Value__c  = value;

                }
            }
        }
        return ruleCriteriaWrapper;
    }
    
    private static AW_ParseCSV_RuleCriteriaWrapper  validateRuleCriteriaField(AW_ParseCSV_RuleCriteriaWrapper ruleCriteriaWrapper){
         if(ruleCriteriaWrapper.ruleCriteria.Related_Object__c != null && ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != null && ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != AW_Rule_Constants.CROSSFORMULA && ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c != 'OwnerName' && !ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c.trim().contains(AW_Rule_Constants.GLOBAL_VARIABLE)){
            AW_ParseCSVTo_AdvanceWorkflow_Util.addFieldsInWrapperMap(ruleCriteriaWrapper.ruleCriteria , 'Field_API_Name__c',ruleCriteriaWrapper.ruleCriteria.Related_Object__c.trim());
            Map<String,Map<String, AW_ListRules.FieldWrapper>> fieldWrapperMap = AW_ParseCSVTo_AdvanceWorkflow_Util.fieldWrapperMap;
        
            if(fieldWrapperMap.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c).containsKey(ruleCriteriaWrapper.ruleCriteria.field_API_Name__c.toLowerCase().trim())){
                ruleCriteriaWrapper.ruleCriteria.Field_Type__c = fieldWrapperMap.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c).get(ruleCriteriaWrapper.ruleCriteria.field_API_Name__c.toLowerCase().trim()).dataType;
                ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c = fieldWrapperMap.get(ruleCriteriaWrapper.ruleCriteria.Related_Object__c).get(ruleCriteriaWrapper.ruleCriteria.field_API_Name__c.toLowerCase().trim()).apiName;
                ruleCriteriaWrapper.ruleCriteria.Field_Name__c = ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c;
                
            }else{
                // ERROR 

                 throw new AW_Exception('Field ' + ruleCriteriaWrapper.ruleCriteria.Field_API_Name__c + ' does not exist in Object: ' + ruleCriteriaWrapper.ruleCriteria.Related_Object__c +' RULE: '+ ruleCriteriaWrapper.ruleCriteria.Rule__c);
         }
        }
        return ruleCriteriaWrapper; 
    }
    
    private static Boolean validateRuleCriteria(AW_ParseCSV_RuleWrapper ruleWrapper){
        // validate rule criteria format
           Pattern listPattern = Pattern.compile('((\\()*[1-9][0-9]|[1-9][0-9]|(\\()*[1-9]|[1-9]|[1-9](\\))*|[1-9][0-9](\\))*)(((\\s(AND|And|Or|OR|and|or)\\s)|(AND|And|Or|OR|and|or))((\\()*[1-9][0-9]|[1-9][0-9]|(\\()*[1-9]|[1-9]|[1-9](\\))*|[1-9][0-9](\\))*))*(\\))*');
           String patterns = ruleWrapper.rule.Filter_Logic__c.trim(); 
        // patterns= 'Biotechnology,Financial Services,Government Local,Government National/Federal,Government State/Regional,Healthcare-Private';
        // patterns= 'Biotechnology';
          
        System.debug(':patterns'+patterns);
        patterns = patterns.replace(' ','');
        //new lines for testing pattern start---------------------------------------------------------------
         Matcher m1 = listPattern.matcher('1&#124');
         System.debug('::::::::::::::::::::::::::matching::::::::::::'+m1.matches());
        //new lines for testing pattern end----------------------------------------------------------------
        Matcher matcher = listPattern.matcher(patterns);
        //error encountered 
        if(matcher.matches()== false){
            throw new AW_Exception('Wrong Format! Follow  format eg:1AND(3OR4) or there is some issue in Criteria format for RULE : ' + ruleWrapper.rule.Name);
        }
        // validate Rule Criteria Count
        Advance_Workflow_Limits__c ruleCriteriaLimits = Advance_Workflow_Limits__c.getInstance('NumCriteriaperRule');
        if(ruleCriteriaLimits != null && ruleCriteriaLimits.value__c != null && ruleWrapper.ruleCriteriaList.size() > ruleCriteriaLimits.value__c){
            throw new AW_Exception('Criteria Limit of '+ruleCriteriaLimits.value__c+' Exceeded in rule ' + ruleWrapper.rule.Name);
         }
        
        return true;
    }
    
    
    private static String[] splitByOperator(String criteria){
        String operator;
        String[] criterias;
        if(criteria.contains('>=')){
            criterias = criteria.split('>=');
            operator = '>=';
        }
        else if(criteria.contains('<=')){
            criterias = criteria.split('<=');
            operator = '<=';
        }else if(criteria.contains('!=NULL')){
            criterias = criteria.split('!=NULL');
            operator = '!=NULL';
        }
        else if(criteria.contains('!=')){
            criterias = criteria.split('!=');
            operator = '!=';
        }else if(criteria.contains('=NULL')){
            criterias = criteria.split('=NULL');
            operator = '=NULL';
        }
        else if(criteria.contains('=')){
            criterias = criteria.split('=');
            operator = '=';
        }
        else if(criteria.contains('>')){
            criterias = criteria.split('>');
            operator = '>';
        }
        else if(criteria.contains('<')){
            criterias = criteria.split('<');
            operator = '<';
        }
        if(criterias != null && criterias.size() > 0){
            List<String> newCriteria = new List<String>();
            newCriteria.add(criterias[0].trim());
            newCriteria.add(operator);
            if(criterias.size() > 1){
                newCriteria.add(criterias[1].trim());
            }
            return newCriteria;
        }
        return null;
    }
    
    private static List<Integer> filterUniqueRCNumbers(){
        List<Integer> criteriaNumbers = new List<Integer>();
        Set<Integer> uniqueNumbers = new Set<Integer>();
        filterLogic = filterLogic.replace('(' , ' ( ').replace(')' , ' ) ');
        Pattern isnumbers = Pattern.Compile('^[0-9]+$');
        for(String fl : filterLogic.split(' ')){
            if(isNumbers.matcher(fl).Matches() && !uniqueNumbers.contains(Integer.valueOf(fl))){
                Integer criteriaNum = Integer.valueOf(fl);
                criteriaNumbers.add(criteriaNum); 
                uniqueNumbers.add(criteriaNum); 
                if(highestRuleCriteriaNumber < criteriaNum){
                    highestRuleCriteriaNumber = criteriaNum;
                }
            }
        }
        return criteriaNumbers;
    }

}
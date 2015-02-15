// 
// (c) 2012 Appirio, Inc.
//
// AW_trgr_RuleCriteriaManager                                                     
//
// Handler Class to process event for trigger AW_trgr_RuleCriteria
//Inserts records in the rule archive object and delete rule
// 
//  
// 26 Jan 2013    Original Peter Babalis
//
public with sharing class AW_trgr_RuleCriteriaManager {
//Variable to make sure that the Rule insert, update  delete  is happening only once.
public static Boolean RULECRITERIA_FLOW_CONTROLLER = true;
  
public static void afterInsertRuleCriteria( List<RuleCriteria__c> newList){
     
Set<Id> ruleIds = new Set<Id>();
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){  
    for(RuleCriteria__c rulecriteria : newList){
        if(rulecriteria.Rule__c != null){
            ruleIds.add(rulecriteria.Rule__c);
        }
    }
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULECRITERIA_FLOW_CONTROLLER = false;
}
}

 // public static void afterUpdateRule(List<Rule__c> newList, Map<Id, Rule__c> oldMap ){
public static void afterUpdateRuleCriteria(List<RuleCriteria__c> newList,List<RuleCriteria__c> oldList  ){
Set<Id> ruleIds = new Set<Id>();
system.debug('--AW_trgr_RuleCriteriaManager.afterUpdateRule');
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){    
    for(Integer i = 0; i < newList.size(); i++){
        RuleCriteria__c newRulecriteria = newList[i];
        RuleCriteria__c oldRulecriteria = oldList[i];
        if(newRulecriteria.Field_Type__c != oldRulecriteria.Field_Type__c || newRulecriteria.Matching_Type__c != oldRulecriteria.Matching_Type__c || newRulecriteria.Related_Object__c != oldRulecriteria.Related_Object__c || newRulecriteria.Minimum_Value__c != oldRulecriteria.Minimum_Value__c || newRulecriteria.Maximum_Value__c != oldRulecriteria.Maximum_Value__c || newRulecriteria.Matching_Value__c != oldRulecriteria.Matching_Value__c || newRulecriteria.CrossFormula__c != oldRulecriteria.CrossFormula__c  ){
            if(newRulecriteria.Rule__c != null ){
                ruleIds.add(newRulecriteria.Rule__c);
            }
            else{
                ruleIds.add(oldRulecriteria.Rule__c);
            }
        }
    }
    /*
    Get all the Rule Criteria  of Rule  and then update Status__c of the Rule to 'Draft' if  current status ='Active'
    */
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULECRITERIA_FLOW_CONTROLLER = false;
  } 
}  

public static void afterDeleteRuleCriteria(List<RuleCriteria__c> oldList){
Set<Id> ruleIds = new Set<Id>();
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){  
    system.debug('--AW_trgr_RuleCriteriaManager.afterDeleteRuleCriteria');
    for(RuleCriteria__c rulecriteria : oldList){
        ruleIds.add(rulecriteria.Rule__c);
    }
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULECRITERIA_FLOW_CONTROLLER = false; 
  } 
}
 

public static void updateRule( Set<Id> Ids){
Map<id,Rule__c> ruleMap = new Map<id,Rule__c>([SELECT id,
                                                      Status__c,
                                                      Version__c 
                                               FROM Rule__c 
                                               WHERE id IN :Ids]);
for(Id ruleId: ruleMap.keyset()){
    Rule__c rule = ruleMap.get(ruleId);
    if ( rule.Status__c =='Active' ){ 
        rule.Advance_Workflow__c =null;
        rule.Order__c =null;
        rule.Execution_Behavior__c =null;
        rule.Status__c ='Draft';
        if (rule.Version__c != null ) rule.Version__c =rule.Version__c+1;else rule.Version__c=1;
    }
}
update ruleMap.values();
}
  
}
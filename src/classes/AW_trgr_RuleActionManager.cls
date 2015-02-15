// 
// (c) 2012 Appirio, Inc.
//
// AW_trgr_RuleActionManager                                                     
//
// Handler Class to process event for trigger AW_trgr_RuleAction
//Inserts records in the rule archive object and delete rule
// 
//  
// 26 Jan 2013    Original Peter Babalis
//
public with sharing class AW_trgr_RuleActionManager {

//Variable to make sure that the Rule insert, update  delete  is happening only once.
public static Boolean RULEACTION_FLOW_CONTROLLER = true;
  
public static void afterInsertRuleAction( List<RuleAction__c> newList){
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){        
    Set<Id> ruleIds = new Set<Id>();
    for(RuleAction__c ruleaction : newList){
      if(ruleaction.Rule__c != null){
        ruleIds.add(ruleaction.Rule__c);
      }
    }
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULEACTION_FLOW_CONTROLLER = false;
}
}

 // public static void afterUpdateRule(List<Rule__c> newList, Map<Id, Rule__c> oldMap ){
public static void afterUpdateRuleAction(List<RuleAction__c> newList,List<RuleAction__c> oldList  ){
Set<Id> ruleIds = new Set<Id>();
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){   
    for(Integer i = 0; i < newList.size(); i++){
      RuleAction__c newRuleaction = newList[i];
      RuleAction__c oldRuleaction = oldList[i];
        if( newRuleaction.Reference_Id__c != oldRuleaction.Reference_Id__c || newRuleaction.Value__c != oldRuleaction.Value__c || newRuleaction.Email_Template__c != oldRuleaction.Email_Template__c || newRuleaction.Notify_User__c != oldRuleaction.Notify_User__c || newRuleaction.Field_Type__c != oldRuleaction.Field_Type__c || newRuleaction.Related_Object__c != oldRuleaction.Related_Object__c || newRuleaction.User_Owner_Id__c != oldRuleaction.User_Owner_Id__c || newRuleaction.CrossObjectField__c != oldRuleaction.CrossObjectField__c || newRuleaction.Long_Value__c != oldRuleaction.Long_Value__c   ){
          if(newRuleaction.Rule__c != null ){
          ruleIds.add(newRuleaction.Rule__c);
        }
        else{
          ruleIds.add(oldRuleaction.Rule__c);
        }
      }
      
    }
    /*
    Get all the Rule Criteria  of Rule  and then update Status__c of the Rule to 'Draft' if  current status ='Active'
    */
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULEACTION_FLOW_CONTROLLER = false;
  } 
}  

public static void afterDeleteRuleAction(List<RuleAction__c> oldList){
Set<Id> ruleIds = new Set<Id>();
if(!AW_ParseCSVTo_AdvanceWorkflow_Util.isImportExportCSV){   
    for(RuleAction__c ruleaction : oldList){
      ruleIds.add(ruleaction.Rule__c);
    }
    if (ruleIds.size()>0  ) updateRule(ruleIds);
    RULEACTION_FLOW_CONTROLLER = false; 
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
  public static void updateDisplayActionData(List<RuleAction__c> listRuleActions){
    Set<Id> ruleIds = new Set<Id>();
    for(RuleAction__c ruleaction : listRuleActions){
      if(ruleaction.Rule__c != null){
        ruleIds.add(ruleaction.Rule__c);
      }
    }
    //DisplayAction__c
    //Type__c&& Related_Object__c && DispalyField__c
    Map<id,Rule__c> ruleMap = new Map<id,Rule__c>([SELECT id,DisplayActions__c 
                                                 FROM Rule__c 
                                                 WHERE id IN :ruleIds]);
    //list<RuleAction__c> newListRuleAction  =[Select Type__c,Related_Object__c,DispalyField__c, Rule__c from RuleAction__c where Rule__c in:ruleIds];
    map<Id,list<RuleAction__c>> mapRuleAction=new map<Id,list<RuleAction__c>>();
    for(RuleAction__c ruleaction:[Select Type__c,Bulk_API__c,Related_Object__c,DispalyField__c,Value__c, Rule__c from RuleAction__c where Rule__c in:ruleIds]){
        if(!mapRuleAction.Containskey(ruleaction.Rule__c)){
          mapRuleAction.put(ruleaction.Rule__c,new list<RuleAction__c>());
        }
        mapRuleAction.get(ruleaction.Rule__c).add(ruleaction);
    }  
    for(Id ruleId:mapRuleAction.keyset()){
      if(ruleMap.containskey(ruleId)){
        Rule__c objRule=ruleMap.get(ruleId);
        objRule.DisplayActions__c='';
        for(RuleAction__c ruleaction:mapRuleAction.get(ruleId)){
          if(ruleaction.Value__c != null || ruleaction.Value__c != ''){
            objRule.DisplayActions__c+=ruleaction.Type__c+ ' ' +ruleaction.Bulk_API__c+' '+ ruleaction.Related_Object__c+ ' ' + ruleaction.DispalyField__c+ ' =' + ruleaction.Value__c + ','  ;
          }
          else{
            objRule.DisplayActions__c+=ruleaction.Type__c+ ' '+ ruleaction.Bulk_API__c+' '+ ruleaction.Related_Object__c+ ' ' + ruleaction.DispalyField__c+ ',';
          }
        }
      }
    }
    update ruleMap.values();
  }   
}
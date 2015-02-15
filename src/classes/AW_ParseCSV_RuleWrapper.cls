/*************************************
  Wrapper class for Rule Action using in import and Export CSV
**************************************/
  public class AW_ParseCSV_RuleWrapper{
    public Rule__c rule {get;set;}
    
    public AW_ParseCSV_RuleWrapper(Rule__c ib){
      rule = ib;
    }
    
    public String Evaluation {get;set;}     
    public String Execution {get;set;}
    public String DisplayCriteria {get;set;}
    public String DisplayActions {get;set;}
    public String advancedWorkflowName{get;set;}
    public String advWorkflowDesc{get;set;}
    public String orderNum{get;set;} 
    //public String formattedCriteria{get;set;}
    //public String formattedActions{get;set;}
    public List<AW_ParseCSV_RuleCriteriaWrapper> ruleCriteriaList{get;set;}
    public List<AW_ParseCSV_RuleActionWrapper> ruleActionList{get;set;}
    public Map<String, Integer> actionTypeCountMap {get;set;}
    
    
    public AW_ParseCSV_RuleWrapper(Rule__c rule , String evaluation , String execution , String displayCriteria , String displayActions){
      
      this.rule = rule; 
      this.Evaluation = evaluation;
      this.Execution = execution;
      this.displayCriteria = displayCriteria;
      this.displayActions = displayActions;
      this.ruleCriteriaList = new List<AW_ParseCSV_RuleCriteriaWrapper>();
      this.ruleActionList = new List<AW_ParseCSV_RuleActionWrapper>();
      this.actionTypeCountMap = new Map<String, Integer>();
      for(String actionType : AW_Rule_Constants.actionTypeForImportMap.values()){
      	this.actionTypeCountMap.put(actionType , 0);
      }
      this.actionTypeCountMap.put('CrossObject' , 0);
      this.actionTypeCountMap.put('LookupObjectField' , 0);
    }
    
  }
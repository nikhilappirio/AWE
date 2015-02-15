//
// (c) 2012 Appirio, Inc.
// AW_AddRulesToWorkflowController                                                     
// This class is used to add Rules to the Execution Plan  
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2012     Peter Babalis     Added Status and Version  for Rules
//  
//  
//  
public with sharing class AW_AddRulesToWorkflowController {
    
    public Rule__c NewRule {get;set;}
 
    public List<RulesPerObject>  listAddRulesPerObject  {get;set;}
 
    private Id  defineruleexecutionplanId ;
    
    public Advance_Workflow__c  ruleExecutionPlan {get;set;}
    
    /**
    * Constructor
    */
    public AW_AddRulesToWorkflowController(ApexPages.StandardController controller) {
        defineruleexecutionplanId = controller.getId();
   
        /**
        * Retrive All Rules related to the Object the Assignment Rule is created by the  "Object__c"
        */
        List<Advance_Workflow__c> listObjects  = new List<Advance_Workflow__c>([Select Id, Enabled__c,Name,Object__c From Advance_Workflow__c Where Id = : controller.getId()]);
        /**
        * Set of Objects
        */  
        Set<String> setObject = new Set<String>();
        if(listObjects != null && listObjects.size() > 0){
            for(Advance_Workflow__c REP : listObjects){
                setObject.add(REP.Object__c);
            }
            ruleExecutionPlan = listObjects[0];
            if(!ruleExecutionPlan.Enabled__c){
           //if(ruleExecutionPlan.Enabled__c){  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info,'Can not add remove rules to a disabled plan'));
            }
        }
        
        List<Rule__c> listRules  = new List<Rule__c>([Select Id,
                                                              Name,
                                                              Filter_Logic__c,
                                                              Description__c, 
                                                              DisplayfilterLogic__c,
                                                              Order__c ,
                                                              Status__c,
                                                              Version__c,
                                                              Advance_Workflow__c,
                                                              Execution_Behavior__c,
                                                              Object__c,
                                                              Total_Actions__c,
                                                              Total_Criteria__c,
                                                              DisplayActions__c,
                                                              Evaluation_Rule__c 
                                                         FROM Rule__c 
                                                         WHERE Object__c in : setObject and ( Status__c in ( 'Draft','Active')) 
                                                         //WHERE ( Status__c in ( 'Draft','Active'))
                                                         ORDER by Order__c ASC NULLS Last]);
          
        listAddRulesPerObject = new List<RulesPerObject>();
        /**
        * Fill the list of wrapper class "RulesPerObject"
        */
        for(Rule__c RO : listRules){   
            if (RO.Total_Actions__c>=1 && RO.Total_Criteria__c>=1)
             {
               RulesPerObject robj = new RulesPerObject();
               robj.Rules = RO;
               robj.isAdd = (RO.Advance_Workflow__c != null && RO.Advance_Workflow__c == defineruleexecutionplanId) ? true : false;
               listAddRulesPerObject.add(robj); 
               SetRecordsinList(robj,RO);
             }
        }                                
    }
    
    /**
    * Select List of Execution Behavior
    */
    Public List<SelectOption> getExecutionBehavior()  {
        List<selectOption> options = new List<selectOption>();
        Schema.DescribeFieldResult field = Rule__c.Execution_Behavior__c.getDescribe();
        for(Schema.Picklistentry picklistEntry : field.getPicklistValues()){
            options.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        }
        return options;  
   }
  
    /**
    * Method for Link Rules  to the RuleofExecution.
    */
    public Pagereference AddRule(){
        //do limit validation:-
        
        try{
            List<Rule__c> updateListRules = new List<Rule__c>();
            Set<Decimal> orderSet = new Set<Decimal>(); 
            for(RulesPerObject RO : listAddRulesPerObject){
                  /**
                  * If "Add Rule" checkbox checked on the page then assign ObjectAssignmentRules__c id to the lookup 
                  * field "Rule_Assignment__c" else assign null
                  */
                  RO.Rules.Advance_Workflow__c = RO.isAdd ? defineruleexecutionplanId : null;
                  RO.Rules.Status__c = RO.isAdd ? 'Active' : 'Draft';
                 system.debug('RO.isAdd '  + RO.isAdd );                   
                  if(RO.isAdd){
                      if(RO.Rules.Order__c == null){
                         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order is required for selected rule'));
                         return null;
                      } 
                      else if(RO.Rules.Order__c == 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order can not be 0'));
                        return null;
                      } 
                      else if(orderSet.contains(RO.Rules.Order__c)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order must be unique'));
                        return null;
                      } else if(RO.Rules.Order__c < 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order can not be negative'));
                        return null;
                      } 
                      else{
                        orderSet.add(RO.Rules.Order__c);
                      }
                  }else{
                      RO.Rules.Status__c='Draft';
                      RO.Rules.Order__c = null;
                      RO.Rules.Execution_Behavior__c = null;
                  }
                  updateListRules.add(RO.Rules);                
            }
            
            /**
            * Update list of Rules
            */
            update updateListRules;
            return new Pagereference('/apex/AW_ListRules_VF?id='+defineruleexecutionplanId);
        }
        catch(Exception e){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0));
            ApexPages.addMessage(msg);
            return null;
        }
    }
    
    /**
    * Return to Execution Plan detail page
    */
    public Pagereference Cancel(){
        return new Pagereference('/apex/AW_ListRules_VF?id='+defineruleexecutionplanId);
    }
    
    private void SetRecordsinList(RulesPerObject objRulesWrapper,Rule__c rule){     
    try{
        if(rule.Evaluation_Rule__c=='Record is Created'){
            objRulesWrapper.Evaluation='Create';
        }
        else if(rule.Evaluation_Rule__c=='Record is Created or Edited'){
        objRulesWrapper.Evaluation='Create, Edit';
        } 
        else if(rule.Evaluation_Rule__c=='Record is created or edited and did not previously meet the rule criteria'){
            objRulesWrapper.Evaluation='Not Meet  Criteria';
        }
        if(rule.Execution_Behavior__c=='Execute Rule and Exit'){
            objRulesWrapper.Execution='Exit';
        }
        else if(rule.Execution_Behavior__c=='Execute Rule and Continue to Next Rule'){
            objRulesWrapper.Execution='Continue';
        }      
        if(rule.DisplayfilterLogic__c != null && rule.DisplayfilterLogic__c !='' && rule.DisplayfilterLogic__c.length()>100){
            objRulesWrapper.Criteria= rule.DisplayfilterLogic__c.mid(0, 100)+'...'; 
        }
        else{
            objRulesWrapper.Criteria= rule.DisplayfilterLogic__c;                           
        }
        objRulesWrapper.DisplayCriteria= rule.DisplayfilterLogic__c;      
        if(rule.DisplayActions__c != null && rule.DisplayActions__c !='' && rule.DisplayActions__c.length()>100){
            objRulesWrapper.Actions= rule.DisplayActions__c.mid(0, 100)+'...';                               
        }
        else{
            objRulesWrapper.Actions= rule.DisplayActions__c;                            
        }   
        objRulesWrapper.Actions= rule.DisplayActions__c;
        //lstInstallBaseWrapper.add(objRulesWrapper);
    }
    catch(exception ex){
        
    }
 }
    
    
     
    /**
    * Inner Class
    */
    public class RulesPerObject{
        public boolean isAdd {get;set;}
        public Rule__c Rules {get;set;}
        public String Evaluation {get;set;}     
        public String Execution {get;set;}
        public String Criteria {get;set;}
        public String DisplayCriteria {get;set;}
        public String Actions {get;set;}    
        public String DisplayActions {get;set;}
    }
}
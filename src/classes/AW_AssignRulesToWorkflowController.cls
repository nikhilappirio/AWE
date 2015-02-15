// 
// (c) 2012 Appirio, Inc.
// Name 			: AW_AssignRulesToWorkflowController	                                                  
// This class creates Execution Plan if not found and Assign Execution Plan to rule 
// based on ID get the object type from the Rule__c	and 
// based on object type get the id, name for the ruleexecution plan 		    			    *
//
// 18 Nov 2012     Peter Babalis     Original
// 02 Feb 2013     Peter Babalis     Remove Advance_Workflow.Enabled dependency//  
 
public with sharing class AW_AssignRulesToWorkflowController {
	
	/**
	* List of Rule to be rendered as table
	*/
	public List<Rule__c>  newRuleAssignmenttoExecutionPlan  {get;set;}
	
	/**
	* Execution Plan Instance
	*/
	public Advance_Workflow__c ruleExecutionPlan  {get;set;}
	
	/**
	* Rule Name
	*/
	public string ruleName{get;set;}
	
	public boolean enabledPlan{get;set;}
	
	public boolean availableRule{get;set;}
	
	private Set<Decimal> orders{get;set;}
	
	
	/**
	* Constructor
	*/
	public AW_AssignRulesToWorkflowController(ApexPages.StandardController controller) {
		if(controller != null){
			enabledPlan = false; 
			availableRule = false;
			orders = new Set<Decimal>();
			newRuleAssignmenttoExecutionPlan = new List<Rule__c>();
			String ruleId = controller.getId();   
			List<Rule__c> retrievedRuleList   = new List<Rule__c> ([SELECT id,
			                                                               Name,
			                                                               Description__c,
																		   DisplayfilterLogic__c, 
																		   Order__c, 
																		   Status__c,
																		   Version__c,
																		   Object__c,
																		   Advance_Workflow__c,
																		   Execution_Behavior__c,
																		   Total_Actions__c,
																		   Total_Criteria__c 
																      FROM Rule__c 
																      WHERE Id = : controller.getId() 
																      limit 1 ]); 
			NewRuleAssignmenttoExecutionPlan = new List<Rule__c>();
			if(retrievedRuleList != null && retrievedRuleList.size() > 0){
				
				newRuleAssignmenttoExecutionPlan.add(retrievedRuleList[0]);
				system.debug( '---newRuleAssignmenttoExecutionPlan[0].Status__c'+ newRuleAssignmenttoExecutionPlan[0].Status__c );
				system.debug( '---newRuleAssignmenttoExecutionPlan[0].Total_Criteria__c'+  newRuleAssignmenttoExecutionPlan[0].Total_Criteria__c);
				system.debug( '---newRuleAssignmenttoExecutionPlan[0].Total_Actions__c'+  newRuleAssignmenttoExecutionPlan[0].Total_Actions__c);
				
				//if(!newRuleAssignmenttoExecutionPlan[0].Available__c){
				if( (newRuleAssignmenttoExecutionPlan[0].Status__c==null) || ( ( newRuleAssignmenttoExecutionPlan[0].Status__c=='Draft' && (newRuleAssignmenttoExecutionPlan[0].Total_Criteria__c== null ||  newRuleAssignmenttoExecutionPlan[0].Total_Criteria__c== 0 ) || (newRuleAssignmenttoExecutionPlan[0].Total_Actions__c==null || newRuleAssignmenttoExecutionPlan[0].Total_Actions__c==0) ) ) ){
					//ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Rule is not active'));
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Rule is Incomplete.It needs at least one actions and one criteria in order to associate to an Advance Workflow '));
					return;
				} 
				else if(newRuleAssignmenttoExecutionPlan[0].Status__c=='Active' ){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Rule is already associated with an Advance Workflow.'));
					return;
				
				}
				else if(newRuleAssignmenttoExecutionPlan[0].Status__c=='Archived' ){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Rule has been archived.'));
					return;
				 }
				else{
					availableRule = true;
				}
				ruleName = retrievedRuleList[0].Name;
				List<Advance_Workflow__c> listRuleExecutionPlan = new List<Advance_Workflow__c> ([SELECT Id,
				                                                                                         Name,
				                                                                                         Enabled__c,
																			                             (SELECT order__c from Rules__r) 
																				                  FROM Advance_Workflow__c 
																				                  WHERE Object__c =:newRuleAssignmenttoExecutionPlan[0].Object__c]);
				if(listRuleExecutionPlan.size() > 0){
					//if(listRuleExecutionPlan[0].Enabled__c == true && newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c == null){
					if(listRuleExecutionPlan[0].Enabled__c != true && newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c == null){
						enabledPlan = true; 
					    //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'Please disable this plan to associate this rule to the plan. Then enable the plan.'));
						ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'Please Enable the Advance Workflow to associate this rule to the plan.'));
					}
					ruleExecutionPlan = listRuleExecutionPlan[0];
					for(Rule__c rule: ruleExecutionPlan.Rules__r){
						if(rule.Id != ruleId){
							orders.add(rule.Order__c);
						}
					}
					newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c = ruleExecutionPlan.Id;
					// Commented default order of 10 
					/*if(newRuleAssignmenttoExecutionPlan[0].Order__c == null){
						newRuleAssignmenttoExecutionPlan[0].Order__c = 10;
					}*/

				}
			} 
		}
	}

	/**
	* Create Execution Plan if not found
	*/
	public void createRuleExecutionPlan(){
		Set<String> setObject = new Set<String>();
system.debug('--createRuleExecutionPlan');
	//	if(ruleExecutionPlan == null && newRuleAssignmenttoExecutionPlan.size() > 0 && newRuleAssignmenttoExecutionPlan[0].Available__c){
		if(ruleExecutionPlan == null && newRuleAssignmenttoExecutionPlan.size() > 0 && ( newRuleAssignmenttoExecutionPlan[0].Total_Criteria__c>0 ) && ( newRuleAssignmenttoExecutionPlan[0].Total_Actions__c > 0 ) && (newRuleAssignmenttoExecutionPlan[0].Status__c =='Draft')){
			Advance_Workflow__c rulePlan = new Advance_Workflow__c();
			rulePlan.Object__c = newRuleAssignmenttoExecutionPlan[0].Object__c;
			rulePlan.Name = newRuleAssignmenttoExecutionPlan[0].Object__c +' '+ System.Now();
			ruleplan.Description__c = 'Created at '+system.now().format();
			ruleplan.Enabled__c=True;
			insert rulePlan;
			ruleExecutionPlan = rulePlan;
			newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c = rulePlan.id;
			// Commented default order of 10
			//newRuleAssignmenttoExecutionPlan[0].Order__c = 10;
		}
		if (ruleExecutionPlan != null){
			newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c = ruleExecutionPlan.id;
		}	 
	}
	
	/**
	* Create SelectOptions for execution Behaviour
	*/
	public List<SelectOption> getExecutionBehavior()  {
		List<selectOption> options = new List<selectOption>();
		Schema.DescribeFieldResult field = Rule__c.Execution_Behavior__c.getDescribe();
		for(Schema.Picklistentry picklistEntry : field.getPicklistValues()){
            options.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        }
		return options;  
    }
	
	 
	/**
	* Assign Execution Plan to rule and update it
	*/
	public Pagereference updateRule(){
		 
			if(newRuleAssignmenttoExecutionPlan.size() > 0){
				newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c = ruleExecutionPlan.Id;
			 	newRuleAssignmenttoExecutionPlan[0].Status__c = 'Active';
			
				if(orders.contains(newRuleAssignmenttoExecutionPlan[0].Order__C)){
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Order number already used'));
					return null;
				}
				else if(newRuleAssignmenttoExecutionPlan[0].Order__c == 0){
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Order cant be zero'));
					return null;
				}
				update newRuleAssignmenttoExecutionPlan[0];
				return new Pagereference('/'+ newRuleAssignmenttoExecutionPlan[0].Id);
			}
		 
		return null;
    }
    
    /**
	* Assign Execution Plan to rule and update it
	*/
	public Pagereference updateRule1(){
		try{
			if(newRuleAssignmenttoExecutionPlan.size() > 0){
				newRuleAssignmenttoExecutionPlan[0].Advance_Workflow__c = ruleExecutionPlan.Id;
			 	newRuleAssignmenttoExecutionPlan[0].Status__c = 'Active';
			
				if(orders.contains(newRuleAssignmenttoExecutionPlan[0].Order__C)){
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Order number already used'));
					return null;
				}
				else if(newRuleAssignmenttoExecutionPlan[0].Order__c == 0){
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Order cant be zero'));
					return null;
				}else if(newRuleAssignmenttoExecutionPlan[0].Order__c < 0){
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Order can not be negative'));
                     return null;
                }
				update newRuleAssignmenttoExecutionPlan[0];
				return new Pagereference('/'+ newRuleAssignmenttoExecutionPlan[0].Id);
			}
		}
		catch(Exception ex){
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,ex.getDMLMessage(0)));
		}
		return null;
    }
  	
  	
  	/**
  	* Action for cancel button
  	*/
    public Pagereference cancel(){
        return new Pagereference('/'+newRuleAssignmenttoExecutionPlan[0].Id);
    }
}
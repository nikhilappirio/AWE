// 
// (c) 2012 Appirio, Inc.
//
// AW_trgr_AdvanceWorkflowManager                                                     
//
// Handler Class to process event for trigger AW_AdvanceWorkflowMain
// Validate only one AdvanceWorkflow per object  
//  
// 02 FEb 2013    Original Peter Babalis
//
public with sharing class AW_trgr_AdvanceWorkflowManager {
	 
//Variable to make sure that the Rule insert, update  delete  is happening only once.
public static Boolean ADVANCEWORKFLOW_FLOW_CONTROLLER = true;

public static void beforeInsertAdvanceWorkflow( List<Advance_Workflow__c> newList){
Set<String> objName = new Set<String>();
/**  Get All  Advance Workflow  */
for(Integer i = 0; i < newlist.size()  ;i++){
	Advance_Workflow__c newFlow =  newlist[i];
	objName.add(newFlow.Object__c);
}     
/** Get existing execution plan  */
    List<Advance_Workflow__c> workflowList = [select Id,Object__c from Advance_Workflow__c where Object__c in: objName];
    Set<String>  alreadyDefineForObj = new Set<String>();
    for(Advance_Workflow__c workflow:workflowList ){
        alreadyDefineForObj.add(workflow.Object__c);
    }
/** Add error if aleady defined execution plan for object */
for(Integer i = 0; i < newlist.size()  ;i++){
	Advance_Workflow__c newFlow =  newlist[i];
	if(alreadyDefineForObj.contains(newFlow.Object__c)){
		newFlow.addError('An Advance Workflow exists for the object');
	}
}  
ADVANCEWORKFLOW_FLOW_CONTROLLER = false;
}

public static void beforeUpdateAdvanceWorkflow( List<Advance_Workflow__c> newList,List<Advance_Workflow__c> oldList){
Set<String> objName = new Set<String>();
/**  Get All  Advance Workflow  */
for(Integer i = 0; i < oldlist.size()  ;i++){
	Advance_Workflow__c oldFlow =  oldlist[i];
	Advance_Workflow__c newFlow =  newlist[i];
	if(newFlow.Object__c != oldFlow.Object__c && newFlow.Object__c != null){
                objName.add(oldFlow.Object__c);
     }
}     
/** Get existing execution plan  */
  //  List<Advance_Workflow__c> workflowList = [select Id,Object__c from Advance_Workflow__c where Object__c in: objName];
    Advance_Workflow_Limits__c awLimits = Advance_Workflow_Limits__c.getInstance('NumAdvWorkflowPerQuery');
    Integer rowLimit = 2000;
    if(awLimits != null && awLimits.Value__c != null){
    	rowLimit = Integer.valueOf(awLimits.Value__c);
    }
    List<Advance_Workflow__c> workflowList = [select Id,Object__c from Advance_Workflow__c Limit :rowLimit];
    Set<String>  alreadyDefineForObj = new Set<String>();
    for(Advance_Workflow__c workflow:workflowList ){
        alreadyDefineForObj.add(workflow.Object__c);
    }
/** Add error if aleady defined execution plan for object */
for(Integer i = 0; i < oldlist.size()  ;i++){
	Advance_Workflow__c oldFlow =  oldlist[i];
	Advance_Workflow__c newFlow =  newlist[i];
	if(newFlow.Object__c != oldFlow.Object__c && newFlow.Object__c != null){
		if(alreadyDefineForObj.contains(newFlow.Object__c)){
            newFlow.addError('An Advance Workflow exists for the object');
         }
     }
}  
ADVANCEWORKFLOW_FLOW_CONTROLLER = false;

}
 
}
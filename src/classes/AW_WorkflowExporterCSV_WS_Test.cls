/**
 * Test Class for AW_WorkflowExporterCSV_WS
 */
@isTest
private class AW_WorkflowExporterCSV_WS_Test {

    static testMethod void testExporter() {
        Rule__c rule    =   new Rule__c(Name = 'How to enter merge values as criteria Contact_test',
                                        Status__c = 'Draft',
                                        Object__c = 'Contact', 
                                        Version__c = 1,
                                        Description__c = 'Rule 1 Description',
                                        Evaluation_Rule__c='Record is created or edited'
                                        //,Advance_Workflow__c = advanceWF.id
                                        );
        insert rule;
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Contact', 'Equals', 'Test', 'LastName', 'LastName', 'STRING', true);     
        
        RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rule, 'Contact', True, 'FirstName', 'Update Field', 'FirstName', true);
        String fieldString = 'select ' + loadFields() + ' from Rule__c';
        AW_WorkflowExporterCSV_WS.exportCSV(fieldString);
        System.assert(AW_WorkflowExporterCSV_WS.WorkflowExportCSV(fieldString) != null);
        
    }
    
    private static String loadFields(){
   	Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Rule__c').getDescribe().Fields.getMap();
   	String fieldString  = '';
   	for(String fd : fieldsMap.keySet()){
   		if(fd != 'lastreferenceddate'){
   			fieldString += fd + ',';
   		}
   	}
   	if(fieldString.endsWith(',')){
   		fieldString = fieldString.subString(0, fieldString.lastIndexOf(','));
   	}
   	return fieldString;
   }
}
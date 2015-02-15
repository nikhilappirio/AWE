global with sharing class AW_WorkflowExporterCSV_WS {
 webservice static list<Rule__c> WorkflowExportCSV(string soql){
 
 // system.debug('Akhilesh --> soql' + soql); 
  
  soql += ' Limit 10000';
   
  list<Rule__c> lstrules = Database.query(soql);
  
  if(lstrules.size()>0){  
    return lstrules;
  }
   
    return null;
 }
 
 	/*  
	 * Export csv
	 */
	  //@RemoteAction
   	 webservice static String exportCSV(String soql){
   	 	List<Rule__c> rules = Database.query(soql);
   	 	AW_CSVGenerator csvGenerator = new AW_CSVGenerator();
   	 	List<RuleCriteria__c> ruleCriteriaList = AW_CSVGenerator.loadRuleCriteriaList(rules); 
        List<RuleAction__c> ruleActionList = AW_CSVGenerator.loadRuleActionList(rules);
        return csvGenerator.exportInCSVForm(rules, new List<RuleCriteria__c>() , new List<RuleAction__c>()); 
   	 } 
 
}
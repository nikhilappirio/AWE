public with sharing class AW_RetrieveArchiveExtensions {
	public  Rule_Archive__c     ruleArchive         =   null;
    public String ruleName{get;set;}
    public String ruleArchiveId {get;set;}
    public String aweId {get;set;}
    public String objName{get;set;}

    public AW_RetrieveArchiveExtensions(ApexPages.StandardController stdController){
    	aweId = stdController.getId();
    	if(aweId != null){
	    	for(Advance_Workflow__c advWF : [select id , Object__c from Advance_Workflow__c where id = : aweId]){
	    		objName = advWF.Object__c;
	    	}
    	}else{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Advance Workflow first'));
    	}
    }   
    
    public PageReference retrieveRuleArchive(){
    	if(ruleArchiveId == null){
    		// error
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Rule Name'));
    		return null;
    	}
    	return new PageReference('/'+ruleArchiveId);
    }
}
public with sharing class AW_AdvanceWorkflowImportResultController {
 

	public	String					AWFId		{get;set;}
	public	String					refRule		{get;set;}
	public  String					valorTest	{get;set;}
	public	List<Error_Log__c>		failures	{get;set;}	
	public	List<Rule__c>			success		{get;set;}
	
	public	AW_AdvanceWorkflowImportResultController(){
		this.AWFId		=	ApexPages.currentPage().getParameters().get('id');
		this.refRule	=	ApexPages.currentPage().getParameters().get('refRule');
		this.failures	=	[select Name, Error_Description__c, ErrorSource__c from Error_Log__c where import_code__c =: refRule];
		this.success	=	[select Name from Rule__c where import_code__c =: refRule];
	}
	
	public	Pagereference	back(){
		Pagereference currPage	=	ApexPages.currentPage();
		String	returnURL		=	currPage.getURL().substringBefore('apex') + AWFId;
		return new Pagereference(returnURL);		
	}
	public	Pagereference	goToLink(){
		transient	Pagereference currPage	=	ApexPages.currentPage();
		transient	String	returnURL		=	currPage.getURL().substringBefore('apex') + AWFId;
		return new Pagereference(returnURL);		
	}
	
	@isTest
	static void MyTest() {
		
   		PageReference pageRef = Page.AW_AdvanceWorkflowImportResult_VF;
   		Test.setCurrentPage(pageRef);
   		
   		// Add parameters to page URL
   		ApexPages.currentPage().getParameters().put('id', 'id');
   		
   		AW_AdvanceWorkflowImportResultController controller = new AW_AdvanceWorkflowImportResultController(); 
 
   		// Instantiate a new controller with all parameters in the page
   		controller = new AW_AdvanceWorkflowImportResultController();   
   		controller.back();
   		controller.goToLink();
   		
	}	
	
}
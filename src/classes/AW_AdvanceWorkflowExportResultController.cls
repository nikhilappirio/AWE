public with sharing class AW_AdvanceWorkflowExportResultController {

	public		Boolean		success	{get;set;}
	public		String		AWFId	{get;set;}
	public AW_AdvanceWorkflowExportResultController(){
		this.success	=	Boolean.valueOf(ApexPages.currentPage().getParameters().get('success'));
		this.AWFId		=	ApexPages.currentPage().getParameters().get('id');		
	}
	public	Pagereference	back(){
		transient	Pagereference 	currPage		=	ApexPages.currentPage();
		transient	String			returnURL		=	currPage.getURL().substringBefore('apex') + AWFId;
		return new Pagereference(returnURL);
	}
	
	@isTest
	static void MyTest() {
		
   		PageReference pageRef = Page.AW_AdvanceWorkflowExportResult_VF;
   		Test.setCurrentPage(pageRef);
   		
   		// Add parameters to page URL
   		ApexPages.currentPage().getParameters().put('id', 'id');
   		ApexPages.currentPage().getParameters().put('success', 'true');
   		
   		AW_AdvanceWorkflowExportResultController controller = new AW_AdvanceWorkflowExportResultController(); 
 
   		// Instantiate a new controller with all parameters in the page
   		controller = new AW_AdvanceWorkflowExportResultController();   
   		controller.back();
       		
	 	
	}	
	
}
//
// (c) 2012 Appirio, Inc.
// AW_ImportCSVJobProcessing                                                     
// 
//
//
public with sharing class AW_ImportCSVJobProcessing {

    public  String      AWFId       {get;set;}
    private String  refRule;
    public  Id JobId {get;set;}
    private Integer actionPollerCount;
    public AW_ImportCSVJobProcessing(){
        this.AWFId      =   ApexPages.currentPage().getParameters().get('id');
        this.refRule  =  ApexPages.currentPage().getParameters().get('refRule');
        this.JobId = ApexPages.currentPage().getParameters().get('JobId');
		actionPollerCount = 0;
		ApexPages.Message processMsg = new ApexPages.Message(ApexPages.Severity.Info,'Your job has been queued for execution and should complete within a few minutes.');
   	    ApexPages.addMessage(processMsg);
    }
    
      // check Job Processing
    public PageReference jobProcessing(){
	  if(jobId != null){
		 for( AsyncApexJob asyncJob :  [select Id,JobItemsProcessed, Status from AsyncApexJob where Id =: jobId]){
			  if(asyncJob.Status == 'Completed'){
			  	return new PageReference('/apex/AW_AdvanceWorkflowImportResult_VF?id=' + AWFId + '&refRule=' + refRule);
			  }else if(asyncJob.Status == 'Failed'){
			  	ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, asyncJob.ExtendedStatus + '. <a href= "/'+ AWFId + '" > Back </a> ');
	   	    	ApexPages.addMessage(errMsg);
			  }else{
			  	ApexPages.Message processMsg = new ApexPages.Message(ApexPages.Severity.Info,'Your job has been queued for execution and should complete within a few minutes.');
   	    		ApexPages.addMessage(processMsg);
			 }
		} 
  	  }else{
  	  		actionPollerCount++;
  	  		if(actionPollerCount == 50){
				ApexPages.Message  errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Error' + '. <a href= "/'+ AWFId + '" > Back </a> ');
	   	    	ApexPages.addMessage(errMsg);
  	  		}else{
  	  			return new PageReference('/apex/AW_AdvanceWorkflowImportResult_VF?id=' + AWFId + '&refRule=' + refRule);
  	  		}
	  }
	  return null;
  }
}
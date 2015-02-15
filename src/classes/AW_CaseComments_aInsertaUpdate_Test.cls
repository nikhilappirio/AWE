//
// (c) 2012 Appirio, Inc.
// Test Class for  AW_CaseComments_aInsertaUpdate  Trigger                                                      
//  
// 18 Nov 2012     Peter Babalis      Original
//  
//  
// 
@isTest
private  class AW_CaseComments_aInsertaUpdate_Test {
static List<CaseComment> testListCsComs;

static List<CaseComment > testListCaseComment;

static testMethod void testRuleEngine() {
       //Creating Cases
       //Id Ids ;
       integer numOfCss=10;
       integer numOfOpptys=10;
       Set<Id> Ids=new Set<Id>();
       createTestDataForRuleEngine();
       
       testListCsComs = [ Select Id, ParentId,CommentBody   from CaseComment  limit 10 ];
     
        for (integer i=0; i<testListCsComs.size();i++   )
        { 
        	 Ids.add(testListCsComs[i].Id);
        }

     //Calling Rule Engine Service
        AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,'CaseComment',true);
        
       System.assert(testListCsComs.size() > 0);
     
    }
    	
//Method to create Test Data
static testMethod void createTestDataForRuleEngine()
{
	  integer numOfCases=5;  
	  List<Case> caseList = new List<Case>();
      for(integer i = 1; i <= numOfcases ; i++){  
	    Case cs = new Case();
        cs.Subject='Subject - Technology'+1;
        cs.Priority='High';
        caseList.add(cs);
      }
      
      insert caseList;
      
      integer numOfCaseComments =10;
         
      List<CaseComment> CaseCommentsList = new List<CaseComment>();
      for(integer i = 1; i <= numOfCaseComments; i++){  
        CaseComment cscomment  = new CaseComment();
        cscomment.ParentId = caseList[0].Id;
        cscomment.CommentBody='Some Case Body Comment'+ i;
        CaseCommentsList.add(cscomment);
      }
		 
		try{ insert CaseCommentsList; }			
		catch(Exception e){	System.assert(false, 'Fails for inserting Test Accounts - inside createTestDataForAccountRuleEgine()'+e.getMessage()); }
	   
}  
}
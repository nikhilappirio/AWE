// 
// (c) 2012 Appirio, Inc.
// Name             : AW_Console_EditController_Test                                                     
// This is the test classs for AW_Console_EditController
//
// 18 Nov 2012     Peter Babalis     Original
//  
//  
@isTest
public class AW_Console_EditController_Test{
	
 public static TestMethod void test_init(){
    
   
	 Workflow_DynamicColumns__c wfdc;
	 wfdc = new Workflow_DynamicColumns__c( Label__c='ABC', ApiName__c='Industry__c',Page_Layout__c='Page',Help_Text__c='Some Help',DataType__c='String',Type__c = 'Fixed');
     insert wfdc;
     AW_Console_EditController  consedit = new AW_Console_EditController();
      
     Id wfdcid=[Select Id  from Workflow_DynamicColumns__c Limit 1].ID;
     Map<String, Schema.SObjectField> fieldMap;
     fieldMap = AW_Console_EditController.getFieldMap(String.valueOf(wfdcid.getSObjectType()));
   
      
      }
}
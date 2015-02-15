// 
// (c) 2012 Appirio, Inc.
//
//  AW_Advance_WorkflowController_Test                                                    
//
// This test class tests DefineRuleExecutionPlanController functionality
//
// 18 Nov 2012     Peter Babalis     Original
//  
//
@isTest
public class AW_Advance_WorkflowController_Test{

    /**
    * Test saveRule method for new Plan
    */
    public static TestMethod void newPlanSaveActionTest(){
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(new Advance_Workflow__c()));
        
        controller.newruleexecutionplan.Name = 'Test Test Test Acc';
        controller.newruleexecutionplan.Description__c = 'Test Description';
        controller.obj = 'Account';
        Test.startTest();
        PageReference page = controller.saveRule();
        Test.stopTest(); 
        System.assertEquals('/'+controller.newruleexecutionplan.id,page.getUrl());
    }
    
    /**
    * Test saveRule method for existing Plan
    */
    public static TestMethod void existingPlanSaveActionTest(){
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        insert plan;
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(plan));
       
        controller.newruleexecutionplan.Description__c = 'Test Description';
        Test.startTest();
        PageReference page = controller.saveRule();
        Test.stopTest(); 
        System.assertEquals('/'+controller.newruleexecutionplan.id,page.getUrl());
    }
    
    /**
    * Test saveAndNewRule method for new Plan
    */
    public static TestMethod void saveAndNewRuleTest(){
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(new Advance_Workflow__c()));
    
        controller.newruleexecutionplan.Name = 'Test Test Test Acc';
        controller.newruleexecutionplan.Description__c = 'Test Description';
        controller.obj = 'Account';
        Test.startTest();
        PageReference page = controller.saveAndNewRule();
        Test.stopTest(); 
        System.assertEquals('/apex/AW_Advance_Workflow_VF',page.getUrl());
    }
    
    /**
    * Test saveRule method for existing plan with duplicate name validation
    */
    public static TestMethod void SaveValidationTest(){
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        insert plan;
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(new Advance_Workflow__c()));
    
        controller.newruleexecutionplan.Name = 'Test Test Plan';
        controller.newruleexecutionplan.Description__c = 'Test Description';
        controller.obj = 'Account';
        Test.startTest();
        PageReference page = controller.saveRule();
        Test.stopTest(); 
        System.assertEquals(null, page);
    }

    /**
    * Test saveAndNewRule method for existing plan with duplicate name validation
    */
    public static TestMethod void SaveandNewValidationTest(){
        Advance_Workflow__c plan = new Advance_Workflow__c(Name = 'Test Test Plan');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        insert plan;
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(new Advance_Workflow__c()));
    
        controller.newruleexecutionplan.Name = 'Test Test Plan';
        controller.newruleexecutionplan.Description__c = 'Test Description';
        controller.obj = 'Account';
        Test.startTest();
        PageReference page = controller.saveAndNewRule();
        Test.stopTest(); 
        System.assertEquals(null, page);
    }
    
    public static testmethod void testDeployFields(){
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        AW_Advance_WorkflowController controller = new AW_Advance_WorkflowController(new ApexPages.StandardController(new Advance_Workflow__c()));
    
        controller.newruleexecutionplan.Name = 'Test Test Test Acc';
        controller.newruleexecutionplan.Description__c = 'Test Description';
        controller.newruleexecutionplan.Advance_Rule_Stamp__c=true;
        controller.obj = 'Account';
        Test.startTest();
        //  PageReference page = controller.saveRule();
            PageReference page = controller.saveAndNewRule();
        Test.stopTest(); 
        
        System.assertEquals('/apex/AW_Advance_Workflow_VF',page.getUrl());
    }
    
     /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
    private class WebServiceMockImpl implements WebServiceMock 
    {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) 
        {
            if(request instanceof MetadataService.retrieve_element)
                response.put('response_x', new MetadataService.retrieveResponse_element());
            else if(request instanceof MetadataService.checkDeployStatus_element)
                response.put('response_x', new MetadataService.checkDeployStatusResponse_element());
            else if(request instanceof MetadataService.update_element)
                response.put('response_x', new MetadataService.updateResponse_element());
            else if(request instanceof MetadataService.listMetadata_element)
                response.put('response_x', new MetadataService.listMetadataResponse_element());
            else if(request instanceof MetadataService.checkStatus_element)
                response.put('response_x', new MetadataService.checkStatusResponse_element());
            else if(request instanceof MetadataService.create_element)
                response.put('response_x', new MetadataService.createResponse_element());
            else if(request instanceof MetadataService.checkRetrieveStatus_element)
                response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
            else if(request instanceof MetadataService.delete_element)
                response.put('response_x', new MetadataService.deleteResponse_element());
            else if(request instanceof MetadataService.describeMetadata_element)
                response.put('response_x', new MetadataService.describeMetadataResponse_element());
            else if(request instanceof MetadataService.deploy_element)
                response.put('response_x', new MetadataService.deployResponse_element());
            return;
        }
    }    
}
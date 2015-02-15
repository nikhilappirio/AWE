@IsTest
public class AW_VisualDisplayController_Test{
        
        static testMethod void uploadTest() {
            //Split string 'file' in to two chunks, first chunk must be divisible by 3 for base64 encode with no padding
            Blob part1 = Blob.valueOf('This text represents a dummy file'); //length is 12 
           
                    
            String part1base64 = EncodingUtil.base64Encode(part1);
            
            
            Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
            
            String wf = [Select Advance_Workflow__c FROM Rule__c WHERE Id=:rule.Id].Advance_Workflow__c; 
            
            
            //Start the test
            Test.startTest();
            //Send first part of the file to be uploaded
            String attachmentId = AW_VisualDisplayController.attachBlob(wf ,'fileName','text',part1base64);
            
            Test.stopTest();
            
            //Assert one file has been attached to the test account
            List<Attachment> attachments = [select Id, Body from Attachment where ParentId = :wf];
            system.assert(attachments.size() == 1);
            
            //Assert the contents of the split file were recontructed correctly
            system.assert(attachments[0].Body.toString() == 'This text represents a dummy file');
        }
        
        static testmethod void initializeUIData(){
            Rule__c rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
            
            String wf = [Select Advance_Workflow__c FROM Rule__c WHERE Id=:rule.Id].Advance_Workflow__c; 
            
            Test.startTest();
                AW_VisualDisplayController.initializeUIData(wf);
            Test.stopTest();
            
        }

}
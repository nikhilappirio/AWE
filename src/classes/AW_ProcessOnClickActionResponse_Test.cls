@IsTest
public class AW_ProcessOnClickActionResponse_Test{
		
		
		static testMethod void testEmailHandler() {
 			 
 			 Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
                insert rule; 
             
             RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='CrossObject',CrossObjectField__c='Account.Type',Type__c='Update Field',Value__c='Prospect');
    
            insert a1;
             Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Mining');
              insert a;   
 			  
 			 ClickEventActionResponse__c res = new ClickEventActionResponse__c();
			 res.action__c=a1.Id;
			 res.recordid__c=a.id;
			 res.record_name__c='Test';
		     insert res;
 			  
			  // create a new email and envelope object
			  Messaging.InboundEmail email = new Messaging.InboundEmail() ;
			  Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
			 
			  // setup the data for the email
			  email.subject = 'Response#'+res.Id+':Test Job Applicant';
			  email.fromname = 'FirstName LastName';
			  env.fromAddress = 'someaddress@email.com';
			 
			  email.plainTextBody='this is a test';
			  // add an attachment
			  Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
			  attachment.body = blob.valueOf('my attachment text');
			  attachment.fileName = 'textfile.txt';
			  attachment.mimeTypeSubType = 'text/plain';
			 
			  email.binaryAttachments =
			    new Messaging.inboundEmail.BinaryAttachment[] { attachment };
			 
			  // call the email service class and test it with the data in the testMethod
			  AW_ProcessOnClickActionResponse emailProcess = new AW_ProcessOnClickActionResponse();
			  emailProcess.handleInboundEmail(email, env);
			 
			  // query for the contact the email service created
			  Task task = [select id, subject from task
			    where subject = 'Test Job Applicant'];
			 
			  System.assertEquals(task.subject,'Test Job Applicant');
			  
			  // find the attachment
			  Attachment a2 = [select name from attachment where parentId = :task.id];
			 
			  System.assertEquals(a2.name,'textfile.txt');
		 
		}	
		
}
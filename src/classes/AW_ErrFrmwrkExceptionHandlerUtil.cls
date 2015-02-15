// 
// (c) 2012 Appirio, Inc.
//
//  AW_ErrFrmwrkExceptionHandlerUtil
//  Main class for error logging and posting chatter feed.
//
// 12 Jan 2013     Peter Babalis     Original
//
// Parameter Description:
// StrLogEmailUIChtr   :concatinated string for error communication,option available Logging,Email,UI message,Chatter post
//                        example1:'EmailChtr'-to send email and post it to chatter.
//                        example1:'LogEmailUI'-Log it to the error object,email the error and show the message on the UI.
// emailIdChtrGroup    :EmailId or/and chatter group name.Email and chatter group name should be seperated by a colon(:)
//                        example1:'test@netapp.com:testChatterGroup.
// callingFuncName     :Class name from which the method is called.
// callingMethodName   :Method name from the error handled is invoked.
// CustomErrorMsg      :Custom error message to be shown instead of standard exception message.
//  
// 
public class AW_ErrFrmwrkExceptionHandlerUtil {
         
    public AW_ErrFrmwrkExceptionHandlerUtil(){}
    
    public static void mHandleErrFrmwrk(Exception eXpObj, String emailIdChtrGroup, string typename, String callingFuncName, 
                                        String callingMethodName, String StrSource, String StrLogEmailUIChtr){
        mHandleErrFrmwrk(eXpObj, emailIdChtrGroup, typename, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, '');
    }
    
    public static void mAsyncHandleErrFrmwrk(String errDescription,String errStackTrace, Integer lnNumber,String emailAddr,string typename,
                                            String callingFuncName, String callingMethodName, String StrSource, String StrLogEmail){
        mAsyncHandleErrFrmwrk(errDescription,errStackTrace, lnNumber, emailAddr, typename, callingFuncName, callingMethodName, StrSource, StrLogEmail, '');
    }
    
    public static void mHandleErrFrmwrkCustom(String emailAddr, String typename, String callingFuncName, String callingMethodName,
                                             String StrSource, String StrLogEmail, String strCustomErrMsg){
        mHandleErrFrmwrkCustom(emailAddr, typename, callingFuncName, callingMethodName, StrSource, StrLogEmail, strCustomErrMsg,'');
    }
    
    public static void mHandleErrFrmwrk(Exception eXpObj, String emailIdChtrGroup, string typename, String callingFuncName,String callingMethodName,
                                        String StrSource, String StrLogEmailUIChtr, String strObjectId)
    {
        Integer TEXT_LONG_SIZE = 32768; 
        String ErrorID ;
        String OrganizationName;
        String OrganizationId ;
        OrganizationName = UserInfo.getOrganizationName();
        OrganizationId = UserInfo.getOrganizationid();     
        String errDescription = eXpObj.getCause() + '-' + eXpObj.getMessage() + '-' + eXpObj.getLineNumber();
        String errStackTrace =  eXpObj.getStackTraceString();
        if(eXpObj != null)
        {
            if(eXpObj.getTypeName()=='System.DmlException')
            {
                errDescription = eXpObj.getTypeName() + '-' + eXpObj.getCause() + '-' + eXpObj.getMessage() + '-' + eXpObj.getLineNumber() + '\n';
                errStackTrace =  eXpObj.getStackTraceString() + '\n' + 'Total DMLError Count: '+ eXpObj.getNumDml() + '\n';
                for (Integer i = 0; i < eXpObj.getNumDml(); i++) 
                {
                    errStackTrace +=  eXpObj.getDmlId(i) + '-';
                    for (string f : eXpObj.getDmlFieldNames(i)) 
                    {   
                            errStackTrace += f + ', ' ;
                    }
                    errStackTrace +=  eXpObj.getDmlMessage(i) + '\n';
                }
            }
        }
        errDescription = (errDescription.length() > TEXT_LONG_SIZE) ? errDescription.subString(0,TEXT_LONG_SIZE) : errDescription;
        errStackTrace =  (errStackTrace.length() > TEXT_LONG_SIZE) ? errStackTrace.subString(0,TEXT_LONG_SIZE) : errStackTrace;
        integer lnNumber = eXpObj.getLineNumber();
        // Log error
        if (StrLogEmailUIChtr.contains('Log') == true)
        {
        Error_Log__c errLog = new Error_Log__c(Exception_Type__c=eXpObj.getTypeName(), Error_Description__c=errDescription, Stack_Trace__c=errStackTrace, Object_Method_Name__c=callingFuncName, Object_Name__c=callingMethodName, ErrorSource__c=StrSource, ErrorLineNumber__c= lnNumber, SObjectId__c=strObjectId);
        insert errLog;
        ErrorID= errLog.Id;
        
        }

        // Send Email
        if (StrLogEmailUIChtr.contains('Email') == true){
            if (emailIdChtrGroup==null || emailIdChtrGroup==''){
                Profile prof = [select id from profile where name='System Administrator'];
                 List<User> UserObj = [Select Id,Email from user where profileid =:prof.Id];
                emailIdChtrGroup = UserObj[0].Email;
            }
            if (!Test.isRunningTest()){
                String emailId = emailIdChtrGroup.substringBefore(':');
               // SendEmail('', false,'Advance Workflow Internal Error While Processing : ' + callingFuncName + ':' + callingMethodName,typename+'-'+errDescription,emailId);
                SendEmailtoUser('',false,'Advance Workflow Internal Error While Processing ' , ErrorId, emailId);
                SendEmailtoAdmin('',false,'--- ADVANCE WORKFLOW INTERNAL ERROR --- ',callingFuncName,callingMethodName,lnNumber,errStackTrace,OrganizationId+' - '+OrganizationName,  ErrorId,errDescription);
               
            }
        }
        
         if(StrLogEmailUIChtr.contains('Chtr') == true){
            createAndPostChatterFeed(errDescription,errStackTrace,lnNumber,emailIdChtrGroup.substringAfter(':'));
        }

    }
    
    public static void mAsyncHandleErrFrmwrk(String errDescription,String errStackTrace, Integer lnNumber, String emailIdChtrGroup, string typename,
                                            String callingFuncName, String callingMethodName, String StrSource, String StrLogEmailUIChtr, String strObjectId)
    {   
    	String ErrorID ;
        String OrganizationName;
        String OrganizationId ;
        Integer TEXT_LONG_SIZE = 32768;
        OrganizationName = UserInfo.getOrganizationName();
        OrganizationId = UserInfo.getOrganizationid();
        if (errDescription != '' && errDescription != null){
            errDescription = (errDescription.length() > TEXT_LONG_SIZE) ? errDescription.subString(0,TEXT_LONG_SIZE) : errDescription;
        }
        if (errStackTrace != '' && errStackTrace != null){
            errStackTrace =  (errStackTrace.length() > TEXT_LONG_SIZE) ? errStackTrace.subString(0,TEXT_LONG_SIZE) : errStackTrace;
        }
        // Log error
        if (StrLogEmailUIChtr.contains('Log') == true){
            Error_Log__c errLog = new Error_Log__c(Exception_Type__c=typename, Error_Description__c=errDescription, Stack_Trace__c=errStackTrace, Object_Method_Name__c=callingFuncName, Object_Name__c=callingMethodName, ErrorSource__c=StrSource, ErrorLineNumber__c= lnNumber, SObjectId__c=strObjectId );
            insert errLog;
            ErrorID= errLog.Id;
             
            
        }
    
        // Send Email
        if (StrLogEmailUIChtr.contains('Email') == true){
            if (emailIdChtrGroup==null || emailIdChtrGroup==''){
                Profile prof = [select id from profile where name='System Administrator'];
                List<User> UserObj = [Select Id,Email from user where profileid =:prof.Id];
                emailIdChtrGroup = UserObj[0].Email;
            }
            if (!Test.isRunningTest()){
                String emailId = emailIdChtrGroup.substringBefore(':');
                SendEmailtoUser('',false,'Advance Workflow Internal Error While Processing ' , ErrorId, emailId);
                SendEmailtoAdmin('',false,'--- ADVANCE WORKFLOW INTERNAL ERROR --- ',callingFuncName,callingMethodName,lnNumber,errStackTrace,OrganizationId+' - '+OrganizationName,  ErrorId,errDescription);
               
             // SendEmail('', false,'Advance Workflow Internal Error While Processing :  ' + callingFuncName + ':' + callingMethodName,typename+'-'+errDescription+'-'+strObjectId,emailId);
            }
        }
        if(StrLogEmailUIChtr.contains('Chtr') == true){
            createAndPostChatterFeed(errDescription,errStackTrace,lnNumber,emailIdChtrGroup.substringAfter(':'));
        }
    
    }    
    
    public static void mHandleErrFrmwrkCustom(String emailIdChtrGroup, String typename, String callingFuncName, String callingMethodName, String StrSource,
                                              String StrLogEmailUIChtr, String strCustomErrMsg, String strObjectId){
            Integer TEXT_LONG_SIZE = 32768;
            String ErrorID ;
            String OrganizationName;
            String OrganizationId ;
            strCustomErrMsg = (strCustomErrMsg.length() > TEXT_LONG_SIZE) ? strCustomErrMsg.subString(0,TEXT_LONG_SIZE) : strCustomErrMsg;
            integer lnNumber = 0;
            // Log error
            if (StrLogEmailUIChtr.contains('Log') == true){
            Error_Log__c errLog = new Error_Log__c(Exception_Type__c=typename, Error_Description__c=strCustomErrMsg, Stack_Trace__c='', Object_Method_Name__c=callingFuncName,
                                                                             Object_Name__c=callingMethodName, ErrorSource__c=StrSource, ErrorLineNumber__c= lnNumber, SObjectId__c=strObjectId );
            insert errLog;
            ErrorID= errLog.Id;
            
            }
    
            // Send Email
            if (StrLogEmailUIChtr.contains('Email') == true){
                if (emailIdChtrGroup==null || emailIdChtrGroup==''){
                Profile prof = [select id from profile where name='System Administrator'];
                List<User> UserObj = [Select Id,Email from user where profileid =:prof.Id];
                emailIdChtrGroup = UserObj[0].Email;
                }
                if (!Test.isRunningTest()){
                    String emailId = emailIdChtrGroup.substringBefore(':');
                    SendEmailtoUser('',false,'Advance Workflow Internal Error While Processing ' , ErrorId, emailId);
                    SendEmailtoAdmin('',false,'--- ADVANCE WORKFLOW INTERNAL ERROR --- ',callingFuncName,callingMethodName,lnNumber,'',OrganizationId+' - '+OrganizationName,  ErrorId,'');
               
                    //SendEmail('', false,'Advance Workflow Internal Error While Processing: ' + callingFuncName + ':' + callingMethodName,strCustomErrMsg+'-'+strObjectId,emailId);
                }
            }
            if(StrLogEmailUIChtr.contains('Chtr') == true){
            createAndPostChatterFeed(strCustomErrMsg,callingFuncName+'.'+callingMethodName,lnNumber,emailIdChtrGroup.substringAfter(':'));
        }
    
    }
    
 //Send email to user
public static void SendEmailtoUser(String AttachmentContent,Boolean IsAttachment,String Subject,String ErrorId ,String ToEmailAddress)
     { 
      
    String MessageBodytoUser  = '<html><body><p style="font-weight:bold;"> An internal application error has occurred. <br><br></p>';
    MessageBodytoUser=MessageBodytoUser+'An error has occurred while processing your Advance Workflow Request. ' ;
    MessageBodytoUser=MessageBodytoUser+'The support team has been notified of the problem.';
    MessageBodytoUser=MessageBodytoUser+'If you believe you have additional information that may be of help';
    MessageBodytoUser=MessageBodytoUser+ 'in reproducing or correcting the error,';
    MessageBodytoUser=MessageBodytoUser+' please contact our Support Team. Please indicate the URL of the page you were ';
    MessageBodytoUser=MessageBodytoUser+'requesting,any error id shown on this page as well as any other related information.';
    MessageBodytoUser=MessageBodytoUser+' We apologize for the inconvenience. ';
    MessageBodytoUser=MessageBodytoUser+'<br><br>';
    MessageBodytoUser=MessageBodytoUser+' Thank you again for your patience and assistance. And thanks for using Advance Workflow!  ';
    MessageBodytoUser=MessageBodytoUser+'<br><br>';
    MessageBodytoUser=MessageBodytoUser+' Error ID: '+ErrorId;
    MessageBodytoUser=MessageBodytoUser+'</body></html>';
  
    String[] ToAddressesUsers = new String[]{};
    ToAddressesUsers=ToEmailAddress.split(',');
    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            mail.setToAddresses(ToAddressesUsers);
            mail.setReplyTo('noreply@appirio.com');
            mail.setSubject(Subject);
            mail.setHtmlBody(MessageBodytoUser);            
    
            if(IsAttachment == true){
                Blob body=Blob.Valueof(AttachmentContent);
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setContentType('text/html');
                attach.setFileName('Error.log');
                attach.setInline(false);
                attach.Body = body; 
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
     }
        
    
    //Send email method Admin
     public static void SendEmailtoAdmin(String AttachmentContent,Boolean IsAttachment,String Subject,String CallingFunc,String CallingMethod, Integer lineNumber,String StackTrace,String OrgName,String ErrorId,String BodyContent )
     { 
    /*
      */
    String MessageBodytoAdmin  = '<html><body><p style="font-weight:bold;"> An internal application error has occurred. <br><br></p>';
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+' Organization Name: '+OrgName;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+' Error ID: '+ErrorId;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Error Description : '+BodyContent ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Advance Workflow Name : ' ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Advance Workflow Rule: ' ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Rule Criteria : ' ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Rule Action : ' ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Class : ' +CallingFunc;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Method : '+CallingMethod  ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Line Number '+String.valueOf(lineNumber) ;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'Stack Trace : ' +StackTrace;
    MessageBodytoAdmin=MessageBodytoAdmin+'<br><br>';
    MessageBodytoAdmin=MessageBodytoAdmin+'</body></html>';
     
    String[] ToAddressesUsers = new String[]{};
    
   // ToAddressesUsers=ToEmailAddress.split(',');
    AdvanceWorkflowAdmins__c awcs = AdvanceWorkflowAdmins__c.getvalues('admin');
    if(awcs == null)  return;
    ToAddressesUsers =awcs.Emailid__c.split(',');
    
    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            mail.setToAddresses(ToAddressesUsers);
            mail.setSubject(Subject);
            mail.setHtmlBody(MessageBodytoAdmin);            
    
            if(IsAttachment == true){
                Blob body=Blob.Valueof(AttachmentContent);
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setContentType('text/html');
                attach.setFileName('Error.log');
                attach.setInline(false);
                attach.Body = body; 
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
     }
     
    
    
 //Send email method
    public static void SendEmail(String AttachmentContent,Boolean IsAttachment,String Subject,String BodyContent,String ToEmailAddress)
    { 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            String[] ToAddresses = new String[]{};
            ToAddresses=ToEmailAddress.split(',');
            mail.setToAddresses(toAddresses);
            mail.setSubject(Subject);
            mail.setHtmlBody(BodyContent);            
    
            if(IsAttachment == true){
                Blob body=Blob.Valueof(AttachmentContent);
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setContentType('text/html');
                attach.setFileName('Error.log');
                attach.setInline(false);
                attach.Body = body; 
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
     }
     
      
     @future
     public static void createAndPostChatterFeed(String errDescription,String errStackTrace,integer lnNumber,String chatterGroupName){
        list<FeedItem> fItemList = new list<FeedItem>();
        String fullBody = '';
        fullBody = 'Error Description :'+errDescription + '\n';
        fullBody += 'Error StackTrace :'+errStackTrace + '\n';
        fullBody += 'Error Line number :'+lnNumber+'\n';
        if(chatterGroupName!=null && chatterGroupName!=''){
            CollaborationGroup chatterGroup = [ Select OwnerId, Name, Id, Description, CollaborationType 
                                                From CollaborationGroup c where c.Name =:chatterGroupName];
        
            FeedItem fItem = new FeedItem();
            fItem.Body = fullBody;
            fItem.Title = 'exception info';
            fItem.ParentId = chatterGroup.Id;
            try{
                insert fItem;
            }catch(Exception e){                        
                fItem.ParentId = UserInfo.getUserId();
                insert fItem;                       
            }
        }
     }
}
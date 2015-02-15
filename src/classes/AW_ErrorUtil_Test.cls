// 
// (c) 2012 Appirio, Inc.
//
//  AW_ErrorUtil_Test                                                     
//
// This class contains test methods for Testing AW_ErrorUtil functionality
//
// 01 Jan 2013     Peter Babalis          Original
//
@isTest(SeeAllData=true)
public class AW_ErrorUtil_Test {

    private static testMethod void AW_ErrorUtil_Test()
    {
        Test.startTest();
        AW_ErrorUtil errFrmUtl = new AW_ErrorUtil();
        try
        {
            String s;
            s.toLowerCase();
        }
        catch (Exception e)
        {
            AW_ErrorUtil.Handler(e, 'Sync', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.HandlerAsync('ErrDesc', 'ErrStack', 15,'Async', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', '');
            AW_ErrorUtil.HandlerAsyncCustom('test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.Handler(e, 'Async', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.Handler(e, 'CustomAsync', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.Handler(e, 'Custom', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.Handler(e, null, 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError', '');
            AW_ErrorUtil.Handler(e);
            AW_ErrorUtil.Handler(e, 'Async');
            AW_ErrorUtil.Handler(e, 'Async', 'Log');
            AW_ErrorUtil.Handler(e, 'Async', 'testemail', 'Log');
            AW_ErrorUtil.Handler(e, 'Async', 'testemail', 'Log', '1-ObjectId');
            AW_ErrorUtil.Handler(e, 'Sync', 'test', 'TestClass','RunTest', 'APEX Class', 'UI', 'CustomError');
            AW_ErrorUtil.logCustomMsg('Custom', 'testemail@netapp.com', 'callingFuncName', 'callingMethodName', 'APEXClass', 'LogEmailUI', 'My Custom Error');
            Profile oProf=[select id from profile where name='System Administrator'];
            User u2 = [SELECT Id FROM User WHERE profileid=:oProf.id and IsActive=:true limit 1];
            AW_ErrorUtil.Handler(e, 'ClassName','MethodName','Source', u2.Id );
         }
         
         try{//Improve the code coverage from DML Error Logging
                List <Account> lst_accts = new List<Account>();
                for(integer i = 0; i<5; i++){
                        Account a = new Account(Name='Missing Required Fields'+i);
                        lst_accts.add(a);
                }
                insert lst_accts;
            }
            catch(Exception e){//Handles DML Exception too.. use this handler
            AW_ErrorUtil.Handler(e, 'Sync','', 'ErrorUtil', 'TestErrorUtil', 'Apex', 'Log', '', '');
        }
        
        Test.stopTest();
    }
    
    private static testMethod void TestErrFrmwrkExceptionHandlerUtil()
     {
        Test.startTest();
        AW_ErrFrmwrkExceptionHandlerUtil errExcHdlUtil = new AW_ErrFrmwrkExceptionHandlerUtil();
        try
        {
            String s;
            s.toLowerCase();
        }
        catch (Exception eXpObj)
        {
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObj, 'test@appirio.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail','1-ObjectId');
            AW_ErrFrmwrkExceptionHandlerUtil.mAsyncHandleErrFrmwrk('ErrorDesc', 'ErrorStack', 10, 'test@netapp.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', '1-ObjectId');
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom('test@appirio.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', 'Custom Error', '1-ObjectId');
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObj, '', 'System.NullPointerException', 'Test', 'Test', 'APEX','LogEmail', '1-ObjectId'); 
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom('', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', 'Custom Error', '1-ObjectId');
            AW_ErrFrmwrkExceptionHandlerUtil.mAsyncHandleErrFrmwrk('ErrorDesc', 'ErrorStack', 10, '', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', '1-ObjectId');
            //function overloading test cases
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObj, 'test@appirio.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail');
            AW_ErrFrmwrkExceptionHandlerUtil.mAsyncHandleErrFrmwrk('ErrorDesc', 'ErrorStack', 10, 'test@netapp.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail');
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom('test@appirio.com', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', 'Custom Error');
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObj, '', 'System.NullPointerException', 'Test', 'Test', 'APEX','LogEmail'); 
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom('', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail', 'Custom Error');
            AW_ErrFrmwrkExceptionHandlerUtil.mAsyncHandleErrFrmwrk('ErrorDesc', 'ErrorStack', 10, '', 'System.NullPointerException', 'Test', 'Test', 'APEX', 'LogEmail');
        }
        
        try
        {
            Opportunity op = new Opportunity();
            insert op;
        }
        catch (Exception eXpObjDML)
        {
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObjDML, 'test@appirio.com', 'System.DmlException','Test', 'Test', 'APEX', 'LogEmail', '1-ObjectId');
            //Function Overloading
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(eXpObjDML, 'test@appirio.com', 'System.DmlException','Test', 'Test', 'APEX', 'LogEmail');
        }
    
        AW_ErrFrmwrkExceptionHandlerUtil.SendEmail('', false,'Error While Processing: test:test','test','test@netapp.com');
        AW_ErrFrmwrkExceptionHandlerUtil.SendEmail('Testing', true,'Error While Processing: test:test','test','test@netapp.com');
        
        Test.stopTest();
     }
     
     static testmethod void testChatterPostCreationOnError(){
         CollaborationGroup grp= new CollaborationGroup();
         grp.Name = 'Error Post';
         grp.CollaborationType  ='Public';                  
         insert grp;
         test.startTest();
            try
            {
                Opportunity op = new Opportunity();
                insert op;
            }
            catch (Exception e)
            {
                AW_ErrFrmwrkExceptionHandlerUtil.createAndPostChatterFeed(e.getMessage(), 'statkstarce', 7,'Error Post');
                
            }
        test.stopTest(); 
         
     }
     
     static testmethod void testSendEmailtoUser(){
         Test.startTest();
              AW_ErrFrmwrkExceptionHandlerUtil.SendEmailtoUser('test content',true,'Error','123','test@test.com');
         Test.stopTest();
     }
     
     static testmethod void testSendEmailtoAdmin(){
         AdvanceWorkflowAdmins__c admin= new AdvanceWorkflowAdmins__c(Name='admin',Emailid__c='test@test.com');
        // insert admin;
         Test.startTest();
         AW_ErrFrmwrkExceptionHandlerUtil.SendEmailtoAdmin('test content',true,'Error','testClass','testMethod',121,'---','CS','123','error');
         Test.stopTest();
     }
}
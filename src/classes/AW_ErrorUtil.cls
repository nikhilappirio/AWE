// 
// (c) 2012 Appirio, Inc.
//
//  AW_ErrorUtil Handler class for AW_ErrFrmwrkExceptionHandlerUtil. 
//
// 12 Jan 2013     Peter Babalis     Original
// Parameter Description:
//
// typename    Captures the Exception Type
// Possible values are :
// typename -  'Sync'
// typename -  'Aync'
// typename -  'Custom'
// typename -  'CustomAsync'
// typename -  'CustomAsync'
//
//
// StrLogEmailUIChtr:Concatenated String for error communication,
//  StrLogEmailUIChtr - Options :  Logging,
//                                 Email,
//                                 UI
//                                 message,
//                                 Chatter post
//
//  Example1:'EmailChtr'-to send email and post it to chatter.
//  Example1:'LogEmailUI'-Log it to the error object,email the error and show the message on the UI.
//
//  emailIdChtrGroup:EmailId or/and chatter group name.Email and chatter group name
//                   should be seperated by a colon(:)
//  Example1:'test@appirio.com:testChatterGroup.'
//
//  callingFuncName     :Class name from which the method is called.
//  callingMethodName   :Method name from the error handled is invoked.
//  CustomErrorMsg      :Custom error message to be shown instead of standard exception message.
//  
//  
 
public class AW_ErrorUtil {

//Constructor.
    public AW_ErrorUtil(){}
    
    
    public static void Handler(Exception e){
        Handler(e, 'Sync','', 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX Class', 'Log', '', '');
    }
    
    public static void Handler(String StrLogEmailUIChtr,String emailIdChtrGroup,Exception e){
        Handler(e, 'Sync',emailIdChtrGroup, 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX Class', 'StrLogEmailUIChtr', '', '');
    }
    
    public static void Handler(Exception e, String typename){
        Handler(e, typename,'', 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX Class', 'Log', '', '');
    }
    
    public static void Handler(Exception e, String ClassName, String MethodName, String Source, Id sojbId){
        Handler(e, '','', ClassName, MethodName, Source, 'Log', '', sojbId);
    }
    
    public static void Handler(Exception e, String typename, String StrLogEmailUIChtr){
        Handler(e, typename,'', 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX', StrLogEmailUIChtr, '', '');
    }
    
    public static void Handler(Exception e, String typename, String emailIdChtrGroup, String StrLogEmailUIChtr){
        Handler(e, typename,emailIdChtrGroup, 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX Class', StrLogEmailUIChtr, '', '');
    }
    
    public static void Handler(Exception e, String typename, String emailIdChtrGroup, String StrLogEmailUIChtr, String strObjectId){
        Handler(e, typename,emailIdChtrGroup, 'NoCallingFuncFound', 'NoCallingMethodFound', 'APEX Class', StrLogEmailUIChtr, '',strObjectId);
    }
    
    public static void Handler(Exception e, String typename, String emailIdChtrGroup, String callingFuncName, String callingMethodName, 
                                String StrSource, String StrLogEmailUIChtr, String CustomErrorMsg){
        Handler(e, typename, emailIdChtrGroup, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, CustomErrorMsg, '');
    }
    
    public static void Handler(Exception e, String typename, String emailIdChtrGroup, String callingFuncName, String callingMethodName, 
                                String StrSource, String StrLogEmailUIChtr, String CustomErrorMsg, String strObjectId){
        string errMsg;
        integer lnNumber;
        String errTypename;
        String errDescription;
        
        if (typename == 'Custom' || typename == 'CustomAsync'){
            errMsg = CustomErrorMsg;
            lnNumber = 0;
            errTypename = 'Custom Error Handling';
        }
        else{
            errMsg = e.getMessage();
            lnNumber = e.getLineNumber();
            errTypename = e.getTypeName();
        } 
        if (typename == 'Sync'){
                // Call Error Exception Handler                
                AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrk(e, emailIdChtrGroup, errTypename, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, strObjectId);   
        }
        else if(typename == 'Async'){
            errDescription = e.getCause() + '-' + e.getMessage() + '-' + e.getLineNumber();
            HandlerAsync(errDescription , e.getStackTraceString(), lnNumber,e.getTypeName(), emailIdChtrGroup, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, strObjectId);
        }
        else if (typename == 'Custom'){
            //Call Cutsom Error Handler
            AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom(emailIdChtrGroup, errTypename, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, CustomErrorMsg, strObjectId); 
        }
        else if (typename == 'CustomAsync'){
            HandlerAsyncCustom(emailIdChtrGroup, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, CustomErrorMsg, strObjectId);
        }
        
        if (StrLogEmailUIChtr.contains('UI') == true){
            if (typename != null && typename != 'Custom' ){
               ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error Type: '+errTypename+' - ErrorMesage: '+errMsg +' - Line Number: '+lnNumber);
               ApexPages.addMessage(myMsg);
            }
            else if (typename == 'Custom'){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,CustomErrorMsg);
                ApexPages.addMessage(myMsg);
            }
            else{
                String errMsgNotFound = 'Error Exception Type is not defined. So, error can not be handled.';
                ApexPages.Message myMsgExcp = new ApexPages.Message(ApexPages.Severity.ERROR,errMsgNotFound);
                ApexPages.addMessage(myMsgExcp);
            }
        }
    }

    public static void logCustomMsg(String typename, String emailIdChtrGroup, String callingFuncName, String callingMethodName,
                                     String StrSource, String StrLogEmailUIChtr, String CustomErrorMsg){
        //Call Cutsom Error Handler.
        AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom(emailIdChtrGroup, typename, callingFuncName, callingMethodName,
                                                                StrSource, StrLogEmailUIChtr, CustomErrorMsg); 
    }
    
    //@future
    public static void HandlerAsync(String errDesc, String errStack, Integer lnNumber, String typeName, String emailIdChtrGroup,String callingFuncName,
                                     String callingMethodName, String StrSource, String StrLogEmailUIChtr,String strObjectId){
                                          
        AW_ErrFrmwrkExceptionHandlerUtil.mAsyncHandleErrFrmwrk(errDesc, errStack, lnNumber, emailIdChtrGroup, typeName, callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, strObjectId);
    }
    
    //@future
    public static void HandlerAsyncCustom(string emailIdChtrGroup, String callingFuncName, String callingMethodName, String StrSource, String StrLogEmailUIChtr,
                                         String CustomErrorMsg, String strObjectId){
                                              
        AW_ErrFrmwrkExceptionHandlerUtil.mHandleErrFrmwrkCustom(emailIdChtrGroup, 'CustomAsync', callingFuncName, callingMethodName, StrSource, StrLogEmailUIChtr, CustomErrorMsg, strObjectId);       
    }

}
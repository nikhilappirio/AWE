public class AW_AdvanceWorkflowHTTPHandler {
     public AW_AdvanceWorkflowHTTPHandler(){
       
       }
        @future(callout=true)
       public static void setHTTPCallout(String actionId,String recordId){
       	  //get the input parameter map:-
       	  String mode='';
       	  RuleAction__c action= [Select Id,Reference_Id__c,Field_Type__c,Field_Name__c,Lookup_Field_Name__c,Type__c,Value__c,Long_Value__c,Related_Object__c,Notify_user__c,Email_Template__c,User_Owner_Id__c,CrossObjectField__c,Bulk_api__c,Lookup_Object__c,Lookup_field_api_name__c,lookup_where_fields__c,Apex_job_Class__c,Input_Parameters__c,output_parameters__c,Endpoint_URL__c,Callout_Method__c,Callout_timeout__c,Rule__c,Rule__r.Object__c FROM RuleAction__c WHERE Id=:actionId];
       	  
       	  Set<Id> evaluateActions = new Set<Id>();
       	  evaluateActions.add(actionId);
       	  Set<Id> ruleIds = new Set<Id>();
       	  ruleIds.add(action.Rule__c);
       	  Set<Id> recordIds = new Set<Id>();
       	  recordIds.add(recordId);
       	  
       	  AW_AdvanceWorkflowExecutionEngine.bulkOperation=true;     
          AW_AdvanceWorkflowExecutionEngine.bulkactionIds=evaluateActions;   
          AW_AdvanceWorkflowExecutionEngine.evaluateRules(ruleIds,recordIds,action.rule__r.object__c,mode );          
         
       }
       
      public  Map<String,STring>  doHTTPCallout(RuleAction__c action,Map<String,String> input){
         Map<String,STring> output = new Map<String,STring>();
                
             Http httpProtocol = new Http();
              // Create HTTP request to send.
             HttpRequest request = new HttpRequest();
            
             request.setEndPoint(action.endpoint_url__c);
             // Set the HTTP verb to GET/POST Based on callout method
             request.setMethod(action.callout_method__c);
             
             if(action.Callout_Timeout__c!=null) 
                request.setTimeout(Integer.valueof(action.Callout_Timeout__c));

              //SET THE Session ID for authorization
		      request.setHeader('Authorization', '11111');
              
              request.setBody(JSON.serialize(input));
             // Send the HTTP request and get the response.
             // The response is in JSON format.
             
           try{    
             
             HttpResponse response = new HttpResponse();
             if(Test.isRunningTest()){
             	 // Create a fake response
		        
		        response.setHeader('Content-Type', 'application/json');
		        response.setBody('{"foo":"bar"}');
		        response.setStatusCode(200);
		     
             }else
             	response = httpProtocol.send(request);
             
             if(response.getStatusCode() <>200){
                httpErrorLog(action,response);
                return output;
             }
             
             System.debug(response.getBody());
               
               
            // Parse JSON response to get all the totalPrice field values.
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                    // Get the value.
                    String fieldName = parser.getText();
                    parser.nextToken();
                    String value =parser.getText();
                    output.put(fieldname,value);
                  
                }
            } 
         }//end try
         catch(System.CalloutException e) {
            //log the error :-
             AW_AdvanceWorkflowExecutionHelper.handleError(e); 
         }
        return output;
     }
  public void httpErrorLog(RuleAction__c action,Httpresponse response){
     	//error:-
                Error_Log__c e = new Error_Log__c();
                e.Error_Rule_Name__c =[Select Name FROM Rule__c WHERE Id=:action.Rule__c].Name;
                e.Object_Name__c  = action.Related_Object__c;
                e.Error_Description__c  = response.getStatusCode()+':'+response.getStatus();
                e.Error_Description__c  = e.Error_Description__c + action.endpoint_url__c;
                insert e;
                
                //send email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                String emailAddr = [select Email from User where Id = :action.Notified_User__c].Email; 
                String[] toAddresses = new String[] {emailAddr};
                mail.setToAddresses(toAddresses);
			
                mail.setSubject('AWF Failed: '+e.Error_Rule_Name__c+' - Apex Callout : ');
                mail.setPlainTextBody(e.Error_Description__c);
                
                String body = 'Erro From : '+action.endpoint_url__c;
                body+='<br/> Input :-'+action.input_parameters__c;
                body+='<br/> Status code :-'+response.getStatusCode();
                body+='<br/> Status :-'+response.getStatus();
                mail.setHtmlBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
     }
     
}
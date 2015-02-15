//
//  AW_AdvanceWorkflowHTTPHandler_Test
//
// This class contains test methods for AW_AdvanceWorkflowHTTPHandler class
//
// 16 Apr 2014    Hitesh Pareek     Original

@isTest
private class AW_AdvanceWorkflowHTTPHandler_Test {

    static testMethod void testSetHTTPCallout() {
        Rule__c Rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
        
        RuleAction__c action = new RuleAction__c(Rule__c=rule.id,Related_object__c='Account',
                                                 Field_name__c='Type',Type__c='Update Field',Value__c='Prospect');
    
        insert action;
        
        Account account = new Account(Name='Test Contact',AnnualRevenue=2000.0,Industry='Agriculture');
        insert account;
        
        Test.startTest();        
        AW_AdvanceWorkflowHTTPHandler.setHTTPCallout(action.id, account.id);        
        Test.stopTest();
        
    }
    
    static testMethod void testDoHTTPCallout(){
        Rule__c Rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
        
        RuleAction__c action = new RuleAction__c(Rule__c = Rule.id, Related_object__c = 'Account', Type__c = 'Apex Callout-HTTP',
                                                 Endpoint_url__c = 'www.test.test', Callout_method__c = 'GET', Callout_Timeout__c = '15000');
    
        insert action;	
    	
    	Test.startTest();
    	AW_AdvanceWorkflowHTTPHandler httpHandler = new AW_AdvanceWorkflowHTTPHandler();
    	Map<String,String> input = new Map<String,String>{'testKey'=>'testValue'};
    	Map<String,STring> output = httpHandler.doHTTPCallout(action, input);
    	    	
    	system.assertEquals(output.get('foo'),'bar');
    	Test.stopTest();
    }
    
    static testMethod void testHTTPErrorLog(){
    	Rule__c Rule = AW_AdvanceWorkflowExecutionEngine_Test.setupRules();
        
        RuleAction__c action = new RuleAction__c(Rule__c = Rule.id, Related_object__c = 'Account', Type__c = 'Apex Callout-HTTP',
                                                 Endpoint_url__c = 'www.test.test', Callout_method__c = 'GET', Callout_Timeout__c = '15000',
                                                 Notified_User__c = UserInfo.getUserId());
    
        insert action;
        
        Test.startTest();
        
        HttpResponse response = new HttpResponse();
        		response.setHeader('Content-Type', 'application/json');
		        response.setBody('{"foo":"bar"}');
		        response.setStatusCode(200);
        AW_AdvanceWorkflowHTTPHandler httpHandler = new AW_AdvanceWorkflowHTTPHandler();
        httpHandler.httpErrorLog(action, response);
        
        string ruleName = [Select Name FROM Rule__c WHERE Id=:action.Rule__c].Name;
        List<Error_Log__c> errorLog = [select Name,Error_Rule_Name__c from Error_Log__c  where Error_Rule_Name__c =:ruleName];
        system.assertNotEquals(errorLog.size(), 0);
        Test.stopTest();
    
    }
}
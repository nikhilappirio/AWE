// 
// (c) 2012 Appirio, Inc.
// AW_FormulaExpressionHelper_Test                                                     
// This test class tests AW_FormulaExpressionHelper functionality   
//
// 24 March 2014     Peter Babalis       Original
//  
//  
//
@isTest
private class AW_FormulaExpressionHelper_Test {

    static testMethod void testFetchFieldFromString() {
        
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a1;
        
        Map<String,Set<String>> validRelationShips = new Map<String,Set<String>>();
        Set<String> setFields = new Set<String>();
        setFields.add('Contact');
        validRelationShips.put('contact', setFields);
        
        Test.startTest();
        String field = AW_FormulaExpressionHelper.fetchFieldFromString(a1, 'left({!Name},4)', validRelationShips);
        system.assertEquals(field, 'name', 'field value should be name');
        
        field = AW_FormulaExpressionHelper.fetchFieldFromString(a1, 'right({!Name},4)', validRelationShips);
        system.assertEquals(field, 'name', 'field value should be name');
        
        field = AW_FormulaExpressionHelper.fetchFieldFromString(a1, 'mid({!Name},4)', validRelationShips);
        system.assertEquals(field, 'name', 'field value should be name');
        
        field = AW_FormulaExpressionHelper.fetchFieldFromString(a1, 'Contact.FirstName', validRelationShips);
        system.assertEquals(field, 'contact.firstname', 'field value should be contact.firstname');
        Test.stopTest();
        
    }
    
    static testMethod void testResolveCriteriaFormulaExpressions(){
    	
    	RuleCriteria__c ruleCriteria = new RuleCriteria__c(related_object__c='Account',
                                                           Matching_Type__c='Equal', Matching_Value__c='now()', field_name__c='createddate',field_API_Name__c='createddate',Field_Type__c='date');
                                                           
        RuleCriteria__c rule_Criteria = AW_FormulaExpressionHelper.resolveCriteriaFormulaExpressions(ruleCriteria);     
        
        Test.startTest();
        ruleCriteria.Matching_Type__c = 'Between';
        ruleCriteria.minimum_value__c = 'now()';
        rule_Criteria = AW_FormulaExpressionHelper.resolveCriteriaFormulaExpressions(ruleCriteria);
        
        ruleCriteria.Matching_Type__c = 'Between';
        ruleCriteria.maximum_value__c = 'now()';
        rule_Criteria = AW_FormulaExpressionHelper.resolveCriteriaFormulaExpressions(ruleCriteria);     
        
        AW_FormulaExpressionHelper.resolveDateTimeFunctions('+7d/7m/7y 1h:m2m:40s');
        Test.stopTest();
                                                 
    }
    
    static testMethod void testFetchCrossformulaValue(){
    	
    	Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='Name',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a1;
        
        Account account = new Account(Name = 'testaccount');
        Test.startTest();
        String formulaExp = AW_FormulaExpressionHelper.fetchCrossformulaValue(a1, Account.Name, account);
        system.debug('====formulaExp===' + formulaExp);
        Test.stopTest();
    }
    
    static testMethod void testDoMerge(){
    	Rule__c rule = new Rule__c(Name = 'Test Contact',Object__c = 'Contact', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Contact',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='FirstName',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a1;
        
        Account account = new Account(Name = 'testaccount');
        insert account;
        
        Contact contact = new Contact(FirstName = 'firstName', LastName='lastName', AccountId = account.id);
        insert contact;
        
        contact = [SELECT FirstName, LastName, Account.Name FROM Contact Where Id =: contact.id limit 1];
        Test.startTest();
        String mergeVal = AW_FormulaExpressionHelper.doMerge(a1, '{!Account.Name}', contact); 
        system.assertEquals(mergeVal, account.Name, 'merge value should be the name of the account');
        Test.stopTest();
    }
    
    static testMethod void testGetCrossFormulaValue(){
    	
    	Account account = new Account(Name = 'testaccount');
        insert account;
        
        Contact contact = new Contact(FirstName = 'firstName', LastName='lastName', AccountId = account.id);
        insert contact;
        
        contact = [SELECT FirstName, LastName, Account.Name FROM Contact Where Id =: contact.id limit 1];
        
        Test.startTest();
        String formulaValue = AW_FormulaExpressionHelper.getCrossFormulaValue(contact, 'Account.Name'); 
        system.assertEquals(formulaValue, account.Name, 'formula value should be the name of the account');
        Test.stopTest();
        
    }
    
    static testMethod void testResolveValueFetched(){
     	
     	Rule__c rule = new Rule__c(Name = 'Test Contact',Object__c = 'Contact', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Contact',
                                                           Matching_Type__c='Equals', Matching_Value__c='Test', field_name__c='Name',field_API_Name__c='FirstName',Field_Type__c='Text');
        insert ruleCriteria ;
        RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
        insert a1;
        
        Account account = new Account(Name = 'testaccount');
        insert account;
        
        Contact contactObj = new Contact(FirstName = 'TestfirstName', LastName='lastName', AccountId = account.id);
        insert contactObj;
        
        contactObj = [SELECT FirstName, LastName, Account.Name FROM Contact Where Id =: contactObj.id limit 1];
        
        Map<String,Map<String,Schema.SObjectField>> fieldMap = new Map<String,Map<String,Schema.SObjectField>>(); 
        Map<String,Schema.SObjectField> fields = new Map<String,Schema.SObjectField>();
        fields.put('FirstName', Contact.FirstName.getDescribe().getSObjectField());
        fieldMap.put('contact',fields);
        
        Test.startTest();
        
        String value = AW_FormulaExpressionHelper.resolveValueFetched(a1,'left({!Account.Name},15)',contactObj, fieldMap) ;
        system.assertEquals(value, account.Name, 'formula value should be the name of the account');
        
        value = AW_FormulaExpressionHelper.resolveValueFetched(a1,'right({!Account.Name},15)',contactObj, fieldMap) ;
        system.assertEquals(value, account.Name, 'formula value should be the name of the account');
        
        value = AW_FormulaExpressionHelper.resolveValueFetched(a1,'mid({!Account.Name},0,15)',contactObj, fieldMap) ;
        system.assertEquals(value, account.Name, 'formula value should be the name of the account');
        
        value = AW_FormulaExpressionHelper.resolveValueFetched(a1,'FirstName',contactObj, fieldMap) ;
        system.assertEquals(value, contactObj.FirstName, 'value should be the FirstName of contact');
        
        value = AW_FormulaExpressionHelper.resolveValueFetched(a1,'today()',contactObj, fieldMap) ;
        
        Test.stopTest();
        
        
     }
}
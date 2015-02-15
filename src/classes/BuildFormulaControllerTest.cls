@isTest
private class BuildFormulaControllerTest {

	/*************************************************************************************************************
	* @author       AutomaTom            
	* @date         31 December 2013 
	* @description  Positive Test - sObject and 1st tier relationship sObjects
	**************************************************************************************************************/
    static testMethod void positiveTest() {
        //Start Tests
        Test.startTest();
        //Instantiate the Controller
        BuildFormulaController controller = new BuildFormulaController();
        //Retrieve Select Options for Opportunity
        List<BuildFormulaController.SelectOption> selectOptions = BuildFormulaController.getSelectOptions('Opportunity');
        //Check that a list was returned
        System.assert(selectOptions.size() > 0);
        //Run some tests on each Select Option
        for (BuildFormulaController.SelectOption selectOption : selectOptions) {
        	//Check that a Label and Value have been set for every Select Option
        	System.assertNotEquals(0, selectOption.Label.length());
        	System.assertNotEquals(0, selectOption.Value.length());
        	//Where a greater than Symbol is encountered in the label, this denotes a 
        	//relationship
        	if (selectOption.Label.indexOf('>') > 0) {
        		//Attempt to retrieve Child Select Options for each Account Select Option
        		List<BuildFormulaController.SelectOption> childSelectOptions = 
        			BuildFormulaController.getChildSelectOptions(selectOption.Value);
        		//Check that Child Select Options were returned for all reference fields
        		System.assert(childSelectOptions.size() > 0);
		        //Run some tests on each Child Select Option
		        for (BuildFormulaController.SelectOption childSelectOption : childSelectOptions) {
		        	//Check that a Label and Value have been set for every Child Select Option
		        	System.assertNotEquals(0, childSelectOption.Label.length());
		        	System.assertNotEquals(0, childSelectOption.Value.length());
		        }
        	} 
        }
        //Stop Tests
        Test.stopTest();
    }
    
	/*************************************************************************************************************
	* @author       AutomaTom            
	* @date         31 December 2013 
	* @description  Negative Test - sObject does not exist
	**************************************************************************************************************/
    static testMethod void negativeTest1() {
        //Start Tests
        Test.startTest();
        //Retrieve Select Options for a pretend object (this will throw an exception)
        try {
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getSelectOptions('PretendObject__c');
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			Pattern exceptionPattern = pattern.compile('(.*)The sobject provided does not exist(.*)'); 
			Matcher exceptionMatcher = exceptionPattern.matcher(e.getMessage());
        	System.assert(exceptionMatcher.matches());
        } 
        //Stop Tests
        Test.stopTest();
    }
    
	/*************************************************************************************************************
	* @author       AutomaTom            
	* @date         31 December 2013 
	* @description  Negative Test - Invalid sObjectRelationship Format
	**************************************************************************************************************/
    static testMethod void negativeTest2() {
        
        //Start Tests
        Test.startTest();
        //Set sObject Relationship (invalid format)
        String sObjectRelationship = '.CreatedBy';
        //Retrieve Select Options for the invalid format sObjectRelationship (this will throw an exception)
        try {       	
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getChildSelectOptions(sObjectRelationship);
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			System.assertEquals(BuildFormulaController.INVALID_RELATIONSHIP_SYNTAX.replace('{!sObjectRelationship}', 
				sObjectRelationship), e.getMessage());
        } 
        //Set sObject Relationship (invalid format)
        sObjectRelationship = 'Account.';
        //Retrieve Select Options for the invalid format sObjectRelationship (this will throw an exception)
        try {       	
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getChildSelectOptions(sObjectRelationship);
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			System.assertEquals(BuildFormulaController.INVALID_RELATIONSHIP_SYNTAX.replace('{!sObjectRelationship}', 
				sObjectRelationship), e.getMessage());
        } 
        //Set sObject Relationship (invalid format)
        sObjectRelationship = 'Account>CreatedBy';
        //Retrieve Select Options for the invalid format sObjectRelationship (this will throw an exception)
        try {       	
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getChildSelectOptions(sObjectRelationship);
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			System.assertEquals(BuildFormulaController.INVALID_RELATIONSHIP_SYNTAX.replace('{!sObjectRelationship}', 
				sObjectRelationship), e.getMessage());
        } 
        //Stop Tests
        Test.stopTest();
    }
    
	/*************************************************************************************************************
	* @author       AutomaTom            
	* @date         31 December 2013 
	* @description  Negative Test - sObject Relationship does not exist
	**************************************************************************************************************/
    static testMethod void negativeTest3() {
        
        //Start Tests
        Test.startTest();
        //Set sObject Relationship (not a Relationship)
        String sObjectRelationship = 'Account.Type';
        //Retrieve Select Options for the invalid sObjectRelationship (this will throw an exception)
        try {       	
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getChildSelectOptions(sObjectRelationship);
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			System.assertEquals(BuildFormulaController.SOBJECT_RELATIONSHIP_DOES_NOT_EXIST_EXCEPTION.replace
				('{!sObjectRelationship}', sObjectRelationship), e.getMessage());
        } 
        //Stop Tests
        Test.stopTest();
    }
    
	/*************************************************************************************************************
	* @author       AutomaTom            
	* @date         31 December 2013 
	* @description  Negative Test - sObject Relationship is for multi-object
	**************************************************************************************************************/
    static testMethod void negativeTest4() {
        
        //Start Tests
        Test.startTest();
        //Set sObject Relationship (multi object relationship)
        String sObjectRelationship = 'Task.Who';
        //Retrieve Select Options for the invalid sObjectRelationship (this will throw an exception)
        try {       	
        	List<BuildFormulaController.SelectOption> selectOptions = 
        		BuildFormulaController.getChildSelectOptions(sObjectRelationship);
        	//Assertion fails if exception was not thrown
        	System.assert(false);
        } catch (Exception e) {
        	//Check that the expected exception was returned
			System.assertEquals(BuildFormulaController.INVALID_MULTI_OBJECT_RELATIONSHIP_EXCEPTION.replace
				('{!sObjectRelationship}', sObjectRelationship), e.getMessage());
        } 
        //Stop Tests
        Test.stopTest();
    }
}
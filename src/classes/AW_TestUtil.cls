@isTest
public with sharing class AW_TestUtil {
	
	/*
	Method for create test account.
	Parameters
	@ accountName - name of the account.
	@ isInsert - set true if account need to be insert. 
	*/
	public static Account createAccount(String accountName, Boolean isInsert){
		
		Account account = new Account(
			Name = accountName
		);
		
		if(isInsert){
			try{ insert account; } catch(Exception e) { System.assert( false, 'Failed while inserting test Account '+ e.getMessage());}
		}
		return account;
	}
	
	
	/*
	Method for create test Rule.
	Parameters
	@ ruleName - name of the Rule.
	@ objectName - Api Name of the object
	@ status - rule status
	@ evaluationRule - evaluation criteira
	@ description - rule description
	@ isInsert - set true if Rule need to be insert. 
	*/
	public static Rule__c createRule(String ruleName, String objectName, String status, String evaluationRule, String description, Boolean isInsert){
		
		Rule__c rule = new Rule__c(
			Name = ruleName,
			Object__c = objectName, 
			Status__c= status,
			Evaluation_Rule__c= evaluationRule,
			Description__c= description
		);
		
		if(isInsert){
			try{ insert rule; } catch(Exception e) { System.assert( false, 'Failed while inserting test Rule '+ e.getMessage());}
		}
		return rule;
	}
	
	
	/*
	Method for create test RuleCriteria.
	Parameters
	@ rule - Rule Object.
	@ relatedObject - Api Name of the related object
	@ matchingType - Filter criteria for matching like "Equal"
	@ matchingValue - matching value that needs to match with the matching type
	@ fieldName - label of the field
	@ fieldAPIname - API name of the field
	@ fieldType - data type of the field
	@ isInsert - set true if RuleCriteria need to be insert. 
	*/
	public static RuleCriteria__c createRuleCriteria(Rule__c rule, String relatedObject, String matchingType, String matchingValue, String fieldName, String fieldAPIname, String fieldType, Boolean isInsert){
		
		RuleCriteria__c ruleCriteria = new RuleCriteria__c(
			rule__c=rule.id,
			related_object__c= relatedObject,
			Matching_Type__c= matchingType, 
			Matching_Value__c= matchingValue, 
			field_name__c= fieldName,
			field_API_Name__c= fieldAPIname,
			Field_Type__c= fieldType
		);
		
		if(isInsert){
			try{ insert ruleCriteria; } catch(Exception e) { System.assert( false, 'Failed while inserting test RuleCriteria '+ e.getMessage());}
		}
		return ruleCriteria;
	}
	                        
	/*
	Method for create test Workflow.
	Parameters
	@ wfName - Workflow Name .
	@ objectName - Api Name of the object
	@ Enabled - Is Workflow Enabled ( True/false )
	@ description - WF description
	@ isInsert - set true if RuleAction need to be insert. 
	*/
	public static Advance_Workflow__c createWorkflow( String wfName, String objectName, Boolean Enabled,  String description, Boolean isInsert){
	        Advance_Workflow__c wf = new Advance_Workflow__c(
			Name = wfName,
			Object__c = objectName, 
			Description__c= description,
			Enabled__c=enabled
			 
		);
		
		if(isInsert){
			try{ insert wf; } catch(Exception e) { System.assert( false, 'Failed while inserting test Workflow '+ e.getMessage());}
		}
		return wf;            
	
	}
	/*
	Method for create test RuleAction.
	Parameters
	@ rule - Rule Object.
	@ relatedObject - Api Name of the related object
	@ bulkApi - Is using bulk API ( True/false )
	@ fieldName - field Name 
	@ type - Action type 
	@ value - value for action
	@ isInsert - set true if RuleAction need to be insert. 
	*/
	public static RuleAction__c createRuleAction(Rule__c rule, String relatedObject, Boolean bulkApi, String fieldName, String type, String value, Boolean isInsert){
		
		RuleAction__c ruleAction = new RuleAction__c(
			rule__c = rule.id,
			related_object__c = relatedObject,
			Bulk_API__c = bulkApi,
            field_name__c = fieldName,
            Type__c= type,
            Value__c= value
        );
		
		if(isInsert){
			try{ insert ruleAction; } catch(Exception e) { System.assert( false, 'Failed while inserting test Rule Action '+ e.getMessage());}
		}
		return ruleAction;
	}
	
	/*
	Method for create test Values_for_Action_Insert_Record
	Parameters
	@ actionId = Id of the rule action on which action will data will be inserted.
	@ infoName - Name
	@ Value - Value  
	@ isInsert - set true if Values_for_Action_Insert_Record need to be insert. 
	*/
	public static Values_for_Action_Insert_Record__c createInsertValues( String actionId, String infoName, String Value,Boolean isInsert){
	        Values_for_Action_Insert_Record__c infos = new Values_for_Action_Insert_Record__c(
			Rule_Action__c=actionId,
			Name = infoName,
		 	Value__c=Value
		 	);
      	
		if(isInsert){
			try{ insert infos; } catch(Exception e) { System.assert( false, 'Failed while inserting test Infos '+ e.getMessage());}
		}
		return infos;            
	 }
	
	/*
	Method for create test Object Action Execution.
	Parameters
	@ recordId - object id on which action will execute.
	@ status - status
	@ type - Action type 
	@ value - value for action
	@ actionId = Id of the rule action
	@ isInsert - set true if Object_Action_Execution need to be insert. 
	*/
	public static Object_Action_Execution__c createObjectActionExecution(String recordId, String status, String type, String value, String actionId, Boolean isInsert){
		
		Object_Action_Execution__c objectActionExecution = new  Object_Action_Execution__c(
	        Record_Id__c = recordId,
	        Status__c = status,
	        Type__c = type,
	        Value__c = value,
	        //Value1__c = value,
	        Action__c = actionId
        );
		
		if(isInsert){
			try{ insert objectActionExecution; } catch(Exception e) { System.assert( false, 'Failed while inserting test Object Action Execution '+ e.getMessage());}
		}
		return objectActionExecution;
	}
	
	/*
	Method for create test User.
	Parameters
	@ userName - user name.
	@ email - email for the user
	@ firstName - first name of user 
	@ lastName - last name of user
	@ alias = alias for user
	@ profileId = profile id for user
	@ isInsert - set true if User need to be insert. 
	*/
	public static User createUser(String userName, String email, String firstName, String lastName, String alias, String profileId, Boolean isInsert){
		
		User user = new User(
			username = userName,
			email = email,
			firstname = firstName,
			lastname = lastName,
			alias = alias, 
			profileid = profileId,
			emailencodingkey='UTF-8', 
            languagelocalekey='en_US', 
            localesidkey='en_US', 
            timezonesidkey='America/Los_Angeles' 
        );
		
		if(isInsert){
			try{ insert user; } catch(Exception e) { System.assert( false, 'Failed while inserting test user '+ e.getMessage());}
		}
		return user;
	}
	
	
	/*
	Method for create test OwnerPrioritization.
	Parameters
	@ assigned - Assigned value in number.
	@ percent - percent value in number.
	@ priority - priority value in number.
	@ weight - weight value in number.
	@ userQueueGroupId = User Id
	@ userQueueGroup - Group Name
	@ ruleActionId - RuleAction Id
	@ isInsert - set true if OwnerPrioritization need to be insert. 
	*/
	public static OwnerPrioritization__c createOwnerPrioritization(Decimal assigned, Decimal percent, Decimal priority, Decimal weight, String userQueueGroupId, String userQueueGroup, String ruleActionId, Boolean isInsert){
		
		OwnerPrioritization__c ownerPrioritization = new OwnerPrioritization__c(
			Assigned__c = assigned,
			Percent__c = percent,
			Priority__c = priority,
			Weight__c = weight,
			User_Queue_Group_Id__c = userQueueGroupId, 
			User_Queue_Group__c = userQueueGroup,
			RuleAction__c = ruleActionId
		);
		
		if(isInsert){
			try{ insert ownerPrioritization; } catch(Exception e) { System.assert( false, 'Failed while inserting test OwnerPrioritization '+ e.getMessage());}
		}
		return ownerPrioritization;
	}
	
	
	
	
	
	
}
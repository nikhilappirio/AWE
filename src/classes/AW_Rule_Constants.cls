/*
  * AW Rule Constants
*/
public class AW_Rule_Constants{
	
	public static final String ACTION_POSTFIX ='/a>';
	public static final String ACTION_PREFIX = '<a'; 
	public static final String ACTION_TYPE_SEPARATOR = ':';
	public static final String EQUAL_SEPARATOR = '=';
	public static final String FIELD_SEPARATOR ='~';
	public static final String AT_UPDATE = 'Update';
	public static final String CROSSOBJECT = 'CrossObject';
	public static final String CROSSOBJECTFIELD = 'CrossObjectField';
	public static final String LOOKUPOBJECTFIELD ='LookupObjectField';
	public static final String LOOKUPOBJECT ='Lookup Object';
	public static final String LOOKUPFIELD = 'LookupFromFieldName';  
	public static final String LOOKUPVALUE = 'LookupValue';
	public static final String CONDITION = 'Condition';
	public static final String OWNERPRIORITIZATIONFIELD = 'OwnerPrioritizationField'; 
	public static final String OWNERPRIORITIZATION = 'OwnerPrioritization';
	public static final String OP_SEPARATOR = ',';
	public static final String CROSSFORMULA = 'CrossFormula';
	public static final String USER_KEYPREFIX = '005';
	public static final String GROUP_KEYPREFIX = '00G';
	public static final String BETWEEN = 'Between';
	public static final String BETWEEN_OPERATOR = 'TO';
	public static final String CSV_RT = 'RecordTypeName';
	public static final String CRITERIA_RT =' RecordTypeId';
	public static final String GLOBAL_VARIABLE = 'GlobalVariable-';
	public static final String GLOBAL_VARIABLE_CSV = 'GlobalVariable$';
	public static final String LINE_SPLITOR = '~~';
	public static final String CARRIAGE_SPLITOR = '^^';
	
    public static Map<String , String> evalutionForExportMap = new Map<String , String>{'Record is created' => 'Created' ,
                                                                'Record is created or edited' => 'Create, Edit' ,
                                                                'Record is created or edited and did not previously meet the rule criteria' =>'Not Meet Criteria' , 
                                                                'Execute Rule and Exit' => 'Exit' , 
                                                                'Execute Rule and Continue to Next Rule' => 'Continue'}; 
                                                                
                                                                
    public static Map<String , String> evalutionForImportMap = new Map<String , String>{'Created' => 'Record is Created' ,
                                                                'Create, Edit' => 'Record is Created or Edited' ,
                                                                'Create,Edit' => 'Record is Created or Edited' ,
                                                                'Not Meet Criteria' =>'Record is created or edited and did not previously meet the rule criteria' ,
                                                                'Exit' => 'Execute Rule and Exit' , 
                                                                'Continue' => 'Execute Rule and Continue to Next Rule'}; 
                                                                /*if(rule.Execution_Behavior__c=='Execute Rule and Exit'){
				objRulesWrapper.Execution='Exit';
			}
			else if(rule.Execution_Behavior__c=='Execute Rule and Continue to Next Rule'){
				objRulesWrapper.Execution='Continue';
			}      */
	public static Map<String, String> executionBehaviourForExportMap = new Map<String, String>{'Execute Rule and Exit' => 'Exit',
																		'Execute Rule and Continue to Next Rule' => 'Continue'};
																		
	public static Map<String, String> executionBehaviourForImportMap = new Map<String, String>{'Exit' => 'Execute Rule and Exit',
																		'Continue' => 'Execute Rule and Continue to Next Rule'};
																		
	public static Map<String, String> actionTypeForImportMap = new Map<String, String>{'Update' => 'Update Field' , 
																					'SendEmail' => 'Send Email',
																					'ApexJob' => 'Execute an Apex Job',
																					'ChatterNotification' => 'Chatter Notification',
																					'Upsert' => 'Upsert Related Object',
																					'UpsertUnrelated' => 'Upsert Unrelated Object',
																					'Insert' => 'Insert Related Object',
																					'InsertUnrelated' => 'Insert Unrelated Object'};
   public static Map<String, String> actionTypeForExportMap = new Map<String, String>{'Update Field' => 'Update' , 
																					'Send Email' => 'SendEmail',
																					'Execute an Apex Job' => 'ApexJob',
																					'Chatter Notification' => 'ChatterNotification',
																					'Upsert Related Object' => 'Upsert',
																					'Upsert Unrelated Object' => 'UpsertUnrelated',
																					'Insert Related Object' => 'Insert',
																					'Insert Unrelated Object' => 'InsertUnrelated'};  
																						
   public static Map<String, String> matchingTypeMap = new Map<String, String>{	'=' => 'EQUALS' , '!=' => 'Not Equal To',
									                  'LIKE%' => 'Contains' ,  'NOTLIKE%%' => 'Does Not Contain',
									                  '>' => 'GREATER THAN', '>=' => 'GREATER OR EQUAL',
									                  '<' => 'Less Than' ,  '<=' => 'Less Or Equal',  
									                  /*'IN' =>  'IN' ,'NOTIN' => 'Not In',*/
									                  'INCLUDES' =>  'Includes' ,'EXCLUDES' => 'Excludes',
									                 /* 'INCLUDE' =>  'Includes' ,'EXCLUDE' => 'Excludes', */
									                  'STARTSWITH'=>' Starts With ',
									                  'ENDSWITH'=>' Ends With',
									                  'BETWEEN'=>' Between ',
									                  'NOTBETWEEN'=>' Not Between ',
									                  'LIKE'=>' Regular Expression ',
									                  'ISCHANGED' => 'IsChanged',
									                  'CHANGEDFROMTO' => 'ChangedFromTo',
									                  'NOTLIKE' => 'Does Not Start With',
									                  'NOTLIKE%' => 'Does Not End With',
									                  '=NULL' => 'IS NULL',
									                  '!=NULL' => 'IS NOT NULL'
									                  };
									                  
	public static Map<String, String> matchingTypeForExportMap = new Map<String, String>{	'EQUALS' => '=' , 'NOT EQUAL TO' => '!=',
									                  'CONTAINS' => 'LIKE%' ,  'DOES NOT CONTAIN' => 'NOTLIKE%%',
									                  'GREATER THAN' => '>', 'GREATER OR EQUAL' => '>=',
									                  'LESS THAN' => '<' ,   'LESS OR EQUAL' => '<=', 
									                  'INCLUDES' =>  'INCLUDES' ,'EXCLUDES' => 'EXCLUDES', 
									                  /*'INCLUDE' =>  'Include' ,'EXCLUDE' => 'Exclude',*/
									                  'STARTS WITH'=>'STARTSWITH',
									                  'ENDS WITH'=>'ENDSWITH',
									                  'BETWEEN'=>'Between',
									                  'NOTBETWEEN'=>' NotBetween ',
									                  'REGEX'=>' LIKE ',
									                  'ISCHANGED' => 'IsChanged',
									                  'CHANGEDFROMTO' => 'ChangedFromTo',
									                  'LIKE %' => 'LIKE%',
									                 /* 'IN' => 'IN',
									                  'NOT IN' => 'NOTIN',*/
									                  'DOES NOT START WITH'  => 'NOTLIKE',
									                  'DOES NOT END WITH'  => 'NOTLIKE%',
									                  'IS NULL' => '=NULL',
									                  'IS NOT NULL' => '!=NULL'
									                  };		

   public static Set<String> logicalOperatorSet = new Set<String>{'(', ')', '.AND.' , '.OR.'};
   
   public static Set<String> allowedFieldSet = new Set<String>{'crossobject', 'lookupobjectfield', 'ownerprioritization'};
	
   public static Set<String> simulateOtherActions = new Set<String>{'Send Email' ,'Execute an Apex Job','Chatter Notification','Apex Callout-HTTP'}; 
   public static Set<String> simulateInsertUpsertActions = new Set<String>{'Upsert Related Object','Upsert Unrelated Object','Insert Related Object','Insert Unrelated Object'}; 	
									                  
}
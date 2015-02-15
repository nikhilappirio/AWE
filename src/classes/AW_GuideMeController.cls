// (c) 2013 Appirio, Inc.
// AW_GuideMeController                                                     
// This class is used to display a GuideMe of Advanced Workflow
//
// 31 Dec 2013     Peter Babalis     Initial version
//                 Build Formula Component Controller. Provides Javascript remoting capabilities, so that the 
//                 Build Formula Popup can dynamically render an sObjects fields/relationships up to n-tiers 
//
public class AW_GuideMeController{
	
	//Component Attributes
	public String RootObjectFieldIdAttr {get; set;}
	public String FormulaFieldIdAttr {get; set;}
	public Integer SelectElementSizeAttr {get; set;}
	public Boolean OpenPopupWithButtonAttr {get; set;}
	
	//Inner Class used to replicate the Select Option functionality.
	//This was required as the native SelectOption class was not returning
	//an object array to the calling javascript function
	public class SelectOption implements Comparable {
		
		public String Value {get; set;}
		public String Label {get; set;}
		
		public SelectOption (String value, String label) {
			this.Value = value;
			this.Label = label;
		}
		
		//Allows sorting in Lists
		public Integer compareTo(Object compareTo) {
        	SelectOption compareToSelectOption = (SelectOption)compareTo;
        	if (Label == compareToSelectOption.Label) return 0;
        	if (Label > compareToSelectOption.Label) return 1;
        	return -1;        
    	}
	}
	
	//Custom Exception Class
	public class AW_GuideMeException extends Exception {}
	
	// BuildFormulaException extends Exception {}
	
	//Custom Exception Messages
	public static final String INVALID_RELATIONSHIP_SYNTAX = 'Invalid sobject relationship. The ' +
	    'BuildFormulaController.getChildSelectOptions method does not support the {!sObjectRelationship} ' +
	    'sobject relationship as a parameter. The sobject relationship provided is not in the format ' +
	    '<sObject>.<Relationship> (e.g. Account.CreatedBy)';

	public static final String INVALID_MULTI_OBJECT_RELATIONSHIP_EXCEPTION = 'Invalid sobject relationship. The ' +
		'BuildFormulaController.getChildSelectOptions method does not support the {!sObjectRelationship} ' +
		'sobject relationship as a parameter. The sobject relationship provided points to multiple types ' + 
		'of objects as parents.';
		
	public static final String SOBJECT_RELATIONSHIP_DOES_NOT_EXIST_EXCEPTION = 'Invalid sobject relationship. The ' +
		'BuildFormulaController.getChildSelectOptions method does not support the {!sObjectRelationship} ' +
		'sobject relationship as a parameter. The sobject relationship provided does not exist.';
	
	@RemoteAction
    /*************************************************************************************************************
    * @author       AutomaTom            
    * @date         31 December 2013 
    * @param        String sObjectName - This should be the name of a valid sObject (e.g. Account)
    * @return       List<BuildFormulaController.SelectOption> - A list of sObject fields and relationships 
    * @description  Returns a list of sObject fields and relationships (Select Options) for the sObject 
    **************************************************************************************************************/
	public static List<AW_GuideMeController.SelectOption> getSelectOptions(String sObjectName) {
		//Initialise
		List<AW_GuideMeController.SelectOption> selectOptions = new List<AW_GuideMeController.SelectOption>();
		//Describe sObject
		Schema.DescribeSObjectResult[] sObjectResults = Schema.describeSObjects(new String[]{sObjectName});
		for (Schema.DescribeSObjectResult sObjectResult : sObjectResults) {
			//Describe sObject Fields
			Map<String, Schema.SObjectField> sObjectFields = sObjectResult.fields.getMap();
			for (String key : sObjectFields.keySet()) {
				Schema.DescribeFieldResult sObjectFieldResult = sObjectFields.get(key).getDescribe();
				//Create a SelectOption for each sObject Field
				selectOptions.add(new AW_GuideMeController.SelectOption(sObjectName + '.' + sObjectFieldResult.getName(), 
					sObjectFieldResult.getLabel()));
				//If the sObject Field is a reference type field and the reference is to a single object only and the 
				//reference returns the name of a valid sObject then add another SelectOption indicating a child relationship 
				if (sObjectFieldResult.getType() == Schema.DisplayType.Reference && 
					!sObjectFieldResult.isNamePointing() && sObjectFieldResult.getRelationshipName() != null) {
					selectOptions.add(new AW_GuideMeController.SelectOption(sObjectName + '.' + 
						sObjectFieldResult.getRelationshipName(), sObjectFieldResult.getLabel().removeEnd(' ID') + ' >'));
				}
			}
		}
		//Sort the List
		selectOptions.sort();
		return selectOptions;
	}
	
    @RemoteAction
    /*************************************************************************************************************
    * @author       AutomaTom            
    * @date         31 December 2013 
    * @param        String sObjectRelationship - This should be an sObject relationship in the format 
    *               <sObject>.<Relationship> (e.g. Account.CreatedBy)
    * @return       List<AW_GuideMeController.SelectOption> - A list of sObject fields and relationships 
    * @description  Returns a list of sObject fields and relationships (select options) for the sObject identified 
    *               on the sObjectRelationship
    **************************************************************************************************************/
    public static List<AW_GuideMeController.SelectOption> getChildSelectOptions(String sObjectRelationship) {

		//Validate input argument format is correct
		Pattern sObjectRelationshipPattern = pattern.compile('\\S+[.]\\S+'); 
		Matcher sObjectRelationshipMatcher = sObjectRelationshipPattern.matcher(sObjectRelationship);
		if (!sObjectRelationshipMatcher.matches()) {
			throw new AW_GuideMeException(INVALID_RELATIONSHIP_SYNTAX.replace('{!sObjectRelationship}', 
				sObjectRelationship));
		} 
        //Parse the sObject and relationship into separate variables
        String sObjectName = sObjectRelationship.left(sObjectRelationship.indexOf('.'));
        String relationship = sObjectRelationship.right(sObjectRelationship.length() - 
        	(sObjectRelationship.indexOf('.') + 1));
		//Describe the sObject
		Schema.DescribeSObjectResult[] sObjectResults = Schema.describeSObjects(new String[]{sObjectName});
		for (Schema.DescribeSObjectResult sObjectResult : sObjectResults) {
			//Describe the sObject Fields
			Map<String, Schema.SObjectField> sObjectFields = sObjectResult.fields.getMap();
			for (String key : sObjectFields.keySet()) {
				Schema.DescribeFieldResult sObjectfieldResult = sObjectFields.get(key).getDescribe();
				//When the described sObject Field matches the Relationship passed in then return a list of 
				//Select Options for the child sObject referenced on the relationship
				if (sObjectfieldResult.getRelationshipName() == relationship) {
					//Validate the sObject field is a reference to a single object only
					//and the reference returns the name of a valid sObject
					if (sObjectfieldResult.isNamePointing()) {
						throw new AW_GuideMeException(INVALID_MULTI_OBJECT_RELATIONSHIP_EXCEPTION.replace
							('{!sObjectRelationship}', sObjectRelationship));
					} else {
						return getSelectOptions(sObjectfieldResult.getReferenceTo().get(0).getDescribe().getName());
					}
				} 
			}
		}
		//Throw an exception if none of the sObject fields matched the value of the Relationship passed in
		throw new AW_GuideMeException(SOBJECT_RELATIONSHIP_DOES_NOT_EXIST_EXCEPTION.replace('{!sObjectRelationship}', 
			sObjectRelationship));
    }
}
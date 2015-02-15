public with sharing class AW_ParseXML_Criteria_Helper {
	public	String 		criteriaName				{get;set;}
	public	String		crossFormula				{get;set;}
	public	String		matchingType				{get;set;}
	public	String		matchingValue1				{get;set;}
	public	String		maximumValue				{get;set;}
	public	String		minimumValue				{get;set;}
	public	String		criteriarelatedObject		{get;set;}
	public	String		criteriafieldapiname		{get;set;}
	public	String		critetriafieldtype			{get;set;}
	public	String		recordtypeid     			{get;set;}
	
	
	public AW_ParseXML_Criteria_Helper(){
		this.criteriarelatedObject	=	'';
		this.maximumValue	=	'';
		this.minimumValue	=	'';
		this.matchingType	=	'';
		this.matchingValue1	=	'';
		this.crossFormula	=	'';
		this.criteriaName	=	'';
		this.criteriafieldapiname =	'';
		this.critetriafieldtype	=	'';
		this.recordtypeid	=	'';
	}

}
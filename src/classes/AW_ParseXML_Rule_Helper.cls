public with sharing class AW_ParseXML_Rule_Helper {
 
	public	Integer 		ruleNumber			{get;set;}
	public	String 			ruleName			{get;set;}	
	public	String			description			{get;set;}
	public	List<AW_ParseXML_Criteria_Helper>	criterias			{get;set;}
	public	List<AW_ParseXML_Action_Helper>	actions				{get;set;}
	public	Integer			orderRule			{get;set;}
	public	String			evaluationRule		{get;set;}
	public	String			executionBehavior	{get;set;}
	public	String			filterLogic			{get;set;}
 	public	String			ruleCriteria		{get;set;}
 	public	String			rulestatus			{get;set;}
	public	Integer			ruleversion			{get;set;}
	
	 
	
	public 	AW_ParseXML_Rule_Helper(){
		this.ruleCriteria		=	'';
		this.filterLogic		=	'';
		this.ruleversion		=	0;
		this.executionBehavior	=	'';
		this.evaluationRule		=	'';
		this.rulestatus         =   '';
		this.orderRule			=	null;
		this.ruleNumber			=	0;
		this.ruleName			=	'';	
		this.description		=	'';	
		this.criterias			=	new List<AW_ParseXML_Criteria_Helper>();
		this.actions			=	new List<AW_ParseXML_Action_Helper>();
		
	}
}
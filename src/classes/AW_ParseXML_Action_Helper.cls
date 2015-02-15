public with sharing class AW_ParseXML_Action_Helper {

	public	list<AW_ParseXML_RelatedAction_Helper>	listaRAction	{get;set;}
	public  list<AW_ParseXML_OwnerPrioritization_Helper> listOwnerPrioritization {get;set;}
	public	String				typeAction				{get;set;}
	public	String				actionfieldName			{get;set;}
	public	String				actionfieldAPIName		{get;set;}
	public	String				actionvalue				{get;set;}
	public	String				actionlongValue			{get;set;}
	public	String				actionnotifyUser		{get;set;}
	public	String				actionemailTemplate_ID		{get;set;}
	public	String				actionrelatedObject		{get;set;}
	public	String				actionCrossObjectField		{get;set;}
	public	String				actionField_Type		{get;set;}
	public	String				actionEmail_Template		{get;set;}
	public  String              actionEmailFolder           {get;set;} // Megha
	public	String				actionEmailTemplateName		{get;set;}
	public	String				actionReference_Id			{get;set;}
	public	String				actionUser_Owner 			{get;set;}
    public  String  			actionAdditionalEmails     {get;set;}
	public  String   			actionApexJobClass     {get;set;}
	public  String   			actionCallOutAction     {get;set;}
 	public  String   			actionCalloutMethod     {get;set;}
	public  String   			actionCalloutTimeout     {get;set;}
    public  String   			actionLookupWhereFields     {get;set;}
	public  String   			actionEndPoint     {get;set;} 
	public  String   			actionEndpointURL     {get;set;}
	public  String   			actionInputParameters     {get;set;}
	public  String   			actionLookupFieldAPIName     {get;set;}
	public  String   			actionLookupFieldName     {get;set;}
	public  String   			actionLookupObject     {get;set;}
	public  String   			actionOutputParameters     {get;set;}
	public  String   			actionRequestParameter     {get;set;}
	public  String   			actionResponseParameter     {get;set;}
	public  String  			actionBulkAPI     {get;set;}
	public  String   			actionUserOwnerId     {get;set;}
	public  String              user_Name		  {get;set;}
	public  String 				group_Name	  {get;set;}
	public  String 				actionPrioritizationMethod {get;set;}

   	
	
	public	AW_ParseXML_Action_Helper(){
		this.typeAction		=	'';
		this.actionrelatedObject	=	'';
		this.actionfieldName		=	'';
		this.actionfieldAPIName   =   '';
	    this.actionfield_Type	=	'';
		this.actionvalue			=	'';
		this.actionlongValue		=	'';
		this.actionnotifyUser		=	'';
		this.actionemailTemplate_ID	=	'';
		this.actionEmailTemplateName	=	'';
		this.actionReference_Id	=	'';
	 	this.actionUser_Owner	=	'';
	 	this.actionAdditionalEmails  = ''; 
		this.actionApexJobClass  = ''; 
		this.actionCallOutAction  = ''; 
		this.actionCalloutMethod  = ''; 
		this.actionCallOutTimeOut  = ''; 
		this.actionLookupWhereFields  = ''; 
		this.actionEndPoint  = ''; 
		this.actionEndpointURL  = ''; 
		this.actionInputParameters  = ''; 
		this.actionLookupFieldAPIName  = ''; 
		this.actionLookupFieldName  = ''; 
		this.actionLookupObject  = ''; 
		this.actionOutputParameters  = ''; 
		this.actionRequestParameter  = ''; 
		this.actionResponseParameter  = ''; 
		this.actionBulkAPI  = ''; 
		this.actionUserOwnerId  = ''; 
		this.actionPrioritizationMethod = '';
	 	this.listaRAction	=	new list<AW_ParseXML_RelatedAction_Helper>();
	 	this.listOwnerPrioritization = new List<AW_ParseXML_OwnerPrioritization_Helper>();

	}
}
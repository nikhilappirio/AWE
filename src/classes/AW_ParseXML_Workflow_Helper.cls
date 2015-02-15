public with sharing class AW_ParseXML_Workflow_Helper {
	public	String		description	{get;set;}
	public	String		name		{get;set;}
	public	String		enabled		{get;set;}
	public	String		objeto		{get;set;}
	public list<AW_ParseXML_Rule_Helper>	listaRules	{get;set;}
	
	
	public AW_ParseXML_Workflow_Helper(){
		this.name			=	'';
		this.enabled		=	'';
		this.objeto			=	'';
		this.description	=	'';
		this.listaRules		=	new list<AW_ParseXML_Rule_Helper>();
	}
	
}
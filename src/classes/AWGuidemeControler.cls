public with sharing class AWGuidemeControler {
	 public String objType   {get;set;}
	 public String newRuleActionType  {get;set;}
	 public String newRuleActionField  {get;set;}
	 public String newRuleActionFieldType  {get;set;}
	 public String calculateFormulaForReference  {get;set;}
 
	 public List<SelectOption> objOptions    {get;set;}
	 public List<SelectOption> unrelatedObjectOptions    {get;set;}
	 
	  
	 public AWGuidemeControler(Apexpages.StandardController stdcon){
         newRuleActionType='Update';
         newRuleActionField='Ownerid';
         newRuleActionFieldType='String';
         calculateFormulaForReference='';
         objType='Account';  
         objOptions = new List<SelectOption>();
         unrelatedObjectOptions = new List<SelectOption>();
         objOptions.add( new SelectOption('Account' , 'Account'));
         objOptions.add( new SelectOption('Oportunity' , 'Oportunity'));
         objOptions.add( new SelectOption('Case' , 'Case'));
          
         unrelatedObjectOptions.add( new SelectOption('Lead' , 'Lead'));
         unrelatedObjectOptions.add( new SelectOption('User' , 'User'));
         
         
	 }

}
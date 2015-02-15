//
// (c) 2012 Appirio, Inc.
// AW_AddRulesToWorkflowController                                                     
// This class is used to add Rules to the Execution Plan  
//
// 18 Nov 2012     Peter Babalis     Original
// 26 Jan 2012     Peter Babalis     Added Status and Version  for Rules
// 13 Feb 2015     Nikhil            Added Filter functionality 
//  
//  
public with sharing class AW_AddRulesToWorkflowController 
{
    public Rule__c NewRule 								{	get;set;	}
    public List<RulesPerObject>  listAddRulesPerObject  {	get;set;	}
    public Advance_Workflow__c  ruleExecutionPlan 		{	get;set;	}
    public String strSearch								{	get;set;	}
    public String strSearchToRestore					{	get;set;	}
	public List<fieldWrapper> FieldDetails 				{	get;set;	}
    private Id  defineruleexecutionplanId ; 
    /**
    * Constructor
    */ 
    public AW_AddRulesToWorkflowController(ApexPages.StandardController controller) 
    {
        defineruleexecutionplanId = controller.getId();
   
        /**
        * Retrive All Rules related to the Object the Assignment Rule is created by the  "Object__c"
        */
        List<Advance_Workflow__c> listObjects  = new List<Advance_Workflow__c>([Select Id, Enabled__c,Name,Object__c From Advance_Workflow__c Where Id = : controller.getId()]);
        /**
        * Set of Objects
        */  
        Set<String> setObject = new Set<String>();
        if(listObjects != null && listObjects.size() > 0)
        {
            for(Advance_Workflow__c REP : listObjects)
            {
                setObject.add(REP.Object__c);
            }
            ruleExecutionPlan = listObjects[0];
            if(!ruleExecutionPlan.Enabled__c)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info,'Can not add remove rules to a disabled plan'));
            }
        }
        
        List<Rule__c> listRules  = new List<Rule__c>([Select Id,
                                                              Name,
                                                              Filter_Logic__c,
                                                              Description__c, 
                                                              DisplayfilterLogic__c,
                                                              Order__c ,
                                                              Status__c,
                                                              Version__c,
                                                              Advance_Workflow__c,
                                                              Execution_Behavior__c,
                                                              Object__c,
                                                              Total_Actions__c,
                                                              Total_Criteria__c,
                                                              DisplayActions__c,
                                                              Evaluation_Rule__c 
                                                         FROM Rule__c 
                                                         WHERE Object__c in : setObject and ( Status__c in ( 'Draft','Active')) 
                                                         ORDER by Order__c ASC NULLS Last]);
          
        listAddRulesPerObject = new List<RulesPerObject>();
        /**
        * Fill the list of wrapper class "RulesPerObject"
        */
        for(Rule__c RO : listRules)
        {   
            if (RO.Total_Actions__c>=1 && RO.Total_Criteria__c>=1)
             {
               RulesPerObject robj = new RulesPerObject();
               robj.Rules = RO;
               robj.isAdd = (RO.Advance_Workflow__c != null && RO.Advance_Workflow__c == defineruleexecutionplanId) ? true : false;
               listAddRulesPerObject.add(robj); 
               SetRecordsinList(robj,RO);
             }
        }  
       	initializeColDetails();                            
    }
    
    /**
    * Select List of Execution Behavior
    */
    Public List<SelectOption> getExecutionBehavior()  
    {
        List<selectOption> options = new List<selectOption>();
        Schema.DescribeFieldResult field = Rule__c.Execution_Behavior__c.getDescribe();
        for(Schema.Picklistentry picklistEntry : field.getPicklistValues())
            options.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        return options;  
   }
  
    /**
    * Method for Link Rules  to the RuleofExecution.
    */
    public Pagereference AddRule()
    {
    	if(listAddRulesPerObject.isEmpty())
    	{
    		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'There are no rules to save!'));
             return null;
    	}
        //do limit validation:-
        try{
            List<Rule__c> updateListRules = new List<Rule__c>();
            Set<Decimal> orderSet = new Set<Decimal>(); 
            for(RulesPerObject RO : listAddRulesPerObject)
            {
                /**
                  * If "Add Rule" checkbox checked on the page then assign ObjectAssignmentRules__c id to the lookup 
                  * field "Rule_Assignment__c" else assign null
                */
				RO.Rules.Advance_Workflow__c = RO.isAdd ? defineruleexecutionplanId : null;
                RO.Rules.Status__c = RO.isAdd ? 'Active' : 'Draft';
                system.debug('RO.isAdd '  + RO.isAdd );                   
                if(RO.isAdd)
                {
                      if(RO.Rules.Order__c == null)
                      {
                         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order is required for selected rule'));
                         return null;
                      } 
                      else if(RO.Rules.Order__c == 0)
                      {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order can not be 0'));
                        return null;
                      } 
                      else if(orderSet.contains(RO.Rules.Order__c))
                      {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Order must be unique'));
                        return null;
                      } 
                      else
                      {
                        orderSet.add(RO.Rules.Order__c);
                      }
                  }else
                  {
                      RO.Rules.Status__c='Draft';
                      RO.Rules.Order__c = null;
                      RO.Rules.Execution_Behavior__c = null;
                  }
                  updateListRules.add(RO.Rules);                
            }
            
            /**
            * Update list of Rules
            */
            update updateListRules;
            return new Pagereference('/apex/AW_ListRules_VF?id='+defineruleexecutionplanId);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getDMLMessage(0)));
            return null;
        }
    }
    
    /**
    * Return to Execution Plan detail page
    */
    public Pagereference Cancel()
    {
        return new Pagereference('/apex/AW_ListRules_VF?id='+defineruleexecutionplanId);
    }
    
    private void SetRecordsinList(RulesPerObject objRulesWrapper,Rule__c rule)
    {     
	    try
	    {
	        if(rule.Evaluation_Rule__c=='Record is Created')
	            objRulesWrapper.Evaluation='Create';
	        else if(rule.Evaluation_Rule__c=='Record is Created or Edited')
	        	objRulesWrapper.Evaluation='Create, Edit';
	        else if(rule.Evaluation_Rule__c=='Record is created or edited and did not previously meet the rule criteria')
	            objRulesWrapper.Evaluation='Not Meet  Criteria';
	        if(rule.Execution_Behavior__c=='Execute Rule and Exit')
	            objRulesWrapper.Execution='Exit';
	        else if(rule.Execution_Behavior__c=='Execute Rule and Continue to Next Rule')
	            objRulesWrapper.Execution='Continue';   
	        if(rule.DisplayfilterLogic__c != null && rule.DisplayfilterLogic__c !='' && rule.DisplayfilterLogic__c.length()>100)
	            objRulesWrapper.Criteria= rule.DisplayfilterLogic__c.mid(0, 100)+'...'; 
	        else
	            objRulesWrapper.Criteria= rule.DisplayfilterLogic__c;                           
	        objRulesWrapper.DisplayCriteria= rule.DisplayfilterLogic__c;      
	        if(rule.DisplayActions__c != null && rule.DisplayActions__c !='' && rule.DisplayActions__c.length()>100)
	            objRulesWrapper.Actions= rule.DisplayActions__c.mid(0, 100)+'...';                               
	        else
	            objRulesWrapper.Actions= rule.DisplayActions__c;                              
	        objRulesWrapper.Actions= rule.DisplayActions__c;
	        
	    }
	    catch(exception e)
	    {
	        
	    }
 }
	 /*	MethodName	:	applyFilter
	   	Return Type	: 	void
	   	Arguments	: 	Null
	   	Description	: 	Captures filter values from pageblocktable header which are used by doquery method to build the query.
	 */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void applyFilter()
    {
        doQuery();
    }
    //---------------------------------------------------------------------------------------------------------------------------//
    /* 	MethodName	:	clearFilter
   		Return Type	: 	void
   		Arguments	: 	Null
   		Description	: 	Clears filter values.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void clearFilter()
    {
        strSearch = '';
        strSearchToRestore = '';
        doQuery();
    }

    private void doQuery()
    {
        List<Rule__c> lstRules2 = DataBase.Query(makeQuery());
        listAddRulesPerObject = new List<RulesPerObject>();
        for(Rule__c RO : lstRules2)
        {   
               RulesPerObject robj = new RulesPerObject();
               robj.Rules = RO;
               robj.isAdd = (RO.Advance_Workflow__c != null && RO.Advance_Workflow__c == defineruleexecutionplanId) ? true : false;
               listAddRulesPerObject.add(robj); 
               SetRecordsinList(robj,RO);
        } 
        system.debug('listAddRulesPerObject after searching ::::::::::: '+listAddRulesPerObject);
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* 	MethodName	:	makeQuery
   		Return Type	: 	string
   		Arguments	: 	Null
   		Description	: 	This method builds the Dyanamic SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private string makeQuery()
    { 
        String soql = 'Select ';
        soql += ' Id,Advance_Workflow__c,';
        soql += '';

        if (fieldList() != '')
            soql += fieldList()+ ',';  
        if(soql.endsWith(','))
            soql = soql.substring(0,soql.length()-1);
        if(soql.endsWith(','))
            soql = soql.substring(0,soql.length()-1);
        soql += '  From Rule__c ';
        String whereclause = getFilterCriteria();
        if(whereclause != '')
        {
            soql += whereclause;
        }
        soql += ' limit 1001';
		system.debug('+++++++++++++++++++++++++++SOQL'+soql);
        return soql;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* 	MethodName	:	getFilterCriteria
   		Return Type	: 	String
   		Arguments	: 	Null
   		Description	: 	This method builds the 'Where' clause for the SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//

    public String getFilterCriteria()
    {
        String filterCriteria = '';
        filterCriteria =' WHERE ( Advance_Workflow__c =\''+  defineruleexecutionplanId + '\' AND Status__c=\'Active\')';
        system.debug('--->filterCriteria '+filterCriteria);
        List<String> criterias = new List<String>();
        system.debug('-----------------------strSearch--------------------------' + strSearch);  
        if(strSearch !=null && strSearch !='')
        {
            List<String> strSearchFields = strSearch.split('\\|');
            system.debug('-----------------------strSearchFields--------------------------' + strSearchFields);
            for(String fsf: strSearchFields)
            {
                system.debug('-----------------------fsf--------------------------' + fsf);
                if(fsf!='' && fsf != null)
                {
                    List<String> fieldDetail = fsf.split('.-~>');
                    system.debug('-----------------------fieldDetail[0] --------------------------' + fieldDetail[0] );
                    if(fieldDetail.size()>2 )
                    {
                        if(fieldDetail[0] != 'Description__c' && fieldDetail[0] != 'DisplayActions__c' &&
                                fieldDetail[0] !='FormattedFilterLogic__c' && fieldDetail[0] !='DisplayfilterLogic__c' &&
                                fieldDetail[0] !='Total_Actions__c' && fieldDetail[0] !='Total_Criteria__c')
                           {
                            	system.debug('-----------------------fieldDetail--------------------------' + fieldDetail);
                            	criterias.add(criteriaHelper(fieldDetail[0],fieldDetail[1],fieldDetail[2]));
                           }
                            
                       
                    }
                }
            }
        } 
        system.debug('strSearch criterias' + criterias);  
        for(String strCriteria:criterias)
        {
            if(strCriteria != '' && strCriteria != null)
            {
                system.debug('--------------------------strCriteria----------------------- '+ strCriteria);
                if(filterCriteria.toUpperCase().contains('WHERE'))
                    filterCriteria += ' AND ' + strCriteria;
                else
                    filterCriteria += ' WHERE ' + strCriteria;
            }
        }

        system.debug('Nikhil===>  filterCriteria' + filterCriteria);    
        return filterCriteria;
    }
    //---------------------------------------------------------------------------------------------------------------------------//
    /* 	MethodName	:	criteriaHelper
   		Return Type	: 	String
   		Arguments	: 	String, String, String
   		Description	: 	This method builds the filters in the 'Where' clause for the SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private String criteriaHelper(String fieldName,String fieldType,String value)
    {
        String criteria ='';
        system.debug('---- criteriaHelper -------- fieldName-----------'+ fieldName);
        system.debug('---- criteriaHelper -------- fieldType-----------'+ fieldType);
        system.debug('----- criteriaHelper ------- value-----------'+ value);

        if(value != null && value != '')
        {
            if(fieldType=='STRING' && fieldName=='ID')
                criteria = fieldName + ' = \'' + value + '\'';  
            else if(fieldType=='INTEGER')
                criteria = fieldName + '=' + value;
            else if(fieldType=='STRING')
                criteria = fieldName + ' like \'%' + value + '%\'';
            else if(fieldType=='OTHER')
                criteria = fieldName + ' like \'%' + value + '%\'';
            else if(fieldType=='BOOLEAN')
            {
                if(value!='All')
                    criteria = fieldName + '=' + boolean.valueOf(value);
            }
            else if(fieldType=='DATE')
            {
                List<String> dateRange = value.split('~');
                if(dateRange.size()>0)
                {
                    List<String> lstFirstDate ;
                    List<String> lstSecondDate ;

                    //making sure to date ranage is present in list if user have not passed
                    if(dateRange.size()==1)
                        dateRange.add('');

                    //when from date range is given
                    if(dateRange[0] != null && dateRange[0] != '')
                    {
                        lstFirstDate = dateRange[0].split('/');
                        criteria = fieldName + '>=' + lstFirstDate[2] + '-' +lstFirstDate[0] + '-' +lstFirstDate[1];
                        //when to date range is given
                        if(dateRange[1] != null && dateRange[1] != '')
                        {
                            lstSecondDate = dateRange[1].split('/');
                            criteria += ' AND ' + fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1];
                        }
                    }
                    //when from date range is not given handle on to date range
                    else{
                        if(dateRange[1] != null && dateRange[1] != '')
                        {
                            lstSecondDate = dateRange[1].split('/');
                            criteria = fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1];
                        }
                    }
                }
            }
            else if(fieldType=='DATETIME')
            {
                List<String> dateRange = value.split('~');
                if(dateRange.size()>0)
                {
                    List<String> lstFirstDate ;
                    List<String> lstSecondDate ;

                    //making sure to date ranage is present in list if user have not passed
                    if(dateRange.size()==1)
                        dateRange.add('');

                    //when from date range is given
                    if(dateRange[0] != null && dateRange[0] != '')
                    {
                        lstFirstDate = dateRange[0].split('/');
                        criteria = fieldName + '>=' + lstFirstDate[2] + '-' +lstFirstDate[0] + '-' +lstFirstDate[1] + 'T00:00:00Z';
                        //when to date range is given
                        if(dateRange[1] != null && dateRange[1] != '')
                        {
                            lstSecondDate = dateRange[1].split('/');
                            criteria += ' AND ' + fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1] + 'T11:59:59Z';
                        }
                    }
                    //when from date range is not given handle on to date range
                    else
                    {
                        if(dateRange[1] != null && dateRange[1] != '')
                        {
                            lstSecondDate = dateRange[1].split('/');
                            criteria = fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1] + 'T11:59:59Z';
                        }
                    }
                }
            }
        }
        system.debug('------------ criteria-----------'+ criteria);
        return criteria;
    }
     //---------------------------------------------------------------------------------------------------------------------------//
    /* 	MethodName	:	initializeColDetails
   		Return Type	: 	void
   		Arguments	: 	Null
   		Description	: 	This invoked in the constructor on page load and initializes variables.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private void initializeColDetails()
    {
        System.debug('$$$$$$$$$$$$$$$$ Inside initializeColDetails');  
        FieldDetails = new List<fieldWrapper>();
        //FieldDetails.add(new fieldWrapper('Id','Id','STRING', 'Id'));
        FieldDetails.add(new fieldWrapper('Order__c','Order','INTEGER', 'Order'));
        FieldDetails.add(new fieldWrapper('Name','Name','STRING', 'Name'));
        //FieldDetails.add(new fieldWrapper('Version__c' , 'Version' , 'INTERGER' , 'Version'));// Megha
        //FieldDetails.add(new fieldWrapper('Description__c' , 'Description' , 'STRING' , 'Description'));// Megha
        //FieldDetails.add(new fieldWrapper('Object__c','Object','STRING', 'Object'));
        FieldDetails.add(new fieldWrapper('Status__c','Status','STRING', 'Status')); 
        //FieldDetails.add(new fieldWrapper('Advance_Workflow__r.Name','Advance_Workflow','STRING', 'Advance_Workflow'));
        //FieldDetails.add(new fieldWrapper('Advance_Workflow__r.Description__c','Advance Workflow Description','STRING', 'Advance Workflow Description'));                    
        FieldDetails.add(new fieldWrapper('Evaluation_Rule__c','Evaluation Rule','STRING', 'Evaluation Rule'));
        FieldDetails.add(new fieldWrapper('Execution_Behavior__c','Execution Behavior','STRING', 'Execution Behavior'));
        FieldDetails.add(new fieldWrapper('DisplayfilterLogic__c','Display Filter Logic','STRING', 'Display Filter Logic'));
        //FieldDetails.add(new fieldWrapper('CSV_Formatted_Criteria__c','CSV Formatted Criteria','STRING', 'CSV Formatted Criteria'));
        //FieldDetails.add(new fieldWrapper('Filter_Logic__c','Filter Logic','STRING', 'Filter Logic'));
        FieldDetails.add(new fieldWrapper('DisplayActions__c','Display Actions','STRING', 'Display Actions')); 
        //FieldDetails.add(new fieldWrapper('CSV_Formatted_Actions__c','CSV Formatted Actions','STRING', 'CSV Formatted Actions'));
        System.debug('---------------------FieldDetails---------------------'+FieldDetails);  
        // FieldDetails.add(new fieldWrapper('Name','Serial #','STRING', 'Serial No'));        
    }

   
   

    private String fieldList()
    {
        System.debug('$$$$$$$$$$$$$$$$ Inside fieldList');
        String result = '';
        system.debug('--------------- FieldDetails -------------------------'+FieldDetails);
        if(FieldDetails != null && FieldDetails.size()>0)
        {            
            for(fieldWrapper fw :FieldDetails)             
                result += fw.apiName + ',';            
             system.debug('FieldDetails++++++++++++++++++++++++++++++'+FieldDetails);
        }  
        return result;
    }
    //---------------------------------------------------------------------------//

    /** Inner wrapper class to wrap selected Columns and populated Filters on the console and dashboard.
          This class is used to build and Save Views. **/

    //---------------------------------------------------------------------------//

    public class fieldWrapper{

        public String apiName {get;set;}
        public String label {get;set;}
        public String dataType{get;set;}
        public String Type{get;set;}
        public String HelpText{get;set;}
        public List<String> referenceToList{get;set;}
        public fieldWrapper(String apiName,String label,String dataType, String HelpText){

            System.debug('$$$$$$$$$$$$$$$$ Inside fieldWrapper constructor');  
            this.apiName = apiName;
            this.label = label;
            this.dataType = dataType;
            this.HelpText = HelpText;
            this.referenceToList = new List<String>();
        }
        public fieldWrapper(String apiName,String label,String dataType, String HelpText , List<String> referenceToList)
        {

            System.debug('$$$$$$$$$$$$$$$$ Inside fieldWrapper constructor');  
            this.apiName = apiName;
            this.label = label;
            this.dataType = dataType;
            this.HelpText = HelpText;
            this.referenceToList = this.referenceToList;

        }

    }
     
    /**
    * Inner Class
    */
    public class RulesPerObject{
        public boolean isAdd {get;set;}
        public Rule__c Rules {get;set;}
        public String Evaluation {get;set;}     
        public String Execution {get;set;}
        public String Criteria {get;set;}
        public String DisplayCriteria {get;set;}
        public String Actions {get;set;}    
        public String DisplayActions {get;set;}
    }
}
/*********************************************************************************
Name : AW_ListRules
Created By : Appirio   [Peter Babalis]
Created Date : 20 April 2013
Purpose : controller for AW_ListRules_VF page
 *********************************************************************************/
public with sharing class AW_ListRules {

    public Document csvRules{get;set;}

    //---------------------------------------------------------------------------//
    //Public Properties
    //---------------------------------------------------------------------------//
    public String UserType{
        get{
            return userInfo.getUserType();
        }
    }

    public list<InstallBaseWrapper> lstInstallBaseWrapper {get;set;}
    public list<Rule__c> lstAllIB {get;set;}


    public list<Workflow_DynamicColumns__c > lstIBDC {get;set;}
    public Boolean moreThan1000 {get;set;}
    public Integer resultsPerPage {get;set;}
    public Integer pageNumber {get;set;}

    public Boolean isAsc {get;set;}
    public Boolean doSort {get;set;}
    public String previousSortField {get;set;}
    public String sortField {get;set;}

    public String fixedSearch{get;set;}
    public String fixedSearchToRestore{get;set;}
    public String dynamicSearch{get;set;}
    public String dynamicSearchToRestore{get;set;}

    public List<SelectOption> assets{get;set;}
    public String selectedAsset {get;set;}
    public String sSOQL {get;set;}


    //------ Properties for Configuring Views

    public String savedViewId {get;set;}
    public String saveAsViewName {get;set;}
    public List<SelectOption> savedViews{get;set;}
    public String selectedObject {get;set;}
    public String moreColumns {get;set;}

    // public Map<String,IB_DynamicColumns__c > DefaultColumnMap{get; set;}
    public Map<String,Workflow_DynamicColumns__c > DefaultColumnMap{get; set;}
    public Map<String, String> DefaultColumnMap_API {get; set;}
    public Map<String, String> DefaultColumnMap_Type {get; set;}
    public Map<String, String> DefaultColumnMap_DataType {get; set;}


    // public List<IB_DynamicColumns__c> lstIBDC_IB {get; set;}
    public List<Workflow_DynamicColumns__c> lstIBDC_IB {get; set;}
    public List<fieldWrapper> fixedFieldDetails {get;set;}
    public List<fieldWrapper> dynamicFieldDetails {get;set;}
    public map<String,String> dynamicFieldInfo;
    public String selectedView {get;set;}
    public String title {get;set;}

    List<Workflow_Console_ViewDetail__c> IBlstCnslVD ;
    // List<IBCnslViewDetail__c> IBlstCnslVD ;
    List<String> moreIBFieldAPIs;
    public pagereference pageref;
    public Boolean requiredFieldMissing =true;
    public String DefaultViewId {get;set;}
    public Id CtrlId  {get;set;}   
    public String wfName  {get;set;}  
    public String wfId  {get;set;}    
    private String objName;
    //---------------------------------------------------------------------------//
    //Private variables
    //---------------------------------------------------------------------------//
    private ApexPages.Standardsetcontroller ssc {get;set;}

  /*  public void uploadCSV(){
        system.debug('*********Uploaded CSV'+csvRules.body);
        if(csvRules.body != null && String.valueOf(csvRules.body) != ''){
            try{
                AW_ParseCSVTo_AdvanceWorkflow_Util.importAWECSV(csvRules.body.toString(), objName, String.valueOf( Datetime.now() + Crypto.getRandomInteger()));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'File is imported successfully'));  
            }catch(Exception ex){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a file before import'));
        }
        //uploadCSV
    }*/

    //---------------------------------------------------------------------------------------------------------------------------//
    //Constructor
    // Argument: Standard Account Controller,
    //---------------------------------------------------------------------------------------------------------------------------//
    public AW_ListRules(ApexPages.StandardController stdController){
        csvRules = new Document();
        CtrlId=stdController.getId();
        list<Advance_Workflow__c> wfList=[Select Id,Name, Object__c from Advance_Workflow__c where id=:CtrlId];
        if(wfList != null && wfList.size()>0  ){
            wfName=wfList.get(0).Name;
            wfId=wfList.get(0).Id;
            objName= wfList.get(0).Object__c;

        }    
        init();
    }
    public PageReference returnPage()
   {
      
     //return new PageReference('/apex/AW_ImportExport_VF?id='+AWFId);
     return new PageReference('/apex/AW_ListRules_VF?id='+wfId);
   } 
    public PageReference showAddRemove(){
        CtrlId=ApexPages.currentPage().getParameters().get('id');
        return new PageReference('/apex/AW_AddRulesToWorkflow_VF?id='+CtrlId);

    }
    //---------------------------------------------------------------------------//
    //Public Methods
    //---------------------------------------------------------------------------//


    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:applysorting
   Return Type: void
   Arguments: Null
   Description: Sorts records displayed on dashboard ascending or descending  when user double clicks on any column label.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//

    public void applySorting(){
        doSort = true;
        doQuery();
        doSort = false;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:applyFilter
   Return Type: void
   Arguments: Null
   Description: Captures filter values from dashboard which are used by doquery method to build the query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void applyFilter(){
        doQuery();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:clearFilter
   Return Type: void
   Arguments: Null
   Description: Clears filter values on dashboard.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void clearFilter(){
        fixedSearch = '';
        fixedSearchToRestore = '';
        dynamicSearch = '';
        dynamicSearchToRestore = '';
        loadpreviousviewdetails();
    }

    //---------------------------------------------------------------------------//
    //Private Methods
    //---------------------------------------------------------------------------//

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:init
   Return Type: void
   Arguments: Null
   Description: This invoked in the constructor on page load and initializes variables.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private void init(){
        assets = new list<SelectOption>();
        assets.add(new SelectOption('All_Assets','All Assets'));
        assets.add(new SelectOption('All_Actionable_Assets','All Actionable Assets'));
        selectedAsset = 'All_Assets';

        saveAsViewName = '';
        //savedViewId = '';
        savedViews = new List<SelectOption>();
        try{
            // Fixed no List has no rows for assignment to SObject Appirio JDC
            for(Workflow_Console_ViewDetail__c wcv : [SELECT Id from Workflow_Console_ViewDetail__c  Where ((View_Type__c ='Account Console' OR View_Type__c ='') And (Name ='---Select View---'))
            Limit 1 ]){
                DefaultViewId = wcv.id;
                
            }
        }catch (System.QueryException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }         

        if(DefaultViewId!=''){      
            savedViewId = DefaultViewId;
            //savedViewId='';
        } else savedViewId='';

        lstIBDC = new list<Workflow_DynamicColumns__c>();
        iblstCnslVD = new list<Workflow_Console_ViewDetail__c>();


        //fetchDynamicColumnDetails();
        lstInstallBaseWrapper = new  list<InstallBaseWrapper>();
        requiredFieldmissing=true;

        doSort = true;
        previousSortField = '';
        sortField = 'Order__c';
        isAsc = true;
        resultsPerPage = 10;


        fetchDefaultColumnMap();
        fetchDynamicColumnDetails();
        initializeFixedColDetails();
        initializeDynamicFieldInfoMap();
        //initializeDynamicFieldDetails();
        initializeIBFieldAPIs();


        selectedObject = 'Rule__c';
        selectedView = '';
        loadPreviousViewDetails();

        changeView();
        //initializeDynamicFieldDetails();
        // doQuery();

    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:updatePageView
   Return Type: void
   Arguments: Null
   Description: This method creates the an IB wrapper list which is displayed on the dashboard page.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private void updatePageView(){
        lstInstallBaseWrapper = new  list<InstallBaseWrapper>();

        for(Rule__c ib:(list<Rule__c>)ssc.getRecords()){
            InstallBaseWrapper objInstallBaseWrapper=new InstallBaseWrapper(ib);
            SetRecordsinList(objInstallBaseWrapper,ib);
        }
    }

    private void SetRecordsinList(InstallBaseWrapper objRulesWrapper,Rule__c rule){
        String sDisplayfilterLogic=null;
        String sDisplayActions=null;
        try{
            if(fixedSearch !=null && fixedSearch !=''){
                List<String> fixedSearchFields = fixedSearch.split('\\|');              
                for(String fsf: fixedSearchFields){               
                    if(fsf!='' && fsf != null){
                        List<String> fieldDetail = fsf.split('.-~>');
                        if(fieldDetail.size()>2 ){
                            if(fieldDetail[0] =='DisplayfilterLogic__c'){
                                sDisplayfilterLogic=fieldDetail[2];                      
                            }
                            if(fieldDetail[0] =='DisplayActions__c'){
                                sDisplayActions=fieldDetail[2];                      
                            }
                        }
                    }
                }       
            }
            if(rule.Evaluation_Rule__c=='Record is Created'){
				objRulesWrapper.Evaluation='Create';
			}

			else if(rule.Evaluation_Rule__c=='Record is Created or Edited'){
				objRulesWrapper.Evaluation='Create, Edit';
			}       
			else if(rule.Evaluation_Rule__c=='Record is created or edited and did not previously meet the rule criteria'){
				objRulesWrapper.Evaluation='Not Meet  Criteria';
			}
			System.debug('::rule.Execution_Behavior__c'+rule.Execution_Behavior__c);
			if(rule.Execution_Behavior__c != null && rule.Execution_Behavior__c.trim() == 'Execute Rule and Exit'){
				objRulesWrapper.Execution='Exit';
			}
			else if(rule.Execution_Behavior__c != null && rule.Execution_Behavior__c == 'Execute Rule and Continue to Next Rule'){
				objRulesWrapper.Execution='Continue';
			} 
            if(rule.DisplayfilterLogic__c != null && rule.DisplayfilterLogic__c !='' && rule.DisplayfilterLogic__c.length()>100){
                objRulesWrapper.Criteria = rule.DisplayfilterLogic__c.mid(0, 100)+'...'; 
            }
            else{
                objRulesWrapper.Criteria = rule.DisplayfilterLogic__c;                           
            }
            objRulesWrapper.DisplayCriteria = rule.DisplayfilterLogic__c;      
            if(rule.DisplayActions__c != null && rule.DisplayActions__c !='' && rule.DisplayActions__c.length()>100){
                objRulesWrapper.Actions= rule.DisplayActions__c.mid(0, 100)+'...';                               
            }
            else{
                objRulesWrapper.Actions= rule.DisplayActions__c;                            
            }   
            objRulesWrapper.Actions= rule.DisplayActions__c;
            /*
        system.debug('--------------- rule.DisplayfilterLogic__c-----------------'+rule.DisplayfilterLogic__c);
        system.debug('--------------- rule.DisplayActions__c-----------------'+rule.DisplayActions__c);  
             */ 
            if(sDisplayfilterLogic==null && sDisplayActions==null){
                /*
            system.debug('--------------- First case-----------------'); 
                 */
                lstInstallBaseWrapper.add(objRulesWrapper);
            }
            else if(sDisplayfilterLogic!=null){
                if(rule.DisplayfilterLogic__c.toUpperCase().contains(sDisplayfilterLogic.toUpperCase())){
                    /*
                system.debug('--------------- second case-----------------'); 
                     */
                    lstInstallBaseWrapper.add(objRulesWrapper);                 

                }
            }
            else if(sDisplayActions!=null){
                if(rule.DisplayActions__c.toUpperCase().contains(sDisplayActions.toUpperCase())){
                    /*
                system.debug('--------------- third case-----------------');
                     */
                    lstInstallBaseWrapper.add(objRulesWrapper);
                }
            }
            System.debug('::lstInstallBaseWrapper'+lstInstallBaseWrapper);
        }
        
        catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
        }
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:fetchDynamicColumnDetails
   Return Type: void
   Arguments: Null
   Description: This method gets the console column details from IB_DynamicColumns__c table.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private void fetchDynamicColumnDetails(){
        for(Workflow_DynamicColumns__c ibdc: [Select Label__c, DataType__c, ApiName__c,Type__c, Page_Layout__c, Help_Text__c From Workflow_DynamicColumns__c  order By Type__c,ColumnOrder__c ]){
            lstIBDC.add(ibdc);
        }
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:doquery
   Return Type: void
   Arguments: Null
   Description: This method gets the console column details from IB_DynamicColumns__c table.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//

    private void doQuery(){

        ssc = new ApexPages.StandardSetController(Database.getQueryLocator(makeQuery()));
        system.debug('PGB  -->ssc ' + ssc);

        //system.debug('PGB  --> ' + 'doQuery =>  lstAllIB.size() :' + lstAllIB.size());
        updatePageView();
        if(ssc.getResultSize()>1000){
            moreThan1000 = true;
            //lstAllIB.remove(1000);
        }
        else{
            moreThan1000 = false;
        }

        ssc.setPageSize(resultsPerPage);
        firstPage();
    }



    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:makeQuery
   Return Type: string
   Arguments: Null
   Description: This method builds the Dyanamic SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private string makeQuery(){  
        String soql = 'Select ';
        soql += ' Id,';
        soql += '';

        if (fieldList()!=''){

            soql += fieldList()+ ',';

        }

        if(soql.endsWith(',')){
            soql = soql.substring(0,soql.length()-1);
        }


        if(soql.endsWith(',')){
            soql = soql.substring(0,soql.length()-1);
        } 

        soql += '  From Rule__c ';

        String whereclause = getFilterCriteria();


        if(whereclause != ''){
            soql += whereclause;
        }

        if(doSort && sortField != null && sortField != ''){
            if( ( sortField=='DisplayfilterLogic__c' || sortField=='DisplayActions__c'   ))  
                sortField=previousSortField;    
            if(isAsc && ( sortField!='DisplayfilterLogic__c' || sortField!='DisplayActions__c' || sortField!='Asset_Category__c' )) {

                soql += ' order by  ' + sortField + ' ASC NULLS LAST';
            }
            else{
                soql += ' order by ' + sortField + ' DESC NULLS LAST';
            }


            isAsc = previousSortField.equals(sortField)? !isAsc : true;

            previousSortField = sortField;
        }

        sSOQL = soql;

        soql += ' limit 1001';

        return soql;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:getFilterCriteria
   Return Type: String
   Arguments: Null
   Description: This method builds the 'Where' clause for the SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//

    public String getFilterCriteria(){

        String filterCriteria = '';

        filterCriteria =' WHERE ( Advance_Workflow__c =\''+  CtrlId + '\' AND Status__c=\'Active\')';
        system.debug('--->filterCriteria'+filterCriteria);
        List<String> criterias = new List<String>();
        system.debug('-----------------------fixedSearch--------------------------' + fixedSearch);  
        if(fixedSearch !=null && fixedSearch !=''){
            List<String> fixedSearchFields = fixedSearch.split('\\|');
            system.debug('-----------------------fixedSearchFields--------------------------' + fixedSearchFields);
            for(String fsf: fixedSearchFields){
                system.debug('-----------------------fsf--------------------------' + fsf);
                if(fsf!='' && fsf != null){
                    List<String> fieldDetail = fsf.split('.-~>');

                    system.debug('-----------------------fieldDetail[0] --------------------------' + fieldDetail[0] );
                    if(fieldDetail.size()>2 ){
                        if(fieldDetail[0] != 'Description__c' && fieldDetail[0] != 'DisplayActions__c' &&
                                fieldDetail[0] !='FormattedFilterLogic__c' && fieldDetail[0] !='DisplayfilterLogic__c' &&
                                fieldDetail[0] !='Total_Actions__c' && fieldDetail[0] !='Total_Criteria__c'){
                            system.debug('-----------------------fieldDetail--------------------------' + fieldDetail);
                            criterias.add(criteriaHelper(fieldDetail[0],fieldDetail[1],fieldDetail[2]));
                        }
                    }
                }
            }
            //fixedSearch = '';
        }
        system.debug('fixedSearch criterias' + criterias);  
        if(dynamicSearch !=null && dynamicSearch !=''){
            List<String> dynamicSearchFields = dynamicSearch.split('\\|');
            for(String dsf: dynamicSearchFields){
                if(dsf!='' && dsf != null){
                    List<String> fieldDetail = dsf.split('.-~>');
                    if(fieldDetail.size()>2 ){
                        criterias.add(criteriaHelper(fieldDetail[0],fieldDetail[1],fieldDetail[2]));
                    }
                }  
            }
            //dynamicSearch = '';
            system.debug('dynamicSearch criterias' + criterias); 
        }

        for(String s:criterias){
            if(s != '' && s != null){
                system.debug('--------------------------s----------------------- '+ s);
                if(filterCriteria.toUpperCase().contains('WHERE')){
                    filterCriteria += ' AND ' + s;
                }
                else{
                    filterCriteria += ' WHERE ' + s;
                }
            }
        }

        system.debug('Akhilesh --> ' + 'makeQuery =>  filterCriteria' + filterCriteria);    

        return filterCriteria;
    }
    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:criteriaHelper
   Return Type: String
   Arguments: String, String, String
   Description: This method builds the filters in the 'Where' clause for the SOQL query.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    private String criteriaHelper(String fieldName,String fieldType,String value){
        String criteria ='';
        system.debug('---- criteriaHelper -------- fieldName-----------'+ fieldName);
        system.debug('---- criteriaHelper -------- fieldType-----------'+ fieldType);
        system.debug('----- criteriaHelper ------- value-----------'+ value);

        if(value != null && value != ''){
            if(fieldType=='STRING' && fieldName=='ID'){
                criteria = fieldName + ' = \'' + value + '\'';
            }    
            else if(fieldType=='INTEGER'){
                criteria = fieldName + '=' + value;
            }      
            else if(fieldType=='STRING'){
                criteria = fieldName + ' like \'%' + value + '%\'';
            } 
            else if(fieldType=='OTHER'){
                criteria = fieldName + ' like \'%' + value + '%\'';
            }
            else if(fieldType=='BOOLEAN'){
                if(value!='All'){
                    criteria = fieldName + '=' + boolean.valueOf(value);
                }
            }
            else if(fieldType=='DATE'){
                List<String> dateRange = value.split('~');
                if(dateRange.size()>0){
                    List<String> lstFirstDate ;
                    List<String> lstSecondDate ;

                    //making sure to date ranage is present in list if user have not passed
                    if(dateRange.size()==1){
                        dateRange.add('');
                    }

                    //when from date range is given
                    if(dateRange[0] != null && dateRange[0] != ''){
                        lstFirstDate = dateRange[0].split('/');
                        criteria = fieldName + '>=' + lstFirstDate[2] + '-' +lstFirstDate[0] + '-' +lstFirstDate[1];
                        //when to date range is given
                        if(dateRange[1] != null && dateRange[1] != ''){
                            lstSecondDate = dateRange[1].split('/');
                            criteria += ' AND ' + fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1];
                        }
                    }
                    //when from date range is not given handle on to date range
                    else{
                        if(dateRange[1] != null && dateRange[1] != ''){
                            lstSecondDate = dateRange[1].split('/');
                            criteria = fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1];
                        }
                    }
                }
            }
            else if(fieldType=='DATETIME'){
                List<String> dateRange = value.split('~');
                if(dateRange.size()>0){
                    List<String> lstFirstDate ;
                    List<String> lstSecondDate ;

                    //making sure to date ranage is present in list if user have not passed
                    if(dateRange.size()==1){
                        dateRange.add('');
                    }

                    //when from date range is given
                    if(dateRange[0] != null && dateRange[0] != ''){
                        lstFirstDate = dateRange[0].split('/');
                        criteria = fieldName + '>=' + lstFirstDate[2] + '-' +lstFirstDate[0] + '-' +lstFirstDate[1] + 'T00:00:00Z';
                        //when to date range is given
                        if(dateRange[1] != null && dateRange[1] != ''){
                            lstSecondDate = dateRange[1].split('/');
                            criteria += ' AND ' + fieldName + '<=' + lstSecondDate[2] + '-' +lstSecondDate[0] + '-' +lstSecondDate[1] + 'T11:59:59Z';
                        }
                    }
                    //when from date range is not given handle on to date range
                    else{
                        if(dateRange[1] != null && dateRange[1] != ''){
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
    //---------------------------------------------------------------------------//
    //Pagination 
    //---------------------------------------------------------------------------//

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:updatePageSize
   Return Type: void
   Arguments: null
   Description: Sets the page size to user entered value and displys the first page of records.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void updatePageSize(){
        system.debug('Akhilesh --> updatePageSize :ResultsPerPage => ' + ResultsPerPage);
        ssc.setPageSize(resultsPerPage);
        firstPage();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:hasNextPage
   Return Type: Boolean
   Arguments: null
   Description: Returns 'true' if next page present else 'false'.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Boolean hasNextPage{
        get{
            if(currentPage < totalPage){
                return true;
            }else{
                return false;
            }
        }
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:hasPrevPage
   Return Type: Boolean
   Arguments: null
   Description: Returns 'true' if previous page present else 'false'.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Boolean hasPrevPage{
        get{
            if(currentPage > 1){
                return true;
            }else{
                return false;
            }
        }
    }
    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:hasFirstPage
   Return Type: Boolean
   Arguments: null
   Description: Returns 'true' if first page present else 'false'.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Boolean hasFirstPage{
        get{return hasPrevPage;}
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:hasLastPage
   Return Type: Boolean
   Arguments: null
   Description: Returns 'true' if last page present else 'false'.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Boolean hasLastPage{
        get{return hasNextPage;}
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:nextPage
   Return Type: void
   Arguments: null
   Description: Setcontroller Methods are used in this action method to navigate the user to the next page. 
                Prior to navigation the selected records are stored by calling Selected_IB(lstInstallBaseWrapper) method.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void nextPage(){
        ssc.next();
        updatePageView();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:prevPage
   Return Type: void
   Arguments: null
   Description: Setcontroller Methods are used in this action method to navigate the user to the previous page.
                Prior to navigation the selected records are stored by calling Selected_IB(lstInstallBaseWrapper) method.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void prevPage(){
        ssc.previous();
        updatePageView();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:firstPage
   Return Type: void
   Arguments: null
   Description: Setcontroller Methods are used in this action method to navigate the user to the first page.
                Prior to navigation the selected records are stored by calling Selected_IB(lstInstallBaseWrapper) method.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void firstPage(){
        ssc.first();
        updatePageView();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:lastPage
   Return Type: void
   Arguments: null
   Description: Setcontroller Methods are used in this action method to navigate the user to the last page.
                Prior to navigation the selected records are stored by calling Selected_IB(lstInstallBaseWrapper) method.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void lastPage(){
        ssc.last();
        updatePageView();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:goToPage
   Return Type: void
   Arguments: null
   Description: Setcontroller Methods are used in this action method to navigate the user to a specific page.
                Prior to navigation the selected records are stored by calling Selected_IB(lstInstallBaseWrapper) method.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public void goToPage(){
        ssc.setPageNumber(pageNumber);
        updatePageView();
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:totalResults
   Return Type: Integer
   Arguments: null
   Description: returns the number of records in the standard set controlller
     */ 
    //--------------------------------------------------------------------------------------------------------------------------//
    public Integer totalResults {
        get {
            return ssc.getResultSize();
        }
        set;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:currentPage
   Return Type: Integer
   Arguments: null
   Description: returns the page number of the curent page from the standard set controlller
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Integer currentPage{
        get {
            pageNumber = ssc.getPageNumber();
            return pageNumber;
        }
        set;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:showingFrom
   Return Type: Integer
   Arguments: null
   Description: returns the least record number biend displayed on page.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Integer showingFrom {
        get {
            return (ssc.getPageNumber() - 1) * ssc.getPageSize() + 1;
        }
        set;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:showingTo
   Return Type: Integer
   Arguments: null
   Description: returns the max record number biend displayed on page.
     */ 
    //----------------------------------------------------------------------------------------------------------------------------//
    public Integer showingTo {
        get {
            return ssc.getPageNumber() == totalPage ?  totalResults:  ssc.getPageNumber() * ssc.getPageSize();
        }
        set;
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    /* MethodName:totalPage
   Return Type: Integer
   Arguments: null
   Description: returns total number of pages required to disply the records.
     */ 
    //---------------------------------------------------------------------------------------------------------------------------//
    public Integer totalPage {
        get {
            integer pagecount = ssc.getResultSize() / ssc.getPageSize();
            return Math.mod(ssc.getResultSize(),ssc.getPageSize()) > 0 ? pagecount + 1 : pagecount;
        }
        set;
    }



    //----------------------- Start Of Public/Private Methods for Views----------------------------------------------------------//


    private void loadDefaultViewDetail(){

        moreColumns = '';
        for(fieldWrapper fw: dynamicFieldDetails){
            moreColumns += fw.apiName + ',';
        }
        if(moreColumns.length() >1){
            moreColumns = moreColumns.substring(0,moreColumns.length()-1);  
        }
        FixedSearch = '';
        FixedSearchToRestore = '';
        DynamicSearch = '';
        DynamicSearchToRestore = '';
        modifyView();
    }


    public void modifyView(){

        requiredFieldmissing=true;
        List<String> fieldHeaders = new List<String>();
        List<String> fieldAPIs = new List<String>();
        dynamicFieldDetails.clear();
        // more column is coming null need to check lalit
        if(moreColumns != null){
            for(String newCol : moreColumns.split(',')){
                if(dynamicFieldInfo.containsKey(newCol)){
                    List <String> lst = dynamicFieldInfo.get(newCol).split('\\|');
                    String label = lst[0] ;
                    String dataType = lst[1] ;
                    String HelpText = lst[2] ;
                    fieldAPIs.add(newCol);
                    fieldHeaders.add(label);
                    dynamicFieldDetails.add(new fieldWrapper(newCol,label,dataType, HelpText));

                    System.debug('@@@@@@@@newcol'+newcol);  

                    if(newCol=='Name'){

                        requiredFieldMissing=false;
                    } 
                }
            }
        }
        System.debug('dynamicFieldDetails'+dynamicFieldDetails);
        updateDynamicSearch();
        //moreFieldHeaders.clear();
        moreIBFieldAPIs.clear();
        //moreFieldHeaders = fieldHeaders;      
        moreIBFieldAPIs = fieldAPIs;
        doQuery();
        /*if (dynamicFieldDetails.size()!=0){

        modify_lstibdc(dynamicFieldDetails);


        } */
    }


    private void updateDynamicSearch(){
        fetchDefaultColumnMap();
        Set<Integer> nthPosition = new  Set<Integer>();

        String updatedDynamicSearchToRestore = '';
        String updatedDynamicSearch = '';

        System.Debug('@@@@@@@@Inside updateDynamicSearch'+DynamicSearch);
        System.Debug('@@@@@@@@DynamicSearch'+DynamicSearch);
        System.Debug('@@@@@@@@moreColums'+moreColumns);

        if(DynamicSearch != null && DynamicSearch.length()>0){
            if(moreColumns != null){
                for(String newCol : moreColumns.split(',')){

                    System.Debug('@@@@@@@@@@@@@@newCol'+newCol);
                    Integer nPosition = DynamicSearch.indexOf('|'+newCol);
                    nPosition++;
                    System.debug('@@@@@@@@@@@@@@nPosition'+nPosition);
                    System.debug('@@@@@@@@@@@@@@nthPosition'+nthPosition);
                    System.debug('@@@@@@@@@@@@@@nthPosition.contains(nPosition)'+nthPosition.contains(nPosition));

                    // if(nthPosition.contains(nPosition)==False){
                    String sTemp;
                    if(nPosition>=0 && nthPosition.contains(nPosition)==False){
                        sTemp = DynamicSearch.substring(nPosition,DynamicSearch.indexOf('|',nPosition));
                        system.debug('Akhilesh--> updateQuoteDynamicSearch : sTemp-'+sTemp);

                        if(DefaultColumnMap.containskey(+sTemp.substringbefore('.-'))){
                            updatedDynamicSearch += sTemp + '|';
                            updatedDynamicSearchToRestore += sTemp.replaceAll('.*\\.-~>','') + '|';

                            nthPosition.add(nPosition);
                        }
                    }
                    else{
                        updatedDynamicSearchToRestore += '|';
                        nthPosition.add(nPosition);
                    }
                    // }

                }
            }
            //system.debug('Akhilesh--> updateQuoteDynamicSearch : quoteDynamicSearch-'+quoteDynamicSearch);
            system.debug('Akhilesh--> updateQuoteDynamicSearch : updatedDynamicSearch-'+updatedDynamicSearch);
            system.debug('Akhilesh--> updateQuoteDynamicSearch : updatedDynamicSearchToRestore-'+updatedDynamicSearchToRestore);
            DynamicSearchToRestore = updatedDynamicSearchToRestore;
            DynamicSearch = updatedDynamicSearch;
        }
    }

    public void fetchDefaultColumnMap(){

        System.debug('$$$$$$$$$$$$$$$$ Inside fetchDefaultColumnMap');  

        // lstIBDC_IB=new list<IB_DynamicColumns__c>() ;
        lstIBDC_IB=new list<Workflow_DynamicColumns__c>() ;


        //DefaultColumnMap = new Map <String, IB_DynamicColumns__c>();
        DefaultColumnMap = new Map <String, Workflow_DynamicColumns__c>();
        DefaultColumnMap_API = new Map <String, String> ();
        DefaultColumnMap_Type = new Map <String, String> ();
        DefaultColumnMap_DataType = new Map <String, String> ();
        // for(IB_DynamicColumns__c ibdc: [Select Label__c, DataType__c, Help_Text__c, ApiName__c,Type__c, Page_Layout__c From IB_DynamicColumns__c  order By Type__c,ColumnOrder__c  ]){
        for(Workflow_DynamicColumns__c ibdc: [Select Label__c, DataType__c, Help_Text__c, ApiName__c,Type__c, Page_Layout__c From Workflow_DynamicColumns__c  order By Type__c,ColumnOrder__c  ]){

            lstIBDC_IB.add(ibdc);

            DefaultColumnMap.put (ibdc.ApiName__c,ibdc);
            DefaultColumnMap_API.put(ibdc.ApiName__c, ibdc.Label__c);
            DefaultColumnMap_Type.put(ibdc.ApiName__c, ibdc.Type__c);
            DefaultColumnMap_DataType.put(ibdc.ApiName__c, ibdc.DataType__c);

        }
    }

    public void saveCurrentView(){

        System.debug('$$$$$$$$$$$$$$$$ Inside saveCurrentView');  

        // IBCnslViewDetail__c ibcnslVD;
        Workflow_Console_ViewDetail__c ibcnslVD;


        Integer indx = getSelectedCnslViewDetail();

        //system.debug('Akhilesh --> ' + 'saveCurrentView:indx ' + indx);     

        if(indx > -1){

            ibcnslVD = IBlstCnslVD[indx];

            fillCurrentViewDetail(ibcnslVD);     

            try{

                update ibcnslVD;

            }catch(Exception e){

                //system.debug('Akhilesh : Exception in updating cnslViewDetail '+ e);

            }  

        }

        else{

            // ibcnslVD = new IBCnslViewDetail__c ();
            ibcnslVD = new Workflow_Console_ViewDetail__c ();



            ibcnslVD.Name = saveAsViewName;          

            fillCurrentViewDetail(ibcnslVD);

            try{

                insert ibcnslVD;

                saveAsViewName = '';

            }catch(Exception e){

                //system.debug('Akhilesh : Exception in inserting cnslViewDetail '+ e);

            }      

            loadPreviousViewDetails();

            savedViewId = ibcnslVD.Id;

            loadPreviousViewData();

        }

    }

    public void deleteCurrentView(){


        System.debug('$$$$$$$$$$$$$$$$ Inside deleteCurrentView');  

        // IBCnslViewDetail__c ibcnslVD;
        Workflow_Console_ViewDetail__c ibcnslVD;

        Integer indx = getSelectedCnslViewDetail();

        //system.debug('Akhilesh --> ' + 'deleteCurrentView:indx ' + indx); 



        if(indx > -1){

            ibcnslVD = iblstCnslVD[indx];

            try{

                delete ibcnslVD;

            }catch(Exception e){

                //system.debug('Akhilesh : Exception in deleting cnslViewDetail '+ e);

            }

            loadDefaultViewDetail(); 

        }

        loadPreviousViewDetails();

    }





    public void ChangeView(){

        System.debug('$$$$$$$$$$$$$$$$ Inside ChangeView');  

        resetSelections();

        title = 'Asset List';

    }


    public void resetSelections(){

        System.debug('$$$$$$$$$$$$$$$$ Inside resetSelections');  

        selectedView = '';

    }


    //private void fillCurrentViewDetail(IBCnslViewDetail__c ibcnslVD){
    private void fillCurrentViewDetail(Workflow_Console_ViewDetail__c ibcnslVD){

        System.debug('$$$$$$$$$$$$$$$$ Inside fillCurrentViewDetail');  

        System.debug('$$$$$$$$$$$$$$$$ moreColumns' + moreColumns);  

        System.debug('$$$$$$$$$$$$$$$$ userinfo.getUserId()'+userinfo.getUserId());  

        System.debug('$$$$$$$$$$$$$$$$ FixedSearch'+FixedSearch);  

        System.debug('$$$$$$$$$$$$$$$$ FixedSearchToRestore' +FixedSearchToRestore);  

        System.debug('$$$$$$$$$$$$$$$$ DynamicSearch' +DynamicSearch);  

        System.debug('$$$$$$$$$$$$$$$$ DynamicSearchToRestore' +DynamicSearchToRestore);  


        ibcnslVD.Selected_Columns__c = moreColumns;

        ibcnslVD.view_Owner__c = userinfo.getUserId();

        ibcnslVD.fixed_Search_Text__c = FixedSearch;

        ibcnslVD.fixed_Search_Restore_Text__c = FixedSearchToRestore;

        ibcnslVD.dynamic_Search_Text__c = DynamicSearch;

        ibcnslVD.dynamic_Search_Restore_Text__c = DynamicSearchToRestore;
        ibcnslVD.View_Type__c='Dashboard';

    }

    private void initializeFixedColDetails(){
        // Id,Name,Order__c,Status__c,DisplayfilterLogic__c,Evaluation_Rule__c,Execution_Behavior__c

        //Select  Id,Name,Order__c,Status__c,DisplayfilterLogic__c,Evaluation_Rule__c,Execution_Behavior__c  From Rule__c  
        System.debug('$$$$$$$$$$$$$$$$ Inside initializeFixedColDetails');  
        /*lstIBDC.Clear();
                    for(IB_DynamicColumns__c ibdc: [Select Label__c, DataType__c, ApiName__c,Type__c, Page_Layout__c, Help_Text__c From IB_DynamicColumns__c  order By Type__c,ColumnOrder__c ]){
                      lstIBDC.add(ibdc);
                    }*/

        dynamicFieldDetails = new List<fieldWrapper>();
        fixedFieldDetails = new List<fieldWrapper>();
        //fixedFieldDetails.add(new fieldWrapper('Id','Id','STRING', 'Id'));
        fixedFieldDetails.add(new fieldWrapper('Order__c','Order','INTEGER', 'Order'));
        fixedFieldDetails.add(new fieldWrapper('Name','Name','STRING', 'Name'));
        //fixedFieldDetails.add(new fieldWrapper('Version__c' , 'Version' , 'INTERGER' , 'Version'));// Megha
        //fixedFieldDetails.add(new fieldWrapper('Description__c' , 'Description' , 'STRING' , 'Description'));// Megha
        fixedFieldDetails.add(new fieldWrapper('Object__c','Object','STRING', 'Object'));
        //fixedFieldDetails.add(new fieldWrapper('Status__c','Status','STRING', 'Status')); 
        fixedFieldDetails.add(new fieldWrapper('Advance_Workflow__r.Name','Advance_Workflow','STRING', 'Advance_Workflow'));
        //fixedFieldDetails.add(new fieldWrapper('Advance_Workflow__r.Description__c','Advance Workflow Description','STRING', 'Advance Workflow Description'));                    
        fixedFieldDetails.add(new fieldWrapper('Evaluation_Rule__c','Evaluation Rule','STRING', 'Evaluation Rule'));
        fixedFieldDetails.add(new fieldWrapper('Execution_Behavior__c','Execution Behavior','STRING', 'Execution Behavior'));
        fixedFieldDetails.add(new fieldWrapper('DisplayfilterLogic__c','Display Filter Logic','STRING', 'Display Filter Logic'));
        //fixedFieldDetails.add(new fieldWrapper('CSV_Formatted_Criteria__c','CSV Formatted Criteria','STRING', 'CSV Formatted Criteria'));
        //fixedFieldDetails.add(new fieldWrapper('Filter_Logic__c','Filter Logic','STRING', 'Filter Logic'));
        fixedFieldDetails.add(new fieldWrapper('DisplayActions__c','Display Actions','STRING', 'Display Actions')); 
        
        //fixedFieldDetails.add(new fieldWrapper('CSV_Formatted_Actions__c','CSV Formatted Actions','STRING', 'CSV Formatted Actions'));
        /*for(IB_DynamicColumns__c ibdc:lstIBDC){
                        if(ibdc.Type__c=='Fixed'){
                          fixedFieldDetails.add(new fieldWrapper(ibdc.ApiName__c,ibdc.Label__c,ibdc.DataType__c, ibdc.Help_Text__c));
                        }
                        if(ibdc.Type__c=='Dynamic'){        
                          dynamicFieldDetails.add(new fieldWrapper(ibdc.ApiName__c,ibdc.Label__c,ibdc.DataType__c, ibdc.Help_Text__c));
                        }
                      }*/
        System.debug('---------------------fixedFieldDetails---------------------'+fixedFieldDetails);
        // System.debug('---------------------dynamicFieldDetails---------------------'+dynamicFieldDetails);  
        // fixedFieldDetails.add(new fieldWrapper('Name','Serial #','STRING', 'Serial No'));        
    }

    private void initializeDynamicFieldInfoMap(){

        System.debug('$$$$$$$$$$$$$$$$ Inside initializeDynamicFieldInfoMap');  


        dynamicFieldInfo= new map<String,String>();

        //for(IB_DynamicColumns__c ibdc:lstIBDC){
        for(Workflow_DynamicColumns__c ibdc:lstIBDC){
            if(ibdc.Type__c=='Fixed' ||ibdc.Type__c=='Dynamic' ){
                dynamicFieldInfo.put(ibdc.ApiName__c,ibdc.Label__c+'|'+ibdc.DataType__c+'|'+ibdc.Help_Text__c);
            }
        }
    }

    public void initializeDynamicFieldDetails(){

        System.debug('$$$$$$$$$$$$$$$$ Inside initializeDynamicFieldDetails==============='+lstIBDC);  

        dynamicFieldDetails = new List<fieldWrapper>();
        //dynamicFieldDetails.add(new fieldWrapper('Object__c','Object','STRING', 'Object'));

        //  for(IB_DynamicColumns__c ibdc:lstIBDC){
        for(Workflow_DynamicColumns__c ibdc:lstIBDC){
            //if(ibdc.Type__c=='Fixed'){
            if(ibdc.Type__c=='Dynamic'){        
                dynamicFieldDetails.add(new fieldWrapper(ibdc.ApiName__c,ibdc.Label__c,ibdc.DataType__c, ibdc.Help_Text__c));
            }
        }
    }

    private void loadPreviousViewDetails(){


        System.debug('$$$$$$$$$$$$$$$$ Inside loadPreviousViewDetails');  

        IBlstCnslVD.clear();

        //savedViewId='';

        savedViews.clear();

        // savedViews.add(new SelectOption('','---Select View---'));



        for(Workflow_Console_ViewDetail__c ibcvd : [SELECT Id,  Name,  CreatedDate,  
                                                    // for(IBCnslViewDetail__c ibcvd : [SELECT Id,  Name,  CreatedDate,  
                                                    Available_Columns__c, Dynamic_Search_Restore_Text__c, 
                                                    Dynamic_Search_Text__c, Fixed_Search_Restore_Text__c, 
                                                    Fixed_Search_Text__c, Selected_Columns__c, View_Owner__c, Selected_View__c, View_Type__c from Workflow_Console_ViewDetail__c

                                                    Where ( (view_Owner__c = :userinfo.getUserId() And (View_Type__c ='Account Console' OR View_Type__c ='' OR View_Type__c ='Dashboard')) OR Name ='---Select View---')
        order by Name Asc , LastModifiedDate Desc

        ]){

            IBlstCnslVD.add(ibcvd);

            savedViews.add(new SelectOption(ibcvd.id,ibcvd.name));                                                                                        

        }

        loadPreviousView();       

    }                


    private void loadPreviousView(){

        System.debug('$$$$$$$$$$$$$$$$ Inside loadPreviousView');  

        //system.debug('Akhilesh --> ' + 'loadPreviousView: '); 

        //system.debug('Akhilesh --> ' + 'savedViewId: ' + savedViewId); 




        // IBCnslViewDetail__c IBcnslVD;
        Workflow_Console_ViewDetail__c IBcnslVD;

        Integer indx = getSelectedCnslViewDetail();



        //system.debug('Akhilesh --> ' + 'loadPreviousView:indx:  ' + indx);



        if(indx > -1){

            IBcnslVD = IBlstCnslVD[indx];

            moreColumns = IBcnslVD.Selected_Columns__c ;

            //recordType = IBcnslVD.Selected_View__c ;

            FixedSearch = IBcnslVD.fixed_Search_Text__c;

            FixedSearchToRestore = IBcnslVD.fixed_Search_Restore_Text__c;

            DynamicSearch = IBcnslVD.dynamic_Search_Text__c;

            DynamicSearchToRestore = IBcnslVD.dynamic_Search_Restore_Text__c;


            modifyView();

        }

        else{

            loadDefaultViewDetail();

        }

    }

    private Integer getSelectedCnslViewDetail(){

        //system.debug('Akhilesh --> ' + 'getSelectedCnslViewDetail:savedViewId ' + savedViewId); 



        if(savedViewId != null && savedViewId != ''){

            Integer indx = 0;

            Boolean vwFound = false;




            // for(IBCnslViewDetail__c ibcVD : iblstCnslVD){
            for(Workflow_Console_ViewDetail__c ibcVD : iblstCnslVD){

                if(ibcVD.id == savedViewId){

                    vwFound = true;

                    break;

                }

                indx++;       

            }



            if(vwFound){

                return indx;

            }

        }

        return -1;

    }

    private void updateQuery(String qry){

        System.debug('$$$$$$$$$$$$$$$$ Inside updateQuery');  

        system.debug('Akhilesh --> updateQuery :qry => ' + qry);

        //Database.QueryLocator ql = Database.getquerylocator(qry);

        //ssc = new ApexPages.StandardSetController(ql);



        List<Rule__c> IBlst = Database.query(qry);

        if(IBlst.size()>1000){

            moreThan1000 = true;

            IBlst.remove(1000);

        }

        else{

            moreThan1000 = false;

        }



        ssc = new ApexPages.StandardSetController(IBlst);

        ssc.setPageSize(ResultsPerPage);

        ssc.first();

    }

    private void prepareIBList(){

        System.debug('$$$$$$$$$$$$$$$$ Inside prepareIBList');  

        String soql = 'SELECT id ' ;

        soql += ' FROM Rule__c ';



        String whereclause = getFilterCriteria();



        //system.debug('Akhilesh --> ' + 'whereclause ' + whereclause);



        if(whereclause != ''){

            soql += whereclause;

        }

        soql += ' limit 1001';




        updateQuery(soql);

        updateCurrentPage();

    }

    private String addExtraColumnsRequired(String soql){

        System.debug('$$$$$$$$$$$$$$$$ Inside addExtraColumnsRequired');  

        List<String> extraColumnsRequired = new List<String>();

        extraColumnsRequired.add('Advance_Workflow__r.Enabled__c');
        extraColumnsRequired.add('Description__c');
        extraColumnsRequired.add('Filter_Logic__c');

        for(String fld :extraColumnsRequired){

            if(!soql.contains(fld)){

                soql += fld +',';

            }

        }
        System.debug('@@@@@@@@requiredFieldmissing'+requiredFieldmissing);

        if(requiredFieldmissing==true){

            // soql += ',' + 'Name';

        }

        return soql;

    }


    private List<Rule__c> QuerySelectedAssets (Set<ID> ibKeyset ){



        String soql = 'SELECT ' + fieldList_all() + ' FROM Rule__c WHERE id in :ibKeyset ';

        System.debug('soql' +soql);

        return(Database.Query(soql));

    }



    private String fieldList_all(){

        System.debug('$$$$$$$$$$$$$$$$ Inside fieldList_all');  

        String result = '';

        //  for(IB_DynamicColumns__c ibdc :lstIBDC){
        for(Workflow_DynamicColumns__c ibdc :lstIBDC){

            result += ibdc.ApiName__c + ',';

        }

        result = result.substring(0,result.length()-1);

        return result;

    }

    private String fieldList(){


        System.debug('$$$$$$$$$$$$$$$$ Inside fieldList');  

        String result = '';
        /*lstIBDC.clear();

        for(IB_DynamicColumns__c ibdc: [Select Label__c, DataType__c, ApiName__c,Type__c, Page_Layout__c, Help_Text__c From IB_DynamicColumns__c  order By Type__c,ColumnOrder__c ]){
                      lstIBDC.add(ibdc);
                    }
                    fixedFieldDetails = new List<fieldWrapper>();
                    dynamicFieldDetails = new List<fieldWrapper>();
                    for(IB_DynamicColumns__c ibdc:lstIBDC){
                        if(ibdc.Type__c=='Fixed'){
                          fixedFieldDetails.add(new fieldWrapper(ibdc.ApiName__c,ibdc.Label__c,ibdc.DataType__c, ibdc.Help_Text__c));
                        }
                        if(ibdc.Type__c=='Dynamic'){        
                          dynamicFieldDetails.add(new fieldWrapper(ibdc.ApiName__c,ibdc.Label__c,ibdc.DataType__c, ibdc.Help_Text__c));
                        }
                      }*/

        system.debug('--------------- fixedFieldDetails -------------------------'+fixedFieldDetails);
        if(fixedFieldDetails != null && fixedFieldDetails.size()>0){            
            for(fieldWrapper fw :fixedFieldDetails){            
                result += fw.apiName + ',';            
            }
            //result = result.substring(0,result.length()-1);
        }  
        
        system.debug('--------------- Inside fieldList dynamicFieldDetails -------------------------'+dynamicFieldDetails);
        //dynamicFieldDetails.add(new fieldWrapper('Status__c','Status','STRING', 'Status'));
        /*   if(dynamicFieldDetails.size()>0){                      
                    for(fieldWrapper fw :dynamicFieldDetails){

                      result += fw.apiName + ',';

                    }
               result = result.substring(0,result.length()-1);
           } */ 

        //system.debug('Akhilesh --> ' + 'result ' + result);



        for(String newCol : moreIBFieldAPIs){

            if(newCol!='Name'){
                result += ',' + newCol;
            }
        }

        System.debug('@@@@@@@@result1' +result);

        result = addExtraColumnsRequired(result);
        System.debug('@@@@@@@@result2' +result);


        return result;

    }




    private void updateCurrentPage(){

        System.debug('$$$$$$$$$$$$$$$$ Inside updateCurrentPage');  

        if(selectedView == null || selectedView == ''){



            set<Id> ibIds = new set<Id>();

            for(Rule__c ib: (List<Rule__c>)ssc.getRecords()){

                ibIds.add(ib.id);

                //records.add(new ObjectWrapper(quote,moreIBFieldAPIs));

            }

            String soql = 'SELECT ' + fieldList() + ' FROM Rule__c WHERE id in :ibIds ';

            sSOQL = 'SELECT ' + fieldList() + ' FROM Rule__c ' + getFilterCriteria();

            if(doSort && sortField != null && sortField != ''){

                if(isAsc){

                    soql += ' order by ' + sortField + ' ASC ';
                    sSOQL += ' order by ' + sortField + ' ASC ';
                }

                else{           

                    soql += ' order by ' + sortField + ' DESC ';
                    sSOQL += ' order by ' + sortField + ' DESC ';
                }       



                isAsc = previousSortField.equals(sortField)? !isAsc : true;



                previousSortField = sortField;

            }

            else{

                soql += ' order by LastModifiedDate DESC ';
                sSOQL += ' order by LastModifiedDate DESC ';
            }



            system.debug('Akhilesh --> updateCurrentPage :soql => ' + soql);
            system.debug('Akhilesh --> updateCurrentPage :sSOQL => ' + sSOQL);





        }

        //system.debug('Akhilesh --> updateCurrentPage :ssc.getRecords() => ' + ssc.getRecords()); 

    }

    public void loadPreviousViewData(){

        System.debug('$$$$$$$$$$$$$$$$ Inside loadPreviousViewData');  


        //system.debug('Akhilesh --> ' + 'loadPreviousViewData called... '); 

        loadPreviousView();

        //prepareIBList();

    }

    public void initializeIBFieldAPIs(){

        System.debug('$$$$$$$$$$$$$$$$ Inside initializeQuoteFieldAPIs');  

        moreIBFieldAPIs = new List<String>();

        moreIBFieldAPIs.add('Installed_Product_Status__c ');
        moreIBFieldAPIs.add('NAGP_Name__c ');


    }

    public void modify_lstibdc (List<fieldWrapper> dynamicFieldDetails) {

        System.debug('$$$$$$$$$$$$$$$$ Inside modify_lstibdc');  


        System.debug('@@@@@@@@@@@@@@@@@@@@@ Inside modify_lstibdc');

        //lstibdc=new List<IB_DynamicColumns__c> ();

        for( fieldwrapper fw : dynamicFieldDetails){

            if (DefaultColumnMap.get(fw.apiName)!=null) {

                //this.lstibdc.add(DefaultColumnMap.get(fw.apiName));

                System.debug('@@@@@@@@@@@@@@@@@@@@@ Inside modify_lstibdc for loop');

            }

        }


    } 

    public static String getValue(sObject record,String fieldName){
        String[] fields = fieldName.split('\\.');
        Integer index = 0;
        sObject rec = record;
        while(fields.size() != index + 1 ){
            try{
                rec = rec.getSObject(fields[index]);
            }
            catch(Exception e){
            }
            index++;
        }
        String val = '';
        try{
            if(rec != null && rec.get(fields[index]) != null){
                // Map<String, Schema.SObjectField> fieldMap = IB_CNSL_Edit_CTRL_AC.getFieldMap(String.valueOf(rec.getsObjectType()));
                Map<String, Schema.SObjectField> fieldMap = AW_Console_EditController.getFieldMap(String.valueOf(rec.getsObjectType()));
                String dataType = String.valueOf(fieldMap.get(fields[index]).getDescribe().getSoapType());
                val = String.valueOf(rec.get(fields[index]));
                //system.debug('Akhilesh --> datatype: ' + dataType );
                if(dataType == 'DATETIME'){
                    val = DateTime.valueOf(val).format('MM/dd/yyyy hh:mm:ss a');
                }
                else if(dataType == 'DATE'){
                    val = DateTime.valueOf(val).format('MM/dd/yyyy');
                }
            }
        }
        catch(Exception e){
        }
        return val;
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
        public fieldWrapper(String apiName,String label,String dataType, String HelpText , List<String> referenceToList){

            System.debug('$$$$$$$$$$$$$$$$ Inside fieldWrapper constructor');  
            this.apiName = apiName;

            this.label = label;

            this.dataType = dataType;

            this.HelpText = HelpText;
            this.referenceToList = this.referenceToList;

        }

    }

    public class objectWrapper{
        public Rule__c IB {get;set;}
        public List<String> extraFields{get;set;}
        public String id {get;set;}
        public String name {get;set;}
        public objectWrapper(sObject record,List<String> extraColumn){
            //System.debug('Akhilesh --> objectWrapper- extraColumn: ' + extraColumn);
            extraFields = new List<String>();
            if(record.getsObjectType() == Rule__c.sObjectType){
                IB = (Rule__c)record;
            }
            id = (Id)record.get('Id');
            name = (String)record.get('Name');
            for(String colName : extraColumn){
                //System.debug('Akhilesh --> objectWrapper- colName: ' + colName);
                //System.debug('Akhilesh --> objectWrapper- getValue: ' + getValue(record,colName));
                extraFields.add(getValue(record,colName));
            }
        }
    }

    //---------------------------------------------------------------------------------------------------------------------------//
    //Inner Classes to wrap IB records with checkbox boolean type
    //---------------------------------------------------------------------------------------------------------------------------//
    public class InstallBaseWrapper{
        public Rule__c InstallBase {get;set;}
    
        public InstallBaseWrapper(Rule__c ib){
            InstallBase = ib;
        }
        public InstallBaseWrapper(String orederNum , String ruleName , String objectName , String advancedWorkflowName, String evaluation , String execution , String criteria , String displayCriteria , String actions , String displayActions){
            this.orderNum = orderNum;
            this.ruleName = ruleName;
            this.objectName = objectName;
            this.advancedWorkflowName = advancedWorkflowName;
            this.Evaluation = evaluation;
            this.Execution = execution;
            this.Criteria = criteria;
            this.displayCriteria = displayCriteria;
            this.actions = actions;
            this.displayActions = displayActions;
        }
        public String Evaluation {get;set;}     
        public String Execution {get;set;}
        public String Criteria {get;set;}
        public String DisplayCriteria {get;set;}
        public String Actions {get;set;}    
        public String DisplayActions {get;set;}
        public String ruleName{get;set;}
        public String advancedWorkflowName{get;set;}
        public String orderNum{get;set;}
        public String objectName{get;set;}
    }  
}
/**
 * This class contains unit tests for validating the behavior of Apex class AW_ListRules
 
 */
@isTest
private class AW_ListRules_Test {
    static Id accountId;
    static Integer RuleRecCount = 15;
    static List<Rule__c> rules;
    static Advance_Workflow__c plan;
     
    
  static testMethod void testFiltercriteria() {
       rules = prepareTestData();         
        Test.startTest();
            PageReference pageRef = Page.AW_ListRules_VF;
            pageRef.getParameters().put('id', plan.id);
            Test.setCurrentPage(pageRef);
            
            //page open and result sorted by Name asc
            //AW_ListRules.CtrlId=plan.Id;
            AW_ListRules controller = new AW_ListRules(new ApexPages.standardController(plan));
            
            controller.resultsPerPage = 1;
        
   	        controller.getFilterCriteria();
   	        
   	        PageReference reference = controller.showAddRemove();   	           	       
   	        system.assertEquals(reference.getURL(), '/apex/AW_AddRulesToWorkflow_VF?id='+plan.id);
   	        controller.initializeDynamicFieldDetails();
   	        
   	        Account accountTest = new Account(Name = 'TestAccount29102012',Industry='Agriculture');
        	insert accountTest;
   	        List<String> extraColumns = new List<String>();
   	        extraColumns.add('Industry');
   	        String accountIndustry = AW_ListRules.getValue(accountTest, 'Industry');
   	        system.assertEquals(accountIndustry, 'Agriculture');
   	        System.assertEquals(controller.UserType , 'Standard');
			controller.returnPage();
			controller.nextPage();
			controller.prevPage();
			System.assert(controller.totalResults > 0);

   }
   
   @IsTest
   static void testCriteriaHelper(){
   			rules = prepareTestData();  
   			       
        	Test.startTest();
            PageReference pageRef = Page.AW_ListRules_VF;
            pageRef.getParameters().put('id', plan.id);
            Test.setCurrentPage(pageRef);
            
            //page open and result sorted by Name asc
            //AW_ListRules.CtrlId=plan.Id;
            AW_ListRules controller = new AW_ListRules(new ApexPages.standardController(plan));
            //String fieldName, fieldType, Value;
           String filterLogic = controller.getFilterCriteria();
    }
    
    static testMethod void checkApplyFilterAndPageNavigations() {
        rules = prepareTestData();         
        Test.startTest();
            PageReference pageRef = Page.AW_ListRules_VF;
            pageRef.getParameters().put('id', plan.id);
            Test.setCurrentPage(pageRef);
            
            //page open and result sorted by Name asc
            //AW_ListRules.CtrlId=plan.Id;
            AW_ListRules controller = new AW_ListRules(new ApexPages.standardController(plan));
            
            controller.resultsPerPage = 1;
            controller.sortField = 'Name';
            //controller.CtrlId=plan.Id;
            controller.applySorting();
            //verifying total result.It should be number of install base record created
            //system.assertEquals(RuleRecCount, controller.totalResults);
            
            //Sorting desc by name
            controller.applySorting();   
            
            //changed sortby field to Status__c 
            controller.sortField = 'Status__c';
            controller.applySorting(); 
            
            
            //Sorting desc by Asset_Category__c        
            controller.modifyView();
             
            //apply filter
            controller.dynamicSearch = controller.fixedSearch = 'Status__c.-~>STRING.-~>Active|CreatedDate.-~>DateTime.-~>05/23/2013';
            controller.applyFilter();
            
            //verifying total result.It should be number of install base record created
            //system.assertEquals(RuleRecCount, controller.totalResults);
            
            //navigation methods 
            //system.assertEquals(false, controller.hasPrevPage);
            if(controller.hasNextPage){
                controller.nextPage();
            }
            if(controller.hasPrevPage){
                controller.prevPage();
            }
            
            controller.lastPage();
            
            if(controller.hasLastPage){
                controller.lastPage();
            }
            
            //system.assertEquals(false, controller.hasNextPage);
            
            if(controller.hasFirstPage){
                controller.firstPage();
            }
           
            controller.pageNumber = 1;
            controller.goToPage();
                
            if(controller.totalPage > 2){
                controller.pageNumber = 2;
                controller.goToPage();
            }
            
            //change page size
            controller.resultsPerPage = 2;
            controller.updatePageSize();
            
            //verify page size change
            //system.assertEquals(2,controller.lstInstallBaseWrapper.size());
            
            
            //change selectedAsset to All actionable
            controller.selectedAsset = 'All_Actionable_Assets';
            controller.applyFilter();
            
            //verify result.Should be 0 as we have not created any actionable assets
            //system.assertEquals(0,controller.totalResults);
            
            //clear filter
            controller.clearFilter();
            
             //apply filter
          //  controller.dynamicSearch = controller.fixedSearch = 'Hardware_Service_End_Date__c.-~>DATE.-~>01/20/2011~01/20/2012';
           // controller.applyFilter();
            
            //clear filter
            controller.clearFilter();
            
              //apply filter
            //controller.dynamicSearch = controller.fixedSearch = 'Hardware_Service_End_Date__c.-~>DATE.-~>~01/20/2012';
            controller.applyFilter();
            
             //apply filter
            //controller.dynamicSearch = controller.fixedSearch = 'SR_Created_Date__c.-~>DATETIME.-~>01/20/2011~01/20/2012';
            controller.applyFilter();
           
            //clear filter
            controller.clearFilter();
           
            //apply filter
            //controller.dynamicSearch = controller.fixedSearch = 'SR_Created_Date__c.-~>DATETIME.-~>~01/20/2012';
            controller.applyFilter();
            
            //clear filter
            controller.clearFilter();
            
            
            //controller.updateUsageAnalytics();
            
            
             //change selectedAsset to All actionable
            controller.selectedAsset = 'All_Assets';
            controller.applyFilter();
            
            controller.saveCurrentView();
            controller.deleteCurrentView();
            System.assert(controller.showingFrom == 1, 'Original value' + controller.showingFrom);
             System.assert(controller.showingTo == 1, 'Original value' + controller.showingTo);
            /*List<String> extraCols = new List<String>{'Installed_Product_Status__c.Asset_Category__c'};
            AW_ListRules.objectWrapper objectWrapper = new InstallBase_1_AC.objectWrapper(rules.get(0), extraCols);*/
            
            
          
             
          
           
            //controller.returnoppty();
        Test.stopTest();
        
    }
    
    static testMethod void testOtherMethods(){
    	rules = prepareTestData();         
        Test.startTest();
        PageReference pageRef = Page.AW_ListRules_VF;
        pageRef.getParameters().put('id', plan.id);
        Test.setCurrentPage(pageRef);
        
        //page open and result sorted by Name asc
        //AW_ListRules.CtrlId=plan.Id;
        AW_ListRules controller = new AW_ListRules(new ApexPages.standardController(plan));
        
        controller.resultsPerPage = 1;
        AW_ListRules.InstallBaseWrapper testIBW = new AW_ListRules.InstallBaseWrapper('1' , rules.get(0).Name , 'Account' , plan.Name, 'Record is Created' , 'Exit' , 'Account.Name = \'Test\' ' ,  'Account.Name = \'Test\' ' , 'Update OwnerId ' ,'Update OwnerId ');
        controller.getFilterCriteria();
    	AW_ListRules.objectWrapper objectWraper = new AW_ListRules.objectWrapper(rules.get(0) , new List<String>{'Sobject__c'});
    	List<AW_ListRules.FieldWrapper> fieldWrappers = new List<AW_ListRules.fieldWrapper>();
    	controller.modify_lstibdc(fieldWrappers);
    } 
     
    //method to prepare test data records
    static List<Rule__c> prepareTestData(){
        plan = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c =True;
        insert plan;
        
         
        Rule__c rule    =   new Rule__c(Name = 'Rule test1',
                                        Status__c = 'Draft',
                                        Object__c = 'Account', 
                                        Version__c = 1,
                                        Description__c = 'Rule 1 Description',
                                        Evaluation_Rule__c='Record is created or edited'
                                        //,Advance_Workflow__c = advanceWF.id
                                        );
        insert rule;
         
        RuleCriteria__c ruleCriteria    =   new RuleCriteria__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Matching_Type__c='Equals', 
        Matching_Value__c='Apparel', 
        Field_name__c='ID',
        Field_API_Name__c='ID',
        Field_Type__c='STRING');
        insert  ruleCriteria;
        
        RuleCriteria__c ruleCriteria1    =   new RuleCriteria__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Matching_Type__c='Equals', 
        Matching_Value__c='32', 
        Field_name__c='Amount',
        Field_API_Name__c='Amount',
        Field_Type__c='INTEGER');
        insert  ruleCriteria1;
        
        RuleCriteria__c ruleCriteria2    =   new RuleCriteria__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Matching_Type__c='Equals', 
        Matching_Value__c='Apparel', 
        Field_name__c='Amount',
        Field_API_Name__c='Amount',
        Field_Type__c='OTHER');
        insert  ruleCriteria2;
       
        RuleCriteria__c ruleCriteria3    =   new RuleCriteria__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Matching_Type__c='Equals', 
        Matching_Value__c='12/11/2014', 
        Field_name__c='Amount_Date__c',
        Field_API_Name__c='Amount_Date__c',
        Field_Type__c='DATETIME');
        insert  ruleCriteria3;
       
        RuleCriteria__c ruleCriteria4    =   new RuleCriteria__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Matching_Type__c='Equals', 
        Matching_Value__c='12/11/2014', 
        Field_name__c='Amount_Date__c',
        Field_API_Name__c='Amount_Date__c',
        Field_Type__c='DATE');
        insert  ruleCriteria4;
       
       
        
        RuleAction__c ruleAction        =   new RuleAction__c(Rule__c = rule.id,
        Related_Object__c='Account',
        Reference_Id__c=Userinfo.getUserId(),
        Field_Name__c='Industry',
        Field_API_Name__c='Industry',
        Type__c='Update Field',
        Value__c='Apparel',
        Long_Value__c=null,
        Notify_User__c=False,
        Email_Template__c=null
        );
    
         insert ruleAction;
 
        rule.Order__c=10;
        rule.Status__c = 'Active';
        rule.Execution_Behavior__c='Execute and Exit';
        rule.Advance_Workflow__c=plan.id;
        update rule;
        
        Account acc = new Account(Name = 'TestAccount29102012',Industry='Agriculture');
        insert acc;
                                                                                                      
        List<Rule__c> ruleslist = new List<Rule__c>();
       /* for(Integer cnt = 0 ; cnt < RuleRecCount ; cnt ++){
            Rule__c rule = new Rule__c();
            rule.Name='test IB' + cnt;
            rule.Description__c='Isaac Quirke Major Account or Named AND Healthcare AND United States test';
            rule.Object__c='Lead';
            rule.Evaluation_Rule__c='Record is created';
            ruleslist.add(rule);            
        }*/
        //Rule__c rule = new Rule__c(Advance_Workflow__c=plan.Id,Name = 'Test Test Account',Object__c = 'Account', Status__c='Active',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
       
         
        ruleslist.add(rule);
        update ruleslist;
        
       /* List<Workflow_DynamicColumns__c> dynCols = new List<Workflow_DynamicColumns__c>(); 
        Workflow_DynamicColumns__c dynCol = new Workflow_DynamicColumns__c(ApiName__c = 'Account__c', Type__c = 'Fixed');
        Workflow_DynamicColumns__c dynCol1 = new Workflow_DynamicColumns__c(ApiName__c = 'Account__r.City__c', Type__c = 'Dynamic');
        Workflow_DynamicColumns__c dynCol2 = new Workflow_DynamicColumns__c(ApiName__c = 'Name');
        dynCols.add(dynCol);
        dynCols.add(dynCol1);
         dynCols.add(dynCol2); 
        insert dynCols;*/
        List<Workflow_Console_ViewDetail__c> wcvList = new List<Workflow_Console_ViewDetail__c>();
        wcvList.add(new Workflow_Console_ViewDetail__c(view_Owner__c = userinfo.getUserId() , View_Type__c ='Account Console' , Name ='AM' ));
        wcvList.add(new Workflow_Console_ViewDetail__c(view_Owner__c = userinfo.getUserId() , View_Type__c ='Dashboard' , Name ='---Select View---' ));
        insert wcvList;
        
        List<Workflow_DynamicColumns__c> workflowDynamicColumns = new List<Workflow_DynamicColumns__c>();
        workflowDynamicColumns.add(new Workflow_DynamicColumns__c(ApiName__c = 'Id' , ColumnOrder__c = 1, 	DataType__c = 'String' , 	Help_Text__c = 'Id column' , Label__c = 'ID' , Type__c = 'Dynamic'));
      	workflowDynamicColumns.add(new Workflow_DynamicColumns__c(ApiName__c = 'CreatedDate' , ColumnOrder__c = 1, 	DataType__c = 'DataTime' , 	Help_Text__c = 'CreatedDate column' , Label__c = 'CreatedDate' , Type__c = 'Dynamic'));
      	insert workflowDynamicColumns;
      	return ruleslist;
    }
}
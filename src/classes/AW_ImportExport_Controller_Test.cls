//
// (c) 2012 Appirio, Inc.
// AW_ImportExport_Controller_Test                                                     
// Test Class for to parse AdvanceAW_ImportExport_Controller
//
// 24 Apr 2013     Peter Babalis     Original
//  
//
 @isTest
 public with sharing class AW_ImportExport_Controller_Test {
 static Advance_Workflow__c plan;
 static Rule__c rule2;
  
 @isTest
 static void TestescapecharsToch() {
        
        String str = 'ciao&hola';
         AW_ImportExport_Controller.escapecharsTochars(str);
    
    }
 /**
    * Test Export methods
    */
    
   public static testMethod void testXMLexport() {
   PageReference pageRef = Page.AW_ImportExport_VF;
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf',Object__c  = 'Account', Enabled__c=True,Description__c = 'Test Desc');
        insert advanceWF;
        
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
        Field_name__c='Industry',
        Field_API_Name__c='Industry',
        Field_Type__c='Picklist');
        insert  ruleCriteria;
        
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
 
        Values_for_Action_Insert_Record__c va   =   new Values_for_Action_Insert_Record__c(Name='name1',Rule_Action__c=ruleAction.id);
        insert va;
        
         
        rule.Order__c=10;
        rule.Status__c = 'Active';
        rule.Execution_Behavior__c='Execute and Exit';
        rule.Advance_Workflow__c=advanceWF.id;
        update rule;

      //  PageReference pageRef = Page.AW_ImportExport_VF;
        Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', advanceWF.id);
        
        AW_ImportExport_Controller controller = new AW_ImportExport_Controller(); 
        
        // Instantiate a new controller with all parameters in the page
        controller = new AW_ImportExport_Controller(); 
        System.assertEquals(controller.getFileFormatOptions().size() , 2);
        controller.fileFormat ='XML'; 
        controller.option = '1';
        controller.ruleOpt = '1';
        controller.exportProcess();
        
        controller.fileFormat ='XML';
        controller.option = '1';
        controller.ruleOpt = '2';
        controller.exportProcess();
        
        controller.fileFormat ='XML';
        controller.option = '1';
        controller.ruleOpt = '3';
        controller.exportProcess();
        
        controller.fileFormat ='XML';
        controller.option = '0';
        controller.ruleOpt = '2';
        controller.exportProcess(); 
   }   
  /**
    * Test Controller methods
    */
   public static testMethod void testController() {
 	    PageReference pageRef = Page.AW_ImportExport_VF;
   	 	Test.setCurrentPage(pageRef);
   		AW_ImportExport_Controller controller = new AW_ImportExport_Controller();
        controller.option = '0';
        controller.ruleOpt = '2';
        controller.cancel();
        controller.checkAction();
        controller.getRadioOptions();
        controller.getRuleOptions();
        controller.start();
        controller.importProcess();
        
}
  
  
    public static void MyTest() {
          
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf',Object__c  = 'Account', Enabled__c=True,Description__c = 'Test Desc');
        insert advanceWF;
        
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
        Field_name__c='Industry',
        Field_API_Name__c='Industry',
        Field_Type__c='Picklist');
        insert  ruleCriteria;
        
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
 
        Values_for_Action_Insert_Record__c va   =   new Values_for_Action_Insert_Record__c(Name='name1',Rule_Action__c=ruleAction.id);
        insert va;
        
         
        rule.Order__c=10;
        rule.Status__c = 'Active';
        rule.Execution_Behavior__c='Execute and Exit';
        rule.Advance_Workflow__c=advanceWF.id;
        update rule;
        
        
        PageReference pageRef = Page.AW_ImportExport_VF;
        Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', advanceWF.id);
        
        AW_ImportExport_Controller controller = new AW_ImportExport_Controller(); 
        
        // Instantiate a new controller with all parameters in the page
        controller = new AW_ImportExport_Controller();  
        controller.option = '1';
        controller.ruleOpt = '3';
        controller.checkAction();
        controller.getRadioOptions();
        controller.getRuleOptions();
        controller.importProcess();
        controller.exportProcess();
        controller.cancel();
        controller.start();
        
            
        
        
        
    }   
     /**
    * Test Export methods
    */
    
   public static testMethod void testCSVExport() {
   PageReference pageRef = Page.AW_ImportExport_VF;
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf',Object__c  = 'Account', Enabled__c=True,Description__c = 'Test Desc');
        insert advanceWF;
        
        Rule__c rule    =   new Rule__c(Name = 'Rule test1',
                                        Status__c = 'Draft',
                                        Object__c = 'Account', 
                                        Version__c = 1,
                                        Description__c = 'Rule 1 Description',
                                        Evaluation_Rule__c='Record is created or edited'
                                        //,Advance_Workflow__c = advanceWF.id
                                        );
        insert rule;
        
        List<RuleCriteria__c> ruleCriteriaList = new List<RuleCriteria__c>();
        ruleCriteriaList.add( new RuleCriteria__c(Rule__c = rule.id,
						        Related_Object__c='Account',
						        Matching_Type__c='Equals', 
						        Matching_Value__c='Apparel', 
						        Field_name__c='Industry',
						        Field_API_Name__c='Industry',
						        Field_Type__c='Picklist'));
						  
		ruleCriteriaList.add( new RuleCriteria__c(Rule__c = rule.id,
						        Related_Object__c = 'Account',
						        Matching_Type__c = 'Between', 
						        Minimum_Value__c = 'today() - 30d',
						        Maximum_Value__c = 'today() - 30d', 
						        Field_name__c='CreatedDate',
						        Field_API_Name__c='CreatedDate',
						        Field_Type__c='DateTime'));
        insert  ruleCriteriaList;
        
        List<RuleAction__c> ruleActions = new List<RuleAction__c>();
        ruleActions.add(new RuleAction__c(Rule__c = rule.id,
			        Related_Object__c='Account',
			        Field_Name__c='Industry',
			        Field_API_Name__c='Industry',
			        Type__c='Update Field',
			        Value__c='Apparel',
			        Long_Value__c=null));
        ruleActions.add(new RuleAction__c(Rule__c = rule.id,
			        Related_Object__c='Account',
			        Type__c='Send Email',
			        Notify_User__c=False,
					User_Owner_Id__c = UserInfo.getUserId(),
					Email_Template_Folder__c = 'Account Folder',
					EmailTemplateName__c = 'Self-Service New Comment Notification',
					Email_Template__c = '000000000000000'));
					
	    ruleActions.add(new RuleAction__c(Rule__c = rule.id,
			        Related_Object__c='Account',
			        Reference_Id__c=Userinfo.getUserId(),
			        Field_Name__c='OwnerPrioritization',
			        Field_API_Name__c='OwnerPrioritization',
			        Type__c='Update Field'));
		ruleActions.add(new RuleAction__c(Rule__c = rule.id,
			        Related_Object__c='Contact',
			        Type__c='Insert Related Object'));
		insert ruleActions;
		
		List<OwnerPrioritization__c> ownerPrioritizations = new List<OwnerPrioritization__c>();
		ownerPrioritizations.add(new OwnerPrioritization__c(Priority__c = 1, Weight__c = 1 , User_Queue_Group_Id__c = UserInfo.getUserId(),User_Queue_Group__c = UserInfo.getName(),  RuleAction__c = ruleActions.get(ruleActions.size() - 2).id));
		insert ownerPrioritizations;
		
		List<Values_for_Action_Insert_Record__c> valInsertRecordList = new List<Values_for_Action_Insert_Record__c>();
		valInsertRecordList.add(new Values_for_Action_Insert_Record__c(Name ='LastName' , Rule_Action__c = ruleActions.get(ruleActions.size() - 1).id , Value__c = 'Test'));
		insert valInsertRecordList;
		
        rule.Order__c=10;
        rule.Status__c = 'Draft';
        rule.Execution_Behavior__c='Execute and Exit';
        rule.Advance_Workflow__c=advanceWF.id;
        rule.Filter_Logic__c = '1 AND 2';
        update rule;
		
		insertCustomSetting();
      //  PageReference pageRef = Page.AW_ImportExport_VF;
        Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', advanceWF.id);
        ApexPages.currentPage().getParameters().put('Obj', 'Account');
        
        AW_ImportExport_Controller controller = new AW_ImportExport_Controller(); 
        
        // Instantiate a new controller with all parameters in the page
        controller = new AW_ImportExport_Controller(); 
        System.assertEquals(controller.getFileFormatOptions().size() , 2);
        controller.fileFormat ='CSV'; 
        controller.option = '1';
        controller.ruleOpt = '1';
        controller.exportProcess();
        
        controller.fileFormat ='CSV';
        controller.option = '1';
        controller.ruleOpt = '2';
        controller.exportProcess();
        
        controller.fileFormat ='CSV';
        controller.option = '1'; 
        controller.ruleOpt = '3';
        controller.exportProcess();
        
        controller.fileFormat ='CSV';
        controller.option = '0';
        controller.ruleOpt = '2';
        controller.exportProcess(); 
        System.assert([select id from Attachment where parentID = : advanceWF.id ].size() > 0);
   }   
   
      /**
    * Test Export methods
    */
    
   public static testMethod void testCSVImport() {
   		PageReference pageRef = Page.AW_ImportExport_VF;
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf',Object__c  = 'Contact', Enabled__c=True, Description__c = 'Test Desc');
        insert advanceWF;
        
        String csvBody_1 = '"WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","Action"';
        String csvBody_2 = '\n';
        String csvBody_3 = '"Contact Workflow_Test","Contact","How to enter merge values as criteria Contact_test","Test","89","Create,Edit","Exit","( Contact.Email = megh.agar@gmail.com .AND. CrossFormula.Account.Name startswith TEST ) .OR. ( Contact.LastName = Megha .AND. LastModifiedDate BETWEEN today() - 21 TO today() )","<aUpdate:Contact.OwnerId=' + UserInfo.getName() + '/a><aChatterNotification:Account: SendToUser= '+ UserInfo.getName() + '~Message=What do u think of Chatter Notification via AWE  ?/a><aInsert:Contact~LastName=SmithByAWE~Ownerid='+ UserInfo.getName() + '~City={!billingCity}/a><aUpdate:CrossObjectField:Account.Name =TestData/a><aUpdate:OwnerPrioritizationField:Method=Round Robin~User='+UserInfo.getName()+', Weight=1, Priority=2~User=Appirio2  Appirio2, Weight=1, Priority=1~User=Appirio3  Appirio3,Weight=1,Priority=0/a>';
            //<aSendEmail:User=Peter Singh~AdditionalEmails=megh.agar@gmail.com~Folder=LeadFolder~Template=Cloud Order Email EN/a>
            //<aApexJob:ApexClass=AW_ApexJob_ActionSample~InputParam=parent:Industry~OutputParam=desc:description/a>
        
        String csvBody = csvBody_1 + csvBody_2 + csvBody_3;
     	insertCustomSetting();   
        //  PageReference pageRef = Page.AW_ImportExport_VF;
        Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', advanceWF.id);
        
        AW_ImportExport_Controller controller = new AW_ImportExport_Controller(new ApexPages.Standardcontroller(advanceWF)); 
        
        // Instantiate a new controller with all parameters in the page
        controller = new AW_ImportExport_Controller(); 
        System.assertEquals(controller.getFileFormatOptions().size() , 2);
        controller.fileFormat ='CSV'; 
        controller.xmlFile = Blob.valueOf(csvBody);
        controller.isBulkMode = false;
        controller.importProcess();
   }   
   
    /**
    * Test Export methods
    */
    
   public static testMethod void testCSVImportBulk() {
   		PageReference pageRef = Page.AW_ImportExport_VF;
        Advance_Workflow__c advanceWF = new Advance_Workflow__c(Name ='advancewf',Object__c  = 'Contact', Enabled__c=True, Description__c = 'Test Desc');
        insert advanceWF;
        
        String csvBody_1 = '"WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","Action"';
        String csvBody_2 = '\n';
        String csvBody_3 = '"Contact Workflow_Test","Contact","How to enter merge values as criteria Contact_test","Test","89","Create,Edit","Exit","( Contact.Email = megh.agar@gmail.com .AND. CrossFormula.Account.Name startswith TEST ) .OR. ( Contact.LastName = Megha .AND. LastModifiedDate BETWEEN today() - 21 TO today() )","<aUpdate:Contact.OwnerId=' + UserInfo.getName() + '/a><aChatterNotification:Account: SendToUser= '+ UserInfo.getName() + '~Message=What do u think of Chatter Notification via AWE  ?/a><aInsert:Contact~LastName=SmithByAWE~Ownerid='+ UserInfo.getName() + '~City={!billingCity}/a><aUpdate:CrossObjectField:Account.Name =TestData/a><aUpdate:OwnerPrioritizationField:Method=Round Robin~User='+UserInfo.getName()+', Weight=1, Priority=2~User=Appirio2  Appirio2, Weight=1, Priority=1~User=Appirio3  Appirio3,Weight=1,Priority=0/a>';
        
            //<aSendEmail:User=Peter Singh~AdditionalEmails=megh.agar@gmail.com~Folder=LeadFolder~Template=Cloud Order Email EN/a>
            //<aApexJob:ApexClass=AW_ApexJob_ActionSample~InputParam=parent:Industry~OutputParam=desc:description/a>
        
        String csvBody = csvBody_1 + csvBody_2 + csvBody_3;
     	insertCustomSetting();   
        //  PageReference pageRef = Page.AW_ImportExport_VF;
        Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', advanceWF.id);
        
        AW_ImportExport_Controller controller = new AW_ImportExport_Controller(); 
        
        // Instantiate a new controller with all parameters in the page
        controller = new AW_ImportExport_Controller(); 
        System.assertEquals(controller.getFileFormatOptions().size() , 2);
        controller.fileFormat ='CSV'; 
        controller.xmlFile = Blob.valueOf(csvBody);
        Test.StartTest();
        controller.importProcess();
        Test.stopTest();
   }   
   
   private static void insertCustomSetting(){
   		List<AWE_Rule_Action_Mapping__c> aweRuleMappingList = new List<AWE_Rule_Action_Mapping__c>();
		
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Name = 'Action Apex Job Class',  Field_API_Name__c='Apex_Job_Class__c', Field_Name__c='ApexClass', Type__c= 'Execute an Apex Job', Object_Name__c='RuleAction__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Input_Parameters__c', Field_Name__c='InputParam', Name='Action Apex Job InputParam', Type__c='Execute an Apex Job',Object_Name__c='RuleAction__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Output_Parameters__c', Field_Name__c='OutputParam', Name='Action Apex Job OutputParam', Type__c='Execute an Apex Job', Object_Name__c='RuleAction__c'));
		
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Input_Parameters__c', Field_Name__c='Message', Name='Action Chatter Notification Message', Type__c='Chatter Notification', Object_Name__c='RuleAction__c'));
		
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User_Owner_Id__c', Field_Name__c='SendToGroup', Name='Action Chatter Notification to Group', Type__c='Chatter Notification', Object_Name__c='RuleAction__c'));
		
		
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User_Owner_Id__c', Field_Name__c='SendToUser', Name='Action Chatter Notification to User', Type__c='Chatter Notification', Object_Name__c='RuleAction__c'));
		
		
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Priority__c', Field_Name__c='Priority', Name='Action Owner Prioritization Priority', Type__c='OwnerPrioritization', Object_Name__c='OwnerPrioritization__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Weight__c', Field_Name__c='Weight', Name='Action Owner Prioritization Weight', Type__c='OwnerPrioritization', Object_Name__c='OwnerPrioritization__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User_Queue_Group__c', Field_Name__c='User', Name='Action Owner Prioritization User', Type__c='OwnerPrioritization', Object_Name__c='OwnerPrioritization__c'));
		 
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Additional_Emails__c', Field_Name__c='Additional Emails', Name='Action SE Add Email', Type__c='Send Email', Object_Name__c='RuleAction__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='EmailTemplateName__c', Field_Name__c='EmailTemplate', Name='Action SE Email Template', Type__c='Send Email', Object_Name__c='RuleAction__c'));
		aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User_Owner_Id__c', Field_Name__c='User', Name='Action SE User', Type__c='Send Email', Object_Name__c='RuleAction__c'));
		insert aweRuleMappingList; 
   } 
   
 

}
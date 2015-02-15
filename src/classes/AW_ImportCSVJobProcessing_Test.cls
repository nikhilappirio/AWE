/**
 * Test Class for AW_ImportCSVJobProcessing
 */
@isTest
private class AW_ImportCSVJobProcessing_Test {

    static testMethod void testJobProcessing() {
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
        AW_ImportCSVJobProcessing jobProcessingCntrl;
        Test.StartTest();
        Pagereference pageRef1 =  controller.importProcess();
        ApexPages.currentPage().getParameters().put('id' , pageRef1.getParameters().get('id'));
        ApexPages.currentPage().getParameters().put('refRule' , pageRef1.getParameters().get('refRule'));
        ApexPages.currentPage().getParameters().put('JobId' , pageRef1.getParameters().get('JobId'));
        jobProcessingCntrl = new AW_ImportCSVJobProcessing();
        jobProcessingCntrl.jobProcessing();
        Test.stopTest();
        jobProcessingCntrl.jobProcessing();
    }
    
    static testMethod void testActionPoller() {
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
        AW_ImportCSVJobProcessing jobProcessingCntrl;
        Test.StartTest();
        Pagereference pageRef1 =  controller.importProcess();
        ApexPages.currentPage().getParameters().put('id' , pageRef1.getParameters().get('id'));
        ApexPages.currentPage().getParameters().put('refRule' , pageRef1.getParameters().get('refRule'));
         jobProcessingCntrl = new AW_ImportCSVJobProcessing();
        for(Integer i = 0; i < = 51;i++){
       	 jobProcessingCntrl.jobProcessing();
        }
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
        aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User__c', Field_Name__c='User', Name='Action Owner Prioritization User', Type__c='OwnerPrioritization', Object_Name__c='OwnerPrioritization__c'));
        
        aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='Additional_Emails__c', Field_Name__c='Additional Emails', Name='Action SE Add Email', Type__c='Send Email', Object_Name__c='RuleAction__c'));
        aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='EmailTemplateName__c', Field_Name__c='Template', Name='Action SE Email Template', Type__c='Send Email', Object_Name__c='RuleAction__c'));
        aweRuleMappingList.add(new AWE_Rule_Action_Mapping__c(Field_API_Name__c='User_Owner_Id__c', Field_Name__c='User', Name='Action SE User', Type__c='Send Email', Object_Name__c='RuleAction__c'));
        insert aweRuleMappingList;
   }
}
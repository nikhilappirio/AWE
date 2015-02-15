// 
// (c) 2012 Appirio, Inc.
//
//  AW_RuleActionsController_Test                                                     
//
// This class contains test methods for ManageRuleActions class
//
// 10 Oct 2012     Peter Babalis     Original
// 06 Feb 2013     Peter Babalis     Cross Formula and Email Templates (Challenge 2020)
// 25 May 2013      Peter Babalis    HTTP Call outs and Apex class Execution (Challenge 2253,2254)
// 24 Sep 2013     Peter Babalis     Upsert Action (Challenge 2790)
//  
@isTest
public class AW_RuleActionsController_Test{

    public static testMethod void testConstructor(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        Test.startTest();
            AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
            
        Test.stopTest();
        system.assertNotEquals(manageRA.objType,null);
        
    }
    
    public static testMethod void testConstructorNew(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id);
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        Test.startTest();
            AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        Test.stopTest();
        system.assertNotEquals(manageRA.objType,null);
     }   

    public static testMethod void testGetFieldNames(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        ApexPages.currentPage().getParameters().put('parentName','Account');
        Test.startTest();
            manageRA.getFieldNames();
        Test.stopTest();
        system.assertEquals(manageRA.fieldOption.size()>0,true);
    }
   
    public static testMethod void testDisplayQueueUserLookup(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        ApexPages.currentPage().getParameters().put('parentName','Account');
        manageRA.populateFields('Lead');
        Test.startTest();
                       
            manageRA.fieldType='OwnerId';
            manageRA.displayAssignmentPanel();
            
        Test.stopTest();
       
    }
    
    public static testMethod void testDisplayUserLookup(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        ApexPages.currentPage().getParameters().put('parentName','Account');
        manageRA.getFieldNames();       
        Test.startTest();
                
            manageRA.fieldType='OwnerId';
            manageRA.displayAssignmentPanel();
            
        Test.stopTest();
       
    }
    
    
    
    public static testMethod void testSaveRuleAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
    }

    public static testMethod void testSaveRuleLongTextAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Description';
        manageRA.newRuleAction.Field_API_Name__c='textarea';
        manageRA.newRuleAction.Value__c = null;


        manageRA.newRuleAction.Long_Value__c = 'Long Value';
       // manageRA.newRuleAction.Value__c =  manageRA.newRuleAction.Long_Value__c.abbreviate(5,1);
        Test.startTest();
        manageRA.displayAssignmentPanel();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
       // system.assertEquals(page.getURL(),'/'+ruleA.id);
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
        
    }
    
    public static testMethod void testSaveAndNewRuleAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }

       public static testMethod void testSaveAndNewRuleValidateLongTextAction(){

        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Description';
        manageRA.newRuleAction.Value__c = null;

        manageRA.newRuleAction.Long_Value__c = 'Long Value';

        Test.startTest();
        manageRA.displayAssignmentPanel();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }


    
    public static testMethod void testSaveAndNewRuleOwnerUserAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerId';
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c = null;
        manageRA.newRuleAction.Reference_Id__c = userinfo.getuserId();
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }
    
    public static testMethod void testSaveandNewRuleOwnerQueueAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerId';
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c = null;
        Group g = new Group(Name = 'Test acc queue');
        g.Type = 'Queue';
        insert g;
        manageRA.newRuleAction.Reference_Id__c= g.Id;
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }

    
     public static testMethod void testSaveRuleOwnerUserAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerId';
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c = null;
        manageRA.newRuleAction.Reference_Id__c = userinfo.getuserId();
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
      //  system.assertEquals(page.getURL(),'/'+ruleA.id);
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
    }
    
    @isTest
    static void testSelectedRecord(){
    	RuleAction__c ruleA = setupData();    	
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerId';
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c = null;
        manageRA.sobjInstance.put('OwnerId',UserInfo.getUserId());          
        //manageRA.newRuleAction.Reference_Id__c = Userinfo.getUserId();
        manageRA.newRuleAction.Field_Type__c = 'reference';
        manageRA.newRuleAction.Field_API_Name__c = 'OwnerId';
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();        
        List<SelectOption> selectOptionsVF = manageRA.getvfPages();
        List<SelectOption> selectOptionsApex = manageRA.getapexClasses(); 
        manageRA.createRelateRec();
        string expression = 'max(5,10)';        
        manageRA.validateExpressionIfAny(expression, 'reference');
        AW_trgr_RuleActionManager.RULEACTION_FLOW_CONTROLLER = true;   // covering trigger : AW_RuleActionsMain 
        update ruleA;
        Test.stopTest();
      //  system.assertEquals(page.getURL(),'/'+ruleA.id);
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
    	
    }
    
    public static testMethod void testSaveRuleOwnerQueueAction(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerId';
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c = null;
        Group g = new Group(Name = 'Test acc queue');
        g.Type = 'Queue';
        insert g;
        manageRA.newRuleAction.Reference_Id__c= g.Id;
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
        //system.assertEquals(page.getURL(),'/'+ruleA.id);
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
    }
     
    
    public static testMethod void testCreateRelateRec(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        Test.startTest();
        manageRA.createRelateRec();
        Test.stopTest();
        System.assertEquals(1, manageRA.lstInsRelRec.size());
    }
    public static testMethod void testCreateRelateRecLongValue(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Description';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c = null;
        manageRA.newRuleAction.Long_Value__c='testvalue';
        Test.startTest();
        manageRA.createRelateRec();
        Test.stopTest();
        System.assertEquals(1, manageRA.lstInsRelRec.size());
    }
    
    public static testMethod void testDeleteRec(){
        //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='LastName',Type__c='Insert Related Object',Value__c='Test');
        insert ruleAction ;
        
        Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c();
        info.Name = 'LastName';
        info.Value__c = 'Test';
        info.Rule_Action__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'LastName';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.selectedRecordId = 'LastName';
        Test.startTest();
        manageRA.deleteRec();
        Test.stopTest();
        System.assertEquals(0, manageRA.lstInsRelRec.size());
    }
    
    public static testMethod void testSaveActionRelatedObj(){
       // Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='LastName',Type__c='Insert Related Object',Value__c='Test');
        insert ruleAction ;
        
        Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c();
        info.Name = 'LastName';
        info.Value__c = 'Test';
        info.Rule_Action__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'LastName';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.selectedRecordId = 'LastName';
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
       // system.assertEquals(page.getURL(),'/'+ruleAction.id);
         system.assertEquals(page.getURL(),'/'+ruleAction.Rule__c);
        
    }
    
    public static testMethod void testSaveAndNewActionRelatedObj(){
        //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Asset',
                                                            field_name__c='Name',Type__c='Insert Related Object',Value__c='Test');
        insert ruleAction ;
        
        Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c();
        info.Name = 'Name';
        info.Value__c = 'Test';
        info.Rule_Action__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.selectedRecordId = 'Name';
        ApexPages.currentPage().getParameters().put('parentName','asset');
        manageRA.getFieldNames();
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }
    
    public static testMethod void testSaveAndNewActionRelatedObjValidation(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Insert Related Object',Value__c='Test');
        insert ruleAction ;
        
        Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c();
        info.Name = 'FirstName';
        info.Value__c = 'Test';
        info.Rule_Action__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'FirstName';
        manageRA.newRuleAction.Reference_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.selectedRecordId = 'LastName';
        ApexPages.currentPage().getParameters().put('parentName','contact');
        manageRA.getFieldNames();
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(null,page);
        
    }
    
       public static testMethod void testMergeFieldValidation(){
        RuleAction__c ruleA = setupData();
        ruleA .Value__c='\'This is a test\'&{!Owner.Name}';
        update ruleA;
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';        
        manageRA.newRuleAction.Value__c='\'This is a test\'&{!Owner.Name}';
        Test.startTest();
            PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
               
        //List<ApexPages.Message> msgList = ApexPages.getMessages();         
        //System.assertEquals(ManageRuleActions.VALUE_ERROR, msgList[0].getSummary());
  
    }
    
    public static testMethod void testMergeFieldValidationFails(){
        RuleAction__c ruleA = setupData();
        ruleA .Value__c='\'This is a test\'&';
        update ruleA;
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA );
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';        
        manageRA.newRuleAction.Value__c='\'This is a test\'&';
        
        Test.startTest();
            PageReference page = manageRA.saveRuleAction();
            List<ApexPages.Message> msgList = ApexPages.getMessages();         
            System.assertEquals(AW_RuleActionsController.MERGE_ERROR, msgList[0].getSummary());
            manageRA.newRuleAction.Value__c='\'This is a test\'&Account.Name';
            page = manageRA.saveRuleAction();
            
            manageRA.newRuleAction.Value__c='\'This is a test&Account.Name';
            page = manageRA.saveRuleAction();
        Test.stopTest();
               
        
    }
    
    @IsTest(SeeAllData=true)
    public static void tesGetTemplates(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
       
        Test.startTest();
            manageRA.getTemplates();
        Test.stopTest();
               
        //List<ApexPages.Message> msgList = ApexPages.getMessages();         
        //System.assertEquals(ManageRuleActions.VALUE_ERROR, msgList[0].getSummary());
  
    }
    public static testMethod void testBuildEmailOptions(){
        PageReference pageRef = Page.AW_RuleActions_VF;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('sendemailto','User');
        
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        
         Test.startTest();
            manageRA.buildEmailOptionsValues();
            ApexPages.currentPage().getParameters().put('sendemailto','Queue');
            manageRA.buildEmailOptionsValues();
        Test.stopTest(); 
        
    }
    
    @IsTest(SeeAllData=true)
    public static void testSaveSendEmailRuleAction(){
        RuleAction__c ruleA = setupData();
        ruleA.Type__c='Send Email';
        ruleA.User_Owner_Id__c=Userinfo.getUserId();
        ruleA.Email_Template__c=[Select Id FROM EmailTemplate LIMIT 1].Id;
        update ruleA;
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'Name';
        Test.startTest();
        manageRA.getTemplates();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/'+ruleA.Rule__c);
    }
      
    public static RuleAction__c setupData(){
    	//AW_Limit_Handler.createLimitSettings();
        //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Name',Type__c='Update Field',Value__c='Test');
        insert ruleAction ;
        return ruleAction ;
    }
        
    public static testMethod void testSaveActionUpdateLookup(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                    field_name__c='LookupObjectField',Type__c='Update Field',
                                                    field_api_name__c='LookupObjectField',Lookup_Object__c = 'contact',
                                                    Lookup_Field_Name__c = 'Name', Lookup_Field_API_Name__c = 'LastName',
                                                    Field_Type__c = 'string');
        insert ruleAction ; 
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController ruleActionCtrl = new AW_RuleActionsController(stdcon);
        Test.startTest();
        PageReference page = ruleActionCtrl.saveRuleAction();
        Test.stopTest();
        system.assertNotEquals(null,page);
   }
   
   public static testMethod void testSaveActionApexJob(){
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                    field_name__c='Name',Type__c='Execute an Apex Job',
                                                    field_api_name__c='Name',Apex_Job_Class__c = 'abc',
                                                    Field_Type__c = 'string');
        insert ruleAction ; 
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController ruleActionCtrl = new AW_RuleActionsController(stdcon);
        Test.startTest();
        PageReference page = ruleActionCtrl.saveRuleAction();
        Test.stopTest();
        system.assertNotEquals(null,page);
   }
   
    public static testMethod void testCreateOwnerPriorityRec(){
        RuleAction__c ruleA = setupData();
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerPrioritization';
        manageRA.ownerPriority.User_Queue_Group_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        Test.startTest();
        	manageRA.addOwnerPriority();
        Test.stopTest();
        System.assertEquals(1, manageRA.ownerPriorityList.size());
    }
    
     public static testMethod void testCreateOwnerPriorityGroupRec(){
        RuleAction__c ruleA = setupData();
        
        User u=[Select Id,name FROM User WHERE Id=:Userinfo.getUserId()];
        system.runAs(u){
	        Group g = new Group(Name = 'Test acc queue');
	        g.Type = 'Queue';
	        insert g;
	        
	        GroupMember gm = new GroupMember(UserOrGroupId=Userinfo.getUserId(),GroupId=g.Id);
	        insert gm;
	        
	        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleA);
	        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
	        manageRA.fieldType = 'OwnerPrioritization';
	        manageRA.ownerPriority.User_Queue_Group_Id__c=g.Id;
	        manageRA.newRuleAction.Value__c='testvalue';
	        Test.startTest();
	        	manageRA.addOwnerPriority();
	        Test.stopTest();
	        System.assertEquals(1, manageRA.ownerPriorityList.size());
        }
    }
    
    public static testMethod void testSaveOwnerRelatedObj(){
        //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Asset',
                                                            field_name__c='OwnerPrioritization',Field_API_Name__c='OwnerPrioritization',Type__c='Update Field',Value__c='Test');
        insert ruleAction ;
        
        OwnerPrioritization__c info = new OwnerPrioritization__C();
       
        info.User_Queue_Group_Id__c = UserInfo.getUserId();
        info.RuleAction__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerPrioritization';
        manageRA.ownerPriority.User_Queue_Group_Id__c=userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.newRuleAction.Field_Api_Name__c='OwnerPrioritization';
        manageRA.selectedRecordId = info.id;
        ApexPages.currentPage().getParameters().put('parentName','asset');
        manageRA.getFieldNames();
        Test.startTest();
        PageReference page = manageRA.saveRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/'+rule.id);
    }
    
     public static testMethod void testSaveAndNewOwnerRelatedObj(){
        //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Asset',
                                                            field_name__c='OwnerPrioritization',Field_API_Name__c='OwnerPrioritization',Type__c='Update Field',Value__c='Test');
        insert ruleAction ;
        
        OwnerPrioritization__c info = new OwnerPrioritization__c();
       
        info.User_Queue_Group_Id__c = UserInfo.getUserId();
        info.RuleAction__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerPrioritization';
        manageRA.ownerPriority.User_Queue_Group_Id__c=UserInfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        manageRA.newRuleAction.Field_Api_Name__c='OwnerPrioritization';
        manageRA.selectedRecordId = info.id;
        ApexPages.currentPage().getParameters().put('parentName','asset');
        manageRA.getFieldNames();
        Test.startTest();
        PageReference page = manageRA.saveAndNewRuleAction();
        Test.stopTest();
        system.assertEquals(page.getURL(),'/apex/AW_RuleActions_VF');
    }
    
    public static testMethod void testDeleteOwnerPriorityRec(){
       //Rule__c rule = new Rule__c(name='Test Rule Test',object__c='Account');
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule; 
        RuleAction__c ruleAction = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='OwnerPrioritization',Field_API_Name__c='OwnerPrioritization',Type__c='Update Field',Value__c='Test');
        insert ruleAction ;
        
        OwnerPrioritization__c info = new OwnerPrioritization__c();
       
        info.User_Queue_Group_Id__c = UserInfo.getUserId();
        info.RuleAction__c = ruleAction.Id;
        insert info;
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(ruleAction);
        AW_RuleActionsController manageRA = new AW_RuleActionsController(stdcon);
        manageRA.fieldType = 'OwnerPrioritization';
        manageRA.ownerPriority.User_Queue_Group_Id__c=Userinfo.getUserId();
        manageRA.newRuleAction.Value__c='testvalue';
        Test.startTest();
        	manageRA.addOwnerPriority();
        	manageRA.selectedRecordId = info.id;
        	manageRA.deleteOwnerPriority();
        Test.stopTest();
        System.assertEquals(1, manageRA.ownerPriorityList.size());
    }
    
   
}
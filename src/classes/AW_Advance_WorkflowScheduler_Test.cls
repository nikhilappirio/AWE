// 
// (c) 20123 Appirio, Inc.
// AW_Advance_WorkflowScheduler_Test                                                     
// Test class for AW_Advance_WorkflowScheduler
//
// 23 Apr 2013     Peter Babalis 
//  
// 
@isTest
private  class AW_Advance_WorkflowScheduler_Test {
    static Advance_Workflow__c plan;
   // static Rule__c rule;
    static Id ruleactionid;
   // List<ID> ruleactionids = new List<ID>();
    static void setupData() {
        plan = new Advance_Workflow__c(Name = 'Test Test Advance Workflow');
        plan.Object__c  = 'Account';
        plan.Description__c = 'Test Desc';
        plan.Enabled__c =True;
        insert plan;
        
        Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule 1 Description');
        insert rule;
        RuleCriteria__c ruleCriteria = new RuleCriteria__c(rule__c=rule.id,related_object__c='Account',
                                                           Matching_Type__c='Equals', Matching_Value__c='Apparel', field_name__c='Industry',field_API_Name__c='Name',Field_Type__c='Picklist');
        insert ruleCriteria ;
        RuleAction__c ruleaction1 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',Bulk_API__c=True,
                                                            field_name__c='Type',Type__c='Update Field',Value__c='TestUpdate');
    
        insert ruleaction1;
        rule.Status__c = 'Active';
        update rule;
       // List<ID> ruleactionids = new List<ID>();
      //  ruleactionids.add(ruleaction1.id);
        ruleactionid=ruleaction1.Id;
        }
   
    static testMethod void scheduleJobWithoutRecTest() {
      Integer delayTime = 15;
       Integer batchSize =100;
       setupData();
       Account acc1 = new Account(Name='Test123');
       Account acc2 = new Account(Name='Test321');
       insert new List<Account>{acc1,acc2};     
    
        Object_Action_Execution__c ObjActionExec1 = new  Object_Action_Execution__c() ;
        Object_Action_Execution__c ObjActionExec2 = new  Object_Action_Execution__c() ;
       
        ObjActionExec1.Record_Id__c=acc1.id;
        ObjActionExec1.Status__c='New';
        ObjActionExec1.Type__c='Bulk API';
        ObjActionExec1.Value__c=acc1.Name;
     //   ObjActionExec1.Value1__c=acc1.Name;
        ObjActionExec1.Action__c=ruleactionid;
        
         
        
        ObjActionExec2.Record_Id__c=acc2.id;
        ObjActionExec2.Status__c='New';
        ObjActionExec2.Type__c='Bulk API';
       //ObjActionExec2.Value1__c=acc2.Name;
         ObjActionExec2.Value__c=acc2.Name;
        ObjActionExec2.Action__c=ruleactionid;
    
        insert new List<Object_Action_Execution__c>{ObjActionExec1,ObjActionExec2};     
         
             
            DateTime dt=system.now(); 
            DateTime thisTime = dt.addMinutes(delayTime);
             
            integer minute = thisTime.minute();
            integer second = thisTime.second();
            integer hour = thisTime.hour();
            integer year = thisTime.year();
            integer month = thisTime.month();
            integer day = thisTime.day();
            String timeStamp = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
     
         
        Test.startTest();
       // AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now().addMinutes(2),'Account');
       //   AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now(),'Object_Action_Execution__c');
          String cronJobID = System.schedule('New Scheduled Job' + System.now().addMinutes(2),timeStamp, new AW_Advance_WorkflowScheduler('Object_Action_Execution__c',dt,''));
     
     
        System.assertNotEquals(null,[select id from crontrigger]);
     
        Test.stopTest();
        
    }
  
    
    static testMethod void scheduleJobTest() {
       Integer delayTime = 15;
       Integer batchSize =100;
       setupData();
       Account acc1 = new Account(Name='Test123');
       Account acc2 = new Account(Name='Test321');
       insert new List<Account>{acc1,acc2};     
    
        Object_Action_Execution__c ObjActionExec1 = new  Object_Action_Execution__c() ;
        Object_Action_Execution__c ObjActionExec2 = new  Object_Action_Execution__c() ;
       
        ObjActionExec1.Record_Id__c=acc1.id;
        ObjActionExec1.Status__c='New';
        ObjActionExec1.Type__c='Bulk API';
     //   ObjActionExec1.Value1__c=acc1.Name;
          ObjActionExec1.Value__c=acc1.Name;
        ObjActionExec1.Action__c=ruleactionid;
        
         
        
        ObjActionExec2.Record_Id__c=acc2.id;
        ObjActionExec2.Status__c='New';
        ObjActionExec2.Type__c='Bulk API';
    //    ObjActionExec2.Value1__c=acc2.Name;
          ObjActionExec2.Value__c=acc2.Name;
        ObjActionExec2.Action__c=ruleactionid;
    
        insert new List<Object_Action_Execution__c>{ObjActionExec1,ObjActionExec2};     
         
             
            DateTime dt=system.now(); 
            DateTime thisTime = dt.addMinutes(delayTime);
             
            integer minute = thisTime.minute();
            integer second = thisTime.second();
            integer hour = thisTime.hour();
            integer year = thisTime.year();
            integer month = thisTime.month();
            integer day = thisTime.day();
            String timeStamp = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
     
         
        Test.startTest();
       // AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now().addMinutes(2),'Account');
       //   AW_AdvanceWorkflowExecutionHelper.StartAWSchedular(System.now(),'Object_Action_Execution__c');
          String cronJobID = System.schedule('New Scheduled Job' + System.now(),timeStamp, new AW_Advance_WorkflowScheduler('Object_Action_Execution__c',dt,''));
     
     
        System.assertNotEquals(null,[select id from crontrigger]);
     
        Test.stopTest();
        
    }
}
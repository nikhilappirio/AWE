// 
// (c) 2012 Appirio, Inc.
//
//  AW_AdvanceWorkflowExecutionEngine_Test                                                    
//
// This class contains test methods for AW_AdvanceWorkflowExecutionEngine class and AW_OwnerPrioritizationHelper class
//
// 10 Oct 2012     Peter Babalis     Original
// 07 Feb 2013     Peter Babalis     Added Cross Fields, tasks and emails
// 24 Sep 2013     Peter Babalis     Added Upsert
// 31 Dec 2013     Peter Babalis     Improved Test Coverage
// 26 March 2013   Peter Babalis     Improved Test Coverage

@IsTest
public class AW_AdvanceWorkflowExecutionEngine_Test{
   static Advance_Workflow__c plan;
    	  @IsTest
          static void testRuleExecutionOwnerPriortization(){
       
               Map<Id,RuleAction__c> ownerPriorityRecs = new Map<Id,RuleAction__c>();
              Set<Id> ruleIds =new Set<Id>();
              List<User> users = new List<User >();
              Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
             
                User u1 = new User(alias = 'usr1', email='user1@acme.com', 
                    emailencodingkey='UTF-8', firstname='fn1',lastname='ln11', 
                    languagelocalekey='en_US', 
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', 
                    username='user1@pao.com');
                users.add(u1);
                 
              User u2 = new User(alias = 'usr2', email='user2@acme.com', 
                    emailencodingkey='UTF-8', firstname='fn2',lastname='ln12', 
                    languagelocalekey='en_US', 
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', 
                    username='user2@pao.com');    
               users.add(u2);     
               
              User u3 = new User(alias = 'usr3', email='user3@acme.com', 
                    emailencodingkey='UTF-8', firstname='fn3',lastname='ln13', 
                    languagelocalekey='en_US', 
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', 
                    username='user3@pao.com');    
               users.add(u3);
              insert users;
                           
         
              Rule__c rule =setupRules();
              
               
               RuleAction__c action = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            Value__c=u1.id,Field_Name__c='OwnerId',Type__c='Update Field',Prioritization_Method__c='Round Robin');
               insert action;
               
               
              // List<RuleAction__c> actions = new List<RuleAction__c>();
       
              // actions=[select id,Name,Type__c,Related_Object__c from RuleAction__c where Rule__c=:Rule.id];
       
              //now create RoundRobin Data :-
              
              List<OwnerPrioritization__c> ownerpriortizations = new List<OwnerPrioritization__c >();
       
             
              OwnerPrioritization__c ownrpr1 = new OwnerPrioritization__c(Assigned__c=0,Percent__c=0.00,Priority__c=1,User_Queue_Group_Id__c=u1.id, User_Queue_Group__c='User1', RuleAction__c = action.Id,Weight__c=1);
              ownerpriortizations.add(ownrpr1);
              OwnerPrioritization__c ownrpr2 = new OwnerPrioritization__c(Assigned__c=0,Percent__c=0.00,Priority__c=2,User_Queue_Group_Id__c=u2.id,User_Queue_Group__c='User2' ,RuleAction__c = action.Id,Weight__c=1);
              ownerpriortizations.add(ownrpr2);
              OwnerPrioritization__c ownrpr3 = new OwnerPrioritization__c(Assigned__c=0,Percent__c=0.00,Priority__c=3, User_Queue_Group_Id__c=u3.id, User_Queue_Group__c='User3', RuleAction__c = action.Id,Weight__c=1);
              ownerpriortizations.add(ownrpr3);
              insert ownerpriortizations;
              rule.Advance_Workflow__c = plan.id;
              update rule;
      		
      		  system.debug('--> OwnerPriorit.action  '+action);
              ruleIds.add(rule.id);
             
              AW_OwnerPrioritizationHelper.getOwnerPrioritizationRecords(ruleIds);
               
             
              String val =  AW_OwnerPrioritizationHelper.assign_basedonRoundRobin(action);
            // String val =  AW_OwnerPrioritizationHelper.assign_basedonWeightedCalculation(action);
             
      		  Account a = new Account(Name='Test',AnnualRevenue=2000.0,Industry='Agriculture',Type='Other');
       	      
       	      system.debug('--> rule '+rule);
              system.debug('--> action  '+action);
            //  system.debug('->actions '+actions);
              system.debug('ownerpriortizations '+ownerpriortizations);
              system.debug('ownerpriortizations val '+val);
               
              Test.startTest();
       		  insert a;    
              //get the account:-
              a=[Select Id,OwnerId  ,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
      
              system.debug('OwnerId '+a.OwnerId);
              system.assertNotEquals('Test', a.OwnerId);
               Test.stopTest();
              
    }
    
    @IsTest
    static void testRuleExecutionBasedonWeightedCalculation(){
       		  
       		  Assignment_Setup__c setup = new Assignment_Setup__c(
       		  	Priority_Divisor__c = 1, 
       		  	Number_Of_Weight__c = 1,
       		  	Name = 'Assignment_Setup' 
       		  );
       		  insert setup;
       		  
              Map<Id,RuleAction__c> ownerPriorityRecs = new Map<Id,RuleAction__c>();
              Set<Id> ruleIds =new Set<Id>();
              List<User> users = new List<User >();
              Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
              User u1 = AW_TestUtil.createUser('user1@pao.com', 'user1@acme.com', 'fn1', 'ln11', 'usr1', p.Id, false);
              users.add(u1);
              User u2 = AW_TestUtil.createUser('user2@pao.com', 'user2@acme.com', 'fn2', 'ln12', 'usr2', p.Id, false);
              users.add(u2);
              User u3 = AW_TestUtil.createUser('user3@pao.com', 'user3@acme.com', 'fn3', 'ln13', 'usr3', p.Id, false);
              users.add(u3);
              insert users;
         
              Rule__c rule =setupRules();
              
              RuleAction__c action = AW_TestUtil.createRuleAction(rule, 'Account', false, 'OwnerId', 'Update Field', u1.id, false);
              action.Prioritization_Method__c='Round Robin';
              insert action;
              
              List<OwnerPrioritization__c> ownerpriortizations = new List<OwnerPrioritization__c >();
             
              OwnerPrioritization__c ownrpr1 = AW_TestUtil.createOwnerPrioritization(1, 1, 1, 1, u1.id, 'User1', action.Id, false);
              ownerpriortizations.add(ownrpr1); 
              OwnerPrioritization__c ownrpr2 = AW_TestUtil.createOwnerPrioritization(1, 1, 1, 2, u2.id, 'User2', action.Id, false);
              ownerpriortizations.add(ownrpr2); 
              OwnerPrioritization__c ownrpr3 = AW_TestUtil.createOwnerPrioritization(1, 1, 1, 3, u3.id, 'User3', action.Id, false);
              ownerpriortizations.add(ownrpr3);
              insert ownerpriortizations;
              rule.Advance_Workflow__c = plan.id;
              update rule;
      		
              ruleIds.add(rule.id);
             
              Test.startTest(); 
              AW_OwnerPrioritizationHelper.getOwnerPrioritizationRecords(ruleIds);
              	String val =  AW_OwnerPrioritizationHelper.assign_basedonWeightedCalculation(action);
              	System.assertEquals(val, u3.id);
              Test.stopTest();
    }
  		@IsTest
        static void testStartRuleProcessing() {
        
        List<SObject> listSObjects = new List<SObject>();
        Advance_Workflow__c wfToInsert = AW_TestUtil.createWorkflow( 'WFAccount', 'Account', true,  'WF Description',true);
        
        Rule__c ruleToInsert = AW_TestUtil.createRule('Test Rule1', 'Account', 'Draft', 'Record is created', 'Rule 1 Description', false);
        Rule__c ruleToUpdate = AW_TestUtil.createRule('Test Rule2', 'Account', 'Draft', 'Record is created or edited', 'Rule 2 Description', true);
        ruleToInsert.Advance_Workflow__c = wfToInsert.id;
	    ruleToUpdate.Advance_Workflow__c = wfToInsert.id;
	     
        
        listSObjects.add(ruleToInsert);
        listSObjects.add(ruleToUpdate);
        
        
             
        Set<Id> Ids=new Set<Id>();
        String sobjName='Account';
        Account acc1 = AW_TestUtil.createAccount('Test Account1', false);
        Account acc2 = AW_TestUtil.createAccount('Test Account2', false);
        insert new List<Account>{acc1,acc2};     
        List<Account> accs = new List<Account>();
        accs.add(acc1);
        accs.add(acc2);
        
         
        Ids.add(acc1.Id);
        Ids.add(acc2.Id);
       
       Map<Id,List<SObject>> validRecords = new Map<Id,List<SObject>>();
       Map<Id, SObject> toUpdateSObject= new Map<Id, SObject> ();
       String qrySOQL= 'select id from Account WHERE Id IN : Ids';
      List<SObject> recordBeforeUpdate = Database.query(qrySOQL);
      toUpdateSObject.put(acc1.Id,acc1);
       
       
       validRecords.put(ruleToInsert.id, accs);
       recordBeforeUpdate = Database.query(qrySOQL);
       //Boolean result = AW_AdvanceWorkflowTransactionProcessing.addRecordstoExecutionHistory(listSObjects,validRecords,recordBeforeUpdate,toUpdateSObject);
         
        Test.startTest();
        	AW_AdvanceWorkflowExecutionEngine.startRulesProcessing(Ids,sobjName,false);
        	
         	system.assertEquals(Ids.size(),2);
             	List<Rule_Execution_History__c> ruleExecutionHistory = [SELECT Id FROM Rule_Execution_History__c WHERE Rule__c =:ruleToInsert.Id];
     	    system.assertEquals(ruleExecutionHistory.size(), 0, 'Should have 1 rule execution history record.');
     	
         	  
        Test.stopTest();
    }
      @IsTest
       static void testRuleExecutionTrue(){
        Rule__c rule = setupRules();
    
    
          //now create account :-
          Account a = new Account(Name='Test',AnnualRevenue=2000.0,Industry='Agriculture');
          
          Test.startTest();
              insert a;    
               //get the account:-
              a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
              system.assertEquals('Test', a.Name);
              system.assertEquals(2000, a.AnnualRevenue);
              
              //this will not evaluate rule as it has already been executed once
              a.AnnualRevenue = 500.0;
              update a; 
              
              a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
              //system.assertEquals('Test', a.Name);
              //system.assertEquals(2000, a.AnnualRevenue);
             //system.assertNotEquals(0, [select id from contact where accountid =: a.Id].size());                                             
          Test.stopTest();
  
        }                
         @IsTest
         static void testRuleExecutionCondition2(){
              Rule__c rule = setupRules();
              
              RuleCriteria__c c1 = new RuleCriteria__c(rule__c=rule.id);
              c1.Field_API_Name__c='FirstName';
              c1.Field_Type__c='String';
              c1.Matching_Type__c='Equals';
              c1.Matching_Value__c='test';
              c1.Related_Object__c='Contact';
               
              insert c1;
              
              RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
              insert a1;
              
              rule.Filter_Logic__c='1 AND (2 OR 3) AND 4';
              update rule;
              
              
              //now create account :-
              Account a = new Account(Name='shuld be test',AnnualRevenue=2000.0,Industry='Agriculture');
              insert a;
              
              Contact c = new Contact(FirstName='test',LastName='contact',AccountId=a.Id);
              insert c;
              

              //get the account:-
              a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
              system.assertEquals('shuld be test', a.Name);
              system.assertEquals(2000, a.AnnualRevenue); 
              Test.startTest(); 
                  //this will not evaluate rule as it has already been executed once
                  a.Industry = 'Agriculture';
                  update a; 
                  
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  //system.assertEquals('Test', a.Name);
                  system.assertEquals(2000, a.AnnualRevenue);
                  system.assertEquals('shuld be test', a.Name);
                  //system.assertEquals(500, a.AnnualRevenue);
                 
                  c =[Select Id,FirstName FROM Contact WHERE Id=:c.Id];
                 //system.assertEquals('TestUpdate', c.FirstName);
                  system.assertEquals('test', c.FirstName);
                                             
              Test.stopTest();
      
         }
     	 @IsTest
         static void testRuleExecutionCrossFormula(){
              Rule__c rule =setupRules();
             
              RuleCriteria__c c1 = new RuleCriteria__c(rule__c=rule.id);
              c1.Field_API_Name__c='Industry';
              c1.Field_Type__c='String';
              c1.Matching_Type__c='Equals';
              c1.Matching_Value__c='Agriculture';
              c1.Related_Object__c='Contact';
               
              insert c1;
              
              RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='FirstName',Type__c='Update Field',Value__c='TestUpdate');
    
              insert a1;
              
              RuleAction__c a2 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='Description',Type__c='Update Field',Value__c='\'Merge Field Update\'&{!Account.Name}');
    
              insert a2;
              
              rule.Filter_Logic__c='1 AND (2 OR 3) AND 4';
              update rule;
              
               
              
              
              //now create account :-
              Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture');
              insert a;
              
              Contact c = new Contact(FirstName='test',LastName='contact',AccountId=a.Id);
              insert c;
              

              //get the account:-
              a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
              system.assertEquals('shuld be test', a.Name);
              system.assertEquals(500, a.AnnualRevenue); 
              Test.startTest(); 
                  //this will not evaluate rule as it has already been executed once
                  a.Industry = 'Agriculture';
                  update a; 
                  
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('shuld be test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);
                  
                  c =[Select Id,FirstName,Description FROM Contact WHERE Id=:c.Id];
                  system.assertEquals('test', c.FirstName);
                  //system.assertEquals('Merge Field Update shuld be test', c.Description );                           
              Test.stopTest();
      
         } 
         @IsTest
        static void testRuleExecutionCrossObjectFieldUpdate(){
              Rule__c rule =setupRules();

              RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Type',Type__c='Update Field',Value__c='Prospect');
    
              insert a1;
              

              rule.Filter_Logic__c='1 AND (2 OR 3)';
              update rule;

             
              Test.startTest(); 
                   //now create account :-
                   Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture',Type='Other' );
                   insert a;                        
              Test.stopTest();
      
         }  
         
         @IsTest
         static void testRuleExecutionSendEmailAction(){
              Rule__c rule =setupRules();
              
              RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            field_name__c='Type',Type__c='Send Email',User_Owner_Id__c=UserInfo.getUserId(),Email_Template__c='1111111');
    
              insert a1;
               Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
             
                
                User u = new User(alias = 'jsmtih', email='jsmith@acme.com', 
                    emailencodingkey='UTF-8', lastname='Smith', 
                    languagelocalekey='en_US', 
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', 
                    username='5589243470@acme.com');
              system.runAs(u){
                  Group g=new Group(name='test');
                  insert g;
                  
                  GroupMember gm=new GroupMember (UserorGroupId=UserInfo.getUserId(),GroupId=g.Id);
                  insert gm;
                  
                  RuleAction__c a2 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                                field_name__c='Type',Type__c='Send Email',User_Owner_Id__c=g.Id,Email_Template__c='1111111');
        
                  insert a2;
                  
    
                  rule.Filter_Logic__c='1 AND (2 OR 3)';
                  update rule;
    
                 
                  Test.startTest(); 
                       //now create account :-
                       Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture' );
                       insert a;                        
                  Test.stopTest();
              }
         }  
         
        @IsTest
        static void testRuleExecutionFalse(){
              setupRules();
              
              //now create account :-
              Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Mining');
              
              Test.startTest();
                  insert a;    
                   //get the account:-
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('shuld be test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);                              
              Test.stopTest();
      
       }
       @IsTest  
       static void testSort(){
             List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('US','US'));
            options.add(new SelectOption('CANADA','Canada'));
            options.add(new SelectOption('MEXICO','Mexico'));
            AW_AdvanceWorkflowExecutionHelper.sortSelectListOnLabel(options );
        }
        
        @IsTest
        static  void testConvertDateMethod(){
            AW_CriteriaEvaluationComparisonHelper.convertToDate('2/11/2012');
            AW_CriteriaEvaluationComparisonHelper.convertToDate('21/11/2012');
            AW_CriteriaEvaluationComparisonHelper.convertToDate('2021/11/20');
        }
        
         
         //updated SH
        public  static Rule__c setupRules(){
               List<RuleCriteria__c> criteria = new List<RuleCriteria__c>();
               List<RuleAction__c> actions = new List<RuleAction__c>();
               
                
               
             
               Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Draft',Evaluation_Rule__c='Record is created or edited',Description__c='Rule Description');
               insert rule; 
               
               RuleCriteria__c c1 = new RuleCriteria__c(rule__c=rule.id);
               c1.Field_API_Name__c='Industry';
               c1.Field_Type__c='Picklist';
               c1.Matching_Type__c='Equals';
               c1.Matching_Value__c='Agriculture';
               c1.Related_Object__c='Account';
               criteria.add(c1);
               
               RuleCriteria__c c2 = new RuleCriteria__c(rule__c=rule.id);
               c2.Field_API_Name__c='AnnualRevenue';
               c2.Field_Type__c='Currency';
               c2.Matching_Type__c='Greater Than';
               c2.Matching_Value__c='1000';
               c2.Related_Object__c='Account';
               criteria.add(c2);
               
               RuleCriteria__c c3 = new RuleCriteria__c(rule__c=rule.id);
               c3.Field_API_Name__c='CreatedDate';
               c3.Field_Type__c='Date';
               c3.Matching_Type__c='Greater Than';
               c3.Matching_Value__c= '6/12/2013';
               c3.Related_Object__c='Account';
               criteria.add(c3);
                        
               insert criteria;
               
               //create action
               
               RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Name',Type__c='Update Field',Value__c='Test');
              
               actions.add(a1);
               
               RuleAction__c a2 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='AnnualRevenue',Type__c='Update Field',Value__c='2000');
               actions.add(a2);
                        
               // By CC
               RuleAction__c a3 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='OwnerId',Type__c='Update Field',Value__c=userinfo.getUserId(),Notify_User__c = true);
               actions.add(a3);
               
               RuleAction__c a4 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            Type__c='Insert Related Object');
               actions.add(a4);
               
               RuleAction__c a5 = new RuleAction__c(rule__c=rule.id,related_object__c='Attachment',
                                                            Type__c='Insert Related Object');
               actions.add(a5);
              
               RuleAction__c a6 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Phone',Type__c='Update Field',Value__c='Owner.Phone');
               actions.add(a6);
               
               RuleAction__c a7 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Description',Type__c='Update Field',Long_Value__c='Test content');
               actions.add(a7);
              
               // Cloud challenger
               //RuleAction__c a8 = new RuleAction__c(rule__c=rule.id,related_object__c='Integration__c',
              //                                              Type__c='Upsert Related Object');
               
               //actions.add(a8);
               insert actions;
               
               List<Values_for_Action_Insert_Record__c> infos = new List<Values_for_Action_Insert_Record__c>();
               
               Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c(Value__c = 'LastName', Rule_Action__c = a4.Id, Name = 'LastName');
               
               infos.add(info);
               
               Values_for_Action_Insert_Record__c info2 = new Values_for_Action_Insert_Record__c(Value__c = 'Name', Rule_Action__c = a4.Id, Name = 'FirstName');
               
               infos.add(info2);
               
               Values_for_Action_Insert_Record__c info3 = new Values_for_Action_Insert_Record__c(Value__c = '12345', Rule_Action__c = a5.Id, Name = 'Body');
               
               infos.add(info3);
               
               Values_for_Action_Insert_Record__c info4 = new Values_for_Action_Insert_Record__c(Value__c = 'testtxt', Rule_Action__c = a5.Id, Name = 'Name');
               
               infos.add(info4);
              
                // Cloud challenger
               //Values_for_Action_Insert_Record__c info5 = new Values_for_Action_Insert_Record__c(Value__c = 'testtype', Rule_Action__c = a8.Id, Name = 'type__c');
               
               //infos.add(info5);
                          
               insert infos;
               
               rule =[Select Id,  Status__c,Filter_Logic__c FROM Rule__c WHERE Id=:rule.Id];
               //rule.Enabled__c=true;
               //By CC
               //rule.Available__c  = true;
               rule.Status__c='Active';
               rule.Evaluation_Rule__c='Record is created or edited and did not previously meet the rule criteria';
               rule.Filter_Logic__c='1 AND (2 OR 3)';
               update rule;
               
               List<Advance_Workflow__c> wfplan=[Select Id FROM Advance_Workflow__c WHERE Object__c='Account'];
               
               if(wfplan.size()==0){
                plan= new Advance_Workflow__c(Name = 'Test Test Plan');
                plan.Object__c  = 'Account';
                plan.Description__c = 'Test Desc';
                plan.Enabled__c = true;
                plan.CountRulesassociatedtoAdvanceWorkflow__c=1;
                insert plan;
               }else plan=wfplan[0];
               
               rule.Advance_Workflow__c = plan.id;
               update rule;
               
            //plan.Enabled__c = true;
            //update plan;
               
               return rule;
         }                                   
         @IsTest
         static void testRuleExecutionTrueChangedFromTo(){
              Rule__c rule = setupRules();
              RuleCriteria__c c3 = new RuleCriteria__c(rule__c=rule.id);
               c3.Field_API_Name__c='Name';
               c3.Field_Type__c='String';
               c3.Matching_Type__c='ChangedFromTo';
               c3.Matching_Value__c = 'shuld be test,test';
               c3.Related_Object__c='Account';
                insert c3;         
                
              rule.Filter_Logic__c += ' AND 4';
              update rule;
                              
              //now create account :-
              Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture');
              
              Test.startTest();
                  insert a;    
                   //get the account:-
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('shuld be test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);
                  
                  //this will not evaluate rule as it has already been executed once
                  a.AnnualRevenue = 500.0;
                  a.Name = 'test';
                  update a; 
                  
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);
                 //system.assertNotEquals(0, [select id from contact where accountid =: a.Id].size());                                             
              Test.stopTest();
      
         }
         @IsTest
         static void testRuleExecutionTrueIsChanged(){
              Rule__c rule = setupRules();
              RuleCriteria__c c3 = new RuleCriteria__c(rule__c=rule.id);
               c3.Field_API_Name__c='Name';
               c3.Field_Type__c='String';
               c3.Matching_Type__c='IsChanged';
               c3.Matching_value__c='oldvalue,newvalue';
               c3.Related_Object__c='Account';
                insert c3;         
                
              rule.Filter_Logic__c += 'AND 4';
              update rule;
                              
              //now create account :-
              Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture');
              
              Test.startTest();
                  insert a;    
                   //get the account:-
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('shuld be test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);
                  
                  //this will not evaluate rule as it has already been executed once
                  a.AnnualRevenue = 500.0;
                  a.Name = 'Test';
                  update a; 
                  
                  a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
                  system.assertEquals('Test', a.Name);
                  system.assertEquals(500, a.AnnualRevenue);
                 //system.assertNotEquals(0, [select id from contact where accountid =: a.Id].size());                                             
              Test.stopTest();
      
         }
         
    //Cloud challenger
    @IsTest
    static  void testRuleExecutionUpsertTest(){
        Rule__c rule = setupRules();
        //now create account :-
        Account a = new Account(Name='Test',AnnualRevenue=2000.0,Industry='Agriculture');
        Test.startTest();
        insert a;    
        //get the account:-
        a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
        system.assertEquals('Test', a.Name);
        system.assertEquals(2000, a.AnnualRevenue);
        Test.stopTest();
    }
  
      
    @IsTest       
    static void testDateExpression(){
        Rule__c rule = setupRules();
        // Cloud challenger
       RuleAction__c action = new RuleAction__c(rule__c=rule.id,related_object__c='Event',
                                                    Type__c='Upsert Related Object');
       
      List<RuleCriteria__c> criteria = new List<RuleCriteria__c>();
       
      criteria=[Select Id,Field_Name__c,Field_Type__c,Matching_Type__c,Matching_Value__c FROM RuleCriteria__c where Rule__c=:Rule.id];
       
       insert action;
       List<RuleAction__c> actions = new List<RuleAction__c>();
       
       actions=[select id,Name,Type__c,Related_Object__c from RuleAction__c where Rule__c=:Rule.id];
       
       List<Values_for_Action_Insert_Record__c> infos = new List<Values_for_Action_Insert_Record__c>();
       
       Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c(Value__c = 'Test Subject', Rule_Action__c = action.Id, Name = 'Subject');
       
       infos.add(info);
       
       Values_for_Action_Insert_Record__c info2 = new Values_for_Action_Insert_Record__c(Value__c = 'Today() +1d', Rule_Action__c = action.Id, Name = 'StartDatetime');
       
       infos.add(info2);
       
       Values_for_Action_Insert_Record__c info3 = new Values_for_Action_Insert_Record__c(Value__c = '{!CreatedDate} +2d', Rule_Action__c = action.Id, Name = 'EndDatetime');
       
       infos.add(info3);
     
       insert infos;
       rule.Advance_Workflow__c = plan.id;
       update rule;
       Account a = new Account(Name='Test',AnnualRevenue=2000.0,Industry='Agriculture',Type='Other');
       system.debug('--> rule '+rule);
       system.debug('--> action  '+action);
       system.debug('->criteria '+criteria);
       system.debug('->actions '+actions);
         system.debug('infos '+infos);
       Test.startTest();
       insert a;    
       //get the account:-
       a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
      // List<Event> e=[select whatid,startdatetime from event where whatid =: a.id ];
       List<Event> e=[select whatid,startdatetime from event ];
       system.debug('e.startdatetime '+e);
       system.assertEquals('Test', a.Name);
       system.assertEquals(2000, a.AnnualRevenue);
       //system.assertEquals((system.today()).addDays(1),[select startdatetime from event where whatid =: a.id][0].startdatetime.date());
       // system.assertEquals((system.today()).addDays(1),e[0].StartDateTime);
      
        Test.stopTest();
    
    }
    @IsTest
    static  void testLookupObjectField(){
        Rule__c rule = setupRules();
        // Cloud challenger
       RuleAction__c action = new RuleAction__c(rule__c=rule.id,lookup_object__c='Contact',Lookup_Field_Name__c = 'Name',
                                                Type__c='Update Field',Field_Name__c = 'LookupObjectField',
                                                Related_Object__c = 'Account',
                                                Lookup_Field_Api_Name__c='Name',Lookup_Where_fields__c = ' Name = \'Test Contact\'');
       insert action;
       
       Contact contact = new Contact(FirstName = 'Test',LastName='Contact');
       insert contact;
       
       rule.Advance_Workflow__c = plan.id;
       update rule;
       Account a = new Account(Name='Test Contact',AnnualRevenue=2000.0,Industry='Agriculture');
       Test.startTest();
       insert a;    
       //get the account:-
       a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
       system.assertEquals('Test Contact', a.Name);
       system.assertEquals(2000, a.AnnualRevenue);
       Test.stopTest();
    }
    
    @IsTest
    static void testExecuteApex(){
    	Rule__c rule = setupRules();
    
    	RuleAction__c action = new RuleAction__c(Rule__c = rule.Id,Related_Object__c = 'Account',
    											 Type__c = 'Execute an Apex Job',
    											 Apex_Job_Class__c = 'Sample_ApexJobActionUpdateAccountContact',
    											 Input_Parameters__c = 'Industry:Agriculture',
    											 Output_Parameters__c = 'Industry:Media');
    	
    	insert action;
    		
    	rule.Advance_Workflow__c = plan.id;
       	update rule;
       	Account account = new Account(Name='Test Contact',AnnualRevenue = 2000.0,Industry = 'Agriculture');
       	Test.startTest();
       	insert account;
       	Contact contact = new Contact(FirstName='test',LastName='contact',AccountId=account.Id);
        insert contact;
       	Sample_ApexJobActionUpdateAccountContact apexJobAction = new Sample_ApexJobActionUpdateAccountContact();
       	Map<String,String> inputParam = new Map<String,String>{'id' => String.valueOf(account.id)};
       	Map<String,String> outputParam = apexJobAction.runAction(inputParam);
       	String objName = apexJobAction.getImplementedObjApiName();
       	Contact conAfter = [select Name, Phone from Contact where id =:contact.id];
       	system.assertEquals(conAfter.Phone,'1111111');
       	system.assertEquals(objName,'Opportunity');
       	Test.stopTest();
       	
    }
    
    @IsTest
    static void testRuleProcessingOnSimulation(){
    	List<Account> accountList = new List<Account>();
    	Set<Id> accountIds = new Set<Id>();
    	
    	Set<Id> ruleIds = new Set<Id>();
    	Boolean isInsert;    	
    	Rule__c rule =setupRules(); ruleIds.add(rule.id);

        RuleAction__c action = new RuleAction__c(Rule__c=rule.id,Related_object__c='Account',
                                                 Field_name__c='Type',Type__c='Update Field',Value__c='Prospect');
     
        insert action;
    	for(integer i=0;i<5;i++){
    		Account account = new Account(Name='Test Contact'+i,AnnualRevenue=2000.0,Industry='Agriculture');
    		accountList.add(account);
    	} 
    	Map<Id, Sobject> oldListMap = new Map<Id, Sobject>();
    	insert accountList;
    	for(Account a :accountList){
    		accountIds.add(a.id);
    		oldListMap.put(a.id , a);
    	}	
    	Test.startTest();
    		isInsert = true;
    		AW_AdvanceWorkflowExecutionEngine.oldListMap = oldListMap;
    		AW_SimulateWorkflowCapture.recordinput = accountList.get(0);
    		AW_AdvanceWorkflowExecutionEngine.startRulesProcessingOnSimulation(accountIds,'Account',isInsert,'Simulation');
    		Account accountInserted = [select name, AnnualRevenue from account where id =:accountList[0].id];
    		system.assertEquals(accountInserted.AnnualRevenue , 2000);
    		//system.assertEquals(accountInserted.Name , 'Test Contact0');
    		//Account accountInserted = [select name, AnnualRevenue from account where id =:accountList[0].id];
    		isInsert = false;
    		accountInserted.AnnualRevenue = 3000;
    		update accountInserted;
    		
    		AW_AdvanceWorkflowExecutionEngine.startRulesProcessingOnSimulation(accountIds,'Account',isInsert,'Simulation');    		
    		system.assertEquals(accountInserted.annualRevenue , 3000);     		
    		 
    		AW_AdvanceWorkflowExecutionEngine.isUpdate = true;
    		AW_AdvanceWorkflowExecutionEngine.oldListMap.put(accountInserted.id, accountInserted);
    		accountInserted.Name = 'TestAcc Updated';
    		accountInserted.Type = 'Customer - Direct';
    		accountInserted.Industry = 'Apparel';
    		update accountInserted;
    		//system.debug('*********AccountInserted*******'+accountInserted);
    		system.assertEquals(accountInserted.Type, 'Customer - Direct');
    		accountInserted.Name = 'TestAcc Updated1';
    		accountInserted.Industry = 'Agriculture';
    		update accountInserted;
    		AW_AdvanceWorkflowExecutionEngine.evaluateRules(ruleIds, accountIds, 'Account', '');
    		//system.assertEquals(accountInserted.Type, 'Prospect');    		  		  		    
    	Test.stopTest();
    }
     
    @IsTest
    static void testApexJobActionSample(){
    	
    	Test.startTest();
    	Map<String,String> mapInputParm = new Map<String,String>{'TestInput'=>'TestInputt'};
    	AW_ApexJob_ActionSample actionSample = new AW_ApexJob_ActionSample();
    	Map<String,String> mapOutputParm = actionSample.runAction(mapInputParm);
    	String ObjName = actionSample.getImplementedObjApiName();
    	System.assertEquals(mapOutputParm.get('desc'),'Update of Description from AWE using Apex Callout as an action ');
    	System.assertEquals(ObjName,'Account');
    	
    	Account account = new Account(Name='Test Acc',AnnualRevenue=2000.0,Industry='Agriculture');
    	AWGuidemeControler guidMeController = new AWGuidemeControler(new ApexPages.Standardcontroller(account)); 
    	System.debug('******guid MeObjOption *******'+guidMeController.objOptions+'***ObjOption2***'+guidMeController.unrelatedObjectOptions);   	    	    
    	Test.stopTest();
    }
    @IsTest
    static void testDoMerge(){
       Rule__c rule = setupRules();
       
       
       RuleAction__c action = new RuleAction__c(rule__c = rule.id,related_object__c = 'Contact',
                                                    Type__c = 'Insert Related Object');
       
       
       insert action;
       
       List<Values_for_Action_Insert_Record__c> infos = new List<Values_for_Action_Insert_Record__c>();
       
       Values_for_Action_Insert_Record__c info = new Values_for_Action_Insert_Record__c(Value__c = '{!Name}', Rule_Action__c = action.Id, Name = 'LastName');
       
       infos.add(info);
       
       insert infos;

       rule.Advance_Workflow__c = plan.id;
       update rule;
       Account a = new Account(Name='Test',AnnualRevenue=2000.0,Industry='Agriculture');
       Test.startTest();
       insert a;    
       //get the account:-
       a=[Select Id,AnnualRevenue,Name,Industry FROM Account WHERE Id=:a.Id];
       system.assertEquals('Test', a.Name);
       system.assertEquals(2000, a.AnnualRevenue);
       Test.stopTest();
    }
}
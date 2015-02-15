/**
 * Class Name :- AW_ParseCSVTo_AdvancedWorkflow_Util_Test
 * Created By :- Ranjeet Singh
 * Created Date:- 22-April-14
 * Description :- To test the functionality of the controller class AW_ParseCSVTo_AdvancedWorkflow_Util
*/

@isTest
public class AW_ParseCSVTo_AdvancedWorkflow_Util_Test{

    static testMethod void testImportAWECSV(){
        insertCustomSetting();
        List<EmailTemplate> emailTemplates = [select id, Name, Folder.Name from EmailTemplate limit 1];
        String csvBody_1 = '"WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","FilterLogic","Action"';
        String csvBody_2 = '\n';
        String csvBody_3 = '"Contact Workflow_Test","Contact","How to enter merge values as criteria Contact_test","Test","89","Create,Edit","Exit","( Email = megh.agar@gmail.com .AND. CrossFormula.Account.Name startswith TEST) .OR. ( LastName = Megha .AND. LastModifiedDate BETWEEN today()-21 TO today() )","(1 AND 2) OR (3 AND 4)",""'; //"<aUpdate:Contact.OwnerId=' + UserInfo.getName() + '/a><aChatterNotification:Account: SendToUser= '+ UserInfo.getName() + '~Message=What do u think of Chatter Notification via AWE  ?/a><aInsert:Contact~LastName=SmithByAWE~Ownerid='+ UserInfo.getName() + '~City={!billingCity}/a><aUpdate:CrossObjectField:Account.Name =TestData/a><aUpdate:OwnerPrioritizationField:Method=Round Robin~User='+UserInfo.getName()+', Weight=1, Priority=2~User=Appirio2  Appirio2, Weight=1, Priority=1~User=Appirio3  Appirio3,Weight=1,Priority=0/a>';
        /*if(emailTemplates.size() > 0){
            csvBody_3  += '<aSendEmail:User='+UserInfo.getName()+'~AdditionalEmails=megh.agar@gmail.com~Folder='+emailTemplates.get(0).Folder.Name+'~Template='+emailTemplates.get(0).Name+'/a>';
        }
        csvBody_3  += '<aApexJob:ApexClass=AW_ApexJob_ActionSample~InputParam=parent:Industry~OutputParam=desc:description/a>"';*/
        String refRule = String.valueOf( Datetime.now() + Crypto.getRandomInteger());
        String csvBody = csvBody_1 + csvBody_2 + csvBody_3;
        Test.startTest();
         System.debug(':::::::::::::::body:::'+csvBody);
         System.debug(':::::::::::::::refRule:::'+refRule);        
        AW_ParseCSVTo_AdvanceWorkflow_Util.importAWECSV(csvBody, refRule , 'Contact'); 
        System.assertEquals([select id from Rule__c ].size(), 1);
        System.assert([select id from RuleCriteria__c ].size() >0);
        System.assert([select id from RuleAction__c ].size() > 0);       
        Test.stopTest();
    }
    
    static testMethod void testExistingRuleImportAWECSV(){
        insertCustomSetting();
        List<EmailTemplate> emailTemplates = [select id, Name, Folder.Name from EmailTemplate limit 1];
        
        Rule__c rule    =   new Rule__c(Name = 'How to enter merge values as criteria Contact_test',
                                        Status__c = 'Draft',
                                        Object__c = 'Contact', 
                                        Version__c = 1,
                                        Description__c = 'Rule 1 Description',
                                        Evaluation_Rule__c='Record is created or edited'
                                        //,Advance_Workflow__c = advanceWF.id
                                        );
        insert rule;
        RuleCriteria__c ruleCriteria = AW_TestUtil.createRuleCriteria(rule, 'Contact', 'Equals', 'Test', 'LastName', 'LastName', 'STRING', true);     
        
        RuleAction__c ruleaction1 = AW_TestUtil.createRuleAction(rule, 'Contact', True, 'FirstName', 'Update Field', 'FirstName', true);
         
        String csvBody_1 = '"WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","FilterLogic","Action"';
        String csvBody_2 = '\n';
        String csvBody_3 = '"Contact Workflow_Test","Contact","How to enter merge values as criteria Contact_test","Test","89","Create,Edit","Exit","( Contact.Email = megh.agar@gmail.com .AND. CrossFormula.Account.Name startswith {!firstName} ) .OR. ( Contact.LastName = Megha .AND. LastModifiedDate BETWEEN today() - 21 TO today() )","(1 AND 2) OR (3 AND 4)",';
        // field Updates
         csvBody_3 += '"<aUpdate:Contact.OwnerId='+UserInfo.getName()+'/a><aUpdate:Name={!LastName}/a>';
         // csv Chatter Notiifcation
        csvBody_3 += '<aChatterNotification:Account: SendToUser='+UserInfo.getName()+'~Message=What do u think of Chatter Notification via AWE  ?/a>';
        // insert Contact
        csvBody_3 +=  '<aInsert:Case~Subject=SmithByAWE~Ownerid='+UserInfo.getName()+'~ContactId={!id}/a>';
        // Update Cross Object
        csvBody_3 +=  '<aUpdate:CrossObjectField:Account.Name =TestData/a>';
        // Update OwnerPrioritization
        csvBody_3 +=  '<aUpdate:OwnerPrioritizationField:Contact.OwnerId:Method=Round Robin~User=Appirio1  Appirio1, Weight=1, Priority=2~User='+UserInfo.getName()+',Weight=1, Priority=1~User='+UserInfo.getName()+',Weight=1,Priority=0/a>';
         // LookupObject 
        csvBody_3 +=  '<aUpdate:LookupObjectField:Opportunity.AccountId:Lookup Object=Opportunity:LookupFromFieldName= AccountId:Condition= AccountId = \'Test\' and StageName != null/a>';
       
        // send mail
        if(emailTemplates.size() > 0){
            csvBody_3  += '<aSendEmail:User='+UserInfo.getName()+'~AdditionalEmails=megh.agar@gmail.com~Folder='+emailTemplates.get(0).Folder.Name+'~Template='+emailTemplates.get(0).Name+'/a>';
        }
        // Apex Job
        csvBody_3  += '<aApexJob:ApexClass=AW_ApexJob_ActionSample~InputParam=parent:Industry~OutputParam=desc:description/a>';
        
        String refRule = String.valueOf( Datetime.now() + Crypto.getRandomInteger());
        String csvBody = csvBody_1 + csvBody_2 + csvBody_3;
        Test.startTest();        
        AW_ParseCSVTo_AdvanceWorkflow_Util.importAWECSV(csvBody, refRule , 'Contact');      
        System.assert([select id from Rule__c ].size() == 1);
        System.assert([select id from RuleCriteria__c ].size() > 0);
        System.assert([select id from RuleAction__c ].size()> 0);   
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
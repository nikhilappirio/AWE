// 
// (c) 2012 Appirio, Inc.
//
//  AW_DynamicActionsHandler_Test                                                     
//
// This class contains test methods for Testing AW_DynamicActionsHandler_Test functionality
//
// 24 Jul 2013     Peter Babalis          Original
//
@isTest(SeeAllData=true)
public class AW_DynamicActionsHandler_Test{
		 
		 public static testmethod void testClickEventExecution(){
		 	Rule__c rule = setupRules();
		 	Account a = new Account(Name='shuld be test',AnnualRevenue=500.0,Industry='Agriculture');
            insert a;
            
            List<RuleAction__c> actions=[Select Id FROM RuleAction__c WHERE Type__c='Load Iframe'];
            
            PageReference pageRef = Page.AW_Execute_Actions_VF;
		    Test.setCurrentPageReference(pageRef);
            
             Test.startTest();
             	AW_DynamicActionsHandler ctrl = new AW_DynamicActionsHandler(new ApexPages.StandardController(a));
             	ctrl.EvaluateRulesOnClick();
             	
             	Apexpages.currentPage().getParameters().put('actionId',actions[0].Id);
             	ctrl.loadVFIframeOrCanvasAction();
             	
             	ctrl.attachment.Name='testfile.txt';
             	ctrl.attachment.Body=blob.valueOf('my attachment text');
             	ctrl.upload();
             	
             	ClickEventActionResponse__c res = new ClickEventActionResponse__c();
				
				res.action__c=actions[0].Id;
				res.recordid__c=a.Id;
				res.record_name__c=a.name;
				insert res;
				
				ctrl.getResponses();
				
				Apexpages.currentPage().getParameters().put('recordId',a.Id);
				Apexpages.currentPage().getParameters().put('responseId',res.Id);
             	ctrl.getIframeCanvasAction();
             	
             	AW_DynamicActionsHandler ctrl2= new AW_DynamicActionsHandler();
             	
             Test.stopTest();
             
		 }
		 
		 public  static Rule__c setupRules(){
            
                Rule__c rule = new Rule__c(Name = 'Test Test Account',Object__c = 'Account', Status__c='Active',Evaluation_Rule__c='On Click Event',Description__c='Rule 1 Description');
                insert rule; 
               
               List<RuleCriteria__c> criteria = new List<RuleCriteria__c>();
               RuleCriteria__c c1 = new RuleCriteria__c(rule__c=rule.id);
               c1.Field_API_Name__c='Industry';
               c1.Field_Type__c='Picklist';
               c1.Matching_Type__c='Equals';
               c1.Matching_Value__c='Agriculture';
               c1.Related_Object__c='Account';
               criteria.add(c1);
               
             
               insert criteria;
               
               //create action
               List<RuleAction__c> actions = new List<RuleAction__c>();
               
               RuleAction__c a1 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='Name',Type__c='Chatter Notification',Value__c='Test',Input_Parameters__c='test post',user_owner_id__c=UserInfo.getUserId());
                                                            
              
               actions.add(a1);
               
               RuleAction__c a2 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='AnnualRevenue',Type__c='Load Iframe',Value__c='2000',endpoint_url__c='google.com',Input_Parameters__c='key:id');
               actions.add(a2);
                        
               // By CC
               RuleAction__c a3 = new RuleAction__c(rule__c=rule.id,related_object__c='Account',
                                                            field_name__c='OwnerId',Type__c='Canvas',Value__c='testapp',Input_Parameters__c='key:id');
               actions.add(a3);
               
               RuleAction__c a4 = new RuleAction__c(rule__c=rule.id,related_object__c='Contact',
                                                            Type__c='Insert Related Object');
               actions.add(a4);
               
               RuleAction__c a5 = new RuleAction__c(rule__c=rule.id,related_object__c='Attachment',
                                                            Type__c='Insert Related Object');
               actions.add(a5);
              
              insert actions;
               
               rule =[Select Id,  Status__c,Filter_Logic__c FROM Rule__c WHERE Id=:rule.Id];
               //rule.Enabled__c=true;
               //By CC
               //rule.Available__c  = true;
               rule.Status__c='Active';
               rule.Evaluation_Rule__c='On Click Event';
               rule.Filter_Logic__c='1';
               update rule;
               
               List<Advance_Workflow__c> wfplan=[Select Id FROM Advance_Workflow__c WHERE Object__c='Account'];
               	Advance_Workflow__c plan;
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
               return rule;
         }
         
}
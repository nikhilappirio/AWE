// (c) 2012 Appirio, Inc.
// AW_DynamicActionsHandler                                                     
// This class is used to process rules assigned to an execution plan 
// and performs the associated actions
// 04 Jul 2013     Peter Babalis     Original
// 24 Dec 2013     Peter Babalis     Refactoring of Class to call methods   
//                                   apex_execution_params, apex_execution_outputupdate
//                                   from helper class  AW_ExecutionActionHelper
//10/04/2014 Change the Sharing based on CheckMarx
// *********************************************************************************/
public with sharing class AW_DynamicActionsHandler{
    
    public Map<String,ClickEventActionResponse__c> foundResponsesForAction {get;set;}
    
    public AW_DynamicActionsHandler() {
 		
    }   
    
    public void getResponses(){
    	foundResponsesForAction=new Map<String,ClickEventActionResponse__c>();
 		system.debug('ruleValid-->'+ruleValid);
 		Set<Id> actionId = new Set<Id>();
 		for(Rule__c rule : ruleValid){
				for(RuleAction__c a:rule.Rule_Actions__r){
					actionId.add(a.Id);
					foundResponsesForAction.put(a.Id,new ClickEventActionResponse__c());
				}
 		}
 		
 		List<ClickEventActionResponse__c> foundresponses =[Select Action__c,Action__r.action_label__c,record__c,response__c FROM ClickEventActionResponse__c WHERE RecordId__c=:recordId AND Action__c IN:actionId];
        
        //we will make option that the user can see that response has been created..and he can view it there:-
        if(foundresponses.size()>0){
	        for(ClickEventActionResponse__c res:foundresponses){
	        	foundResponsesForAction.put(res.action__c,res);
	        }
        }
    }
    
    public Document document {get;set;}
    
    public Attachment attachment {
	  get {
	      if (attachment == null)
	        attachment = new Attachment();
	      return attachment;
	    }
	  set;
	  } 


    public string recordId{get;set;}
    public List<Rule__c> ruleValid {get;set;}
   
    public AW_DynamicActionsHandler(ApexPages.StandardController controller) {
		recordId = controller.getId();
		ruleValid = new List<Rule__c> (); 
    }
	
	public void EvaluateRulesOnClick(){
		 //First process the rules for onclick event
		 
		 AW_AdvanceWorkflowExecutionEngine.startRulesProcessingOnClick(new Set<Id>{recordId}, String.valueOf(Id.valueOf(recordId).getSObjectType()));
	     
	     //after rule processing :- lets deal with valid rules
		 ruleValid = AW_AdvanceWorkflowExecutionEngine.displayClickEventValidRules;
		 system.debug('ruleValid--->'+ruleValid);
		 //all the action for chatterNotification should be execute immediately
		 executeAllChatterNotification();
		 system.debug('ruleValid--->'+ruleValid);
	}
	
	public void executeAllChatterNotification(){
		
			List<ClickEventActionResponse__c> response=  new List<ClickEventActionResponse__c>();
			
			//get all the existing responses:-
			List<ClickEventActionResponse__c> existing=  [Select Action__c FROM ClickEventActionResponse__c WHERE RecordId__c=:recordId];
			
			Set<Id> executedActions = new Set<Id>();
			for(ClickEventActionResponse__c res:existing)
				executedActions.add(res.action__c);
				
			List<FeedItem> item = new List<FeedItem>();
			Map<String,STring> actionToFeed = new Map<String,STring>();
			for(Rule__c rule : ruleValid){
				for(RuleAction__c a:rule.Rule_Actions__r){
					if(a.Type__c=='Chatter Notification' && !executedActions.contains(a.Id)){
						FeedItem f= new FeedItem();
						f.Body=a.Input_Parameters__c;
						f.ParentId=recordId;
						item.add(f);
						String post = f.body.length()>16? f.body.substring(0,15):f.body;
						actionToFeed.put(post,a.Id);
					}
				}
			}	
			if(item.size()==0) return;
			
			insert item;
			
			SObject so =Database.query('Select Name FROM '+String.valueof(Id.valueof(recordId).getSObjectType())+' WHERE Id=\''+recordId+'\'');
			//now create a response record
			for(Integer i=0;i<item.size();i++){
				Feeditem f= item[i];
				
				ClickEventActionResponse__c res = new ClickEventActionResponse__c();
				String post = f.body.length()>16? f.body.substring(0,15):f.body;
				res.action__c=actionToFeed.get(post);
				res.recordid__c=recordId;
				res.record_name__c=string.valueof(so.get('name'));
				res.responseid__c =f.Id;
				
				res.response_name__c=post;
				response.add(res);								
			}
			
			insert response;			
	}
	
	public PageReference upload() {
 
	    attachment.OwnerId = UserInfo.getUserId();
	    attachment.ParentId = recordId; // the record the file is attached to
	    SObject so =Database.query('Select Name FROM '+String.valueof(Id.valueof(recordId).getSObjectType())+' WHERE Id=\''+recordId+'\'');
			
	    try {
	      	insert attachment;
	      	 String actionId=ApexPages.currentPage().getParameters().get('actionId2');
	      	 ClickEventActionResponse__c res = new ClickEventActionResponse__c();
			 res.action__c=actionId;
			 res.recordid__c=recordId;
			 res.record_name__c=string.valueof(so.get('name'));
			 res.responseid__c=attachment.id;
			 res.response_name__c=attachment.name;
	         insert res;
	      	
	    } catch (DMLException e) {
	      	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
	      	
	    } finally {
	      	attachment = new Attachment(); 
	    }
	 
	    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
	    return null; 
  }
  
    
   public PageReference loadVFIframeOrCanvasAction(){
  		String actionId=ApexPages.currentPage().getParameters().get('actionId');
  		RuleAction__c action = AW_HandleClickActionExecution_Helper.getAction(actionId);
  		//[Select input_parameters__c,value__c,Related_Object__c FROM RuleAction__c WHERE Id=:actionId];
  		
  		SObject so = AW_HandleClickActionExecution_Helper.getSObjectData(action,recordId);
        
         
        AW_AdvanceWorkflowExecutionEngine.fieldMap = new Map<String,Map<String,Schema.SObjectField>>();
        AW_AdvanceWorkflowExecutionEngine.fieldMap.put(action.related_object__c.toLowerCase(),Schema.getGlobalDescribe().get(action.related_object__c).getDescribe().fields.getMap());
            
        
        Map<String,STring> params_m=AW_ExecutionActionHelper.apex_execution_params(action, action.Input_Parameters__c, so);                     
         //make a string out of it
        List<String> params = new List<String>();
        for(String key:params_m.keySet())
         	params.add(key+'='+params_m.get(key));
          
         ClickEventActionResponse__c res = new ClickEventActionResponse__c();
		 res.action__c=action.Id;
		 res.recordid__c=recordId;
		 res.record_name__c=string.valueof(so.get('name'));
         insert res;
         
         params.add('responseId='+res.Id); 
         
         if(action.Type__c!='Load a VF Page'){
         	params.add('actionId='+actionId); 
         	params.add('recordId='+recordId); 
         }
         
         String page =action.Type__c=='Load a VF Page' ? action.value__c:'apex/AW_Execute_Actions_VF';       
         return new PageReference('/'+page+'?'+String.join(params,'&'));  
   }
   
   public Component.Apex.PageBlock getIframeCanvasAction(){
        Component.Apex.PageBlock pageBlk = new Component.Apex.PageBlock();
		
		String ruleActionId=ApexPages.currentPage().getParameters().get('actionId');
        recordId =ApexPages.currentPage().getParameters().get('recordId');
        RuleAction__c   action=AW_HandleClickActionExecution_Helper.getAction(ruleActionId);
        SObject so = AW_HandleClickActionExecution_Helper.getSObjectData(action,recordId);
            
        AW_AdvanceWorkflowExecutionEngine.fieldMap = new Map<String,Map<String,Schema.SObjectField>>();
        AW_AdvanceWorkflowExecutionEngine.fieldMap.put(action.related_object__c.toLowerCase(),Schema.getGlobalDescribe().get(action.related_object__c).getDescribe().fields.getMap());
            
        Map<String,STring> params_m=AW_ExecutionActionHelper.apex_execution_params(action, action.Input_Parameters__c, so);                              
        params_m.put('responseId',ApexPages.currentPage().getParameters().get('responseId'));
		
        if(action.Type__c=='Canvas'){
            Component.Apex.canvasApp  canvas= new Component.Apex.canvasApp();
            canvas.developerName=action.value__c;
            if(params_m!=null && params_m.size()>0)
                canvas.parameters=JSON.serialize(params_m);
            pageBlk.childComponents.add(canvas);
        }
        else if(action.Type__c=='Load Iframe'){
            Component.Apex.IFrame iframe = new Component.Apex.IFrame();
             //make a string out of it
            List<String> params = new List<String>();
            for(String key:params_m.keySet())
             params.add(key+'='+params_m.get(key));
            //iframe.src='http://www.salesforce.com';
            iframe.src=action.endpoint_url__c+'?'+String.join(params,'&');
            //iframe.height='50%'
            iframe.scrolling=true;
            pageBlk.childComponents.add(iframe);
        }
        return pageBlk;
  }

}
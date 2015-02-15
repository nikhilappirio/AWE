// (c) 2012 Appirio, Inc.
// AW_VisualDisplayController                                                     
// This class is used to display a graphical representation of Advanced Workflow
//
// 2 Jul 2013     Peter Babalis     Initial version
// 20 Dec 2013     Peter Babalis     Improvments on smaller element size, smoother transition, attaching a plot, cancel button 
//  
// 10 Oct 2014 Change the Sharing based on CheckMarx
// *********************************************************************************/
public with sharing class AW_VisualDisplayController{

		String advanceWorkflowId; 
    	public AW_VisualDisplayController(ApexPages.StandardController ctrl){
    		advanceWorkflowId = ctrl.getId(); 
    	}
    	
    	
    	
    	@RemoteAction
	    public static Node initializeUIData(String advWfId) {
	       //String ids= ApexPages.currentPage().getParameters().get('id');
	       String query='Select Id,Name,Advance_Workflow__c,Description__c ,Evaluation_Rule__c,Execution_Behavior__c,Object__c,Total_Actions__c,Total_Criteria__c FROM Rule__c';
	       
	       Node mainroot = new Node();
	       
	       //for this let us build the data
	       //The main root is going to be the Advance Workflow
	       
	       Advance_Workflow__c wf = [Select Id,Name,Enabled__c,Description__c ,Object__c,CountRulesassociatedtoAdvanceWorkflow__c FROM Advance_Workflow__c WHERE Id=:advWfId];
	       
	       //For this advance workflow let us get the rules,for rules let us get the critria,actiosn
	       List<Rule__c> ruleData =[Select Id,Name,Advance_Workflow__c,Filter_Logic__c,Description__c ,Evaluation_Rule__c,Execution_Behavior__c,Object__c,Total_Actions__c,Total_Criteria__c ,DisplayfilterLogic__c,
	       							(Select Id,Name,Field_API_Name__c,Field_Type__c ,Matching_Type__c,Matching_Value__c,Maximum_Value__c,Minimum_Value__c,Related_Object__c,CrossFormula__c,rule__r.DisplayfilterLogic__c FROM Rule_Criteria__r),
	       							(Select Id,Name,Action_Label__c,Notified_User__c,Reference_Id__c,Field_Type__c,Field_Name__c,Lookup_Field_Name__c,Type__c,Value__c,Long_Value__c,Related_Object__c,Notify_user__c,Email_Template__c,User_Owner_Id__c,CrossObjectField__c,Bulk_api__c,Lookup_Object__c,Lookup_field_api_name__c,lookup_where_fields__c,Apex_job_Class__c,Input_Parameters__c,output_parameters__c,Endpoint_URL__c,Callout_Method__c,Callout_timeout__c,Rule__c,Additional_Emails__c ,EmailTemplateName__c FROM Rule_Actions__r)
	       							FROM Rule__c WHERE Advance_Workflow__c=:advWfId ORDER BY Order__c ASC];
	       
	      
	       
	       //build the data set needed:-
	       
	       mainroot.id=wf.id;
	       mainroot.name= wf.name;
	       mainroot.data.description=wf.description__c;
	       mainroot.data.typeofObj = 'Advance_Workflow__c'; 
	       mainroot.data.sobj =wf;
	       //add rules as children
	       for(Integer i=0;i<ruleData.size();i++){
	       	   Rule__c rule=ruleData[i];
	       	   
	       	   Node ruleChild = new Node();
	       	   ruleChild.id=rule.Id;
	       	   ruleChild.name=rule.name;	       	   
	       	   ruleChild.data.typeofObj = 'Rule__c';
	       	   //ruleChild.data.ruleeval =rule.Evaluation_Rule__c;
	       	   ruleChild.data.sobj =rule;
	       	   //add child for this rule:-
	       	   List<Node> childNodes= new List<Node>();
	       	   
	       	   
	       	   Node childCriteria = new Node();
		       childCriteria.id=rule.Rule_Criteria__r[0].Id;
		       childCriteria.name='Criteria';		          
		       childCriteria.data.typeofObj = 'RuleCriteria__c';
		       childCriteria.data.sobj =rule;
		       childCriteria.data.description=rule.DisplayfilterLogic__c;
		       
		       Node childAction = childCriteria;
		       for(RuleAction__c cr:rule.Rule_Actions__r){
		       	 	 childAction= addActionChildNode(cr,childAction);
		       	
		       } 
		       
		       childNodes.add(childCriteria);
		       
		       
	       	   //here if the rule behaviour is continue to next rule we will add the next rule
	       	   //as child for this rule
	       	   if(rule.Execution_Behavior__c=='Execute Rule and Continue to Next Rule' & i+1<ruleData.size() ){
	       	   	 	//add rule as the child
	       	   	 	Integer j=i+1;
	       	   	 	Rule__c childrule = ruleData[j];
	       	   	 	Node ruleChild2 = new Node();
		       	    ruleChild2.id=childrule.Id+'Ch';
		       	    ruleChild2.name=childrule.name;		       	    
		       	    ruleChild2.data.typeofObj = 'Recur__Rule__c'; // nickynine -  changed to identify recuring Rule
		       	    ruleChild2.data.sobj =childrule;
		       	    //ruleChild2.data.ruleeval =childrule.Evaluation_Rule__c;
		       	    childAction.children.add(ruleChild2);	       	    
	       	   }else{
	       	   		Node ruleChild2 = new Node();
	       	   		ruleChild2.id=i+'End';
	       	   		ruleChild2.name='End';		     
	       	   		ruleChild2.data.typeofObj = 'End';
	       	   		childAction.children.add(ruleChild2);	    
	       	   }
	       	   
	       	   
	       	   ruleChild.children.addAll(childNodes);
	       	   mainroot.children.add(ruleChild);
	       	   
	       }
	        
	       return mainroot;
	       
	    }
	    
	    private static Node addActionChildNode(RuleAction__c cr,Node parentNode){
	    	Node child = new Node();
	    	  	   	   
		    child.id=cr.Id;
		    child.name=cr.name;		   
		    child.data.typeofObj = 'RuleAction__c';		  
		    child.data.sobj =cr;		    	 
		    parentNode.children.add(child);	        
	        return child;
	       	
	    }
	    
	     @RemoteAction
	    public static String attachBlob(String parentId, String fileName, String contentType, String base64BlobValue){
	        /*
	        parentId: The sfdc object Id this file will be attached to	      
	        fileName: Name of the attachment
	        contentTye: Content Type of the file being attached
	        base64BlobValue: Base64 encoded string of the file piece currently processing
	        */
	        Advance_Workflow__c wf= [Select Name FROM Advance_Workflow__c WHERE Id=:parentId];       
	        
	        //let us just cleanup the old attachment - we do this to make sure we have recent copy
	        //may be rules have neem added or removed 
	        String name ='Chart-'+wf.Name ; 
	        delete [Select Id FROM Attachment WHERE Name=:name AND ParentId=:parentId];
	        
	        Attachment att = new Attachment(
	        ParentId = parentId,
	        Body = EncodingUtil.Base64Decode(base64BlobValue),
	        Name = name,
	        ContentType = contentType);
	        insert att;
	        return att.Id;    
	       
	    }
	    
	   
    	
    	/* Wrapper Class for node in the flow diagram */
    	public class Node {
    		public String id {get;set;}
    		public String name {get;set;}
    		public NodeData data {get;set;}
    		
    		public List<Node> children {get;set;}
    		
    		public Node(){
    			children= new List<Node>();
    			data = new NodeData();
    		}
    		
    	}
    	
    	/* additional data for node */
    	public class NodeData {
    		 public String description{get;set;}
    		 public STring typeofObj {get;set;}
    		 public SObject sobj {get;set;}
    	}
    	
    	

}
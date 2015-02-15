public class AW_ApexJob_ActionSample1 implements AW_RuleActionInterface{
 public Map<String,STring> runAction(Map<String,String> mapInputParm){
   String leadnm = (String)mapInputParm.get('LeadName');
	            
   Map<String,STring> returndata= new Map<String,STring>();
   Lead oldlead = getLeadDetails(leadnm);
    if(oldlead != null ) {
                        oldlead.NAGP__c = 'Test Scenario of Direct Update of field into NAGP using AWE APEX action FirstName : '+oldlead.FirstName+' LastName: ' +oldlead.LastName + '  oldlead.Company: ' +oldlead.Company  ;
            			update oldlead;
           			    //do some action here say get :-
            		    returndata.put('LeadDesc','Update of Description using Output param from AWE Apex action');
        		 }
             else{
                   returndata.put('LeadDesc','Failure: to Update Description from AWE ');
        } 
   
    return returndata;
 }
 
 public String getImplementedObjApiName(){
    return 'Lead'; 
 }
 public Lead  getLeadDetails(String leadnum){
        Lead ld =null;
        for(Lead l : [SELECT Id, FirstName,LastName,Company,LeadSource,Status,NAGP__c from Lead  WHERE Name = : leadnum]){
            ld = l;
        }
        return ld;
        
         
    } 
 }
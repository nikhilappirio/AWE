public class Sample_ApexJobActionUpdateLead implements AW_RuleActionInterface{
	
 public Map<String,STring> runAction(Map<String,String> mapInputParm){
   String leadnm = (String)mapInputParm.get('LeadName');
	system.debug('--->INPUT PARAM '+leadnm);              
   Map<String,STring> returndata= new Map<String,STring>();
   Lead oldlead = getLeadDetails(leadnm);
   system.debug('-->oldlead '+oldlead);
    if(oldlead != null ) {
                        oldlead.NAGP__c = 'Test Scenario of Direct Update of field into NAGP using AWE APEX action FirstName : '+oldlead.FirstName+' LastName: ' +oldlead.LastName + '  oldlead.Company: ' +oldlead.Company  ;
                        oldlead.Industry='Other';
            			update oldlead;
            			system.debug('-->oldlead after '+oldlead);
   
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
        for(Lead l : [SELECT Id, Industry,FirstName,LastName,Company,LeadSource,Status,NAGP__c from Lead  WHERE Name = : leadnum]){
            ld = l;
        }
        return ld;
        
         
    } 
}
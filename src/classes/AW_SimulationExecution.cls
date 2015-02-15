Global class AW_SimulationExecution {
      public static List<SObject> 	lstSObjectforUpdateSimulation 		{get; set;} 
      public static Map<String, Sobject> mapUpsertBeforeSobjects {get;set;}
      public static String 	            SimulationInvalidCriteriaMessage  		{get; set;} 
      
      static{
      	if(mapUpsertBeforeSobjects == null){
      		mapUpsertBeforeSobjects = new Map<String , Sobject>();
      	}
      }
    
	   public static  boolean performSimulationOperations(Map<Id,SObject> toupdateSobj,List<SObject> insertrelatedobj,boolean validcriteria){
        SimulationInvalidCriteriaMessage='' ;
        if( !validcriteria ) 
        { SimulationInvalidCriteriaMessage='Record did not meet the criteria';
         return false;
        }
          
        if (insertrelatedobj.size()>0 ){
           try {
              system.debug('--BEGIN INSERT/UPSERT TRANSACTION ....');
              
                // Upsert cannot be done on sobject so separating record on the basis of id
               List<SObject> lstSObjectforInsert = new List<SObject>();
               List<SObject> lstSObjectforUpdate = new List<SObject>();

               for(SObject sobj: insertrelatedobj){
                		if(sobj != null){
	               		if(sobj.id == null){
	               			lstSObjectforInsert.add(sobj);
	               		}else{
	               			lstSObjectforUpdate.add(sobj);
	               		}
               		}
               }
              
               if(lstSObjectforInsert.size() > 0){
              		system.debug('--Number of Record to Be  INSERTED/UPSERTED :'+ lstSObjectforInsert.size());
               		system.debug('-- Record to Be  INSERTED/UPSERTED : '+ lstSObjectforInsert );
               		//DISPLAY ON VISUAL FORCE   lstSObjectforInsert;
               		
               }
               if(lstSObjectforUpdate.size() > 0){
               	    system.debug('--Number of Record to Be  UPDATED/UPSERTED :'+ lstSObjectforUpdate.size());
               		system.debug('-- Record to Be  UPDATED/UPSERTED : '+ lstSObjectforUpdate );
               		//DISPLAY ON VISUAL FORCE   lstSObjectforUpdate;
               		
               		 
               		
               }
               
               system.debug('--END  INSERT/UPSERT TRANSACTION .... ');  
            }
            catch(DMLException e) {

        
            return false;
            }  
         }
        if (toupdateSobj.size()>0 ){
            // Create a savepoint  
            try {
               
               system.debug('-- BEGIN SIMULATE UPDATE TRANSACTION ....');
               system.debug('--SIMULATE Number of Record to Be  Updated :'+ toupdateSobj.size());
               system.debug('-- SIMULATE Record to Be UPDATED : '+ toupdateSobj );
                lstSObjectforUpdateSimulation =toupdateSobj.values();
                		
               system.debug('--END  SIMULATE UPDATE TRANSACTION .... ');  
               return true;    
            }
            catch(DMLException e) {

            
            return false;
            }  
            
         } 
         return true;      
    }
       
    //Megha
    public static String getUpsertFields(RuleAction__c ruleAction){
    	String fd = '';
    	for(Values_for_Action_Insert_Record__c valuesForAction : ruleAction.Values_for_Action_Insert_Record__r){
    		if(!valuesForAction.Name.equalsIgnoreCase('Id')){
    			fd += valuesForAction.Name + ',';	
    		}
    	}
    	if(fd.endsWith(',')){
    		fd = fd.subString(0, fd.lastIndexOf(','));
    	}
    	return fd;
    }
    public static void handleError(Exception e){
        String msg = string.valueOf(e);
        List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
      //  AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowTransactionProcessing.cls','addRecordstoExecutionHistory','AW_AdvanceWorkflowTransactionProcessing.cls','LogEmail','Rule_Execution_History__c');
    }
    
     
    
}
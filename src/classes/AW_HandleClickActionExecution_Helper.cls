public class AW_HandleClickActionExecution_Helper{

        public static SObject getSObjectData(RuleAction__c action,String recordId){
            List<String> input = action.Input_Parameters__c!=null? action.Input_Parameters__c.split(','):new List<String>();
            Set<String> fieldList = new Set<STring>();
            fieldList.add('id');
            fieldList.add('name');
            if(input.size()>0){
                for(String pair : input){
                    List<String> keyValue = pair.split(':');
                    if(!fieldList.contains(keyValue[1].toLowerCase()))
                        fieldList.add(keyValue[1].toLowerCase());
                }
             }
             
             String soql='SELECT '+String.join(new List<STring>(fieldList),',')+
                           ' FROM '+action.Related_Object__c+' WHERE Id=\''+recordId+'\'';
              system.debug(soql)  ;           
              SObject so= database.query(soql);        
              return so;
      }
      
      public static RuleAction__c getAction(String ruleActionId){
        return [SELECT Name,   input_parameters__c,related_object__c,                                
                                   Rule__c,Value__c ,
                                   CrossObjectField__c,
                                   Field_API_Name__c,
                                   rule__r.object__c,
                                   User_Owner_Id__c,
                                   Endpoint_URL__c,
                                   notified_user__c,
                                   Email_template_folder__c,
                                   additional_emails__c,
                                   Field_Type__c,
                                   Type__c
                             FROM  RuleAction__c
                             WHERE id=:ruleActionId];
      }
}
// 
// (c) 2012 Appirio, Inc.
// AW_Console_EditController                                                     
// This class is used to assign rules to a Workflow
//
// 20 Apr 2013     Peter Babalis     Original
//  
//
public class AW_Console_EditController {
  public static Map<String,Map<String, Schema.SObjectField>> GlobalObjectFieldList {get;set;}
 
  public List<AW_ListRules.fieldWrapper> columns {get;set;}
   
  public AW_Console_EditController(){
      initializeColumnDetails();
  }
  
  private void initializeColumnDetails(){
    columns = new List<AW_ListRules.fieldWrapper>();
     
     
     for(Workflow_DynamicColumns__c  wfdc: [Select Label__c, DataType__c, Help_Text__c, ApiName__c,Type__c, Page_Layout__c From Workflow_DynamicColumns__c   Where Type__c != 'Query' order By Type__c,ColumnOrder__c  ]){
      if(wfdc.Type__c == 'Fixed' ||wfdc.Type__c == 'Dynamic' ){
        columns.add(new AW_ListRules.fieldWrapper(wfdc.ApiName__c,wfdc.Label__c,wfdc.DataType__c,wfdc.Help_Text__c));
      }
     }
    }    
        
   public static Map<String, Schema.SObjectField> getFieldMap(String objType){
        objType = objType.toLowerCase();                
        
        if(GlobalObjectFieldList == null)
           GlobalObjectFieldList = new Map<String,Map<String, Schema.SObjectField>>();
           
        if(!GlobalObjectFieldList.containsKey(objType)){
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if(gd.containsKey(objType)){
        GlobalObjectFieldList.put(objType,gd.get(objType).getDescribe().fields.getMap());
        } 
        }           
        return GlobalObjectFieldList.get(objType);
    }
    
  
}
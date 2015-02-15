public with sharing class AW_ConfiguratorController {
public List<Advance_Workflow_Limits__c> lstAdvWorkflowLimits {get;set;}
public List<AdvanceWorkflowConf__c> lstAdvWorkflowConf {get;set;}
public List<AdvanceWorkflowAdmins__c> lstAdvWorkflowAdmins {get;set;}
//public List<ApexLogSettings__c> lstApexLogSettings {get;set;}
public List<Assignment_Setup__c> lstAsgnSetup {get;set;}
public List<AWE_Rule_Action_Mapping__c> lstAWERuleActionMapping {get;set;}
public List<AWE_Rule_Lookup_Page_Size__c> lstRuleLookupPageSize {get;set;}
public List<AWE_Custom_Lookup_Settings__c> lstAweCustomLookupListFields {get;set;}
public AW_ConfiguratorController(){
    lstAdvWorkflowLimits = Advance_Workflow_Limits__c.getAll().values();
    lstAdvWorkflowConf = AdvanceWorkflowConf__c.getAll().values();
    lstAdvWorkflowAdmins = AdvanceWorkflowAdmins__c.getAll().values();
    //lstApexLogSettings = ApexLogSettings__c.getAll().values();
    lstAsgnSetup = Assignment_Setup__c.getAll().values();
    lstAWERuleActionMapping = AWE_Rule_Action_Mapping__c.getAll().values();
    lstRuleLookupPageSize = AWE_Rule_Lookup_Page_Size__c.getAll().values();
    lstAweCustomLookupListFields = AWE_Custom_Lookup_Settings__c.getAll().values();
  }
  
  public void saveLimits(){
    update lstAdvWorkflowLimits;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Limits saved successfully !'));
  }
  
  public void createDefaultLimits(){
    system.debug('------->inside create defaults');
    // Delete all limit records first
    List<Advance_Workflow_Limits__c> lstAdvEWrkLimitsToDelete = Advance_Workflow_Limits__c.getAll().values();
    if(lstAdvEWrkLimitsToDelete != null && lstAdvEWrkLimitsToDelete.size() > 0){
        delete lstAdvEWrkLimitsToDelete;
    }
    List<Advance_Workflow_Limits__c> lstAdvWrkLimits = new List<Advance_Workflow_Limits__c>();
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumApexClassPerQuery',
                            Limit__c = 'Max Numbers of Apex classes to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumCollaborationGrpPerQuery',
                            Limit__c = 'Max Numbers of Colloboration records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumProfilesPerQuery',
                            Limit__c = 'Max Numbers of profile records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumOwnerPrioPerQuery',
                            Limit__c = 'Max Numbers of owner priority records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
                            
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumAdvWorkflowPerQuery',
                            Limit__c = 'Max Numbers of Advanced Workflow records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumOrganizationPerQuery',
                            Limit__c = 'Max Numbers of Organization records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 1
                            ));
                            
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUserRolePerQuery',
                            Limit__c = 'Max Numbers of User Role records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 500
                            ));
                            
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumApexPagesPerQuery',
                            Limit__c = 'Max Numbers of Apex Pages records to be queried',
                            Type_of_Limit__c = 'Salesforce SOQL Row limit',
                            Value__c = 2000
                            ));
        
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUpdateActionsperRule',
                            Limit__c = 'Total Number of Update Actions per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 10
                            ));
    
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumEmailActionsperRule',
                            Limit__c = 'Total Number of Email Actions per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 10
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumInsertActionsperRule',
                            Limit__c = 'Number of Insert Actions per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 25
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumApexJobsperRule',
                            Limit__c = 'Total Number of Apex Jobs per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 5
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUpdateLookupReferenceFieldsperRule',
                            Limit__c = 'Total Number of Update Lookup Reference per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 25
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUpdateMergeFieldsperRule',
                            Limit__c = 'Total Number of Update Merge Fields per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 25
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUpdateCrossReferenceFieldsperRule',
                            Limit__c = 'Total Number of Update Cross Reference Field per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 25
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumAPexCalloutperRule',
                            Limit__c = 'Total Number of Apex Call out per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 5
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumUpsertActionsperRule',
                            Limit__c = 'Number of Upsert Actions per Rule',
                            Type_of_Limit__c = 'Action',
                            Value__c = 10
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumAdvanceWorkflowperObject',
                            Limit__c = 'Total Number of Advance Workflow per Object',
                            Type_of_Limit__c = 'Advance Workflow',
                            Value__c = 1
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumCriteriaperRule',
                            Limit__c = 'Total Number of Criteria per Rule',
                            Type_of_Limit__c = 'Criteria',
                            Value__c = 99
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumCriteriaCrossFormulaFieldsperRule',
                            Limit__c = 'Total Number of Criteria with Cross Formula field per Rule',
                            Type_of_Limit__c = 'Criteria',
                            Value__c = 25
                            ));
    lstAdvWrkLimits.add(new Advance_Workflow_Limits__c(
                            Name='NumRulesperObject',
                            Limit__c = 'Total Number of Rules per Object',
                            Type_of_Limit__c = 'Rule',
                            Value__c = 400
                            ));
    insert lstAdvWrkLimits;
    lstAdvWorkflowLimits = Advance_Workflow_Limits__c.getAll().values();
    
    
  }
   public void saveConf(){
    update lstAdvWorkflowConf;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Configuration saved successfully !'));
  }
  
  public void createDefaultConfig(){
    // Delete all existing config and create new config
    List<AdvanceWorkflowConf__c> lstAdvWorkflowConfToDelete = AdvanceWorkflowConf__c.getAll().values();
    if(lstAdvWorkflowConfToDelete != null && lstAdvWorkflowConfToDelete.size() > 0){
        delete lstAdvWorkflowConfToDelete;
    }
    List<AdvanceWorkflowConf__c> lstAdvWrkConf = new List<AdvanceWorkflowConf__c>();
    lstAdvWrkConf.add(new AdvanceWorkflowConf__c(
                            Name='Lead',
                            Delay_Time__c=2,
                            Batch_Size__c=25,
                            Threshold_for_Async_Invocation__c=10
                            ));
    
    lstAdvWrkConf.add(new AdvanceWorkflowConf__c(
                            Name='WorkflowConf',
                            Delay_Time__c=1,
                            Batch_Size__c=50,
                            Threshold_for_Async_Invocation__c=15
                            ));
    insert lstAdvWrkConf;
    lstAdvWorkflowConf = AdvanceWorkflowConf__c.getAll().values();
    
    
  }
   public void saveAdmins(){
    update lstAdvWorkflowAdmins;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Admins saved successfully !'));
  }
  
  public void createDefaultAdmins(){
    //Delete existing default records
    List<AdvanceWorkflowAdmins__c> lstAdvWorkflowAdminsToDelete = AdvanceWorkflowAdmins__c.getAll().values();
    if(lstAdvWorkflowAdminsToDelete != null && lstAdvWorkflowAdminsToDelete.size() > 0){
        delete lstAdvWorkflowAdminsToDelete;
    }
    List<AdvanceWorkflowAdmins__c> lstAdvWrkAdmins = new List<AdvanceWorkflowAdmins__c>();
    lstAdvWrkAdmins.add(new AdvanceWorkflowAdmins__c(
                                            Name='Advance Workflow Admin',
                                            Emailid__c='peter@appirio.com'
                                            ));
    insert lstAdvWrkAdmins;
    lstAdvWorkflowAdmins = AdvanceWorkflowAdmins__c.getAll().values();
  }
   /*public void saveSettings(){
    update lstApexLogSettings;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Apex log settings saved successfully !'));
  }
  
  public void createDefaultSettings(){
    List<ApexLogSettings__c> lstApxLogSettingToDelete = ApexLogSettings__c.getAll().values();
    if(lstApxLogSettingToDelete != null && lstApxLogSettingToDelete.size() > 0){
        delete lstApxLogSettingToDelete;
    }
    List<ApexLogSettings__c> lstNewApexLogSetng = new List<ApexLogSettings__c>();
    lstNewApexLogSetng.add(new ApexLogSettings__c(
                                Name='AW_RuleActionsController::All',
                                Activate_System_Logs__c=true,
                                Active__c=true,
                                LogDmlExceptions__c=true,
                                Log_Level__c=4,
                                MaxDays__c=100,
                                MaxRecords__c=100,
                                Send_Email__c=true
                                ));
    lstNewApexLogSetng.add(new ApexLogSettings__c(
                                Name='GlobalActivation',
                                Activate_System_Logs__c=false,
                                Active__c=true,
                                LogDmlExceptions__c=false,
                                Log_Level__c=null,
                                MaxDays__c=0,
                                MaxRecords__c=0,
                                Send_Email__c=false
                                ));
    insert lstNewApexLogSetng;
    
    lstApexLogSettings = ApexLogSettings__c.getAll().values();
  }*/
  
  public void saveAssignmentSetup(){
    update lstAsgnSetup;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Assignment setup saved successfully !'));
  }
  
  public void saveDefaultAssgSettings(){
    List<Assignment_Setup__c> lstAssgSetupToDelete = Assignment_Setup__c.getAll().values();
    if(lstAssgSetupToDelete != null && lstAssgSetupToDelete.size() > 0){
        delete lstAssgSetupToDelete;
    }
    
    List<Assignment_Setup__c> lstNewAssgSettings = new List<Assignment_Setup__c>();
    lstNewAssgSettings.add(new Assignment_Setup__c(
                                Name='Weight Average Assignment',
                                Max_Assignment__c=10,
                                Number_Of_Weight__c=1,
                                Priority_Divisor__c=1
                                ));
    insert lstNewAssgSettings;
    lstAsgnSetup = Assignment_Setup__c.getAll().values();
  }
  public void saveMapping(){
    update lstAWERuleActionMapping;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Rule action mapping saved successfully !'));
  }
  
  public void createDefaultMappings(){
    List<AWE_Rule_Action_Mapping__c >lstAWERuleActionMappingToDelete = AWE_Rule_Action_Mapping__c.getAll().values();
    if(lstAWERuleActionMappingToDelete != null && lstAWERuleActionMappingToDelete.size() > 0){
        delete lstAWERuleActionMappingToDelete;
    }
    
    List<AWE_Rule_Action_Mapping__c> lstNewAweRuleActionMapngs = new List<AWE_Rule_Action_Mapping__c>();
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Apex Job Class',
                                            Field_API_Name__c='Apex_Job_Class__c',
                                            Field_Name__c='ApexClass',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Execute an Apex Job'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Apex Job InputParam',
                                            Field_API_Name__c='Input_Parameters__c',
                                            Field_Name__c='InputParam',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Execute an Apex Job'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Apex Job Object',
                                            Field_API_Name__c='Related_Object__c',
                                            Field_Name__c='Object',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Execute an Apex Job'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Apex Job OutputParam',
                                            Field_API_Name__c='Output_Parameters__c',
                                            Field_Name__c='OutputParam',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Execute an Apex Job'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Chatter ActionLabel',
                                            Field_API_Name__c='Action_Label__c',
                                            Field_Name__c='ActionLabel',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Chatter Notification'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Chatter Notification Message',
                                            Field_API_Name__c='Input_Parameters__c',
                                            Field_Name__c='Message',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Chatter Notification'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Chatter Notification to Group',
                                            Field_API_Name__c='User_Owner_Id__c',
                                            Field_Name__c='SendToGroup',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Chatter Notification'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Chatter Notification to User',
                                            Field_API_Name__c='User_Owner_Id__c',
                                            Field_Name__c='SendToUser',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Chatter Notification'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Owner Prioritization Priority',
                                            Field_API_Name__c='Priority__c',
                                            Field_Name__c='Priority',
                                            Object_Name__c='OwnerPrioritization__c',
                                            Type__c='OwnerPrioritization'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Owner Prioritization User',
                                            Field_API_Name__c='User_Queue_Group__c',
                                            Field_Name__c='User',
                                            Object_Name__c='OwnerPrioritization__c',
                                            Type__c='OwnerPrioritization'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action Owner Prioritization Weight',
                                            Field_API_Name__c='Weight__c',
                                            Field_Name__c='Weight',
                                            Object_Name__c='OwnerPrioritization__c',
                                            Type__c='OwnerPrioritization'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action SE Add Email',
                                            Field_API_Name__c='Additional_Emails__c',
                                            Field_Name__c='AdditionalEmails',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Send Email'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action SE Email',
                                            Field_API_Name__c='User_Owner_Id__c',
                                            Field_Name__c='User',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Send Email'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action SE Email Template',
                                            Field_API_Name__c='EmailTemplateName__c',
                                            Field_Name__c='Template',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Send Email'
                                            ));
    
    lstNewAweRuleActionMapngs.add(new AWE_Rule_Action_Mapping__c(
                                            Name='Action SE Folder',
                                            Field_API_Name__c='Email_Template_Folder__c',
                                            Field_Name__c='Folder',
                                            Object_Name__c='RuleAction__c',
                                            Type__c='Send Email'
                                            ));
    
    insert lstNewAweRuleActionMapngs;
    lstAWERuleActionMapping = AWE_Rule_Action_Mapping__c.getAll().values();
    
  }
    public void savePageSize(){
    update lstRuleLookupPageSize;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Rule lookup page size saved successfully !'));
  }
  
  public void createDefaultPageStng(){
    List<AWE_Rule_Lookup_Page_Size__c> lstRuleLookupPageSizeToDelete = AWE_Rule_Lookup_Page_Size__c.getAll().values();
    if(lstRuleLookupPageSizeToDelete != null && lstRuleLookupPageSizeToDelete.size() > 0){
        delete lstRuleLookupPageSizeToDelete;
    }
    
    List<AWE_Rule_Lookup_Page_Size__c> lstNewAWERulePageSize = new List<AWE_Rule_Lookup_Page_Size__c>();
    lstNewAWERulePageSize.add(new AWE_Rule_Lookup_Page_Size__c(name = 'Default',
                                    page_size__c=10));
    insert lstNewAWERulePageSize;
    
    lstRuleLookupPageSize = AWE_Rule_Lookup_Page_Size__c.getAll().values();
  }
  
  public void saveCustomLookupSettings(){
    update lstAweCustomLookupListFields;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm,'Custom Lookup List View Fields saved successfully !'));
  }
  
  public void saveDefaultCustomLookupSettings(){
    List<AWE_Custom_Lookup_Settings__c> lstCustomLookupToDelete = AWE_Custom_Lookup_Settings__c.getAll().values();
    if(lstCustomLookupToDelete != null && lstCustomLookupToDelete.size() > 0){
        delete lstCustomLookupToDelete;
    }
    
    List<AWE_Custom_Lookup_Settings__c> lstNewCustomLookupSettings = new List<AWE_Custom_Lookup_Settings__c>();
    lstNewCustomLookupSettings.add(new AWE_Custom_Lookup_Settings__c(
                                Name='Rule Archive Name',
                                Field_API_Name__c = 'Rule_Name__c',
                                isName__c = true,
                                Object_Name__c = 'Rule_Archive__c'
                                ));
   lstNewCustomLookupSettings.add(new AWE_Custom_Lookup_Settings__c(
                                Name='Rule Archive Version',
                                Field_API_Name__c = 'Version__c',
                                isName__c = false,
                                Object_Name__c = 'Rule_Archive__c'
                                ));
    lstNewCustomLookupSettings.add(new AWE_Custom_Lookup_Settings__c(
                                Name='Rule  Name',
                                Field_API_Name__c = 'Name',
                                isName__c = true,
                                Object_Name__c = 'Rule__c'
                                ));
    lstNewCustomLookupSettings.add(new AWE_Custom_Lookup_Settings__c(
                                Name='Rule Status',
                                Field_API_Name__c = 'Status__c',
                                isName__c = false,
                                Object_Name__c = 'Rule__c'
                                ));
    insert lstNewCustomLookupSettings;
    lstAweCustomLookupListFields = AWE_Custom_Lookup_Settings__c.getAll().values();
  }
  
  public void resetValues(){
    lstAdvWorkflowLimits = Advance_Workflow_Limits__c.getAll().values();
    lstAdvWorkflowConf = AdvanceWorkflowConf__c.getAll().values();
    lstAdvWorkflowAdmins = AdvanceWorkflowAdmins__c.getAll().values();
    //lstApexLogSettings = ApexLogSettings__c.getAll().values();
    lstAsgnSetup = Assignment_Setup__c.getAll().values();
    lstAWERuleActionMapping = AWE_Rule_Action_Mapping__c.getAll().values();
    lstRuleLookupPageSize = AWE_Rule_Lookup_Page_Size__c.getAll().values();
    lstAweCustomLookupListFields = AWE_Custom_Lookup_Settings__c.getAll().values();
  }
}
public with sharing class AW_RetrieveVersionController {
     
    static  String xmlString                        =   null;
    static  AW_ParseXML_Rule_Helper                 wfRule              =   null;
    static  AW_ParseXML_Criteria_Helper             auxCriteria         =   null;
    static  AW_ParseXML_Action_Helper               auxAction           =   null;   
    static  AW_ParseXML_RelatedAction_Helper        auxRelatedAction    =   null;   
    static  AW_ParseXML_OwnerPrioritization_Helper  auxOwnerPrioritization = null;
    static  Integer             ruleNumber          =   0;
    public  Rule_Archive__c     ruleArchive         =   null;
    static  decimal             version         =   0;
    Static  String              objeto              =   null;
    public String newRuleId {get;set;}
    public Boolean isSuccess{get;set;}

    public AW_RetrieveVersionController(){
    
        list<Rule_Archive__c> ruleArchives = [SELECT body__c,Version__c,Object__c FROM Rule_Archive__c WHERE id =: ApexPages.currentPage().getParameters().get('id')];
        
        if(!ruleArchives.isEmpty()){
            //System.debug('\n---->BODY: '+ruleArchive.Body__c);
            xmlString   =   ruleArchives[0].Body__c;
            version     =   ruleArchives[0].Version__c;
            objeto      =   ruleArchives[0].Object__c;
            ruleArchive = ruleArchives[0];
        }
    
    }   

    public String  parser(){
        
        DOM.Document doc    =   new DOM.Document();     
        try {
            //System.debug(xmlString);
            doc.load(xmlString);    
            DOM.XMLNode root = doc.getRootElement();
            walkThrough(root);

            //Testeando objeto auxiliar FRAN
           // System.debug('\n--->Descripcion object: '+wFRule);

            return null;
        }catch (System.XMLException e) {  // invalid XML
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            return e.getMessage();
        }
    }
    

    
    public void retrieveRule(){
        
        integer exists = 0;
        //Comprobar si existe una Rule (on name) con estado Active o draft, 
        //Si existe poner estado draft y name = name + dateTime (seconds)
        list<Rule__c> rule = null;
        Savepoint sp = Database.setSavepoint();
        
        try{
        	parser();
	        if(wfRule != null){
	        rule = [SELECT Name,status__c 
	                        FROM Rule__c 
	                        WHERE Name =: wfRule.ruleName AND ( (status__c = 'Active') OR (status__c = 'Draft') )];
	        }                
	        //if( !rule.isEmpty()){
	        if( rule != null){
	            exists = 1;
	        }
	
	        if(wfRule != null){
	                
	            Rule__c ruleSF                  =   new Rule__c();
	            if(exists == 0){
	                ruleSF.Name                     =   wfRule.ruleName;
	            }else{
	                ruleSF.Name                     =   wfRule.ruleName+datetime.now();
	            }
	            ruleSF.Object__c                =   objeto;
	            ruleSF.Description__c           =   wfRule.description;
	            ruleSF.Evaluation_Rule__c       =   wfRule.evaluationRule;
	            ruleSF.DisplayfilterLogic__c    =   wfRule.ruleCriteria;
	            ruleSF.Order__c                 =   wfRule.orderRule;
	            ruleSF.Execution_Behavior__c    =   '';                     //wfRule.executionBehavior
	            ruleSF.Filter_Logic__c          =   wfRule.filterLogic;
	            ruleSF.Version__c               =   null;                   //version       
	            ruleSF.Status__c                =   'Draft';                        
	            insert ruleSF;
	            newRuleId = ruleSF.id;
	//          listaRulesInsert.add(ruleSF);
	                    
	            //Se insertan listas de criteria
	            if(!wfRule.criterias.isEmpty()){
	            	List<RuleCriteria__c> criterias = new List<RuleCriteria__c>();
	                for(AW_ParseXML_Criteria_Helper cr : wfRule.criterias){ 
	                    RuleCriteria__c criteria        =   new RuleCriteria__c();
	                    criteria.field_name__c          =   cr.criteriaName;   
	                    criteria.Field_API_Name__c      =   cr.criteriafieldapiname;
	                    criteria.CrossFormula__c        =   cr.crossFormula;
	                    criteria.Matching_Type__c       =   cr.matchingType;
	                    criteria.Matching_Value__c      =   cr.matchingValue1;
	                    criteria.Maximum_Value__c       =   cr.maximumValue;
	                    criteria.Minimum_Value__c       =   cr.minimumValue;
	                    criteria.Related_Object__c      =   cr.criteriarelatedObject;
	                    criteria.Record_Type_Id__c      =   cr.recordtypeid;
	                    criteria.Rule__c                =   ruleSF.id;
	                   //System.debug('::::::::::::::::::criteria to be inserted::::::::::'+criteria);
	                   //System.debug('::::::::::::::::::criteria to be inserted: criteria.Record_Type_Id__c  :::::::::'+criteria.Record_Type_Id__c);
	                   //System.debug('::::::::::::::::::criteria to be inserted  cr.recordtypeid; ::::::::::'+cr.recordtypeid);
	                    criterias.add(criteria);
	                }
	                if(!criterias.isEmpty()){
	                	insert criterias;
	                }
	            }
	                    
	            //Se insertan las listas de action
	            if(!wfRule.actions.isEmpty()){
	            	map<Integer , RuleAction__c> ruleActionMap = new map<Integer, RuleAction__c>();
	            	map<Integer , List<Values_for_Action_Insert_Record__c>> ruleActionInsertRecordsMap = new map<Integer , List<Values_for_Action_Insert_Record__c>>();
	            	map<Integer , List<OwnerPrioritization__c>> ruleActionOwnerPrioritizationMap = new map<Integer , List<OwnerPrioritization__c>>();
	                Integer uniqueKey = 1001;
	                for(AW_ParseXML_Action_Helper ac : wfRule.actions){ 
	                	RuleAction__c action            =   new RuleAction__c();
	                    action.Related_Object__c        =   ac.actionrelatedObject;
	                    action.Field_API_Name__c        =   ac.actionfieldAPIName;
	                    action.Type__c                  =   ac.typeAction;
	                    action.Field_Name__c            =   ac.actionfieldName;
	                    action.Value__c                 =   ac.actionvalue;
	                    action.Long_Value__c            =   ac.actionlongValue;
	                    action.Email_Template__c        =   ac.actionEmail_Template;
	                    action.EmailTemplateName__c     =   ac.actionEmailTemplateName;
	                    //Megha
	                    action.Email_Template_Folder__c =   ac.actionEmailFolder;
	                    action.Additional_Emails__c		=   ac.actionAdditionalEmails;
	                    action.CrossObjectField__c      =   ac.actionCrossObjectField;
	                    action.Field_Type__c            =   ac.actionField_Type;
	                    action.Reference_Id__c          =   ac.actionReference_Id;
	                    action.User_Owner_Id__c         =   ac.actionUser_Owner;
	                    action.Prioritization_Method__c =   ac.actionPrioritizationMethod;
	                    action.Rule__c                  =   ruleSF.Id;
	                    if(ac.actionnotifyUser == 'TRUE') action.Notify_User__c = true;
	                    ruleActionMap.put(uniqueKey , action);    
	                    //Se insertan las listas RelatedActions
	                    if(!ac.listaRAction.isEmpty()){
	                    	ruleActionInsertRecordsMap.put(uniqueKey, new List<Values_for_Action_Insert_Record__c>());
	                        for(AW_ParseXML_RelatedAction_Helper ra : ac.listaRAction){
	                            Values_for_Action_Insert_Record__c relatedAction    =   new Values_for_Action_Insert_Record__c();
	                            relatedAction.Rule_Action__c    =   action.id;
	                            relatedAction.Name              =   ra.FieldName;
	                            relatedAction.Value__c          =   ra.value;
	                            ruleActionInsertRecordsMap.get(uniqueKey).add(relatedAction);
	                        }                               
	                    }
	                    
	                    //add Owner Prioritization
	                    if(!ac.listOwnerPrioritization.isEmpty()){
	                    	ruleActionOwnerPrioritizationMap.put(uniqueKey, new List<OwnerPrioritization__c>());
	                    	for(AW_ParseXML_OwnerPrioritization_Helper op : ac.listOwnerPrioritization){
	                            OwnerPrioritization__c ownerPrioritization    =   new OwnerPrioritization__c(RuleAction__c    =   action.id,
	                            												  User_Queue_Group__c = op.userQueueGroup,
	                            												  User_Queue_Group_Id__c = op.userQueueGroupId);
	                            if(op.priority != null) ownerPrioritization.Priority__c = Decimal.valueOf(op.priority);
	                            if(op.weight != null) ownerPrioritization.weight__c = Decimal.valueOf(op.weight);
	                            if(op.percent != null) ownerPrioritization.percent__c = Decimal.valueOf(op.percent);
	                            if(op.Assigned != null) ownerPrioritization.Assigned__c = Decimal.valueOf(op.Assigned);
	                            ruleActionOwnerPrioritizationMap.get(uniqueKey).add(ownerPrioritization);
	                        }
	                    }
	                    uniqueKey++;
	                            
	                }
	                System.debug(':;ruleActionOwnerPrioritizationMap'+ruleActionOwnerPrioritizationMap);
	                 System.debug(':;ruleActionInsertRecordsMap'+ruleActionInsertRecordsMap);
	                if(!ruleActionMap.isEmpty()){
	                	insert ruleActionMap.values();
	                }
	                if(!ruleActionInsertRecordsMap.isEmpty()){
	                	List<Values_for_Action_Insert_Record__c> valueActionInsertRecords = new List<Values_for_Action_Insert_Record__c>();
	                	for(Integer key : ruleActionInsertRecordsMap.keySet()){
	                		if(ruleActionMap.containsKey(Key)){
	                		 	Id actionId = ruleActionMap.get(Key).id;
	                		 	for(Values_for_Action_Insert_Record__c valr : ruleActionInsertRecordsMap.get(Key)){
	                		 		valr.Rule_Action__c = actionId;
	                		 		valueActionInsertRecords.add(valr);
	                		 	}
	                		}
	                	}
	                	if(!valueActionInsertRecords.isEmpty()){
	                		insert valueActionInsertRecords;
	                	}
	                }
	                
	                if(!ruleActionOwnerPrioritizationMap.isEmpty()){
	                	List<OwnerPrioritization__c> ownerPrioritizations = new List<OwnerPrioritization__c>();
	                	for(Integer key : ruleActionOwnerPrioritizationMap.keySet()){
	                		if(ruleActionMap.containsKey(Key)){
	                		 	Id actionId = ruleActionMap.get(Key).id;
	                		 	for(OwnerPrioritization__c op : ruleActionOwnerPrioritizationMap.get(Key)){
	                		 		 op.RuleAction__c = actionId;
	                		 		ownerPrioritizations.add(op);
	                		 	}
	                		}
	                	}
	                	if(!ownerPrioritizations.isEmpty()){
	                		insert ownerPrioritizations;
	                	}
	                }
	                        
	            }
	            list<Rule_Archive__c> ruleArchive = [SELECT Id,body__c,Version__c,Object__c FROM Rule_Archive__c WHERE id =: ApexPages.currentPage().getParameters().get('id')];
	        	delete ruleArchive;
	            isSuccess = true;                   
	        }
	        
	        
	        
        }catch(Exception ex){
        	Database.rollback(sp);
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
        }        
                
    }
    
    //Se mapea el XML en objeto auxliar WFAdvance
    public  void walkThrough(DOM.XMLNode node) {
        
        String result = '\n';
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
                        
            
            /*---------SECCION RULE----------*/
            if(node.getName()       == 'RULE_NAME'){    
                
                ruleNumber++;           
                wfRule              =   new AW_ParseXML_Rule_Helper();
                wfRule.ruleNumber   =   ruleNumber;
                wfRule.ruleName     =   node.getAttribute('name', null).unescapeXML();
            }
            else if(node.getName()  == 'RULE_DESCRIPTION'){
                wfRule.description  =   node.getText();
            }else if(node.getName() == 'ORDER' && node.getText()!='null' ){
                wfRule.orderRule    =   integer.valueOf(node.getText());
            }else if(node.getName() == 'EVALUATION_RULE'){
                wfRule.evaluationRule   =   node.getText();
            }else if(node.getName() == 'EXECUTION_BEHAVIOR'){
                wfRule.executionBehavior    =   node.getText();
            }else if(node.getName() == 'DISPLAYFILTERLOGIC'){
                wfRule.ruleCriteria =   node.getText();
            }else if(node.getName() == 'FILTER_LOGIC'){
                wfRule.filterLogic  =   node.getText();
            }
            
            
            /*----- CRITERIA SECTION-------------*/
            else if(node.getName() == 'CRITERIA'){
                auxCriteria         =   new AW_ParseXML_Criteria_Helper();
                wfRule.criterias.add(auxCriteria);
            }else if(node.getName() == 'CRITERIA_FIELD_NAME'){
                auxCriteria.criteriaName    =   node.getText();
            }else if(node.getName() == 'CrossFormula'){
                auxCriteria.crossFormula    =   node.getText();
            }else if(node.getName() == 'MATCHING_TYPE'){
                auxCriteria.matchingType    =   node.getText();
            }else if(node.getName() == 'MATCHING_VALUE' && node.getText() != null){
                auxCriteria.matchingValue1  =   node.getText().unescapeXML();
            }else if(node.getName() == 'MAXIMUM_VALUE'){
                auxCriteria.maximumValue    =   node.getText();
            }else if(node.getName() == 'MINIMUM_VALUE'){
                auxCriteria.minimumValue    =   node.getText();
            }else if(node.getName() == 'RELATED_OBJECT_CRITERIA'){
                auxCriteria.criteriarelatedObject   =   node.getText();
            }    
            else if(node.getName() == 'RECORDTYPEID' && node.getText() != null && node.getText() != 'null'){ 
               //    auxCriteria.recordtypeid =   charsToescapechars(node.getText());
                 auxCriteria.recordtypeid =   node.getText();
                 auxCriteria.criteriafieldapiname =  'RecordTypeId';
                 
                //system.debug('-->RECORDTYPE  '+auxCriteria.recordtypeid );
            }else if(node.getName() == 'CRITERIA_FIELD_API_NAME'){
                auxCriteria.criteriafieldapiname = node.getText();
            }

            
            
            /*---- ACTION SECTION   ------------*/
            else if(node.getName() == 'ACTION'){
                auxAction       =       new AW_ParseXML_Action_Helper();
                wfRule.actions.add(auxAction);
            }else if(node.getName() == 'RELATED_OBJECT_ACTION'){
                auxAction.actionrelatedObject = node.getText();
            }else if(node.getName() == 'ACTION_TYPE'){
                auxAction.typeAction = node.getText();
            }else if(node.getName() == 'ACTION_FIELD_NAME'){
                auxAction.actionfieldName = node.getText();
            }else if(node.getName() == 'VALUE_for_Update' && node.getText() != null){
                auxAction.actionvalue = node.getText().unescapeXML();
            }else if(node.getName() == 'LONG_VALUE' && node.getText() != null){
                auxAction.actionlongValue = node.getText().unescapeXML();
            }else if(node.getName() == 'NOTIFY_USER'){
                auxAction.actionnotifyUser = node.getText();
            }else if(node.getName() == 'REFERENCE_ID'){
                auxAction.actionReference_Id = node.getText();
            }else if(node.getName() == 'CROSSOBJECTFIELD'){
                auxAction.actionCrossObjectField = node.getText();
            }else if(node.getName() == 'ACTION_USER_OWNER'){
                auxAction.actionUser_Owner = node.getText();
            }else if(node.getName() == 'ACTION_FIELD_API_NAME'){
                auxAction.actionfieldAPIName = node.getText();
            }else if(node.getName() == 'EMAIL_TEMPLATE_NAME'){
                auxAction.actionEmailTemplateName = node.getText();
            }else if(node.getName() == 'EMAIL_TEMPLATE'){
                auxAction.actionEmail_Template = node.getText();
            }else if(node.getName() == 'EMAIL_TEMPLATE_FOLDER'){
                auxAction.actionEmailFolder = node.getText();
            }else if(node.getName() ==  'ADDITIONAL_EMAILS'){
            	auxAction.actionAdditionalEmails = node.getText();
            }else if(node.getName() == 'PRIORITIZATION_METHOD'){
            	auxAction.actionPrioritizationMethod = node.getText();
            }
            
            
            /*----SECCION RELATEDOBJECT-ACTION--*/
            else if(node.getName() == 'Insert_Field'){
                //system.debug('>>Insert_Field'+ node.getName());
                auxRelatedAction    =   new AW_ParseXML_RelatedAction_Helper();
                auxAction.listaRAction.add(auxRelatedAction);
            }else if(node.getName() == 'Field_Name_Insert'){
               // system.debug('>>Insert_Field'+ node.getName());
               // system.debug('>>Insert_Field'+ node.getText());
                auxRelatedAction.fieldName = node.getText();
            }else if(node.getName() == 'Value_For_Insert' && node.getText() != null){
                auxRelatedAction.value = node.getText().unescapeXML();
               // system.debug('>>Insert_Field'+ node.getText());
            }
            
            
             /*----SECCION OWNER PRIORITIZATION-ACTION--*/
            else if(node.getName() == 'OWNER_PRI'){
                // system.debug('>>OWNER_PRI'+ node.getName());
                auxOwnerPrioritization   =   new AW_ParseXML_OwnerPrioritization_Helper();
                auxAction.listOwnerPrioritization.add(auxOwnerPrioritization);
            }else if(node.getName() == 'USER_QUEUE_GROUP'){
                auxOwnerPrioritization.userQueueGroup = node.getText();
            }else if(node.getName() == 'USER_QUEUE_GROUP_ID'){
                auxOwnerPrioritization.userQueueGroupId = node.getText();
            }else if(node.getName() == 'PRIORITY'){
                auxOwnerPrioritization.priority = node.getText();
            }else if(node.getName() == 'WEIGHT'){
                auxOwnerPrioritization.weight = node.getText();
            }
            else if(node.getName() == 'PERCENT'){
                auxOwnerPrioritization.percent = node.getText();
            }else if(node.getName() == 'ASSIGNED'){
                auxOwnerPrioritization.assigned = node.getText();
            }
            for (Dom.XMLNode child: node.getChildElements()) {
              walkThrough(child);
            }
                        
        }
        
    }
    
    public PageReference returnToWorkflow(){
    	if(ruleArchive != null){
    		List<Advance_Workflow__c> advWorkflows = [select id , Object__c from Advance_Workflow__c where object__c = : ruleArchive.Object__c];
    		if(!advWorkflows.isEmpty())
    		return new PageReference('/'+advWorkflows.get(0).id);
    	}
    	return new PageReference('/home/home.jsp');
    }

    @isTest
    static void MyTest() {
        
                 String body =      '<RULE_NAME name="Account Rule NAME B">'+
                                    '<RULE_DESCRIPTION>DESCRIPTION FIELD SAMPLE ACOUNT RULE WITH 2 FILTER CRITERIA AND 6 ACTION</RULE_DESCRIPTION>'+
                                    '<AVAILABLE>True</AVAILABLE>'+
                                    '<ORDER>0</ORDER>'+
                                    '<EVALUATION_RULE>"Record is created or edited and did not previously meet the rule criteria"</EVALUATION_RULE>'+
                                    '<EXECUTION_BEHAVIOR>null</EXECUTION_BEHAVIOR>'+
                                    '<DISPLAYFILTERLOGIC>Account.CrossFormula = Inside Sales AND Account.BillingCountry != USA</DISPLAYFILTERLOGIC>'+
                                    '<FILTER_LOGIC>null</FILTER_LOGIC>'+
                                    '<RULE_CRITERIA_SECTION>'+
                                    '<CRITERIA num="1">'+
                                    '<CRITERIA_FIELD_NAME>"CrossFormula"</CRITERIA_FIELD_NAME>'+
                                    '<CrossFormula>null</CrossFormula>'+
                                    '<MATCHING_TYPE>"Equals"</MATCHING_TYPE>'+
                                    '<MATCHING_VALUE>"Inside Sales"</MATCHING_VALUE>'+
                                    '<MAXIMUM_VALUE>null</MAXIMUM_VALUE>'+
                                    '<MINIMUM_VALUE>null</MINIMUM_VALUE>'+
                                    '<RELATED_OBJECT_CRITERIA>null</RELATED_OBJECT_CRITERIA>'+
                                    '</CRITERIA>'+
                                    '<CRITERIA num="2">'+
                                    '<CRITERIA_FIELD_NAME>"BillingCountry"</CRITERIA_FIELD_NAME>'+
                                    '<CrossFormula>null</CrossFormula>'+
                                    '<MATCHING_TYPE>"Equals"</MATCHING_TYPE>'+
                                    '<MATCHING_VALUE>"Inside Sales"</MATCHING_VALUE>'+
                                    '<MAXIMUM_VALUE>null</MAXIMUM_VALUE>'+
                                    '<MINIMUM_VALUE>null</MINIMUM_VALUE>'+
                                    '<RELATED_OBJECT_CRITERIA>"Opp"</RELATED_OBJECT_CRITERIA>'+
                                    '</CRITERIA>'+
                                    '</RULE_CRITERIA_SECTION>'+
                                    '<RULE_ACTION_SECTION>'+
                                    '<ACTION num="1">'+
                                    '<RELATED_OBJECT_ACTION>null</RELATED_OBJECT_ACTION>'+
                                    '<ACTION_TYPE>null</ACTION_TYPE>'+
                                    '<Field_Name>null</Field_Name>'+
                                    '<VALUE_for_Update>null</VALUE_for_Update>'+
                                    '<LONG_VALUE>null</LONG_VALUE>'+
                                    '<NOTIFY_USER>false</NOTIFY_USER>'+
                                    '<EMAIL_TEMPLATE>null</EMAIL_TEMPLATE>'+
                                    '</ACTION>'+
                                    '<ACTION num="2">'+
                                    '<RELATED_OBJECT_ACTION>null</RELATED_OBJECT_ACTION>'+
                                    '<ACTION_TYPE>null</ACTION_TYPE>'+
                                    '<Field_Name>null</Field_Name>'+
                                    '<VALUE_for_Update>null</VALUE_for_Update>'+
                                    '<LONG_VALUE>null</LONG_VALUE>'+
                                    '<NOTIFY_USER>false</NOTIFY_USER>'+
                                    '<EMAIL_TEMPLATE>null</EMAIL_TEMPLATE>'+
                                    '<INSERT_RELATED_OBJECT_SECTION>'+
                                    '<Insert_Field>1</Insert_Field>'+
                                    '<Field_Name_Insert>"LastName"</Field_Name_Insert>'+
                                    '<Value_For_Insert>"Barr"</Value_For_Insert>'+
                                    '<Insert_Field>2</Insert_Field>'+
                                    '<Field_Name_Insert>"Department"</Field_Name_Insert>'+
                                    '<Value_For_Insert>"Finance"</Value_For_Insert>'+
                                    '</INSERT_RELATED_OBJECT_SECTION>'+
                                    '</ACTION>'+
                                    '</RULE_ACTION_SECTION>'+
                                    '</RULE_NAME>';             

    
        Rule_Archive__c ruleArchive =  new Rule_Archive__c(Object__c = 'account');
        ruleArchive.Body__c = body;
        insert ruleArchive; 
        
        PageReference pageRef = Page.AW_RetrieveVersion_VF;
        Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('id', ruleArchive.id);
        
        AW_RetrieveVersionController retrieveVersion1   =   new AW_RetrieveVersionController();
        
        AW_RetrieveVersionController.xmlString = body;
             
        Rule__c rule    =   new Rule__c(Name = 'Account Rule NAME B',status__c = 'Active',version__c = 1,description__c = 'descripcion',
                                        Evaluation_Rule__c='evaluation',Object__c='account');
        insert rule;     
        
        retrieveVersion1.retrieveRule();
        retrieveVersion1.returnToWorkflow();
            
        
    }   
    
}
public with sharing class AW_ExecutionHistoryController {
      
        String advId;
        String query;
        
        public string historyBy{get;set;} 
        public Date StartDate{get;set;}
        public Date fDate{get;set;}
        public Date EndDate{get;set;}
        public string objectName{get;set;}
        //public string csvBody{get;set;}
        
        public List<SelectOption> objOptions    {get;set;}
        
        public List<Rule_Execution_History__c> allHistoryRecords {get;set;}
        
        public ApexPages.StandardSetController setCon {get;set;}
        Public Integer noOfRecords{get; set;}
        Public Integer size{get;set;}
        
        /*
          variable that stores this value for which the history needs to be filter
        */
        public string filterValue{get;set;}
        public string recordCaptureName{get;set;}
        public String recKeyPrefix{get;set;}
        public String ruleKeyPrefix{get;set;}
        
        public AW_ExecutionHistoryController(Apexpages.StandardController ctrl){
            advId = ctrl.getId();
            objectName=[Select Object__c FROM Advance_Workflow__c WHERE Id =:advId].Object__c;
            recKeyPrefix = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().getKeyPrefix();   
            if(Schema.getGlobalDescribe().keyset().contains('rule__c')){
               ruleKeyPrefix= Schema.getGlobalDescribe().get('rule__c').getDescribe().getKeyPrefix();  
            }
            else{
               ruleKeyPrefix= Schema.getGlobalDescribe().get('awe__rule__c').getDescribe().getKeyPrefix();
            }  
            size=20;
        }
        
        public AW_ExecutionHistoryController(){
            historyBy= ApexPages.currentPage().getParameters().get('historyBy');
            filterValue= ApexPages.currentPage().getParameters().get('filterValue');
            StartDate = Date.parse(ApexPages.currentPage().getParameters().get('sDate'));
            EndDate = Date.parse(ApexPages.currentPage().getParameters().get('eDate'));
            System.debug('HISTORYBY : '+ historyBy + ' FILTER VALUE : '+ filterValue + StartDate + ' to '+ StartDate);
            buildquery();
            //Start : adding limit of 10,000 to avoid reaching error conditions
            query = query + 'Order by CreatedDate LIMIT 10000';
            //End : adding limit of 10,000 to avoid reaching error conditions
            System.debug(':::::::query::::::::::'+query);
            allHistoryRecords = database.query(query);
            
        }
        
        private void buildquery(){
                
            /*
              build the query for the filter
            */  
            query='Select CreatedDate, Id,Rule__c,Advance_Workflow__c,Criteria__c,Record_After_Action_Applied__c,   Actions__c,Evaluation__c,Execution__c,Record_ID__c,Record_Name__c,RuleName__c,Rule_Execution_Status__c, Rule_object__c, Rule_Version__c,Transaction_Stamp__c FROM Rule_Execution_History__c WHERE Id!=\'\'';
            if(historyBy=='historybyobject'  ){
            //Start : Bug Fix - FILTER VALUE = objectName for history by object
                query+=' AND Rule_object__c=\''+objectName+'\'';
            //End : Bug Fix - FILTER VALUE = objectName for history by object           
            }else if(historyBy=='historybyrecord'  ){
                query+=' AND Record_ID__c LIKE \''+filterValue+'%\'';           
            }else if(historyBy=='historybyrule'  ){
                query+=' AND Rule__c LIKE \''+filterValue+'%\'';            
            }else {
                query+=' AND Transaction_Stamp__c=\''+filterValue+'\'';         
            }
            if(StartDate != null && EndDate != null){
            query+=' AND CreatedDate > :StartDate' +  ' AND CreatedDate < :EndDate';
            }
           
        }
        
        public void loadHistory(){
            
            if(filterValue==null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Filter not provided..loading entire history'));
                return;
            }
            
            buildquery();
            System.debug('Query:::::'+query);
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setCon.setPageSize(size);
             noOfRecords = setCon.getResultSize();
             
                
        } 
        
        public List<Rule_Execution_History__c> gethistory(){
            List<Rule_Execution_History__c> historyList = new List<Rule_Execution_History__c>();
            if(setCon!=null){
                for(Rule_Execution_History__c a : (List<Rule_Execution_History__c>)setCon.getRecords())
                    historyList.add(a);
            }
            return historyList;
        } 
        
        public void initfilters(){
             if(historyBy=='historybyobject' && objOptions==null){
                objOptions = new List<SelectOption>();
                Map<String, Schema.SObjectType> mapObj = Schema.getGlobalDescribe();
                for(Schema.SObjectType sobj:mapObj.values()){
                    Schema.DescribeSObjectResult descRes = sobj.getDescribe();
                    objOptions.add(new SelectOption(descRes.getName(),descRes.getLabel() + ' (' + descRes.getName() + ')'));
                }
             }
             recordCaptureName ='';
             filterValue='';  
        } 
        
        public PageReference exportToCSV(){
            system.debug('-->Number of records '+noOfRecords);
            //if (noOfRecords >1000) reurn;
            System.debug(':::::::::::::::::::FILTER:::'+ filterValue);
            //Start : Bug Fix - FILTER VALUE - date filter
             PageReference p = new PageReference('/apex/AW_ExecutionHistoryCSV_VF?historyBy='+historyBy+'&filterValue='+filterValue+'&objectName='+objectName+'&sDate='+StartDate.format()+'&eDate='+EndDate.format());
          
            //End : Bug Fix - FILTER VALUE - date filter
            p.setRedirect(true);
            return p;   
        }
        
        
}
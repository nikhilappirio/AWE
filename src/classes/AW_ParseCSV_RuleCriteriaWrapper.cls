/*************************************
    Wrapper class for Rule Action using in import and Export CSV
**************************************/
public class AW_ParseCSV_RuleCriteriaWrapper{
            
            public integer sno{set;get;}
            
            public RuleCriteria__c ruleCriteria{get; set;}
            
            public boolean isbetween{set;get;}
            public boolean isPicklist{set;get;}
            public boolean isBoolean{set;get;}
            public boolean isCrossFormula{set;get;}
            public boolean isGlobalVariable{set;get;}
            public AW_ParseCSV_RuleCriteriaWrapper(RuleCriteria__c ruleCriteria){
                    this.isbetween = false;
                    this.ruleCriteria = ruleCriteria ;
                    this.isCrossFormula = false;
                    this.isGlobalVariable = false;
                    this.isBoolean = false;
            }
   
    
    }
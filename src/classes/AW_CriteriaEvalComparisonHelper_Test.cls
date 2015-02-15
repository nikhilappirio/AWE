@IsTest
public class AW_CriteriaEvalComparisonHelper_Test{
	   //updated by SH
     static testmethod void testStringComparsionMethod(){
             Boolean result ;       
             Test.startTest();
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('test','test', 'equals', 'string');                    
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('test','test', 'not equal to', 'string');                      
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('test','es', 'Contains', 'string');                    
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy','es', 'Does Not Contain', 'string');                   
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy','du', 'Starts With', 'string');                    
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy','my', 'Ends With', 'string');                  
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy','[a-z]+', 'Regular Expression', 'string');                 
                 system.assertEquals(true, result);     
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy2','dummy2', 'includes', 'picklist');                   
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid('dummy2','dummy2', 'excludes', 'multipicklist');                  
                 system.assertEquals(false, result);    
                
                
             Test.stopTest();   
        }
        
        static testmethod void testNumberComparsionMethod(){
             Boolean result ;       
             Test.startTest();
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(10.0,10.0, 'equals', 'decimal',null);                  
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(10.0,10.0, 'not equal to', 'decimal',null);                        
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(14.0,10.0, 'Greater Than', 'decimal',null);                    
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(10.0,14.0, 'Less Than', 'decimal',null);                   
                 system.assertEquals(true, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(15.0,14.0, 'Greater or Equal', 'decimal',null);                    
                 system.assertEquals(true, result); 
                
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(14.0,14.0, 'Less or Equal', 'decimal',null);                   
                 system.assertEquals(true, result); 
                 
                 RuleCriteria__c c = new RuleCriteria__c();
                 c.Maximum_Value__c='100';
                 c.Minimum_Value__c='50';
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(60.0,14.0, 'between', 'decimal',c);                    
                 system.assertEquals(true, result); 
                 
             Test.stopTest();   
        }
        
        static testmethod void testDateComparsionMethod(){
             Boolean result ;
             
             Date d = date.today();
             
                    
             Test.startTest();           
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'equals', 'date',null);                   
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'not equal to', 'date',null);                     
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,date.parse('12/27/2009'), 'Greater Than', 'date',null);                  
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,date.parse('12/27/2009'), 'Less Than', 'date',null);                 
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,date.parse('12/27/2009'), 'Greater or Equal', 'date',null);                  
                 system.assertEquals(true, result); 
                
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,date.parse('12/27/2009'), 'Less or Equal', 'date',null);                 
                 system.assertEquals(false, result);
                 
                 
                 RuleCriteria__c c = new RuleCriteria__c();
                 c.Maximum_Value__c='12/27/2019';
                 c.Minimum_Value__c='12/27/2009';
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'between', 'date',c);                 
                 system.assertEquals(true, result); 
                 
                  result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'Not Between', 'date',c);                 
                 system.assertEquals(false, result); 
                        
             Test.stopTest();    
         }
         
         static testmethod void testDateTimeComparsionMethod(){
             Boolean result ;
             
             Contact a = new Contact(LastName='test');
             insert a;
             
             a =[Select Id,CreatedDate FROM Contact WHERE Id =:a.Id];
             
            // Datetime d = Datetime.valueOf(string.valueof(a.get('CreatedDate')));
             Datetime d  = DateTime.parse('10/15/2012 11:46 AM');  
             Datetime dt = DateTime.parse('10/15/2011 11:46 AM'); 
                    
             Test.startTest();           
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'equals', 'datetime',null);                   
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,d, 'not equal to', 'datetime',null);                     
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'Greater Than', 'datetime',null);                    
                 system.assertEquals(true, result); 
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'Less Than', 'datetime',null);                   
                 system.assertEquals(false, result);
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'Greater or Equal', 'datetime',null);                    
                 system.assertEquals(true, result); 
                
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'Less or Equal', 'datetime',null);                   
                 system.assertEquals(false, result);
                 
                 
                 RuleCriteria__c c = new RuleCriteria__c();
                 c.Maximum_Value__c='10/14/2019 11:46 AM';
                 c.Minimum_Value__c='10/14/2009 11:46 AM';
                 
                 result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'between', 'datetime',c);
                 system.assertEquals(true, result); 
                 
                  result= AW_CriteriaEvaluationComparisonHelper.isValid(d,dt, 'not between', 'datetime',c);
                 system.assertEquals(false, result); 
                        
             Test.stopTest();    
         }
}
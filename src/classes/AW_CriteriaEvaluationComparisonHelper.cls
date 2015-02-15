public class AW_CriteriaEvaluationComparisonHelper{
   public static String escsapeplitdelimeter ='\\;';
  
	 /*
      STRING COMPARISONS
    */
    public static Boolean isValid(String value1 , String value2 ,String op ,String fieldtype){
        
        if (value1!=null) value1 = value1 .trim();
        if (value2!=null) value2=   value2 .trim();   
        if (fieldtype=='multipicklist' ) {    
              value1 = value1.replaceall(';',',');
         }
        
        if(op.equalsIgnoreCase('Equals')){
            return ( value1 == value2 ) ? true : false;
            
        }
        if(op.equalsIgnoreCase('Not Equal To')){
            return ( value1 != value2 ) ? true : false;
             
        }      
        // Megha added IgnoreCase       
        if(op.equalsIgnoreCase('Contains'))
            return ( value1.containsIgnoreCase(value2) ) ? true : false;
         // Megha added IgnoreCase    
        if(op.equalsIgnoreCase('Does Not Contain'))
            return ( value1.containsIgnoreCase(value2) ) ? false: true;
      
        if(op.equalsIgnoreCase('Is Null'))
             return String.isBlank(value1) ;
         
         if(op.equalsIgnoreCase('Is Not Null'))
             return String.isNotBlank(value1);    
      
        //updated SH : starts with & ends with to work with multiple values
        // Megha added IgnoreCase                   
        if(op.equalsIgnoreCase('Starts With')){
            Boolean result = false;
            for(String value : value2.split(',')){
                result= value1.startsWithIgnoreCase(value) || value1.startsWithIgnoreCase('('+value) ? true:false;
                if(result) break;
            }
            return result; 
            //return ( value1.startsWith(value2) ) ? true : false;                
        }
        // Megha added IgnoreCase
        if(op.equalsIgnoreCase('Ends With')){
            Boolean result = false;
            for(String value : value2.split(',')){
                result= value1.endsWithIgnoreCase(value)|| value1.startsWithIgnoreCase(value+')') ? true:false;
                if(result) break;
            }
            return result; 
            //return ( value1.endsWith(value2) ) ? true : false;  
        } 
       // Megha added IgnoreCase 
       if(op.equalsIgnoreCase('Does Not Start With'))
             return ( value1.startsWithIgnoreCase(value2) ) ? false: true;                
        // Megha added IgnoreCase 
        if(op.equalsIgnoreCase('Does Not End With'))
             return ( value1.endsWithIgnoreCase(value2) ) ? false: true;      
         
        if(op.equalsIgnoreCase('Regular Expression')){
            Matcher conMatcher = Pattern.compile(value2).matcher(value1);
            return conMatcher.matches();            
        }
        
        
         if(op.equalsIgnoreCase('includes')){
             Boolean result = false;
           //  for(String value : value2.split(',')){
          //      for(String value : value2.split('\\|')){	
             //  for(String value : value2.split(''+escsapeplitdelimeter+'') ){	
             if (fieldtype=='string' ) {    
                 for(String value : value2.split(',')){
             	     system.debug('--> include value1 '+ value1 +' value '+value);
             	    
             	      value = value.trim();
                      result= value1.equalsIgnoreCase(value);
                      if(result) break;
                 }
              } else {
         
               for(String value : value2.split(''+escsapeplitdelimeter+'') ){	
             	   system.debug('--> include value1 '+ value1 +' value '+value);
             	    value = value.trim();
                    result= value1.equalsIgnoreCase(value);
                    if(result) break;
                }
             }
             return result;  
        }
        
        if(op.equalsIgnoreCase('excludes') ){
             Boolean result = false;
        //     for(String value : value2.split(',')){
           if (fieldtype=='string' ) {    
                 for(String value : value2.split(',')){
             	     system.debug('--> excludes value1 '+ value1 +' value '+value);
             	    
             	      value = value.trim();
                      result= value1.equalsIgnoreCase(value);
                      if(result) break;
                 }
              } else {
         
               for(String value : value2.split(''+escsapeplitdelimeter+'') ){	
             	   system.debug('--> excludes value1 '+ value1 +' value '+value);
             	    value = value.trim();
                    result= value1.equalsIgnoreCase(value);
                    if(result) break;
                }
           }  
            
             return !result;
         } 
         return false;

    }
    
    /*
      DECIMAL/NUMBER COMPARISONS
    */
        public static Boolean isValid(Decimal value1 , Decimal value2 ,String op,String fieldtype,RuleCriteria__c cr ){
       
            if(op.equalsIgnoreCase('Equals'))
                return ( value1 == value2 ) ? true : false;
            
            if(op.equalsIgnoreCase('Not Equal To'))
                return ( value1 != value2 ) ? true : false;
            
            if(op.equalsIgnoreCase('Greater Than'))
                return ( value1 > value2 ) ? true : false;
             
            if(op.equalsIgnoreCase('Less Than'))
                return ( value1 < value2 ) ? true : false;
             
            if(op.equalsIgnoreCase('Greater or Equal'))
                return ( value1 >= value2 ) ? true : false;
                 
            if(op.equalsIgnoreCase('Less or Equal'))
                return ( value1 <= value2 ) ? true : false;
        
            if(op.equalsIgnoreCase('Is Null'))
                 return ( value1 == null) ? true : false;

             
             if(op.equalsIgnoreCase('Is Not Null'))
                 return ( value1 != null) ? true: false;      
                 
             if(op.equalsIgnoreCase('between')){
                Decimal min = decimal.valueOf(cr.Minimum_Value__c);
                Decimal max = decimal.valueOf(cr.Maximum_Value__c);
                return  (value1 >min && value1 < max) ? true:false;                 
             } 
             if(op.equalsIgnoreCase('Not Between')){
                Decimal min = decimal.valueOf(cr.Minimum_Value__c);
                Decimal max = decimal.valueOf(cr.Maximum_Value__c);
                return  (value1 < min || value1 > max) ? true:false;                 
             }  
             
               
            //other wise it is an invlaid operator on this datatype:-                   
            return false;
        }
        
         /*
      DATE COMPARISONS
    */
    public static Boolean isValid(Date value1 , Date value2 ,String op,String fieldtype,RuleCriteria__c cr ){
      
        if(op.equalsIgnoreCase('Equals'))
            return ( value1 == value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Not Equal To'))
            return ( value1 != value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Greater Than'))
            return ( value1 > value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Less Than'))
            return ( value1 < value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Greater or Equal'))
            return ( value1 >= value2 ) ? true : false;
             
        if(op.equalsIgnoreCase('Less or Equal'))
            return ( value1 <= value2 ) ? true : false;
             
        if(op.equalsIgnoreCase('between')){
            
            Date min = Date.parse(cr.Minimum_Value__c);
            Date max = Date.parse(cr.Maximum_Value__c);
             
            return  (value1 > min && value1 < max) ? true:false;                
        }    
        if(op.equalsIgnoreCase('Not Between')){
            
            Date min = Date.parse(cr.Minimum_Value__c);
            Date max = Date.parse(cr.Maximum_Value__c);
             
            return  (value1 < min || value1 > max) ? true:false;                
        }  
        
              
        //other wise it is an invlaid operator on this datatype:-                   
        return false;
    }
    
     /*
       DATETIME COMPARISONS
    */
    public static Boolean isValid(Datetime value1 , Datetime value2 ,String op,String fieldtype,RuleCriteria__c cr ){
     
        if(op.equalsIgnoreCase('Equals'))
            return ( value1 == value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Not Equal To'))
            return ( value1 != value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Greater Than'))
            return ( value1 > value2 ) ? true : false;
         
        if(op.equalsIgnoreCase('Less Than'))
            return ( value1 < value2 ) ? true : false;
        
        if(op.equalsIgnoreCase('Greater or Equal'))
            return ( value1 >= value2 ) ? true : false;
             
        if(op.equalsIgnoreCase('Less or Equal'))
            return ( value1 <= value2 ) ? true : false;
     
        if(op.equalsIgnoreCase('Is Null'))
             return ( value1 == null) ? true : false;
         
         if(op.equalsIgnoreCase('Is Not Null'))
             return ( value1 != null) ? true: false;              
     
        if(op.equalsIgnoreCase('between')){
            
            Datetime min = Datetime.parse(cr.Minimum_Value__c);
            Datetime max = Datetime.parse(cr.Maximum_Value__c);
            
            return  (value1 >min && value1<max) ? true:false;               
        } 
         if(op.equalsIgnoreCase('Not Between')){
            
            Datetime min = Datetime.parse(cr.Minimum_Value__c);
            Datetime max = Datetime.parse(cr.Maximum_Value__c);
            
            return  (value1 < min || value1 > max) ? true:false;               
        } 
         
             
        //other wise it is an invlaid operator on this datatype:-                   
        return false;
    }
    
    public static boolean isChanged(Id recordId, string fieldAPIName){
        if(Trigger.isExecuting && Trigger.isUpdate){
            if(Trigger.oldMap.get(recordId).get(fieldAPIName) != Trigger.newMap.get(recordId).get(fieldAPIName)){
                return true;
            }
        }
        return false;
    }
    
    // Megha isChanged for Simulation
    public static boolean isChanged_onSimulation(String fieldAPIName, Sobject newSobj, Sobject oldSobj){
    	if(oldSobj != null && newSobj.get(fieldAPIName) != oldSobj.get(fieldAPIName)){
                return true;
        }
        return false;
    }
    
    public static boolean isChangedFromTo(Id recordId, RuleCriteria__c cr){
        if(Trigger.isExecuting && Trigger.isUpdate){
            String value = cr.Matching_value__c;
            String fieldAPIName = cr.Field_API_Name__c;
            if(value != null && value.contains(',')){
                String[] result = value.split(',');
                String oldValue = result[0];
                String newValue = result[1];
                if( AW_CriteriaEvaluationComparisonHelper.doComparison(String.Valueof(Trigger.oldMap.get(recordId).get(fieldAPIName)),oldValue, cr.Field_Type__c, new RuleCriteria__c(Matching_Type__c = 'equals')) && 
                    AW_CriteriaEvaluationComparisonHelper.doComparison(String.valueOf(Trigger.newMap.get(recordId).get(fieldAPIName)), newValue, cr.Field_Type__c, new RuleCriteria__c(Matching_Type__c ='equals'))){
                    return true;
                }
                /*if(String.Valueof(Trigger.oldMap.get(recordId).get(fieldAPIName)).equalsIgnoreCase(oldValue) && 
                   String.valueOf(Trigger.newMap.get(recordId).get(fieldAPIName)).equalsIgnoreCase(newValue)){
                    return true;
                }*/
            } 
        }
        return false;
    }
    
    // Megha isChangedFromTo  for Simulation
    public static boolean isChangedFromTo_OnSimulation(RuleCriteria__c cr, String recNewValue, String recOldValue){
    	String value = cr.Matching_value__c;
        String fieldAPIName = cr.Field_API_Name__c;
        if(value != null && value.contains(',')){
            String[] result = value.split(',');
            String oldValue = result[0];
            String newValue = result[1];
            if( AW_CriteriaEvaluationComparisonHelper.doComparison(recOldValue,oldValue, cr.Field_Type__c, new RuleCriteria__c(Matching_Type__c = 'equals')) && 
                AW_CriteriaEvaluationComparisonHelper.doComparison(recNewValue, newValue, cr.Field_Type__c, new RuleCriteria__c(Matching_Type__c ='equals'))){
                return true;
            }
            /*if(String.Valueof(Trigger.oldMap.get(recordId).get(fieldAPIName)).equalsIgnoreCase(oldValue) && 
               String.valueOf(Trigger.newMap.get(recordId).get(fieldAPIName)).equalsIgnoreCase(newValue)){
                return true;
            }*/
        } 
        return false;
    }
    
   
    //call the methods to do actual comparison based on the fieldtypes
        public static Boolean doComparison(String recordFieldValue,String comparisonValue,String fieldtype,RuleCriteria__c cr){
                Boolean result=false;
             //   system.debug('-->COMPARE RECORD '+ recordFieldValue +' CRITERIA VALUE '+ comparisonValue);
                system.debug('-->COMPARE RECORD '+ recordFieldValue +' CRITERIA VALUE '+ comparisonValue+'::cr'+cr);
              
                if(cr.Matching_Type__c.equalsIgnoreCase('Is Null') || cr.Matching_Type__c.equalsIgnoreCase('Is Not Null')){
                     result =  isValid(recordFieldValue,comparisonValue,cr.Matching_Type__c,fieldtype); 
                 }else if(recordFieldValue!=null){                 
                    //if the datatype is string/url/email/phone/reference/picklist/multipicklist 
                     if(fieldtype=='string' || fieldtype=='combobox'|| fieldtype=='reference' || fieldtype=='textarea' || fieldtype=='boolean' || fieldtype=='url'||fieldtype=='email'||fieldtype=='phone' || fieldtype=='picklist' || fieldtype=='multipicklist'){
                            //call the method to valid string
                          result =  isValid(recordFieldValue,comparisonValue,cr.Matching_Type__c,fieldtype);    
                     }else if(fieldtype=='date'){
                             comparisonValue= (comparisonValue ==null || comparisonValue.trim() == '') ? Date.today().format() : comparisonValue;
                             result = isValid(Date.valueOf(recordFieldValue),convertToDate(comparisonValue.trim()),cr.Matching_Type__c,fieldtype,cr); 
                       }else if(fieldtype=='integer' || fieldtype=='double' || fieldtype=='currency' || fieldtype=='number' || fieldtype=='percent'){
                         comparisonValue = comparisonValue ==null ? '0': comparisonValue;
                         result = isValid(decimal.valueOf(recordFieldValue),decimal.valueOf(comparisonValue),cr.Matching_Type__c,fieldtype,cr); 
                     }else if(fieldtype=='datetime'){
                        comparisonValue= comparisonValue ==null ? Datetime.now().format() : comparisonValue+' 00:00 AM';                       
                        result = isValid(Datetime.valueOf(recordFieldValue),Datetime.parse(comparisonValue),cr.Matching_Type__c,fieldtype,cr);  
                         
                     }
                 }
                 system.debug('-->doComparison result  '+ result);
                 return result;
        }
        
         
         public static Date convertToDate(String comparisonValue){
            Date convertedDate = null;
            try{
	            if (comparisonValue != null && comparisonValue != '' ){ 
	            	convertedDate = Date.parse(comparisonValue);
	            }
            }catch(Exception e){
            	/**
            	 * This means comparisonValue has some date but parse method cannot parse it may be due to date format
            	 */
                if(comparisonValue != null && comparisonValue != ''){
                	List<String> dateSplit;
                	if(comparisonValue.contains('/')){
                		dateSplit = comparisonValue.split('/');
                		convertedDate = date.newinstance(Integer.valueof(dateSplit[2]),Integer.valueof(dateSplit[0]), Integer.valueof(dateSplit[1])); 
                	}else if(comparisonValue.contains('-')){
                		dateSplit = comparisonValue.split('-');
                		convertedDate = date.newinstance(Integer.valueof(dateSplit[2]),Integer.valueof(dateSplit[0]), Integer.valueof(dateSplit[1]));
                	} 
                }
            }
            /**
             * Finally return null if nothing is returned above
             */
            return convertedDate;
        }
}
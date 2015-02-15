// 
// (c) 2013 Appirio, Inc.
// AW_FormulaExpressionHelper                                                     
// A helper class to evaluate merge and formula fields  during rule execution
//
// 12 Dec 2013     Peter Babalis     Original  
// 17 Mar 2014     Peter Babalis Add Math Expressions
// 11 Oct 2014     Peter Babalis  Add processing of task update from leads (whoid)
//  
public class AW_FormulaExpressionHelper{
    
    
    //Map<String,Set<String>> validRelationShips
    private static String concatop='&';
    private static String apostrophe='\'';
    /* 
          helper method added to get the field from value
        */  
        
    public static String fetchFieldFromString(RuleAction__c action,String value,Map<String,Set<String>> validRelationShips){
               value= value!=null? value.trim():value;
                if(value!=null){
                    String value1= value.toLowerCase();
                    if(value1.startswith('left(')){
                        //return value1.substringBetween('left(',',');
                        return fetchFieldFromString(action,value1.substringBetween('left(',','),validRelationShips);
                    }
                    else if(value1.startswith('right(')){
                        //return value1.substringBetween('right(',',');
                        return fetchFieldFromString(action,value1.substringBetween('right(',','),validRelationShips);
                    }else if(value1.startswith('mid(')){
                        //return value1.substringBetween('mid(',',');
                        return fetchFieldFromString(action,value1.substringBetween('mid(',','),validRelationShips);
                    }
                   //to support min/max operation 
                   else if(value1.startswith('max(') || value1.startswith('min(')){
                           String startString = value1.startswith('max(') ? 'max(':'min('; 
                           String fieldValue1 = fetchFieldFromString(action,value1.substringBetween(startString,','),validRelationShips);
                           String fieldValue2 = fetchFieldFromString(action,value1.substringBetween(',',')'),validRelationShips);       
                           system.debug('fieldValue1->'+fieldValue1);
                           system.debug('fieldValue2->'+fieldValue2);
                           List<String>  mergeFields = new List<STring>();
                           if(fieldValue1!=null)mergeFields.add( fieldValue1.trim().toLowerCase());
                           if(fieldValue2!=null)mergeFields.add( fieldValue2.trim().toLowerCase());
                           return String.join(mergeFields,',');
                   }
        
                }
                system.debug('fetch value-->'+value +' action.Field_Type__c '+ action.Field_Type__c +' action.Field_Name__c '+action.Field_Name__c);  
                 
                if(  value != null && !value.contains('{!')   && action.Field_Name__c!=null  && !(action.Field_Type__c=='PHONE'  || action.Field_Type__c=='TEXTAREA' || action.Field_Type__c=='STRING' || action.Field_Type__c=='URL') && (value.contains('*') || value.contains('+') || value.contains('-') || ( value.contains('/'))) ){ 
             // if(  value != null && !value.contains('{!')    && action.Field_Name__c!=null  && !(action.Field_Type__c=='TEXTAREA' || action.Field_Type__c=='STRING' || action.Field_Type__c=='URL') && (value.contains('*') || value.contains('+') || value.contains('-') || ( value.contains('/'))) ){ 
                //if(value != null && (value.contains('*') || value.contains('+') || value.contains('-') || ( !value.contains('//') && value.contains('/'))) ){
                //if(value != null && (value.contains('*') || value.contains('+') || value.contains('-') || value.contains('/')) ){
                    AW_ExpressionEvaluation_Helper util = new AW_ExpressionEvaluation_Helper();
                    String[] postfix =util.convertInfixToPostfix(value); 
                    Set<String> s1 = new Set<String>{'+', '-','*','/','(',')','max','min'};
                    List<String>  mergeFields = new List<STring>();
                    for(String exprSym: postfix){
                        if(!s1.contains(exprSym.toLowerCase())){
                            //then check wether it is valid
                            String fld = exprSym.startsWith('{!')?exprSym.substringBetween('{!','}'):exprSym;
                            boolean check = pattern.matches('[a-zA-Z_.]+',fld);
                            if(check)mergeFields.add(exprSym.toLowerCase());
                            //other wise we are assuming it to be a constant number
                        }
                    }
                     
                    return mergeFields.size()>0?String.join(mergeFields,','):null;
                } 
                //else if(value!=null && ( (value.contains(concatop) && (value.contains(apostrophe)) )|| value.startsWith('{!'))){
                  else if(value!=null && ( (value.contains(concatop) && (value.contains('{!')) && (value.contains(apostrophe)) )|| value.startsWith('{!'))){
                 
                    List<String> splitVaue = value.split(concatop);
                    List<String>  mergeFields = new List<STring>();
                    for(String s:splitVaue){
                        s=s.trim();
                        if(s.startsWith('{!')){
                            String mergeField= s.substringBetween('{!','}');
                            mergeFields.add( mergeField.toLowerCase());
                        }
                    }
                   return String.join(mergeFields,',');
                }else
                //that means we are trying to reference
                if(value != null && value.contains('.')){
                    //then validate:- as we can have . in value field as well for www.koncero.com could be a value
                    List<String> splitReference = value.split('\\.');
                    Set<String> validRN = validRelationShips.get(action.Related_Object__c.toLowerCase())!=null ? validRelationShips.get(action.Related_Object__c.toLowerCase()): new Set<String>();
                    //system.debug('fetch validRN-->'+validRN);   
                    //return value.toLowerCase();
                    if(validRN.contains(splitReference[0])){
                        return value.toLowerCase();
                    }
                } 
                
                return null;
    }
    
    
     //@SH 28/8 adding a method to resolve formaul expression for criteria evaluation
    public static RuleCriteria__c resolveCriteriaFormulaExpressions(RuleCriteria__c cr){
           if((cr.matching_type__c!='Between' && cr.matching_type__c !='Not Between') && cr.matching_value__c!=null){                                       
              if(cr.matching_value__c.startswith('now(') || cr.matching_value__c.startswith('today(')){
                    Datetime myDateTime = AW_FormulaExpressionHelper.resolveDateTimeFunctions(cr.matching_value__c);
                    cr.matching_value__c = cr.Field_Type__c.toLowerCase()=='date' ? myDateTime.date().format() : myDateTime.format();
              }
          }
          
         if((cr.matching_type__c=='Between' || cr.matching_type__c =='Not Between') && cr.minimum_value__c!=null){
               if(cr.minimum_value__c.startswith('now(') || cr.minimum_value__c.startswith('today(')){
                    Datetime myDateTime = AW_FormulaExpressionHelper.resolveDateTimeFunctions(cr.minimum_value__c);
                    cr.minimum_value__c = cr.Field_Type__c.toLowerCase()=='date' ? myDateTime.date().format() : myDateTime.format();
              } 
          }
          
         if((cr.matching_type__c=='Between' || cr.matching_type__c =='Not Between') && cr.maximum_value__c!=null){
               if(cr.maximum_value__c.startswith('now(') || cr.maximum_value__c.startswith('today(')){
                    Datetime myDateTime = AW_FormulaExpressionHelper.resolveDateTimeFunctions(cr.maximum_value__c);
                    cr.maximum_value__c = cr.Field_Type__c.toLowerCase()=='date' ? myDateTime.date().format() : myDateTime.format();
              } 
          }
          system.debug('-->CR  '+cr);
          return cr;               
    }
    
    
    
    public static String fetchCrossformulaValue(RuleAction__c action,String value,SObject o){
        //validate again else could result an error
          List<String> reference = value.split('\\.'); 
          system.debug('reference -->'+reference );
          
          if(reference[0].isNumeric())return value;
          
          SObject fetchedChild ;
          
          String fieldToFetch = reference[reference.size()-1];
          system.debug('fieldToFetch-->'+fieldToFetch );
        
          //SObject fetchedChild  ;
          for(Integer i=0;i<reference.size()-1;i++){
              if(reference[i]=='.' || reference[i].trim()=='' ) continue;
              if(i>=1 && fetchedChild ==null) break;
              fetchedChild = fetchedChild==null ?  o.getSObject(reference[i].trim()):fetchedChild.getSObject(reference[i].trim());
              system.debug('fetched child-->'+fetchedChild);
          }
            system.debug('fetchedChild -->'+fetchedChild );
          return fetchedChild!=null?string.valueof(fetchedChild.get(fieldToFetch)):'';
    } 
    
    
    public static datetime resolveDateTimeFunctions(String value1){
        //then it is today funstionality
                system.debug('value1>>>'+value1);    
                datetime myDateTime = datetime.now();
                if(value1.contains('+')){
                    //then add value
                    List<String> splitparam = value1.split('\\+');
                    //we assume the format to add day /month/year h:m:s would be 7d/7m/7y 1h:m2m:40s
                    List<String> datetimeparts = splitparam[1].split(' ');
                    
                    if(datetimeparts[0].contains('/')) 
                        splitparam = datetimeparts[0].split('/');
                    else if(datetimeparts[0].contains(':')) 
                        splitparam = datetimeparts[0].split(':');
                    else
                        splitparam = datetimeparts[0].split(' ');
                    system.debug('splitparam>>>'+splitparam);   
                    for(String s:splitparam){
                        myDateTime = dateFuntionality(myDateTime,s);                    
                    }
                    
                    if(datetimeparts.size()>1){
                        splitparam = datetimeparts[1].split(':');
                        for(String s:splitparam){
                            myDateTime = dateFuntionality(myDateTime,s);                    
                        }
                    }//end if(datetimeparts.size()>1)
                    
                }//end if('+')  
           system.debug('myDateTime>>>'+myDateTime);    
           return myDateTime;
    }
    
    public static Datetime dateFuntionality(Datetime dt, String s){
        system.debug('s>>>'+s);  
        if(s.contains('d')) {
            dt=dt.addDays(Integer.valueof(s.replace('d','')));
        }else if(s.contains('m')) {
            dt=dt.addMonths(Integer.valueof(s.replace('m','')));
        }else if(s.contains('y')) {
            dt=dt.addYears(Integer.valueof(s.replace('y','')));
        }
        else if(s.contains('h')) {
            dt=dt.addHours(Integer.valueof(s.replace('h','')));
        }
        else if(s.contains('i')) {
            dt=dt.addMinutes(Integer.valueof(s.replace('i','')));
        }
        else if(s.contains('s')) {
            dt=dt.addSeconds(Integer.valueof(s.replace('s','')));
        }
          
        return dt;
    }
    
    public static String doMerge(RuleAction__c action,String value,SObject o){
        
          system.debug('----in doMerge--- value '+value);
          system.debug('-----in doMerge----- action '+action);
          value=value.replaceAll('\'','');
          List<String> splitVaue = value.split(concatop);
       
       //   system.debug('----in merge fields--- splitVaue '+splitVaue);
         
        try{
        for(String s:splitVaue){
             s=s.trim();
             if(s.startsWith('{!')){
                String mergeField= s.substringBetween('{!','}');
                
                List<String> reference = mergeField.split('\\.');                    
                SObject fetchedChild ;
                              
                String fieldToFetch = reference[reference.size()-1];
                system.debug('----> after trim  fieldToFetch '+fieldToFetch);
          
                for(Integer i=0;i<reference.size()-1;i++){
                      if(reference[i]=='.' || reference[i].trim()==''  ) continue;
                      
                    if(i>=1 && fetchedChild ==null) break;
                     
			         if (reference[i] =='WhoId')  {	
			         		system.debug('-------->416::' + o);
			         		SObject sobj = o.clone(true);
			         		system.debug('>>>>>>>>>>>418:' + sobj.get('WhoId'));                       
			                //SObject taskObj = Database.query('Select Whoid FROM Task WHERE Id =\''+String.valueof(o.get('id'))+'\'');
			           		//ID whoid= (ID)taskObj.get('WhoId');
			           		ID whoId = (ID)sobj.get('WhoId');
			           		String query = 'Select ' + fieldToFetch + ' From ' + whoId.getSObjectType() + ' where id=\''+whoid+'\'';
			                SObject sobjDetails = Database.query(query);
			                fetchedChild = sobjDetails;
			                           
			          } 
                     else {                           
                           fetchedChild = fetchedChild==null ?  o.getSObject(reference[i]):fetchedChild.getSObject(reference[i]);              
                     } 
                     // system.debug(' o.getSObject(refer' +o.getSObject(Id));
                 system.debug('---->in doMerge-  fetchedChild '+fetchedChild);
           } 
                //we need to update this line for multiple reference :it will throw an error fetched child is null
                String replacewithval =  fetchedChild==null ? '':string.valueof(fetchedChild.get(fieldToFetch)) ;               
                if(fetchedChild==null && !s.contains('.')) replacewithval = string.valueof(o.get(fieldToFetch));
                 replacewithval = replacewithval ==null ? '':replacewithval ;
                 value=value.replace(s,replacewithval);   
                    
            }
        }
           //PGB 52314 value=value.replaceAll('&',' ');
          //PGB 52314 
          
        system.debug('----in merge fields--- action '+action);
        if(action.Type__c=='Send Email') {
           value=value.replaceAll('&',' ');
         }else 
        {
            value=value.replaceAll('&','');
         }
         
            return value;
        }catch(Exception e){
                throw e;
                String msg = string.valueOf(e);
                   
                 List<User> usr = [select email  from user where username=:UserInfo.getUsername()];
                 AW_ErrorUtil.Handler(e, 'Async', usr[0].email, 'AW_AdvanceWorkflowExecution.cls','domerge','AW_AdvanceWorkflowExecution.cls','LogEmail','RuleAction__c');
                 //other wise it is an invlaid operator on this datatype:-                   
              return null;
       } 
    }  
    
    public static String getCrossFormulaValue(SObject record,String formula){
        List<String> reference = formula.split('\\.'); 
        String fieldToFetch = reference[reference.size()-1];
        
        SObject fetchedRecord ;
        for(Integer i=0;i<reference.size()-1;i++){
              if(reference[i]=='.' || reference[i].trim()=='' ) continue;
              
              //second condition :- @any point the reference returns null we cannot evaluate further
              if(i>=1 && fetchedRecord==null) return null;
              
              fetchedRecord = fetchedRecord==null ?  record.getSObject(reference[i]):fetchedRecord.getSObject(reference[i]);
              if(fetchedRecord == null) break;
              system.debug('fetched fetchedRecord-->'+fetchedRecord);
        }
        
        if(fetchedRecord!=null) 
         return string.valueof(fetchedRecord.get(fieldToFetch));
        
        return null;
    }  
    
    
    //helper method that will fetch the value resolvinf merge fields
    /*
     Sh 11/3 updated to support mathsexpression,min,max
    */
    public static String resolveValueFetched(RuleAction__c action,String value,SObject o, Map<String,Map<String,Schema.SObjectField>> fieldMap){
         value=value.trim();
         String value1 = value.toLowerCase();
        
        if(value1.startswith('left(')){
                String fieldValue = AW_FormulaExpressionHelper.resolveValueFetched(action,value1.substringBetween('left(',','),o,fieldMap);
                Integer numChars = Integer.valueof(value1.substringBetween(',',')'));
                value = fieldValue.left(numChars);
        }
       else if(value1.startswith('right(')){
                String fieldValue = resolveValueFetched(action,value1.substringBetween('right(',','),o,fieldMap);
                Integer numChars = Integer.valueof(value1.substringBetween(',',')'));
                value = fieldValue.right(numChars);
       }else if(value1.startswith('mid(')){
                String fieldValue = resolveValueFetched(action,value1.substringBetween('mid(',','),o,fieldMap);
                value1 = value1.replace('mid(','');
                value1 = value1.replace(')','');
                List<String> params = value1.split(',');
                value = fieldValue.mid(Integer.valueof(params[1]),Integer.valueof(params[2]));
       }
       else if(value1.startswith('now(') || value1.startswith('today(')){
                Datetime myDateTime = AW_FormulaExpressionHelper.resolveDateTimeFunctions(value1);
                value = value1.startswith('today(') ? String.valueof(myDateTime.date()) : String.valueof(myDateTime); 
       }
       //to support min/max operation 
       else if(value1.startswith('max(') || value1.startswith('min(')){
               String startString = value1.startswith('max(') ? 'max(':'min('; 
               String fieldValue1 = resolveValueFetched(action,value1.substringBetween(startString,','),o,fieldMap);
               String fieldValue2 = resolveValueFetched(action,value1.substringBetween(',',')'),o,fieldMap);       
               if(value1.startswith('max(')) return Decimal.valueof(fieldValue1) >Decimal.valueof(fieldValue2) ? fieldValue1:fieldValue2;       
               else return Decimal.valueof(fieldValue1) >Decimal.valueof(fieldValue2) ? fieldValue2:fieldValue1;
       }
       
       //Check if the value has a maths expression
         if(value != null && !(action.Field_Type__c=='TEXTAREA' ||action.Field_Type__c=='PHONE'  || action.Field_Type__c=='DATE' || action.Field_Type__c=='DATETIME'  || action.Field_Type__c=='STRING' || action.Field_Type__c=='URL')  && (value.contains('*') || value.contains('+') || value.contains('-') ||    value.contains('/')) ){
      //  if(value != null && !(action.Field_Type__c=='TEXTAREA' || action.Field_Type__c=='DATE' || action.Field_Type__c=='DATETIME'  || action.Field_Type__c=='STRING' || action.Field_Type__c=='URL')  && (value.contains('*') || value.contains('+') || value.contains('-') ||    value.contains('/')) ){
      //   if(value != null && !(action.Field_Type__c=='TEXTAREA' || action.Field_Type__c=='STRING' || action.Field_Type__c=='URL')  && (value.contains('*') || value.contains('+') || value.contains('-') || ( !value.contains('//') && value.contains('/'))) ){
              AW_ExpressionEvaluation_Helper util = new AW_ExpressionEvaluation_Helper();
              value =util.evaluateEquation(action,value,o,fieldMap); 
             
       }
      
       // PGB53114  Added  if(value=='{!Id}') {.....
         if(value=='{!Id}') {
             value=AW_FormulaExpressionHelper.doMerge(action,value,o);
        }else 
       // PGB52214   if(value.contains(concatop) || value.startsWith('{!')){
        if(value!=null && ( (value.contains(concatop) && (value.contains('{!')) && (value.contains(apostrophe)) )|| value.startsWith('{!'))){
                 value=AW_FormulaExpressionHelper.doMerge(action,value,o);
                             //o1 = updateField(action.Related_Object__c,fieldToUpdate,value,o1);
        }
        // PGB062314 else if(value.contains('.') && action.Field_Type__c!='URL'){
        else if (value.contains('.') && !( action.Field_Type__c=='TEXTAREA' || action.Field_Type__c=='URL') ){
            
                            //String valuetosave = fetchCrossformulaValue(action,value,o);
                            value = AW_FormulaExpressionHelper.fetchCrossformulaValue(action,value,o);
                            //o1 = updateField(action.Related_Object__c,fieldToUpdate,valuetosave,o1);    
        }
        else{
            Map<String,Schema.SObjectField> fieldList = fieldMap.get(action.Related_Object__c.toLowerCase());
            String valueToUpdate =value;
            if(fieldList!=null && (fieldList.containsKey(value)==true ||  fieldMap.containsKey(value.toLowerCase())==true)){
                 value = string.valueof(o.get(valueToUpdate));
            }
            
                      //o1 = updateField(action.Related_Object__c,fieldToUpdate,valueToUpdate,o1); 
         }//end else
         
         return value;
         
    }    
}
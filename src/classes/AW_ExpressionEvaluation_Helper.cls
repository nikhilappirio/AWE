// 
// (c) 2012 Appirio, Inc.
//
//  AW_ExpressionEvaluation_Helper	                                                  
//
// This class is used to evaluate expressions for rule criteria
//
// 10 Oct 2012     Peter Babalis     Original
// 19 Dec 2013     Peter Babalis     Fixed issue related to more than 10 criteria
// 14 Mar 2014     Peter Babalis     Evaluate Math Expressions
//  
//  

/*
  Enhancing this class to suport mathematical equations
*/
public class AW_ExpressionEvaluation_Helper{
    
    private Integer top=-1; 
    
    String[] stack = new List<String>();
    
    //returns the precedence of the symbol
    private Integer getPriority(String symbol){
        if(symbol=='*' ||  symbol=='/' ) return 4;
        
        if(symbol=='+' ||  symbol=='-' ) return 2;
         
        return 1;
    }
    
    private Boolean isOperator(String symbol){
            if(symbol == '*' || symbol == '+' || symbol=='(' || symbol==')' || symbol=='/' || symbol=='-')
                return true;
            else
                return false;
    }
    
    private void push(String item){
        top++;
        stack.add(item);
    }
    
    private String pop(){
        String  ret= stack.remove(top);
        top--;
        return ret; 
    }
    
    public String[] convertInfixToPostfix(String infix){
    	 system.debug('-->infix ' +infix);
         infix = infix.toLowerCase();
         infix = infix.replaceAll('and', '*');
         infix = infix.replaceAll('or', '+');
         infix = infix.replaceAll(' ', '');//remove all blank spaces :-
        
       //  system.debug('-->infix ' +infix);
        // infix='((0 + 0 + 0 + 0 ) + 0 + 0 + 0 + 0 + 0 + 0 + ( 0 + 0 + 1))';
        //system.debug('-->MODIFED infix ' +infix);
         
         Integer i,j=0;
         
        // String symbol;
         String[] postfix = new List<String>();
         ++top;
         stack.add('#');
          
         Integer length = infix.length();
         
         //test
         String exp=infix.replaceAll('\\*',' * ');
         exp=exp.replaceAll('\\+',' + ');
          exp=exp.replaceAll('-',' - ');
         exp=exp.replaceAll('/',' / ');
         exp=exp.replaceAll('\\(',' ( ');
         exp=exp.replaceAll('\\)',' ) ');
         
         //now split:-
         List<String> filter = exp.split(' ');
         
         for(String symbol:filter){ //i=0;i<length;i++
             //symbol = charAt(infix,i);
             if(symbol.trim()=='') continue;
             if(!isOperator(symbol)){
                postfix.add(symbol);  
                j++;  
             }else{
                if(symbol=='(')push(symbol);  
                else if(symbol==')') {
                    while(stack[top]!='(') 
                    { 
                        postfix.add(pop()); 
                        j++; 
                    }                    
                    pop(); //(
                }else{ 
                    if(getPriority(symbol)>getPriority(stack[top])) 
                        push(symbol); 
                    else{ 
                        while(getPriority(symbol)<=getPriority(stack[top])) 
                        { 
                            postfix.add(pop()); 
                            j++; 
                        } 
                        push(symbol); 
                    }//end of else. 
                }//end of else. 
             }//end else
         }//end for
         
   // system.debug('->stack '+stack); 
         while(stack[top]!='#') 
         { 
            postfix.add(pop()); 
            j++; 
         } 
         
      //   system.debug('->intopos '+postfix);
         return postfix;     
    }
    /*
    private String charAt(String str, Integer index) {
            if(str == null){
                return null;
            }
            if(str.length() <= 0){
                return str; 
            }
            if(index < 0 || index >= str.length()){
                return null;    
            }
            return str.substring(index, index+1);
   }
   */
   
   public Boolean evaluateExpression(String filterLogic,Map<Integer,Integer> result){
   
    //system.debug('-->filterLogic  '+filterLogic);	
    //system.debug('-->filterLogic  '+result);	
        filterLogic = filterLogic.toLowerCase();       
        filterLogic = filterLogic.replaceAll(' ', '');//remove all blank spaces :-
        filterLogic = filterLogic.replaceAll('and',' AND ');
        filterLogic = filterLogic.replaceAll('or',' OR ');
        filterLogic = filterLogic.replaceAll('\\(',' ( ');
        filterLogic = filterLogic.replaceAll('\\)',' ) ');
        //system.debug('-->filterLogic  '+filterLogic);
        
        List<String> expr = filterLogic.split(' ');
   	/*	
   		for(Integer i:result.keySet()){
   			 //filterLogic=filterLogic.replace(string.valueof(i),string.valueof(result.get(i)));
   		    filterLogic=filterLogic.replaceFirst(string.valueof(i),string.valueof(result.get(i)));
   		 }
   		 */
         for(Integer i=0;i<expr.size();i++){
            if(expr[i].trim()=='' || expr[i].trim()=='(' || expr[i].trim()==')'|| expr[i].trim()=='AND'|| expr[i].trim()=='OR')
                continue;
            expr[i] = string.valueof(result.get(Integer.valueof(expr[i])));
        }
        
        filterLogic = String.join(expr,'');
        system.debug('HAVE Criteria Met Evaluation-->'+filterLogic);              

        return evaluatePostfixExpression(convertInfixToPostfix(filterLogic));
   }
  
    //helper method to evaluate expression like a+b a*b-4
   public String evaluateEquation(RuleAction__c action,String expr,SObject o,Map<String,Map<String,Schema.SObjectField>> fieldMap){
   
   		List<String> postfix = convertInfixToPostfix(expr);
   		
   		Integer length = postfix.size();
   		String symbol;
   		  		   		
   		
   		top=-1; // reinitialize
   		stack.clear();
   		
   		for(Integer i=0;i<length;i++){
   			 symbol = postfix[i];
   			  
   			 if(!isOperator(symbol)){
   			 	push(symbol);
   			 }else{
   			 	//evaluate the result here and push the result back to the stack
   			 	String firstOpr = pop();
   			 	String secondOpr = pop();
   			 	
   			 	boolean check1 = pattern.matches('[a-zA-Z]+',firstOpr);
   			 	boolean check2 = pattern.matches('[a-zA-Z]+',secondOpr);
   			 	
   			  	
   			 	String value1 = check1 ? AW_FormulaExpressionHelper.resolveValueFetched(action,firstOpr,o,fieldMap):firstOpr;
   			 	String value2 = check2 ? AW_FormulaExpressionHelper.resolveValueFetched(action,secondOpr,o,fieldMap):secondOpr;
   			  	if(String.isBlank(value1)) value1='0';
   			 	if(String.isBlank(value2)) value2='0';
   			 	
   			 	if(String.isBlank(firstOpr)) firstOpr='0';
   			 	if(String.isBlank(secondOpr)) secondOpr='0';
   			  	Decimal op1 = check1 ? Decimal.valueOf(value1):Decimal.valueof(firstOpr);
   			 	Decimal op2 = check2 ? Decimal.valueOf(value2):Decimal.valueof(secondOpr);
   			 	Decimal res=0;
   			
   			 	
   			 	
   			 	if(symbol=='*'){
   			 		res = op1*op2;
   			 	}else if(symbol=='/'){
   			 		res = op1/op2;
   			 	}else if(symbol=='-'){
   			 		res = op1-op2;
   			 	}
   			 	
   			 	else {
   			 		res = op1+op2;  			 	
   			 	}
   			 	
   			 	//now push the result back to stack  			 
   			 	push(string.valueOf(res));   			 	
   			 }  			 
   		}
   		//finally 		
   		return String.valueof(pop());  		
   }
   
   public Boolean evaluatePostfixExpression(List<String> postfix){
   		
   		Integer length = postfix.size();
   		String symbol;
   		  		   		
   		//system.debug('-->postfix  '+postfix);
   		top=-1; // reinitialize
   		stack.clear();
   		
   		for(Integer i=0;i<length;i++){
   			 symbol = postfix[i];
   			
   			// system.debug('-->symbol  '+i+' '+symbol);
   			 
   			 if(!isOperator(symbol)){
   			 	push(symbol);
   			 }else{
   			 	//evaluate the result here and push the result back to the stack
   			 	Integer op1 = Integer.valueOf(pop());
   			 	Integer op2 = Integer.valueOf(pop());
   			 	Integer res=0;
   			 //	system.debug('-->op   '+i+ ' symbol '+symbol+' op1 '+op1+' op2 '+op2 );
   			 	
   			 	if(symbol=='*'){
   			 		res = op1*op2;
   			 	}else {
   			 		res = op1+op2;
   			 		res = res>1 ?1:res;
   			 		
   			 	}
   			 	
   			// 	system.debug('-->res  '+res);
   			 	//now push the result back to stack  			 
   			 	push(string.valueOf(res));   			 	
   			 }  			 
   		}
   		
   		//finally 		
   		return Integer.valueof(pop()) >=1 ? true:false;   		
   }
    
}
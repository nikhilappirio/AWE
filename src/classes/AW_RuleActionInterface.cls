global interface   AW_RuleActionInterface{
      // All other functionality excluded           
           Map<String,String> runAction(Map<String,String> mapInputParm);
           /**
            * This method should always return object api name for which this implementation has be done
            */
           String getImplementedObjApiName();
}
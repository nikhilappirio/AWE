public virtual class Sample_ApexJobActionUpdateAccountContact implements AW_RuleActionInterface{

                public Map<String,String> runAction(Map<String,String> mapInputParm){
                 //here sample to demo the update of a field in record
                 //SObject o = (SObject)mapInputParm.get('objInstance');
                 String sobjType = 'Account';//String.valueof(o.getSobjectType());
                 Map<String,String> outputParam = new Map<String,String>();
                 outputParam.put('Description','testDescription');
                 if(sobjType =='Account'){
                     //o.put('Website','www.apexjob.com');
                     //update o;
                     
                     List<Contact> con = [Select Id,Phone FROM Contact WHERE AccountId=:mapInputParm.get('id')];
                     if(con.size()==0) return outputParam ;//return null;
                     List<Contact> updateContacts= new List<Contact>();
                     for(Contact c:con){
                         c.Phone='1111111';
                         updateContacts.add(c);
                     }    
                     update updateContacts;
                     
                     
                 }                                  
                 return outputParam;
                 //return null;                
            }
            
            public String getImplementedObjApiName(){
                return 'Opportunity';
           }

}
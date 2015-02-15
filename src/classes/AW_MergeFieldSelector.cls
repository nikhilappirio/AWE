public class AW_MergeFieldSelector {
	
	public  List<List<fieldResponse>> fieldData {get;set;}
	
	public string objName{get;set;}
	
	//we need the index for some cleanup purpose
	public string index{get;set;}
	
	public AW_MergeFieldSelector(){
		fieldData = new List<List<fieldResponse>>();
	}
	
	
    public void getFields() {
        
        //here lets do a describe call
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobj = gd.get(objName);
        Schema.DescribeSObjectResult objinfo = sobj.GetDescribe();
        Map<String, Schema.SObjectField> mapField = objinfo.fields.getMap();
        
        List<fieldResponse>  fieldToShow = new List<fieldResponse>();
        
        for(String field : mapField.keySet()){
        	 Schema.DescribeFieldResult F = mapField.get(field).getDescribe();
        	 fieldResponse res = new fieldResponse();
        	 res.fieldName = f.getName();
        	 res.fieldLabel = f.getLabel();
        	 if(f.getReferenceTo().size()>0){
        		 res.fieldReference = String.valueof(f.getReferenceTo()[0]);
        		 res.relationshipName = f.getRelationshipName();
        	 }
        	 fieldToShow.add(res);
        	
        }
        
        if(index!=null && index!=''){
        	Integer i = integer.valueOf(index)+1;
        	Integer size = integer.valueOf(index)+1;
        	//clean up all the elements after this index
        	if(fieldData.size()> size){
        		while(fieldData.size() !=size) {fieldData.remove(i);i++;}
        	}
        }
        
        //now put that back into the static data list
        fieldData.add(fieldToShow);
         
    }
    
    public void reset(){
    	fieldData = new List<List<fieldResponse>>();
    	
    }
    
    public class fieldResponse{
    	
    	public String fieldName{get;set;}
    	public String fieldLabel{get;set;}
    	public String fieldReference{get;set;}
    	public String relationshipName{get;set;}
    }
	
	
}
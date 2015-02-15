public class AW_ParseCSV_WorkflowWrapper{
    	public Map<String, AW_ParseCSV_RuleWrapper> ruleWrapperMap{get;set;}
    	public String objectName{get;set;}
    	public String name {get;set;}
    	public String description {get;set;}
    	
    	public AW_ParseCSV_WorkflowWrapper(){
    		this.objectName = '';
    		this.name = '';
    		this.description = '';
    		this.ruleWrapperMap = new Map<String, AW_ParseCSV_RuleWrapper>();
    	}
    	
    	public AW_ParseCSV_WorkflowWrapper(String objectName ,  String name , String description ,Map<String, AW_ParseCSV_RuleWrapper> ruleWrapperMap){
    		this.objectName = objectName;
    		this.name = name;
    		this.description = description;
    		this.ruleWrapperMap = ruleWrapperMap;
    	}
    	
    	
    }
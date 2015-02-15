public with sharing class AW_ParseXML_OwnerPrioritization_Helper {
	public String userQueueGroup {get;set;}
	public String userQueueGroupId {get;set;}
	public String  priority {get;set;}
	public String weight {get;set;}
	public String percent{get;set;}
	public String assigned {get;set;}
	
	public  AW_ParseXML_OwnerPrioritization_Helper(){
		this.userQueueGroup = '';
		this.userQueueGroupId = '';
		this.priority = '0';
		this.weight = '0';
		this.percent = '0';
		this.assigned = '0';
		
	}
}
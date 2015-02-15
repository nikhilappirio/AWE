/*************************************
	Wrapper class for Rule Action using in import and Export CSV
**************************************/
public class AW_ParseCSV_RuleActionWrapper {
		public RuleAction__c ruleAction;
		public String userOwnerName;
		public String sendTo;
		public Integer uniqueKey;
		public List<Values_for_Action_Insert_Record__c> insertRecordValues;
		public List<OwnerPrioritization__c> ownerPrioritizationList;
		
		public AW_ParseCSV_RuleActionWrapper(RuleAction__c ruleAction ,String userOwnerName , String sendTo, List<Values_for_Action_Insert_Record__c> insertRecordValues, List<OwnerPrioritization__c> ownerPrioritizationList){
			this.ruleAction = ruleAction;
			this.userOwnerName = userOwnerName;
			this.sendTo = sendTo;
			this.insertRecordValues = insertRecordValues;
			this.ownerPrioritizationList = ownerPrioritizationList;
		}
		public AW_ParseCSV_RuleActionWrapper(RuleAction__c ruleAction){
			this.ruleAction = ruleAction;
			this.insertRecordValues = new List<Values_for_Action_Insert_Record__c>();
			this.ownerPrioritizationList = new List<OwnerPrioritization__c>();
		}
		
	}
// 
// (c) 2012 Appirio, Inc.
//
//  AW_RuleLookupController                                                    
//criteriaList
// Class for Lookup Rules on Simulation Page
//
// 07/14/2014
public with sharing class AW_RuleLookupController {
	public String objectName{get;set;}
	public String aweObjName {get;set;}
	public String searchText{get;set;}
	public List<AWE_Custom_Lookup_Settings__c> aweCustomLookupSettings {get;set;}
	public String mainField{get;set;}
	private ApexPages.StandardSetController stdController;
	public List<Sobject> searchedSobject{get{
			if(stdController != null){
				return (List<Sobject>)stdController.getRecords();
			}
			return new List<Sobject>();
	}set;}
	
	public AW_RuleLookupController(){
		objectName = ApexPages.currentPage().getParameters().get('objName');
		searchText = ApexPages.currentPage().getParameters().get('sText');
		aweObjName = ApexPages.currentPage().getParameters().get('aweObjName');
		if(objectName != null){
			aweCustomLookupSettings = loadCustomLookupSettings();
			
			loadSearchRecords();
		}
	} 
	
	public void loadSearchRecords(){
		Integer stdPageSize = 20;
		String soqlQuery = 'select id ';
		if(!aweCustomLookupSettings.isEmpty()){
			for(AWE_Custom_Lookup_Settings__c cls : aweCustomLookupSettings){
				soqlQuery += ',' + cls.Field_API_Name__c;
			}
		}else{
			soqlQuery += ', Name ';
		}
		if(mainField == null){
			mainField = 'Name';
		}
		System.debug('::objectName'+objectName);
		System.debug('::aweObjName'+aweObjName);
		System.debug('::mainField'+mainField);
		soqlQuery += ' from ' + aweObjName + ' WHERE ';
		if(aweObjName == 'Rule__c' || aweObjName == 'Rule_Archive__c'){
			soqlQuery += ' Object__c  = : objectName ';
		}else{
			soqlQuery += ' Related_Object__c  = : objectName ';
		}
		if(aweObjName == 'Rule__c'){
			soqlQuery += ' AND Status__c in (\'Active\' , \'Draft\') ';
		}
		if(searchText != null && searchText.trim() != ''){
			String likeFilter = searchText +'%';
			soqlQuery += ' AND '+ mainField +' like : likeFilter';
		}
		stdController = new ApexPages.StandardSetController(Database.query(soqlQuery));
		AWE_Rule_Lookup_Page_Size__c pageSizeInstance = AWE_Rule_Lookup_Page_Size__c.getInstance('Default');
		
		if(pageSizeInstance != null && pageSizeInstance.page_Size__c != null){
			stdPageSize = Integer.valueOf(pageSizeInstance.page_Size__c);
		}
		stdController.setPageSize(stdPageSize);
	}
	
	public List<AWE_Custom_Lookup_Settings__c> loadCustomLookupSettings(){
		Map<String, AWE_Custom_Lookup_Settings__c> aweCustomLookupSeetingMap = AWE_Custom_Lookup_Settings__c.getAll();
		List<AWE_Custom_Lookup_Settings__c> tempCustomLookupSettings = new List<AWE_Custom_Lookup_Settings__c>();
		for(AWE_Custom_Lookup_Settings__c cls : aweCustomLookupSeetingMap.values()){
			if(cls.Object_Name__c == aweObjName){
				tempCustomLookupSettings.add(cls);
				if(cls.isName__c){
					mainField = cls.field_API_Name__c;
				}
			}
		}
		return tempCustomLookupSettings;
		
	}
	public PageReference search(){
		loadSearchRecords();
		return null;
	}
	//Boolean to check if there are more records after the present displaying records
    public Boolean hasNext{
        get
        {
            if(stdController != null){
                return stdController.getHasNext();
            }
            return false;
        }set;}

    //Boolean to check if there are more records before the present displaying records
    public Boolean hasPrevious{
        get
        {
            if(stdController != null){
                return stdController.getHasPrevious();
            }
            return false;
        }set;}

    //Page number of the current displaying records
    public Integer pageNumber{
        get
        {
            if(stdController != null){
                return stdController.getPageNumber();
            }
            return 0;
        }set;}

     //Page number of the Size
    public Integer pageSize{
        get
        {
            if(stdController != null){
                return stdController.getPageSize();
            }
            return 0;
        }set;}

    //Returns the previous page of records
    public void previous(){
        if(stdController != null){
            stdController.previous();
        }
    }

    //Returns the next page of records
    public void next(){
       if(stdController != null){
            stdController.next();
        }
    }

	

}
public with sharing class AW_SampleCSVController {
    
    public String csvBody{get;set;}
    public String aweId {get;set;}
    
    public AW_SampleCSVController(){
        csvBody = generateCSVBody();
    }
    
    private String generateCSVBody(){
        String csv = '"WORKFLOW","OBJECT","RULE_NAME","Description","Order","Evaluation","Execution","Criteria","FilterLogic","Action"\n';
        // update Field Ex
        /*csv += '"Account","Account","fifteen criteria" ,"15 criteria with AND/OR logic Update Field"';
        csv += '"Create,Edit" ,"Exit","( ( Account.Industry = Apparel .OR. Account.Industry = Banking .OR. Account.Industry = Biotechnology .OR. Account.Industry = Chemicals ) .OR. Account.Industry = Communications .OR. Account.Industry = Consulting .OR. Account.Industry = Not For Profit .OR. Account.Industry = Technology .OR. Account.Industry = Utilities .OR. Account.Industry = Apparel .OR. ( Account.Industry = Apparel .OR. Account.Industry = Apparel .OR. Account.Industry = Apparel .OR. Account.Industry = Banking .OR. Account.Industry = Apparel .OR. Account.Industry = Biotechnology ) )",'
                + '"<aUpdate:Account.OwnerId=Awe Awe/a>" \n';
        // 2 criteria with OwnerPrioritization
        csv += '"Account","Account","2 criteria with OwnerPrioritization","2 criteria with OwnerPrioritization","",';
        csv += '"Create,Edit","Exit","Account.SLAExpirationDate__c Between (10/1/2013 To 10/1/2009) .AND. Account.BillingCountry = USA",'
                + '"<aUpdate:OwnerPrioritizationField:Account.OwnerId:Method=Round Robin~User=Appirio1 Appirio1, Weight=1,Priority=2~User=Appirio2 Appirio2, Weight=1, Priority=1~User=Appirio3 Appirio3,Weight=1,Priority=0/a>" \n';
        */
        csv += '"Account","Account","Account Upsert with Between Date as Criteria with complex logic","Account Upsert with Between Date as Criteria with complex logic","","Create, Edit","Continue",'
                + '"( Account.Industry = Agriculture .AND. Account.SLAExpirationDate__c Between today() + -21d TO today() .AND. Account.Type ChangedFromTo Prospect , Other ) .OR. (  Account.Industry = Apparel  .AND. Account.Type ChangedFromTo Prospect , Other .AND. Account.SLAExpirationDate__c Between today() + -7d TO today() )","(1 AND 2 AND 3) OR (4 AND 5 AND 6)","<aUpsert:Integration__c~Status__c=0 - NEW~Type__c=Job Order~SObject_ID__c={!Id}~Endpoint__c=TCAST/a>"' + '\n';

        csv +=  '"Account","Account","AccountLookup","Updates a field on Account with a value retrieved from unrelated object to Account. The unrelated object serves as a lookup to Account. Both object share common field(s) that are utilized to reterieve the requested value","","Create, Edit","Exit",'
        + '"Account.Industry = Agriculture","1","<aUpdate:LookupObjectField:Account.Description:Lookup Object=Lead:LookupFromFieldName=Description:LookupValue=:Condition=Industry=\'Agriculture\' AND LastName= \'Bab\'/a>"' +'\n';

        csv +=  '"Account","Account","Rule with Insert Action and Merge field","Insert a New Contact when a condition on the Account is true","","Create, Edit","Continue",'+
        '"Account.Industry = Agriculture","1","<aInsert:Contact~LastName=Doe~FirstName=Joe~Title=Executive Producer~Salutation=Prof.~Description=Example of inserting a contact from an account~Phone={!Phone}~MailingCity={!BillingCity}~MailingStreet={!BillingStreet}~MailingCountry={!BillingCountry}~EmailBouncedDate={!SLAExpirationDate__c} +60d/a>"' + '\n';

        csv +=  '"Account","Account","Execute Apex Callouts from AWE","Execute Apex Callouts from AWE","","Create, Edit","Continue","Account.Industry = Agriculture",'
        + '"1","<aApexJob:InputParam=parent:Industry~OutputParam=desc:description~Object=Account~ApexClass=AW_ApexJob_ActionSample/a>"' + '\n';
        
        csv +=  '"Account","Account","Rule with changeFromTo and IsChanged as Filter Criteria","Account ChangeFromTo and IsChanged","","Create, Edit","Continue",'
                 + '"Account.Type ChangedFromTo Prospect , Other    .AND.   Account.Industry IsChanged","1 AND 2","<aUpdate:Account.OwnerId=Awe Awe/a>"' + '\n'; 
        csv += '"Account","Account","CrossFormula Reference Field","CrossFormula Reference Field  Account has a lookup relationship to RegionLookUp__c  where Plan_Category__c  is a field of the RegionLookUp__c","","Create, Edit","Continue",'
                + '"CrossFormula.RegionLookUp__r.Plan_Category__c STARTSWITH ABC","<aUpdate:Account.OwnerId=Awe Awe/a>"\n';
        csv += '"Account","Account","OwnerPriortization","OwnerPriortization","","Create,Edit","Exit","Account.Industry = Agriculture",'
                +  '"1","<aUpdate:OwnerPrioritizationField:Account.OwnerId:Method=Round Robin~User=Appirio User, Weight=1, Priority=2~User=Awe Awe, Weight=1, Priority=1~User=John Travolta,Weight=1,Priority=0/a>"\n';
        
        csv += '"Account","Account","Rule With Multiple actions one of which is Send Email","2 criteria with AND logic and Between Date Operator 1 Update Owner id with value 1 Update Value with Merge Field 1 Insert Related Object 1 Send Email with All elements ( User, Folder TemplateAdditional Emails)"'
                + ',"","Create, Edit","Continue","Account.SLAExpirationDate__c Between 10/1/2009 TO 10/1/2013   .AND.   Account.BillingCountry = USA","1 AND 2",'
                + '<aUpdate:Account.OwnerId=Awe Awe/a><aInsert:Contact~LastName=Smith&T~OwnerId=Awe Awe~Description=The old-school marketing format has survived to play a crucial creative role in modern e-commerce. Today,  AT&T publishes the catalog is bait for customers, like a store window display, and a source of inspiration, the way roaming through store aisles can be. The hope is that  AT& T shoppers will mark pages they like and then head online, or into a store, to buy.~EmailBouncedDate={!SLAExpirationDate__c}/a><aUpdate:Account.RegionLookup__c={!OwnerId}/a><aSendEmail:Template=Support: Sales Account Ownership Notification~Folder=00l70000001Co4OAAS~User=Awe Awe~AdditionalEmails=pan@email.com,pba@email.com,george@email.com~/a>"\n';
                 
        csv += '"Account","Account","Update field of a child object","Update Title and Description of all contacts (child object ) related to an Account","","Create, Edit","Continue","Account.Industry = Agriculture","1","<aUpdate:Contact.Description=This is a sample from Import/a><aUpdate:Contact.Title=Tour Guide/a>"\n';
        csv += '"Account","Account","Fifteen criteria","15 criteria with AND/OR logic 1 Insert Related Object 1 Upsert Unrelated Object 1 Update with URL value","","Create, Edit","Continue","(( Account.Industry = Apparel .OR. Account.Industry = Banking .OR. Account.Industry = Biotechnology .OR. Account.Industry = Chemicals ) .OR. Account.Industry = Communications .OR. Account.Industry = Consulting .OR. Account.Industry = Not For Profit .OR. Account.Industry = Technology .OR. Account.Industry = Utilities .OR. Account.Industry = Apparel .OR. ( Account.Industry = Apparel .OR. Account.Industry = Apparel .OR. Account.Industry = Apparel .OR. Account.Industry = Banking .OR. Account.Industry = Apparel .OR. Account.Industry = Biotechnology ) )","((1 OR 2 OR 3 OR 4) OR 5 OR 6 OR 7 OR 8 OR 9 OR 10 OR (11 OR 12 OR 13 OR 14))",'
                + '"<aUpdate:Account.Website=http://infoworks.power.amers.becpsn.com/infoworks/drl/objectId/090224f080079610/a><aUpdate:Account.Type=Technology Partner/a><aInsert:Opportunity~StageName=Prospecting~OwnerId=Awe Awe~CloseDate=Today()+ 30d~Name=Opp1-PAO~Amount=100.00/a><aUpsertUnrelated:Campaign~Type=Advertisement~BudgetedCost=10000~EndDate=Today()+30d~Status=In Progress~StartDate=Today() ~ActualCost=100~OwnerId=Awe Awe~IsActive=true~Name=AWE awarnes/a>"\n'; 
        csv +=  '"Case","Case","Cross Object Boolean","Cross Object Boolean","","Create,Edit","Continue","Case.Status = Escalated .AND. Case.Type = Mechanical","1 AND 2",'
        + '"<aUpdate:CrossObjectField:Account.CheckBox2__c=True/a>"' + '\n';
        
        csv += '"Lead","Lead","Complex AND,OR Filter Logic with Update OwnerId as action","Complex AND,OR Filter Logic with Between, Include and Exclude operator, Cross Formula fields Recortype fields",""'
                + ',"Create, Edit","Continue","Lead.Lead_Score__c !=NULL .AND. Lead.Size_of_Company__c Between 100 TO 9999999 .AND.  CrossFormula.Territory__r.Name = US AR .AND. Lead.Industry_Header_PL__c EXCLUDES Biotechnology,Consumer Products,Entertainment & Media,Financial Services,Healthcare-Private,Healthcare-Public,High Technology,ISP .AND. Lead.Account_Type__c INCLUDES Prospect,Customer .AND. Lead.Sophos_Product_Interest__c INCLUDES Email,Encryption,Endpoint,Mobile,Small Business,Web,UTM/Network Security,Other .AND. Lead.RecordTypeId = Sophos Generated-AE","1 AND 2 AND  3 AND 4 AND 5 AND 6 AND 7","<aUpdate:Lead.OwnerId=Awe Awe/a>"'+ '\n';

        csv += '"Lead","Lead","Chatter Notification Group","Chatter Notification Group","","Create,Edit","Exit","Account.Industry = Agriculture","1",'
             + '"<aChatterNotification:Account: ActionLabel=Some Label~SendToGroup=All Olive Wreath~Message=What do u think of Chatter Notification via AWE  ?/a>"\n';
             
        csv += '"Lead","Lead","Chatter Notification User","Chatter Notification User","","Create,Edit","Exit","Lead.Industry = Agriculture","1",'
             + '"<aChatterNotification:Lead: ActionLabel=Some Label~SendToUser=AWE AWE~Message=What do u think of Chatter Notification via AWE ?/a>"\n';
             
        csv += '"Lead","Lead","Assign Partner Lead Team Member","Assign Partner Lead Team Member","","Create, Edit","Exit","Lead.Assigned_to_Partner__c !=NULL","1",'
              + '"<aInsert:Partner_Lead_Team_Member__c~Assigned_To__c=true~Team_Member__c={!assigned_to_partner__r.partner_primary_lead_contact__c}~Team_Role__c=Reseller/a>"\n';
         
        csv += '"Lead","Lead","Update Bulk Mode","Update Bulk Mode","3","Create, Edit","Continue","Lead.Lead_Score__c != NULL   .AND.   Lead.Size_of_Company__c Between 10000 TO 9999999   .AND.   CrossFormula.Territory__r.Name = US AR   .AND.   Lead.Industry_Header_PL__c Aerospace & Defense,Biotechnology,Consumer Products,Entertainment & Media,Financial Services,Healthcare-Private,Healthcare-Public,High Technology,ISP   .AND.   Lead.Account_Type__c Prospect,Customer   .AND.   Lead.Sophos_Product_Interest__c Email,Encryption,Endpoint,Mobile,Small Business,Web,UTM/Network Security,Other   .AND.   Lead.RecordTypeId Partner Generated,Deal Registration","1  AND 2 AND 3 AND 4 AND 5 AND 6 AND 7","<aUpdateBulk:Lead.OwnerId=Awe Awe/a>"' +'\n';     
        csv += '"Lead","Lead","Insert Bulk Mode","Insert Bulk Mode","2","Create, Edit","Continue","Lead.Assigned_to_Partner__c !=NULL","1","<aInsertBulk:Partner_Lead_Team_Member__c~Assigned_To__c=true~Team_Role__c=Reseller~Team_Member__c={!assigned_to_partner__r.partner_primary_lead_contact__c}/a>"' +'\n';       
        csv +=  '"Opportunity","Opportunity","Oppty Cross Date","1 Update with Cross Object Field","","Record is created or edited","Execute Rule and Continue to Next Rule","Opportunity.StageName = Prospecting .OR. Opportunity.Description startsWith Pros","1 OR 2",'
        + '"<aUpdate:CrossObjectField:Account.SLAExpirationDate__c =Today()  + 360d/a>"' + '\n';
        csv += '"Opportunity","Opportunity","Create a Case from Oppty WF","Create a Case from Oppty 1","","Create, Edit","Continue","CrossFormula.Account.BillingState INCLUDES CA,TX   .AND.   Opportunity.LeadSource = Web   .AND.   Opportunity.StageName = Closed Won","1 AND 2 AND 3","<aInsert:Case~AccountId={!AccountId}~OwnerId=US - Platinum/Gold~Reason=Feedback~Origin=Web~Description={!Description}~Subject={!Name}~Status=New/a>"\n'; 
        csv += '"Task","Task","Rule with Update CrossObject field Task Description and Status","Rule with Update CrossObject field Task Description and Status","","Create, Edit","Exit","Task.Status = Completed","1",'
                + '<aUpdate:CrossObjectField:WhatId.Description=Some Value/a><aUpdate:CrossObjectField:WhatId.Status={!Status}/a>\n';
        
        return csv;
    }
}
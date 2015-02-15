// 
// (c) 2012 Appirio, Inc.
//
// AW_SendEmailUtil                                                     
//
//  Utility Class to send mail 
//  
//
// 3  Oct 2012     Peter Babalis     Original
// 11 Nov 2012     Cloud Challenger
//  
//  
public with sharing class AW_SendEmailUtil {
    
    /**
    * Send email to passed email address with content present in email body list
    */
    public void sendEmail(List<String> emailAddress,List<String> emailBodyList){
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Integer i = 0;
        for(string email:  emailAddress){
            Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
            String emailBody = emailBodyList[i]; 
            singleEmail.setHTMLBody(emailBody);
       //     singleEmail.setHTMLBody(htmlBody);
            singleEmail.setSubject('Records Assigned to you');
            singleEmail.setToAddresses( new List<String>{email});
            singleEmail.setPlainTextBody(emailBody);
            i++;
            emailList.add(singleEmail);
        }
        
        Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList); 
    }
     //added a method that will send email with attachment
    public static Boolean sendEmailwithAttachment(Attachment a){
        
        Messaging.SingleEmailMessage    mail    =   new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment   attach  =   new Messaging.EmailFileAttachment();
        attach.setContentType('text/xml');
        attach.setFileName('ExportResult.xml');
        attach.setInline(false);
        attach.Body = a.Body;
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
        mail.setSenderDisplayName('Advance Workflow Notification');     
        List<String>                    lEmails =   new List<String>();
        String userName = UserInfo.getUserName();
        User activeUser = [Select Email From User where Username = : userName limit 1];
        String userEmail = activeUser.Email;
        lEmails.add(userEmail);
        mail.setToAddresses(lEmails);
        mail.setSubject('Export Advance Workflow process ');
        mail.setHtmlBody('Please, check the attached mail file.');
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            return true;
        }
        catch(Exception e){
            return false;
        }
    }
    
    //added a method that will send email with templates
    /*
      Modified this method to handle emails in custom way
    */
    /*public void sendEmail(Map<Id,User> user,Map<String,Map<String,List<RuleAction__c>>> userEmailInfo){
        
         List<String> templateIds= new List<String>();
         for(String userId : userEmailInfo.keySet()){
                
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){                    
                    for(RuleAction__c action  : emailInfo.get(recordId)){  
                       templateIds.add(action.email_template__c);                                        
                    }
                }                
        } 
        Map<Id,EmailTemplate> templateData=new Map<Id,EmailTemplate>([Select Id,Body,Subject,TemplateType,HtmlValue FROM EmailTemplate WHERE Id IN:templateIds]);
             
        //Due to salesforce limitation: we will convert user to contact & the send emails :-        
        Map<String,Contact> contactUsers= new Map<String,Contact>();
        
        List<Contact> contacts=new List<Contact>();
        for(User u : user.values()){         
                contacts.add(new Contact(FirstName=u.FirstName,LastName=u.LastName,email=u.email,Description=u.Id));
        }
        if(contacts.size()>0)insert contacts;
                
        for(Contact c: contacts)
            contactUsers.put(c.Description,c);
        
        List<String> contactId= new List<String>();
        List<String> LeadId= new List<String>();
         
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String userId : userEmailInfo.keySet()){
                //string emailId = users.get(userId).Email;
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){                    
                    for(RuleAction__c action  : emailInfo.get(recordId)){
                       String templateId = action.email_template__c;  
                       EmailTemplate t= templateData.get(templateId);                
                       Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();                                             
                        singleEmail.setTemplateID(templateId);
                        String target =  t.TemplateType.toLowerCase()=='visualforce' ? userId:contactUsers.get(userId).Id;
                        singleEmail.setTargetObjectId(target );
                        singleEmail.setSaveAsActivity(false);
                        Id referenceId = Id.valueof(recordId);
                        if((referenceId.getSObjectType() != Contact.SobjectType && referenceId.getSObjectType() != Lead.SobjectType) || t.TemplateType.toLowerCase()=='visualforce'){
                            //updating it to incorporate the latest change
                            singleEmail.setWhatId(recordId);
                            emailList.add(singleEmail); 
                        }
                        else if(referenceId.getSObjectType() == Contact.SobjectType)   
                             contactId.add(recordId);
                        else if(referenceId.getSObjectType() == Lead.SobjectType)                   
                             LeadId.add(recordId);
                        
                        
                        //Adding on 31 May
                        
                    }
                }                
        }
        if(emailList.size()>0) Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
        
        //now some maula processing required for lead & contact
        if(contactId.size()>0 ){
            //we have contacts so manual processing for sending is required            
            processContactEmails(user,userEmailInfo,templateData,contactId);
        }
        
        if(LeadId.size()>0 ){
            //we have lead so manual processing for sending is required            
            processLeadEmails(user,userEmailInfo,templateData,LeadId);
        }
    
        delete  contacts;  
             
    }*/
    
    public void sendEmail(Map<Id,User> user,Map<String,Map<String,List<RuleAction__c>>> userEmailInfo){
        
         List<String> templateIds= new List<String>();
         for(String userId : userEmailInfo.keySet()){
                
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){                    
                    for(RuleAction__c action  : emailInfo.get(recordId)){  
                       templateIds.add(action.email_template__c);                                        
                    }
                }                
        }
         
        Map<Id,EmailTemplate> templateData=new Map<Id,EmailTemplate>([Select Id,Body,Subject,TemplateType,HtmlValue FROM EmailTemplate WHERE Id IN:templateIds]);
       	
       	If(templateData == null || templateData.size() == 0) return;  
        
        Map<String,Set<Id>> objIds = new Map<String,Set<Id>>();
        
        for(String userId : userEmailInfo.keySet()){
                //string emailId = users.get(userId).Email;
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){  
                     Id referenceId = Id.valueof(recordId);
                     String objectAPIName = referenceId.getSObjectType().getDescribe().getName().toLowerCase();
                     Set<Id> objinfo = objIds.get(objectAPIName)!=null ? objIds.get(objectAPIName): new Set<Id> ();
                     objinfo.add(referenceId);
                     objIds.put(objectAPIName,objinfo);
                }
        }
        
        Map<Id,SObject> records = new Map<Id,SObject>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 

        for(String objName : objIds.keySet()){
            Map<String, Schema.SObjectField> M = gd.get(objName).getDescribe().fields.getMap();
            List<String> fields=new List<String>();
            fields.addAll(M.keySet());
            Set<Id> ids = objIds.get(objName);  
            String query = 'Select '+String.join(fields,',')+' FROM '+objName+' WHERE Id IN:ids';
            List<SObject> rds= Database.query(query);
            
            for(SOBject o : rds)records.put(o.Id,o); 
            
        }
        
         User currentUser = [SELECT Id,
                                   Name,
                                   FirstName,
                                   LastName 
                            FROM   User 
                            WHERE  Id=:UserInfo.getUserId()];
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String userId : userEmailInfo.keySet()){
                string emailId = user.get(userId).Email;
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){ 
                    Id referenceId = Id.valueof(recordId);
                    
                    for(RuleAction__c a  : emailInfo.get(recordId)){  
                          String templateId = a.email_template__c;
                          Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                          //since this contains text & not html
                          String emailBody= replaceMergeFields(templateData.get(templateId).Body,records.get(recordId),user.get(userId),currentUser );
                          String htmlBody = emailBody;
                          
                          if(templateData.get(templateId).HtmlValue!=null)
                          	 htmlBody =  replaceMergeFields(templateData.get(templateId).HtmlValue,records.get(recordId),user.get(userId),currentUser );
                          
                          singleEmail.setHTMLBody(htmlBody);
                          String subject = replaceMergeFields(templateData.get(templateId).Subject,records.get(recordId),user.get(userId),currentUser );
                          singleEmail.setSubject(subject);
                          List<String> emailAddress = new List<String>();
                           
                          if(a.additional_emails__c!=null){
                          	system.debug('-->a.additional_emails__c '+a.additional_emails__c);
                            emailAddress.addAll(a.additional_emails__c.split(',')); 
                          }
                          
                         if(a.User_Owner_Id__c!=null)
                            emailAddress.add(emailId);
                            
                          system.debug(emailAddress);
                          if(emailAddress.size()==0)continue;
                          
                          singleEmail.setToAddresses( emailAddress);
                          singleEmail.setPlainTextBody(emailBody);
                          singleEmail.setSaveAsActivity(false);
                          emailList.add(singleEmail);
                    }
                }                
        }
        system.debug('-->emailList '+emailList);
        
        if(emailList.size()>0) Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
    }
    
    //added a method that will send email with templates
    /*public void sendEmail(Map<Id,User> user,Map<String,Map<String,List<String>>> userEmailInfo){
        
         List<String> templateIds= new List<String>();
         for(String userId : userEmailInfo.keySet()){
                
                Map<String,List<String>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){                    
                    for(String templateId : emailInfo.get(recordId)){  
                       templateIds.add(templateId);                                        
                    }
                }                
        } 
        Map<Id,EmailTemplate> templateData=new Map<Id,EmailTemplate>([Select Id,Body,Subject,TemplateType,HtmlValue FROM EmailTemplate WHERE Id IN:templateIds]);
             
        //Due to salesforce limitation: we will convert user to contact & the send emails :-        
        Map<String,Contact> contactUsers= new Map<String,Contact>();
        
        List<Contact> contacts=new List<Contact>();
        for(User u : user.values()){         
                contacts.add(new Contact(FirstName=u.FirstName,LastName=u.LastName,email=u.email,Description=u.Id));
        }
        if(contacts.size()>0)insert contacts;
                
        for(Contact c: contacts)
            contactUsers.put(c.Description,c);
        
        List<String> contactId= new List<String>();
        List<String> LeadId= new List<String>();
        
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String userId : userEmailInfo.keySet()){
                //string emailId = users.get(userId).Email;
                Map<String,List<String>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){                    
                    for(String templateId : emailInfo.get(recordId)){  
                       EmailTemplate t= templateData.get(templateId);                
                       Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                        //singleEmail.setToAddresses( new List<String>{emailId});                        
                        singleEmail.setTemplateID(templateId);
                        String target =  t.TemplateType.toLowerCase()=='visualforce' ? userId:contactUsers.get(userId).Id;
                        singleEmail.setTargetObjectId(target );
                        singleEmail.setSaveAsActivity(false);
                        Id referenceId = Id.valueof(recordId);
                        if((referenceId.getSObjectType() != Contact.SobjectType && referenceId.getSObjectType() != Lead.SobjectType) || t.TemplateType.toLowerCase()=='visualforce'){
                            singleEmail.setWhatId(recordId);
                            emailList.add(singleEmail); 
                        }
                        else if(referenceId.getSObjectType() == Contact.SobjectType)   
                             contactId.add(recordId);
                        else if(referenceId.getSObjectType() == Lead.SobjectType)                   
                             LeadId.add(recordId);
                    }
                }                
        }
        if(emailList.size()>0) Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
        
        //now some maula processing required for lead & contact
        if(contactId.size()>0 ){
            //we have contacts so manual processing for sending is required            
            //processContactEmails(user,userEmailInfo,templateData,contactId);
        }
        
        if(LeadId.size()>0 ){
            //we have lead so manual processing for sending is required            
            //processLeadEmails(user,userEmailInfo,templateData,LeadId);
        }
    
        delete  contacts;            
    }*/
    
    /*
    private void processContactEmails(Map<Id,User> user,Map<String,Map<String,List<RuleAction__c>>> userEmailInfo,Map<Id,EmailTemplate> templateData,List<String> contactId)
    {   
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Contact.fields.getMap();
        List<String> fields=new List<String>();
        fields.addAll(M.keySet());
        String query = 'Select '+String.join(fields,',')+' FROM Contact WHERE Id IN:contactId';
        List<Contact> contacts= Database.query(query);
        
        User currentUser = [SELECT Id,
                                   Name,
                                   FirstName,
                                   LastName 
                            FROM   User 
                            WHERE  Id=:UserInfo.getUserId()];
        
        Map<Id,Contact> contact_m= new Map<Id,Contact>();
        
        for(Contact c: contacts)
            contact_m.put(c.Id,c);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String userId : userEmailInfo.keySet()){
                string emailId = user.get(userId).Email;
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){ 
                    Id referenceId = Id.valueof(recordId);
                    if(referenceId.getSObjectType() != Contact.SobjectType)
                       continue;                  
                    
                    for(RuleAction__c a  : emailInfo.get(recordId)){  
                          String templateId = a.email_template__c;
                          Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                          String emailBody= replaceMergeFields(templateData.get(templateId).Body,contact_m.get(recordId),user.get(userId),currentUser );
                          singleEmail.setHTMLBody(emailBody);
                          singleEmail.setSubject(templateData.get(templateId).Subject);
                          singleEmail.setToAddresses( new List<String>{emailId });
                          singleEmail.setPlainTextBody(emailBody);
                           singleEmail.setSaveAsActivity(false);
                          emailList.add(singleEmail);
                    }
                }                
        }
        if(emailList.size()>0) Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
        
        
    }
   
    private void processLeadEmails(Map<Id,User> user,Map<String,Map<String,List<RuleAction__c>>> userEmailInfo,Map<Id,EmailTemplate> templateData,List<String> leadId)
    {  
    
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Lead.fields.getMap();
        List<String> fields=new List<String>();
        fields.addAll(M.keySet());
        String query = 'Select '+String.join(fields,',')+' FROM Lead WHERE Id IN:leadId';
        List<Lead> leads= Database.query(query);
        
        User currentUser = [Select Id,Name,FirstName,LastName FROM User WHERE Id=:UserInfo.getUserId()];
        
        Map<Id,Lead> lead_m= new Map<Id,Lead>();
        
        for(Lead c: leads)
            lead_m.put(c.Id,c);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(String userId : userEmailInfo.keySet()){
                string emailId = user.get(userId).Email;
                Map<String,List<RuleAction__c>> emailInfo = userEmailInfo.get(userId);
                for(String recordId : emailInfo.keySet()){ 
                    Id referenceId = Id.valueof(recordId);
                    if(referenceId.getSObjectType() != Lead.SobjectType)
                       continue;                  
                    
                    for(RuleAction__c a  : emailInfo.get(recordId)){  
                          String templateId = a.email_template__c;
                          Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                          String emailBody= replaceMergeFields(templateData.get(templateId).Body,lead_m.get(recordId),user.get(userId),currentUser );
                          singleEmail.setHTMLBody(emailBody);
                          singleEmail.setSubject(templateData.get(templateId).Subject);
                          singleEmail.setToAddresses( new List<String>{emailId });
                          singleEmail.setPlainTextBody(emailBody);
                          singleEmail.setSaveAsActivity(false);
                          emailList.add(singleEmail);
                    }
                }                
        }
        if(emailList.size()>0) Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
     
    }*/
    
    private String replaceMergeFields(String text,SObject c,User u ,User currentUser){
        String thePattern = '\\{!((\\w+)\\.(\\w+))\\}';
        Pattern myPattern = Pattern.compile(thePattern);
        Matcher myMatcher = myPattern.matcher(text);
        
        while(myMatcher.find()){
           try{
               if(myMatcher.group(2)=='Receiving_User' || myMatcher.group(2)=='Owner')
                   text=text.replace('{!'+myMatcher.group(1)+'}',string.valueof(u.get(myMatcher.group(3))));
               else if(myMatcher.group(2)=='User')
                   text=text.replace('{!'+myMatcher.group(1)+'}',string.valueof(currentUser.get(myMatcher.group(3))));
               else 
                   text=text.replace('{!'+myMatcher.group(1)+'}',string.valueof(c.get(myMatcher.group(3))));
           }catch(Exception e){
                   text=text.replace('{!'+myMatcher.group(1)+'}','');
           }                           
        }
        return text;
    }

}
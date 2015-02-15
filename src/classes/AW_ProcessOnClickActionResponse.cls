global class AW_ProcessOnClickActionResponse implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope) {
 
    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
    
     //get the response id from the subject : Response#<responseid>:subject;
     String responseId= email.subject.split(':')[0].split('#')[1];
     ClickEventActionResponse__c res =[Select recordid__c ,responseid__c,response_name__c FROM ClickEventActionResponse__c  WHERE Id=:responseId];
     //Create a task as a response:-

     Task newTask= new Task( subject = email.subject.split(':')[1], 
                        Description= email.plaintextbody,
                        ActivityDate = System.today(),
                        Priority = 'Medium',
                        Status = 'Closed'                    
                       );
    Id recordId = Id.valueof(res.recordid__c);
    if(recordId.getSObjectType()==Contact.SobjectType || recordId.getSObjectType()==Lead.SobjectType)
        newTask.whoId=recordId ;
    else if(recordId.getSObjectType()==User.SobjectType)
        newTask.ownerid=recordId;
    else
        newTask.whatId=recordId ;
    
    // Insert the new Task 
    insert newTask;   
 
    if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
       List<Attachment> attachments = new List<attachment>();
      for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
        Attachment attachment = new Attachment();
        // attach to the newly created contact record
        attachment.ParentId = newTask.Id;
        attachment.Name = email.binaryAttachments[i].filename;
        attachment.Body = email.binaryAttachments[i].body;
        attachments.add(attachment);
      }
      insert attachments ;
    }
    res.response_name__c=newTask.subject;
    res.responseid__c=newTask.id;
    update res;
    
    return result;
 
  }
 
}
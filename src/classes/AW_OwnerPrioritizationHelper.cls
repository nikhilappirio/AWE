public class AW_OwnerPrioritizationHelper{
         /*
           Based on the method of assignment this class returns the owner id for which the
           record needs to be assigned
        */
        static Map<Id,RuleAction__c> ownerPriorityRecords = new Map<Id,RuleAction__c>();
        
        // global custom settings for AssignmentEngine
		private static Assignment_Setup__c setup;
		// unit percent per weight: this controls the max assignment for the given weight
		private static Decimal unitPercent = 0;
		static {
			setup = Assignment_Setup__c.getOrgDefaults();			
			//unitPercent = setup.Max_Assignment__c / (setup.Number_Of_Weight__c - 1);
		}
        
       
        public static String assign_basedonRoundRobin(RuleAction__c action){
             
             system.debug('->ownerpriortizations val.action  '+action);
             system.debug('->ownerpriortizations val.ownerPriorityRecords  '+ownerPriorityRecords);
             
             
             List<OwnerPrioritization__c> roundrobinEntries = ownerPriorityRecords.get(action.id).Owner_Prioritization__r;
             
             //sort the list based on priority:-
             //sortList(roundrobinEntries,'Priority__c','asc');
             sortList(roundrobinEntries,'Priority__c','desc');
             
             // choose the entry with highest score
			 OwnerPrioritization__c highest = roundrobinEntries.get(0);
			  
			 // update after assign			 
			for (OwnerPrioritization__c entry : roundrobinEntries) {
				 system.debug('->entry  '+entry);
				 system.debug('->entry  '+entry.Priority__c);
				if (entry.Priority__c >=0 ) { 
				// update Assigned and adjust Priority
				if (entry.Id == highest.Id) {
					entry.Priority__c = 0;
					entry.Assigned__c =entry.Assigned__c==null?  1:entry.Assigned__c+1;
				} else {
					entry.Priority__c += 1;
				}
			}	
				 
			}
			// update all  records
			update roundrobinEntries;			
			// return the assigned user to trigger
			return highest.User_Queue_Group_Id__c;
			
        }
        
        public static String assign_basedonWeightedCalculation(RuleAction__c action){
               
                // calculate total number of records assigned so far
				AggregateResult[] results =  [SELECT SUM(Assigned__c) sum FROM OwnerPrioritization__c];
				
				Integer total = ((Decimal)results[0].get('sum')).intValue();
		
               // get OwnerPrioritization__c records
				List<OwnerPrioritization__c> weightedEntries = ownerPriorityRecords.get(action.id).Owner_Prioritization__r;
				
				sortList(weightedEntries,'Percent__c','asc');					
				
				List<OwnerPrioritization__c> candidates = new List<OwnerPrioritization__c>();
				
				// the entry with the minimun Percent in this interaion
				OwnerPrioritization__c minPercentEntry = weightedEntries.get(0);
				
				// select candiddates whose Percent hasn't reached to the max allowed Percent
				for (OwnerPrioritization__c entry : weightedEntries) {
					if (entry.Id == minPercentEntry.Id) {		// entry with min percent of assignment
						candidates.add(entry);
					} else {
						Decimal diffWeight = (entry.Weight__c - minPercentEntry.Weight__c).abs();
						Decimal maxAllowed = diffWeight * unitPercent;
						Decimal diffPercent = (entry.Percent__c - minPercentEntry.Percent__c).abs();
						if (diffPercent < maxAllowed)
							candidates.add(entry);
					}
				}
				
				// choose the entry with highest score
				OwnerPrioritization__c highest = candidates.get(0);
				for (OwnerPrioritization__c entry : candidates) {
					Decimal score = entry.Weight__c + (entry.Priority__c / setup.Priority_Divisor__c);
					if (score > (highest.Weight__c + (highest.Priority__c / setup.Priority_Divisor__c)))
						highest = entry;
				}
				//System.debug('highest: '+highest.Weight__c);
				
				// update after assign
				total += 1;
				for (OwnerPrioritization__c entry : weightedEntries) {
					// update Assigned and adjust Priority
					if (entry.Id == highest.Id) {
						entry.Priority__c = 0;
						entry.Assigned__c += 1; 
					} else {
						entry.Priority__c += 1;
					}
					// update Percent
					Decimal assigned = entry.Assigned__c;
					Decimal percent = assigned.divide(total, 2)*100;
					entry.Percent__c = percent;
				}
				// update all WeightedAssignment records
				update weightedEntries;
				
				// return the assigned user to trigger
				return highest.User_Queue_Group_Id__c;
        }
        
        public static void getOwnerPrioritizationRecords(Set<Id> actionIds){
        	ownerPriorityRecords = new Map<Id,RuleAction__c>(
        								[Select Id,(Select User_Queue_Group_Id__c,Assigned__c,Percent__c,Priority__c,Weight__c FROM Owner_Prioritization__r )
        								 FROM RuleAction__c WHERE Rule__c IN:actionIds
        								]
        							); 	
        }
        
        public static void sortList(List<Sobject> items, String sortField, String order){
		       List<Sobject> resultList = new List<Sobject>();
		   
		        //Create a map that can be used for sorting 
		       Map<object, List<Sobject>> objectMap = new Map<object, List<Sobject>>();
		           
		       for(Sobject ob : items){
		                if(objectMap.get(ob.get(sortField)) == null){  // For non Sobject use obj.ProperyName
		                    objectMap.put(ob.get(sortField), new List<Sobject>()); 
		                }
		                objectMap.get(ob.get(sortField)).add(ob);
		        }       
		        //Sort the keys
		        List<object> keys = new List<object>(objectMap.keySet());
		        keys.sort();
		       
		        for(object key : keys){ 
		            resultList.addAll(objectMap.get(key)); 
		        }
		       
		        //Apply the sorted values to the source list
		        items.clear();
		        if(order.toLowerCase() == 'asc'){
		            for(Sobject ob : resultList){
		                items.add(ob); 
		            }
		        }else if(order.toLowerCase() == 'desc'){
		            for(integer i = resultList.size()-1; i >= 0; i--){
		                items.add(resultList[i]);  
		            }
		        }
	    }

}
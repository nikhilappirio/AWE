@IsTest
public class AW_MergeFieldSelector_Test{
	
	
		static testmethod void testGetFields(){
			
				AW_MergeFieldSelector ctrl= new AW_MergeFieldSelector();
				
				Test.startTest();
					ctrl.objName ='Account';
					ctrl.getFields();
				Test.stopTest();
				
				system.assert(ctrl.fieldData.size()==1);
			
		}
		
		static testmethod void testGetFields2(){
			
				AW_MergeFieldSelector ctrl= new AW_MergeFieldSelector();
				
				Test.startTest();
					ctrl.objName ='Account';
					ctrl.index='0';
					ctrl.getFields();
					
					system.assert(ctrl.fieldData.size()==1);
					ctrl.objName='User';
					ctrl.index='1';
					ctrl.getFields();
					
					system.assert(ctrl.fieldData.size()==2);
					
					ctrl.objName='User';
					ctrl.index='2';
					ctrl.getFields();
					
					system.assert(ctrl.fieldData.size()==3);
					
					ctrl.objName='User';
					ctrl.index='1';
					ctrl.getFields();
					
					//system.assert(ctrl.fieldData.size()==2);
					
				Test.stopTest();
		}
		
		static testmethod void testReset(){
				
				AW_MergeFieldSelector ctrl= new AW_MergeFieldSelector();
				
				Test.startTest();
					ctrl.objName ='Account';
					ctrl.getFields();
					
					system.assert(ctrl.fieldData.size()==1);
					
					ctrl.reset();
					system.assert(ctrl.fieldData.size()==0);
				Test.stopTest();
			
		}

}
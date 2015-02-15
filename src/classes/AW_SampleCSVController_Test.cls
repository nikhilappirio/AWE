/**
 *Test class for AW_SampleCSVController
 */
@isTest
private class AW_SampleCSVController_Test {

    static testMethod void testSampleCSV() {
         AW_SampleCSVController sampleCSV = new  AW_SampleCSVController();
         System.assert(sampleCSV.csvBody != null);
    }
}
public with sharing class AW_ImportExportHelper {

	/*
    * load Reference Id
    */
   public static Map<String , Map<String, Id>> loadReferenceIds(Map<String , Map<String, Id>> referenceFieldIdMap , String keyField, String valField){
        for(String objName : referenceFieldIdMap.keySet()){
            Set<String> ids = referenceFieldIdMap.get(objName).keySet();
            String soqlQuery = ' SELECT Id , Name';
            soqlQuery += ' FROM '+ objName  + ' WHERE  ' + keyField + ' in : ids';
            for(Sobject sobj : Database.query(soqlQuery)){
                referenceFieldIdMap.get(objName).put((String)sobj.get(keyField) ,(String) sobj.get(valField));
            } 
        }
        return referenceFieldIdMap;
    }
   
   
   public static String blobToString(blob b , String encoding){
   		String hex = EncodingUtil.convertToHex(b);
		Integer bytesCount = hex.length() >> 1;
	    String[] bytes = new String[bytesCount];
	    for(Integer i = 0; i < bytesCount; ++i)
	        bytes[i] =  hex.mid(i << 1, 2);
	      System.debug('::bytes'+bytes);
	    return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), encoding);
   }

}
public with sharing class DynamicPicklistController {

    @AuraEnabled
    public static string fetchAccounts(){
        ReturnWrapper wrap = new ReturnWrapper();
        try {
            wrap.returnValue = new Map<string, Object>();
            List<Account> accountList = new List<Account>();
            for(Account a : [select Id, Name, Country__c, State__c from Account])
            {
                accountList.add(a);
            }
            wrap.returnValue.put('accountList', accountList);
            wrap.isSuccess = true;
        } catch (Exception e) {
            wrap.errorMsgs = new List<String>{e.getMessage()};
            wrap.isSuccess = false;
        }
        return JSON.serialize(wrap);
    }

    @AuraEnabled(cacheable=true)
    public static String fetchPicklistOptions(String objectName, String controlFieldName, String dependFieldName){
        ReturnWrapper wrap = new ReturnWrapper();
        try {
            wrap.returnValue = new Map<string, Object>();
            //Use your own method to build the map of picklist dependency
            //I am using schema objects to find the dependencies of picklist options
            DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
            DescribeFieldResult controlFieldResult = objResult.fields.getMap().get(controlFieldName).getDescribe();
            List<Schema.PicklistEntry> controlOptions = controlFieldResult.getPicklistValues();
            wrap.returnValue.put('controlOptions', controlOptions);
            DescribeFieldResult dependFieldResult = objResult.fields.getMap().get(dependFieldName).getDescribe();
            Map<Object,List<String>> optionsMap = DynamicPicklistController.getDependentPicklistValues(dependFieldResult);
            wrap.returnValue.put('dependOptionsMap', optionsMap);
            wrap.isSuccess = true;
        } catch (Exception e) {
            wrap.errorMsgs = new List<String>{e.getMessage()};
            wrap.isSuccess = false;
        }
        return JSON.serialize(wrap);
    }

    private class ReturnWrapper
    {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String successMsg;
        
        @AuraEnabled public Map<string, Object> returnValue; 
        @AuraEnabled public List<String> errorMsgs;
    }

    public static Map<Object,List<String>> getDependentPicklistValues( Schema.DescribeFieldResult depend )
    {
        Schema.sObjectField controlToken = depend.getController();
        if ( controlToken == null ) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
        (   control.getType() == Schema.DisplayType.Boolean
        ?   null
        :   control.getPicklistValues()
        );
    
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) 
        if ( entry.isActive() )
        {
            System.debug('current picklist option '+entry.getLabel());
            List<String> base64chars =
                String.valueOf
                (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
                ).split( '' );
            System.debug('base64chars '+base64chars);
            for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
            {
                Object controlValue =
                (   controlEntries == null
                ?   (Object) (index == 1)
                :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                );
                System.debug('evaluating '+controlValue);
                Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                System.debug('bitIndex '+bitIndex);
                System.debug('bitShift '+bitShift);
                System.debug('shifted '+ (1 << bitShift));
                System.debug('index found '+ base64map.indexOf( base64chars[ bitIndex ] ));
                System.debug('& result'+ (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)));
                //the logic here is that data is stored in 6 bits. 000000. 
                //So for the index = 0 i.e for the first control value, the first bit has to be 1
                //so we do a & operation with a 6 bit binary number with first digit as 1 i.e 32 and if the result is 0, 
                //means the first digit is not 1 for the current picklist option
                //similarly for the 2nd control value, 2nd bti has to be 1, 
                //so we take a 5 bit binary number 10000 and do & operation. 
                if  (   controlValue == null
                    ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                    ) 
                    {
                        System.debug('skipping this');
                        continue;
                    }
                if ( !dependentPicklistValues.containsKey( controlValue ) )
                {
                    dependentPicklistValues.put( controlValue, new List<String>() );
                }
                System.debug('added in map '+controlValue + '-' + entry.getLabel());
                dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
            }
        }
        return dependentPicklistValues;
    }

    @AuraEnabled
    public static string saveAccounts(String accounts){
        ReturnWrapper wrap = new ReturnWrapper();
        try {
            wrap.returnValue = new Map<string, Object>();
            List<Account> accList = (List<Account>) JSON.deserialize(accounts, List<Account>.class);
            update accList;
            wrap.isSuccess = true;
            wrap.successMsg = 'Accounts are saved';
        } catch (Exception e) {
            wrap.errorMsgs = new List<String>{e.getMessage()};
            wrap.isSuccess = false;
        }
        return JSON.serialize(wrap);
    }
}

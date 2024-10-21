public with sharing class ContactTriggerHandler {

    // Future method to make a callout to the getDummyJSONUserFromId API
    @future(callout=true)
    public static void getDummyJSONUserForContacts(List<String> contactIds) {
        // Query contacts based on IDs
        List<Contact> contacts = [SELECT Id, DummyJSON_Id__c FROM Contact WHERE Id IN :contactIds];
        
        for (Contact con : contacts) {
            // Call the getDummyJSONUserFromId method
            DummyJSONCallout.getDummyJSONUserFromId(con.DummyJSON_Id__c);
        }
    }

    // Future method to make a callout to the postCreateDummyJSONUser API
    @future(callout=true)
    public static void postCreateDummyJSONUserForContacts(List<String> contactIds) {
        // Query contacts based on IDs
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id IN :contactIds];
        
        for (Contact con : contacts) {
            // Call the postCreateDummyJSONUser method
            DummyJSONCallout.postCreateDummyJSONUser(con.Id);
        }
    }
}

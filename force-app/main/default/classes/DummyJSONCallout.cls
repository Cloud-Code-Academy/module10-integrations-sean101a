/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	 public static void getDummyJSONUserFromId(String dummyUserId) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		
		// Set the endpoint URL
		String endpoint = 'https://dummyjson.com/users/' + dummyUserId;
		request.setEndpoint(endpoint);
		
		// Set the HTTP method to GET
		request.setMethod('GET');
		
		// Set the header to accept JSON response
		request.setHeader('Content-Type', 'application/json');
		
		try {
			// Send the request
			HttpResponse response = http.send(request);
			
			// Check if the response was successful (status code 200)
			if (response.getStatusCode() == 200) {
				// Parse the JSON response
				Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
				
				// Extract relevant data from the response
				String firstName = (String) responseMap.get('firstName');
				String lastName = (String) responseMap.get('lastName');
				String email = (String) responseMap.get('email');
				String phone = (String) responseMap.get('phone');
				String birthDateStr = (String) responseMap.get('birthDate'); // assuming birthdate is a string in the format 'yyyy-MM-dd'
				
				// Convert birthDate to Date if it exists
				Date birthDate = birthDateStr != null ? Date.valueOf(birthDateStr) : null;
				
				// Handle address extraction
				Map<String, Object> addressMap = (Map<String, Object>) responseMap.get('address');
				String street = addressMap != null && addressMap.containsKey('address') ? (String) addressMap.get('address') : null;
				String city = addressMap != null && addressMap.containsKey('city') ? (String) addressMap.get('city') : null;
				String postalCode = addressMap != null && addressMap.containsKey('postalCode') ? (String) addressMap.get('postalCode') : null;
				String state = addressMap != null && addressMap.containsKey('state') ? (String) addressMap.get('state') : null;
				String country = addressMap != null && addressMap.containsKey('country') ? (String) addressMap.get('country') : null;
				
				// Query for existing contact using the dummyUserId (DummyJSON_Id__c is an external id field)
				Contact contact = [SELECT Id, DummyJSON_Id__c FROM Contact WHERE DummyJSON_Id__c = :dummyUserId LIMIT 1];
				
				// If contact exists, update the contact details, otherwise create a new one
				if (contact != null) {
					contact.FirstName = firstName;
					contact.LastName = lastName;
					contact.Email = email;
					contact.Phone = phone;
					contact.Birthdate = birthDate;
					contact.MailingStreet = street;
					contact.MailingCity = city;
					contact.MailingPostalCode = postalCode;
					contact.MailingState = state;
					contact.MailingCountry = country;
				} else {
					contact = new Contact(
						FirstName = firstName,
						LastName = lastName,
						Email = email,
						Phone = phone,
						Birthdate = birthDate,
						MailingStreet = street,
						MailingCity = city,
						MailingPostalCode = postalCode,
						MailingState = state,
						MailingCountry = country,
						DummyJSON_Id__c = dummyUserId
					);
				}
				
				// Upsert contact (update if exists, insert if new) using the external id field DummyJSON_Id__c
				upsert contact DummyJSON_Id__c;
				
			} else {
				// Handle the error if the status code is not 200
				System.debug('Failed to get user info. Status code: ' + response.getStatusCode());
			}
		} catch (Exception e) {
			// Handle any exceptions that might occur during the callout
			System.debug('Error occurred during HTTP callout: ' + e.getMessage());
		}
	}	

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */

	 @TestVisible
	 private static Contact createContactFromJson(String jsonResponse) {
		 // Log the raw JSON response
		 System.debug('Raw JSON Response: ' + jsonResponse);
		 
		 // Deserialize the JSON string into a map of primitive data types
		 Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
		 System.debug('Deserialized responseMap: ' + responseMap);
		 
		 // Create a new contact object
		 Contact contact = new Contact();
		 
		 // Set the contact fields from the JSON response, ensure values exist
		 if (responseMap.containsKey('email')) {
			 contact.Email = (String) responseMap.get('email');
		 } else {
			 System.debug('Email not found in JSON response.');
		 }
		 
		 if (responseMap.containsKey('phone')) {
			 // Trim any whitespace just in case and ensure it's a string
			 contact.Phone = String.valueOf(responseMap.get('phone')).trim();
			 System.debug('Phone value set to: ' + contact.Phone);
		 } else {
			 System.debug('Phone not found in JSON response.');
		 }
	 
		 // Birthdate must be converted to Date from String (assuming the format is yyyy-MM-dd)
		 if (responseMap.containsKey('birthDate') && responseMap.get('birthDate') != null) {
			 contact.Birthdate = Date.valueOf((String) responseMap.get('birthDate'));
		 } else {
			 System.debug('Birthdate not found or null in JSON response.');
		 }
	 
		 // Deserialize the address from the JSON response
		 if (responseMap.containsKey('address') && responseMap.get('address') != null) {
			 Map<String, Object> addressMap = (Map<String, Object>) responseMap.get('address');
			 System.debug('Deserialized addressMap: ' + addressMap);
			 if (addressMap != null) {
				 if (addressMap.containsKey('address')) {
					 contact.MailingStreet = (String) addressMap.get('address');
				 } else {
					 System.debug('Street not found in address map.');
				 }
				 if (addressMap.containsKey('city')) {
					 contact.MailingCity = (String) addressMap.get('city');
				 } else {
					 System.debug('City not found in address map.');
				 }
				 if (addressMap.containsKey('postalCode')) {
					 contact.MailingPostalCode = (String) addressMap.get('postalCode');
				 } else {
					 System.debug('PostalCode not found in address map.');
				 }
				 if (addressMap.containsKey('state')) {
					 contact.MailingState = (String) addressMap.get('state');
				 } else {
					 System.debug('State not found in address map.');
				 }
				 if (addressMap.containsKey('country')) {
					 contact.MailingCountry = (String) addressMap.get('country');
				 } else {
					 System.debug('Country not found in address map.');
				 }
			 } else {
				 System.debug('Address map is null.');
			 }
		 } else {
			 System.debug('Address not found or null in JSON response.');
		 }
		 
		 // Return the populated contact object
		 return contact;
	 }	 

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
		public static void postCreateDummyJSONUser(String contactId) {
			// Query the contact record to gather the necessary fields for the JSON payload
			Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
			
			// Prepare the HTTP request
			Http http = new Http();
			HttpRequest request = new HttpRequest();
			
			// Set the endpoint URL. Best practice is to use a Named Credential, but for now, we’ll use a direct URL.
			String endpoint = 'https://dummyjson.com/users/add';
			request.setEndpoint(endpoint);
			
			// Set the HTTP method to POST
			request.setMethod('POST');
			
			// Set the request header to accept JSON and to send JSON
			request.setHeader('Content-Type', 'application/json');
			
			// Generate the JSON payload using the contact data
			String jsonPayload = generateDummyJsonUserPayload(contact);
			request.setBody(jsonPayload);
			
			try {
				// Send the request
				HttpResponse response = http.send(request);
				
				// Check if the response status is successful (HTTP status code 200 - 299)
				if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
					// Update the contact's 'DummyJSON_Last_Updated__c' field to the current date/time
					contact.DummyJSON_Last_Updated__c = System.now();
					update contact;
				} else {
					// Handle non-successful response (status code outside the 200 range)
					System.debug('Failed to send contact info. Status code: ' + response.getStatusCode());
				}
			} catch (Exception e) {
				// Handle any exceptions that occur during the callout
				System.debug('Error during callout: ' + e.getMessage());
			}
		}
	
		// Helper method to generate JSON payload from the contact object
		private static String generateDummyJsonUserPayload(Contact contact) {
			// Create a map to hold the data for JSON serialization
			Map<String, Object> payload = new Map<String, Object>();
			payload.put('firstName', contact.FirstName);
			payload.put('lastName', contact.LastName);
			payload.put('email', contact.Email);
			payload.put('phone', contact.Phone);
			
			// Serialize the map to a JSON string
			return JSON.serialize(payload);
		}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */

		@TestVisible
		private static String generateDummyJsonUserPayload(String contactId) {
			// Query the contact to get the required fields
			Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
			
			// Create a map to hold the field values for the JSON payload
			Map<String, Object> payload = new Map<String, Object>();
			
			// Populate the map with field values from the contact
			// If a field is null, provide a default value (e.g., "unknown")
			payload.put('salesforceId', contact.Id != null ? contact.Id : 'unknown');
			payload.put('firstName', contact.FirstName != null ? contact.FirstName : 'unknown');
			payload.put('lastName', contact.LastName != null ? contact.LastName : 'unknown');
			payload.put('email', contact.Email != null ? contact.Email : 'unknown');
			payload.put('phone', contact.Phone != null ? contact.Phone : 'unknown');
			
			// Serialize the map into a JSON string
			String jsonPayload = JSON.serialize(payload);
			
			// Return the JSON string payload
			return jsonPayload;
		}
}
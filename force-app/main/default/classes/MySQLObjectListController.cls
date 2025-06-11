public with sharing class MySQLObjectListController {
    
    public static String getUserkey(){
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Employee_Key__c FROM User WHERE Id = :currentUserId LIMIT 1];
        return currentUser.Employee_Key__c;
    }
    
   @AuraEnabled(cacheable=true)
    public static List<WorkRowObject> fetchWorkRowObjects() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.workrow.io/wp-json/workrow/v1/list-objects?timestamp=' + DateTime.now().getTime());

        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        if(getUserkey() != NULL){
           request.setHeader('api-key',getUserkey());
        }
        
        HttpResponse response = http.send(request);
        System.debug('HTTP Response Body: ' + response.getBody());
        if (response.getStatusCode() == 200) {
            ApiResponse apiResponse = (ApiResponse) JSON.deserialize(response.getBody(), ApiResponse.class);
            System.debug('apiResponse.objects'+apiResponse.objects);
            return apiResponse.objects;
        } else {
            throw new AuraHandledException('Failed to fetch objects: ' + response.getBody());
        }
    }
    
    public class ApiResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<WorkRowObject> objects { get; set; }
    }
    
    public class WorkRowObject {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String api_name { get; set; }
        @AuraEnabled public String created_at { get; set; }
        @AuraEnabled public String updated_at { get; set; }
    }
    
    @AuraEnabled
    public static String saveObject(String labeledName, String objName) {
        String endpointUrl = 'https://api.workrow.io/wp-json/workrow/v1/create-object?timestamp';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
        
        if(getUserkey() != NULL){
           req.setHeader('api-key',getUserkey());
        }
        
        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('object_name', objName);
        bodyMap.put('label', labeledName);
        
        String jsonBody = JSON.serialize(bodyMap);
        req.setBody(jsonBody);
        
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 201) {
            System.debug('Object created successfully: ' + res.getBody());
            return 'Object created successfully';
        } else {
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                String message = (String) errorResponse.get('message');
                Map<String, Object> dataMap = (Map<String, Object>) errorResponse.get('data');
                String reason = 'Unknown error reason';
                if (dataMap != null && dataMap.containsKey('reason')) {
                    reason = (String) dataMap.get('reason');
                }
                System.debug('Error: ' + message + '. Reason: ' + reason);
                return 'Error: ' + message + '. Reason: ' + reason;
            } catch (Exception e) {
                System.debug('Error: Failed to parse error response. ' + e.getMessage());
                return 'Error: Failed to parse error response. ' + e.getMessage();
            }
        }
    }
    
    @AuraEnabled
    public static String saveField(String labeledName, String fieldName, String fieldType, String objName, String textLength) {
        String endpointUrl = 'https://api.workrow.io/wp-json/workrow/v1/create-field?';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
        if(getUserkey() != NULL){
           req.setHeader('api-key',getUserkey());
        }
        
        Map<String, String> requestBody = new Map<String, String>();
        requestBody.put('object_name', objName);  
        requestBody.put('field_label', labeledName);  
        requestBody.put('field_name', fieldName); 
        requestBody.put('field_type', fieldType);
        requestBody.put('field_length', textLength);
        
        String jsonBody = JSON.serialize(requestBody);
        req.setBody(jsonBody);
        
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 201) {
            return 'Field created successfully';
        } else {
            
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                String message = (String) errorResponse.get('message');
                Map<String, Object> dataMap = (Map<String, Object>) errorResponse.get('data');
                String reason = 'Unknown error reason';
                if (dataMap != null && dataMap.containsKey('reason')) {
                    reason = (String) dataMap.get('reason');
                }
                System.debug('Error: ' + message + '. Reason: ' + reason);
                return 'Error: ' + message + '. Reason: ' + reason;
            } catch (Exception e) {
                System.debug('Error: Failed to parse error response. ' + e.getMessage());
                return 'Error: Failed to parse error response. ' + e.getMessage();
            }
        }
    }
    
    @AuraEnabled
    public static List<WorkRowField> fetchWorkRowField(String objName) {
       Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.workrow.io//wp-json/workrow/v1/list-fields?timestamp='+DateTime.now().getTime()+'&object_name='+objName);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        if(getUserkey() != NULL){
           request.setHeader('api-key',getUserkey());
        }
        
        HttpResponse response = http.send(request);
        System.debug('HTTP Response Body: ' + response.getBody());
        if (response.getStatusCode() == 200) {
            ApiFieldResponse apiResponse = (ApiFieldResponse) JSON.deserialize(response.getBody(), ApiFieldResponse.class);
            System.debug('apiResponse.fields'+apiResponse.fields);
            return apiResponse.fields;
        } else {
            throw new AuraHandledException('Failed to fetch fields: ' + response.getBody());
        } 
    }
    public class ApiFieldResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<WorkRowField> fields { get; set; }
    }
    public class WorkRowField {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String api_name { get; set; }
        @AuraEnabled public String field_type { get; set; }
        @AuraEnabled public String updated_at { get; set; } 
        @AuraEnabled public String length { get; set; }
    }
    
    @AuraEnabled
    public static String createPicklist(String labeledName, String recordId) {
        System.debug('labeledName'+labeledName);
        System.debug('id'+recordId);
        String endpointUrl = 'https://api.workrow.io//wp-json/workrow/v1/picklist?';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
		
        Map<String, String> requestBody = new Map<String, String>();
            requestBody.put('field_id', recordId);  
            requestBody.put('label', labeledName);  
        
        String jsonBody = JSON.serialize(requestBody);
        req.setBody(jsonBody);
        
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 201) {
            System.debug('Picklist Value created successfully: ' + res.getBody());
            return 'Picklist Value Created successfully';
        } else {
            System.debug('Failed to create Picklist Value. Status code: ' + res.getStatusCode() + ' Response: ' + res.getBody());
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String message = (String) errorResponse.get('message');
                Map<String, Object> dataMap = (Map<String, Object>) errorResponse.get('data');
                String reason = 'Unknown error reason';
                if (dataMap != null && dataMap.containsKey('reason')) {
                    reason = (String) dataMap.get('reason');
                }
                System.debug('Error: ' + message + '. Reason: ' + reason);
                return 'Error: ' + message + '. Reason: ' + reason;
            } catch (Exception e) {
                System.debug('Error: Failed to parse error response. ' + e.getMessage());
                return 'Error: Failed to parse error response. ' + e.getMessage();
            }
        } 
    }
    
    @AuraEnabled
    public static List<WorkRowFieldPicklist> fetchWorkRowFieldPicklist(String fieldId) {
       Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.workrow.io//wp-json/workrow/v1/picklist?timestamp='+DateTime.now().getTime()+'&field_id='+fieldId);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        if(getUserkey() != NULL){
           request.setHeader('api-key',getUserkey());
        }
        
        HttpResponse response = http.send(request);
        System.debug('HTTP Response Body: ' + response.getBody());
        if (response.getStatusCode() == 200) {
            ApiPicklistResponse apiResponse = (ApiPicklistResponse) JSON.deserialize(response.getBody(), ApiPicklistResponse.class);
            System.debug('apiResponse.fields'+apiResponse.values);
            return apiResponse.values;
        } else {
            throw new AuraHandledException('Failed to fetch picklits: ' + response.getBody());
        } 
    }
    public class ApiPicklistResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<WorkRowFieldPicklist> values { get; set; }
    }
    public class WorkRowFieldPicklist {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String updated_at { get; set; }
    }
    
    @AuraEnabled
    public static String editPicklist(String picklistname, String picklistId) {
        System.debug('labeledName>>'+picklistname);
        System.debug('id'+picklistId);
        String endpointUrl = 'https://api.workrow.io//wp-json/workrow/v1/picklist/'+picklistId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('PUT');
		
        Map<String, String> requestBody = new Map<String, String>();
              
            requestBody.put('label', picklistname);  
        
        String jsonBody = JSON.serialize(requestBody);
        req.setBody(jsonBody);
        
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            System.debug('Picklist Value Edited successfully: ' + res.getBody());
            return 'Picklist Value Edited successfully';
        } else {
            System.debug('Failed to edit Picklist Value. Status code: ' + res.getStatusCode() + ' Response: ' + res.getBody());
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String message = (String) errorResponse.get('message');
                Map<String, Object> dataMap = (Map<String, Object>) errorResponse.get('data');
                String reason = 'Unknown error reason';
                if (dataMap != null && dataMap.containsKey('reason')) {
                    reason = (String) dataMap.get('reason');
                }
                System.debug('Error: ' + message + '. Reason: ' + reason);
                return 'Error: ' + message + '. Reason: ' + reason;
            } catch (Exception e) {
                System.debug('Error: Failed to parse error response. ' + e.getMessage());
                return 'Error: Failed to parse error response. ' + e.getMessage();
            }
        } 
    }
    
    @AuraEnabled
    public static List<WorkRowUsers> fetchUserDetail() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.workrow.io//wp-json/workrow/v1/get_users?timestamp=' + DateTime.now().getTime());

        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        if(getUserkey() != NULL){
           request.setHeader('api-key',getUserkey());
        }
        
        HttpResponse response = http.send(request);
        System.debug('HTTP Response Body: ' + response.getBody());
        if (response.getStatusCode() == 200) {
            usersResponse apiResponse = (usersResponse) JSON.deserialize(response.getBody(), usersResponse.class);
            System.debug('usersResponseList'+apiResponse.data);
            return apiResponse.data;
        } else {
            throw new AuraHandledException('Failed to fetch Users: ' + response.getBody());
        }
    }
    public class usersResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<WorkRowUsers> data { get; set; }
    }
    
    public class WorkRowUsers {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String name { get; set; }
    }
    
}
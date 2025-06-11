@isTest
public class MySQLObjectListControllerTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @isTest
    static void testSaveObject() {
        String responseBody = '{"message": "Object created successfully"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, responseBody));

        String labeledName = 'Test Label';
        String objName = 'TestObject';

        Test.startTest();
        MySQLObjectListController.saveObject(labeledName, objName);  
        Test.stopTest();
        System.debug('saveObject test completed.');
    }

    @isTest
    static void testFetchWorkRowObjects() {
        String responseBody = '{"message": "Success", "objects": [{"id": "1", "label": "Object 1", "api_name": "object_1", "created_at": "2023-01-01", "updated_at": "2023-01-02"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, responseBody));

        Test.startTest();
        List<MySQLObjectListController.WorkRowObject> result = MySQLObjectListController.fetchWorkRowObjects(); 
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(1, result.size(), 'The result should contain one object.');

        MySQLObjectListController.WorkRowObject firstObject = result[0];
        System.assertEquals('1', firstObject.id, 'The object ID should be "1".');
        System.assertEquals('Object 1', firstObject.label, 'The object label should be "Object 1".');
        System.assertEquals('object_1', firstObject.api_name, 'The API name should be "object_1".');
        System.assertEquals('2023-01-01', firstObject.created_at, 'The created_at date should be "2023-01-01".');
        System.assertEquals('2023-01-02', firstObject.updated_at, 'The updated_at date should be "2023-01-02".');
    }

    @isTest
    static void testSaveField() {
        String responseBody = '{"message": "Field created successfully"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, responseBody));

        String labeledName = 'Test Label';
        String fieldName = 'TestLabel';
        String fieldType = 'Integer';  // Corrected the typo
        String objName = 'TestObject';
        String textLength = '255'; 

        Test.startTest();
        String result = MySQLObjectListController.saveField(labeledName, fieldName, fieldType, objName, textLength); 
        Test.stopTest();
        System.debug('saveField test completed.');
    }

    @isTest
    static void testFetchWorkRowFieldSuccess() {
        String responseBody = '{"message": "Success", "fields": [{"id": "1", "label": "Field 1", "api_name": "field_1", "field_type": "text", "updated_at": "2023-01-01"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, responseBody));

        String objName = 'TestObject';

        Test.startTest();
        List<MySQLObjectListController.WorkRowField> result = MySQLObjectListController.fetchWorkRowField(objName); 
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(1, result.size(), 'The result should contain one field.');

        MySQLObjectListController.WorkRowField firstField = result[0];
        System.assertEquals('1', firstField.id, 'The field ID should be "1".');
        System.assertEquals('Field 1', firstField.label, 'The field label should be "Field 1".');
        System.assertEquals('field_1', firstField.api_name, 'The API name should be "field_1".');
        System.assertEquals('text', firstField.field_type, 'The field type should be "text".');
        System.assertEquals('2023-01-01', firstField.updated_at, 'The updated_at date should be "2023-01-01".');
    }
    
    @isTest
    static void testCreatePicklist_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Picklist created successfully", "data": {}}'));
        Test.startTest();
        MySQLObjectListController.createPicklist('Test Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
    }

    @isTest
    static void testCreatePicklist_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"message": "Invalid field", "data": {"reason": "Field not found"}}'));
        Test.startTest();
        MySQLObjectListController.createPicklist('Invalid Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
    }

    @isTest
    static void testCreatePicklist_ParsingError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"message": "Unexpected error"'));
        Test.startTest();
        MySQLObjectListController.createPicklist('Test Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
    }
	
    
    @isTest
    static void testFetchWorkRowFieldPicklist_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Success", "values": [{"id": "1", "label": "Picklist Option 1", "updated_at": "2025-05-08"}]}'));
        Test.startTest();
        List<MySQLObjectListController.WorkRowFieldPicklist> result = MySQLObjectListController.fetchWorkRowFieldPicklist('a1B5g000000JX5zEAC');
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Expected 1 picklist value');
        System.assertEquals('1', result[0].id, 'Expected picklist option ID to be 1');
    }

    @isTest
    static void testFetchWorkRowFieldPicklist_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"message": "Field not found", "values": []}'));
        Test.startTest();
        try {
            MySQLObjectListController.fetchWorkRowFieldPicklist('a1B5g000000JX5zEAC');
            System.assert(false, 'Expected an exception due to failed API response');
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }

    @isTest
    static void testFetchWorkRowFieldPicklist_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Success", "values": []}'));
        Test.startTest();
        List<MySQLObjectListController.WorkRowFieldPicklist> result = MySQLObjectListController.fetchWorkRowFieldPicklist('a1B5g000000JX5zEAC');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Expected an empty list of picklist values');
    }

    @isTest
    static void testEditPicklist_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Picklist updated successfully", "data": {}}'));
        Test.startTest();
        String result = MySQLObjectListController.editPicklist('Updated Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
        System.assertEquals('Picklist Value Edited successfully', result);
    }

    @isTest
    static void testEditPicklist_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"message": "Picklist not found", "data": {"reason": "ID not valid"}}'));
        Test.startTest();
        String result = MySQLObjectListController.editPicklist('Invalid Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
        System.assert(result.contains('Error: Picklist not found'), 'Expected error message');
        System.assert(result.contains('Reason: ID not valid'), 'Expected error reason');
    }

    @isTest
    static void testEditPicklist_ParsingError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"message": "Unexpected error"'));
        Test.startTest();
        String result = MySQLObjectListController.editPicklist('Test Picklist', 'a1B5g000000JX5zEAC');
        Test.stopTest();
        System.assert(result.contains('Error: Failed to parse error response'), 'Expected parsing error message');
    }
    
    @isTest
    static void testFetchWorkRowUser_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Success", "data": [{"id": "1", "name": "Test name", "email": "test@gmail.com"}]}'));
        Test.startTest();
        List<MySQLObjectListController.WorkRowUsers> result = MySQLObjectListController.fetchUserDetail();
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Expected 1 picklist value');
        System.assertEquals('1', result[0].id, 'Expected picklist option ID to be 1');
    }

    @isTest
    static void testFetchWorkRowUser_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"message": "Field not found", "data": []}'));
        Test.startTest();
        try {
            MySQLObjectListController.fetchUserDetail();
            System.assert(false, 'Expected an exception due to failed API response');
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }

    @isTest
    static void testFetchWorkRowUser_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"message": "Success", "data": []}'));
        Test.startTest();
        List<MySQLObjectListController.WorkRowUsers> result = MySQLObjectListController.fetchUserDetail();
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Expected an empty list of picklist values');
    }
}
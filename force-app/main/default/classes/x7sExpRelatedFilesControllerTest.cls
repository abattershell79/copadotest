/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@IsTest
public with sharing class x7sExpRelatedFilesControllerTest {

    @TestSetup
    static void testSetup() {
        Contact testContact = x7sExpTestUtils.createTestContact();
        System.assertNotEquals(null, testContact);
    }

    // Test finding a user
    @IsTest
    public static void testGetAttachments() {
        // Set up and run as a standard user
        List<Contact> testContacts = [SELECT Id FROM Contact WHERE Email = :x7sExpTestConstants.STANDARD_EMAIL];
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = :x7sExpTestConstants.ACCOUNT_NAME];

        User testUser = x7sExpTestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        } catch (Exception e) {
            testUser.ContactId = null;
            insert testUser;
        }

        Attachment testAttachment = x7sExpTestUtils.createAttachment(testAccounts[0].Id);
        insert testAttachment;

        x7sExpResponse testResponse = x7sExpRelatedFilesController.getFilesForCurrentUserForRecord((String) testAccounts[0].Id);

        // Assert that the result is found for this user
        System.assertEquals(testResponse.results.size(), 1);


        System.runAs(testUser) {
            // Run the get files method for this user, against Account record
            testResponse = x7sExpRelatedFilesController.getFilesForCurrentUserForRecord((String) testAccounts[0].Id);

            // Assert that no result found for test user, as they are not the owner!
            System.assertEquals(testResponse.results.size(), 0);
        }

    }
}
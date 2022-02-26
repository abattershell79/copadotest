/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@IsTest
public with sharing class x7sExpMyGroupsControllerTest {

    // Note: For Group Membership, ensure that the type of user matches the type of group. Salesforce prevents
    // Internal Chatter Group (No Network Id) <=> Internal User (Has Standard/Internal Profile)
    // Community Chatter Group (Has Network Id) <=> Community User (Has Community/Partner profile)

    @TestSetup
    static void testSetup() {
        Contact testContact = x7sExpTestUtils.createTestContact();
        System.assertNotEquals(null, testContact);
    }

    @IsTest
    public static void testIsNotInGroup() {
        // Create user
        List<Contact> testContacts = [SELECT Id FROM Contact WHERE Email = :x7sExpTestConstants.STANDARD_EMAIL];

        User testUser = x7sExpTestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        } catch (Exception e) {
            testUser.ContactId = null;
            insert testUser;
        }

        // Make sure they're not yet in a group
        System.runAs(testUser) {
            System.assertEquals(x7sExpMyGroupsController.isInAGroup(), false);
        }


        // Insert a collab group - failing only in HGSE environment on DML setup / non setup between CollaborationGroup and User
        /*CollaborationGroup testGroup = x7sExpTestUtils.createChatterGroup(x7sExpTestConstants.TEST_GROUPNAME,'Public');
        insert testGroup;

        CollaborationGroupMember testGroupMember = x7sExpTestUtils.createGroupMembership(testGroup.Id, testUser.Id);
        insert testGroupMember;

        System.runAs(testUser){
            System.assertEquals(x7sExpMyGroupsController.isInAGroup(), true);
        }*/


    }

    @IsTest
    public static void testGetFeaturedGroup() {

        // Insert a collab group
        CollaborationGroup testGroup = x7sExpTestUtils.createChatterGroup(x7sExpTestConstants.TEST_GROUPNAME, 'Public');
        insert testGroup;

        // Call action and cast result as Collab Group
        x7sExpResponse expResponse = x7sExpMyGroupsController.getFeaturedGroup(testGroup.Id);
        CollaborationGroup foundGroup = (CollaborationGroup) expResponse.results[0];

        // Test that the collab group name is accurate
        System.assertEquals(foundGroup.Name, x7sExpTestConstants.TEST_GROUPNAME);
    }
    @IsTest
    public static void testGetFeaturedGroups() {

        // Insert a collab group
        List<CollaborationGroup> testGroups = new List<CollaborationGroup>();
        List<String> testIds = new List<String>();
        testGroups.add(x7sExpTestUtils.createChatterGroup(x7sExpTestConstants.TEST_GROUPNAME + ' 1', 'Public'));
        testGroups.add(x7sExpTestUtils.createChatterGroup(x7sExpTestConstants.TEST_GROUPNAME + ' 2', 'Public'));
        testGroups.add(x7sExpTestUtils.createChatterGroup(x7sExpTestConstants.TEST_GROUPNAME + ' 3', 'Public'));
        insert testGroups;
        for (Integer i = 0; i < testGroups.size(); i++) {
            if (i <= 1) {
                testIds.add(testGroups[i].Id);
            }
        }


        // Call action and cast result as Collab Group
        x7sExpResponse expResponse = x7sExpMyGroupsController.getFeaturedGroups(testIds, '5');
        CollaborationGroup foundGroup = (CollaborationGroup) expResponse.results[0];

        // Test that the collab group name is accurate
        System.assertEquals(foundGroup.Name, x7sExpTestConstants.TEST_GROUPNAME + ' 1');
        System.assertEquals(2, expResponse.results.size());
    }

    @IsTest
    public static void testGetMyGroups() {
        // Create user
        List<Contact> testContacts = [SELECT Id FROM Contact WHERE Email = :x7sExpTestConstants.STANDARD_EMAIL];

        User testUser = x7sExpTestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        } catch (Exception e) {
            testUser.ContactId = null;
            insert testUser;
        }

        System.runAs(testUser) {
            System.assertEquals(x7sExpMyGroupsController.getMyGroups('3').results.size(), 0);
        }
    }


    @IsTest
    public static void testGetPrefix() {
        System.assert(x7sExpMyGroupsController.getSitePrefix() != null);
    }


}
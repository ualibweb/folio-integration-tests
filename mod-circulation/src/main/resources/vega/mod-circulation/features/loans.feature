Feature: Loans tests

  Background:
    * url baseUrl
    * callonce login testUser
    * configure headers = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitoken)', 'Accept': '*/*'  }

    * def instanceId = call uuid1
    * def servicePointId = call uuid1
    * def locationId = call uuid1
    * def holdingId = call uuid1
    * def itemId = call uuid1
    * def groupId = call uuid1
    * def userId = call uuid1
    * def ownerId = call uuid1
    * def manualChargeId = call uuid1
    * def paymentMethodId = call uuid1
    * def userBarcode = random(100000)
    * def checkOutByBarcodeId = call uuid1
    * def parseObjectToDate = read('classpath:vega/mod-circulation/features/util/parse-object-to-date-function.js')

  Scenario: When patron and item id's entered at checkout, post a new loan using the circulation rule matched
    * def extUserId = call uuid1

    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: 666666, extMaterialTypeId: #(materialTypeId), extItemId: #(itemId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup')  { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: #(userBarcode), extGroupId: #(groupId) }

    # checkOut
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: 666666 }

    # get loan and verify
    Given path 'circulation', 'loans'
    And param query = '(userId==' + extUserId + ' and ' + 'itemId==' + itemId + ')'
    When method GET
    Then status 200
    And match response.loans[0].id == checkOutResponse.response.id
    And match response.loans[0].loanPolicyId == loanPolicyMaterialId

  Scenario: Get checkIns records, define current item checkIn record and its status
    * def extInstanceTypeId = call uuid1
    * def extInstitutionId = call uuid1
    * def extCampusId = call uuid1
    * def extLibraryId = call uuid1

    #post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceTypeId: #(extInstanceTypeId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extInstitutionId: #(extInstitutionId), extCampusId: #(extCampusId), extLibraryId: #(extLibraryId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: '555555', extMaterialTypeId: #(materialTypeId), extItemId: #(itemId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode) }

    # checkOut an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: '555555' }

    # checkIn an item with certain itemBarcode
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: '555555' }

    # get check-ins and assert checkedIn record
    Given path 'check-in-storage', 'check-ins'
    When method GET
    Then status 200
    * def checkedInRecord = response.checkIns[response.totalRecords - 1]
    And match checkedInRecord.itemId == itemId

    Given path 'check-in-storage', 'check-ins', checkedInRecord.id
    When method GET
    Then status 200
    And match response.itemStatusPriorToCheckIn == 'Checked out'
    And match response.itemId == itemId

  Scenario: When get loans for a patron is called, return a paged collection of loans for that patron with all data as specified in the circulation/loans API

    * def extUserId = call uuid1
    * def extItemBarcode1 = random(10000)
    * def extItemBarcode2 = random(10000)
    * def extUserBarcode = random(100000)

    # post items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode1), extMaterialTypeId: #(materialTypeId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode2), extMaterialTypeId: #(materialTypeId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode), extUserId: #(extUserId) }

    # checkOut the first item
    * def checkOutResponse1 = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode1) }
    # checkOut the second item
    * def checkOutResponse2 = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode2) }

    # Get a paged collection of patron
    Given path 'circulation', 'loans'
    And param query = '(userId=="' + extUserId + '")'
    When method GET
    Then status 200
    And match response == { totalRecords: #present, loans: #present }
    And match response.totalRecords == 2
    And match response.loans[0] == { id: #present, lostItemPolicyId: #present, metadata: #present, item: #present, dueDate: #present, checkoutServicePointId: #present, borrower: #present, feesAndFines: #present, userId: #present, patronGroupAtCheckout: #present, overdueFinePolicy: #present, checkoutServicePoint: #present, itemId: #present, loanPolicyId: #present, itemEffectiveLocationIdAtCheckOut: #present, loanDate: #present, action: #present, overdueFinePolicyId: #present, lostItemPolicy: #present, id: #present, loanPolicy: #present, status: #present }
    And match response.loans[0].id == checkOutResponse1.response.id
    And match response.loans[1] == { id: #present, lostItemPolicyId: #present, metadata: #present, item: #present, dueDate: #present, checkoutServicePointId: #present, borrower: #present, feesAndFines: #present, userId: #present, patronGroupAtCheckout: #present, overdueFinePolicy: #present, checkoutServicePoint: #present, itemId: #present, loanPolicyId: #present, itemEffectiveLocationIdAtCheckOut: #present, loanDate: #present, action: #present, overdueFinePolicyId: #present, lostItemPolicy: #present, id: #present, loanPolicy: #present, status: #present }
    And match response.loans[1].id == checkOutResponse2.response.id

  Scenario: When an existing loan is declared lost, update declaredLostDate, item status to declared lost and bill lost item fees per the Lost Item Fee Policy
    * def itemBarcode = random(100000)
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * def postServicePointResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * def servicePointId = postServicePointResult.response.id
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(itemBarcode), extMaterialTypeId: #(materialTypeId) }
    * def itemId = postItemResult.response.id
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode) }

    * def checkOutResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: #(itemBarcode) }
    * def loanId = checkOutResult.response.id
    * def declaredLostDateTime = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@DeclareItemLost') { servicePointId: #(servicePointId), loanId: #(loanId), declaredLostDateTime:#(declaredLostDateTime) }

    Given path '/loan-storage', 'loans', loanId
    When method GET
    Then status 200
    And match parseObjectToDate(response.declaredLostDate) == parseObjectToDate(declaredLostDateTime)

    Given path '/item-storage', 'items', itemId
    When method GET
    Then status 200
    And match response.status.name == 'Declared lost'

    * def lostItemFeePolicyEntity = read('samples/policies/lost-item-fee-policy-entity-request.json')
    Given path 'accounts'
    And param query = 'loanId==' + loanId + ' and feeFineType==Lost item processing fee'
    When method GET
    Then status 200
    And match response.accounts[0].amount == lostItemFeePolicyEntity.lostItemProcessingFee

    Given path 'accounts'
    And param query = 'loanId==' + loanId + ' and feeFineType==Lost item fee'
    When method GET
    Then status 200
    And match response.accounts[0].amount == lostItemFeePolicyEntity.chargeAmountItem.amount

  Scenario: Post item, two patrons, check out item and post a recall request, assert expectedDueDateBeforeRequest and dueDate

    * def groupId = call uuid1
    * def extInstanceId = call uuid1
    * def extInstanceTypeId = call uuid1
    * def extInstitutionId = call uuid1
    * def extHoldingsRecordId = call uuid1
    * def extCampusId = call uuid1
    * def extLibraryId = call uuid1
    * def requestId = call uuid1
    * def extItemId = call uuid1
    * def extUserId = call uuid1
    * def extUserId2 = call uuid1
    * def expectedLoanDate = '2021-10-27T13:25'
    * def expectedDueDateBeforeRequest = '2021-11-17T13:25'

    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceTypeId: #(extInstanceTypeId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extInstitutionId: #(extInstitutionId), extCampusId: #(extCampusId), extLibraryId: #(extLibraryId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings') { extInstanceTypeId: #(extInstanceTypeId), extHoldingsRecordId: #(extHoldingsRecordId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: '333333', extMaterialTypeId: #(materialTypeId), extItemId: #(extItemId), extHoldingsRecordId: #(extHoldingsRecordId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: '44441' }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId2), extUserBarcode: '44442' }

    # checkOut an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: '44441', extCheckOutItemBarcode: '333333' }

    # check loan and dueDateChangedByRecall availability
    Given path 'circulation', 'loans'
    And param query = 'status.name=="Open" and itemId==' + extItemId
    When method GET
    Then status 200
    * def loanResponse = response.loans[0]
    Then match loanResponse.dueDateChangedByRecall == '#notpresent'
    Then match loanResponse.loanPolicyId == loanPolicyMaterialId
    Then match loanResponse.loanDate contains expectedLoanDate
    Then match loanResponse.dueDate contains expectedDueDateBeforeRequest

    # post recall request by patron-requester
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRequest') { itemId: #(extItemId), requesterId: #(extUserId2), extInstanceId: #(extInstanceId), extHoldingsRecordId: #(extHoldingsRecordId) }

    # check loan and dueDateChangedByRecall availability after request
    Given path 'circulation', 'loans'
    And param query = 'status.name=="Open" and itemId==' + extItemId
    When method GET
    Then status 200
    Then match $.loans[0].dueDateChangedByRecall == true
    And match $.loans[0].dueDate contains expectedDueDateBeforeRequest

  Scenario: When an loaned item is checked in at a service point that serves its location and no request exists, change the item status to Available

    * def extItemBarcode = 'fat1003-ibc'
    * def extUserId = call uuid1
    * def extUserBarcode = 'fat1003-ubc'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode)}

    # post a user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode), extUserId: #(extUserId) }

    # check-out the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }

    # verify that no request exist before check-in
    Given path 'circulation', 'requests'
    And param query = '(requesterId==' + extUserId + ' and status=="Open*")'
    When method GET
    Then status 200
    And match response.totalRecords == 0
    And match response.requests == []

    # check-in the item and verify that item status is changed to 'Available'
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode) }
    * def item = checkInResponse.response.item
    And match item.id == itemId
    And match item.status.name == 'Available'

  Scenario: When an requested loaned item is checked in at a service point designated as the pickup location of the request, change the item status to awaiting-pickup

    * def extInstanceId = call uuid1
    * def extHoldingsRecordId = call uuid1
    * def extItemBarcode = '12123366'
    * def extUserId1 = call uuid1
    * def extUserId2 = call uuid2
    * def extUserBarcode1 = '3315666'
    * def extUserBarcode2 = '3315669'
    * def extRequestId = call uuid1

    # post a location and service point
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceId: #(extInstanceId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings') { extHoldingsRecordId: #(extHoldingsRecordId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode), extHoldingsRecordId: #(extHoldingsRecordId) }

    # post an user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode1), extUserId: #(extUserId1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode2), extUserId: #(extUserId2) }

    # checkOut the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode) }

    # post a request for the checked-out-item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRequest') { requestId: #(extRequestId), itemId: #(itemId), requesterId: #(extUserId2), extInstanceId: #(extInstanceId), extHoldingsRecordId: #(extHoldingsRecordId) }

    # checkIn the item and check if the request status changed to awaiting pickup
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode) }
    * def response = checkInResponse.response
    And match response.item.id == itemId
    And match response.item.status.name == 'Awaiting pickup'

    # check the status of the user request whether changed to 'Open-Awaiting pickup'
    Given path 'circulation', 'requests', extRequestId
    When method GET
    Then status 200
    And match response.status == 'Open - Awaiting pickup'

  Scenario:  When a loaned item is checked in at a service point that does not serve its location and no request exists, change the item status to In-transit and destination to primary service point for its location

    * def extItemBarcode = 'fat1004-ibc'
    * def extUserId = call uuid1
    * def extUserBarcode = 'fat1004-ubc'
    * def extServicePointId1 = call uuid1
    * def extServicePointId2 = call uuid1
    * def extInstitutionId1 = call uuid1
    * def extInstitutionId2 = call uuid1
    * def extCampusId1 = call uuid1
    * def extCampusId2 = call uuid1
    * def extLibraryId1 = call uuid1
    * def extLibraryId2 = call uuid1
    * def extLocationId1 = call uuid1
    * def extLocationId2 = call uuid1

    # first location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extLocationId: #(extLocationId1),  extInstitutionId: #(extInstitutionId1), extCampusId: #(extCampusId1), extLibraryId: #(extLibraryId1), extServicePointId: #(extServicePointId1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId1) }

    # second location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extLocationId: #(extLocationId2), extInstitutionId: #(extInstitutionId2), extCampusId: #(extCampusId2), extLibraryId: #(extLibraryId2), extServicePointId: #(extServicePointId2) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId2) }

    # post an item which is located in the first location
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings') { extLocationId: #(extLocationId1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode) }

    # post a user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode), extUserId: #(extUserId) }

    # check-out the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode), extServicePointId: #(extServicePointId1) }

    # verify that no request exist before check-in
    Given path 'circulation', 'requests'
    And param query = '(requesterId==' + extUserId + ' and status=="Open*")'
    When method GET
    Then status 200
    And match response.totalRecords == 0
    And match response.requests == []

    # check-in the item from second service point and verify that item status is changed to 'In transit'
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode), extServicePointId: #(extServicePointId2) }
    * def item = checkInResponse.response.item
    And match item.id == itemId
    And match item.status.name == 'In transit'
    And match item.inTransitDestinationServicePointId == extServicePointId1

  Scenario: When an item has the status intellectual item, do not allow checkout

    * def extItemBarcode = 'FAT-1007IBC'
    * def extUserBarcode = 'FAT-1007UBC'
    * def extStatusName = 'Intellectual item'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode), extStatusName: #(extStatusName) }

    # post a user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # check-out the item and verify that checking-out the item is not processable
    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    * def error = response.errors[0]
    And match error.message == '#string'
    And match error.message == 'Long Way to a Small Angry Planet (' + materialTypeName + ') (Barcode: ' + extItemBarcode + ') has the item status Intellectual item and cannot be checked out'
    And match error.parameters[0].value == extItemBarcode

  Scenario: When an item that had the status of restricted that was checked out is checked in, set the item status to Available

    * def itemBarcode = '88888'
    * def userBarcode = random(100000)

    # post associated entities and item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(itemBarcode), extMaterialTypeId: #(materialTypeId) }
    * def itemId = postItemResult.response.id

    # post group and patron
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode) }

    # declare item with restricted status
    Given path 'inventory/items/' + itemId + '/mark-restricted'
    When method POST
    Then status 200
    And match response.status.name == 'Restricted'

    # checkOut an item with certain itemBarcode to created patron
    * def checkOutResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: #(itemBarcode) }
    * def loanId = checkOutResult.response.id

    # checkIn an item with certain itemBarcode, assert loan as Closed and item status as Available
    * def postCheckInResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(itemBarcode) }
    And match postCheckInResult.response.loan.id == loanId
    And match postCheckInResult.response.loan.status.name == 'Closed'
    And match postCheckInResult.response.item.id == itemId
    And match postCheckInResult.response.item.status.name == 'Available'

  Scenario: When an item has the status of in process allow checkout

    * def extItemBarcode = '888777'
    * def extUserBarcode = '334455'
    * def extUserId = call uuid1

    # post a location and service point
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode) }
    * def itemId = postItemResult.response.id

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode), extUserId: #(extUserId) }

    # declare item with in process status
    Given path 'inventory/items/' + itemId + '/mark-in-process-non-requestable'
    When method POST
    Then status 200
    And match response.status.name == 'In process (non-requestable)'

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    And match checkOutResponse.response.item.id == itemId
    And match checkOutResponse.response.item.status.name == 'Checked out'
    And match checkOutResponse.response.loanDate == '#present'

  Scenario:  When a loaned item is checked in at a service point that does not serve its location and a request exists, change the item status to In-transit and destination to pickup location in the request

    * def extInstanceId = call uuid1
    * def extHoldingsRecordId = call uuid1
    * def extItemBarcode = 'fat1005-ibc'
    * def extUserId1 = call uuid1
    * def extUserId2 = call uuid1
    * def extUserBarcode1 = 'fat1005-ubc1'
    * def extUserBarcode2 = 'fat1005-ubc2'
    * def extServicePointId1 = call uuid1
    * def extServicePointId2 = call uuid1
    * def extServicePointId3 = call uuid1
    * def extInstitutionId1 = call uuid1
    * def extInstitutionId2 = call uuid1
    * def extInstitutionId3 = call uuid1
    * def extCampusId1 = call uuid1
    * def extCampusId2 = call uuid1
    * def extCampusId3 = call uuid1
    * def extLibraryId1 = call uuid1
    * def extLibraryId2 = call uuid1
    * def extLibraryId3 = call uuid1
    * def extLocationId1 = call uuid1
    * def extLocationId2 = call uuid1
    * def extLocationId3 = call uuid1
    * def extRequestId = call uuid1

    # first location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extLocationId: #(extLocationId1),  extInstitutionId: #(extInstitutionId1), extCampusId: #(extCampusId1), extLibraryId: #(extLibraryId1), extServicePointId: #(extServicePointId1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId1) }

    # second location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extLocationId: #(extLocationId2), extInstitutionId: #(extInstitutionId2), extCampusId: #(extCampusId2), extLibraryId: #(extLibraryId2), extServicePointId: #(extServicePointId2) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId2) }

    # third location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation') { extLocationId: #(extLocationId3), extInstitutionId: #(extInstitutionId3), extCampusId: #(extCampusId3), extLibraryId: #(extLibraryId3), extServicePointId: #(extServicePointId3) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId3) }

    # post an item which is located in the first location
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceId: #(extInstanceId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings') { extLocationId: #(extLocationId1), extHoldingsRecordId: #(extHoldingsRecordId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode), extHoldingsRecordId: #(extHoldingsRecordId) }

    # post two users
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode1), extUserId: #(extUserId1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode2), extUserId: #(extUserId2) }

    # first user checks-out the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode), extServicePointId: #(extServicePointId1) }

    # second user posts a request for the checked-out-item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRequest') { requestId: #(extRequestId), itemId: #(itemId), requesterId: #(extUserId2), extServicePointId: #(extServicePointId2), extInstanceId: #(extInstanceId), extHoldingsRecordId: #(extHoldingsRecordId) }

    # check-in the item from third service point and verify that item status is changed to 'In transit'
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode), extServicePointId: #(extServicePointId3) }
    * def item = checkInResponse.response.item
    And match item.id == itemId
    And match item.status.name == 'In transit'
    And match item.inTransitDestinationServicePointId == extServicePointId2

  Scenario: When an item has the status of restricted, allow checkout with override

    * def extItemBarcode = 'fat1008-ibc'
    * def extUserBarcode = 'fat1008-ubc'

    # post associated entities and item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode), extMaterialTypeId: #(materialTypeId) }
    * def itemId = postItemResult.response.id

    # post group and patron
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # declare item with restricted status
    Given path 'inventory/items/' + itemId + '/mark-restricted'
    When method POST
    Then status 200
    And match response.status.name == 'Restricted'

    # checkOut an item with certain itemBarcode to created patron
    * def checkOutResult = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    * def item = checkOutResult.response.item
    And match item.id == itemId
    And match item.status.name == 'Checked out'

  Scenario: When an item that had the status of in process that was checked out is checked in, set the item status to Available

    * def extItemBarcode = 'FAT-1011IBC'
    * def extUserBarcode = 'FAT-1011UBC'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }
    * def itemId = postItemResponse.response.id

    # post a user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # change the item status to In-process
    Given path 'inventory/items/' + itemId + '/mark-in-process-non-requestable'
    When method POST
    Then status 200
    And match response.status.name == 'In process (non-requestable)'

    # check-out the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }

    # check-in the item and verify that the item status is Available
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode) }
    * def item = checkInResponse.response.item
    And match item.barcode == extItemBarcode
    And match item.status.name == 'Available'

  Scenario: When an item has the status of on order allow checkout

    * def extItemBarcode = 'FAT-1012IBC'
    * def extUserBarcode = 'FAT-1012UBC'
    * def extStatusName = 'On order'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode), extStatusName: #(extStatusName) }
    * def itemId = postItemResponse.response.id
    And match postItemResponse.response.status.name == extStatusName

    # post a user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    And match checkOutResponse.response.item.id == itemId
    And match checkOutResponse.response.item.status.name == 'Checked out'
    And match checkOutResponse.response.loanDate == '#present'

  Scenario: When an item that had the status of On order that was checked out is checked in, item status should be changed to Available

    * def extItemBarcode = '888555'
    * def extUserBarcode = '334477'
    * def extUserId = call uuid1
    * def extStatusName = 'On order'

    # post a location and service point
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')

    # post an item and assert its status name as On order
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(itemId), extItemBarcode: #(extItemBarcode), extStatusName: #(extStatusName) }
    * def itemId = postItemResponse.response.id
    And match postItemResponse.response.status.name == extStatusName

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode), extUserId: #(extUserId) }

    # checkOut the item and assert its status
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    * def loanId = checkOutResponse.response.id
    And match checkOutResponse.response.item.id == itemId
    And match checkOutResponse.response.item.status.name == 'Checked out'
    And match checkOutResponse.response.loanDate == '#present'

    # checkIn an item with certain itemBarcode, assert loan as Closed and item status as Available
    * def postCheckInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode) }
    And match postCheckInResponse.response.loan.id == loanId
    And match postCheckInResponse.response.loan.status.name == 'Closed'
    And match postCheckInResponse.response.item.id == itemId
    And match postCheckInResponse.response.item.status.name == 'Available'

  Scenario: When an overdue item is returned, an overdue fine is billed per the Overdue Fine Policy

    * def extItemBarcode = 'FAT-1017IBC'
    * def extUserBarcode = 'FAT-1017UBC'
    * def extCheckInDate = '2021-11-17T13:30:46.000Z'

     # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }
    * def itemId = postItemResponse.response.id

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # post owner, manual charge and payment method
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostManualCharge')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPaymentMethod')

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    * def loanId = checkOutResponse.response.id

    # checkIn the item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode), extCheckInDate: #(extCheckInDate) }

    # get overdue fine by loan id
    Given path 'accounts'
    And param query = 'loanId==' + loanId
    When method GET
    Then status 200
    * def accountInResponse = response.accounts[0]
    And match response.totalRecords == 1
    And match accountInResponse.status.name == 'Open'
    And match accountInResponse.feeFineType == 'Overdue fine'
    And def accountId = accountInResponse.id
    And def overdueFineAmount = accountInResponse.amount

    # check-pay and verify that the fine is possible to be paid
    Given path 'accounts/' + accountId + '/check-pay'
    And request { amount: '#(overdueFineAmount)' }
    When method POST
    Then status 200
    And match response.allowed == true

    # pay overdue fine and verify that the fine is billed fully
    * def postPayResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPay') { amount: #(overdueFineAmount) }
    * def feefineactionInResponse = postPayResponse.response.feefineactions[0]
    And match feefineactionInResponse.typeAction == 'Paid fully'
    And match feefineactionInResponse.amountAction == overdueFineAmount
    And match feefineactionInResponse.accountId == accountId

  Scenario: When an existing loan is claimed returned, update claimedReturnedDate, suspend any lost item fees billed and refund any lost item fees paid

    * def extManualChargeId = call uuid1
    * def extItemBarcode = 'FAT-999IBC'
    * def extUserBarcode = 'FAT-999UBC'

     # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }
    * def itemId = postItemResponse.response.id

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # post owner, manual charge and payment method
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostManualCharge') { extManualChargeId: #(extManualChargeId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPaymentMethod')

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    * def loanId = checkOutResponse.response.id

    # declare the item as lost
    * def declaredLostDateTime = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@DeclareItemLost') { loanId: #(loanId), declaredLostDateTime:#(declaredLostDateTime) }

    # get the lost item fines by loan id
    Given path 'accounts'
    And param query = 'loanId==' + loanId
    When method GET
    Then status 200
    * def accountsInResponse = karate.sort(response.accounts, (account) => account.feeFineType)
    And match response.totalRecords == 2
    And match accountsInResponse[0].status.name == 'Open'
    And match accountsInResponse[0].feeFineType == 'Lost item fee'
    And match accountsInResponse[1].status.name == 'Open'
    And match accountsInResponse[1].feeFineType == 'Lost item processing fee'
    * def lostItemFineAccountId = accountsInResponse[0].id
    * def lostItemFineAmount = accountsInResponse[0].amount
    * def lostItemFeeFineId = accountsInResponse[0].feeFineId
    * def lostItemFeeFineType = accountsInResponse[0].feeFineType
    * def lostItemProcessingFineAccountId = accountsInResponse[1].id
    * def lostItemProcessingFineAmount = accountsInResponse[1].amount
    * def lostItemProcessingFeeFineId = accountsInResponse[1].feeFineId
    * def lostItemProcessingFeeFineType = accountsInResponse[1].feeFineType

    # check-pay and verify that the fine is possible to be paid
    Given path 'accounts/' + lostItemFineAccountId + '/check-pay'
    And request { amount: '#(lostItemFineAmount)' }
    When method POST
    Then status 200
    And match response.allowed == true

    # pay the lost item fine and verify that the fine is paid fully
    * def postPayResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPay') { accountId: #(lostItemFineAccountId), amount: #(lostItemFineAmount) }
    * def feefineactionInResponse = postPayResponse.response.feefineactions[0]
    And match feefineactionInResponse.typeAction == 'Paid fully'
    And match feefineactionInResponse.amountAction == lostItemFineAmount
    And match feefineactionInResponse.accountId == lostItemFineAccountId

    # claim the item as returned
    * def claimItemReturnedDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostClaimItemReturned')

    # update accounts
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutAccount') { accountId: #(lostItemFineAccountId), barcode: #(extItemBarcode), amount: #(lostItemFineAmount), feeFineId: #(lostItemFeeFineId), feeFineType: #(lostItemFeeFineType), holdingsRecordId: #(holdingId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutAccount') { accountId: #(lostItemProcessingFineAccountId), barcode: #(extItemBarcode), amount: #(lostItemProcessingFineAmount), feeFineId: #(lostItemProcessingFeeFineId), feeFineType: #(lostItemProcessingFeeFineType), holdingsRecordId: #(holdingId) }

    # verify the loaned item status is claimed-returned
    Given path 'circulation/loans/' + loanId
    When method GET
    Then status 200
    And match $.item.status.name == 'Claimed returned'

    # refund to patron
    * def typeAction1 = 'Credited fully-Claim returned'
    * def creditedFeeInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRefundFee') { accountId: #(lostItemFineAccountId), amount: #(lostItemFineAmount), balance: 0, typeAction: #(typeAction1) }
    And match creditedFeeInResponse.response.typeAction == typeAction1
    And match creditedFeeInResponse.response.accountId == lostItemFineAccountId
    And match creditedFeeInResponse.response.amountAction == lostItemFineAmount

    * def typeAction2 = 'Refunded fully-Claim returned'
    * def refundedFeeInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRefundFee') { accountId: #(lostItemFineAccountId), amount: #(lostItemFineAmount), balance: #(lostItemFineAmount), typeAction: #(typeAction2) }
    And match refundedFeeInResponse.response.typeAction == typeAction2
    And match refundedFeeInResponse.response.accountId == lostItemFineAccountId
    And match refundedFeeInResponse.response.amountAction == lostItemFineAmount
    And match refundedFeeInResponse.response.balance == lostItemFineAmount

    # verify that the fine billed is suspended
    Given path 'accounts'
    And param query = '(loanId==' + loanId + ')'
    When method GET
    Then status 200
    * def accounts = response.accounts;
    And match accounts[0].paymentStatus.name == 'Suspended claim returned'
    And match accounts[1].paymentStatus.name == 'Suspended claim returned'

  Scenario: When an existing loan is aged to lost update agedToLostDate, item status to Aged to lost

    * def extItemBarcode = 'FAT-1000IBC'
    * def extUserBarcode = 'FAT-1000UBC'
    * def extLoanDate = '2020-01-01T00:00:00.000Z'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }

    # post a group and an user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode), extLoanDate: #(extLoanDate) }
    * def extLoanId = checkOutResponse.response.id

    # find current module id for age-to-lost processor delay time
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    When method GET
    Then status 200
    * def fun = function(module) { return module.routingEntry.pathPattern == '/circulation/scheduled-age-to-lost' }
    * def modules = karate.filter(response, fun)
    * def currentModuleId = modules[0].id

    # update age-to-lost processor delay time
    * def updateRequest = read('classpath:vega/mod-circulation/features/samples/change-age-to-lost-processor-delay-time.json')
    * updateRequest.id = currentModuleId
    * updateRequest.routingEntry.unit = 'second'
    * updateRequest.routingEntry.delay = '1'
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    And request updateRequest
    When method PATCH
    Then status 204

    # get the loan and verify that the loan has been aged to lost and got agedToLostDate
    * configure retry = { count: 5, interval: 1000 }
    Given path 'loan-storage', 'loans', extLoanId
    And retry until response.itemStatus == 'Aged to lost'
    When method GET
    Then status 200
    And match $.agedToLostDelayedBilling.agedToLostDate == '#present'
    And match $.itemStatus == 'Aged to lost'

    # revert retry configuration to default values
    * configure retry = { count: 3, interval: 3000 }

    # revert age-to-lost processor delay time
    * def revertRequest = read('classpath:vega/mod-circulation/features/samples/change-age-to-lost-processor-delay-time.json')
    * revertRequest.id = currentModuleId
    * revertRequest.routingEntry.unit = 'minute'
    * revertRequest.routingEntry.delay = '30'
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    And request revertRequest
    When method PATCH
    Then status 204

  Scenario: When an existing loan is checked in, update checkInServicePointId, returnDate

    * def extItemBarcode = 'FAT-995IBC'
    * def extUserBarcode = 'FAT-995UBC'
    * def extServicePointId = call uuid1

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint') { servicePointId: #(extServicePointId) }

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }
    * def extItemId = postItemResponse.response.id

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode) }
    * def extLoanId = checkOutResponse.response.id

    # checkIn the item and verify that checkInServicePointId and returnDate of the loan are updated
    * def extCheckInDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * def checkInResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode), extServicePointId: #(extServicePointId), extCheckInDate: #(extCheckInDate) }
    And match checkInResponse.response.loan.id == extLoanId
    And match checkInResponse.response.loan.checkinServicePointId == extServicePointId
    And match checkInResponse.response.loan.returnDate == '#present'

  Scenario: When an existing loan is marked for renewal, update the loan record including renewal count and renewal date

    * def extItemBarcode = 'FAT-994IBC'
    * def extUserBarcode = 'FAT-994UBC'
    * def extLoanDate = '2022-04-01T00:00:00.000Z'
    # loan period is set to 3 weeks by loan policy
    * def dueDateAfterRenewal = '2022-05-13T00:00:00.000+00:00'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode), extLoanDate: #(extLoanDate) }
    * def extLoanId = checkOutResponse.response.id

    # renew the loan
    * def renewalRequest = read('classpath:vega/mod-circulation/features/samples/loan-renewal-request-entity-loan.json')
    * renewalRequest.id = extLoanId
    * renewalRequest.userBarcode = extUserBarcode
    * renewalRequest.itemBarcode = extItemBarcode
    Given path 'circulation/renew-by-barcode'
    And request renewalRequest
    When method POST
    Then status 200
    And match response.renewalCount == 1
    And match response.dueDate == dueDateAfterRenewal

  Scenario: When an existing loan is aged to lost update agedToLostDate and aged to lost policy specifies delayed billing, update lostItemHasBeenBilled, dateLostItemShouldBeBilled

    * def extItemBarcode = 'FAT-1001IBC'
    * def extUserId = call uuid1
    * def extLoanDate = '2020-01-01T00:00:00.000Z'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post a group and an user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: #(extUserBarcode) }

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode), extLoanDate: #(extLoanDate) }
    * def extLoanId = checkOutResponse.response.id

    # find current module id for age-to-lost processor delay time
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    When method GET
    Then status 200
    * def fun = function(module) { return module.routingEntry.pathPattern == '/circulation/scheduled-age-to-lost' }
    * def modules = karate.filter(response, fun)
    * def currentModuleId = modules[0].id

    # update age-to-lost processor delay time
    * def updateRequest = read('classpath:vega/mod-circulation/features/samples/change-age-to-lost-processor-delay-time.json')
    * updateRequest.id = currentModuleId
    * updateRequest.routingEntry.unit = 'second'
    * updateRequest.routingEntry.delay = '1'
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    And request updateRequest
    When method PATCH
    Then status 204

    # get the loan and verify that the loan has been aged to lost and updated agedToLostDate, lostItemHasBeenBilled and dateLostItemShouldBeBilled
    * configure retry = { count: 5, interval: 1000 }
    Given path 'loan-storage', 'loans', extLoanId
    And print response
    And retry until response.itemStatus == 'Aged to lost'
    When method GET
    And match $.agedToLostDelayedBilling.agedToLostDate == '#present'
    And match $.itemStatus == 'Aged to lost'
    And match $.agedToLostDelayedBilling.lostItemHasBeenBilled == false
    And match $.agedToLostDelayedBilling.dateLostItemShouldBeBilled == '#present'

    # revert retry configuration to default values
    * configure retry = { count: 3, interval: 3000 }

    # revert age-to-lost processor delay time
    * def revertRequest = read('classpath:vega/mod-circulation/features/samples/change-age-to-lost-processor-delay-time.json')
    * revertRequest.id = currentModuleId
    * revertRequest.routingEntry.unit = 'minute'
    * revertRequest.routingEntry.delay = '30'
    Given path '/_/proxy/tenants/' + tenant + '/timers'
    And request revertRequest
    When method PATCH
    Then status 204

  Scenario: When patron has exceeded their Patron Group Limit for 'Maximum number of items charged out', patron is not allowed to borrow items per Conditions settings

    * def extItemBarcode1 = 'FAT-1019IBC-1'
    * def extUserBarcode = 'FAT-1019UBC'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode1) }

    # post a group and an user
    * def extUserId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: #(extUserBarcode) }

    # get the interested condition id, Maximum number of items charged out
    Given path 'patron-block-conditions'
    When method GET
    Then status 200
    * def conditions = karate.sort(response.patronBlockConditions, (condition) => condition.name)
    * def conditionId = conditions[0].id

    # set block actions, renewals and requests to the condition
    * def blockMessage = 'You have blocked!'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutPatronBlockConditionById') { pbcId: #(conditionId), pbcMessage: #(blockMessage), blockBorrowing: #(true), blockRenewals: #(false), blockRequests: #(false), pbcName: #('Maximum number of items charged out') }

    # set patron block limits
    * def limitId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPatronBlocksLimitsByConditionId') { id: #(limitId), extGroupId: #(groupId), pbcId: #(conditionId), extValue: #(1) }

    # checkOut the items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode1) }

    # check automated patron block of the user and verify that the user has block for borrowing
    Given path 'automated-patron-blocks', extUserId
    When method GET
    Then status 200
    And match $.automatedPatronBlocks[0].patronBlockConditionId == conditionId
    And match $.automatedPatronBlocks[0].blockBorrowing == true
    And match $.automatedPatronBlocks[0].blockRenewals == false
    And match $.automatedPatronBlocks[0].blockRequests == false

    # verify that borrowing has been blocked for the user
    * def extItemBarcode2 = 'FAT-1019IBC-2'
    * def extItemId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId), extItemBarcode: #(extItemBarcode3) }

    * def loanDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode2
    * checkOutByBarcodeEntityRequest.servicePointId = servicePointId
    * checkOutByBarcodeEntityRequest.loanDate = loanDate
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match $.errors[0].message == blockMessage

  Scenario: When an overdue item is renewed, an overdue fine is billed per the Overdue Fine Policy

    * def extItemBarcode = 'FAT-1018IBC'
    * def extUserBarcode = 'FAT-1018UBC'

     # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * def postItemResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }

    # post a group and user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode) }

    # post owner, manual charge and payment method
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostManualCharge')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPaymentMethod')

    # checkOut the item
    * def extLoanDate = '2020-01-01T00:00:00.000Z'
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode), extLoanDate: #(extLoanDate) }
    * def loanId = checkOutResponse.response.id

    # renew the loan
    * def extDueDateAfterRenewal = '2020-02-12T00:00:00.000+00:00'
    * def renewalRequest = read('classpath:vega/mod-circulation/features/samples/loan-renewal-request-entity-loan.json')
    * renewalRequest.id = loanId
    * renewalRequest.userBarcode = extUserBarcode
    * renewalRequest.itemBarcode = extItemBarcode
    Given path 'circulation/renew-by-barcode'
    And request renewalRequest
    When method POST
    Then status 200
    And match response.renewalCount == 1
    And match response.dueDate == extDueDateAfterRenewal

    # checkIn the item
    * def extCheckInDate = '2020-02-12T00:05:00.000+00:00'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: #(extItemBarcode), extCheckInDate: #(extCheckInDate) }

    # get overdue fine by loan id
    Given path 'accounts'
    And param query = 'loanId==' + loanId
    When method GET
    Then status 200
    * def accountInResponse = response.accounts[0]
    And match response.totalRecords == 1
    And match accountInResponse.status.name == 'Open'
    And match accountInResponse.feeFineType == 'Overdue fine'
    And match accountInResponse.amount == 25.0

  Scenario: When an item has the status of Lost and paid, allow checkout with override

    * def extItemBarcode = 'FAT-1014IBC'
    * def extUserBarcode1 = 'FAT-1014UBC-1'
    * def extUserBarcode2 = 'FAT-1014UBC-2'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an owner and a payment method
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPaymentMethod')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode) }

    # post a group and the first user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode1) }

    # checkout the item by the first user
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode) }
    * def extLoanId = checkOutResponse.response.id

    # declare the item as lost
    * def extDeclaredLostDateTime = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@DeclareItemLost') { loanId: #(extLoanId), declaredLostDateTime:#(extDeclaredLostDateTime) }

    # get the lost item fines by loan id
    Given path 'accounts'
    And param query = 'loanId==' + extLoanId
    When method GET
    Then status 200
    * def accountsInResponse = karate.sort(response.accounts, (account) => account.feeFineType)
    And match response.totalRecords == 2
    And match accountsInResponse[0].status.name == 'Open'
    And match accountsInResponse[0].feeFineType == 'Lost item fee'
    And match accountsInResponse[1].status.name == 'Open'
    And match accountsInResponse[1].feeFineType == 'Lost item processing fee'
    * def lostItemFineAccountId = accountsInResponse[0].id
    * def lostItemFineAmount = accountsInResponse[0].amount
    * def lostItemProcessingFineAccountId = accountsInResponse[1].id
    * def lostItemProcessingFineAmount = accountsInResponse[1].amount

    # check-pay and verify that the lost item fine is possible to be paid
    Given path 'accounts/' + lostItemFineAccountId + '/check-pay'
    And request { amount: '#(lostItemFineAmount)' }
    When method POST
    Then status 200
    And match response.allowed == true

    # pay the lost item fine and verify that the lost item fine is paid fully
    * def postPayResponse1 = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPay') { accountId: #(lostItemFineAccountId), amount: #(lostItemFineAmount) }
    * def feefineactionInResponse1 = postPayResponse1.response.feefineactions[0]
    And match feefineactionInResponse1.typeAction == 'Paid fully'
    And match feefineactionInResponse1.amountAction == lostItemFineAmount
    And match feefineactionInResponse1.accountId == lostItemFineAccountId

    # check-pay and verify that the lost item fine is possible to be paid
    Given path 'accounts/' + lostItemProcessingFineAccountId + '/check-pay'
    And request { amount: '#(lostItemProcessingFineAmount)' }
    When method POST
    Then status 200
    And match response.allowed == true

    # pay the lost item fine and verify that the lost item fine is paid fully
    * def postPayResponse2 = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPay') { accountId: #(lostItemProcessingFineAccountId), amount: #(lostItemProcessingFineAmount) }
    * def feefineactionInResponse2 = postPayResponse2.response.feefineactions[0]
    And match feefineactionInResponse2.typeAction == 'Paid fully'
    And match feefineactionInResponse2.amountAction == lostItemProcessingFineAmount
    And match feefineactionInResponse2.accountId == lostItemProcessingFineAccountId

    # check the item status and verify that it is on the lost and paid state
    * configure retry = { count: 5, interval: 1000 }
    Given path 'circulation', 'loans', extLoanId
    And retry until response.status.name == 'Closed'
    When method GET
    Then status 200
    And match $.item.status.name == 'Lost and paid'

    # revert retry configuration to default values
    * configure retry = { count: 3, interval: 3000 }

    # post the second user
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(extUserBarcode2) }

    # checkout the item which is on the lost and paid state for the second user
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode2), extCheckOutItemBarcode: #(extItemBarcode) }
    And match checkOutResponse.response.status.name == 'Open'
    And match checkOutResponse.response.borrower.barcode == extUserBarcode2
    And match checkOutResponse.response.item.barcode == extItemBarcode

  Scenario: When patron has exceeded their Patron Group Limit 'Maximum number of overdue items', patron is not allowed to borrow items per Conditions settings

    * def extUserBarcode = 'FAT-1021UBC'
    * def extItemBarcode1 = 'FAT-1021IBC-1'
    * def extItemBarcode2 = 'FAT-1021IBC-2'
    * def extLoanDate = '2020-01-01T00:00:00.000Z'
    * def conditionName = 'Maximum number of overdue items'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode2) }

    # post a group and an user
    * def extUserId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: #(extUserBarcode) }

    # get the interested condition id, Maximum number of overdue items
    Given path 'patron-block-conditions'
    When method GET
    Then status 200
    * def fun = function(condition) { return condition.name == conditionName }
    * def condition = karate.filter(response.patronBlockConditions, fun)
    * def conditionId = condition[0].id

    # set block actions, borrowing to the condition
    * def blockMessage = 'You have blocked!'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutPatronBlockConditionById') { pbcId: #(conditionId), pbcMessage: #(blockMessage), blockBorrowing: #(true), blockRenewals: #(false), blockRequests: #(false), pbcName: #(conditionName) }

    # set patron block limits
    * def limitId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPatronBlocksLimitsByConditionId') { id: #(limitId), extGroupId: #(groupId), pbcId: #(conditionId), extValue: #(1) }

    # checkOut the items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode1), extLoanDate: #(extLoanDate) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode2), extLoanDate: #(extLoanDate) }

    # check automated patron block of the user and verify that the user has block for borrowing, renewal and request
    Given path 'automated-patron-blocks', extUserId
    When method GET
    Then status 200
    And match $.automatedPatronBlocks[0].patronBlockConditionId == conditionId
    And match $.automatedPatronBlocks[0].blockBorrowing == true
    And match $.automatedPatronBlocks[0].blockRenewals == false
    And match $.automatedPatronBlocks[0].blockRequests == false

    # verify that borrowing has been blocked for the user
    * def extItemBarcode3 = 'FAT-1021IBC-3'
    * def extItemId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId), extItemBarcode: #(extItemBarcode3) }

    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode3
    * checkOutByBarcodeEntityRequest.servicePointId = servicePointId
    * checkOutByBarcodeEntityRequest.loanDate = extLoanDate
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match $.errors[0].message == blockMessage

  Scenario: When patron has exceeded their Patron Group Limit for 'Maximum outstanding fee/fine balance', patron is not allowed to borrow items per Conditions settings

    * def extItemBarcode1 = 'FAT-1023IBC-1'
    * def extUserBarcode = 'FAT-1023UBC'
    * def conditionName = 'Maximum outstanding fee/fine balance'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an owner
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostOwner')

    # post an item
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(extItemBarcode1) }

    # post a group and an user
    * def extUserId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId), extUserBarcode: #(extUserBarcode) }

    # get the interested condition id, Maximum outstanding fee/fine balance
    Given path 'patron-block-conditions'
    When method GET
    Then status 200
    * def fun = function(condition) { return condition.name == conditionName }
    * def condition = karate.filter(response.patronBlockConditions, fun)
    * def conditionId = condition[0].id

    # set block actions, borrowing to the condition
    * def blockMessage = 'You have blocked!'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutPatronBlockConditionById') { pbcId: #(conditionId), pbcMessage: #(blockMessage), blockBorrowing: #(true), blockRenewals: #(false), blockRequests: #(false), pbcName: #(conditionName) }

    # set patron block limits
    * def limitId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPatronBlocksLimitsByConditionId') { id: #(limitId), extGroupId: #(groupId), pbcId: #(conditionId), extValue: #(7.50) }

    # checkOut the item
    * def checkOutResponse = call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode), extCheckOutItemBarcode: #(extItemBarcode1) }
    * def extLoanId = checkOutResponse.response.id

    # declare item lost and verify that the user has got lost item fee/fine
    * def extLostDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@DeclareItemLost') { loanId: #(extLoanId), declaredLostDateTime: #(extLostDate), servicePointId: #(servicePointId) }

    # get the lost item fines by loan id
    Given path 'accounts'
    And param query = 'loanId==' + extLoanId
    When method GET
    Then status 200
    * def accountsInResponse = karate.sort(response.accounts, (account) => account.feeFineType)
    And match response.totalRecords == 2
    And match accountsInResponse[0].status.name == 'Open'
    And match accountsInResponse[0].feeFineType == 'Lost item fee'
    And match accountsInResponse[0].paymentStatus.name == 'Outstanding'
    And match accountsInResponse[1].status.name == 'Open'
    And match accountsInResponse[1].feeFineType == 'Lost item processing fee'
    And match accountsInResponse[1].paymentStatus.name == 'Outstanding'

    # check automated patron block of the user and verify that the user has block for borrowing
    Given path 'automated-patron-blocks', extUserId
    When method GET
    Then status 200
    And match $.automatedPatronBlocks[0].patronBlockConditionId == conditionId
    And match $.automatedPatronBlocks[0].blockBorrowing == true
    And match $.automatedPatronBlocks[0].blockRenewals == false
    And match $.automatedPatronBlocks[0].blockRequests == false

    # verify that borrowing has been blocked for the user
    * def extItemBarcode2 = 'FAT-1023IBC-2'
    * def extItemId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId), extItemBarcode: #(extItemBarcode2) }

    * def loanDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode2
    * checkOutByBarcodeEntityRequest.servicePointId = servicePointId
    * checkOutByBarcodeEntityRequest.loanDate = loanDate
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match $.errors[0].message == blockMessage

  Scenario: When patron has exceeded their Patron Group Limit for 'Maximum number of overdue recalls', patron is not allowed to borrow items per Conditions settings

    * def extItemBarcode1 = 'FAT-1022IBC-1'
    * def extItemBarcode2 = 'FAT-1022IBC-2'
    * def extItemId1 = call uuid1
    * def extItemId2 = call uuid1
    * def extInstanceId = call uuid1
    * def extUserBarcode1 = 'FAT-1022UBC-1'
    * def extUserBarcode2 = 'FAT-1022UBC-2'
    * def extUserId1 = call uuid1
    * def extUserId2 = call uuid1

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceId: #(extInstanceId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId1), extItemBarcode: #(extItemBarcode1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId2), extItemBarcode: #(extItemBarcode2) }

    # post a group and users
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId1), extUserBarcode: #(extUserBarcode1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId2), extUserBarcode: #(extUserBarcode2) }

    # get 'Maximum number of overdue recalls' condition ID
    Given path 'patron-block-conditions'
    When method GET
    Then status 200
    * def conditions = karate.sort(response.patronBlockConditions, (condition) => condition.name)
    * def conditionId = conditions[3].id

    # set patron block limits
    * def limitId = call uuid1
    * def patronBlockLimitRequest = { id: #(limitId), patronGroupId: #(groupId), conditionId: #(conditionId), value: 1 }
    Given path 'patron-block-limits'
    And request patronBlockLimitRequest
    When method POST
    Then status 201

    # set up 'Maximum number of overdue recalls' condition to only block the patron from borrowing
    * def blockMessage = 'Maximum number of overdue recalls limit reached'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutPatronBlockConditionById') { pbcId: #(conditionId), pbcMessage: #(blockMessage), blockBorrowing: #(true), blockRenewals: #(false), blockRequests: #(false), pbcName: #('Maximum number of overdue recalls') }

    # checkOut the items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode1) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode2) }

    # post two requests in order to exceed limit
    * def extRequestId1 = call uuid1
    * def extRequestId2 = call uuid2
    * def extRequestType = 'Recall'
    * def extRequestLevel = 'Item'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRequest') { requestId: #(extRequestId1), itemId: #(extItemId1), requesterId: #(extUserId2), extRequestType: #(extRequestType), extInstanceId: #(extInstanceId), extHoldingsRecordId: #(holdingId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostRequest') { requestId: #(extRequestId2), itemId: #(extItemId2), requesterId: #(extUserId2), extRequestType: #(extRequestType), extInstanceId: #(extInstanceId), extHoldingsRecordId: #(holdingId) }

    # check automated patron block of the borrower-user and verify that the user has block for borrowing
    Given path 'automated-patron-blocks', extUserId1
    When method GET
    Then status 200
    And match $.automatedPatronBlocks[0].patronBlockConditionId == conditionId
    And match $.automatedPatronBlocks[0].blockBorrowing == true
    And match $.automatedPatronBlocks[0].blockRenewals == false
    And match $.automatedPatronBlocks[0].blockRequests == false

    # verify that borrowing has been blocked for the borrower-user
    * def extItemBarcode3 = 'FAT-1022IBC-3'
    * def extItemId3 = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') {  extItemId: #(extItemId3), extItemBarcode: #(extItemBarcode3) }

    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode1
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode3
    * checkOutByBarcodeEntityRequest.servicePointId = servicePointId
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match $.errors[0].message == blockMessage

  Scenario: When patron has exceeded their Patron Group Limit for 'Recall overdue by maximum number of days', patron is not allowed to borrow items per Conditions settings

    * def extUserBarcode1 = 'FAT-1024UBC-1'
    * def extUserBarcode2 = 'FAT-1024UBC-2'
    * def extItemBarcode1 = 'FAT-1024IBC-1'
    * def conditionName = 'Recall overdue by maximum number of days'

    # location and service point setup
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostServicePoint')

    # post an item
    * def extItemId1 = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId1), extItemBarcode: #(extItemBarcode1) }

    # post a group and users
    * def extUserId1 = call uuid1
    * def extUserId2 = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostGroup') { extUserGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId1), extUserBarcode: #(extUserBarcode1), extGroupId: #(groupId) }
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostUser') { extUserId: #(extUserId2), extUserBarcode: #(extUserBarcode2), extGroupId: #(groupId) }

    # get the interested condition id, Recall overdue by maximum number of days
    Given path 'patron-block-conditions'
    When method GET
    Then status 200
    * def fun = function(condition) { return condition.name == conditionName }
    * def condition = karate.filter(response.patronBlockConditions, fun)
    * def conditionId = condition[0].id

    # set block actions, borrowing to the condition
    * def blockMessage = 'You have blocked!'
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PutPatronBlockConditionById') { pbcId: #(conditionId), pbcMessage: #(blockMessage), blockBorrowing: #(true), blockRenewals: #(false), blockRequests: #(false), pbcName: #('Recall overdue by maximum number of days') }

    # set patron block limits
    * def limitId = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostPatronBlocksLimitsByConditionId') { id: #(limitId), extGroupId: #(groupId), pbcId: #(conditionId), extValue: #(1) }

    # checkOut the items
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(extUserBarcode1), extCheckOutItemBarcode: #(extItemBarcode1) }

    # post a recall request for the item
    * def extRequestId = call uuid1
    * def requestEntityRequest = read('classpath:vega/mod-circulation/features/samples/request/request-entity-request.json')
    * requestEntityRequest.id = extRequestId
    * requestEntityRequest.itemId = extItemId1
    * requestEntityRequest.requesterId = extUserId2
    * requestEntityRequest.requestType = 'Recall'
    * requestEntityRequest.holdingsRecordId = holdingId
    * requestEntityRequest.requestLevel = 'Item'
    * requestEntityRequest.requestDate = '2021-10-27T15:51:02Z'
    Given path 'circulation', 'requests'
    And request requestEntityRequest
    When method POST
    Then status 201
    And match response.id == extRequestId
    And match response.itemId == extItemId1
    And match response.requesterId == extUserId2
    And match response.pickupServicePointId == servicePointId
    And match response.status == 'Open - Not yet filled'

    # check automated patron block of the user and verify that the user has block for borrowing
    Given path 'automated-patron-blocks', extUserId1
    When method GET
    Then status 200
    And match $.automatedPatronBlocks[0].patronBlockConditionId == conditionId
    And match $.automatedPatronBlocks[0].blockBorrowing == true
    And match $.automatedPatronBlocks[0].blockRenewals == false
    And match $.automatedPatronBlocks[0].blockRequests == false

    # verify that borrowing has been blocked for the user
    * def extItemBarcode2 = 'FAT-1024IBC-2'
    * def extItemId2 = call uuid1
    * call read('classpath:vega/mod-circulation/features/util/initData.feature@PostItem') { extItemId: #(extItemId2), extItemBarcode: #(extItemBarcode2) }

    * def loanDate = call read('classpath:vega/mod-circulation/features/util/get-time-now-function.js')
    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = extUserBarcode1
    * checkOutByBarcodeEntityRequest.itemBarcode = extItemBarcode2
    * checkOutByBarcodeEntityRequest.servicePointId = servicePointId
    * checkOutByBarcodeEntityRequest.loanDate = loanDate
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match $.errors[0].message == blockMessage

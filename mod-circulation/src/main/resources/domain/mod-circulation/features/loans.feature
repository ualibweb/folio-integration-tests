Feature: Loans tests

  Background:
    * url baseUrl
    * callonce login testUser
    * configure headers = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitoken)', 'Accept': '*/*'  }
    * def instanceId = call uuid1
    * def servicePointId = call uuid1
    * def locationId = call uuid1
    * def holdingId = call uuid1
    * def materialTypeId = call uuid1
    * def loanPolicyId = call uuid1
    * def loanPolicyMaterialId = call uuid1
    * def lostItemFeePolicyId = call uuid1
    * def overdueFinePoliciesId = call uuid1
    * def patronPolicyId = call uuid1
    * def requestPolicyId = call uuid1
    * def groupId = call uuid1
    * def userId = call uuid1
    * def userBarcode = random(100000)
    * def checkOutByBarcodeId = call uuid1
    * def parseObjectToDate = read('classpath:domain/mod-circulation/features/util/parse-object-to-date-function.js')

  Scenario: When patron and item id's entered at checkout, post a new loan using the circulation rule matched

    * def itemId = call uuid1
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostInstance')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLocation')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: 666666, extMaterialTypeId: #(materialTypeId), extItemId: #(itemId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLoanPolicy') { extLoanPolicyId: #(loanPolicyId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLoanPolicy') { extLoanPolicyId: #(loanPolicyMaterialId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLostPolicy') { extLostItemFeePolicyId: #(lostItemFeePolicyId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostOverduePolicy') { extOverdueFinePoliciesId: #(overdueFinePoliciesId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostPatronPolicy') { extPatronPolicyId: #(patronPolicyId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostRequestPolicy') { extRequestPolicyId: #(requestPolicyId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostRulesWithMaterialType') { extLoanPolicyId: #(loanPolicyId), extLostItemFeePolicyId: #(lostItemFeePolicyId), extOverdueFinePoliciesId: #(overdueFinePoliciesId), extPatronPolicyId: #(patronPolicyId), extRequestPolicyId: #(requestPolicyId), extMaterialTypeId: #(materialTypeId), extLoanPolicyMaterialId: #(loanPolicyMaterialId), extOverdueFinePoliciesMaterialId: #(overdueFinePoliciesId), extLostItemFeePolicyMaterialId: #(lostItemFeePolicyId), extRequestPolicyMaterialId: #(requestPolicyId), extPatronPolicyMaterialId: #(patronPolicyId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostGroup')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode) }

    # checkOut
    * def checkOutResponse = call read('classpath:domain/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: 666666 }

    # get loan and verify
    Given path 'circulation', 'loans'
    And param query = '(userId==' + userId + ' and ' + 'itemId==' + itemId + ')'
    When method GET
    Then status 200
    And match response.loans[0].id == checkOutResponse.response.id
    And match response.loans[0].loanPolicyId == loanPolicyMaterialId

  Scenario: Get checkIns records, define current item checkIn record and its status

    * def extInstanceTypeId = call uuid1
    * def extInstitutionId = call uuid1
    * def extCampusId = call uuid1
    * def extLibraryId = call uuid1
    * def itemId = call uuid1

    #post an item
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceTypeId: #(extInstanceTypeId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLocation') { extInstitutionId: #(extInstitutionId), extCampusId: #(extCampusId), extLibraryId: #(extLibraryId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: '555555', extItemId: #(itemId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostPolicies')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostGroup')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode)  }

    # checkOut an item
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: '555555' }

    # checkIn an item with certain itemBarcode
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@CheckInItem') { itemBarcode: '555555' }

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

    Scenario: When an existing loan is declared lost, update declaredLostDate, item status to declared lost and bill lost item fees per the Lost Item Fee Policy
      * def itemBarcode = random(100000)
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostInstance')
      * def postServicePointResult = call read('classpath:domain/mod-circulation/features/util/initData.feature@PostServicePoint')
      * def servicePointId = postServicePointResult.response.id
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostOwner') { servicePointId: #(servicePointId) }
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLocation')
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostHoldings')
      * def postItemResult = call read('classpath:domain/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: #(itemBarcode), extMaterialTypeId: #(materialTypeId) }
      * def itemId = postItemResult.response.id
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostPolicies')
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostGroup')
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: #(userBarcode) }

      * def checkOutResult = call read('classpath:domain/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: #(userBarcode), extCheckOutItemBarcode: #(itemBarcode) }
      * def loanId = checkOutResult.response.id
      * def declaredLostDateTime = call read('classpath:domain/mod-circulation/features/util/get-time-now-function.js')
      * call read('classpath:domain/mod-circulation/features/util/initData.feature@DeclareItemLost') { servicePointId: #(servicePointId), loanId: #(loanId), declaredLostDateTime:#(declaredLostDateTime) }

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

  Scenario: Post items, post patron, checkOut items, declare one as lost and checkOut additional item to exceed limit

    * def extInstanceTypeId = call uuid1
    * def extInstitutionId = call uuid1
    * def extCampusId = call uuid1
    * def extLibraryId = call uuid1
    * def itemId1 = call uuid1
    * def itemId2 = call uuid1

    # post two items
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostInstance') { extInstanceTypeId: #(extInstanceTypeId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostServicePoint')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostLocation') { extInstitutionId: #(extInstitutionId), extCampusId: #(extCampusId), extLibraryId: #(extLibraryId) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostHoldings')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: '555500', extItemId: #(itemId1) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostItem') { extItemBarcode: '555501', extItemId: #(itemId2) }
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostPolicies')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostGroup')
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostUser') { extUserBarcode: '77771' }

        # post owner associated with service point
    * def ownerEntityRequest =
    """
    {
  "owner": "Main Circ",
  "desc": "Main Library Circulation Desk",
  "servicePointOwner": [{
    "value": "#(servicePointId)",
    "label": "Main Lib Circ Desk"
  }]
}
    """
    Given path 'owners'
    And request ownerEntityRequest
    When method POST
    Then status 201

       # post patron blocks condition for max number of lost items
  # put https://folio-snapshot-load-okapi.dev.folio.org/patron-block-conditions/72b67965-5b73-4840-bc0b-be8f3f6e047e

    * def conditionId = '72b67965-5b73-4840-bc0b-be8f3f6e047e'
    * def blockConditionsRequest =
    """
  {
	"id": "#(conditionId)",
	"name": "Maximum number of lost items",
	"blockBorrowing": true,
	"blockRenewals": false,
	"blockRequests": false,
	"valueType": "Integer",
	"message": "You already lost an item!"
}
  """
    Given path 'patron-block-conditions', conditionId
    And request blockConditionsRequest
    When method PUT
    Then status 204

       # post patron blocks limit for max number of lost items as 0 pcs
  # post https://folio-snapshot-load-okapi.dev.folio.org/patron-block-limits
    * def blockLimitsRequest =
    """
  {
	"patronGroupId": "#(groupId)",
	"conditionId": "#(conditionId)",
	"value": 0,
	"id": "09305aed-a946-408b-a89f-a64348a38252"
}
  """
    Given path 'patron-block-limits'
    And request blockLimitsRequest
    When method POST
    Then status 201

        # checkOut an item
    * call read('classpath:domain/mod-circulation/features/util/initData.feature@PostCheckOut') { extCheckOutUserBarcode: '77771', extCheckOutItemBarcode: '555500' }

     # get loan
    Given path 'circulation', 'loans'
    And param query = '(userId==' + userId + ' and ' + 'itemId==' + itemId1 + ')'
    When method GET
    Then status 200
    * def currentLoanId = response.loans[0].id


        # change borrowed item status to lost
  # post https://folio-snapshot-load-okapi.dev.folio.org/circulation/loans/7975dcb6-ef79-47ae-8f53-58aabf035a01/declare-item-lost
    # loanId==7975dcb6-ef79-47ae-8f53-58aabf035a01
    * def declareItemLostRequest =
    """
  {
	"comment": "was lost",
	"servicePointId": "#(servicePointId)",
	"declaredLostDateTime": "2021-11-04T09:48:31.000Z",
	"id": "6a4b6787-5515-4917-8eaa-44dd788e35a2"
}
  """
    Given path 'circulation', 'loans', currentLoanId, 'declare-item-lost',
    And request declareItemLostRequest
    When method POST
    Then status 204

        # checkOut next item to exceed max number of lost items and generate error message
    * def checkOutByBarcodeEntityRequest = read('samples/check-out-by-barcode-entity-request.json')
    * checkOutByBarcodeEntityRequest.userBarcode = '77771'
    * checkOutByBarcodeEntityRequest.itemBarcode = '555501'
    Given path 'circulation', 'check-out-by-barcode'
    And request checkOutByBarcodeEntityRequest
    When method POST
    Then status 422
    And match response.message == 'You already lost an item!!!'


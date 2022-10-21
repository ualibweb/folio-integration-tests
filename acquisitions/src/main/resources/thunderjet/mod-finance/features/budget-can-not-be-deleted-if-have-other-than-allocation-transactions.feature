Feature: Budget can not be deleted if have other than allocation transactions

  Background:
    * url baseUrl
    # uncomment below line for development
    #* callonce dev {tenant: 'testfinance'}
    * callonce loginAdmin testAdmin
    * def okapitokenAdmin = okapitoken

    * callonce loginRegularUser testUser
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': 'application/json'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': 'application/json'  }

    * configure headers = headersUser
    * callonce variables

    * def ledgerId = callonce uuid1
    * def fundIdWithFromAllocation = callonce uuid1
    * def fundIdWithToAllocation = callonce uuid2

    * def budgetIdFromAllocation = callonce uuid3
    * def budgetIdWithToAllocation = callonce uuid4

    * def fromAllocationId = callonce uuid5
    * def toAllocationId = callonce uuid6

  Scenario: Create ledger
    * call createLedger { 'id': '#(ledgerId)'}

  Scenario Outline: Create funds and budget <budgetId> for <fundId>
    * def fundId = <fundId>
    * def ledgerId = <ledgerId>
    * def budgetId = <budgetId>
    * configure headers = headersAdmin
    * call createFund { 'id': '#(fundId)'}
    * call createBudget { 'id': '#(budgetId)', 'allocated': 10000, 'fundId': '#(fundId)'}
  Examples:
    | fundId                      | budgetId                  | ledgerId |
    | fundIdWithFromAllocation    | budgetIdFromAllocation    | ledgerId |
    | fundIdWithToAllocation      | budgetIdWithToAllocation  | ledgerId |


  Scenario Outline: Create allocation <allocationId> for <fundId>
    * def fundId = <fundId>
    * def allocationId = <allocationId>
    Given path 'finance/allocations'
    And request
    """
    {
        "id": "#(allocationId)",
        "amount": 25,
        "currency": "USD",
        "description": "To allocation",
        "fiscalYearId": "#(globalFiscalYearId)",
        "source": "User",
        "toFundId": "#(fundId)",
        "transactionType": "Allocation"
    }
    """
    When method POST
    Then status 201
    Examples:
      | fundId                      | allocationId     |
      | fundIdWithFromAllocation    | fromAllocationId |
      | fundIdWithToAllocation      | toAllocationId   |

  Scenario: Transfer money from first budget to second
    Given path 'finance-storage/transactions'
    * configure headers = headersAdmin
    And request
    """
    {
      "amount": "25",
      "currency": "USD",
      "fromFundId": "#(fundIdWithFromAllocation)",
      "toFundId": "#(fundIdWithToAllocation)",
      "fiscalYearId": "#(globalFiscalYearId)",
      "transactionType": "Transfer",
      "source": "User"
    }
    """
    When method POST
    Then status 201

  Scenario Outline: Verify that budget <budgetId> only with allocation transaction can be deleted and money were not spent
    * def budgetId = <budgetId>
    Given path 'finance/budgets', budgetId
    When method DELETE
    Then status 400
    And match response.errors[0].code == "transactionIsPresentBudgetDeleteError"
  Examples:
    | budgetId                  |
    | budgetIdFromAllocation    |
    | budgetIdWithToAllocation  |


  Scenario Outline: Verify that budget <budgetId> was not deleted
    * def budgetId = <budgetId>
    Given path 'finance/budgets', budgetId
    When method GET
    Then status 200
    Examples:
      | budgetId                  |
      | budgetIdFromAllocation    |
      | budgetIdWithToAllocation  |

  Scenario Outline: Verify that allocation transactions <allocationId> was not deleted
    * def allocationId = <allocationId>
    Given path 'finance/transactions', allocationId
    When method GET
    Then status 200
    Examples:
      | allocationId     |
      | fromAllocationId |
      | toAllocationId   |

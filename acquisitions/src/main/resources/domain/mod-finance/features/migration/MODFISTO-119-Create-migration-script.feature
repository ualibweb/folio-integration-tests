Feature: Test migration

  Background:
    * url baseUrl
    # uncomment below line for development
    * callonce dev {tenant: 'test_finance'}
    * callonce login testAdmin
    * def okapitokenAdmin = okapitoken

    * callonce login testUser
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': 'application/json'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': 'application/json'  }

    * configure headers = headersUser
    * callonce variables

    * def fundIdDonor = "6b86dcac-2f8c-4ad3-a0ab-41d15354c151"
    * def fundIdRecipient = "6b86dcac-2f8c-4ad3-a0ab-41d15354c152"
    * def fundIdDonorRecipient = "6b86dcac-2f8c-4ad3-a0ab-41d15354c153"
    * def fundIdAnotherFiscalYear = "6b86dcac-2f8c-4ad3-a0ab-41d15354c154"
    * def fundIdAnotherFiscalYear1 = "6b86dcac-2f8c-4ad3-a0ab-41d15354c155"

    * def budgetIdDonor = "6b86dcac-2f8c-4ad3-a0ab-41d15354c156"
    * def budgetIdRecipient = "6b86dcac-2f8c-4ad3-a0ab-41d15354c157"
    * def budgetIdDonorRecipient = "6b86dcac-2f8c-4ad3-a0ab-41d15354c158"


  Scenario Outline: prepare finances for fund with <fundId> and budget with <budgetId> and fiscal year <fiscalYearId>
    * def fundId = <fundId>
    * def budgetId = <budgetId>
    * def allocated = <allocated>
    * def fiscalYearId = <fiscalYearId>
    * def budgetStatus = <budgetStatus>
    * call createFund { 'id': '#(fundId)'}
    * call createBudget { 'id': '#(budgetId)', 'fundId': '#(fundId)', 'allocated': '#(allocated)', 'fiscalYearId': '#(fiscalYearId)', 'budgetStatus' : '#(budgetStatus)'}

    Examples:
      | fundId                   | budgetId                  |fiscalYearId           |allocated|budgetStatus|
      | fundIdDonor              | budgetIdDonor             |globalFiscalYearId     |30000    |'Active'    |
      | fundIdRecipient          | budgetIdRecipient         |globalFiscalYearId     |130      |'Active'    |
      | fundIdDonorRecipient     | budgetIdDonorRecipient    |globalFiscalYearId     |20000    |'Active'    |
      | fundIdAnotherFiscalYear  | budgetIdAnotherFiscalYear |globalNextFiscalYearId |5000     |'Planned'   |
      | fundIdAnotherFiscalYear1 | budgetIdAnotherFiscalYear1|globalNextFiscalYearId |7000     |'Planned'   |


  Scenario Outline: create transfer transaction with fromFundId <fromFundId>, toFundId <toFundId>, amount <amount>, fiscalYearId <fiscalYearId>
    * def fromFundId = <fromFundId>
    * def toFundId = <toFundId>
    * def amount = <amount>
    * def fiscalYearId = <fiscalYearId>

    * call createTransferTransaction { 'fromFundId': '#(fromFundId)', 'toFundId': #(toFundId), 'amount': #(amount), 'fiscalYearId': #(fiscalYearId)}

    Examples:
      | fromFundId               | toFundId            |  amount |fiscalYearId          |
      | fundIdDonor              |fundIdDonorRecipient | 1000.0  |globalFiscalYearId    |
      | fundIdDonor              |fundIdDonorRecipient | 600.5   |globalFiscalYearId    |
      | fundIdDonor              |fundIdRecipient      | 100.5   |globalFiscalYearId    |
      | fundIdDonor              |fundIdRecipient      | 500.5   |globalFiscalYearId    |
      | fundIdDonorRecipient     |fundIdRecipient      | 100.2   |globalFiscalYearId    |
      | fundIdDonorRecipient     |fundIdRecipient      | 1102    |globalFiscalYearId    |


  Scenario: Get budget
    Given path '/finance/budgets/', budgetIdDonor
    When method GET
    Then status 200
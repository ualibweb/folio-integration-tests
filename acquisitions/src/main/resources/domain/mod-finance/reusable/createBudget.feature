Feature: budget

  Background:
    * url baseUrl

  Scenario: createBudget
    * def fundId = karate.get('fundId', globalFundId)
    * def fiscalYearId = karate.get('fiscalYearId', globalFiscalYearId)
    * def budgetStatus = karate.get('budgetStatus', 'Active')

    Given path 'finance/budgets'
    And request
    """
    {
      "id": "#(id)",
      "budgetStatus": "Active",
      "fundId": "#(fundId)",
      "name": "#(id)",
      "fiscalYearId":"#(fiscalYearId)",
      "allocated": #(allocated),
      "allowableEncumbrance": 100.0,
      "allowableExpenditure": 100.0
    }
    """
    When method POST
    Then status 201

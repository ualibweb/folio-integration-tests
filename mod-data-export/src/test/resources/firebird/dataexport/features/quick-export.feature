Feature: Test quick export

  Background:
    * url baseUrl

    * callonce login testAdmin
    * def okapiAdminToken = okapitoken

    * callonce login testUser
    * def okapiUserToken = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapiUserToken)', 'Accept': 'application/json'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapiAdminToken)', 'Accept': 'application/json'  }
    * configure retry = { interval: 3000, count: 10 }
    * configure headers = headersUser

  Scenario: Quick export should return 200 status, with jobExecutionId and jobExecutionHrId
    Given path 'data-export/quick-export'
    And request
    """
    {
    "uuids": ["1762b035-f87b-4b6f-80d8-c02976e03575"],
    "type": "uuid",
    "recordType": "INSTANCE"
    }
    """
    When method POST
    Then status 200
    And match response == {jobExecutionId: '#uuid', jobExecutionHrId: '#number'}
    And def jobExecutionId = response.jobExecutionId

  ## verify job execution for quick export
    * call pause 3000
    * call read('classpath:firebird/dataexport/features/get-job-execution.feature@getJobWhenJobStatusCompleted') { jobExecutionId: '#(jobExecutionId)'}
    * def jobExecutions = response.jobExecutions
    * def jobExecution = karate.jsonPath(jobExecutions, "$.[?(@.id=='" + jobExecutionId + "')]")[0]
    And assert jobExecution.status == 'COMPLETED'
    And assert jobExecution.progress.exported == 1
    And assert jobExecution.progress.total == 1
    And match jobExecution.runBy == '#present'
    And match jobExecution.progress == '#present'
    * def hrId = '' + jobExecution.hrId
    And match jobExecution.exportedFiles[0].fileName contains hrId

  Scenario: Quick export with custom fileName should return 200 status, with jobExecutionId and jobExecutionHrId
    Given path 'data-export/quick-export'
    And request
    """
    {
    "criteria": "(languages=\"eng\")",
    "uuids": ["b73eccf0-57a6-495e-898d-32b9b2210f2f"],
    "type": "uuid",
    "recordType": "INSTANCE",
    "fileName": "test"
    }
    """
    When method POST
    Then status 200
    And match response == {jobExecutionId: '#uuid', jobExecutionHrId: '#number'}
    And def jobExecutionId = response.jobExecutionId

  ## verify job execution for quick export
    * call pause 3000
    * call read('classpath:firebird/dataexport/features/get-job-execution.feature@getJobWhenJobStatusCompleted') { jobExecutionId: '#(jobExecutionId)'}
    * def jobExecutions = response.jobExecutions
    * def jobExecution = karate.jsonPath(jobExecutions, "$.[?(@.id=='" + jobExecutionId + "')]")[0]

    Then assert jobExecution.status == 'COMPLETED'
    And assert jobExecution.progress.exported == 1
    And assert jobExecution.progress.total == 1
    And match jobExecution.runBy == '#present'
    And match jobExecution.progress == '#present'
    * def hrId = '' + jobExecution.hrId
    And match jobExecution.exportedFiles[0].fileName contains hrId
    And match jobExecution.exportedFiles[0].fileName contains 'test'

  Scenario: clear storage folder
    Given path 'data-export/clean-up-files'
    When method POST
    Then status 204
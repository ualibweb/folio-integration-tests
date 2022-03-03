Feature: Test quickMARC holdings records
  Background:
    * url baseUrl
    * callonce login testAdmin
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': 'application/json'  }
    * def utilFeature = 'classpath:spitfire/mod-quick-marc/features/setup/import-record.feature'

    * def testInstanceId = karate.properties['instanceId']
    * def testHoldingsId = karate.properties['holdingsId']

  # ================= positive test cases =================

  Scenario: Record should contains a valid 004 field
    Given path 'records-editor/records'
    And param externalId = testInstanceId
    And headers headersUser
    When method GET
    Then status 200
    And def instanceHrid = response.externalHrid

    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def tag = karate.jsonPath(response, "$.fields[?(@.tag=='004')]")[0]
    Then match tag.content == instanceHrid

  Scenario: Record should contains a 008 tag
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.fields[?(@.tag=='008')].content != null

  Scenario: Record should contains a valid 852 location code
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def tag = karate.jsonPath(response, "$.fields[?(@.tag=='852')]")[0]
    Then match tag.content != null
    Then match tag.content contains "$b olin"

  Scenario: Edit quick-marc record tags
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response
    And def tag = karate.jsonPath(record, "$.fields[?(@.tag=='867')]")[0]

    * def newTagContent = '$8 0 $a Updated Content'
    * set tag.content = newTagContent

    * remove record.fields[?(@.tag=='867')]
    * record.fields.push(tag)
    * set record.relatedRecordVersion = 2

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 202

    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match karate.jsonPath(response, "$.fields[?(@.tag=='867')]")[0].content == newTagContent

    Given path '/source-storage/source-records'
    And param recordType = 'MARC_HOLDING'
    And headers headersUser
    When method get
    Then status 200
    And match response.sourceRecords[0].parsedRecord.content.fields[*].867.subfields contains {"a": "Updated Content"}

    Given path 'holdings-storage/holdings', testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.holdingsStatementsForSupplements[0].statement == 'Updated Content'

  Scenario: Edit quick-marc record remove not required tag
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response

    * remove record.fields[?(@.tag=='867')]
    * set record.relatedRecordVersion = 3

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 202

    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.fields[?(@.tag=='867')] == []

    Given path '/source-storage/source-records'
    And param recordType = 'MARC_HOLDING'
    And headers headersUser
    When method get
    Then status 200
    And match response.sourceRecords[0].parsedRecord.content.fields[*].867 == []

    Given path 'holdings-storage/holdings', testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.holdingsStatementsForSupplements == []

  Scenario: Edit quick-marc record add new tag, should be updated in SRS
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response

    * def fields = record.fields
    * def newField = { "tag": "035", "content": "$a Test tag", "isProtected":false, "indicators": [ "\\", "\\" ] }
    * fields.push(newField)

    * set record.fields = fields
    * set record.relatedRecordVersion = 4

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 202

    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.fields contains newField

    Given path '/source-storage/source-records'
    And param recordType = 'MARC_HOLDING'
    And headers headersUser
    When method get
    Then status 200
    Then match response.sourceRecords[0].parsedRecord.content.fields[*].035 != null

    Given path 'holdings-storage/holdings', testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    Then match response.formerIds contains "Test tag"

#   ================= negative test cases =================

  Scenario: Record contains invalid 004 and not linked to instance record HRID
    * def expectedMessage = "The 004 tag of the Holdings doesn't has a link to the Bibliographic record"

    Given call read(utilFeature+'@ImportRecord') { fileName:'marcHoldingsNotValid004', jobName:'createHoldings' }
    Then match status == 'ERROR'
    Then match errorMessage == expectedMessage

  Scenario: Attempt to create a duplicate 004
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response

    * def fields = record.fields
    * def newField = { "tag": "004", "content": "in00000000002", "isProtected":false }
    * fields.push(newField)

    * set record.fields = fields
    * set record.relatedRecordVersion = 5

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 422
    Then match response.errors[0].message == 'Is unique tag'

  Scenario: Attempt to create a duplicate 852
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response

    * def fields = record.fields
    * def newField = { "tag": "852", "content": "$b Test", "isProtected": false, "indicators": [ "0", "1" ] }
    * fields.push(newField)

    * set record.fields = fields
    * set record.relatedRecordVersion = 5

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 422
    Then match response.errors[0].message == 'Is unique tag'

  Scenario: Attempt to delete 852
    Given path 'records-editor/records'
    And param externalId = testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And def record = response

    * remove record.fields[?(@.tag=='852')]
    * set record.relatedRecordVersion = 5

    Given path 'records-editor/records', record.parsedRecordId
    And headers headersUser
    And request record
    When method PUT
    Then status 422
    Then match response.errors[0].message == 'Is required tag'

    Given path 'holdings-storage/holdings', testHoldingsId
    And headers headersUser
    When method GET
    Then status 200
    And match response.callNumber == 'BR140 .J86'

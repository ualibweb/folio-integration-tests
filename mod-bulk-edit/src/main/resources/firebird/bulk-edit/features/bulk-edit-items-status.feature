Feature: bulk-edit items update status tests

  Background:
    * url baseUrl
    * callonce login testUser
    * def okapitokenAdmin = okapitoken
    * configure retry = { interval: 5000, count: 5 }
    * configure headers = { 'Accept': '*/*', 'x-okapi-token': '#(okapitokenAdmin)', 'x-okapi-tenant': '#(testUser.tenant)' }
    * def applicationJsonContentType = { 'Content-Type': 'application/json' }
    * def multipartFromDataContentType = { 'Content-Type': 'multipart/form-data' }
    * def UserUtil = Java.type('org.folio.util.UserUtil')
    * def userUtil = new UserUtil();
    * callonce loadVariables

  # POSITIVE SCENARIOS - BARCODE IDENTIFIER

  Scenario: test bulk-edit job type BULK_EDIT_IDENTIFIERS
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/get_item_status_records.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

    #error logs should be empty

    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0


    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200
    And karate.log("item status response",response)

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And match $.progress contains { total: 2, processed: 2, progress: 100}

        #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedPreviewItemsJson = read('classpath:samples/item/json/expected_items_status_preview_after_update.json')
    And def expected = karate.sort(expectedPreviewItemsJson.items, x => x.barcode)
    And def actual = karate.sort(response.items, x => x.barcode)
    And match $.totalRecords == 2
    And match actual[0] contains deep expected[0]
    And match actual[1] contains deep expected[1]


    #error logs should be empty
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0

  # NEGATIVE SCENARIO - UUID IDENTIFIER

  Scenario: test bulk-edit job type ITEM_STATUS update with errors
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/invalid_item_status_barcode.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

#    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/invalid_item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 2
    And def fileLink = $.files[1]

    #verfiy errors file
    Given url fileLink
    When method GET
    Then status 200
    And def expectedCsvFile = karate.readAsString('classpath:samples/item/csv/invalid_status_expected_errors.csv')
    And def fileMatches = userUtil.compareErrorsCsvFiles(expectedCsvFile, response);
    And match fileMatches == true

    #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.items[0].status.name != ""
    And match $.items[1].status.name != ""

    #get errors should return status update not allowed error
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedErrorsJson = read('classpath:samples/item/json/invalid_status_expected_errors.json')
    And match $.total_records == 6
    And match $.errors contains deep expectedErrorsJson.errors[0]


    # POSITIVE SCENARIOS - UUID AS AN IDENTIFIER

  Scenario: test bulk-edit job type BULK_EDIT_IDENTIFIERS
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersUUIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/get_item_status_uuid_records.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

    #error logs should be empty

    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0


    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200
    And karate.log("item status response",response)

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And match $.progress contains { total: 2, processed: 2, progress: 100}

        #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedPreviewItemsJson = read('classpath:samples/item/json/expected_items_status_preview_after_update.json')
    And def expected = karate.sort(expectedPreviewItemsJson.items, x => x.barcode)
    And def actual = karate.sort(response.items, x => x.barcode)
    And match $.totalRecords == 2
    And match actual[0] contains deep expected[0]
    And match actual[1] contains deep expected[1]


    #error logs should be empty
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0

#  # NEGATIVE SCENARIO - UUID IDENTIFIER

  Scenario: test bulk-edit job type ITEM_STATUS update with errors
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersUUIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/invalid_item_status_uuid.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

#    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/invalid_item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 2
    And def fileLink = $.files[1]

    #verfiy errors file
    Given url fileLink
    When method GET
    Then status 200
    And def expectedCsvFile = karate.readAsString('classpath:samples/item/csv/invalid_status_expected_errors.csv')
    And def fileMatches = userUtil.compareErrorsCsvFiles(expectedCsvFile, response);
    And match fileMatches == true

    #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.items[0].status.name != ""
    And match $.items[1].status.name != ""

    #get errors should return status update not allowed error
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedErrorsJson = read('classpath:samples/item/json/invalid_status_expected_errors.json')
    And match $.total_records == 6
    And match $.errors contains deep expectedErrorsJson.errors[0]

     # POSITIVE SCENARIOS - HRID AS AN IDENTIFIER

  Scenario: test bulk-edit job type BULK_EDIT_IDENTIFIERS
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersHRIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/get_item_status_hrid_records.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

    #error logs should be empty

    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0


    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200
    And karate.log("item status response",response)

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And match $.progress contains { total: 2, processed: 2, progress: 100}

        #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedPreviewItemsJson = read('classpath:samples/item/json/expected_items_status_preview_after_update.json')
    And def expected = karate.sort(expectedPreviewItemsJson.items, x => x.barcode)
    And def actual = karate.sort(response.items, x => x.barcode)
    And match $.totalRecords == 2
    And match actual[0] contains deep expected[0]
    And match actual[1] contains deep expected[1]

    #error logs should be empty
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0

#  # NEGATIVE SCENARIO - HRID IDENTIFIER

  Scenario: test bulk-edit job type ITEM_STATUS update with errors
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersHRIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/invalid_item_status_hrid.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '2'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

#    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/invalid_item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 2
    And def fileLink = $.files[1]

    #verfiy errors file
    Given url fileLink
    When method GET
    Then status 200
    And def expectedCsvFile = karate.readAsString('classpath:samples/item/csv/invalid_status_expected_errors.csv')
    And def fileMatches = userUtil.compareErrorsCsvFiles(expectedCsvFile, response);
    And match fileMatches == true

    #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.items[0].status.name != ""
    And match $.items[1].status.name != ""

    #get errors should return status update not allowed error
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedErrorsJson = read('classpath:samples/item/json/invalid_status_expected_errors.json')
    And match $.total_records == 6
    And match $.errors contains deep expectedErrorsJson.errors[0]


         # POSITIVE SCENARIOS - HOLDINGS HRID AS AN IDENTIFIER

  Scenario: test bulk-edit job type BULK_EDIT_IDENTIFIERS
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersHoldingsHRIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/get_item_status_holdings_hrid_records.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '1'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

    #error logs should be empty

    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0


    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200
    And karate.log("item status response",response)

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And match $.progress contains { total: 1, processed: 1, progress: 100}

        #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedPreviewItemsJson = read('classpath:samples/item/json/expected_items_status_hrid_preview_after_update.json')
    And def expected = karate.sort(expectedPreviewItemsJson.items, x => x.barcode)
    And def actual = karate.sort(response.items, x => x.barcode)
    And match $.totalRecords == 2
    And match actual[0] contains deep expected[0]
    And match actual[1] contains deep expected[1]

    #error logs should be empty
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0

#  # NEGATIVE SCENARIO - HOLDINGS HRID IDENTIFIER

  Scenario: test bulk-edit job type ITEM_STATUS update with errors
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersHoldingsHRIDJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/invalid_item_status_holdings_hrid.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '1'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

#    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/invalid_item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 2
    And def fileLink = $.files[1]

    #verfiy errors file
    Given url fileLink
    When method GET
    Then status 200
    And def expectedCsvFile = karate.readAsString('classpath:samples/item/csv/invalid_status_expected_hhrid_errors.csv')
    And def fileMatches = userUtil.compareErrorsCsvFiles(expectedCsvFile, response);
    And match fileMatches == true

    #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.items[0].status.name != ""
    And match $.items[1].status.name != ""

    #get errors should return status update not allowed error
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedErrorsJson = read('classpath:samples/item/json/invalid_status_hhrid_expected_errors.json')
    And match $.total_records == 3
    And match $.errors contains deep expectedErrorsJson.errors[0]



         # POSITIVE SCENARIOS - ACCESSION NUMBER AS AN IDENTIFIER

  Scenario: test bulk-edit job type BULK_EDIT_IDENTIFIERS
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersAccessionJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/get_item_status_accession_number_records.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '1'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

    #error logs should be empty

    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0


    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200
    And karate.log("item status response",response)

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

        #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And match $.progress contains { total: 1, processed: 1, progress: 100}

        #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedPreviewItemsJson = read('classpath:samples/item/json/expected_items_status_accession_preview_after_update.json')
    And match $.totalRecords == 1
    And match $.items[0] contains deep expectedPreviewItemsJson.items[0]


    #error logs should be empty
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.total_records == 0

#  # NEGATIVE SCENARIO - HOLDINGS HRID IDENTIFIER

  Scenario: test bulk-edit job type ITEM_STATUS update with errors
    #create bulk-edit job
    Given path 'data-export-spring/jobs'
    And headers applicationJsonContentType
    And request itemIdentifiersAccessionJob
    When method POST
    Then status 201
    And match $.status == 'SCHEDULED'
    And def jobId = $.id

    #uplaod file and trigger the job automatically
    Given path 'bulk-edit', jobId, 'upload'
    And multipart file file = { read: 'classpath:samples/item/csv/invalid_item_status_accession.csv', contentType: 'text/csv' }
    And headers multipartFromDataContentType
    When method POST
    Then status 200
    And string responseMessage = response
    And match responseMessage == '1'

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 1
    And def fileLink = $.files[0]

#    #post content update
    Given path 'bulk-edit', jobId, 'item-content-update/upload'
    And headers applicationJsonContentType
    And def itemStatusUpdate = read('classpath:samples/item/json/invalid_item_status_content_update.json')
    And request itemStatusUpdate
    When method POST
    Then status 200

    #trigger the job execution
    Given path 'bulk-edit', jobId, 'start'
    And headers applicationJsonContentType
    When method POST
    Then status 200

    #get job until status SUCCESSFUL and validate
    Given path 'data-export-spring/jobs', jobId
    And headers applicationJsonContentType
    And retry until response.status == 'SUCCESSFUL'
    When method GET
    Then status 200
    And match $.startTime == '#present'
    And match $.endTime == '#present'
    And assert response.files.length == 2
    And def fileLink = $.files[1]

    #verfiy errors file
    Given url fileLink
    When method GET
    Then status 200
    And def expectedCsvFile = karate.readAsString('classpath:samples/item/csv/invalid_status_expected_accession_errors.csv')
    And def fileMatches = userUtil.compareErrorsCsvFiles(expectedCsvFile, response);
    And match fileMatches == true

    #get preview
    Given url baseUrl
    And path 'bulk-edit', jobId, 'preview/items'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And match $.items[0].status.name != ""

    #get errors should return status update not allowed error
    Given path 'bulk-edit', jobId, 'errors'
    And param limit = 10
    And headers applicationJsonContentType
    When method GET
    Then status 200
    And def expectedErrorsJson = read('classpath:samples/item/json/invalid_status_accession_expected_errors.json')
    And match $.total_records == 3
    And match $.errors contains deep expectedErrorsJson.errors[0]
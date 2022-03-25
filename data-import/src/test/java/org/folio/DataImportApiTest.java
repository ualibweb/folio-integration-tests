package org.folio;

import org.folio.test.TestBase;
import org.folio.test.config.TestModuleConfiguration;
import org.folio.test.services.TestIntegrationService;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class DataImportApiTest extends TestBase {
    private static final String TEST_BASE_PATH = "classpath:folijet/data-import/features/";

    public DataImportApiTest() {
        super(new TestIntegrationService(new TestModuleConfiguration(TEST_BASE_PATH)));
    }

    @Test
    @Order(1)
    void dataImportIntegrationTest() {
        runFeatureTest("data-import-integration");
    }

    @Test
    @Order(2)
    void testCreateRecords() {
        runFeatureTest("create-marc-authority-records");
    }

    @Test
    void fileExtensionsTest() {
        runFeatureTest("file-extensions");
    }

    @Test
    void fileUploadTest() {
        runFeatureTest("file-upload");
    }

    @Test
    void importInvoiceTest() {
        runFeatureTest("import-edi-invoice");
    }

    @Test
    void testDataImportAuthorityRecordsFeature() {
        runFeatureTest("data-import-authority-records");
    }

    @BeforeAll
    public void setup() {
        runFeature("classpath:folijet/data-import/data-import-junit.feature");
    }

    @AfterAll
    public void ordersApiTestAfterAll() {
        runFeature("classpath:common/destroy-data.feature");
    }
}

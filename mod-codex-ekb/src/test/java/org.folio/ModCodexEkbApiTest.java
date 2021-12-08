package org.folio;

import org.folio.test.TestBase;
import org.folio.test.config.TestModuleConfiguration;
import org.folio.test.services.TestIntegrationService;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

public class ModCodexEkbApiTest extends TestBase {
    private static final String TEST_BASE_PATH = "classpath:spitfire/codexekb/features/";

    public ModCodexEkbApiTest() {
        super(new TestIntegrationService(new TestModuleConfiguration(TEST_BASE_PATH)));
    }

    @BeforeAll
    public void modCodexEkbBeforeAll() {
        runFeature("classpath:spitfire/codexekb/basic-junit.feature");
    }

    @Test
    void instancesTest() {
        runFeatureTest("codex-instances");
    }

    @Test
    void packagesTest() {
        runFeatureTest("codex-packages");
    }

    @AfterAll
    public void modCodexEkbAfterAll() {
        runFeature("classpath:common/destroy-data.feature");
    }
}

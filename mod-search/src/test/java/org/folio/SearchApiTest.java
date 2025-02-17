package org.folio;

import org.folio.test.TestBase;
import org.folio.test.annotation.FolioTest;
import org.folio.test.config.TestModuleConfiguration;
import org.folio.test.services.TestIntegrationService;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@FolioTest(team = "spitfire", module = "mod-search")
class SearchApiTest extends TestBase {

    private static final String TEST_BASE_PATH = "classpath:spitfire/mod-search/";

    public SearchApiTest() {
        super(new TestIntegrationService(
                new TestModuleConfiguration(TEST_BASE_PATH)));
    }

    @BeforeAll
    void setUpTenant() {
        runFeatureTest("set-up/tenant-init");
    }

    @AfterAll
    void destroyTenant() {
        runFeatureTest("set-up/tenant-destroy");
    }

    @ValueSource(strings = {
            "authority-single-property-search",
            "resource-job-ids-search",
            "single-property-search",
            "boolean-search"
    })
    @ParameterizedTest
    void runSearchTest(String featureName) {
        runFeatureTest("search/" + featureName);
    }

    @ValueSource(strings = {
            "sort-by-option-search.feature",
            "facet-search.feature",
            "filter-search"
    })
    @ParameterizedTest
    void runFiltersTest(String featureName) {
        runFeatureTest("filters/" + featureName);
    }

    @ValueSource(strings = {
            "authority-browse.feature",
            "call-number-browse.feature",
            "subject-browse.feature",
            "contributor-browse.feature"
    })
    @ParameterizedTest
    void runBrowseTest(String featureName) {
        runFeatureTest("browse/" + featureName);
    }
}

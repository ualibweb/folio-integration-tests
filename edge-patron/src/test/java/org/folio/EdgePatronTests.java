package org.folio;

import org.folio.test.TestBase;
import org.folio.test.config.TestModuleConfiguration;
import org.folio.test.services.TestIntegrationService;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class EdgepatronTests extends TestBase {

  public EdgepatronTests() {
    super(new TestIntegrationService(new TestModuleConfiguration("classpath:domain/edge-patron/features/")));
  }

  @BeforeAll
  public void setup() {
    runFeature("classpath:domain/edge-patron/patron-junit.feature");
  }

  @Test
  void patronTest() {
    runFeatureTest("patrons");
  }
}

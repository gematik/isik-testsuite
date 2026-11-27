/*-
 * #%L
 * tiger-integration-isik
 * %%
 * Copyright (C) 2025 - 2026 gematik GmbH
 * %%
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * *******
 *
 * For additional notes and disclaimer from gematik and in case of changes
 * by gematik, find details in the "Readme" file.
 * #L%
 */
package de.gematik.isik.test.report;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ReportArchiveSanitizerTest {

  @TempDir Path tempDirectory;

  @Test
  void redactsHeaderValuesAndCredentialFieldsWithoutRemovingEvidence() {
    String report =
        "{\"headers\":{\"Authorization\":\"Bearer bearer-secret\","
            + "\"X-Api-Key\":\"api-secret\"},"
            + "\"password\":\"password secret\","
            + "\"message\":\"Authorization: Custom custom-secret; Bearer inline-secret\"}";

    String sanitized = ReportArchiveSanitizer.redactSensitiveValues(report);

    assertFalse(sanitized.contains("bearer-secret"));
    assertFalse(sanitized.contains("api-secret"));
    assertFalse(sanitized.contains("password secret"));
    assertFalse(sanitized.contains("custom-secret"));
    assertFalse(sanitized.contains("inline-secret"));
    assertTrue(sanitized.contains("\"message\""));
    assertTrue(sanitized.contains("[REDACTED]"));
  }

  @Test
  void stagesSanitizedCopiesWithoutChangingOriginalReportSources() throws IOException {
    Path target = tempDirectory.resolve("target");
    Path project = tempDirectory.resolve("project");
    Path unresolvedReport = target.resolve("site/serenity/unresolvedReports/result.json");
    Path failsafeLog = target.resolve("failsafe-reports/result.txt");
    Path serverLog = target.resolve("serverLogs/server.log");
    Path testData = target.resolve("test-classes/testdata/credentials.yaml");
    Path tigerConfig = project.resolve("tiger.yaml");
    Path pom = project.resolve("pom.xml");
    String unresolvedSecret = "unresolved-secret";
    String configSecret = "config-secret";
    String logSecret = "log-secret";

    write(
        unresolvedReport, "{\"headers\":{\"Authorization\":\"Bearer " + unresolvedSecret + "\"}}");
    write(target.resolve("site/serenity/serenity-summary.html"), "<p>Bearer summary-secret</p>");
    write(failsafeLog, "Authorization: Basic " + logSecret);
    write(serverLog, "access_token: server-log-secret");
    write(testData, "password: " + configSecret);
    write(tigerConfig, "Authorization: Bearer tiger-secret");
    write(pom, "<project><password>pom-secret</password></project>");

    ReportArchiveSanitizer.prepareReportArchives(target, project);

    Path staged = target.resolve("sanitized-reports");
    assertRedacted(staged.resolve("test-report/unresolvedReports/result.json"), unresolvedSecret);
    assertRedacted(staged.resolve("test-report/pom.xml"), "pom-secret");
    assertRedacted(staged.resolve("debug-report/serenity/serenity-summary.html"), "summary-secret");
    assertRedacted(
        staged.resolve("debug-report/logs/target/failsafe-reports/result.txt"), logSecret);
    assertRedacted(
        staged.resolve("debug-report/logs/target/serverLogs/server.log"), "server-log-secret");
    assertRedacted(
        staged.resolve("debug-report/config/target/test-classes/testdata/credentials.yaml"),
        configSecret);
    assertRedacted(staged.resolve("debug-report/config/tiger.yaml"), "tiger-secret");
    assertTrue(Files.readString(unresolvedReport).contains(unresolvedSecret));
    assertTrue(Files.readString(tigerConfig).contains("tiger-secret"));
  }

  private static void write(Path path, String content) throws IOException {
    Files.createDirectories(path.getParent());
    Files.writeString(path, content);
  }

  private static void assertRedacted(Path path, String secret) throws IOException {
    assertFalse(Files.readString(path).contains(secret), path.toString());
  }
}

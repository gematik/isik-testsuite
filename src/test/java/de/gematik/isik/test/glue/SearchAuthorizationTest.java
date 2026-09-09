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
package de.gematik.isik.test.glue;

import static de.gematik.isik.test.glue.IsikGlue.assertForbiddenOrEmptySearch;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class SearchAuthorizationTest {

  @Test
  void acceptsForbiddenWithoutRequiringAFhirBody() {
    assertDoesNotThrow(() -> assertForbiddenOrEmptySearch("403", ""));
  }

  @ParameterizedTest
  @ValueSource(
      strings = {
        "{\"resourceType\":\"Bundle\",\"type\":\"searchset\"}",
        "{\"resourceType\":\"Bundle\",\"type\":\"searchset\",\"total\":0,\"entry\":[]}"
      })
  void acceptsEmptySearchBundles(String body) {
    assertDoesNotThrow(() -> assertForbiddenOrEmptySearch("200", body));
  }

  @ParameterizedTest
  @ValueSource(strings = {"201", "204", "400", "401", "404", "500"})
  void rejectsOtherStatusesEvenWithAnEmptyBundle(String status) {
    assertThrows(
        AssertionError.class,
        () ->
            assertForbiddenOrEmptySearch(
                status, "{\"resourceType\":\"Bundle\",\"type\":\"searchset\",\"total\":0}"));
  }

  @ParameterizedTest
  @ValueSource(
      strings = {
        "",
        "not JSON",
        "{\"resourceType\":\"OperationOutcome\"}",
        "{\"resourceType\":\"Patient\",\"id\":\"hidden\"}",
        "{\"resourceType\":\"Bundle\"}",
        "{\"resourceType\":\"Bundle\",\"type\":\"collection\"}",
        "{\"resourceType\":\"Bundle\",\"type\":\"searchset\",\"total\":1}"
      })
  void rejectsInvalidOrNonemptySuccessResponses(String body) {
    assertThrows(AssertionError.class, () -> assertForbiddenOrEmptySearch("200", body));
  }

  @ParameterizedTest
  @ValueSource(strings = {"Condition", "Patient", "Encounter"})
  void rejectsAnyReturnedResourceEvenWhenTotalIsZero(String resourceType) {
    String body =
        "{\"resourceType\":\"Bundle\",\"type\":\"searchset\",\"total\":0,"
            + "\"entry\":[{\"search\":{\"mode\":\"include\"},\"resource\":{\"resourceType\":\""
            + resourceType
            + "\",\"id\":\"hidden\"}}]}";
    assertThrows(AssertionError.class, () -> assertForbiddenOrEmptySearch("200", body));
  }
}

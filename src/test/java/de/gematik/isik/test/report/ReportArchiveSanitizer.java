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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

public final class ReportArchiveSanitizer {

  private static final String SENSITIVE_KEYS =
      "(?:authorization|proxy-authorization|www-authenticate|proxy-authenticate|cookie|set-cookie"
          + "|x-api-key|x-auth-token|api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token"
          + "|auth[_-]?token|oauth[_-]?token|session[_-]?token|client[_-]?(?:secret|password|id)"
          + "|password|passwd|secret|credential|username|user[_-]?name|private[_-]?key|token)";

  private static final Pattern JSON_SENSITIVE_FIELD =
      Pattern.compile(
          "(?i)(\""
              + SENSITIVE_KEYS
              + "\"\\s*:\\s*)(\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|[^,}\\]]+)");
  private static final Pattern YAML_SENSITIVE_FIELD =
      Pattern.compile("(?im)(^[ \\t]*(?:" + SENSITIVE_KEYS + ")[ \\t]*:[ \\t]*).*$");
  private static final Pattern XML_SENSITIVE_ELEMENT =
      Pattern.compile(
          "(?is)(<\\s*(?:[\\w.-]+:)?("
              + SENSITIVE_KEYS
              + ")\\b[^>]*>).*?(</\\s*(?:[\\w.-]+:)?\\2\\s*>)");
  private static final Pattern HEADER_VALUE =
      Pattern.compile(
          "(?i)(\\b(?:authorization|proxy-authorization|www-authenticate|proxy-authenticate"
              + "|x-api-key|x-auth-token|cookie|set-cookie)\\b\\s*[:=]\\s*)"
              + "(\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|[^\\r\\n,;}\\]<>\"']+)");
  private static final Pattern INLINE_CREDENTIAL =
      Pattern.compile(
          "(?i)(\\b(?:api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token|auth[_-]?token"
              + "|oauth[_-]?token|session[_-]?token|client[_-]?(?:secret|password|id)|password"
              + "|passwd|secret|credential|username|user[_-]?name|private[_-]?key|token)"
              + "\\b\\s*[=:]\\s*)"
              + "(\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|[^\\s,;&}\\]<>\"']+)");
  private static final Pattern AUTH_SCHEME_TOKEN =
      Pattern.compile("(?i)\\b(Bearer|Basic)\\s+[A-Za-z0-9._~+/-]+=*");
  private static final Set<String> TEXT_EXTENSIONS =
      Set.of(
          ".css",
          ".csv",
          ".feature",
          ".html",
          ".htm",
          ".ini",
          ".js",
          ".json",
          ".log",
          ".md",
          ".properties",
          ".sh",
          ".svg",
          ".text",
          ".txt",
          ".xml",
          ".yaml",
          ".yml");

  private ReportArchiveSanitizer() {}

  public static void main(String[] args) throws IOException {
    if (args.length != 2) {
      throw new IllegalArgumentException("Expected target directory and project directory");
    }
    prepareReportArchives(Path.of(args[0]), Path.of(args[1]));
  }

  static void prepareReportArchives(Path targetDirectory, Path projectDirectory)
      throws IOException {
    Path stagingDirectory = targetDirectory.resolve("sanitized-reports");
    deleteTree(stagingDirectory);

    Path testReport = stagingDirectory.resolve("test-report");
    Path debugReport = stagingDirectory.resolve("debug-report");
    Files.createDirectories(testReport);
    Files.createDirectories(debugReport.resolve("serenity"));
    Files.createDirectories(debugReport.resolve("config/target/test-classes/testdata"));
    Files.createDirectories(debugReport.resolve("logs/target/failsafe-reports"));
    Files.createDirectories(debugReport.resolve("logs/target/serverLogs"));

    Path serenityReports = targetDirectory.resolve("site/serenity");
    copyTree(serenityReports, testReport);
    copyTree(serenityReports, debugReport.resolve("serenity"));
    copyFile(projectDirectory.resolve("pom.xml"), testReport.resolve("pom.xml"));
    copyFile(projectDirectory.resolve("tiger.yaml"), debugReport.resolve("config/tiger.yaml"));
    copyMatchingFiles(
        targetDirectory.resolve("test-classes/testdata"),
        debugReport.resolve("config/target/test-classes/testdata"),
        ".yaml");
    copyMatchingFiles(
        targetDirectory.resolve("failsafe-reports"),
        debugReport.resolve("logs/target/failsafe-reports"),
        ".txt");
    copyTree(targetDirectory.resolve("serverLogs"), debugReport.resolve("logs/target/serverLogs"));
  }

  static String redactSensitiveValues(String content) {
    String sanitized = replace(JSON_SENSITIVE_FIELD, content, "$1\"[REDACTED]\"");
    sanitized = replace(YAML_SENSITIVE_FIELD, sanitized, "$1[REDACTED]");
    sanitized = replace(XML_SENSITIVE_ELEMENT, sanitized, "$1[REDACTED]$3");
    sanitized = replace(HEADER_VALUE, sanitized, "$1[REDACTED]");
    sanitized = replace(INLINE_CREDENTIAL, sanitized, "$1[REDACTED]");
    return replace(AUTH_SCHEME_TOKEN, sanitized, "$1 [REDACTED]");
  }

  private static String replace(Pattern pattern, String content, String replacement) {
    return pattern.matcher(content).replaceAll(replacement);
  }

  private static void copyTree(Path source, Path destination) throws IOException {
    if (!Files.exists(source, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    if (Files.isSymbolicLink(source)) {
      throw new IOException("Refusing to archive symbolic link: " + source);
    }
    if (!Files.isDirectory(source)) {
      throw new IOException("Expected a report directory: " + source);
    }
    Files.walkFileTree(
        source,
        new SimpleFileVisitor<>() {
          @Override
          public FileVisitResult preVisitDirectory(Path directory, BasicFileAttributes attributes)
              throws IOException {
            if (attributes.isSymbolicLink()) {
              throw new IOException("Refusing to archive symbolic link: " + directory);
            }
            Files.createDirectories(destination.resolve(source.relativize(directory)));
            return FileVisitResult.CONTINUE;
          }

          @Override
          public FileVisitResult visitFile(Path file, BasicFileAttributes attributes)
              throws IOException {
            if (attributes.isSymbolicLink()) {
              throw new IOException("Refusing to archive symbolic link: " + file);
            }
            if (attributes.isRegularFile()) {
              copyFile(file, destination.resolve(source.relativize(file)));
            }
            return FileVisitResult.CONTINUE;
          }
        });
  }

  private static void copyMatchingFiles(Path source, Path destination, String extension)
      throws IOException {
    if (!Files.exists(source, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    if (Files.isSymbolicLink(source)) {
      throw new IOException("Refusing to archive symbolic link: " + source);
    }
    if (!Files.isDirectory(source)) {
      throw new IOException("Expected a report directory: " + source);
    }
    try (var files = Files.list(source)) {
      for (Path file : files.toList()) {
        if (Files.isSymbolicLink(file)) {
          throw new IOException("Refusing to archive symbolic link: " + file);
        }
        if (Files.isRegularFile(file) && file.getFileName().toString().endsWith(extension)) {
          copyFile(file, destination.resolve(file.getFileName()));
        }
      }
    }
  }

  private static void copyFile(Path source, Path destination) throws IOException {
    if (!Files.exists(source, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    if (Files.isSymbolicLink(source)) {
      throw new IOException("Refusing to archive symbolic link: " + source);
    }
    if (!Files.isRegularFile(source)) {
      throw new IOException("Expected a report file: " + source);
    }
    Files.createDirectories(destination.getParent());
    String fileName = source.getFileName().toString().toLowerCase(Locale.ROOT);
    if (TEXT_EXTENSIONS.stream().anyMatch(fileName::endsWith)) {
      Files.writeString(
          destination, redactSensitiveValues(Files.readString(source, StandardCharsets.UTF_8)));
    } else {
      Files.copy(source, destination);
    }
  }

  private static void deleteTree(Path directory) throws IOException {
    if (!Files.exists(directory)) {
      return;
    }
    Files.walkFileTree(
        directory,
        new SimpleFileVisitor<>() {
          @Override
          public FileVisitResult visitFile(Path file, BasicFileAttributes attributes)
              throws IOException {
            Files.delete(file);
            return FileVisitResult.CONTINUE;
          }

          @Override
          public FileVisitResult postVisitDirectory(Path dir, IOException exception)
              throws IOException {
            if (exception != null) {
              throw exception;
            }
            Files.delete(dir);
            return FileVisitResult.CONTINUE;
          }
        });
  }
}

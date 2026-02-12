# Project-specific Dockerfile

#We recommend to use a base image of the same version as the tiger version you are using in your project.
# This ensures that the tiger dependencies are already loaded into the local maven repository.
# https://hub.docker.com/r/gematik1/tiger-testsuite-baseimage/tags
FROM gematik1/tiger-testsuite-baseimage:4.1.7

# Git Args
ARG COMMIT_HASH
ARG VERSION

ENV MAVEN_PROFILE=stufe3 \
    TESTS_TO_RUN="@Stufe3 and (not @Optional)"

LABEL de.gematik.vendor="gematik GmbH" \
      maintainer="software-development@gematik.de" \
      de.gematik.app="ISIK Testsuite" \
      de.gematik.git-repo-name="https://github.com/gematik/isik-testsuite" \
      de.gematik.commit-sha=$COMMIT_HASH \
      de.gematik.version=$VERSION

USER root

# Uupgrade packages
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

USER tiger-testsuite

# Optional: if you need a different dependency script, overwrite the one inside the base image
# -chown is needed because the COPY command will otherwise copy the file as root
COPY --chown=tiger-testsuite . /app

RUN mvn clean dependency:go-offline verify -DskipTests -ntp

# The base image executes as an entry point the command mvn clean verify in the /app folder. And afterwards
# it copies an existing *report.zip from /app/target/*report.zip to /app/report/
# Currently your project needs to ensure the zip files is created
# You can define your own ENTRYPOINT which will override the one from the base image
# Command to be executed.
ENTRYPOINT ["bash", "-c", "rm -rf $REPORT_DIR/* ; mvn clean verify -ntp -P${MAVEN_PROFILE} -DTESTS_TO_RUN=\"${TESTS_TO_RUN}\" || true ; mv -v $APP_HOME/target/*report.zip $REPORT_DIR/"]
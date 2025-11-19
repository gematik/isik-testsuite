# Project-specific Dockerfile

#We recommend to use a base image of the same version as the tiger version you are using in your project.
# This ensures that the tiger dependencies are already loaded into the local maven repository.
FROM gematik1/tiger-testsuite-baseimage:4.1.1

# Git Args
ARG COMMIT_HASH
ARG VERSION

LABEL de.gematik.vendor="gematik GmbH" \
      maintainer="software-development@gematik.de" \
      de.gematik.app="ISIK3 Testsuite" \
      de.gematik.git-repo-name="https://github.com/gematik/isik3-testsuite" \
      de.gematik.commit-sha=$COMMIT_HASH \
      de.gematik.version=$VERSION


# Optional: if you need a different dependency script, overwrite the one inside the base image
# -chown is needed because the COPY command will otherwise copy the file as root
COPY --chown=tiger-testsuite . /app

RUN mvn clean dependency:go-offline verify -DskipTests -ntp

# The base image executes as an entry point the command mvn clean verify in the /app folder. And afterwards
# it copies an existing *report.zip from /app/target/*report.zip to /app/report/
# Currently your project needs to ensure the zip files is created
# You can define your own ENTRYPOINT which will override the one from the base image
# Command to be executed.

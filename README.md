<img align="right" width="250" height="47" src="imgs/gematik_logo.png"/> <br/> 

# ISiK Test Suite

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
       <ul>
        <li><a href="#release-notes">Release Notes</a></li>
      </ul>
	</li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project
This is a test suite for conformance tests of the ISiK specification modules, for both Stufe 3 and 5:

- Stufe 3
  - [Basis](https://simplifier.net/guide/isik-basis-v3?version=current)
  - [Medikation](https://simplifier.net/guide/isik-medikation-v3?version=current)
  - [Terminplanung](https://simplifier.net/guide/isik-terminplanung-v3?version=current)
  - [Dokumentenaustausch](https://simplifier.net/guide/isik-dokumentenaustausch-v3?version=current)
  - [Vitalparameter und Körpermaße](https://simplifier.net/guide/isik-vitalparamater-v3?version=current)
- [Stufe 5](https://simplifier.net/isik-stufe-5/~guides)
  
As default, Tests will be executed for the Stufe 5 of the specification. To run tests for Stufe 3 instead, you need to explicitly select the tag `@Stufe3`.

### Release Notes
See [ReleaseNotes.md](./ReleaseNotes.md) for all information regarding the (newest) releases.

## Getting Started

### Prerequisites

To run the test suite you need the following components:

1. This test suite, which you can get either by cloning this repository or downloading the latest release.
2. An ISiK resource server (System under Test, SUT) that is compliant with one of the ISiK Stufe 3 or Stufe 5 specification modules.

Operating system requirements: cf. [Tiger Framework OS requirements](https://gematik.github.io/app-Tiger/Tiger-User-Manual.html#_requirements)

### Installation

#### Test environment
Configure the endpoint of the SUT using the configuration element `servers.fhirserver.source` in the `tiger-isik-stufe3.yaml` or `tiger-isik-stufe5.yaml`  configuration file. Example:

```yaml
servers:
#...   
  fhirserver:
    type: externalUrl
    source:
      - http://localhost:9032
```

See examples for different configuration options in the [tiger.yaml for ISIK Stufe 3](tiger-isik-stufe3.yaml), [tiger.yaml for ISIK Stufe 5](tiger-isik-stufe5.yaml) or check the official [Tiger documentation](https://gematik.github.io/app-Tiger/Tiger-User-Manual.html) 

#### Test resources

Each test case requires specific test resources to be present in the SUT. Create the following test resources in the SUT and put their corresponding IDs into the `testdata/MODULENAME.yaml` configuration file. 

Example:

The `@Patient-Read` test case requires a patient resource to be created in the SUT by the user before the test case can be run. As the SUT would usually assign a new unique ID to each created resource, e.g. `244b0d72-fe47-4294-be48-7763895287c5`, this newly assigned ID should be put into the `testdata/basis.yaml` configuration file. The precondition of the test case declares which configuration variable should be used - `patient-read-id` in this example:  

```yaml
...
patient-read-id: Patient-Read-Example
...
```

## Usage

### Using Maven

Edit the file `.env` to select the test cases you want to run (see [.env](./env) for examples). The default value is all tests from the ISIK basis module, for the specification level 3 (Stufe 3). 

Afterward call Maven to execute the tests:

```shell
mvn clean verify
```

#### Proxy settings

If using the tiger testsuite behind a proxy provide the proxy configuration at the following places:
1. Maven configuration ([official documentation](https://maven.apache.org/guides/mini/guide-proxies.html).
2. `tiger-isik-stufe3.yaml` or `tiger-isik-stufe5.yaml` (`forwardToProxy` configuration block)

### Using Docker

The testsuite is also distributed as a [docker image](https://hub.docker.com/r/gematik1/isik-testsuite). 
Make sure, that the docker environment has a connection to the System-Under-Test (configure [docker proxy settings](https://docs.docker.com/engine/cli/proxy/) if needed). 

To use the image, download and adjust the following files according to your test environment:
* `tiger-isik-stufe3.yaml` or `tiger-isik-stufe5.yaml`  (configuration of the test environment and test framework)
* `dc-testsuite.yml` (configuration of the docker container)
* `.env` (configuration of the test suite)
* `testdata/*.yaml` (configuration of test data per module)

Then start a docker container using docker-compose:

```shell
docker compose -f dc-testsuite.yml up
```

## Inspecting test results

Right after starting a test suite a browser window will open, which provides an overview of the testing progress. If using Tiger in Docker, please navigate to http://localhost:9010 manually. See [Tiger Workflow UI](https://gematik.github.io/app-Tiger/Tiger-User-Manual.html#_tiger_user_interfaces) for further information about the user interface. To run the test suite without the GUI, e.g. within a CI/CD pipeline, set the configuration element `lib.activateWorkflowUi` to `false` in the `tiger-isik-stufe3.yaml` or `tiger-isik-stufe5.yaml`  configuration file.

After the test suite finishes the archived test results can be found in `debug-report.zip` file (take notice of the `debug-report` suffix) or `target/site/serenity/index.html` in case of a Maven run.

> **Warning**
> Each test run deletes the reports of the previous run. Backup the created reports if you need them in the future.

## Submitting test results as part of the ISiK certification process
The artifact  `target/test-report.zip` is required to apply for the [ISiK conformance certificate](https://fachportal.gematik.de/informationen-fuer/isik/bestaetigungsverfahren-isik) (take notice of the `test-report` suffix). Please [get an account](https://fachportal.gematik.de/gematik-onlineshop/titus?ai%5Baction%5D=detail&ai%5Bcontroller%5D=Catalog&ai%5Bd_name%5D=111&ai%5Bd_pos%5D=2) to the TITUS platform and upload the report into the corresponding submission form.

> **Warning**
> Each test run deletes the reports of the previous run. Backup the created reports if you need them in the future.

## Contributing
If you want to contribute, please check our [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Copyright 2025 gematik GmbH

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

See the [LICENSE](./LICENSE) for the specific language governing permissions and limitations under the License.

## Additional Notes and Disclaimer from gematik GmbH

1. Copyright notice: Each published work result is accompanied by an explicit statement of the license conditions for use. These are regularly typical conditions in connection with open source or free software. Programs described/provided/linked here are free software, unless otherwise stated.
2. Permission notice: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions::
    1. The copyright notice (Item 1) and the permission notice (Item 2) shall be included in all copies or substantial portions of the Software.
    2. The software is provided "as is" without warranty of any kind, either express or implied, including, but not limited to, the warranties of fitness for a particular purpose, merchantability, and/or non-infringement. The authors or copyright holders shall not be liable in any manner whatsoever for any damages or other claims arising from, out of or in connection with the software or the use or other dealings with the software, whether in an action of contract, tort, or otherwise.
    3. The software is the result of research and development activities, therefore not necessarily quality assured and without the character of a liable product. For this reason, gematik does not provide any support or other user assistance (unless otherwise stated in individual cases and without justification of a legal obligation). Furthermore, there is no claim to further development and adaptation of the results to a more current state of the art.
3. Gematik may remove published results temporarily or permanently from the place of publication at any time without prior notice or justification.
4. Please note: Parts of this code may have been generated using AI-supported technology.’ Please take this into account, especially when troubleshooting, for security analyses and possible adjustments.

## Contact

Please open a GitHub issue or a ticket within [Anfrageportal ISiK](https://service.gematik.de/servicedesk/customer/portal/16) for any questions or feedback.

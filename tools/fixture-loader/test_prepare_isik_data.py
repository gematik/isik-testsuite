"""Exercise transactions, ID mapping and restart safety against a local FHIR test double."""
from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import io
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

import prepare_isik_data as loader


class FixtureImportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.bundle = self.root / "bundle.json"
        self.mapping = self.root / "mapping.json"
        self.config = self.root / "input"
        self.config.mkdir()
        self.output = self.root / "output"
        self.resources = {
            "Patient/source-patient": {"resourceType": "Patient", "id": "source-patient",
                                       "identifier": [{"system": "urn:example", "value": "source-patient"}],
                                       "generalPractitioner": [{"reference": "Practitioner/source-practitioner"}]},
            "Practitioner/source-practitioner": {"resourceType": "Practitioner", "id": "source-practitioner"},
            "Binary/source-document": {"resourceType": "Binary", "id": "source-document", "contentType": "text/plain", "data": "dGVzdA=="},
            "DocumentReference/source-reference": {"resourceType": "DocumentReference", "id": "source-reference",
                                                    "subject": {"reference": "Patient/source-patient"},
                                                    "content": [{"attachment": {"url": "Binary/source-document"}}]},
        }
        self.bundle.write_text(json.dumps({"resourceType": "Bundle", "type": "transaction", "entry": [
            {"fullUrl": "https://example.org/fhir/" + identity, "resource": resource,
             "request": {"method": "PUT", "url": identity}} for identity, resource in self.resources.items()]}))
        self.mapping.write_text(json.dumps({"schemaVersion": 1, "configuration": {"basis.yaml": {
            "patient-read-id": {"resource": "Patient/source-patient", "format": "id"},
            "practitioner-reference": {"resource": "Practitioner/source-practitioner", "format": "reference"}}},
            "resourceLinks": [{"resource": "DocumentReference/source-reference", "path": "/content/0/attachment/url",
                               "target": "Binary/source-document"}]}))
        (self.config / "basis.yaml").write_text('# Keep this comment\npatient-read-id: source-patient\npractitioner-reference: Practitioner/source-practitioner\nidentifier-value: source-patient\nidentifier-number: 000123\n')
        self.posts, self.requests, self.store, self.transaction = 0, [], {}, None
        self.drop_response = self.fail_read = self.redirect = self.bad_location = self.bad_reference = False
        self.metadata = {"resourceType": "CapabilityStatement", "fhirVersion": "4.0.1", "format": ["json"],
                         "rest": [{"mode": "server", "interaction": [{"code": "transaction"}], "resource": [
                             {"type": kind, "updateCreate": True, "interaction": [{"code": operation} for operation in ("read", "create", "update")]}
                             for kind in ("Patient", "Practitioner", "Binary", "DocumentReference")]}]}
        owner = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def respond(self, status, value):
                body = json.dumps(value).encode()
                self.send_response(status)
                self.send_header("Content-Type", "application/fhir+json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self):
                owner.requests.append(("GET", self.path))
                if owner.redirect:
                    self.send_response(302)
                    self.send_header("Location", owner.base + "/redirect-target")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                elif self.path == "/fhir/metadata":
                    self.respond(200, owner.metadata)
                elif owner.fail_read:
                    self.respond(500, {"resourceType": "OperationOutcome", "text": "Bearer private-test-token"})
                else:
                    self.respond(200, owner.store[self.path.removeprefix('/fhir/')])

            def do_POST(self):
                owner.requests.append(("POST", self.path))
                owner.posts += 1
                owner.transaction = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                assigned = {}
                for index, entry in enumerate(owner.transaction['entry']):
                    identity = (entry['resource']['resourceType'] + '/' + str(100 + index)
                                if entry['request']['method'] == 'POST' else entry['request']['url'])
                    assigned[entry['fullUrl']] = identity

                def resolve(value):
                    if isinstance(value, dict):
                        return {key: (assigned.get(child, child) if key in ('reference', 'url') and isinstance(child, str)
                                      else resolve(child)) for key, child in value.items()}
                    if isinstance(value, list):
                        return [resolve(item) for item in value]
                    return value

                response = []
                for entry in owner.transaction['entry']:
                    identity = assigned[entry['fullUrl']]
                    resource = resolve(entry['resource'])
                    resource['id'] = identity.split('/')[1]
                    if owner.bad_reference and resource['resourceType'] == 'DocumentReference':
                        resource['content'][0]['attachment']['url'] = entry['resource']['content'][0]['attachment']['url']
                    owner.store[identity] = resource
                    location = ('https://other.example/fhir/' if owner.bad_location else owner.base + '/') + identity + '/_history/1'
                    response.append({'response': {'status': '201 Created', 'location': location}})
                if owner.drop_response:
                    self.close_connection = True
                else:
                    self.respond(200, {'resourceType': 'Bundle', 'type': 'transaction-response', 'entry': response})

        self.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(thread.join)
        self.addCleanup(self.server.shutdown)
        self.base = 'http://127.0.0.1:' + str(self.server.server_port) + '/fhir'

    def invoke(self, *extra, real_dataset=False):
        args = ['--fhir-url', self.base, '--output', str(self.output)]
        if not real_dataset:
            args += ['--bundle', str(self.bundle), '--mapping', str(self.mapping), '--config-dir', str(self.config)]
        out, err = io.StringIO(), io.StringIO()
        with patch.dict(os.environ, {'FHIR_TOKEN': 'private-test-token'}), redirect_stdout(out), redirect_stderr(err):
            code = loader.main(args + list(extra))
        return code, out.getvalue() + err.getvalue()

    def manifest(self):
        return json.loads((self.output / 'manifest.json').read_text())

    def test_dry_run_is_offline_and_preserves_business_identifiers(self):
        code, text = self.invoke()
        self.assertEqual(code, 0, text)
        self.assertEqual(self.requests, [])
        transaction = json.loads((self.output / 'transaction.json').read_text())
        self.assertTrue(all(entry['request']['method'] == 'POST' and 'id' not in entry['resource'] for entry in transaction['entry']))
        patient = transaction['entry'][0]['resource']
        self.assertEqual(patient['identifier'][0]['value'], 'source-patient')
        self.assertEqual(patient['generalPractitioner'][0]['reference'], transaction['entry'][1]['fullUrl'])
        self.assertEqual(transaction['entry'][3]['resource']['content'][0]['attachment']['url'], transaction['entry'][2]['fullUrl'])
        self.assertFalse((self.output / 'configs').exists())
        self.assertEqual(self.manifest()['state'], 'planned')

    def test_server_assigned_ids_generate_yaml_and_reuse_does_not_create_duplicates(self):
        code, text = self.invoke('--execute')
        self.assertEqual(code, 0, text)
        config = (self.output / 'configs/basis.yaml').read_text()
        self.assertIn('patient-read-id: "100"', config)
        self.assertIn('practitioner-reference: "Practitioner/101"', config)
        self.assertIn('identifier-value: source-patient\nidentifier-number: 000123', config)
        self.assertIn('# Keep this comment', config)
        self.assertEqual(self.manifest()['state'], 'complete')
        self.assertEqual(self.invoke('--execute')[0], 0)
        self.assertEqual(self.posts, 1)
        self.assertIn('patient-read-id: source-patient', (self.config / 'basis.yaml').read_text())
        for path in self.output.rglob('*'):
            if path.is_file():
                self.assertNotIn('private-test-token', path.read_text())

    def test_preserve_mode_uses_put_and_keeps_identity(self):
        code, text = self.invoke('--id-mode', 'preserve', '--execute')
        self.assertEqual(code, 0, text)
        self.assertTrue(all(entry['request']['method'] == 'PUT' for entry in self.transaction['entry']))
        self.assertEqual(self.manifest()['idMap'], {identity: identity for identity in self.resources})

    def test_missing_capabilities_stop_before_post(self):
        self.metadata['rest'][0]['interaction'] = []
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertIn('transaction support', text)
        self.assertEqual(self.posts, 0)
        self.assertEqual(self.manifest()['state'], 'planned')

    def test_preserve_requires_update_create(self):
        self.metadata['rest'][0]['resource'][0]['updateCreate'] = False
        code, text = self.invoke('--execute', '--id-mode', 'preserve')
        self.assertEqual(code, 2)
        self.assertIn('updateCreate', text)
        self.assertEqual(self.posts, 0)

    def test_lost_response_blocks_resubmission(self):
        self.drop_response = True
        self.assertEqual(self.invoke('--execute')[0], 2)
        self.assertEqual(self.manifest()['state'], 'submitting')
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertIn('uncertain outcome', text)
        self.assertEqual(self.posts, 1)

    def test_readback_failure_can_resume_without_post_and_does_not_leak_token(self):
        self.fail_read = True
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertNotIn('private-test-token', text)
        self.assertEqual(self.manifest()['state'], 'imported')
        self.assertFalse((self.output / 'configs').exists())
        self.fail_read = False
        self.assertEqual(self.invoke('--execute')[0], 0)
        self.assertEqual(self.posts, 1)

    def test_unresolved_attachment_url_blocks_generated_configuration(self):
        self.bad_reference = True
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertEqual(self.manifest()['state'], 'imported')
        self.assertFalse((self.output / 'configs').exists())

    def test_redirect_is_not_followed(self):
        self.redirect = True
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertIn('HTTP 302', text)
        self.assertEqual(self.requests, [('GET', '/fhir/metadata')])

    def test_foreign_response_location_is_not_requested(self):
        self.bad_location = True
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertEqual(len(self.requests), 2)
        self.assertEqual(self.manifest()['state'], 'submitting')

    def test_changed_inputs_and_transaction_are_rejected(self):
        self.assertEqual(self.invoke()[0], 0)
        original = self.bundle.read_text()
        self.bundle.write_text(original + '\n')
        code, text = self.invoke('--execute')
        self.assertEqual(code, 2)
        self.assertIn('different inputs', text)
        self.bundle.write_text(original)
        path = self.output / 'transaction.json'
        transaction = json.loads(path.read_text())
        transaction['entry'].pop()
        path.write_text(json.dumps(transaction))
        self.assertEqual(self.invoke('--execute')[0], 2)
        self.assertEqual(self.requests, [])

    def test_mapping_drift_and_unknown_references_fail_offline(self):
        path = self.config / 'basis.yaml'
        text = path.read_text()
        path.write_text(text.replace('patient-read-id: source-patient', 'patient-read-id: changed'))
        self.assertEqual(self.invoke()[0], 2)
        path.write_text(text)
        bundle = json.loads(self.bundle.read_text())
        bundle['entry'][0]['resource']['generalPractitioner'][0]['reference'] = 'Practitioner/missing'
        self.bundle.write_text(json.dumps(bundle))
        self.assertEqual(self.invoke()[0], 2)
        self.assertEqual(self.requests, [])

    def test_actual_dataset_import_maps_all_130_resources_and_206_fields(self):
        bundle = json.loads((loader.ROOT / 'testdata/Stufe5/fixtures/bundle.json').read_text())
        types = sorted({entry['resource']['resourceType'] for entry in bundle['entry']})
        template = self.metadata['rest'][0]['resource'][0]
        self.metadata['rest'][0]['resource'] = [dict(deepcopy(template), type=kind) for kind in types]
        code, text = self.invoke('--execute', real_dataset=True)
        self.assertEqual(code, 0, text)
        manifest = self.manifest()
        self.assertEqual(len(manifest['idMap']), 130)
        self.assertEqual(manifest['configurationFields'], 206)
        self.assertEqual(len(list((self.output / 'configs').glob('*.yaml'))), 8)
        mapping = json.loads((loader.ROOT / 'testdata/Stufe5/fixtures/config-mapping.json').read_text())
        for filename, fields in mapping['configuration'].items():
            values = loader.yaml_lines((self.output / 'configs' / filename).read_text())
            for key, field in fields.items():
                identity = manifest['idMap'][field['resource']]
                self.assertEqual(values[key][1], identity if field['format'] == 'reference' else identity.split('/')[1])


if __name__ == '__main__':
    unittest.main()

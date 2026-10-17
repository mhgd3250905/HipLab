"""Copy-ready import checks preserve codec quality and per-drill provenance."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location('sync_copy_ready', Path(__file__).resolve().parents[1]/'sync_drill_media.py')
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


def put(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding='utf-8')


def fixture(root):
    sid = 'test-drill'
    source_path = root/'source/result.json'
    source = {'id': sid, 'frames': 2, 'fps': 30, 'inherited_source_qa_status': 'pass',
        'inherited_source_qa': {'pass': True}, 'composition_qa_pass': True,
        'video_validation': {'full_cpu_decode': True}, 'outputs': {'alpha_0': {'sha256': 'frame0'}, 'alpha_1': {'sha256': 'frame1'}}}
    put(source_path, source)
    binding = hashlib.sha256(json.dumps(['frame0', 'frame1'], separators=(',', ':')).encode()).hexdigest()
    selected = root/'selection.json'
    put(selected, {'app_ids': [sid], 'items': [{'id': sid, 'batch': 'revision-r3',
        'source_commit': 'actual-source-commit', 'result_sha256': sync.file_sha256(source_path), 'alpha_binding_sha256': binding}]})
    video = root/(sid+'.mp4')
    video.write_bytes(b'original encoded app-ready bytes')
    recipe = {'size': 1080, 'crf': 18, 'background': '#101013'}
    row = {'id': sid, 'video': video.name, 'sha256': sync.file_sha256(video), 'frames': 2, 'fps': 30,
        'pass': True, 'full_cpu_decode': True, 'inherited_source_qa_status': 'pass',
        'composition_qa_pass': True, 'recipe': recipe, 'poster_time_seconds': 0,
        'provenance': {'source_batch': 'revision-r3', 'source_commit': 'actual-source-commit',
            'source_result': str(source_path), 'source_result_sha256': sync.file_sha256(source_path),
            'source_alpha_binding_sha256': binding}}
    put(root/'metrics'/(sid+'.json'), row)
    manifest = {'kind': 'hiplab-android-exact-alpha', 'all_complete': True, 'recipe': recipe,
        'selection': str(selected), 'selection_sha256': sync.file_sha256(selected), 'items': {sid: row}}
    put(root/'delivery.json', manifest)
    probe = {'streams': [{'codec_type': 'video', 'codec_name': 'h264', 'pix_fmt': 'yuv420p',
        'width': 1080, 'height': 1080, 'r_frame_rate': '30/1', 'avg_frame_rate': '30/1', 'nb_read_frames': '2'}],
        'format': {'duration': str(2/30)}}
    return sid, row, probe


class CopyReadyTests(unittest.TestCase):
    def test_valid_import_binds_source_and_copies_identical_bytes_without_encode(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sid, row, probe = fixture(root)
            with patch.object(sync.subprocess, 'check_output', return_value=json.dumps(probe).encode()):
                ready = sync.ready_deliveries(str(root), 1080, 18)
            target = root/'app.mp4'
            with patch.object(sync, 'encode', side_effect=AssertionError('No second encode allowed')):
                sync.copy_ready_video(str(root/row['video']), str(target), row['sha256'])
            self.assertEqual(target.read_bytes(), (root/row['video']).read_bytes())
            meta = sync.ready_metadata({}, ready[sid])
            self.assertEqual(meta['source_batch'], 'revision-r3')
            self.assertEqual(meta['source_commit'], 'actual-source-commit')
            self.assertTrue(meta['copy_ready'])

    def test_444_wrong_fps_audio_and_truncated_frames_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _, _, probe = fixture(root)
            for key, value in (('pix_fmt', 'yuv444p'), ('r_frame_rate', '15/1'), ('nb_read_frames', '1')):
                bad = json.loads(json.dumps(probe))
                bad['streams'][0][key] = value
                with self.subTest(key=key), patch.object(sync.subprocess, 'check_output', return_value=json.dumps(bad).encode()):
                    with self.assertRaisesRegex(ValueError, 'codec/size/frame timing'):
                        sync.ready_deliveries(str(root), 1080, 18)
            probe['streams'].append({'codec_type': 'audio'})
            with patch.object(sync.subprocess, 'check_output', return_value=json.dumps(probe).encode()):
                with self.assertRaisesRegex(ValueError, 'no audio'):
                    sync.ready_deliveries(str(root), 1080, 18)

    def test_changed_selection_or_video_sha_is_rejected_before_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _, row, _ = fixture(root)
            (root/row['video']).write_bytes(b'modified')
            with self.assertRaisesRegex(ValueError, 'video SHA mismatch'):
                sync.ready_deliveries(str(root), 1080, 18)
            fixture(root)
            (root/'selection.json').write_text('{}')
            with self.assertRaisesRegex(ValueError, 'selection changed'):
                sync.ready_deliveries(str(root), 1080, 18)

    def test_failed_copy_preserves_existing_app_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, target = root/'source.mp4', root/'app.mp4'
            source.write_bytes(b'new source')
            target.write_bytes(b'old installed bytes')
            with self.assertRaises(ValueError):
                sync.copy_ready_video(str(source), str(target), 'wrong-sha')
            self.assertEqual(target.read_bytes(), b'old installed bytes')
            self.assertFalse(Path(str(target)+'.copy-ready.tmp').exists())


if __name__ == '__main__':
    unittest.main()

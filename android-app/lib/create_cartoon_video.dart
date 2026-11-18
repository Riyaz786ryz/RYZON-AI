import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ai_creative_studio.dart';

class CreateCartoonVideoScreen extends StatefulWidget {
  const CreateCartoonVideoScreen({super.key});

  @override
  State<CreateCartoonVideoScreen> createState() => _CreateCartoonVideoScreenState();
}

class _CreateCartoonVideoScreenState extends State<CreateCartoonVideoScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _narration = TextEditingController();
  final List<Uint8List> _images = [];
  final List<String> _mimeTypes = [];
  int _secondsPerScene = 3;
  String _language = 'Tamil';
  String _voice = 'Kore';
  bool _busy = false;
  String? _message;
  String? _videoPath;

  Future<void> _pickScenes() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 65, maxWidth: 1280);
      if (files.isEmpty || !mounted) return;
      final remaining = 6 - _images.length;
      if (remaining <= 0) {
        setState(() => _message = 'You can add up to 6 scenes.');
        return;
      }
      final selected = files.take(remaining).toList();
      final bytes = <Uint8List>[];
      final types = <String>[];
      for (final file in selected) {
        final data = await file.readAsBytes();
        if (data.length > 4 * 1024 * 1024) {
          throw Exception('One image is larger than 4 MB. Please choose smaller images.');
        }
        final lower = file.name.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        bytes.add(data);
        types.add(mime);
      }
      if (!mounted) return;
      setState(() {
        _images.addAll(bytes);
        _mimeTypes.addAll(types);
        _message = null;
        _videoPath = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _createVideo() async {
    if (_images.isEmpty) {
      setState(() => _message = 'Add at least one scene image first.');
      return;
    }
    setState(() { _busy = true; _message = null; _videoPath = null; });
    try {
      Uint8List? audioBytes;
      String? audioMimeType;
      final words = _narration.text.trim();
      if (words.isNotEmpty) {
        final speech = await RyzonAiApi.generateSpeech(
          text: words,
          language: _language,
          voiceName: _voice,
        );
        audioBytes = speech.bytes;
        audioMimeType = speech.mimeType;
      }
      final video = await RyzonAiApi.renderSlideshowVideo(
        sceneImages: _images,
        mimeTypes: _mimeTypes,
        secondsPerImage: _secondsPerScene,
        audioBytes: audioBytes,
        audioMimeType: audioMimeType,
      );
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ryzone_cartoon_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(video, flush: true);
      if (mounted) setState(() {
        _videoPath = file.path;
        _message = 'Your MP4 video is ready and saved on this device.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareVideo() async {
    final path = _videoPath;
    if (path == null) return;
    await Share.shareXFiles([XFile(path, mimeType: 'video/mp4')], text: 'Created with RYZONE');
  }

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = RyzonAiApi.baseUrl.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Cartoon Video')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF49317E), Color(0xFF242044)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.movie_creation_outlined, size: 32, color: Color(0xFFD9CCFF)),
                  SizedBox(height: 10),
                  Text('Build a short scene video', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Choose up to 6 scene images. RYZONE can combine them into a vertical MP4 and optionally add AI narration.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickScenes,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add scene images (${_images.length}/6)'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_images[index], width: 86, height: 104, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          onPressed: _busy ? null : () => setState(() {
                            _images.removeAt(index);
                            _mimeTypes.removeAt(index);
                            _videoPath = null;
                          }),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _secondsPerScene,
              decoration: const InputDecoration(labelText: 'Duration per scene', border: OutlineInputBorder()),
              items: [1, 2, 3, 4, 5].map((v) => DropdownMenuItem(value: v, child: Text('$v seconds'))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _secondsPerScene = v ?? 3),
            ),
            const SizedBox(height: 16),
            const Text('Optional AI narration', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _narration,
              enabled: !_busy,
              minLines: 3,
              maxLines: 5,
              maxLength: 3000,
              decoration: const InputDecoration(
                hintText: 'Type a short narration or dialogue. Leave empty for a silent video.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(labelText: 'Narration language', border: OutlineInputBorder()),
              items: ['Tamil', 'English', 'Hindi', 'Urdu'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _language = v ?? 'Tamil'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _voice,
              decoration: const InputDecoration(labelText: 'AI voice', border: OutlineInputBorder()),
              items: const ['Kore', 'Puck', 'Charon', 'Aoede', 'Fenrir', 'Leda', 'Orus', 'Zephyr'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _voice = v ?? 'Kore'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _createVideo,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.movie_filter_outlined),
              label: Text(_busy ? 'Creating video…' : 'Create MP4 Video'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
            if (_videoPath != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _shareVideo,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share video'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(_message!, style: TextStyle(color: _videoPath != null ? Colors.greenAccent : Colors.orangeAccent)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                    size: 17, color: connected ? Colors.greenAccent : Colors.orangeAccent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    connected
                        ? 'Backend address configured. Sign in and valid server AI credentials are required.'
                        : 'Backend is not deployed or connected yet. This screen will work after secure backend setup.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'This version combines still images into a slideshow MP4. Character movement, lip-sync and automatic scene-image generation are still being developed.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

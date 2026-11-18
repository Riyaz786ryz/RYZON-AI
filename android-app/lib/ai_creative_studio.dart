import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

/// Configure with --dart-define=RYZONE_API_BASE_URL=https://your-deployed-backend
/// Provider API keys must remain on the server and never in the APK.
class RyzonAiApi {
  static const String baseUrl = String.fromEnvironment('RYZONE_API_BASE_URL');

  static Future<Uint8List> generatePhotoToCartoon({
    required Uint8List imageBytes,
    required String mimeType,
    required String style,
  }) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('AI backend is not connected yet. The server must be deployed and configured first.');
    }
    if (imageBytes.isEmpty || imageBytes.length > 12 * 1024 * 1024) {
      throw Exception('Please choose an image smaller than 12 MB.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get your secure sign-in token. Please sign in again.');
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse(root + '/v1/media/photo-to-cartoon'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer ' + token},
      body: jsonEncode({
        'mimeType': mimeType,
        'imageBase64': base64Encode(imageBytes),
        'style': style,
      }),
    ).timeout(const Duration(minutes: 4));
    Map<String, dynamic> payload;
    try { payload = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('The AI server returned an unreadable response.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['error']?.toString() ?? 'Photo-to-Cartoon failed (' + response.statusCode.toString() + ').');
    }
    final encoded = payload['imageBase64']?.toString() ?? '';
    if (encoded.isEmpty) throw Exception('The AI server returned no cartoon image.');
    try { return base64Decode(encoded); }
    catch (_) { throw Exception('The generated image could not be decoded.'); }
  }

  static Future<GeneratedSpeechAudio> generateSpeech({
    required String text,
    required String language,
    required String voiceName,
  }) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('AI backend is not connected yet. Deploy and configure the backend first.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get your secure sign-in token. Please sign in again.');
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse('$root/v1/media/text-to-speech'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer ' + token},
      body: jsonEncode({'text': text, 'language': language, 'voiceName': voiceName}),
    ).timeout(const Duration(minutes: 4));
    Map<String, dynamic> payload;
    try { payload = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('The AI voice server returned an unreadable response.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['error']?.toString() ?? 'AI voice generation failed (' + response.statusCode.toString() + ').');
    }
    final encoded = payload['audioBase64']?.toString() ?? '';
    if (encoded.isEmpty) throw Exception('The AI voice server returned no audio.');
    try {
      return GeneratedSpeechAudio(bytes: base64Decode(encoded), mimeType: payload['mimeType']?.toString() ?? 'audio/wav');
    } catch (_) { throw Exception('The generated audio could not be decoded.'); }
  }

  static Future<Uint8List> renderSlideshowVideo({
    required List<Uint8List> sceneImages,
    required List<String> mimeTypes,
    int secondsPerImage = 3,
    Uint8List? audioBytes,
    String? audioMimeType,
  }) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('AI backend is not connected yet. Deploy and configure the backend first.');
    }
    if (sceneImages.isEmpty || sceneImages.length > 6 || sceneImages.length != mimeTypes.length) {
      throw Exception('Choose between 1 and 6 scene images.');
    }
    if (sceneImages.any((image) => image.isEmpty || image.length > 4 * 1024 * 1024)) {
      throw Exception('Each scene image must be 4 MB or smaller.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get your secure sign-in token. Please sign in again.');
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse('$root/v1/media/render-video'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer ' + token},
      body: jsonEncode({
        'images': List.generate(sceneImages.length, (index) => {
          'mimeType': mimeTypes[index],
          'imageBase64': base64Encode(sceneImages[index]),
        }),
        'secondsPerImage': secondsPerImage,
        if (audioBytes != null && audioBytes.isNotEmpty) 'audioBase64': base64Encode(audioBytes),
        if (audioBytes != null && audioBytes.isNotEmpty) 'audioMimeType': audioMimeType ?? 'audio/wav',
      }),
    ).timeout(const Duration(minutes: 3));
    Map<String, dynamic> payload;
    try { payload = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('The video renderer returned an unreadable response.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['error']?.toString() ?? 'Video rendering failed (${response.statusCode}).');
    }
    final encoded = payload['videoBase64']?.toString() ?? '';
    if (encoded.isEmpty) throw Exception('The video renderer returned no MP4 file.');
    try { return base64Decode(encoded); }
    catch (_) { throw Exception('The rendered MP4 could not be decoded.'); }
  }

  static Future<String> generate({required String task, required Map<String, dynamic> input}) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('Backend not connected. Deploy the cloud backend and set RYZONE_API_BASE_URL when building the app.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get your secure sign-in token. Please sign in again.');
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse('$root/v1/ai/$task'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer $token'},
      body: jsonEncode(input),
    ).timeout(const Duration(seconds: 55));
    Map<String, dynamic> payload;
    try { payload = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('The AI server returned an unreadable response.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['error']?.toString() ?? 'AI request failed (${response.statusCode}).');
    }
    final result = payload['result']?.toString().trim() ?? '';
    if (result.isEmpty) throw Exception('The AI server returned an empty result.');
    return result;
  }
}

class AiCreativeStudioScreen extends StatefulWidget {
  const AiCreativeStudioScreen({super.key});
  @override
  State<AiCreativeStudioScreen> createState() => _AiCreativeStudioScreenState();
}

class _AiCreativeStudioScreenState extends State<AiCreativeStudioScreen> {
  final _prompt = TextEditingController();
  final _characters = TextEditingController();
  String _task = 'story';
  String _language = 'Tamil';
  String _genre = 'Adventure';
  String _tone = 'Funny';
  int _sceneCount = 5;
  bool _busy = false;
  String? _result;
  String? _error;

  @override
  void dispose() { _prompt.dispose(); _characters.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.length < 3) { setState(() => _error = 'Please enter at least 3 characters.'); return; }
    setState(() { _busy = true; _error = null; _result = null; });
    try {
      late final Map<String, dynamic> input;
      if (_task == 'dialogue') {
        input = {'scene': text, 'characters': _characters.text.trim(), 'language': _language, 'tone': _tone};
      } else if (_task == 'scenes') {
        input = {'story': text, 'language': _language, 'sceneCount': _sceneCount};
      } else {
        input = {'idea': text, 'language': _language, 'genre': _genre, 'audience': 'family'};
      }
      final result = await RyzonAiApi.generate(task: _task, input: input);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final connected = RyzonAiApi.baseUrl.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Story & Script Studio')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF49317E), Color(0xFF242044)]), borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome, size: 32, color: Color(0xFFD9CCFF)), SizedBox(height: 10),
          Text('Build your cartoon story', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), SizedBox(height: 6),
          Text('Create a story, character dialogue or scene-by-scene storyboard. These are text outputs; animated video rendering is a separate step.'),
        ])),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _task, decoration: const InputDecoration(labelText: 'What do you want to create?', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'story', child: Text('AI Cartoon Story')), DropdownMenuItem(value: 'dialogue', child: Text('Character Dialogue')), DropdownMenuItem(value: 'scenes', child: Text('Storyboard / Scenes')),
        ], onChanged: _busy ? null : (v) => setState(() { _task = v ?? 'story'; _result = null; _error = null; })),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _language, decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'Tamil', child: Text('Tamil')), DropdownMenuItem(value: 'English', child: Text('English')), DropdownMenuItem(value: 'Hindi', child: Text('Hindi')), DropdownMenuItem(value: 'Urdu', child: Text('Urdu')),
        ], onChanged: _busy ? null : (v) => setState(() => _language = v ?? 'Tamil')),
        if (_task == 'story') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _genre, decoration: const InputDecoration(labelText: 'Story type', border: OutlineInputBorder()), items: const [
            DropdownMenuItem(value: 'Adventure', child: Text('Adventure')), DropdownMenuItem(value: 'Comedy', child: Text('Comedy')), DropdownMenuItem(value: 'Friendship', child: Text('Friendship')), DropdownMenuItem(value: 'Fantasy', child: Text('Fantasy')), DropdownMenuItem(value: 'Family', child: Text('Family')),
          ], onChanged: _busy ? null : (v) => setState(() => _genre = v ?? 'Adventure')),
        ],
        if (_task == 'dialogue') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _tone, decoration: const InputDecoration(labelText: 'Dialogue style', border: OutlineInputBorder()), items: const [
            DropdownMenuItem(value: 'Funny', child: Text('Funny')), DropdownMenuItem(value: 'Emotional', child: Text('Emotional')), DropdownMenuItem(value: 'Action', child: Text('Action')), DropdownMenuItem(value: 'Friendly', child: Text('Friendly')),
          ], onChanged: _busy ? null : (v) => setState(() => _tone = v ?? 'Funny')),
          const SizedBox(height: 12),
          TextField(controller: _characters, enabled: !_busy, decoration: const InputDecoration(labelText: 'Character names (optional)', border: OutlineInputBorder(), hintText: 'Raja, Meena, Puppy')),
        ],
        if (_task == 'scenes') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(value: _sceneCount, decoration: const InputDecoration(labelText: 'Number of scenes', border: OutlineInputBorder()), items: List.generate(10, (i) => DropdownMenuItem(value: i + 3, child: Text('${i + 3} scenes'))), onChanged: _busy ? null : (v) => setState(() => _sceneCount = v ?? 5)),
        ],
        const SizedBox(height: 12),
        TextField(controller: _prompt, enabled: !_busy, minLines: 4, maxLines: 8, maxLength: _task == 'scenes' ? 5000 : 2000, decoration: InputDecoration(labelText: _task == 'scenes' ? 'Your story' : _task == 'dialogue' ? 'Scene description' : 'Your cartoon idea', hintText: _task == 'dialogue' ? 'Describe the scene and what happens…' : _task == 'scenes' ? 'Paste your story here…' : 'Two friends find a magical puppy in their village…', border: const OutlineInputBorder(), alignLabelWithHint: true)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _generate, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(_busy ? 'Creating…' : _task == 'dialogue' ? 'Write Character Dialogue' : _task == 'scenes' ? 'Create Storyboard' : 'Write Cartoon Story'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15))),
        const SizedBox(height: 10),
        Row(children: [Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 17, color: connected ? Colors.greenAccent : Colors.orangeAccent), const SizedBox(width: 7), Expanded(child: Text(connected ? 'Backend address configured. Google sign-in is required.' : 'Backend not deployed / connected yet. Configure its address after deployment.', style: const TextStyle(color: Colors.white70, fontSize: 12)))]),
        if (_error != null) ...[const SizedBox(height: 14), Text(_error!, style: const TextStyle(color: Colors.orangeAccent))],
        if (_result != null) ...[const SizedBox(height: 20), const Text('AI RESULT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)), const SizedBox(height: 8), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1B26), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF49435D))), child: SelectableText(_result!, style: const TextStyle(height: 1.5)))],
      ])),
    );
  }
}

class GeneratedSpeechAudio {
  const GeneratedSpeechAudio({required this.bytes, required this.mimeType});
  final Uint8List bytes;
  final String mimeType;
}

class AiVoiceStudioScreen extends StatefulWidget {
  const AiVoiceStudioScreen({super.key});
  @override
  State<AiVoiceStudioScreen> createState() => _AiVoiceStudioScreenState();
}

class _AiVoiceStudioScreenState extends State<AiVoiceStudioScreen> {
  final _text = TextEditingController();
  final _player = AudioPlayer();
  String _language = 'Tamil';
  String _voice = 'Kore';
  bool _busy = false;
  bool _playing = false;
  String? _error;
  GeneratedSpeechAudio? _audio;

  Uint8List _wavFromPcm(Uint8List pcm) {
    const sampleRate = 24000;
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final header = ByteData(44);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }
    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  Future<void> _generate() async {
    final value = _text.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter the words you want the AI voice to speak.');
      return;
    }
    setState(() { _busy = true; _error = null; _audio = null; _playing = false; });
    await _player.stop();
    try {
      final result = await RyzonAiApi.generateSpeech(
        text: value, language: _language, voiceName: _voice,
      );
      if (mounted) setState(() => _audio = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play() async {
    final audio = _audio;
    if (audio == null) return;
    try {
      final mime = audio.mimeType.toLowerCase();
      final isPcm = mime.contains('l16') || mime.contains('pcm');
      final bytes = isPcm ? _wavFromPcm(audio.bytes) : audio.bytes;
      await _player.play(BytesSource(bytes, mimeType: isPcm ? 'audio/wav' : audio.mimeType));
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not play this audio: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = RyzonAiApi.baseUrl.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Voice Studio')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF49317E), Color(0xFF242044)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.record_voice_over, size: 32, color: Color(0xFFD9CCFF)),
              SizedBox(height: 10),
              Text('Turn your words into speech', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Generate spoken audio in your selected language and listen inside RYZONE.'),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            enabled: !_busy,
            minLines: 4,
            maxLines: 7,
            maxLength: 3000,
            decoration: const InputDecoration(
              labelText: 'Text for the AI voice',
              hintText: 'Type a story line or dialogue here…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(labelText: 'Speech language', border: OutlineInputBorder()),
            items: const ['Tamil', 'English', 'Hindi', 'Urdu'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: _busy ? null : (v) => setState(() => _language = v ?? 'Tamil'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _voice,
            decoration: const InputDecoration(labelText: 'AI voice', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Kore', child: Text('Kore')),
              DropdownMenuItem(value: 'Puck', child: Text('Puck')),
              DropdownMenuItem(value: 'Charon', child: Text('Charon')),
              DropdownMenuItem(value: 'Aoede', child: Text('Aoede')),
              DropdownMenuItem(value: 'Fenrir', child: Text('Fenrir')),
              DropdownMenuItem(value: 'Leda', child: Text('Leda')),
              DropdownMenuItem(value: 'Orus', child: Text('Orus')),
              DropdownMenuItem(value: 'Zephyr', child: Text('Zephyr')),
            ],
            onChanged: _busy ? null : (v) => setState(() => _voice = v ?? 'Kore'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Generating voice…' : 'Generate AI Voice'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
          if (_audio != null) ...[
            const SizedBox(height: 14),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(Icons.audio_file, color: Color(0xFFD9CCFF), size: 30),
                const SizedBox(width: 12),
                const Expanded(child: Text('Your AI voice is ready', style: TextStyle(fontWeight: FontWeight.bold))),
                IconButton(
                  tooltip: _playing ? 'Stop audio' : 'Play audio',
                  onPressed: () async {
                    if (_playing) {
                      await _player.stop();
                      if (mounted) setState(() => _playing = false);
                    } else {
                      await _play();
                    }
                  },
                  icon: Icon(_playing ? Icons.stop_circle_outlined : Icons.play_circle_fill, size: 34),
                ),
              ]),
            )),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 17,
              color: connected ? Colors.greenAccent : Colors.orangeAccent),
            const SizedBox(width: 7),
            Expanded(child: Text(
              connected ? 'Backend address is configured. A valid Gemini API key is still required on the server.' : 'AI voice is not live yet: deploy the backend and configure its secure API key and app address.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            )),
          ]),
        ],
      )),
    );
  }
}

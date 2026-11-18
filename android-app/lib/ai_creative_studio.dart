import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Configure with --dart-define=RYZON_API_BASE_URL=https://your-deployed-backend
/// Provider API keys must remain on the server and never in the APK.
class RyzonAiApi {
  static const String baseUrl = String.fromEnvironment('RYZON_API_BASE_URL');

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

  static Future<Uint8List> generateSpeech({
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
    try { return base64Decode(encoded); }
    catch (_) { throw Exception('The generated audio could not be decoded.'); }
  }

  static Future<String> generate({required String task, required Map<String, dynamic> input}) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('Backend not connected. Deploy the cloud backend and set RYZON_API_BASE_URL when building the app.');
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
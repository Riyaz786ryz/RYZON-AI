import 'package:flutter/material.dart';

import 'ai_creative_studio.dart';

class CreateCartoonVideoScreen extends StatefulWidget {
  const CreateCartoonVideoScreen({super.key});

  @override
  State<CreateCartoonVideoScreen> createState() => _CreateCartoonVideoScreenState();
}

class _CreateCartoonVideoScreenState extends State<CreateCartoonVideoScreen> {
  final TextEditingController _story = TextEditingController();
  String _language = 'Tamil';
  int _sceneCount = 5;
  bool _busy = false;
  String? _storyboard;
  String? _error;

  Future<void> _createStoryPlan() async {
    final story = _story.text.trim();
    if (story.length < 10) {
      setState(() => _error = 'Please tell your story in at least 10 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _storyboard = null;
    });

    try {
      final result = await RyzonAiApi.generate(
        task: 'scenes',
        input: {
          'story': story,
          'language': _language,
          'sceneCount': _sceneCount,
        },
      );
      if (mounted) setState(() => _storyboard = result);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _story.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendConnected = RyzonAiApi.baseUrl.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Cartoon Video')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF49317E), Color(0xFF242044)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.movie_creation_outlined, size: 34, color: Color(0xFFD9CCFF)),
                  SizedBox(height: 10),
                  Text(
                    'One story. A complete cartoon movie.',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Just tell RYZONE your story. The AI movie workflow will prepare characters, scenes, dialogue, camera directions, voices and music for you.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _story,
              enabled: !_busy,
              minLines: 5,
              maxLines: 9,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'Your story',
                hintText: 'Example: A little boy and a lion become friends and go on an adventure in the forest...',
                helperText: 'You do not need to write prompts or character dialogues.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(
                labelText: 'Dialogue language',
                border: OutlineInputBorder(),
              ),
              items: const ['Tamil', 'English', 'Hindi', 'Urdu']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: _busy ? null : (value) => setState(() => _language = value ?? 'Tamil'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _sceneCount,
              decoration: const InputDecoration(
                labelText: 'Story length',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 3, child: Text('Short – 3 scenes')),
                DropdownMenuItem(value: 5, child: Text('Normal – 5 scenes')),
                DropdownMenuItem(value: 8, child: Text('Long – 8 scenes')),
                DropdownMenuItem(value: 10, child: Text('Movie – 10 scenes')),
              ],
              onChanged: _busy ? null : (value) => setState(() => _sceneCount = value ?? 5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _createStoryPlan,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_busy ? 'Preparing your story…' : 'Prepare My Cartoon Movie'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
            ],
            if (_storyboard != null) ...[
              const SizedBox(height: 22),
              const Text(
                'YOUR STORYBOARD',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF49435D)),
                ),
                child: SelectableText(_storyboard!, style: const TextStyle(height: 1.5)),
              ),
              const SizedBox(height: 20),
              const Text(
                'DEMO PREVIEW',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 9),
              Center(
                child: Container(
                  width: 230,
                  height: 132,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242231),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF8B78C8)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.movie_outlined, size: 42, color: Colors.white24),
                      Positioned.fill(
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              color: Colors.black.withValues(alpha: 0.72),
                              child: const Text(
                                'RYZONE DEMO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 7,
                        right: 9,
                        child: Text(
                          '5–10 SEC PREVIEW',
                          style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'The protected, small-screen demo player will appear here when the AI video-rendering service is connected. Demo downloads and sharing will stay disabled.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Full video unlock – credits required'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 7),
              const Text(
                'Credits are not charged in this planning stage. Full-video generation and watermark-free export will be enabled only after secure credit reservation, payment checks and video rendering are connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  backendConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 17,
                  color: backendConnected ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    backendConnected
                        ? 'Story planning uses the configured secure backend. Video preview and final rendering are not connected yet.'
                        : 'Secure AI backend is not connected yet. Storyboard generation will work after backend deployment.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

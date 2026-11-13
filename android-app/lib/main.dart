import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const RyzonAiApp());

class RyzonAiApp extends StatelessWidget {
  const RyzonAiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RYZON AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF101018),
          cardTheme: CardThemeData(
            color: const Color(0xFF1C1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF343242)),
            ),
          ),
        ),
        home: const HomeScreen(),
      );
}

class StudioFeature {
  const StudioFeature(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

const features = <StudioFeature>[
  StudioFeature('Photo to Cartoon', 'Upload photos and find people', Icons.face_retouching_natural),
  StudioFeature('AI Movie Maker', 'Build a story scene by scene', Icons.movie_creation_outlined),
  StudioFeature('Video to Cartoon', 'Cartoonize an existing video', Icons.video_library_outlined),
  StudioFeature('Live Cartoon Camera', 'Preview cartoon camera effects', Icons.camera_alt_outlined),
  StudioFeature('Character Studio', 'Create and manage characters', Icons.person_outline),
  StudioFeature('Voice Studio', 'Plan character voices and dialogue', Icons.record_voice_over),
  StudioFeature('Music Studio', 'Plan music and sound effects', Icons.music_note),
  StudioFeature('AI Movie Director', 'Plan shots, scenes and emotions', Icons.theaters_outlined),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('RYZON AI', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Projects',
              onPressed: () => _showMessage(context, 'My Projects will be added in a later step.'),
              icon: const Icon(Icons.folder_open_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF45317D), Color(0xFF242044)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR AI CARTOON STUDIO',
                            style: TextStyle(letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD9CCFF))),
                        SizedBox(height: 10),
                        Text('Bring your stories to life.',
                            style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Create characters, plan scenes and build your own cartoon movies.'),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text('Creative Studio', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.02,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final feature = features[index];
                      return _FeatureCard(
                        feature: feature,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => feature.title == 'Photo to Cartoon'
                                ? const PhotoCharacterScreen()
                                : FeatureScreen(feature: feature),
                          ),
                        ),
                      );
                    },
                    childCount: features.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Text(
                    'Photo selection and on-device face detection are the first working modules. AI generation services are not connected yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});
  final StudioFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(feature.icon, size: 30, color: const Color(0xFFC8B6FF)),
                const Spacer(),
                Text(feature.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                Text(feature.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
}

class PhotoCharacterScreen extends StatefulWidget {
  const PhotoCharacterScreen({super.key});

  @override
  State<PhotoCharacterScreen> createState() => _PhotoCharacterScreenState();
}

class _PhotoCharacterScreenState extends State<PhotoCharacterScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
      enableTracking: true,
    ),
  );

  XFile? _photo;
  List<Face> _faces = [];
  final Set<int> _selected = {};
  bool _busy = false;
  String? _error;

  Future<void> _choosePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;

      setState(() {
        _photo = image;
        _faces = [];
        _selected.clear();
        _error = null;
        _busy = true;
      });

      final detected = await _detector.processImage(
        InputImage.fromFilePath(image.path),
      );
      if (!mounted) return;
      setState(() {
        _faces = detected;
        _selected.addAll(List<int>.generate(detected.length, (i) => i));
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not read this photo. Please choose another image.';
      });
    }
  }

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Photo to Cartoon')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Choose a photo',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Upload a photo containing one or more people. RYZON AI scans it on this device and counts the faces it can detect.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _busy ? null : _choosePhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(_photo!.path),
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 180,
                      child: Center(child: Text('Photo preview unavailable')),
                    ),
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 22),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),
                const Center(child: Text('Detecting faces...')),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
              ],
              if (_photo != null && !_busy && _error == null) ...[
                const SizedBox(height: 22),
                Text(
                  '\${_faces.length} face(s) detected',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text('Select the people you want to turn into cartoon characters.',
                    style: TextStyle(color: Colors.white70)),
                if (_faces.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'No clear faces were found. Try a brighter, front-facing photo.',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ...List<Widget>.generate(_faces.length, (index) {
                  final box = _faces[index].boundingBox;
                  return Card(
                    child: CheckboxListTile(
                      value: _selected.contains(index),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(index);
                        } else {
                          _selected.remove(index);
                        }
                      }),
                      title: Text('Person \${index + 1}'),
                      subtitle: Text('Face area: \${box.width.round()} × \${box.height.round()} px'),
                      secondary: const CircleAvatar(child: Icon(Icons.person_outline)),
                    ),
                  );
                }),
                if (_faces.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : _confirmCharacters,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Confirm \${_selected.length} character(s)'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 18),
              const Text(
                'Privacy: this module performs face detection on the device. It does not upload the photo to an AI server.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );

  void _confirmCharacters() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Characters selected'),
        content: Text(
          '\${_selected.length} person(s) selected. Cartoon character profile generation will be added in the next step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key, required this.feature});
  final StudioFeature feature;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(feature.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(feature.icon, size: 56, color: const Color(0xFFC8B6FF)),
                const SizedBox(height: 18),
                Text(feature.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                  'This studio module is part of the RYZON AI roadmap. Its working AI features and service connections will be built in the next development steps.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

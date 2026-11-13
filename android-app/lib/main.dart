import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';

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
  StudioFeature('Make Cartoon Reels', 'Create vertical Shorts and Reels', Icons.video_camera_back_outlined),
  StudioFeature('Video / Movie Splitter', 'Split videos into 30s or 60s parts', Icons.content_cut),
  StudioFeature('Photo to Cartoon', 'Upload photos and find people', Icons.face_retouching_natural),
  StudioFeature('AI Movie Maker', 'Build a story scene by scene', Icons.movie_creation_outlined),
  StudioFeature('Video to Cartoon', 'Cartoonize an existing video', Icons.video_library_outlined),
  StudioFeature('Live Cartoon Camera', 'Preview cartoon camera effects', Icons.camera_alt_outlined),
  StudioFeature('Character Studio', 'Create and manage characters', Icons.person_outline),
  StudioFeature('Voice Studio', 'Plan character voices and dialogue', Icons.record_voice_over),
  StudioFeature('Music Studio', 'Plan music and sound effects', Icons.music_note),
  StudioFeature('AI Movie Director', 'Plan shots, scenes and emotions', Icons.theaters_outlined),
  StudioFeature('Emotion & Acting Studio', 'Plan expressions and acting', Icons.mood),
  StudioFeature('Smart Costume Designer', 'Design outfits for each scene', Icons.checkroom),
  StudioFeature('AI World Builder', 'Create story locations and worlds', Icons.public),
  StudioFeature('Storyboard Preview', 'Review scenes before generation', Icons.view_carousel_outlined),
  StudioFeature('Character Interaction', 'Plan how characters act together', Icons.groups_2_outlined),
  StudioFeature('Camera & Action Control', 'Plan cinematic shots and motion', Icons.videocam_outlined),
  StudioFeature('Movie Seasons', 'Continue stories across episodes', Icons.video_collection_outlined),
  StudioFeature('Trailer & Thumbnail Maker', 'Plan trailers, posters and covers', Icons.movie_filter_outlined),
  StudioFeature('Voice Recording Studio', 'Record authorized character voices', Icons.mic_none),
  StudioFeature('Movie Quality Checker', 'Review continuity, voice and lip sync', Icons.fact_check_outlined),
  StudioFeature('Character Creator Studio', 'Customize original character looks', Icons.face_3_outlined),
  StudioFeature('Animal & Creature Creator', 'Create animals and fantasy beings', Icons.pets_outlined),
  StudioFeature('Action & Stunt Studio', 'Plan movement and action scenes', Icons.sports_martial_arts),
  StudioFeature('Weather & Time Control', 'Set weather and time of day', Icons.cloud_outlined),
  StudioFeature('AI Vehicle Creator', 'Add cars, aircraft and more', Icons.directions_car_outlined),
  StudioFeature('Multi-Track Movie Editor', 'Edit video, voice and music tracks', Icons.tune),
  StudioFeature('Social Media Export Studio', 'Prepare formats for social platforms', Icons.ondemand_video),
  StudioFeature('Team Movie Studio', 'Collaborate on shared projects', Icons.people_alt_outlined),
  StudioFeature('Multiple Story Endings', 'Create alternate story outcomes', Icons.account_tree_outlined),
  StudioFeature('AI Transformation Studio', 'Transform character appearances', Icons.auto_awesome),
  StudioFeature('My Asset Library', 'Reuse saved project assets', Icons.collections_bookmark_outlined),
  StudioFeature('AI Lighting Studio', 'Control cinematic light and shadows', Icons.light_mode_outlined),
  StudioFeature('Special Effects Studio', 'Plan magic, smoke and visual effects', Icons.bolt_outlined),
  StudioFeature('Global Language Studio', 'Plan dubbing and subtitles', Icons.translate),
  StudioFeature('RYZON AI Movie Theatre', 'Watch and share finished movies', Icons.local_movies_outlined),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeatureScreen(feature: features.first),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B45D8), Color(0xFF39266F)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFC8B6FF), width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x553F237C), blurRadius: 18, offset: Offset(0, 7)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(Icons.video_camera_back_outlined, size: 29, color: Colors.white),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MAKE CARTOON REELS', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: Color(0xFFE8DFFF))),
                                SizedBox(height: 5),
                                Text('Create viral-style short videos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 4),
                                Text('Vertical 9:16  •  YouTube Shorts  •  Instagram Reels', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeatureScreen(feature: features[1]),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF176B78), Color(0xFF183B58)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF72DCE8), width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(Icons.content_cut, size: 27, color: Colors.white),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VIDEO / MOVIE SPLITTER', style: TextStyle(fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.w800, color: Color(0xFFC9F8FF))),
                                SizedBox(height: 5),
                                Text('Turn one long video into many parts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 4),
                                Text('30 sec  •  60 sec  •  Part 1, Part 2, Part 3…', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 17),
                        ],
                      ),
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
                            builder: (_) {
                              if (feature.title == 'Make Cartoon Reels') {
                                return const CartoonReelsScreen();
                              }
                              if (feature.title == 'Photo to Cartoon') {
                                return const PhotoCharacterScreen();
                              }
                              if (feature.title == 'Video / Movie Splitter') {
                                return const VideoMovieSplitterScreen();
                              }
                              return FeatureScreen(feature: feature);
                            },
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
                  '${_faces.length} face(s) detected',
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
                      title: Text('Person ${index + 1}'),
                      subtitle: Text('Face area: ${box.width.round()} × ${box.height.round()} px'),
                      secondary: const CircleAvatar(child: Icon(Icons.person_outline)),
                    ),
                  );
                }),
                if (_faces.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : _confirmCharacters,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Confirm ${_selected.length} character(s)'),
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
          '${_selected.length} person(s) selected. Cartoon character profile generation will be added in the next step.',
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

class CartoonReelsScreen extends StatefulWidget {
  const CartoonReelsScreen({super.key});
  @override
  State<CartoonReelsScreen> createState() => _CartoonReelsScreenState();
}

class _CartoonReelsScreenState extends State<CartoonReelsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final List<XFile> _photos = [];
  int _seconds = 30;
  String _style = '3D Movie';
  String _language = 'Tamil';
  String _mood = 'Funny';
  bool _draftReady = false;

  Future<void> _addPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 90);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _photos.addAll(picked);
        _draftReady = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add photos. Please try again.')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _draftReady = false;
    });
  }

  void _prepareDraft() {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First add at least one photo for your reel.')),
      );
      return;
    }
    setState(() => _draftReady = true);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Cartoon Reels')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B45D8), Color(0xFF39266F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smart_display_outlined, size: 34),
                SizedBox(height: 8),
                Text('Create your next short video',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Plan a vertical 9:16 cartoon reel for Shorts and Reels.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('1. Add your photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Choose one or more photos'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${_photos.length} photo(s) selected', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (context, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photos[index].path),
                        width: 88,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 88, height: 112,
                          child: ColoredBox(color: Color(0xFF343242), child: Icon(Icons.image_not_supported)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 3,
                      top: 3,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removePhoto(index),
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 5,
                      child: Text('${index + 1}', style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('2. Reel settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Video length'),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15s')),
              ButtonSegment(value: 30, label: Text('30s')),
              ButtonSegment(value: 60, label: Text('60s')),
            ],
            selected: {_seconds},
            onSelectionChanged: (value) => setState(() {
              _seconds = value.first;
              _draftReady = false;
            }),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _style,
            decoration: const InputDecoration(labelText: 'Cartoon style', border: OutlineInputBorder()),
            items: const ['3D Movie', 'Anime', 'Cute', 'Funny', 'Fantasy']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() {
              if (value != null) _style = value;
              _draftReady = false;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mood,
            decoration: const InputDecoration(labelText: 'Reel mood', border: OutlineInputBorder()),
            items: const ['Funny', 'Love', 'Adventure', 'Emotional', 'Dance']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() {
              if (value != null) _mood = value;
              _draftReady = false;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(labelText: 'Dialogue / caption language', border: OutlineInputBorder()),
            items: const ['Tamil', 'English', 'Hindi']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() {
              if (value != null) _language = value;
              _draftReady = false;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reel title or caption (optional)',
              hintText: 'Write a short title...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _draftReady = false),
          ),
          const SizedBox(height: 20),
          const Text('3. Preview layout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 190,
              height: 338,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C3EB6), Color(0xFF17182C)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBFA6FF), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photos.isEmpty
                  ? const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_display_outlined, size: 42),
                        SizedBox(height: 8),
                        Text('9:16 REEL PREVIEW'),
                        SizedBox(height: 4),
                        Text('Add photos to begin', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ))
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_photos.first.path), fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.78)],
                              stops: const [0.42, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: Text(
                            _captionController.text.isEmpty ? 'Your reel caption' : _captionController.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(child: Text('Vertical 9:16 • Shorts / Reels', style: TextStyle(color: Colors.white60, fontSize: 12))),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _prepareDraft,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Prepare Reel Draft'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
          if (_draftReady) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text('Reel draft prepared', style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text('${_photos.length} photos • ${_seconds} seconds • 9:16'),
                    Text('${_style} • ${_mood} • ${_language}'),
                    const SizedBox(height: 6),
                    const Text(
                      'This is a draft configuration only. Cartoon rendering, voice, music, and MP4 export will be connected in a later build.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Use photos and voices only with permission. No AI cartoon video is uploaded or generated by this draft screen.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class VideoMovieSplitterScreen extends StatefulWidget {
  const VideoMovieSplitterScreen({super.key});

  @override
  State<VideoMovieSplitterScreen> createState() => _VideoMovieSplitterScreenState();
}

class _VideoMovieSplitterScreenState extends State<VideoMovieSplitterScreen> {
  final ImagePicker _picker = ImagePicker();
  final Trimmer _trimmer = Trimmer();
  XFile? _video;
  Duration _duration = Duration.zero;
  int _clipSeconds = 30;
  bool _loading = false;
  bool _exporting = false;
  List<String> _parts = [];
  String? _error;

  Future<void> _chooseVideo() async {
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      setState(() {
        _loading = true;
        _error = null;
        _parts = [];
        _video = picked;
      });
      await _trimmer.loadVideo(videoFile: File(picked.path));
      final duration = _trimmer.videoPlayerController?.value.duration ?? Duration.zero;
      if (!mounted) return;
      setState(() {
        _duration = duration;
        _loading = false;
      });
      if (duration == Duration.zero) {
        setState(() => _error = 'Could not read this video duration. Please try another video.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open this video. Please choose another supported video.';
      });
    }
  }

  Future<String?> _savePart(int startMs, int endMs, int partNumber) async {
    final completer = Completer<String?>();
    await _trimmer.saveTrimmedVideo(
      startValue: startMs.toDouble(),
      endValue: endMs.toDouble(),
      videoFolderName: 'RYZON_AI_Parts',
      videoFileName: 'Part_${partNumber.toString().padLeft(2, '0')}',
      onSave: (outputPath) {
        if (!completer.isCompleted) completer.complete(outputPath);
      },
    );
    return completer.future;
  }

  Future<void> _splitVideo() async {
    if (_video == null || _duration <= Duration.zero || _exporting) return;
    final totalMs = _duration.inMilliseconds;
    final segmentMs = _clipSeconds * 1000;
    final count = (totalMs / segmentMs).ceil();
    setState(() {
      _exporting = true;
      _error = null;
      _parts = [];
    });
    final outputs = <String>[];
    try {
      for (var i = 0; i < count; i++) {
        final start = i * segmentMs;
        final end = (start + segmentMs).clamp(0, totalMs).toInt();
        if (end <= start) continue;
        final path = await _savePart(start, end, i + 1);
        if (path == null || path.isEmpty) {
          throw Exception('Part ${i + 1} could not be saved.');
        }
        outputs.add(path);
        if (mounted) setState(() => _parts = List<String>.from(outputs));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${outputs.length} video part(s) saved in RYZON_AI_Parts.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Export stopped: ${e}');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    return hours > 0 ? '${hours}:${minutes}:${seconds}' : '${minutes}:${seconds}';
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partCount = _duration.inMilliseconds == 0
        ? 0
        : (_duration.inMilliseconds / (_clipSeconds * 1000)).ceil();
    return Scaffold(
      appBar: AppBar(title: const Text('Video / Movie Splitter')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Split a long video into short parts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Choose your own video, select 30 or 60 seconds, and create sequential clips without skipping the timeline.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _loading || _exporting ? null : _chooseVideo,
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Choose video from Gallery'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
          if (_loading) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
            const Center(child: Text('Loading video...')),
          ],
          if (_video != null && !_loading) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.movie_outlined, color: Color(0xFFC8B6FF)),
                      SizedBox(width: 8),
                      Text('Selected video', style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 7),
                    Text(_video!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Duration: ${_formatDuration(_duration)}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Choose part length', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 seconds')),
                ButtonSegment(value: 60, label: Text('60 seconds')),
              ],
              selected: {_clipSeconds},
              onSelectionChanged: _exporting
                  ? null
                  : (selection) => setState(() => _clipSeconds = selection.first),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${partCount} part(s) will be created',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (partCount > 0)
                      ...List<Widget>.generate(partCount, (index) {
                        final start = Duration(seconds: index * _clipSeconds);
                        final remaining = _duration - start;
                        final length = remaining.inSeconds.clamp(0, _clipSeconds).toInt();
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text('Part ${index + 1}'),
                          subtitle: Text('${_formatDuration(start)} – ${_formatDuration(start + Duration(seconds: length))}'),
                          trailing: Text('${length}s', style: const TextStyle(color: Colors.white70)),
                        );
                      }),
                    const Text(
                      'The final part may be shorter than the selected length.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _exporting || partCount == 0 ? null : _splitVideo,
              icon: const Icon(Icons.content_cut),
              label: Text(_exporting ? 'Creating parts...' : 'Create ${partCount} parts'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
            if (_exporting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text('${_parts.length} / ${partCount} parts saved',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ],
            if (_parts.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Saved parts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ...List<Widget>.generate(_parts.length, (index) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                    title: Text('Part ${index + 1}'),
                    subtitle: Text(_parts[index], maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          const SizedBox(height: 16),
          const Text(
            'Only split videos you own or have permission to edit and share. This first version saves clips to the app video folder; gallery visibility and device testing still need verification.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
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

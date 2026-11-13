import 'package:flutter/material.dart';

void main() {
  runApp(const RyzonAiApp());
}

class RyzonAiApp extends StatelessWidget {
  const RyzonAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF343242)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class StudioFeature {
  const StudioFeature(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

const features = <StudioFeature>[
  StudioFeature('Photo to Cartoon', 'Turn photos into characters', Icons.face_retouching_natural),
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR AI CARTOON STUDIO', style: TextStyle(letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD9CCFF))),
                      SizedBox(height: 10),
                      Text('Bring your stories to life.', style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.bold)),
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
                          builder: (_) => FeatureScreen(feature: feature),
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
                  'Starter build • AI generation services are not connected yet.',
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
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final StudioFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
}

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key, required this.feature});

  final StudioFeature feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

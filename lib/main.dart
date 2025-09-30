import 'dart:io' show File; // ok on non‑web
import 'dart:math';
import 'dart:typed_data'; // for web bytes
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const CattlenseApp());

class CattlenseApp extends StatelessWidget {
  const CattlenseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattlense Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});
  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _webBytes; // holds bytes for web display
  bool _loading = false;

  // Mock result
  String? _species; // Cattle / Buffalo
  String? _breed;
  String? _disease;
  double? _confidence;
  Rect? _box; // fake detection box

  Future<void> _chooseSource() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Open Camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Open Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return;

    // On web, grab bytes now for Image.memory; XFile.path is a blob URL on web.
    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await file.readAsBytes();
    }

    setState(() {
      _picked = file;
      _webBytes = bytes;
      _loading = true;
      _species = null;
      _breed = null;
      _disease = null;
      _confidence = null;
      _box = null;
    });

    // Simulate “inference”
    await Future.delayed(const Duration(milliseconds: 900));
    _runMockInference();
  }

  void _runMockInference() {
    final rng = Random(_picked!.path.hashCode);
    final diseases = [
      'Lumpy Skin Disease (LSD)',
      'Ringworm (Dermatophytosis)',
      'Mange / Scabies',
      'Dermatophilosis',
      'Ticks & Parasitic Infestations',
    ];
    final cattleBreeds = [
      'Gir',
      'Sahiwal',
      'Red Sindhi',
      'Tharparkar',
      'Hariana',
      'Ongole',
      'Kankrej',
      'Deoni',
      'Hallikar',
      'Krishna Valley',
    ];
    final buffaloBreeds = [
      'Zafrabadi',
      'Murrah',
    ];

    // Simple heuristic: filename containing "buff" or "murrah" -> buffalo
    final name = _picked!.name.toLowerCase();
    final isBuff = name.contains('buff') || name.contains('murrah');
    final species =
        isBuff ? 'Buffalo' : (rng.nextBool() ? 'Cattle' : 'Buffalo');
    final breed = species == 'Buffalo'
        ? buffaloBreeds[rng.nextInt(buffaloBreeds.length)]
        : cattleBreeds[rng.nextInt(cattleBreeds.length)];
    final disease = diseases[rng.nextInt(diseases.length)];
    final confidence = (70 + rng.nextInt(25)) / 100.0;

    // Fake box somewhere near center
    final left = 0.15 + rng.nextDouble() * 0.3;
    final top = 0.18 + rng.nextDouble() * 0.25;
    final w = 0.5 + rng.nextDouble() * 0.25;
    final h = 0.35 + rng.nextDouble() * 0.2;

    setState(() {
      _species = species;
      _breed = breed;
      _disease = disease;
      _confidence = confidence;
      _box = Rect.fromLTWH(left, top, w, h);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cattlense'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _chooseSource,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Open Camera / Gallery'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'AI-powered cattle & buffalo breed classification and skin disease suggestion.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _imagePanel(theme),
          const SizedBox(height: 16),
          _resultPanel(theme),
          const SizedBox(height: 16),
          _tipsPanel(theme),
        ],
      ),
    );
  }

  Widget _imagePanel(ThemeData theme) {
    final radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 1.3,
        child: ClipRRect(
          borderRadius: radius,
          child: _picked == null
              ? _emptyState()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (kIsWeb && _webBytes != null)
                      Image.memory(_webBytes!, fit: BoxFit.cover)
                    else
                      Image.file(File(_picked!.path), fit: BoxFit.cover),
                    if (_loading)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_loading && _box != null)
                      CustomPaint(
                        painter: DetectionOverlay(
                          relativeBox: _box!,
                          label: '${_breed ?? 'Unknown'}',
                          color: Colors.teal,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.photo_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('Tap the button to capture or pick an image'),
        ],
      ),
    );
  }

  Widget _resultPanel(ThemeData theme) {
    final ok = !_loading && _species != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ok
          ? Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted: ${_species!} • ${_breed!}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Confidence: ${((_confidence ?? 0) * 100).toStringAsFixed(1)}%',
                    ),
                    const Divider(height: 24),
                    Text(
                      'Likely skin disease: ${_disease!}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(For diagnosis consult a veterinarian.)',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _tipsPanel(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tips:'),
            SizedBox(height: 8),
            Text(
                '• Use good lighting and focus on the animal\'s face and upper body.'),
            Text('• Avoid blurry or low-resolution images.'),
            Text('•  Ensure the animal is facing the camera for best results.'),
          ],
        ),
      ),
    );
  }
}

class DetectionOverlay extends CustomPainter {
  DetectionOverlay({
    required this.relativeBox,
    required this.label,
    this.color = Colors.teal,
  });

  final Rect relativeBox; // in 0..1 coordinates
  final String label;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      relativeBox.left * size.width,
      relativeBox.top * size.height,
      relativeBox.width * size.width,
      relativeBox.height * size.height,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.15);

    // box
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, paint);

    // label bg
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    const labelPad = 6.0;
    final labelRect = Rect.fromLTWH(
      rect.left,
      max(0, rect.top - tp.height - 10),
      tp.width + 2 * labelPad,
      tp.height + 2 * labelPad,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      Paint()..color = color,
    );
    tp.paint(
        canvas, Offset(labelRect.left + labelPad, labelRect.top + labelPad));
  }

  @override
  bool shouldRepaint(covariant DetectionOverlay oldDelegate) {
    return oldDelegate.relativeBox != relativeBox ||
        oldDelegate.label != label ||
        oldDelegate.color != color;
  }
}

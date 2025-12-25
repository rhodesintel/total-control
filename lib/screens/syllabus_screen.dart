import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/config_service.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final ConfigService _config = ConfigService();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<String> _films = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _loadFilms() async {
    await _config.init();
    setState(() => _films = List<String>.from(_config.syllabusFilms));
  }

  void _addFilm(String title) {
    if (title.isEmpty || _films.contains(title)) return;
    setState(() => _films.add(title));
    _config.setSyllabusFilms(_films);
  }

  void _removeFilm(String title) {
    setState(() => _films.remove(title));
    _config.setSyllabusFilms(_films);
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Film'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Enter film title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) _addFilm(title);
  }

  Future<void> _scanSyllabus() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() => _isProcessing = true);
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedTitles = _extractFilmTitles(recognizedText.text);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (extractedTitles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No film titles detected')));
        return;
      }
      final confirmed = await _showConfirmTitlesDialog(extractedTitles);
      if (confirmed != null) for (final t in confirmed) _addFilm(t);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<String> _extractFilmTitles(String text) {
    final titles = <String>[];
    final yearPattern = RegExp(r'^(.+?)\s*\((\d{4})\)\s*$');
    for (var line in text.split('\n')) {
      line = line.trim();
      if (line.length < 3) continue;
      final m = yearPattern.firstMatch(line);
      if (m != null) titles.add('${m.group(1)!.trim()} (${m.group(2)})');
      else if (line.length > 5 && line.length < 80 && line[0] == line[0].toUpperCase()) titles.add(line);
    }
    return titles.toSet().toList();
  }

  Future<List<String>?> _showConfirmTitlesDialog(List<String> titles) async {
    final selected = List<bool>.filled(titles.length, true);
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Detected Titles'),
          content: SizedBox(width: double.maxFinite, child: ListView.builder(
            shrinkWrap: true,
            itemCount: titles.length,
            itemBuilder: (_, i) => CheckboxListTile(title: Text(titles[i]), value: selected[i], onChanged: (v) => setS(() => selected[i] = v ?? false)),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, [for (int i = 0; i < titles.length; i++) if (selected[i]) titles[i]]), child: const Text('Add')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syllabus Films'), actions: [
        IconButton(icon: const Icon(Icons.camera_alt), onPressed: _isProcessing ? null : _scanSyllabus, tooltip: 'Scan'),
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog, tooltip: 'Add'),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Films in your syllabus are allowed even when blocking is active.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _scanSyllabus,
            icon: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.document_scanner),
            label: Text(_isProcessing ? 'Scanning...' : 'Scan Syllabus Photo'),
          ),
        ])),
        Expanded(child: _films.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.movie_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No films'), Text('Tap + or scan')]))
          : ListView.builder(itemCount: _films.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.movie), title: Text(_films[i]), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeFilm(_films[i]))))),
        Padding(padding: const EdgeInsets.all(16), child: Text('${_films.length} films', style: Theme.of(context).textTheme.bodySmall)),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}

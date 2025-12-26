import 'package:flutter/material.dart';
import '../services/config_service.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});
  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final ConfigService _config = ConfigService();
  List<String> _films = [];

  @override
  void initState() {
    super.initState();
    _loadFilms();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syllabus Films'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog, tooltip: 'Add'),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Films in your syllabus are allowed even when blocking is active.'),
          SizedBox(height: 8),
          Text('(Photo scanning temporarily disabled)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        Expanded(child: _films.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.movie_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No films'), Text('Tap + to add')]))
          : ListView.builder(itemCount: _films.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.movie), title: Text(_films[i]), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeFilm(_films[i]))))),
        Padding(padding: const EdgeInsets.all(16), child: Text('${_films.length} films', style: Theme.of(context).textTheme.bodySmall)),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}

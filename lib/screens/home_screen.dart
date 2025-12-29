import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/rule.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Rule> _rules = [];
  Progress _progress = Progress(stepsToday: 8234, workoutMinutesToday: 15);

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getString('rules');
    if (rulesJson != null) {
      final List<dynamic> decoded = jsonDecode(rulesJson);
      setState(() {
        _rules = decoded.map((r) => Rule.fromJson(r)).toList();
      });
    }
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = jsonEncode(_rules.map((r) => r.toJson()).toList());
    await prefs.setString('rules', rulesJson);
  }

  void _addRule(Rule rule) {
    setState(() => _rules.add(rule));
    _saveRules();
  }

  void _deleteRule(String id) {
    setState(() => _rules.removeWhere((r) => r.id == id));
    _saveRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.metal,
                border: Border.all(color: AppColors.amberDim, width: 2),
              ),
              child: const Center(
                child: Text(
                  '◆ TOTAL CONTROL ◆',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Subtitle
            const Text(
              'NO X UNTIL X',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 12),

            // Rules list
            Expanded(
              child: _rules.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _rules.length,
                      itemBuilder: (ctx, i) => _buildRuleCard(_rules[i]),
                    ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAddRuleDialog(context),
                  child: const Text('+ ADD RULE'),
                ),
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _rules.isEmpty ? 'NO RULES SET' : 'PROTECTION ACTIVE',
                style: TextStyle(
                  fontSize: 11,
                  color: _rules.isEmpty ? AppColors.textDim : AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: AppColors.textDim),
          const SizedBox(height: 16),
          const Text(
            'No rules yet',
            style: TextStyle(color: AppColors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + ADD RULE to create one',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(Rule rule) {
    final (met, status) = _progress.checkCondition(rule.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.metal,
        border: Border.all(
          color: met ? AppColors.greenDim : AppColors.redDim,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 80,
              child: Column(
                children: [
                  Icon(
                    met ? Icons.lock_open : Icons.lock,
                    color: met ? AppColors.green : AppColors.red,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    met ? 'ALLOWED' : 'BLOCKED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: met ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Rule info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO ${rule.blockedItems.take(2).join(", ")}${rule.blockedItems.length > 2 ? " +${rule.blockedItems.length - 2}" : ""}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'UNTIL ${rule.condition.describe()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.red),
              onPressed: () => _confirmDelete(rule),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Rule rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Delete Rule?', style: TextStyle(color: AppColors.amber)),
        content: Text(rule.describe(), style: const TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRule(rule.id);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    final itemsController = TextEditingController();
    final valueController = TextEditingController(text: '10000');
    ConditionType selectedType = ConditionType.steps;
    Set<String> selectedCategories = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('NEW RULE', style: TextStyle(color: AppColors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NO ___
                const Text('NO', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Category chips
                const Text('Quick select:', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: BlockCategory.presets.map((cat) {
                    final isSelected = selectedCategories.contains(cat.name);
                    return FilterChip(
                      label: Text('${cat.icon} ${cat.name}'),
                      selected: isSelected,
                      selectedColor: AppColors.amber,
                      backgroundColor: AppColors.metal,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.bg : AppColors.text,
                        fontSize: 10,
                      ),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedCategories.add(cat.name);
                            // Add items to text field
                            final current = itemsController.text.isEmpty
                                ? <String>[]
                                : itemsController.text.split(',').map((s) => s.trim()).toList();
                            current.addAll(cat.items);
                            itemsController.text = current.toSet().join(', ');
                          } else {
                            selectedCategories.remove(cat.name);
                            // Remove items
                            final current = itemsController.text.split(',').map((s) => s.trim()).toSet();
                            current.removeAll(cat.items);
                            itemsController.text = current.join(', ');
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                const Text('Or type manually:', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                TextField(
                  controller: itemsController,
                  style: const TextStyle(color: AppColors.text),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Netflix, YouTube, TikTok...',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.metal),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // UNTIL ___
                const Text('UNTIL', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Condition type selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ConditionType.values.map((type) {
                    final isSelected = type == selectedType;
                    return ChoiceChip(
                      label: Text(type.name),
                      selected: isSelected,
                      selectedColor: AppColors.amber,
                      backgroundColor: AppColors.metal,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.bg : AppColors.text,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => selectedType = type);
                          // Set default values
                          switch (type) {
                            case ConditionType.steps:
                              valueController.text = '10000';
                            case ConditionType.time:
                              valueController.text = '17:00';
                            case ConditionType.workout:
                              valueController.text = '30';
                            case ConditionType.location:
                              valueController.text = 'Gym';
                            default:
                              valueController.text = '';
                          }
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Value input (not for tomorrow/password)
                if (selectedType != ConditionType.tomorrow && selectedType != ConditionType.password) ...[
                  const Text('VALUE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: valueController,
                    style: const TextStyle(color: AppColors.text),
                    keyboardType: selectedType == ConditionType.time
                        ? TextInputType.datetime
                        : TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _getHint(selectedType),
                      hintStyle: const TextStyle(color: AppColors.textDim),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.metal),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final items = itemsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter at least one item to block')),
                  );
                  return;
                }

                final condition = _buildCondition(selectedType, valueController.text);
                final rule = Rule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  blockedItems: items,
                  condition: condition,
                );

                Navigator.pop(ctx);
                _addRule(rule);
              },
              child: const Text('CREATE'),
            ),
          ],
        ),
      ),
    );
  }

  String _getHint(ConditionType type) {
    switch (type) {
      case ConditionType.steps:
        return '10000';
      case ConditionType.time:
        return '17:00';
      case ConditionType.workout:
        return '30 (minutes)';
      case ConditionType.location:
        return 'Gym';
      default:
        return '';
    }
  }

  Condition _buildCondition(ConditionType type, String value) {
    switch (type) {
      case ConditionType.steps:
        return Condition(type: type, stepsTarget: int.tryParse(value) ?? 10000);
      case ConditionType.time:
        return Condition(type: type, timeTarget: value);
      case ConditionType.workout:
        return Condition(type: type, workoutMinutes: int.tryParse(value) ?? 30);
      case ConditionType.location:
        return Condition(type: type, location: Location(name: value, latitude: 0, longitude: 0));
      case ConditionType.tomorrow:
      case ConditionType.password:
        return Condition(type: type);
    }
  }
}

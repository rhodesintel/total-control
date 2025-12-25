import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../theme/coldwar_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Demo goals - will be replaced with persistent storage
  final List<Goal> _goals = [
    Goal(
      id: '1',
      name: '50K Steps Daily',
      type: GoalType.realtime,
      target: 50000,
      current: 32450,
      unit: 'steps',
      deadline: DateTime(2025, 1, 15),
      rewardApps: ['netflix.com', 'youtube.com'],
      source: 'Google Fit',
      status: GoalStatus.active,
    ),
    Goal(
      id: '2',
      name: 'LSAT Score 170+',
      type: GoalType.delayed,
      target: 170,
      current: null,
      unit: 'score',
      deadline: DateTime(2025, 2, 1),
      rewardApps: ['ALL'],
      source: 'LSAC Portal',
      status: GoalStatus.waiting,
      gracePeriod: true,
      resultArrived: false,
    ),
    Goal(
      id: '3',
      name: 'Emergency Fund \$5K',
      type: GoalType.realtime,
      target: 5000,
      current: 3247,
      unit: 'USD',
      deadline: DateTime(2025, 3, 1),
      rewardApps: ['netflix.com', 'spotify.com'],
      source: 'Plaid (Chase)',
      status: GoalStatus.active,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('◆ GOALS ◆'),
        leading: IconButton(
          icon: const Text('◄', style: TextStyle(fontSize: 20, color: ColdWarTheme.amber)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Hazard stripe top
          _buildHazardStripe(),

          Expanded(
            child: Container(
              color: ColdWarTheme.bgPanel,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Earn rewards by hitting targets:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  for (final goal in _goals) _buildGoalCard(goal),

                  const SizedBox(height: 16),
                  _buildAddGoalButton(),
                ],
              ),
            ),
          ),

          // Hazard stripe bottom
          _buildHazardStripe(),
        ],
      ),
    );
  }

  Widget _buildHazardStripe() {
    return SizedBox(
      height: 8,
      child: CustomPaint(
        painter: HazardStripePainter(),
        size: const Size(double.infinity, 8),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColdWarTheme.bgInset,
        border: Border.all(color: ColdWarTheme.metal, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  '► ${goal.name}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColdWarTheme.amber,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: ColdWarTheme.metal,
                  child: Text(
                    goal.type == GoalType.realtime ? 'LIVE' : 'PENDING',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 10,
                      color: goal.type == GoalType.realtime
                          ? ColdWarTheme.ok
                          : ColdWarTheme.amberDim,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress or status
            if (goal.type == GoalType.realtime)
              _buildRealtimeProgress(goal)
            else
              _buildDelayedStatus(goal),

            const SizedBox(height: 12),

            // Footer: deadline + rewards
            Row(
              children: [
                Text(
                  'Deadline: ${_formatDate(goal.deadline)}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 10,
                    color: ColdWarTheme.textDim,
                  ),
                ),
                const Spacer(),
                Text(
                  'Unlocks: ${_formatRewards(goal.rewardApps)}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 10,
                    color: ColdWarTheme.okDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeProgress(Goal goal) {
    final pct = (goal.progress * 100).round();
    final isMet = goal.isMet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: ColdWarTheme.metal,
            border: Border.all(color: ColdWarTheme.textDim),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: goal.progress,
                child: Container(
                  color: isMet ? ColdWarTheme.ok : ColdWarTheme.amber,
                ),
              ),
              Center(
                child: Text(
                  '${_formatNumber(goal.current ?? 0)} / ${_formatNumber(goal.target)} ${goal.unit}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: ColdWarTheme.text,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Status text
        Text(
          isMet
              ? '✓ GOAL MET - REWARDS UNLOCKED'
              : '↓ ${_formatNumber(goal.remaining)} ${goal.unit} remaining',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 11,
            color: isMet ? ColdWarTheme.ok : ColdWarTheme.textDim,
          ),
        ),
      ],
    );
  }

  Widget _buildDelayedStatus(Goal goal) {
    if (goal.gracePeriod && !goal.resultArrived) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏳ GRACE PERIOD ACTIVE',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColdWarTheme.ok,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rewards unlocked while awaiting result',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 10,
              color: ColdWarTheme.textDim,
            ),
          ),
          Text(
            'Checking: ${goal.source}',
            style: const TextStyle(
              fontFamily: 'Courier New',
              fontSize: 10,
              color: ColdWarTheme.amberDim,
            ),
          ),
        ],
      );
    } else if (goal.resultArrived) {
      final met = goal.isMet;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            met ? '✓ GOAL MET' : '✖ GOAL MISSED',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: met ? ColdWarTheme.ok : ColdWarTheme.danger,
            ),
          ),
          if (!met) ...[
            const SizedBox(height: 4),
            const Text(
              'Blocked until next attempt',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 10,
                color: ColdWarTheme.dangerDim,
              ),
            ),
          ],
        ],
      );
    } else {
      return const Text(
        'AWAITING RESULT',
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: ColdWarTheme.amber,
        ),
      );
    }
  }

  Widget _buildAddGoalButton() {
    return InkWell(
      onTap: _showAddGoalDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColdWarTheme.metal,
          border: Border.all(color: ColdWarTheme.metalLight, width: 2),
        ),
        child: const Center(
          child: Text(
            '+ ADD GOAL',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ColdWarTheme.amber,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColdWarTheme.bgPanel,
        title: const Text(
          'NEW GOAL',
          style: TextStyle(
            fontFamily: 'Courier New',
            color: ColdWarTheme.amber,
          ),
        ),
        content: const Text(
          'Goal creation coming soon.\n\nSupported sources:\n• Google Fit (steps)\n• Plaid (bank balance)\n• LSAC (LSAT scores)\n• Manual entry',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            color: ColdWarTheme.text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toStringAsFixed(0);
  }

  String _formatRewards(List<String> rewards) {
    if (rewards.contains('ALL')) return 'ALL SITES';
    if (rewards.length <= 2) return rewards.join(', ');
    return '${rewards.take(2).join(', ')} +${rewards.length - 2}';
  }
}

class HazardStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellowPaint = Paint()..color = ColdWarTheme.hazardYellow;
    final blackPaint = Paint()..color = ColdWarTheme.hazardBlack;

    const stripeWidth = 20.0;
    for (int i = -2; i < (size.width / stripeWidth).ceil() + 2; i++) {
      final x = i * stripeWidth;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, i.isEven ? yellowPaint : blackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

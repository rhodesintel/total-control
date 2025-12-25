import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/config_service.dart';
import '../services/blocker_service.dart';
import '../services/fitness_sync_service.dart';
import '../theme/coldwar_theme.dart';
import 'schedule_screen.dart';
import 'syllabus_screen.dart';
import 'settings_screen.dart';
import 'goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ConfigService _config = ConfigService();
  final BlockerService _blocker = BlockerService();
  bool _blockerEnabled = true;
  bool _vpnEnabled = false;
  bool _accessibilityEnabled = false;
  bool _overlayEnabled = false;
  int _syllabusCount = 0;
  int _threatCount = 47;

  // Fitness
  final FitnessSyncService _fitness = FitnessSyncService();
  int _steps = 0;
  int _stepsGoal = 10000;
  int _workoutMins = 0;
  int _workoutGoal = 30;
  int _earnedMins = 0;

  // Scanner animation
  late AnimationController _scannerController;
  bool _scanComplete = false;
  List<Offset> _detectedBlips = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _autoStartVpn();
    _loadFitness();

    // Scanner animation - one rotation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Generate random blips
    final random = math.Random();
    for (int i = 0; i < random.nextInt(3) + 2; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = random.nextDouble() * 0.6 + 0.2;
      _detectedBlips.add(Offset(
        0.5 + dist * math.cos(angle) * 0.4,
        0.5 + dist * math.sin(angle) * 0.4,
      ));
    }

    _scannerController.forward().then((_) {
      setState(() => _scanComplete = true);
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    await _config.init();
    final permissions = await _blocker.checkPermissions();
    final vpnRunning = await _blocker.isVpnRunning();
    setState(() {
      _blockerEnabled = _config.isBlockerEnabled;
      _vpnEnabled = vpnRunning;
      _accessibilityEnabled = permissions['accessibility'] ?? false;
      _overlayEnabled = permissions['overlay'] ?? false;
      _syllabusCount = _config.syllabusFilms.length;
    });
  }

  Future<void> _autoStartVpn() async {
    final isRunning = await _blocker.isVpnRunning();
    if (!isRunning) {
      final prepared = await _blocker.prepareVpn();
      if (prepared) {
        await _blocker.startVpn();
        await _config.setVpnEnabled(true);
        if (mounted) setState(() => _vpnEnabled = true);
      }
    } else {
      if (mounted) setState(() => _vpnEnabled = true);
    }
  }

  Future<void> _loadFitness() async {
    final hasAuth = await _fitness.requestPermissions();
    if (!hasAuth) return;

    await _fitness.loadGoals();
    final data = await _fitness.getTodayFitness();
    final rewards = _fitness.calculateRewards(data);

    if (mounted) {
      setState(() {
        _steps = rewards['steps'] as int;
        _stepsGoal = rewards['steps_goal'] as int;
        _workoutMins = rewards['workout_mins'] as int;
        _workoutGoal = rewards['workout_goal'] as int;
        _earnedMins = rewards['earned_mins'] as int;
      });
    }

    // Sync to Firebase
    await _fitness.syncToFirebase();
  }

  Future<void> _toggleVpn(bool value) async {
    if (value) {
      final prepared = await _blocker.prepareVpn();
      if (prepared) {
        await _blocker.startVpn();
        await _config.setVpnEnabled(true);
        setState(() => _vpnEnabled = true);
      }
    } else {
      final approved = await _requestDisableApproval();
      if (!approved) return;
      await _blocker.stopVpn();
      await _config.setVpnEnabled(false);
      setState(() => _vpnEnabled = false);
    }
  }

  Future<bool> _requestDisableApproval() async {
    if (_config.hasPassword) {
      return await _showPasswordDialog();
    }
    return await _showWarningDialog();
  }

  Future<bool> _showWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColdWarTheme.bgPanel,
        title: const Text('DISABLE PROTECTION?', style: TextStyle(fontFamily: 'Courier New', color: ColdWarTheme.amber)),
        content: const Text('This will allow blocked sites to bypass filtering.', style: TextStyle(fontFamily: 'Courier New', color: ColdWarTheme.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DISABLE', style: TextStyle(color: ColdWarTheme.danger))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showPasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColdWarTheme.bgPanel,
        title: const Text('PASSWORD REQUIRED', style: TextStyle(fontFamily: 'Courier New', color: ColdWarTheme.amber)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(fontFamily: 'Courier New', color: ColdWarTheme.text),
          decoration: const InputDecoration(hintText: 'Enter password', hintStyle: TextStyle(color: ColdWarTheme.textDim)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () {
            final verified = _config.verifyPassword(controller.text);
            Navigator.pop(context, verified);
          }, child: const Text('OK')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _navigateTo(Widget screen) async {
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hazard stripe top
          const HazardStripe(),

          // Main content
          Expanded(
            child: Container(
              color: ColdWarTheme.bgPanel,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStatusPanel(),
                    _buildScannerAndStats(),
                    _buildFitnessPanel(),
                    _buildNavButtons(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),

          // Hazard stripe bottom
          const HazardStripe(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColdWarTheme.metal,
        border: Border.all(color: ColdWarTheme.metalLight, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            _buildRivet(),
            const Expanded(
              child: Column(
                children: [
                  Text(
                    '◆ TOTAL CONTROL ◆',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColdWarTheme.amber,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'by Rhodes',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 10,
                      color: ColdWarTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            _buildRivet(),
          ],
        ),
      ),
    );
  }

  Widget _buildRivet() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ColdWarTheme.rivet,
        shape: BoxShape.circle,
        border: Border.all(color: ColdWarTheme.bgInset, width: 1),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ SYSTEM STATUS ]',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 10, color: ColdWarTheme.textDim),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: ColdWarTheme.bgInset,
              border: Border.all(color: ColdWarTheme.metal, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildStatusRow('VPN INTERCEPT', _vpnEnabled, () => _toggleVpn(!_vpnEnabled)),
                const SizedBox(height: 8),
                _buildStatusRow('ACCESS CONTROL', _accessibilityEnabled, () => _blocker.openAccessibilitySettings()),
                const Divider(color: ColdWarTheme.metal, height: 20),
                Text(
                  _vpnEnabled && _accessibilityEnabled
                      ? '● PROTECTION ACTIVE ●'
                      : _vpnEnabled || _accessibilityEnabled
                          ? '◐ PARTIAL PROTECTION ◐'
                          : '○ PROTECTION DISABLED ○',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    color: _vpnEnabled && _accessibilityEnabled
                        ? ColdWarTheme.ok
                        : _vpnEnabled || _accessibilityEnabled
                            ? ColdWarTheme.amber
                            : ColdWarTheme.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: active ? ColdWarTheme.ok : ColdWarTheme.dangerDim,
              shape: BoxShape.circle,
              boxShadow: active ? [BoxShadow(color: ColdWarTheme.ok.withOpacity(0.5), blurRadius: 4)] : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Courier New',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColdWarTheme.textStencil,
            ),
          ),
          const Spacer(),
          Text(
            active ? 'ARMED' : 'DISARMED',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? ColdWarTheme.ok : ColdWarTheme.dangerDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerAndStats() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ THREAT SCANNER ]',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 10, color: ColdWarTheme.textDim),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: ColdWarTheme.bgInset,
              border: Border.all(color: ColdWarTheme.metal, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Scanner
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0800),
                    border: Border.all(color: ColdWarTheme.metal, width: 2),
                  ),
                  child: AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ScannerPainter(
                          angle: _scannerController.value * 2 * math.pi,
                          blips: _detectedBlips,
                          scanComplete: _scanComplete,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Stats
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0800),
                          border: Border.all(color: ColdWarTheme.metal),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_threatCount'.padLeft(4, '0'),
                              style: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ColdWarTheme.amber,
                              ),
                            ),
                            const Text(
                              'NEUTRALIZED',
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 9,
                                color: ColdWarTheme.amberDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanComplete
                            ? '${_detectedBlips.length} BLOCKED'
                            : 'SCANNING...',
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _scanComplete ? ColdWarTheme.ok : ColdWarTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessPanel() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ FITNESS REWARDS ]',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 10, color: ColdWarTheme.textDim),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: ColdWarTheme.bgInset,
              border: Border.all(color: ColdWarTheme.metal, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildProgressRow('STEPS', _steps, _stepsGoal),
                const SizedBox(height: 8),
                _buildProgressRow('WORKOUT', _workoutMins, _workoutGoal, suffix: 'min'),
                const Divider(color: ColdWarTheme.metal, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _earnedMins > 0 ? ColdWarTheme.ok : ColdWarTheme.dangerDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _earnedMins > 0 ? 'EARNED: ${_earnedMins}min STREAMING' : 'NO REWARDS YET',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _earnedMins > 0 ? ColdWarTheme.ok : ColdWarTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int goal, {String suffix = ''}) {
    final pct = (current / goal).clamp(0.0, 1.0);
    final complete = current >= goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Courier New', fontSize: 11, fontWeight: FontWeight.bold, color: ColdWarTheme.textStencil)),
            Text('$current/$goal$suffix', style: TextStyle(fontFamily: 'Courier New', fontSize: 11, color: complete ? ColdWarTheme.ok : ColdWarTheme.amber)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(color: const Color(0xFF0A0800), border: Border.all(color: ColdWarTheme.metal)),
          child: FractionallySizedBox(
            widthFactor: pct,
            alignment: Alignment.centerLeft,
            child: Container(color: complete ? ColdWarTheme.ok : ColdWarTheme.amber),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ SUBSYSTEMS ]',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 10, color: ColdWarTheme.textDim),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildNavButton('SCHEDULE', '24HR GRID', Icons.calendar_month, () => _navigateTo(const ScheduleScreen()))),
              const SizedBox(width: 8),
              Expanded(child: _buildNavButton('GOALS', '2 ACTIVE', Icons.flag, () => _navigateTo(const GoalsScreen()))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildNavButton('SYLLABUS', '$_syllabusCount ITEMS', Icons.movie, () => _navigateTo(const SyllabusScreen()))),
              const SizedBox(width: 8),
              Expanded(child: _buildNavButton('SETTINGS', '►', Icons.settings, () => _navigateTo(const SettingsScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: ColdWarTheme.metal,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: ColdWarTheme.metalLight, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColdWarTheme.textStencil,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 9,
                  color: ColdWarTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(height: 1, color: ColdWarTheme.amberDim),
          const SizedBox(height: 8),
          const Text(
            'RHODES SYSTEMS v0.15',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 9, color: ColdWarTheme.textDim),
          ),
          const Text(
            'FOCUS IS FREEDOM',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 10, color: ColdWarTheme.amberDim),
          ),
        ],
      ),
    );
  }
}

class HazardStripe extends StatelessWidget {
  const HazardStripe({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(painter: HazardStripePainter()),
    );
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

class ScannerPainter extends CustomPainter {
  final double angle;
  final List<Offset> blips;
  final bool scanComplete;

  ScannerPainter({required this.angle, required this.blips, required this.scanComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Grid circles
    final gridPaint = Paint()
      ..color = ColdWarTheme.okDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double r = radius; r > 0; r -= radius / 4) {
      canvas.drawCircle(center, r, gridPaint);
    }

    // Crosshairs
    canvas.drawLine(Offset(4, center.dy), Offset(size.width - 4, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 4), Offset(center.dx, size.height - 4), gridPaint);

    if (!scanComplete) {
      // Sweep line
      final sweepPaint = Paint()
        ..color = ColdWarTheme.ok
        ..strokeWidth = 2;

      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy - radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), sweepPaint);

      // Trail
      for (int i = 1; i < 10; i++) {
        final trailAngle = angle - i * 0.1;
        final trailPaint = Paint()
          ..color = ColdWarTheme.ok.withOpacity(1 - i / 10)
          ..strokeWidth = 1;
        final tx = center.dx + radius * math.cos(trailAngle);
        final ty = center.dy - radius * math.sin(trailAngle);
        canvas.drawLine(center, Offset(tx, ty), trailPaint);
      }
    }

    // Blips
    final blipPaint = Paint()..color = ColdWarTheme.amber;
    for (final blip in blips) {
      final blipAngle = math.atan2(0.5 - blip.dy, blip.dx - 0.5);
      final normalizedAngle = (blipAngle + 2 * math.pi) % (2 * math.pi);
      final sweepAngle = (angle + 2 * math.pi) % (2 * math.pi);

      if (scanComplete || normalizedAngle < sweepAngle) {
        canvas.drawCircle(
          Offset(blip.dx * size.width, blip.dy * size.height),
          4,
          blipPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScannerPainter oldDelegate) =>
      angle != oldDelegate.angle || scanComplete != oldDelegate.scanComplete;
}

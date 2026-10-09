import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../models/certificate_model.dart';
import '../../services/api_service.dart';
import '../../services/certificate_service.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _activeAction;
  bool get _isGenerating => _activeAction != null;
  int _points = 0;
  late CertificateLevel _currentLevel;

  late final AnimationController _shimmerCtrl;
  late final AnimationController _badgePulse;

  @override
  void initState() {
    super.initState();
    _currentLevel = CertificateLevel.fromPoints(0);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final api = ApiService();
      final response = await api.get('/users/profile-stats');
      if (mounted) {
        final pts = response['points'] ?? 0;
        setState(() {
          _points = pts;
          _currentLevel = CertificateLevel.fromPoints(pts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Certificate stats error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _download() async {
    if (_currentLevel.level < 1) {
      _showLockedSnack();
      return;
    }
    if (_activeAction != null) return;
    setState(() => _activeAction = 'download');
    try {
      final user = context.read<UserProvider>();
      final file = await CertificateService.saveCertificateLocally(
        recipientName: user.userName ?? 'CampusLift User',
        collegeName:   user.collegeName ?? 'VIT Pune',
        points:        _points,
        level:         _currentLevel,
        prn:           user.prn,
      );
      if (mounted) _showSavedSnack(file);
    } catch (e) {
      if (mounted) _showErrorSnack('Failed to save certificate: $e');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _share() async {
    if (_currentLevel.level < 1) {
      _showLockedSnack();
      return;
    }
    if (_activeAction != null) return;
    setState(() => _activeAction = 'share');
    try {
      final user = context.read<UserProvider>();
      await CertificateService.shareCertificate(
        recipientName: user.userName ?? 'CampusLift User',
        collegeName:   user.collegeName ?? 'VIT Pune',
        points:        _points,
        level:         _currentLevel,
        prn:           user.prn,
      );
    } catch (e) {
      if (mounted) _showErrorSnack('Failed to share certificate: $e');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _preview() async {
    if (_currentLevel.level < 1) {
      _showLockedSnack();
      return;
    }
    if (_activeAction != null) return;
    setState(() => _activeAction = 'preview');
    try {
      final user = context.read<UserProvider>();
      final pdfBytes = await CertificateService.generateCertificatePdf(
        recipientName: user.userName ?? 'CampusLift User',
        collegeName:   user.collegeName ?? 'VIT Pune',
        points:        _points,
        level:         _currentLevel,
        prn:           user.prn,
      );
      if (pdfBytes.isEmpty) {
        throw Exception('Generated PDF contains empty data');
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.95,
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Certificate Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _share();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _download();
                      },
                    ),
                  ],
                ),
                body: PdfPreview(
                  build: (format) => pdfBytes,
                  useActions: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showErrorSnack('Preview failed: $e');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Earn 100 points to unlock your first certificate!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSavedSnack(File file) {
    final fileName = file.path.split(RegExp(r'[\\/]')).last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text('Saved to $fileName')),
        ]),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $msg'),
        backgroundColor: AppColors.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoader() : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'My Achievements',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCertificateCard(),
          const SizedBox(height: 24),
          if (_currentLevel.level >= 1) _buildActionButtons(),
          if (_currentLevel.level < 1) _buildUnlockHint(),
          const SizedBox(height: 32),
          _buildProgressSection(),
          const SizedBox(height: 32),
          _buildLevelRoadmap(),
        ],
      ),
    );
  }

  // ── Certificate Hero Card ─────────────────────────────────────────────────

  Widget _buildCertificateCard() {
    final color = _currentLevel.primaryColor;
    final accent = _currentLevel.accentColor;
    final isUnlocked = _currentLevel.level >= 1;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D2149),
                    Color(0xFF1A3A6B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Top-left decorative corner
            Positioned(
              top: -20, left: -20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Gold accent stripes (right side)
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: Container(
                width: 8,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFB8860B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12, top: 0, bottom: 0,
              child: Container(
                width: 4,
                color: const Color(0xFFF5A623).withValues(alpha: 0.4),
              ),
            ),

            // Gold border frame
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Lock overlay for level 0
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 40, color: Colors.white54),
                      SizedBox(height: 8),
                      Text(
                        'Earn 100 points to unlock',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CAMPUSLIFT',
                            style: TextStyle(
                              color: Color(0xFFF5A623),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            'CERTIFICATE OF ACHIEVEMENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Badge medallion
                      AnimatedBuilder(
                        animation: _badgePulse,
                        builder: (_, __) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [accent, color, const Color(0xFF0D2149)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFFF5A623),
                              width: 2 + _badgePulse.value * 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5 + _badgePulse.value * 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentLevel.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // "This certificate is proudly presented to"
                  Text(
                    'This certificate is proudly presented to',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Recipient name
                  Consumer<UserProvider>(
                    builder: (_, user, __) => Text(
                      user.userName ?? 'CampusLift User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 16),

                  // Bottom row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLevel.title.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFF5A623),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _currentLevel.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '$_points pts',
                        style: const TextStyle(
                          color: Color(0xFFF5A623),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.12, end: 0.0, duration: 500.ms);
  }

  // ── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    if (_isGenerating) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary,
              ),
            ),
            SizedBox(width: 14),
            Text(
              'Generating your certificate…',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _actionBtn(
            icon: Icons.download_rounded,
            label: 'Download PDF',
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
            onTap: _download,
            isLoading: _activeAction == 'download',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.share_rounded,
            label: 'Share',
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF00C853)],
            ),
            onTap: _share,
            isLoading: _activeAction == 'share',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.preview_rounded,
            label: 'Preview',
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            ),
            onTap: _preview,
            isLoading: _activeAction == 'preview',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: _activeAction != null ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockHint() {
    final ptsNeeded = 100 - _points;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Certificate Locked',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earn $ptsNeeded more points to unlock your first certificate',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  // ── Progress Section ──────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    final progress = _currentLevel.progressTo(_points);
    final color = _currentLevel.primaryColor;
    final nextPts = _currentLevel.nextLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_points pts',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                backgroundColor: AppColors.borderGrey,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentLevel.title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _currentLevel.isMaxLevel
                    ? '🏆 Max Level!'
                    : 'Next: $nextPts pts',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (_currentLevel.isMaxLevel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👑', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'You are a CampusLift Legend!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  // ── Level Roadmap ─────────────────────────────────────────────────────────

  Widget _buildLevelRoadmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievement Roadmap',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...CertificateLevel.allLevels.asMap().entries.map((entry) {
          final i = entry.key;
          final lvl = entry.value;
          final achieved = _points >= lvl.minPoints;
          final isCurrent = lvl.level == _currentLevel.level;

          return _buildRoadmapTile(lvl, achieved, isCurrent, i);
        }),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildRoadmapTile(
    CertificateLevel lvl, bool achieved, bool isCurrent, int idx,
  ) {
    final color = lvl.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: color, width: 2)
            : Border.all(color: AppColors.borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: achieved
                ? color.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achieved
                ? color.withValues(alpha: 0.15)
                : AppColors.borderGrey.withValues(alpha: 0.5),
            border: Border.all(
              color: achieved ? color : AppColors.borderGrey,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              lvl.emoji,
              style: TextStyle(
                fontSize: 22,
                color: achieved ? null : null,
              ).copyWith(
                color: achieved ? null : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Level ${lvl.level}: ${lvl.title}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: achieved ? AppColors.textPrimary : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'CURRENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              lvl.description,
              style: TextStyle(
                fontSize: 12,
                color: achieved ? AppColors.textSecondary : AppColors.textMuted,
              ),
            ),
            Text(
              '${lvl.minPoints} pts required',
              style: TextStyle(
                fontSize: 11,
                color: achieved ? color : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: achieved
            ? Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.secondary, size: 22),
              )
            : Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.textMuted, size: 18),
              ),
      ),
    ).animate(delay: Duration(milliseconds: 80 * idx)).fadeIn(duration: 400.ms)
        .slideX(begin: -0.06, end: 0.0, duration: 350.ms);
  }
}

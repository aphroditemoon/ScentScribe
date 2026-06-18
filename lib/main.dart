
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.charcoalDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  Animate.restartOnHotReload = true;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const ScentScribeApp(),
    ),
  );
}

class ScentScribeApp extends StatelessWidget {
  const ScentScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScentScribe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashWrapper(),
    );
  }
}


class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _showSplash ? const SplashScreen() : const MainShell(),
    );
  }
}


class _PetalParticle {
  double x, y, size, speed, opacity, angle, drift;
  int petalType;
  _PetalParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
    required this.drift,
    required this.petalType,
  });
}

class _PetalPainter extends CustomPainter {
  final List<_PetalParticle> petals;
  _PetalPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final paint = Paint()
        ..color = _petalColor(petal.petalType).withOpacity(petal.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.angle);

      _drawPetal(canvas, paint, petal.size, petal.petalType);
      canvas.restore();
    }
  }

  Color _petalColor(int type) {
    final colors = [
      const Color(0xFFFFB7C5),
      const Color(0xFFFFC9D6),
      const Color(0xFFFF9EB5),
      const Color(0xFFFFE0E8),
      const Color(0xFFFFA8C0),
    ];
    return colors[type % colors.length];
  }

  void _drawPetal(Canvas canvas, Paint paint, double size, int type) {


    final w = size * 0.62;
    final h = size;

    final path = Path();
    path.moveTo(0, 0);

    path.cubicTo(
      -w * 0.95, -h * 0.08,
      -w * 0.78, -h * 0.78,
      -w * 0.14, -h * 0.92,
    );

    path.quadraticBezierTo(0, -h * 0.8, w * 0.14, -h * 0.92);

    path.cubicTo(
      w * 0.78, -h * 0.78,
      w * 0.95, -h * 0.08,
      0, 0,
    );
    path.close();

    canvas.drawPath(path, paint);


    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = size * 0.025
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -h * 0.05), Offset(0, -h * 0.78), veinPaint);
  }

  @override
  bool shouldRepaint(_PetalPainter old) => true;
}

class _FloatingPetalsWidget extends StatefulWidget {
  const _FloatingPetalsWidget();

  @override
  State<_FloatingPetalsWidget> createState() => _FloatingPetalsWidgetState();
}

class _FloatingPetalsWidgetState extends State<_FloatingPetalsWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_PetalParticle> _petals;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _petals = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update)..repeat();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPetals();
    });
  }

  void _initPetals() {
    final size = MediaQuery.of(context).size;
    _petals = List.generate(25, (i) => _randomPetal(size, fromRandom: true));
  }

  _PetalParticle _randomPetal(Size size, {bool fromRandom = false}) {

    double x, y;
    final side = _rng.nextInt(4);
    switch (side) {
      case 0:
        x = _rng.nextDouble() * size.width;
        y = fromRandom ? _rng.nextDouble() * size.height : -30;
        break;
      case 1:
        x = _rng.nextDouble() * size.width;
        y = fromRandom ? _rng.nextDouble() * size.height : size.height + 30;
        break;
      case 2:
        x = fromRandom ? _rng.nextDouble() * size.width : -30;
        y = _rng.nextDouble() * size.height;
        break;
      default:
        x = fromRandom ? _rng.nextDouble() * size.width : size.width + 30;
        y = _rng.nextDouble() * size.height;
    }

    return _PetalParticle(
      x: x,
      y: y,
      size: 14 + _rng.nextDouble() * 16,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      opacity: 0.15 + _rng.nextDouble() * 0.35,
      angle: _rng.nextDouble() * math.pi * 2,
      drift: (_rng.nextDouble() - 0.5) * 1.2,
      petalType: _rng.nextInt(3),
    );
  }

  void _update() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    for (final p in _petals) {

      p.y -= p.speed;
      p.x += p.drift * 0.5;
      p.angle += 0.01;

      if (p.y < -40 || p.x < -40 || p.x > size.width + 40) {

        final fresh = _randomPetal(size);
        p.x = fresh.x;
        p.y = fresh.y;
        p.size = fresh.size;
        p.speed = fresh.speed;
        p.opacity = fresh.opacity;
        p.drift = fresh.drift;
        p.petalType = fresh.petalType;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PetalPainter(_petals),
      size: Size.infinite,
    );
  }
}


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    Color(0xFF1A1020),
                    AppColors.obsidian,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: const _FloatingPetalsWidget(),
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFE08FC0).withOpacity(0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 168,
              height: 168,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            )
                .animate()
                .scale(
                    duration: 900.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3))
                .fadeIn(duration: 500.ms),
          ),
        ],
      ),
    );
  }
}


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _profileDialogChecked = false;
  bool _profileDialogShowing = false;

  static const List<Widget> _screens = [
    HomeScreen(),
    CollectionScreen(),
    AIScreen(),
    JournalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoading && provider.userProfile != null && !_profileDialogChecked) {
          _profileDialogChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowInitialProfilePopup(provider);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: IndexedStack(
            index: provider.selectedNavIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNav(context, provider),
        );
      },
    );
  }

  bool _isPlaceholderName(String? name) {
    final normalized = (name ?? '').trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == '-' ||
        normalized == 'moonlight' ||
        normalized == 'fragrance lover' ||
        normalized == 'scentist' ||
        normalized == 'perfume lover' ||
        normalized == 'hello';
  }

  Future<void> _maybeShowInitialProfilePopup(AppProvider provider) async {
    if (!mounted || _profileDialogShowing) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyCompleted = prefs.getBool('profile_setup_done') ?? false;
    final profile = provider.userProfile;
    final shouldShow = profile != null &&
        (!alreadyCompleted || _isPlaceholderName(profile.name));

    if (!mounted || !shouldShow) return;

    _profileDialogShowing = true;
    final saved = await _showInitialProfileDialog(provider);
    _profileDialogShowing = false;

    if (saved == true) {
      await prefs.setBool('profile_setup_done', true);
    }
  }

  Future<bool?> _showInitialProfileDialog(AppProvider provider) {
    final profile = provider.userProfile;
    final nameCtrl = TextEditingController(
      text: _isPlaceholderName(profile?.name) ? '' : (profile?.name ?? ''),
    );
    final bioCtrl = TextEditingController(text: profile?.bio ?? '');
    String? errorText;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Set Up Your Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add your name and bio so ScentScribe no longer uses a default profile name.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    errorText: errorText,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                    hintText: 'Example: Sweet gourmand lover',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => errorText = 'Name cannot be empty');
                  return;
                }

                final current = provider.userProfile;
                if (current != null) {
                  await provider.updateUserProfile(current.copyWith(
                    name: name,
                    bio: bioCtrl.text.trim(),
                    clearBio: bioCtrl.text.trim().isEmpty,
                  ));
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      bioCtrl.dispose();
    });
  }

  Widget _buildBottomNav(BuildContext context, AppProvider provider) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.local_florist_rounded, label: 'Collection'),
      _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI', isCenter: true),
      _NavItem(icon: Icons.book_rounded, label: 'Journal'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoalDark,
        border: const Border(
          top: BorderSide(color: AppColors.charcoalLight, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isSelected = provider.selectedNavIndex == i;

              if (item.isCenter) {
                return GestureDetector(
                  onTap: () => provider.setNavIndex(i),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [
                              AppColors.amethyst,
                              Color(0xFF6C3483),
                            ])
                          : AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected
                                  ? AppColors.amethyst
                                  : AppColors.gold)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(item.icon,
                        color: AppColors.obsidian, size: 24),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => provider.setNavIndex(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

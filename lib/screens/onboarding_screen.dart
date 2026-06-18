
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/perfume_model.dart';
import '../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;


  final List<String> _selectedFamilies = [];
  String _skinType = 'normal';
  String _userName = '';
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

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
                  center: Alignment(0, -0.3),
                  radius: 0.8,
                  colors: [Color(0xFF150F20), AppColors.obsidian],
                ),
              ),
            ),
          ),
          PageView(
            controller: _ctrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _buildWelcomePage(),
              _buildNamePage(),
              _buildFamilyPage(),
              _buildSkinPage(),
              _buildReadyPage(),
            ],
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.gold : AppColors.charcoalLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Center(
              child: Image.asset('assets/images/app_logo.png', width: 80, height: 80),
            ),
          ).animate().scale(
              duration: 800.ms, curve: Curves.elasticOut,
              begin: const Offset(0, 0)),
          const SizedBox(height: 32),
          Text('Welcome to\nScentScribe',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  height: 1.2)).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 16),
          Text(
            'Your personal AI fragrance intelligence.\nNever waste a blind buy again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 16, height: 1.5),
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 48),
          GoldButton(
            label: 'Get Started',
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_rounded, color: AppColors.gold, size: 60),
          const SizedBox(height: 24),
          Text('What should we call you?',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('We\'ll personalise your scent journey.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 36),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Enter your name...',
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gold),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gold, width: 2),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.charcoalLight),
              ),
              filled: false,
            ),
            onChanged: (v) => setState(() => _userName = v),
          ),
          const SizedBox(height: 48),
          GoldButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: _nameCtrl.text.trim().isEmpty ? null : _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyPage() {
    final families = {
      PerfumeFamily.fresh: ('🍃', 'Fresh', 'Clean, citrusy, airy'),
      PerfumeFamily.oriental: ('🌙', 'Oriental', 'Rich, warm, exotic'),
      PerfumeFamily.floral: ('🌸', 'Floral', 'Romantic, bloom-forward'),
      PerfumeFamily.woody: ('🌲', 'Woody', 'Earthy, grounded, natural'),
      PerfumeFamily.gourmand: ('🍫', 'Gourmand', 'Sweet, edible, cozy'),
      PerfumeFamily.aquatic: ('🌊', 'Aquatic', 'Ocean breeze, clean'),
      PerfumeFamily.chypre: ('🌺', 'Chypre', 'Mossy, sophisticated'),
      PerfumeFamily.powdery: ('✨', 'Powdery', 'Soft, retro, skin-like'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      child: Column(
        children: [
          Text('Your Fragrance Taste',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Pick families you love (select multiple)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
              children: families.entries.map((e) {
                final family = e.key;
                final info = e.value;
                final familyName = family.toString().split('.').last;
                final selected = _selectedFamilies.contains(familyName);
                final p = Perfume(
                    id: '', name: '', brand: '',
                    family: family, notes: [], addedAt: DateTime.now());

                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedFamilies.remove(familyName);
                    } else {
                      _selectedFamilies.add(familyName);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? p.familyColor.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? p.familyColor
                            : AppColors.charcoalLight,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(info.$1,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(info.$2,
                                  style: TextStyle(
                                      color: selected
                                          ? p.familyColor
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(info.$3,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          GoldButton(
            label: _selectedFamilies.isEmpty ? 'Skip' : 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildSkinPage() {
    final skinTypes = {
      'dry': ('🏜️', 'Dry', 'Scents fade faster. Moisturise first.'),
      'normal': ('✅', 'Normal', 'Balanced performance.'),
      'oily': ('💧', 'Oily', 'Scents last longer on you.'),
      'combination': ('🔀', 'Combination', 'Varies by body area.'),
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Your Skin Type',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Skin chemistry affects how fragrances perform and last.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 32),
          ...skinTypes.entries.map((e) {
            final selected = _skinType == e.key;
            return GestureDetector(
              onTap: () => setState(() => _skinType = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.gold
                        : AppColors.charcoalLight,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(e.value.$1,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.$2,
                              style: TextStyle(
                                  color: selected
                                      ? AppColors.gold
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(e.value.$3,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.gold, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          GoldButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 80)
              .animate().scale(
                  duration: 800.ms, curve: Curves.elasticOut,
                  begin: const Offset(0, 0)),
          const SizedBox(height: 24),
          Text('You\'re all set,\n${_nameCtrl.text.trim().isEmpty ? '-' : _nameCtrl.text.trim()}!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w600))
              .animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 16),
          const Text(
            'Your AI scent profile is ready.\nStart by adding your first perfume to your collection.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 40),
          GoldButton(
            label: 'Enter ScentScribe',
            icon: Icons.arrow_forward_rounded,
            onTap: _complete,
          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),
        ],
      ),
    );
  }

  void _nextPage() {
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _complete() async {
    final provider = context.read<AppProvider>();
    final name = _nameCtrl.text.trim().isEmpty
        ? '-'
        : _nameCtrl.text.trim();


    final currentProfile = provider.userProfile;
    if (currentProfile != null) {
      final updated = currentProfile.copyWith(
        name: name,
        skinType: _skinType,
        preferredFamilies: _selectedFamilies,
        preferredNotes: const [],
        avoidedNotes: const [],
      );
      await provider.updateUserProfile(updated);
    }


    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    widget.onComplete();
  }
}


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/perfume_model.dart';
import '../services/ml_engine.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final profile = provider.userProfile;
        final scentProfile = provider.scentProfile;

        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, provider, profile),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (scentProfile != null) ...[
                      _buildScentDNA(scentProfile),
                      const SizedBox(height: 20),
                    ],
                    _buildFamilyDistribution(provider),
                    const SizedBox(height: 20),
                    _buildSkinPreferences(context, provider, profile),
                    const SizedBox(height: 20),
                    _buildSettings(context, provider, profile),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider,
      UserProfile? profile) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.obsidian,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F0A18), AppColors.obsidian],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.gold.withOpacity(0.1),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: () => _showProfilePhotoOptions(context, provider, profile),
                      child: Stack(
                        children: [
                          _buildAvatar(profile),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.obsidian, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.obsidian, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 10),
                    Text(
                      profile?.name ?? '-',
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (profile?.bio != null && profile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          profile.bio!,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      provider.scentProfile?.profileType ??
                          'Discovering your scent identity...',
                      style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile? profile) {
    if (profile?.photoPath != null && profile!.photoPath!.isNotEmpty) {
      final file = File(profile.photoPath!);
      if (file.existsSync()) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.file(file, fit: BoxFit.cover,
                width: 80, height: 80),
          ),
        );
      }
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Text(
          profile?.name.isNotEmpty == true
              ? profile!.name[0].toUpperCase()
              : 'S',
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.obsidian,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showProfilePhotoOptions(BuildContext context, AppProvider provider, UserProfile? profile) {
    if (profile == null) return;
    final hasPhoto = profile.photoPath != null && profile.photoPath!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.charcoalLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Text('Profile Photo',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              _photoAction(
                icon: Icons.photo_library_rounded,
                title: hasPhoto ? 'Change Photo' : 'Upload Photo',
                subtitle: 'Choose an image from your gallery',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickProfilePhoto(context, provider, profile);
                },
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 10),
                _photoAction(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  subtitle: 'Return to initial avatar letter',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await _removeProfilePhoto(provider, profile);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.roseGold : AppColors.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.charcoalLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto(BuildContext context, AppProvider provider, UserProfile profile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final dest = File('${appDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(dest.path);

    final oldPath = profile.photoPath;
    if (oldPath != null && oldPath.isNotEmpty && oldPath != dest.path) {
      try {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) await oldFile.delete();
      } catch (_) {}
    }

    await provider.updateUserProfile(profile.copyWith(photoPath: dest.path));
  }

  Future<void> _removeProfilePhoto(AppProvider provider, UserProfile profile) async {
    final oldPath = profile.photoPath;
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) await oldFile.delete();
      } catch (_) {}
    }
    await provider.updateUserProfile(profile.copyWith(clearPhotoPath: true));
  }

  Widget _buildScentDNA(ScentProfile sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Your Scent DNA',
          subtitle: 'AI-analyzed from your collection',
        ),
        const SizedBox(height: 14),
        GlassCard(
          borderColor: AppColors.gold.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        AppColors.gold,
                        Color(0xFFB8860B),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getDominantIcon(sp.dominantFamily),
                      color: AppColors.obsidian,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sp.profileType,
                          style: GoogleFonts.cormorantGaramond(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${sp.totalPerfumes} scents · avg ★${sp.averageRating.toStringAsFixed(1)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (sp.topNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Signature Notes',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sp.topNotes
                      .take(5)
                      .map((n) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3)),
                            ),
                            child: Text(n,
                                style: const TextStyle(
                                    color: AppColors.gold, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  IconData _getDominantIcon(PerfumeFamily? family) {
    if (family == null) return Icons.star_rounded;
    switch (family) {
      case PerfumeFamily.floral: return Icons.local_florist_rounded;
      case PerfumeFamily.woody: return Icons.park_rounded;
      case PerfumeFamily.oriental: return Icons.auto_awesome_rounded;
      case PerfumeFamily.fresh: return Icons.ac_unit_rounded;
      case PerfumeFamily.citrus: return Icons.wb_sunny_rounded;
      case PerfumeFamily.aquatic: return Icons.waves_rounded;
      default: return Icons.spa_rounded;
    }
  }

  Widget _buildFamilyDistribution(AppProvider provider) {
    final dist = provider.getFamilyDistribution();
    if (dist.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Collection Breakdown'),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            children: dist.entries.map((e) {
              final family = PerfumeFamily.values.firstWhere(
                (f) => f.toString().split('.').last == e.key,
                orElse: () => PerfumeFamily.fresh,
              );
              final p = Perfume(
                  id: '',
                  name: '',
                  brand: '',
                  family: family,
                  notes: [],
                  addedAt: DateTime.now());
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(_getFamilyIcon(family),
                        color: p.familyColor, size: 18),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value,
                          backgroundColor: AppColors.charcoalLight,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(p.familyColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(e.value * 100).toInt()}%',
                      style: TextStyle(
                          color: p.familyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  IconData _getFamilyIcon(PerfumeFamily family) {
    switch (family) {
      case PerfumeFamily.floral: return Icons.local_florist_rounded;
      case PerfumeFamily.woody: return Icons.park_rounded;
      case PerfumeFamily.oriental: return Icons.auto_awesome_rounded;
      case PerfumeFamily.fresh: return Icons.ac_unit_rounded;
      case PerfumeFamily.citrus: return Icons.wb_sunny_rounded;
      case PerfumeFamily.aquatic: return Icons.waves_rounded;
      default: return Icons.spa_rounded;
    }
  }

  Widget _buildSkinPreferences(BuildContext context, AppProvider provider,
      UserProfile? profile) {
    final skinTypes = ['dry', 'normal', 'oily', 'combination'];
    final currentSkin = profile?.skinType ?? 'normal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Skin Profile',
          subtitle: 'Affects AI longevity predictions',
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Skin Type',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 10),
              Row(
                children: skinTypes.map((t) {
                  final selected = currentSkin == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (profile != null) {
                          final updated = profile.copyWith(skinType: t);
                          provider.updateUserProfile(updated);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.gold.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.gold
                                : AppColors.charcoalLight,
                          ),
                        ),
                        child: Text(
                          t[0].toUpperCase() + t.substring(1),
                          style: TextStyle(
                            color: selected
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _skinTip(currentSkin),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppProvider provider, UserProfile? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Settings'),
        const SizedBox(height: 14),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsTile(
                  Icons.person_rounded,
                  'Edit Profile',
                  'Update name, bio & photo',
                  () => _showEditProfile(context, provider)),
              if (profile != null && profile.photoPath != null && profile.photoPath!.isNotEmpty) ...[
                _divider(),
                _settingsTile(
                    Icons.delete_outline_rounded,
                    'Remove Profile Photo',
                    'Delete current profile photo',
                    () => _removeProfilePhoto(provider, profile)),
              ],
              _divider(),
              _settingsTile(
                  Icons.info_outline_rounded,
                  'About ScentScribe',
                  'v1.0.0',
                  () => _showAbout(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.gold, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 0.5, color: AppColors.charcoalLight),
      );

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.charcoalLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              'ScentScribe',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text('v1.0.0 · AI-Powered Fragrance Ecosystem',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Icon(Icons.favorite_rounded,
                            color: AppColors.roseGold, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          'Made by',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Erlangga Putra Mahardika',
                          style: GoogleFonts.cormorantGaramond(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close',
                            style: TextStyle(color: AppColors.gold)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.charcoalLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        color: AppColors.roseGold, size: 16),
                    const SizedBox(width: 8),
                    const Text('Tap to see who made this',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AppProvider provider) {
    final profile = provider.userProfile;
    final nameCtrl = TextEditingController(text: profile?.name ?? '');
    final bioCtrl = TextEditingController(text: profile?.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.charcoalLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.gold),
                hintText: 'A few words about your scent journey...',
              ),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Save Changes',
              width: double.infinity,
              onTap: () {
                if (profile != null && nameCtrl.text.trim().isNotEmpty) {
                  final updated = profile.copyWith(
                    name: nameCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                    clearBio: bioCtrl.text.trim().isEmpty,
                  );
                  provider.updateUserProfile(updated);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _skinTip(String skinType) {
    switch (skinType) {
      case 'dry':
        return 'Dry skin absorbs fragrance quickly. Apply unscented moisturizer first, or spray on clothes for better longevity.';
      case 'oily':
        return 'Oily skin retains fragrance longer and may amplify base notes. You might need fewer sprays than average.';
      case 'combination':
        return 'Apply to oilier areas (neck, chest) for maximum longevity, and lighter sprays on drier areas.';
      default:
        return 'Normal skin has balanced sebum that allows fragrances to perform close to their intended projection and longevity.';
    }
  }
}

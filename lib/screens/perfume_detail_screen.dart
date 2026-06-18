
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';
import '../services/ml_engine.dart';
import 'add_journal_screen.dart';

class PerfumeDetailScreen extends StatefulWidget {
  final String perfumeId;
  const PerfumeDetailScreen({super.key, required this.perfumeId});

  @override
  State<PerfumeDetailScreen> createState() => _PerfumeDetailScreenState();
}

class _PerfumeDetailScreenState extends State<PerfumeDetailScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final perfume = provider.getPerfumeById(widget.perfumeId);
        if (perfume == null) {
          return const Scaffold(
            body: Center(child: Text('Perfume not found')),
          );
        }

        final entries = provider.getEntriesForPerfume(perfume.id);
        final prediction = provider.predictPerformance(perfume);

        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHero(context, perfume, provider),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoSection(perfume),
                    const SizedBox(height: 20),
                    _buildMLPredictionCard(prediction, provider.weather),
                    const SizedBox(height: 20),
                    _buildNotesSection(perfume),
                    const SizedBox(height: 20),
                    _buildSeasonSection(perfume),
                    const SizedBox(height: 20),
                    _buildJournalSection(context, perfume, entries, provider),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(context, perfume),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, Perfume p, AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.obsidian,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => provider.toggleWishlist(p.id),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              p.isWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: p.isWishlist ? AppColors.roseGold : AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showDeleteDialog(context, p.id, provider),
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_horiz_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.familyColor.withOpacity(0.4),
                p.familyColor.withOpacity(0.1),
                AppColors.obsidian,
              ],
            ),
          ),
          child: Stack(
            children: [

              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        p.familyColor.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 132,
                      height: 152,
                      child: PerfumeBottleImage(
                        perfumeName: p.name,
                        brand: p.brand,
                        imageUrl: p.imageUrl,
                        imagePath: p.imagePath,
                        backgroundColor: Colors.transparent,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(4),
                      ),
                    ).animate().scale(
                          duration: 800.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 12),
                    Text(
                      p.name,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      p.brand.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildInfoSection(Perfume p) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _infoTile('Family', p.familyEmoji + ' ' + p.family.toString().split('.').last)),
              Expanded(child: _infoTile('Rating', '${p.rating}/5.0 ⭐')),
              if (p.mlOwned != null)
                Expanded(child: _infoTile('Volume', '${p.mlOwned!.toInt()} ml')),
            ],
          ),
          if (p.perfumer != null || p.launchYear != null) ...[
            const Divider(color: AppColors.charcoalLight),
            Row(
              children: [
                if (p.perfumer != null)
                  Expanded(child: _infoTile('Perfumer', p.perfumer!)),
                if (p.launchYear != null)
                  Expanded(child: _infoTile('Year', '${p.launchYear}')),
                if (p.countryOfOrigin != null)
                  Expanded(child: _infoTile('Origin', p.countryOfOrigin!)),
              ],
            ),
          ],
          if (p.description != null) ...[
            const Divider(color: AppColors.charcoalLight),
            Text(
              p.description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMLPredictionCard(
      PerformancePrediction pred, WeatherSnapshot? weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AI PREDICTION',
                style: TextStyle(
                  color: AppColors.obsidian,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (weather != null)
              Text(
                '${weather.emoji} ${weather.temperature.toInt()}°C · ${weather.humidity.toInt()}% humid',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          borderColor: AppColors.gold.withOpacity(0.2),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _predictionStat(
                    icon: Icons.timer_outlined,
                    label: 'Longevity',
                    value: '${pred.estimatedLongevityHours.toStringAsFixed(1)}h',
                    color: AppColors.gold,
                  ),
                  Container(width: 0.5, height: 50, color: AppColors.charcoalLight),
                  _predictionStat(
                    icon: Icons.air_rounded,
                    label: 'Sillage',
                    value: '${pred.estimatedSillage.toStringAsFixed(1)}/10',
                    color: AppColors.amethyst,
                  ),
                  Container(width: 0.5, height: 50, color: AppColors.charcoalLight),
                  _predictionStat(
                    icon: Icons.radio_button_checked_rounded,
                    label: 'Projection',
                    value: pred.projectionRadius,
                    color: AppColors.roseGold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.15), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pred.applicationTip,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _predictionStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildNotesSection(Perfume p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Fragrance Notes'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.topNotes.isNotEmpty)
                _noteCategory('Top Notes', p.topNotes, AppColors.topNote, '🕐 Opens in 0–30 min'),
              if (p.heartNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                _noteCategory('Heart Notes', p.heartNotes, AppColors.heartNote, '💫 Reveals in 30 min – 4h'),
              ],
              if (p.baseNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                _noteCategory('Base Notes', p.baseNotes, AppColors.baseNote, '🌙 Stays 4h+'),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _noteCategory(String label, List<FragranceNote> notes,
      Color color, String timeline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(timeline,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: notes.map((n) => NotePill(note: n)).toList(),
        ),
      ],
    );
  }

  Widget _buildSeasonSection(Perfume p) {
    if (p.bestSeasons.isEmpty && p.bestTimes.isEmpty) return const SizedBox();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.bestSeasons.isNotEmpty) ...[
            const Text('Best Seasons',
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: p.bestSeasons.map((s) {
                final emojis = {
                  Season.spring: '🌸 Spring',
                  Season.summer: '☀️ Summer',
                  Season.autumn: '🍂 Autumn',
                  Season.winter: '❄️ Winter',
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(emojis[s]!,
                      style: const TextStyle(
                          color: AppColors.gold, fontSize: 12)),
                );
              }).toList(),
            ),
          ],
          if (p.bestTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Best Times',
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: p.bestTimes.map((t) {
                final emojis = {
                  ScentTimeOfDay.morning: '🌅 Morning',
                  ScentTimeOfDay.afternoon: '🌤️ Afternoon',
                  ScentTimeOfDay.evening: '🌆 Evening',
                  ScentTimeOfDay.night: '🌙 Night',
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amethyst.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.amethyst.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(emojis[t]!,
                      style: const TextStyle(
                          color: AppColors.amethystLight, fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalSection(BuildContext context, Perfume p,
      List<JournalEntry> entries, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Scent Log',
          subtitle: '${entries.length} entries',
          trailing: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddJournalScreen(perfumeId: p.id)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '+ Log',
                style: TextStyle(
                  color: AppColors.obsidian,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          GlassCard(
            child: const EmptyState(
              icon: Icons.book_outlined,
              title: 'No logs yet',
              subtitle: 'Tap "+ Log" to record today\'s wear.',
            ),
          )
        else
          ...entries.map((e) => _buildJournalCard(e)),
      ],
    );
  }

  Widget _buildJournalCard(JournalEntry entry) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatDate(entry.date),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (entry.weather != null)
                Text(
                  '${entry.weather!.emoji} ${entry.weather!.temperature.toInt()}°C',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ratingBar('Longevity', entry.longevityRating, AppColors.gold),
              const SizedBox(width: 12),
              _ratingBar('Sillage', entry.sillageRating, AppColors.amethyst),
              const SizedBox(width: 12),
              _ratingBar('Projection', entry.projectionRating, AppColors.roseGold),
            ],
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes!,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4),
            ),
          ],
          if (entry.moods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: entry.moods
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(m,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingBar(String label, int rating, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: rating / 10,
            backgroundColor: AppColors.charcoalLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
          const SizedBox(height: 2),
          Text('$rating/10',
              style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, Perfume p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddJournalScreen(perfumeId: p.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.obsidian),
            SizedBox(width: 8),
            Text('Log Today\'s Wear',
                style: TextStyle(
                    color: AppColors.obsidian,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.charcoalLight,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: const Text('Remove from Collection',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                provider.deletePerfume(id);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded,
                  color: AppColors.textMuted),
              title: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

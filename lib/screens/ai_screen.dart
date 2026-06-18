
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
import 'perfume_detail_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<String> _layeringIds = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              _buildAppBar(context, provider),
              SliverToBoxAdapter(child: _buildTabBar()),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRecommendationsTab(provider),
                _buildLayeringTab(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    final weather = provider.weather;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.obsidian,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF130D1F), AppColors.obsidian],
            ),
          ),
          child: Stack(
            children: [

              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.amethyst.withOpacity(0.12),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              AppColors.amethyst,
                              Color(0xFF6C3483),
                            ]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('AI ENGINE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Scent Intelligence',
                        style: GoogleFonts.cormorantGaramond(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600)),
                    if (weather != null)
                      Text(
                        '${weather.emoji} ${weather.temperature.toInt()}°C · ${weather.humidity.toInt()}% RH · ${provider.timeOfDay}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.amethyst, Color(0xFF6C3483)]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: '🔮 Daily Picks'),
          Tab(text: '🧪 Layering Lab'),
        ],
      ),
    );
  }


  Widget _buildRecommendationsTab(AppProvider provider) {
    final recs = provider.getRecommendations();

    if (provider.collection.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'No collection yet',
        subtitle:
            'Add perfumes to your collection to get AI-powered weather recommendations.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildWeatherInsightCard(provider),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Ranked by Weather Match',
          subtitle: 'Tap any card to see full details & predictions',
        ),
        const SizedBox(height: 14),
        ...recs.asMap().entries.map(
            (e) => _buildRecCard(context, e.value, e.key)),
      ],
    );
  }

  Widget _buildWeatherInsightCard(AppProvider provider) {
    final w = provider.weather;
    final time = provider.timeOfDay;
    if (w == null) return const SizedBox();

    String headline;
    String detail;
    Color accent;

    if (w.isHot && w.isHumid) {
      headline = 'Hot & Humid — Go Airy';
      detail =
          'High temp (${w.temperature.toInt()}°C) + humidity (${w.humidity.toInt()}%) will amplify any scent heavily. Fresh, aquatic, or green fragrances are your best friends today.';
      accent = AppColors.info;
    } else if (w.isCold) {
      headline = 'Cold Weather Unlocked';
      detail =
          'At ${w.temperature.toInt()}°C, rich orientals, gourmands, and heavy woods will finally project without being cloying. Perfect for your boldest bottles.';
      accent = AppColors.amethyst;
    } else if (w.isHumid) {
      headline = 'Humidity Alert';
      detail =
          'Humidity at ${w.humidity.toInt()}% will boost your sillage significantly. Spray less than usual — 1-2 sprays max even for your lightest scents.';
      accent = AppColors.warning;
    } else {
      headline = 'Ideal Conditions';
      detail =
          '${w.temperature.toInt()}°C with ${w.humidity.toInt()}% humidity is near-perfect fragrance weather. Most of your collection will perform at its best today.';
      accent = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(headline,
                  style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildRecCard(
      BuildContext context, ScentRecommendation rec, int index) {
    final p = rec.perfume;
    final isTop = index == 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PerfumeDetailScreen(perfumeId: p.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop
                ? AppColors.amethyst.withOpacity(0.5)
                : AppColors.charcoalLight,
            width: isTop ? 1 : 0.5,
          ),
          boxShadow: isTop
              ? [
                  BoxShadow(
                      color: AppColors.amethyst.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    if (isTop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.amethyst,
                            Color(0xFF6C3483),
                          ]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('TOP',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      )
                    else
                      Text(
                        '#${index + 1}',
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 6),
                    ScoreRing(
                      score: rec.score,
                      size: 44,
                      color: isTop ? AppColors.amethyst : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: p.familyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: PerfumeBottleImage(
                  perfumeName: p.name,
                  brand: p.brand,
                  imageUrl: p.imageUrl,
                  imagePath: p.imagePath,
                  backgroundColor: Colors.transparent,
                  borderRadius: 14,
                  padding: const EdgeInsets.all(5),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(p.brand,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      rec.reason,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: rec.matchFactors
                          .take(2)
                          .map((f) => Text(f,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 80 * index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.08),
    );
  }


  Widget _buildLayeringTab(AppProvider provider) {
    final selectedPerfumes = _layeringIds
        .map((id) => provider.getPerfumeById(id))
        .whereType<Perfume>()
        .toList();

    LayeringResult? result;
    if (selectedPerfumes.length >= 2) {
      result = provider.predictLayering(selectedPerfumes);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildLayeringHeader(),
        const SizedBox(height: 16),
        _buildLayeringSelector(provider, selectedPerfumes),
        const SizedBox(height: 16),
        if (selectedPerfumes.isNotEmpty)
          _buildSelectedPerfumes(selectedPerfumes, provider),
        if (result != null) ...[
          const SizedBox(height: 20),
          _buildLayeringResult(result),
        ],
        const SizedBox(height: 20),
        _buildLayeringTips(),
      ],
    );
  }

  Widget _buildLayeringHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withOpacity(0.2), width: 0.5),
      ),
      child: const Row(
        children: [
          const Icon(Icons.science_rounded, color: AppColors.gold, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Layering Lab',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text(
                  'Select 2–3 perfumes to see AI compatibility score & predicted blend notes.',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayeringSelector(
      AppProvider provider, List<Perfume> selected) {
    final available = provider.collection
        .where((p) => !_layeringIds.contains(p.id))
        .toList();

    if (_layeringIds.length >= 3) {
      return GlassCard(
        child: const Text(
          'Max 3 perfumes selected. Remove one to add another.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Add Perfume',
          subtitle: 'Pick from your collection',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: available.isEmpty
              ? const Center(
                  child: Text('All perfumes selected',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final p = available[i];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _layeringIds.add(p.id)),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.charcoalLight, width: 0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 42,
                              height: 48,
                              child: PerfumeBottleImage(
                                perfumeName: p.name,
                                brand: p.brand,
                                imageUrl: p.imageUrl,
                                imagePath: p.imagePath,
                                backgroundColor: Colors.transparent,
                                borderRadius: 10,
                                padding: const EdgeInsets.all(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 9),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedPerfumes(
      List<Perfume> selected, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Selected Blend',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _layeringIds.clear()),
              child: const Text('Clear all',
                  style:
                      TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...selected.asMap().entries.map((e) {
          final p = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: p.familyColor.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 48,
                  child: PerfumeBottleImage(
                    perfumeName: p.name,
                    brand: p.brand,
                    imageUrl: p.imageUrl,
                    imagePath: p.imagePath,
                    backgroundColor: Colors.transparent,
                    borderRadius: 10,
                    padding: const EdgeInsets.all(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(p.brand,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _layeringIds.remove(p.id)),
                  child: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLayeringResult(LayeringResult result) {
    final scoreColor = result.score >= 80
        ? AppColors.success
        : result.score >= 60
            ? AppColors.gold
            : result.score >= 40
                ? AppColors.warning
                : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: scoreColor.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScoreRing(
                      score: result.score, size: 72, color: scoreColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _compatibilityLabel(result.score),
                          style: TextStyle(
                              color: scoreColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.analysis,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.clashWarnings.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...result.clashWarnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(w,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 12)),
                    )),
              ],
              const SizedBox(height: 14),
              const Text('Predicted Blend Notes',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.resultNotes
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
          ),
        ).animate().scale(
            begin: const Offset(0.95, 0.95),
            duration: 400.ms,
            curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildLayeringTips() {
    final tips = [
      (Icons.layers_rounded, 'Heavy base first',
          'Apply the stronger, heavier scent directly on skin first. Let it settle for 2-3 minutes.'),
      (Icons.auto_awesome_rounded, 'Lighter on top',
          'Layer the lighter fragrance on top or on different pulse points to create dimension.'),
      (Icons.thermostat_rounded, 'Test on warm skin',
          'Warmth activates the blend. Apply after a shower for the best melding of notes.'),
      (Icons.timer_rounded, 'Give it 30 min',
          'The true blend character reveals itself after the top notes evaporate. Be patient.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Layering Tips'),
        const SizedBox(height: 12),
        ...tips.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.charcoalLight, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.$1, color: AppColors.gold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.$2,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(t.$3,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _compatibilityLabel(double score) {
    if (score >= 85) return '🌟 Exceptional Harmony';
    if (score >= 70) return '✅ Good Compatibility';
    if (score >= 50) return '⚠️ Mixed Result';
    return '❌ Challenging Pairing';
  }
}

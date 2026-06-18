
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';
import 'perfume_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, provider),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildWeatherCard(context, provider),
                    const SizedBox(height: 28),
                    _buildQuickStats(context, provider),
                    const SizedBox(height: 28),
                    _buildTodayRecommendations(context, provider),
                    const SizedBox(height: 28),
                    _buildRecentJournal(context, provider),
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

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider) {
    final timeOfDay = provider.timeOfDay;
    final greeting = _getGreeting(timeOfDay);

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.obsidian,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              provider.userProfile?.name ?? '-',
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        background: Stack(
          children: [

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF1A1020),
                      AppColors.obsidian,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 48,
              right: 20,
              child: Text(
                'ScentScribe',
                style: GoogleFonts.cormorantGaramond(
                  color: AppColors.gold.withOpacity(0.3),
                  fontSize: 13,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, AppProvider provider) {
    final weather = provider.weather;
    final timeOfDay = provider.timeOfDay;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          weather?.emoji ?? '🌤️',
                          style: const TextStyle(fontSize: 36),
                        ).animate().scale(
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather != null
                                  ? '${weather.temperature.toInt()}°C'
                                  : '--°C',
                              style: GoogleFonts.cormorantGaramond(
                                color: AppColors.textPrimary,
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              weather?.condition ?? 'Loading...',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _weatherStat(
                            '💧', '${weather?.humidity.toInt() ?? '--'}%',
                            'Humidity'),
                        const SizedBox(width: 16),
                        if (weather?.feelsLike != null)
                          _weatherStat('🌡️',
                              '${weather!.feelsLike!.toInt()}°',
                              'Feels like'),
                        const SizedBox(width: 16),
                        _weatherStat('🕐', _capitalise(timeOfDay), 'Now'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => provider.refreshWeather(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.charcoalLight, width: 0.5),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  if (weather?.city != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      weather!.city!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (weather != null) ...[
            const SizedBox(height: 14),
            Container(
              height: 0.5,
              color: AppColors.charcoalLight,
            ),
            const SizedBox(height: 14),
            _buildWeatherInsight(weather, timeOfDay),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _weatherStat(String emoji, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildWeatherInsight(WeatherSnapshot weather, String time) {
    String insight;
    if (weather.isHot && weather.isHumid) {
      insight = '🔥 Hot & humid — go light! Fresh or aquatic scents shine today.';
    } else if (weather.isHot) {
      insight = '☀️ Warm day — citrus and aquatics will perform beautifully.';
    } else if (weather.isCold) {
      insight = '❄️ Cold weather boosts longevity — perfect for oriental & woody scents.';
    } else if (weather.isHumid) {
      insight = '💧 High humidity will amplify your sillage — spray lightly!';
    } else {
      insight = '✨ Great conditions today — most of your collection will perform well.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.gold.withOpacity(0.15), width: 0.5),
      ),
      child: Text(
        insight,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppProvider provider) {
    final stats = [
      {
        'label': 'Collection',
        'value': '${provider.collection.length}',
        'icon': Icons.local_florist_rounded,
        'color': AppColors.gold,
      },
      {
        'label': 'Wishlist',
        'value': '${provider.wishlist.length}',
        'icon': Icons.favorite_rounded,
        'color': AppColors.amethyst,
      },
      {
        'label': 'Logs',
        'value': '${provider.journalEntries.length}',
        'icon': Icons.book_rounded,
        'color': AppColors.roseGold,
      },
      {
        'label': 'Profile',
        'value': provider.scentProfile?.profileType.split(' ').first ?? '—',
        'icon': Icons.auto_awesome_rounded,
        'color': AppColors.success,
      },
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        final stat = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < stats.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.charcoalLight, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(stat['icon'] as IconData,
                    color: stat['color'] as Color, size: 22),
                const SizedBox(height: 4),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    color: stat['color'] as Color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 100 * e.key))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2),
        );
      }).toList(),
    );
  }

  Widget _buildTodayRecommendations(BuildContext context, AppProvider provider) {
    final recs = provider.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Today\'s Picks',
          subtitle: 'AI-curated for ${provider.weather?.condition ?? 'today\'s'} weather',
          trailing: TextButton(
            onPressed: () => provider.setNavIndex(1),
            child: const Text('See all',
                style: TextStyle(color: AppColors.gold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),
        if (recs.isEmpty)
          EmptyState(
            icon: Icons.auto_awesome_rounded,
            title: 'Add perfumes first',
            subtitle: 'Your AI picks will appear here once you add scents to your collection.',
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recs.length,
              itemBuilder: (context, i) => _buildRecommendationCard(
                  context, recs[i], i),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, ScentRecommendation rec, int index) {
    final p = rec.perfume;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PerfumeDetailScreen(perfumeId: p.id)),
      ),
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 14, left: index == 0 ? 0 : 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: index == 0
                ? AppColors.gold.withOpacity(0.4)
                : AppColors.charcoalLight,
            width: index == 0 ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    p.familyColor.withOpacity(0.3),
                    p.familyColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 74,
                      height: 92,
                      child: PerfumeBottleImage(
                        perfumeName: p.name,
                        brand: p.brand,
                        imageUrl: p.imageUrl,
                        imagePath: p.imagePath,
                        backgroundColor: Colors.transparent,
                        borderRadius: 14,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.obsidian.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${rec.score.toInt()}%',
                        style: TextStyle(
                          color: _scoreColor(rec.score),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('TOP',
                            style: TextStyle(
                                color: AppColors.obsidian,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.brand,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rec.reason,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1),
    );
  }

  Widget _buildRecentJournal(BuildContext context, AppProvider provider) {
    final entries = provider.journalEntries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Logs',
          subtitle: 'Your scent diary',
          trailing: TextButton(
            onPressed: () => provider.setNavIndex(2),
            child: const Text('View all',
                style: TextStyle(color: AppColors.gold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          GlassCard(
            child: const EmptyState(
              icon: Icons.book_outlined,
              title: 'No logs yet',
              subtitle: 'Start logging your daily scent wear to track performance.',
            ),
          )
        else
          ...entries.asMap().entries.map((e) =>
              _buildJournalRow(context, e.value, provider, e.key)),
      ],
    );
  }

  Widget _buildJournalRow(BuildContext context, JournalEntry entry,
      AppProvider provider, int index) {
    final perfume = provider.getPerfumeById(entry.perfumeId);
    if (perfume == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: perfume.familyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PerfumeBottleImage(
              perfumeName: perfume.name,
              brand: perfume.brand,
              imageUrl: perfume.imageUrl,
              imagePath: perfume.imagePath,
              backgroundColor: Colors.transparent,
              borderRadius: 12,
              padding: const EdgeInsets.all(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(perfume.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  _formatDate(entry.date),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.textMuted, size: 12),
                const SizedBox(width: 3),
                Text('${entry.longevityRating}/10',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.air_rounded,
                    color: AppColors.textMuted, size: 12),
                const SizedBox(width: 3),
                Text('${entry.sillageRating}/10',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms);
  }

  String _getGreeting(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning': return 'GOOD MORNING';
      case 'afternoon': return 'GOOD AFTERNOON';
      case 'evening': return 'GOOD EVENING';
      default: return 'GOOD NIGHT';
    }
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.gold;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

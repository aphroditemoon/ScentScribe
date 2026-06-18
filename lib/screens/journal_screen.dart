
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';
import 'add_journal_screen.dart';
import 'perfume_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildTabBar()),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLogTab(provider),
                _buildAnalyticsTab(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.obsidian,
      title: Text('Scent Journal',
          style: GoogleFonts.cormorantGaramond(
              fontSize: 22, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelColor: AppColors.obsidian,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Log'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }


  Widget _buildLogTab(AppProvider provider) {
    final entries = provider.journalEntries;

    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.book_outlined,
        title: 'Your journal is empty',
        subtitle: 'Start logging your daily fragrance wear to track performance over time.',
        action: GoldButton(
          label: 'Log Today',
          icon: Icons.add_rounded,
          onTap: provider.collection.isEmpty
              ? null
              : () => _selectPerfumeToLog(context, provider),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, i) =>
          _buildEntryCard(context, entries[i], provider, i),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry,
      AppProvider provider, int index) {
    final perfume = provider.getPerfumeById(entry.perfumeId);
    if (perfume == null) return const SizedBox();

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        provider.deleteJournalEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log entry deleted')),
        );
      },
      child: GestureDetector(
        onLongPress: () => _showEntryOptions(context, entry, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.charcoalLight, width: 0.5),
          ),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: perfume.familyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: PerfumeBottleImage(
                        perfumeName: perfume.name,
                        brand: perfume.brand,
                        imageUrl: perfume.imageUrl,
                        imagePath: perfume.imagePath,
                        backgroundColor: Colors.transparent,
                        borderRadius: 13,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(perfume.brand,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(entry.date),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        if (entry.weather != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${entry.weather!.emoji} ${entry.weather!.temperature.toInt()}°C',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: () => _showEntryOptions(context, entry, provider),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.more_vert_rounded,
                            color: AppColors.textMuted, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _compactRatingRow(
                        'Longevity', entry.longevityRating, AppColors.gold),
                    const SizedBox(height: 6),
                    _compactRatingRow(
                        'Sillage', entry.sillageRating, AppColors.amethyst),
                    const SizedBox(height: 6),
                    _compactRatingRow('Projection',
                        entry.projectionRating, AppColors.roseGold),
                    if (entry.notes != null &&
                        entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          entry.notes!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ],
                    if (entry.moods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: entry.moods
                            .map((m) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.amethyst
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.amethyst
                                            .withOpacity(0.2)),
                                  ),
                                  child: Text(m,
                                      style: const TextStyle(
                                          color: AppColors.amethystLight,
                                          fontSize: 10)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.05),
    );
  }

  void _showEntryOptions(BuildContext context, JournalEntry entry, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.charcoalLight,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.gold),
              title: const Text('Edit Entry',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showEditEntry(context, entry, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Delete Entry',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Entry?',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('This cannot be undone.',
                        style: TextStyle(color: AppColors.textMuted)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          provider.deleteJournalEntry(entry.id);
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditEntry(BuildContext context, JournalEntry entry, AppProvider provider) {
    int longevity = entry.longevityRating;
    int sillage = entry.sillageRating;
    int projection = entry.projectionRating;
    final notesCtrl = TextEditingController(text: entry.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.charcoalLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Edit Log Entry',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _editSlider(ctx, setModal, 'Longevity', longevity, AppColors.gold,
                  (v) => longevity = v),
              _editSlider(ctx, setModal, 'Sillage', sillage, AppColors.amethyst,
                  (v) => sillage = v),
              _editSlider(ctx, setModal, 'Projection', projection, AppColors.roseGold,
                  (v) => projection = v),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 20),
              GoldButton(
                label: 'Save',
                width: double.infinity,
                onTap: () async {
                  final updated = JournalEntry(
                    id: entry.id,
                    perfumeId: entry.perfumeId,
                    date: entry.date,
                    longevityRating: longevity,
                    sillageRating: sillage,
                    projectionRating: projection,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    moods: entry.moods,
                    moodRating: entry.moodRating,
                    weather: entry.weather,
                    temperature: entry.temperature,
                    humidity: entry.humidity,
                    occasion: entry.occasion,
                  );
                  await provider.updateJournalEntry(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editSlider(BuildContext context, StateSetter setModal,
      String label, int value, Color color, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80,
              child: Text(label, style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12))),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 1, max: 10, divisions: 9,
              activeColor: color,
              inactiveColor: AppColors.charcoalLight,
              onChanged: (v) => setModal(() => onChanged(v.round())),
            ),
          ),
          SizedBox(width: 24,
              child: Text('$value', style: TextStyle(
                  color: color, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _compactRatingRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              backgroundColor: AppColors.charcoalLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }


  Widget _buildAnalyticsTab(AppProvider provider) {
    final entries = provider.journalEntries;
    final collection = provider.collection;

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No data yet',
        subtitle: 'Log some wear sessions to see your performance analytics.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSummaryStats(entries, collection),
        const SizedBox(height: 20),
        _buildPerformanceChart(entries, provider),
        const SizedBox(height: 20),
        _buildTopPerformers(entries, provider),
        const SizedBox(height: 20),
        _buildWeatherCorrelation(entries),
      ],
    );
  }

  Widget _buildSummaryStats(
      List<JournalEntry> entries, List<Perfume> collection) {
    final avgLongevity =
        entries.map((e) => e.longevityRating).reduce((a, b) => a + b) /
            entries.length;
    final avgSillage =
        entries.map((e) => e.sillageRating).reduce((a, b) => a + b) /
            entries.length;
    final avgProjection = entries
            .map((e) => e.projectionRating)
            .reduce((a, b) => a + b) /
        entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard('Avg Longevity',
                  avgLongevity.toStringAsFixed(1), '/10', AppColors.gold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Avg Sillage',
                  avgSillage.toStringAsFixed(1), '/10', AppColors.amethyst),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Total Logs', '${entries.length}', '',
                  AppColors.roseGold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
      String label, String value, String suffix, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value + suffix,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(
      List<JournalEntry> entries, AppProvider provider) {
    final recent = entries.take(7).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Performance Trend',
          subtitle: 'Last 7 entries',
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.charcoalLight.withOpacity(0.4),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= recent.length)
                          return const SizedBox();
                        return Text(
                          '${recent[i].date.day}/${recent[i].date.month}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (recent.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  _lineData(
                    recent.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(),
                            e.value.longevityRating.toDouble()))
                        .toList(),
                    AppColors.gold,
                  ),
                  _lineData(
                    recent.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(),
                            e.value.sillageRating.toDouble()))
                        .toList(),
                    AppColors.amethyst,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend('Longevity', AppColors.gold),
            const SizedBox(width: 20),
            _legend('Sillage', AppColors.amethyst),
          ],
        ),
      ],
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeColor: AppColors.obsidian,
          strokeWidth: 1.5,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildTopPerformers(
      List<JournalEntry> entries, AppProvider provider) {

    final scores = <String, List<double>>{};
    for (final e in entries) {
      scores.putIfAbsent(e.perfumeId, () => []);
      scores[e.perfumeId]!.add(e.overallScore);
    }
    final ranked = scores.entries
        .map((e) => MapEntry(
            e.key,
            e.value.reduce((a, b) => a + b) / e.value.length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Top Performers'),
        const SizedBox(height: 12),
        ...ranked.take(3).toList().asMap().entries.map((e) {
          final perfume = provider.getPerfumeById(e.value.key);
          if (perfume == null) return const SizedBox();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.charcoalLight, width: 0.5),
            ),
            child: Row(
              children: [
                Text('#${e.key + 1}',
                    style: TextStyle(
                        color: e.key == 0
                            ? AppColors.gold
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  height: 42,
                  child: PerfumeBottleImage(
                    perfumeName: perfume.name,
                    brand: perfume.brand,
                    imageUrl: perfume.imageUrl,
                    imagePath: perfume.imagePath,
                    backgroundColor: Colors.transparent,
                    borderRadius: 10,
                    padding: const EdgeInsets.all(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(perfume.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(perfume.brand,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '${e.value.value.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeatherCorrelation(List<JournalEntry> entries) {
    final hot = entries
        .where((e) =>
            e.temperature != null && e.temperature! >= 30)
        .toList();
    final mild = entries
        .where((e) =>
            e.temperature != null &&
            e.temperature! >= 20 &&
            e.temperature! < 30)
        .toList();
    final cool = entries
        .where((e) =>
            e.temperature != null && e.temperature! < 20)
        .toList();

    double avg(List<JournalEntry> list) => list.isEmpty
        ? 0
        : list.map((e) => e.longevityRating.toDouble()).reduce((a, b) => a + b) /
            list.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Weather vs Longevity',
          subtitle: 'How temperature affects your fragrances',
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _weatherCorrelRow('🔥 Hot (30°C+)', avg(hot), hot.length),
              const SizedBox(height: 10),
              _weatherCorrelRow('🌤️ Mild (20–30°C)', avg(mild), mild.length),
              const SizedBox(height: 10),
              _weatherCorrelRow('❄️ Cool (<20°C)', avg(cool), cool.length),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherCorrelRow(String label, double avg, int count) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: count > 0 ? avg / 10 : 0,
                  backgroundColor: AppColors.charcoalLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    avg >= 7
                        ? AppColors.success
                        : avg >= 5
                            ? AppColors.gold
                            : AppColors.error,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count > 0
                    ? '${avg.toStringAsFixed(1)}/10 · $count entries'
                    : 'No data',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectPerfumeToLog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.charcoalLight,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Select Perfume to Log',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...provider.collection.take(6).map((p) => ListTile(
                leading: SizedBox(
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
                title: Text(p.name,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(p.brand,
                    style: const TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddJournalScreen(perfumeId: p.id)),
                  );
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} · ${_timeStr(date)}';
  }

  String _timeStr(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

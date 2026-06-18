
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';

class AddJournalScreen extends StatefulWidget {
  final String perfumeId;
  const AddJournalScreen({super.key, required this.perfumeId});

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _notesCtrl = TextEditingController();
  int _longevity = 7;
  int _sillage = 7;
  int _projection = 7;
  int _mood = 3;
  List<String> _selectedMoods = [];
  bool _isSaving = false;

  final List<String> _moodOptions = [
    'Happy', 'Professional', 'Romantic', 'Calm',
    'Confident', 'Energized', 'Nostalgic', 'Mysterious',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final perfume = provider.getPerfumeById(widget.perfumeId);

        return Scaffold(
          backgroundColor: AppColors.obsidian,
          appBar: AppBar(
            backgroundColor: AppColors.obsidian,
            title: Text('Log Wear', style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w600)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (perfume != null) _buildPerfumeHeader(perfume),
              const SizedBox(height: 20),
              _buildRatingSection('Longevity', Icons.timer_rounded, _longevity,
                  'How long did it last?',
                  (v) => setState(() => _longevity = v)),
              const SizedBox(height: 14),
              _buildRatingSection('Sillage', Icons.air_rounded, _sillage,
                  'How far did it project?',
                  (v) => setState(() => _sillage = v)),
              const SizedBox(height: 14),
              _buildRatingSection('Projection', Icons.graphic_eq_rounded, _projection,
                  'How strong was the presence?',
                  (v) => setState(() => _projection = v)),
              const SizedBox(height: 20),
              _buildMoodSection(),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'How did it perform? Any observations...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              GoldButton(
                label: 'Save Entry',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                width: double.infinity,
                onTap: _isSaving ? null : () => _save(provider),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerfumeHeader(Perfume p) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
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
                Text(p.name, style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16,
                    fontWeight: FontWeight.w700)),
                Text(p.brand, style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Text(DateTime.now().day.toString().padLeft(2, '0') + '/' +
              DateTime.now().month.toString().padLeft(2, '0'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String label, IconData icon, int value,
      String hint, Function(int) onChanged) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$value/10', style: const TextStyle(
                    color: AppColors.gold, fontSize: 14,
                    fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
          Slider(
            value: value.toDouble(),
            min: 1, max: 10, divisions: 9,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.charcoalLight,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('How did it make you feel?',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moodOptions.map((m) {
              final selected = _selectedMoods.contains(m);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) _selectedMoods.remove(m);
                  else _selectedMoods.add(m);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.amethyst.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppColors.amethyst
                            : AppColors.charcoalLight,
                        width: selected ? 1 : 0.5),
                  ),
                  child: Text(m, style: TextStyle(
                      color: selected
                          ? AppColors.amethystLight
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppProvider provider) async {
    setState(() => _isSaving = true);
    try {
      final entry = JournalEntry(
        id: const Uuid().v4(),
        perfumeId: widget.perfumeId,
        date: DateTime.now(),
        longevityRating: _longevity,
        sillageRating: _sillage,
        projectionRating: _projection,
        moodRating: _mood,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        weather: provider.weather,
        moods: _selectedMoods,
        temperature: provider.weather?.temperature,
        humidity: provider.weather?.humidity,
      );
      await provider.addJournalEntry(entry);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

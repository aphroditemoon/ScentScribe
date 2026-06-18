
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';
import '../services/perfume_image_service.dart';

class AddPerfumeScreen extends StatefulWidget {
  const AddPerfumeScreen({super.key});

  @override
  State<AddPerfumeScreen> createState() => _AddPerfumeScreenState();
}

class _AddPerfumeScreenState extends State<AddPerfumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _perfumerCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  PerfumeFamily _selectedFamily = PerfumeFamily.fresh;
  double _rating = 4.0;
  bool _isWishlist = false;
  List<Season> _selectedSeasons = [];
  List<ScentTimeOfDay> _selectedTimes = [];
  List<Occasion> _selectedOccasions = [];
  final List<FragranceNote> _notes = [];
  bool _isSaving = false;
  final Debouncer _imageDebouncer = Debouncer();
  String? _previewImageUrl;
  bool _isSearchingImage = false;


  final _noteNameCtrl = TextEditingController();
  NoteCategory _noteCategory = NoteCategory.top;
  double _noteIntensity = 0.7;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onPerfumeImageQueryChanged);
    _brandCtrl.addListener(_onPerfumeImageQueryChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onPerfumeImageQueryChanged);
    _brandCtrl.removeListener(_onPerfumeImageQueryChanged);
    _imageDebouncer.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _mlCtrl.dispose();
    _priceCtrl.dispose();
    _perfumerCtrl.dispose();
    _yearCtrl.dispose();
    _noteNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        title: Text(
          'Add Perfume',
          style: GoogleFonts.cormorantGaramond(
              fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildFamilyPicker(),
            const SizedBox(height: 20),
            _buildRatingSection(),
            const SizedBox(height: 20),
            _buildNotesSection(),
            const SizedBox(height: 20),
            _buildSeasonsSection(),
            const SizedBox(height: 20),
            _buildTimesSection(),
            const SizedBox(height: 20),
            _buildOccasionsSection(),
            const SizedBox(height: 20),
            _buildExtraDetails(),
            const SizedBox(height: 20),
            _buildWishlistToggle(),
            const SizedBox(height: 30),
            GoldButton(
              label: 'Add to Collection',
              icon: Icons.add_rounded,
              isLoading: _isSaving,
              width: double.infinity,
              onTap: _isSaving ? null : _savePerfume,
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Perfume Name *'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brandCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Brand / House *'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter a brand' : null,
          ),
          const SizedBox(height: 14),
          _buildPerfumeImagePreview(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
                labelText: 'Description (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mlCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Volume (ml)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Color get _selectedFamilyColor {
    final perfume = Perfume(
      id: '',
      name: '',
      brand: '',
      family: _selectedFamily,
      notes: const [],
      addedAt: DateTime.now(),
    );
    return perfume.familyColor;
  }

  Widget _buildPerfumeImagePreview() {
    final perfumeName = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.charcoalLight, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 96,
            child: PerfumeBottleImage(
              perfumeName: perfumeName,
              brand: brand,
              imageUrl: _previewImageUrl,
              backgroundColor: _selectedFamilyColor.withOpacity(0.10),
              borderRadius: 14,
              padding: const EdgeInsets.all(6),
              showLoadingState: _isSearchingImage,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bottle Image Preview',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  perfumeName.isEmpty
                      ? 'Type a perfume name to find the bottle image.'
                      : _isSearchingImage
                          ? 'Searching bottle image...'
                          : 'Image updates automatically from the perfume name.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPerfumeImageQueryChanged() {
    final perfumeName = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();

    _imageDebouncer.run(() async {
      if (!mounted) return;
      if (perfumeName.isEmpty && brand.isEmpty) {
        setState(() {
          _previewImageUrl = null;
          _isSearchingImage = false;
        });
        return;
      }

      setState(() => _isSearchingImage = true);
      final imageUrl = await PerfumeImageService.instance.findImageUrl(
        perfumeName: perfumeName,
        brand: brand,
      );

      if (!mounted) return;
      if (perfumeName != _nameCtrl.text.trim() || brand != _brandCtrl.text.trim()) {
        return;
      }

      setState(() {
        _previewImageUrl = imageUrl;
        _isSearchingImage = false;
      });
    });
  }

  Widget _buildFamilyPicker() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fragrance Family',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PerfumeFamily.values.map((f) {
              final p = Perfume(
                  id: '', name: '', brand: '',
                  family: f, notes: [], addedAt: DateTime.now());
              final selected = _selectedFamily == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFamily = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? p.familyColor.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? p.familyColor
                          : AppColors.charcoalLight,
                      width: selected ? 1 : 0.5,
                    ),
                  ),
                  child: Text(
                    '${p.familyEmoji} ${f.toString().split('.').last}',
                    style: TextStyle(
                      color: selected ? p.familyColor : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Rating', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingStars(
                rating: _rating,
                size: 32,
                interactive: true,
                onRatingChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(width: 12),
              Text(
                '${_rating.toInt()}/5',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fragrance Notes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Add the notes of your perfume',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteNameCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Note name (e.g. Rose)',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.charcoalLight, width: 0.5),
                ),
                child: DropdownButton<NoteCategory>(
                  value: _noteCategory,
                  dropdownColor: AppColors.charcoal,
                  underline: const SizedBox(),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12),
                  items: NoteCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _noteCategory = v!),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addNote,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.obsidian, size: 20),
                ),
              ),
            ],
          ),
          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _notes
                  .map((n) => GestureDetector(
                        onTap: () =>
                            setState(() => _notes.remove(n)),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NotePill(note: n),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded,
                                    size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _addNote() {
    final name = _noteNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _notes.add(FragranceNote(
        name: name,
        category: _noteCategory,
        intensity: _noteIntensity,
      ));
      _noteNameCtrl.clear();
    });
  }

  Widget _buildSeasonsSection() {
    final seasons = {
      Season.spring: '🌸 Spring',
      Season.summer: '☀️ Summer',
      Season.autumn: '🍂 Autumn',
      Season.winter: '❄️ Winter',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Best Seasons',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seasons.entries.map((e) {
              final selected = _selectedSeasons.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedSeasons.remove(e.key);
                  } else {
                    _selectedSeasons.add(e.key);
                  }
                }),
                child: _toggleChip(e.value, selected, AppColors.gold),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesSection() {
    final times = {
      ScentTimeOfDay.morning: '🌅 Morning',
      ScentTimeOfDay.afternoon: '🌤️ Afternoon',
      ScentTimeOfDay.evening: '🌆 Evening',
      ScentTimeOfDay.night: '🌙 Night',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Best Times', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.entries.map((e) {
              final selected = _selectedTimes.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedTimes.remove(e.key);
                  } else {
                    _selectedTimes.add(e.key);
                  }
                }),
                child:
                    _toggleChip(e.value, selected, AppColors.amethyst),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionsSection() {
    final occasions = {
      Occasion.casual: '👕 Casual',
      Occasion.office: '💼 Office',
      Occasion.date: '💕 Date',
      Occasion.formal: '🎩 Formal',
      Occasion.sport: '🏃 Sport',
      Occasion.outdoor: '🌿 Outdoor',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Occasions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: occasions.entries.map((e) {
              final selected = _selectedOccasions.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedOccasions.remove(e.key);
                  } else {
                    _selectedOccasions.add(e.key);
                  }
                }),
                child:
                    _toggleChip(e.value, selected, AppColors.roseGold),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDetails() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extra Details',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _perfumerCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Perfumer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _yearCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Launch Year'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistToggle() {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Add to Wishlist',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text('Save as a scent you want to try',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _isWishlist,
            onChanged: (v) => setState(() => _isWishlist = v),
            activeColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : AppColors.charcoalLight,
          width: selected ? 1 : 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? color : AppColors.textMuted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _savePerfume() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<AppProvider>();
      final resolvedImageUrl = _previewImageUrl ??
          await PerfumeImageService.instance.findImageUrl(
            perfumeName: _nameCtrl.text.trim(),
            brand: _brandCtrl.text.trim(),
          );

      final perfume = Perfume(
        id: provider.generateId(),
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        family: _selectedFamily,
        notes: _notes,
        imageUrl: resolvedImageUrl,
        mlOwned: double.tryParse(_mlCtrl.text),
        price: double.tryParse(_priceCtrl.text),
        rating: _rating,
        addedAt: DateTime.now(),
        isWishlist: _isWishlist,
        bestSeasons: _selectedSeasons,
        bestTimes: _selectedTimes,
        occasions: _selectedOccasions,
        perfumer: _perfumerCtrl.text.trim().isEmpty
            ? null
            : _perfumerCtrl.text.trim(),
        launchYear: int.tryParse(_yearCtrl.text),
      );

      await provider.addPerfume(perfume);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

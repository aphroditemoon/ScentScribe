
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/perfume_bottle_image.dart';
import '../models/perfume_model.dart';
import 'perfume_detail_screen.dart';
import 'add_perfume_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  PerfumeFamily? _selectedFamily;
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final collection = _searchQuery.isEmpty
            ? (_selectedFamily != null
                ? provider.filterByFamily(_selectedFamily!)
                : provider.collection)
            : provider.searchPerfumes(_searchQuery);

        return Scaffold(
          backgroundColor: AppColors.obsidian,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFamilyFilter()),
              SliverToBoxAdapter(
                child: _buildTabBar(provider),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildCollectionTab(context, provider, collection),
                _buildWishlistTab(context, provider),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(context),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.obsidian,
      title: Text(
        'My Collection',
        style: GoogleFonts.cormorantGaramond(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _isGrid = !_isGrid),
          icon: Icon(
            _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name, brand, or note...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFamilyFilter() {
    final families = PerfumeFamily.values;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: families.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: _selectedFamily == null,
                onSelected: (_) => setState(() => _selectedFamily = null),
                selectedColor: AppColors.gold.withOpacity(0.2),
                side: BorderSide(
                  color: _selectedFamily == null
                      ? AppColors.gold
                      : AppColors.charcoalLight,
                ),
                labelStyle: TextStyle(
                  color: _selectedFamily == null
                      ? AppColors.gold
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          final family = families[i - 1];
          final p = Perfume(
              id: '', name: '', brand: '',
              family: family, notes: [], addedAt: DateTime.now());
          final selected = _selectedFamily == family;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(family.toString().split('.').last[0].toUpperCase() + family.toString().split('.').last.substring(1)),
              selected: selected,
              onSelected: (_) => setState(() =>
                  _selectedFamily = selected ? null : family),
              selectedColor: p.familyColor.withOpacity(0.2),
              side: BorderSide(
                color: selected ? p.familyColor : AppColors.charcoalLight,
              ),
              labelStyle: TextStyle(
                color: selected ? p.familyColor : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        dividerColor: Colors.transparent,
        labelColor: AppColors.obsidian,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          Tab(text: 'Collection (${provider.collection.length})'),
          Tab(text: 'Wishlist (${provider.wishlist.length})'),
        ],
      ),
    );
  }

  Widget _buildCollectionTab(BuildContext context, AppProvider provider,
      List<Perfume> perfumes) {
    if (perfumes.isEmpty) {
      return EmptyState(
        icon: Icons.local_florist_outlined,
        title: 'Nothing here yet',
        subtitle: 'Add your first perfume to start building your scent wardrobe.',
        action: GoldButton(
          label: 'Add Perfume',
          icon: Icons.add_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPerfumeScreen()),
          ),
        ),
      );
    }

    if (_isGrid) return _buildGrid(context, perfumes, provider);
    return _buildList(context, perfumes, provider);
  }

  Widget _buildGrid(BuildContext context, List<Perfume> perfumes, AppProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: perfumes.length,
      itemBuilder: (_, i) => _buildGridCard(context, perfumes[i], provider, i),
    );
  }

  Widget _buildGridCard(BuildContext context, Perfume p, AppProvider provider, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PerfumeDetailScreen(perfumeId: p.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.charcoalLight, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      p.familyColor.withOpacity(0.25),
                      p.familyColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 92,
                        height: 118,
                        child: PerfumeBottleImage(
                          perfumeName: p.name,
                          brand: p.brand,
                          imageUrl: p.imageUrl,
                          imagePath: p.imagePath,
                          backgroundColor: Colors.transparent,
                          borderRadius: 16,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => provider.toggleWishlist(p.id),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.roseGold.withOpacity(0.3),
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: FamilyBadge(family: p.family, showLabel: false),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
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
                    const Spacer(),
                    Row(
                      children: [
                        RatingStars(rating: p.rating, size: 12),
                        const Spacer(),
                        if (p.mlOwned != null)
                          Text(
                            '${p.mlOwned!.toInt()}ml',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * i))
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildList(BuildContext context, List<Perfume> perfumes, AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: perfumes.length,
      itemBuilder: (_, i) => _buildListTile(context, perfumes[i], provider, i),
    );
  }

  Widget _buildListTile(BuildContext context, Perfume p, AppProvider provider, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PerfumeDetailScreen(perfumeId: p.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.charcoalLight, width: 0.5),
        ),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Row(children: [
                    FamilyBadge(family: p.family),
                    if (p.mlOwned != null) ...[
                      const SizedBox(width: 6),
                      Text('${p.mlOwned!.toInt()}ml',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RatingStars(rating: p.rating, size: 14),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * i))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.05),
    );
  }

  Widget _buildWishlistTab(BuildContext context, AppProvider provider) {
    final wishlist = provider.wishlist;
    if (wishlist.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_outline_rounded,
        title: 'Your wishlist is empty',
        subtitle: 'Save perfumes you want to try to your wishlist.',
      );
    }
    return _buildGrid(context, wishlist, provider);
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddPerfumeScreen()),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.obsidian, size: 28),
      ),
    );
  }
}

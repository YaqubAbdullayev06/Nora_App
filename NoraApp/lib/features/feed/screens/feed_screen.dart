import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';
import '../../../models/models.dart';

/// Feed Screen — age-adaptive content feed with smart categorization.
/// Features:
/// - "For You" personalized recommendations
/// - "Quick Reads" for short sessions
/// - Visual content type badges
/// - Category filtering with counts
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;
        final categories = _getCategoriesForAgeGroup(persona.ageGroup);
        final allContent = provider.feedContent;
        final filteredContent = _selectedCategory == 'All'
            ? allContent
            : allContent
                .where((c) => c.category == _selectedCategory)
                .toList();

        // Smart sections
        final recommended = _getRecommendedContent(allContent, persona);
        final quickReads = allContent
            .where((c) => c.durationMinutes <= 5)
            .take(3)
            .toList();
        final trending = allContent.where((c) => c.points >= 20).toList();

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(persona),
                ),

                // Category chips
                SliverToBoxAdapter(
                  child: _buildCategoryChips(categories, persona, allContent),
                ),

                // "For You" section
                if (_selectedCategory == 'All' && recommended.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'For You',
                      'Recommended based on your interests',
                      Icons.recommend_rounded,
                      persona,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecommendedCarousel(recommended, persona),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing16),
                  ),
                ],

                // "Quick Reads" section
                if (_selectedCategory == 'All' && quickReads.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Quick Reads',
                      '5 minutes or less',
                      Icons.timer_rounded,
                      persona,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildQuickReadsRow(quickReads, persona),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing16),
                  ),
                ],

                // "Trending" section
                if (_selectedCategory == 'All' && trending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Trending',
                      'Popular this week',
                      Icons.trending_up_rounded,
                      persona,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTrendingList(trending, persona),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing16),
                  ),
                ],

                // All content header
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    _selectedCategory == 'All' ? 'All Content' : _selectedCategory,
                    '${filteredContent.length} items',
                    Icons.grid_view_rounded,
                    persona,
                  ),
                ),

                // Content list
                if (filteredContent.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(persona),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredContent[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: DesignTokens.spacing12),
                            child: _buildEnhancedContentCard(item, persona),
                          );
                        },
                        childCount: filteredContent.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing40),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PersonaTheme persona) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFeedTitle(persona.ageGroup),
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH2,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                Text(
                  _getFeedSubtitle(persona.ageGroup),
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          NoraMascot(size: 48, showGlow: false),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
      List<String> categories, PersonaTheme persona, List<ContentItem> allContent) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignTokens.spacing8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          final count = category == 'All'
              ? allContent.length
              : allContent.where((c) => c.category == category).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? persona.primary : DesignTokens.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radius20),
                border: Border.all(
                  color: isSelected ? persona.primary : DesignTokens.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? (persona.isDark
                              ? DesignTokens.background
                              : Colors.white)
                          : DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : DesignTokens.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeExtraSmall,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon, PersonaTheme persona) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacing20, DesignTokens.spacing20,
          DesignTokens.spacing20, DesignTokens.spacing12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius10),
            ),
            child: Icon(icon, color: DesignTokens.accent, size: 18),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCarousel(
      List<ContentItem> recommended, PersonaTheme persona) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
        itemCount: recommended.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignTokens.spacing12),
        itemBuilder: (context, index) {
          final item = recommended[index];
          return _buildRecommendedCard(item, persona);
        },
      ),
    );
  }

  Widget _buildRecommendedCard(ContentItem item, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => _showContentDetail(context, item),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              persona.primary.withValues(alpha: 0.15),
              persona.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(
            color: persona.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildContentTypeBadge(item.contentType, persona),
                  const Spacer(),
                  _buildPointsBadge(item.points),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: DesignTokens.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.durationMinutes} min',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DesignTokens.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeExtraSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReadsRow(List<ContentItem> quickReads, PersonaTheme persona) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
        itemCount: quickReads.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignTokens.spacing12),
        itemBuilder: (context, index) {
          final item = quickReads[index];
          return _buildQuickReadCard(item, persona);
        },
      ),
    );
  }

  Widget _buildQuickReadCard(ContentItem item, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => _showContentDetail(context, item),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: DesignTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentTypeBadge(item.contentType, persona),
            const Spacer(),
            Text(
              item.title,
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${item.durationMinutes} min',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeExtraSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingList(List<ContentItem> trending, PersonaTheme persona) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
      child: Column(
        children: trending.take(3).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
            child: _buildTrendingCard(item, persona),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendingCard(ContentItem item, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => _showContentDetail(context, item),
      child: NoraCard(
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        child: Row(
          children: [
            _buildContentTypeIcon(item.contentType, persona),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBodySmall,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.durationMinutes} min · ${item.category}',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                  ),
                ],
              ),
            ),
            _buildPointsBadge(item.points),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContentCard(ContentItem item, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => _showContentDetail(context, item),
      child: NoraCard(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Row(
          children: [
            _buildContentTypeIcon(item.contentType, persona),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: DesignTokens.fontSizeBody,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontFamily: DesignTokens.fontFamilyDisplay,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPointsBadge(item.points),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.spacing8),
                  Row(
                    children: [
                      _buildContentTypeBadge(item.contentType, persona),
                      const SizedBox(width: DesignTokens.spacing8),
                      Icon(
                        Icons.schedule_rounded,
                        color: DesignTokens.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.durationMinutes} min',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeExtraSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeBadge(String type, PersonaTheme persona) {
    final (icon, label, color) = switch (type) {
      'video' => (Icons.play_circle_rounded, 'Video', DesignTokens.danger),
      'article' => (Icons.article_rounded, 'Read', DesignTokens.accent),
      'game' => (Icons.sports_esports_rounded, 'Play', DesignTokens.success),
      'interactive' => (Icons.touch_app_rounded, 'Try', DesignTokens.warning),
      'audio' => (Icons.headphones_rounded, 'Listen', DesignTokens.accentSecondary),
      _ => (Icons.article_rounded, 'Read', DesignTokens.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeExtraSmall,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeIcon(String type, PersonaTheme persona) {
    final (icon, color) = switch (type) {
      'video' => (Icons.play_circle_filled_rounded, DesignTokens.danger),
      'article' => (Icons.article_rounded, DesignTokens.accent),
      'game' => (Icons.sports_esports_rounded, DesignTokens.success),
      'interactive' => (Icons.touch_app_rounded, DesignTokens.warning),
      'audio' => (Icons.headphones_rounded, DesignTokens.accentSecondary),
      _ => (Icons.article_rounded, DesignTokens.accent),
    };

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: DesignTokens.warning, size: 14),
          const SizedBox(width: 4),
          Text(
            '$points XP',
            style: TextStyle(
              color: DesignTokens.warning,
              fontSize: DesignTokens.fontSizeExtraSmall,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Smart Content Selection ───

  List<ContentItem> _getRecommendedContent(
      List<ContentItem> allContent, PersonaTheme persona) {
    // Simple recommendation: mix of high-point content and varied categories
    final highPoint = allContent.where((c) => c.points >= 15).toList();
    final shortContent = allContent.where((c) => c.durationMinutes <= 10).toList();

    // Combine and deduplicate
    final recommended = <ContentItem>{};
    recommended.addAll(highPoint.take(2));
    recommended.addAll(shortContent.take(2));

    return recommended.toList().take(4).toList();
  }

  void _showContentDetail(BuildContext context, ContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: DesignTokens.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeH2,
                          fontWeight: FontWeight.bold,
                          fontFamily: DesignTokens.fontFamilyDisplay,
                        ),
                      ),
                    ),
                    _buildPointsBadge(item.points),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildContentTypeBadge(item.contentType,
                        context.read<AppProvider>().persona),
                    const SizedBox(width: DesignTokens.spacing8),
                    Icon(Icons.schedule_rounded,
                        color: DesignTokens.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${item.durationMinutes} min',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.description,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBody,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (item.takeaway != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: DesignTokens.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Key Takeaway:',
                            style: TextStyle(
                                color: DesignTokens.accent,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(item.takeaway!,
                            style: TextStyle(color: DesignTokens.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                NoraButton(
                  label: 'Complete & Claim ${item.points} XP',
                  icon: Icons.check_circle_rounded,
                  expanded: true,
                  onPressed: () {
                    context.read<AppProvider>().claimContentReward(item);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Claimed ${item.points} XP! Great focus!')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(PersonaTheme persona) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              persona.mascotAssetPath,
              width: 64,
              height: 64,
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              _getEmptyTitle(persona.ageGroup),
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamilyDisplay,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              _getEmptySubtitle(persona.ageGroup),
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBodySmall,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Age-specific data ───

  String _getFeedTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Fun Stuff';
      case AgeGroup.kid:
        return 'Your Feed';
      case AgeGroup.teen:
        return 'Learn & Grow';
      case AgeGroup.adult:
        return 'Discover';
    }
  }

  String _getFeedSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Things to watch and play!';
      case AgeGroup.kid:
        return 'Activities picked just for you';
      case AgeGroup.teen:
        return 'Resources to help you grow';
      case AgeGroup.adult:
        return 'Content for your goals';
    }
  }

  String _getEmptyTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Nothing here yet!';
      case AgeGroup.kid:
        return 'All caught up!';
      case AgeGroup.teen:
        return 'No new content';
      case AgeGroup.adult:
        return 'Empty feed';
    }
  }

  String _getEmptySubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Check back later for new fun!';
      case AgeGroup.kid:
        return 'More quests coming soon!';
      case AgeGroup.teen:
        return 'New articles drop daily';
      case AgeGroup.adult:
        return 'Check back later for updates';
    }
  }

  List<String> _getCategoriesForAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return ['All', 'Colors', 'Animals', 'Puzzles', 'Music'];
      case AgeGroup.kid:
        return ['All', 'Math', 'Language', 'Science', 'Games'];
      case AgeGroup.teen:
        return ['All', 'Study', 'Programming', 'Wellness', 'Social'];
      case AgeGroup.adult:
        return ['All', 'Productivity', 'Business', 'Wellness', 'Tech'];
    }
  }
}

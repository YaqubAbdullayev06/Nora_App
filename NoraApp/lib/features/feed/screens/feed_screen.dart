import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';
import '../../../models/models.dart';

/// Feed Screen — age-adaptive content feed.
/// Baby: colorful cards, large text, video thumbnails
/// Kid: game cards, progress bars, achievement badges
/// Teen: study articles, code snippets, social features
/// Adult: productivity articles, career content, minimal design
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
        final filteredContent = _selectedCategory == 'All'
            ? provider.feedContent
            : provider.feedContent
                .where((c) => c.category == _selectedCategory)
                .toList();

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(persona),
                _buildCategoryChips(categories, persona),
                Expanded(
                  child: filteredContent.isEmpty
                      ? _buildEmptyState(persona)
                      : _buildContentList(filteredContent, persona),
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

  Widget _buildCategoryChips(List<String> categories, PersonaTheme persona) {
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
              child: Text(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentList(List<ContentItem> content, PersonaTheme persona) {
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      itemCount: content.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: DesignTokens.spacing12),
      itemBuilder: (context, index) {
        final item = content[index];
        return _buildContentCard(item, persona);
      },
    );
  }

  Widget _buildContentCard(ContentItem item, PersonaTheme persona) {
    return NoraImageCard(
      imageUrl: item.imageUrl,
      title: item.title,
      subtitle: item.description,
      category: item.category,
      durationMinutes: item.durationMinutes,
      points: item.points,
      typeIcon: _getContentTypeIcon(item.contentType),
      onTap: () => _showContentDetail(context, item),
    );
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
                Text(
                  item.title,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 16,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(persona.mascotEmoji, style: const TextStyle(fontSize: 64)),
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
        return 'Content';
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
        return 'Articles and resources for you';
      case AgeGroup.adult:
        return 'Curated content for your goals';
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

  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'game':
        return Icons.sports_esports_rounded;
      case 'interactive':
        return Icons.touch_app_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

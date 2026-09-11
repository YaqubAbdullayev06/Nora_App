import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../services/app_scanner_service.dart';
import '../../../services/usage_tracker_service.dart';
import '../../../services/api_service.dart';
import '../../../models/app_info.dart';

/// App Scan Screen — AI-powered app scanning and blocking recommendations.
/// Shows all apps, categorizes them, and lets the user apply AI recommendations.
class AppScanScreen extends StatefulWidget {
  const AppScanScreen({super.key});

  @override
  State<AppScanScreen> createState() => _AppScanScreenState();
}

class _AppScanScreenState extends State<AppScanScreen>
    with SingleTickerProviderStateMixin {
  final _scannerService = AppScannerService();
  final _usageService = UsageTrackerService();
  final _apiService = ApiService();

  List<AppInfo> _allApps = [];
  Map<String, dynamic>? _classification;
  bool _isScanning = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final Map<String, String> _appIcons = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performScan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performScan() async {
    setState(() => _isScanning = true);

    try {
      final apps = await _scannerService.scanAppsWithBlockStatus();
      final todayUsage = await _usageService.getTodayUsage();

      if (!mounted) return;

      // Merge usage data
      final appsWithUsage = apps.map((app) {
        final usageApp = todayUsage?.topApps.firstWhere(
          (u) => u.packageName == app.packageName,
          orElse: () => AppUsageEntry(
            packageName: app.packageName,
            appName: app.appName,
            totalTimeMinutes: 0,
            lastTimeUsed: 0,
            category: app.category,
          ),
        );
        return app.copyWith(
          usageTodayMinutes: usageApp?.totalTimeMinutes ?? 0,
        );
      }).toList();

      // Get AI classification
      final provider = context.read<AppProvider>();
      final appMaps = appsWithUsage
          .where((a) => !a.isSystemApp)
          .map((a) => a.toMap())
          .toList();

      final classification = await _apiService.classifyApps(
        apps: appMaps,
        ageGroup: provider.ageGroup.name,
      );

      // Merge AI recommendations
      final recommended =
          (classification['aiRecommendedBlock'] as List? ?? []).toList();
      final recommendedPackages =
          recommended.map((r) => r['packageName'].toString()).toSet();

      final mergedApps = appsWithUsage.map((app) {
        return app.copyWith(
          aiRecommendedBlock: recommendedPackages.contains(app.packageName),
        );
      }).toList();

      setState(() {
        _allApps = mergedApps;
        _classification = classification;
        _isScanning = false;
      });

      // Load app icons in background (non-blocking)
      _loadAppIcons(mergedApps);
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  /// Load app icons in background after scan completes.
  /// Loads in parallel batches of 10 for speed.
  Future<void> _loadAppIcons(List<AppInfo> apps) async {
    const batchSize = 10;
    for (var i = 0; i < apps.length; i += batchSize) {
      if (!mounted) return;
      final batch = apps.skip(i).take(batchSize).toList();
      final results = await Future.wait(
        batch.map((app) => _scannerService.getAppIcon(app.packageName).then(
              (icon) => MapEntry(app.packageName, icon),
            )),
        eagerError: true,
      );
      if (!mounted) return;
      for (final entry in results) {
        if (entry.value != null) {
          _appIcons[entry.key] = entry.value!;
        }
      }
      // Single setState to rebuild all visible tiles at once
      setState(() {});
    }
  }

  Future<void> _applyAIRecommendations() async {
    final recommended = _allApps.where((a) => a.aiRecommendedBlock).toList();
    if (recommended.isEmpty) return;

    final packages = recommended.map((a) => a.packageName).toList();

    try {
      await _scannerService.addToBlockedApps(packages);

      // Update local state
      setState(() {
        _allApps = _allApps.map((app) {
          if (packages.contains(app.packageName)) {
            return app.copyWith(isBlocked: true);
          }
          return app;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blocked ${packages.length} apps successfully!'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block apps: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _toggleBlock(AppInfo app) async {
    try {
      if (app.isBlocked) {
        await _scannerService.removeFromBlockedApps([app.packageName]);
      } else {
        await _scannerService.addToBlockedApps([app.packageName]);
      }

      setState(() {
        _allApps = _allApps.map((a) {
          if (a.packageName == app.packageName) {
            return a.copyWith(isBlocked: !a.isBlocked);
          }
          return a;
        }).toList();
      });
    } catch (e) {
      debugPrint('Toggle block failed: $e');
    }
  }

  List<AppInfo> get _filteredApps {
    var apps = _allApps.where((a) => !a.isSystemApp).toList();

    if (_selectedCategory != 'all') {
      apps = apps.where((a) => a.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      apps = apps
          .where((a) =>
              a.appName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return apps;
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final app in _allApps.where((a) => !a.isSystemApp)) {
      counts[app.category] = (counts[app.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          appBar: AppBar(
            backgroundColor: DesignTokens.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: DesignTokens.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'App Scanner',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            actions: [
              IconButton(
                icon: _isScanning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(persona.primary),
                        ),
                      )
                    : Icon(Icons.refresh_rounded,
                        color: DesignTokens.textMuted),
                onPressed: _isScanning ? null : _performScan,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: persona.primary,
              unselectedLabelColor: DesignTokens.textMuted,
              indicatorColor: persona.primary,
              tabs: const [
                Tab(text: 'All Apps'),
                Tab(text: 'AI Recommend'),
                Tab(text: 'Blocked'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Summary card
              if (_classification != null) _buildSummaryCard(persona),
              // Search bar
              _buildSearchBar(),
              // Category filters
              _buildCategoryFilters(),
              // App list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppList(_filteredApps),
                    _buildAppList(
                      _allApps.where((a) => a.aiRecommendedBlock).toList(),
                      showRecommendation: true,
                    ),
                    _buildAppList(
                      _allApps.where((a) => a.isBlocked).toList(),
                    ),
                  ],
                ),
              ),
              // Apply recommendations button
              if (_allApps.any((a) => a.aiRecommendedBlock) && !_isScanning)
                _buildApplyButton(persona),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(dynamic persona) {
    final totalApps = _classification!['totalApps'] ?? 0;
    final userApps = _classification!['userApps'] ?? 0;
    final distractionCount = _classification!['distractionAppsCount'] ?? 0;
    final blockingCount =
        (_classification!['aiRecommendedBlock'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [persona.primary, persona.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Scan Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('$totalApps', 'Total', persona),
              _buildStatItem('$userApps', 'User Apps', persona),
              _buildStatItem('$distractionCount', 'Distractions', persona),
              _buildStatItem('$blockingCount', 'To Block', persona),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _classification!['summary'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, dynamic persona) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: DesignTokens.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: DesignTokens.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: DesignTokens.textMuted),
          filled: true,
          fillColor: DesignTokens.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final counts = _categoryCounts;
    final categories = ['all', ...counts.keys.toList()..sort()];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final count = cat == 'all' ? _allApps.length : (counts[cat] ?? 0);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.accent.withValues(alpha: 0.2)
                      : DesignTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? DesignTokens.accent : DesignTokens.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat != 'all')
                      Text(
                        _getCategoryEmoji(cat),
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (cat != 'all') const SizedBox(width: 4),
                    Text(
                      cat == 'all' ? 'All' : _getCategoryName(cat),
                      style: TextStyle(
                        color: isSelected
                            ? DesignTokens.accent
                            : DesignTokens.textMuted,
                        fontSize: 12,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected
                            ? DesignTokens.accent
                            : DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppList(List<AppInfo> apps, {bool showRecommendation = false}) {
    if (_isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android_rounded,
                size: 48, color: DesignTokens.textMuted),
            const SizedBox(height: 16),
            Text(
              showRecommendation
                  ? 'No apps recommended for blocking'
                  : 'No apps found',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _buildAppTile(app, showRecommendation: showRecommendation);
      },
    );
  }

  Widget _buildAppTile(AppInfo app, {bool showRecommendation = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showRecommendation
              ? DesignTokens.danger.withValues(alpha: 0.3)
              : app.isBlocked
                  ? DesignTokens.danger.withValues(alpha: 0.2)
                  : DesignTokens.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // App icon — real icon or category emoji fallback
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(app.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildAppIcon(app),
          ),
          const SizedBox(width: 12),
          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      app.categoryDisplayName,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                    if (app.usageTodayMinutes > 0) ...[
                      Text(' • ',
                          style: TextStyle(color: DesignTokens.textMuted)),
                      Text(
                        '${app.usageTodayMinutes}m today',
                        style: TextStyle(
                          color: app.usageTodayMinutes > 60
                              ? DesignTokens.warning
                              : DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // AI recommendation badge
          if (app.aiRecommendedBlock && !app.isBlocked)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI: Block',
                style: TextStyle(
                  color: DesignTokens.warning,
                  fontSize: 10,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
          // Block toggle
          Switch(
            value: app.isBlocked,
            onChanged: (_) => _toggleBlock(app),
            activeThumbColor: DesignTokens.danger,
            activeTrackColor: DesignTokens.danger.withValues(alpha: 0.3),
            inactiveThumbColor: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(dynamic persona) {
    final count = _allApps.where((a) => a.aiRecommendedBlock).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        border: Border(
          top: BorderSide(color: DesignTokens.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _applyAIRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: persona.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apply AI Recommendations ($count apps)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'social_media':
        return '📱';
      case 'entertainment':
        return '🎬';
      case 'games':
        return '🎮';
      case 'productivity':
        return '💼';
      case 'messaging':
        return '💬';
      case 'education':
        return '📚';
      case 'news':
        return '📰';
      case 'photography':
        return '📷';
      case 'navigation':
        return '🗺️';
      case 'finance':
        return '💰';
      case 'health':
        return '🏥';
      case 'shopping':
        return '🛒';
      default:
        return '📦';
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'social_media':
        return 'Social';
      case 'entertainment':
        return 'Entertainment';
      case 'games':
        return 'Games';
      case 'productivity':
        return 'Productivity';
      case 'messaging':
        return 'Messaging';
      case 'education':
        return 'Education';
      case 'finance':
        return 'Finance';
      case 'health':
        return 'Health';
      case 'navigation':
        return 'Navigation';
      case 'shopping':
        return 'Shopping';
      case 'news':
        return 'News';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'social_media':
        return const Color(0xFFE91E63);
      case 'entertainment':
        return const Color(0xFF9C27B0);
      case 'games':
        return const Color(0xFFFF5722);
      case 'productivity':
        return const Color(0xFF4CAF50);
      case 'messaging':
        return const Color(0xFF2196F3);
      case 'education':
        return const Color(0xFF00BCD4);
      case 'finance':
        return const Color(0xFFFF9800);
      case 'health':
        return const Color(0xFF4CAF50);
      case 'navigation':
        return const Color(0xFF3F51B5);
      case 'shopping':
        return const Color(0xFFE91E63);
      case 'news':
        return const Color(0xFF795548);
      default:
        return DesignTokens.textMuted;
    }
  }

  Widget _buildAppIcon(AppInfo app) {
    // Try to load real icon from map
    final icon = _appIcons[app.packageName];
    if (icon != null && icon.isNotEmpty) {
      try {
        final bytes = base64Decode(icon);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCategoryEmoji(app.category),
          ),
        );
      } catch (_) {
        // Fall through to emoji
      }
    }
    // Fallback: category emoji
    return _buildCategoryEmoji(app.category);
  }

  Widget _buildCategoryEmoji(String category) {
    return Center(
      child: Text(
        _getCategoryEmoji(category),
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}

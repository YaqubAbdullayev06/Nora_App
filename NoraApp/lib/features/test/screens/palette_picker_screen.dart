import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A test screen to visually browse and select color palettes.
/// Access via route: /palette-picker
class PalettePickerScreen extends StatefulWidget {
  const PalettePickerScreen({super.key});

  @override
  State<PalettePickerScreen> createState() => _PalettePickerScreenState();
}

class _PalettePickerScreenState extends State<PalettePickerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _current || index < 0 || index >= _palettes.length) return;
    setState(() => _current = index);
    _anim.reset();
    _anim.forward();
  }

  @override
  Widget build(BuildContext context) {
    final p = _palettes[_current];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? _buildWideLayout(p, constraints)
                : _buildNarrowLayout(p);
          },
        ),
      ),
    );
  }

  // ── WIDE (desktop/web) ──────────────────────────────

  Widget _buildWideLayout(_PaletteData p, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPaletteTabs(),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Opacity(
              opacity: _anim.value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - _anim.value)),
                child: _buildWideCard(p),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(_PaletteData p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: color swatches
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaletteTitle(p),
              const SizedBox(height: 16),
              _buildSwatchesGrid(p),
              const SizedBox(height: 16),
              _buildApplyButton(p),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right: preview
        Expanded(
          flex: 4,
          child: _buildMiniAppPreview(p),
        ),
      ],
    );
  }

  // ── NARROW (mobile) ─────────────────────────────────

  Widget _buildNarrowLayout(_PaletteData p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildPaletteTabs(),
          const SizedBox(height: 16),
          _buildPaletteTitle(p),
          const SizedBox(height: 12),
          _buildSwatchesGrid(p),
          const SizedBox(height: 16),
          _buildMiniAppPreview(p),
          const SizedBox(height: 16),
          _buildApplyButton(p),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Choose Your Palette',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap a palette to preview • Click colors to copy hex',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_palettes.length, (i) {
        final p = _palettes[i];
        final isSelected = i == _current;
        return GestureDetector(
          onTap: () => _goTo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? p.primary.withValues(alpha: 0.18)
                  : const Color(0xFF1A1C20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? p.primary
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? p.primary : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPaletteTitle(_PaletteData p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              p.name,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          p.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          p.vibe,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.3),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSwatchesGrid(_PaletteData p) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: p.swatches.map((s) {
        return GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: s.hex));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied ${s.hex}'),
                backgroundColor: p.primary,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Tooltip(
            message: '${s.label}\n${s.hex}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 44,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  s.hex,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.25),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniAppPreview(_PaletteData p) {
    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.psychology, color: p.onPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nora',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.notifications_outlined,
                  color: p.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 14),

          // Screen time card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Screen Time Today',
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '2h 34m',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-18%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Chart bars
          Row(
            children: List.generate(7, (i) {
              final heights = [0.4, 0.6, 0.3, 0.8, 0.5, 0.7, 0.45];
              final isToday = i == 6;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: heights[i],
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? p.primary
                                  : p.primary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? p.primary : p.textMuted,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              _buildMiniButton(p, Icons.play_arrow, 'Focus'),
              const SizedBox(width: 10),
              _buildMiniButton(p, Icons.timer_outlined, 'Timer'),
              const SizedBox(width: 10),
              _buildMiniButton(p, Icons.self_improvement, 'Breathe'),
            ],
          ),
          const SizedBox(height: 12),

          // Habit cards preview
          Row(
            children: [
              _buildMiniHabitCard(p, '🧘', 'Meditate', '5 min'),
              const SizedBox(width: 10),
              _buildMiniHabitCard(p, '📖', 'Read', '15 min'),
              const SizedBox(width: 10),
              _buildMiniHabitCard(p, '💧', 'Hydrate', '2 glasses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton(_PaletteData p, IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: p.primary, size: 16),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 9, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHabitCard(
      _PaletteData p, String emoji, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border, width: 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      )),
                  Text(subtitle,
                      style: TextStyle(fontSize: 8, color: p.textMuted)),
                ],
              ),
            ),
            Icon(Icons.check_circle_outline,
                color: p.primary.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(_PaletteData p) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _applyPalette(p),
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Apply ${p.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _applyPalette(_PaletteData p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('${p.emoji} ${p.name}',
            style: TextStyle(color: p.textPrimary)),
        content: Text(
          'Palette selected!\n\n'
          'Primary: ${p.primary.hex}\n'
          'Background: ${p.background.hex}\n'
          'Surface: ${p.surface.hex}\n\n'
          'In production, this would change the entire app theme.',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: p.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── PALETTE DATA ──────────────────────────────────────────────

class _PaletteData {
  final String name;
  final String emoji;
  final String description;
  final String vibe;
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final List<_ColorSwatch> swatches;

  const _PaletteData({
    required this.name,
    required this.emoji,
    required this.description,
    required this.vibe,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.swatches,
  });
}

class _ColorSwatch {
  final Color color;
  final String hex;
  final String label;

  const _ColorSwatch(this.color, this.hex, this.label);
}

extension _ColorHex on Color {
  String get hex =>
      '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

final _palettes = [
  // ── 1. Midnight Sage ──
  _PaletteData(
    name: 'Midnight Sage',
    emoji: '🌿',
    description: 'Refined emerald on true dark. Calm, grounded, nature-forward.',
    vibe: 'Like a meditation app meets a developer tool.',
    primary: const Color(0xFF6BBF8A),
    onPrimary: const Color(0xFF0A1A10),
    background: const Color(0xFF121416),
    surface: const Color(0xFF1C1F22),
    textPrimary: const Color(0xFFE8EAE6),
    textSecondary: const Color(0xFF9BA197),
    textMuted: const Color(0xFF5A6158),
    border: const Color(0xFF2D3230),
    success: const Color(0xFF6BBF8A),
    swatches: const [
      _ColorSwatch(Color(0xFF6BBF8A), '#6BBF8A', 'Primary'),
      _ColorSwatch(Color(0xFF8FD4A6), '#8FD4A6', 'Primary Lt'),
      _ColorSwatch(Color(0xFFC4A265), '#C4A265', 'Secondary'),
      _ColorSwatch(Color(0xFF121416), '#121416', 'Background'),
      _ColorSwatch(Color(0xFF1C1F22), '#1C1F22', 'Surface'),
      _ColorSwatch(Color(0xFFE8EAE6), '#E8EAE6', 'Text'),
      _ColorSwatch(Color(0xFF2D3230), '#2D3230', 'Border'),
    ],
  ),

  // ── 2. Deep Ocean ──
  _PaletteData(
    name: 'Deep Ocean',
    emoji: '🌊',
    description: 'Dark navy with ocean-teal. Trustworthy, deep, focused.',
    vibe: 'Underwater calm. Professional and trustworthy.',
    primary: const Color(0xFF4ECDC4),
    onPrimary: const Color(0xFF0B1120),
    background: const Color(0xFF0B1120),
    surface: const Color(0xFF131B2E),
    textPrimary: const Color(0xFFE2E8F0),
    textSecondary: const Color(0xFF7B8CA8),
    textMuted: const Color(0xFF4A5568),
    border: const Color(0xFF1E2D4A),
    success: const Color(0xFF48BB78),
    swatches: const [
      _ColorSwatch(Color(0xFF4ECDC4), '#4ECDC4', 'Primary'),
      _ColorSwatch(Color(0xFF7EDDD6), '#7EDDD6', 'Primary Lt'),
      _ColorSwatch(Color(0xFFFF6B6B), '#FF6B6B', 'Secondary'),
      _ColorSwatch(Color(0xFF0B1120), '#0B1120', 'Background'),
      _ColorSwatch(Color(0xFF131B2E), '#131B2E', 'Surface'),
      _ColorSwatch(Color(0xFFE2E8F0), '#E2E8F0', 'Text'),
      _ColorSwatch(Color(0xFF1E2D4A), '#1E2D4A', 'Border'),
    ],
  ),

  // ── 3. Soft Midnight ──
  _PaletteData(
    name: 'Soft Midnight',
    emoji: '🌙',
    description: 'Warm purple/indigo on dark. Modern, creative, 2026.',
    vibe: 'Spotify meets wellness journal. Trendy and warm.',
    primary: const Color(0xFFA78BFA),
    onPrimary: const Color(0xFF0F0E17),
    background: const Color(0xFF0F0E17),
    surface: const Color(0xFF1A1926),
    textPrimary: const Color(0xFFF0ECF9),
    textSecondary: const Color(0xFF918CAD),
    textMuted: const Color(0xFF56526A),
    border: const Color(0xFF2D2A3E),
    success: const Color(0xFF6EE7B7),
    swatches: const [
      _ColorSwatch(Color(0xFFA78BFA), '#A78BFA', 'Primary'),
      _ColorSwatch(Color(0xFFC4B5FD), '#C4B5FD', 'Primary Lt'),
      _ColorSwatch(Color(0xFFF9A8D4), '#F9A8D4', 'Secondary'),
      _ColorSwatch(Color(0xFF0F0E17), '#0F0E17', 'Background'),
      _ColorSwatch(Color(0xFF1A1926), '#1A1926', 'Surface'),
      _ColorSwatch(Color(0xFFF0ECF9), '#F0ECF9', 'Text'),
      _ColorSwatch(Color(0xFF2D2A3E), '#2D2A3E', 'Border'),
    ],
  ),

  // ── 4. Nordic Frost ──
  _PaletteData(
    name: 'Nordic Frost',
    emoji: '❄️',
    description: 'Cool grays with icy blue. Minimal, Scandinavian.',
    vibe: 'Notion meets a Scandinavian design studio.',
    primary: const Color(0xFF7DD3E8),
    onPrimary: const Color(0xFF111318),
    background: const Color(0xFF111318),
    surface: const Color(0xFF1A1D24),
    textPrimary: const Color(0xFFE4E7EC),
    textSecondary: const Color(0xFF8891A0),
    textMuted: const Color(0xFF505764),
    border: const Color(0xFF2A2E38),
    success: const Color(0xFF6EE7B7),
    swatches: const [
      _ColorSwatch(Color(0xFF7DD3E8), '#7DD3E8', 'Primary'),
      _ColorSwatch(Color(0xFFA3E1F0), '#A3E1F0', 'Primary Lt'),
      _ColorSwatch(Color(0xFFE8B86D), '#E8B86D', 'Secondary'),
      _ColorSwatch(Color(0xFF111318), '#111318', 'Background'),
      _ColorSwatch(Color(0xFF1A1D24), '#1A1D24', 'Surface'),
      _ColorSwatch(Color(0xFFE4E7EC), '#E4E7EC', 'Text'),
      _ColorSwatch(Color(0xFF2A2E38), '#2A2E38', 'Border'),
    ],
  ),

  // ── 5. Warm Dusk ──
  _PaletteData(
    name: 'Warm Dusk',
    emoji: '🌅',
    description: 'Warm peach/amber on deep charcoal. Cozy, human.',
    vibe: 'Coffee shop at dusk. Warm, inviting, human.',
    primary: const Color(0xFFE8A87C),
    onPrimary: const Color(0xFF181614),
    background: const Color(0xFF181614),
    surface: const Color(0xFF222018),
    textPrimary: const Color(0xFFF0E8DC),
    textSecondary: const Color(0xFFA09484),
    textMuted: const Color(0xFF6A5E50),
    border: const Color(0xFF353028),
    success: const Color(0xFF85CDCA),
    swatches: const [
      _ColorSwatch(Color(0xFFE8A87C), '#E8A87C', 'Primary'),
      _ColorSwatch(Color(0xFFF0C4A0), '#F0C4A0', 'Primary Lt'),
      _ColorSwatch(Color(0xFF85CDCA), '#85CDCA', 'Secondary'),
      _ColorSwatch(Color(0xFF181614), '#181614', 'Background'),
      _ColorSwatch(Color(0xFF222018), '#222018', 'Surface'),
      _ColorSwatch(Color(0xFFF0E8DC), '#F0E8DC', 'Text'),
      _ColorSwatch(Color(0xFF353028), '#353028', 'Border'),
    ],
  ),
];

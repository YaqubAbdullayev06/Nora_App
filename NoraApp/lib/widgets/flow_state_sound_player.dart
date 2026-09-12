import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/theme/persona_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/flow_state_sounds.dart';

/// FlowStateSoundPlayer — Widget for selecting and playing ambient sounds.
///
/// Shows a horizontal scrollable list of sound types with play/stop controls.
/// Integrates with the timer screen for flow-state audio.
class FlowStateSoundPlayer extends StatefulWidget {
  final PersonaTheme persona;
  final bool isPlaying;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final SoundType? currentSound;

  const FlowStateSoundPlayer({
    super.key,
    required this.persona,
    this.isPlaying = false,
    this.onPlay,
    this.onStop,
    this.currentSound,
  });

  @override
  State<FlowStateSoundPlayer> createState() => _FlowStateSoundPlayerState();
}

class _FlowStateSoundPlayerState extends State<FlowStateSoundPlayer> {
  SoundType? _selectedSound;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound ?? SoundType.brownNoise;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
          ),
          child: Row(
            children: [
              Icon(
                Icons.waves,
                size: 20,
                color: widget.persona.primary,
              ),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                "Flow-State Sounds",
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const Spacer(),
              if (widget.isPlaying)
                Text(
                  "Now Playing",
                  style: TextStyle(
                    color: widget.persona.primary,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacing12),

        // Sound type selector (horizontal scroll)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
            ),
            itemCount: SoundType.values.length,
            itemBuilder: (context, index) {
              final sound = SoundType.values[index];
              final isSelected = _selectedSound == sound;
              final isCurrentlyPlaying =
                  widget.isPlaying && widget.currentSound == sound;

              return GestureDetector(
                onTap: () {
                  HapticService.buttonPressed();
                  setState(() => _selectedSound = sound);
                  if (isCurrentlyPlaying) {
                    widget.onStop?.call();
                  } else {
                    widget.onPlay?.call();
                  }
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: DesignTokens.spacing12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.persona.primary.withValues(alpha: 0.15)
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    border: Border.all(
                      color: isSelected
                          ? widget.persona.primary
                          : DesignTokens.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sound icon/emoji
                      Text(
                        sound.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: DesignTokens.spacing4),
                      // Sound name
                      Text(
                        sound.name,
                        style: TextStyle(
                          color: isSelected
                              ? widget.persona.primary
                              : DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontWeight: isSelected
                              ? DesignTokens.fontWeightBold
                              : DesignTokens.fontWeightRegular,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Playing indicator
                      if (isCurrentlyPlaying)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.equalizer,
                            size: 14,
                            color: widget.persona.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Description and controls
        if (_selectedSound != null)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSound!.description,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing12),
                // Play/Stop button
                Row(
                  children: [
                    Expanded(
                      child: _SoundToggleButton(
                        isPlaying: widget.isPlaying &&
                            widget.currentSound == _selectedSound,
                        onPlay: () {
                          HapticService.success();
                          widget.onPlay?.call();
                        },
                        onStop: () {
                          HapticService.buttonPressed();
                          widget.onStop?.call();
                        },
                        persona: widget.persona,
                        soundName: _selectedSound!.name,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Play/Stop toggle button for sounds.
class _SoundToggleButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final PersonaTheme persona;
  final String soundName;

  const _SoundToggleButton({
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
    required this.persona,
    required this.soundName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlaying ? onStop : onPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing12,
        ),
        decoration: BoxDecoration(
          color: isPlaying ? DesignTokens.danger : persona.primary,
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            Text(
              isPlaying ? "Stop" : "Play $soundName",
              style: TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

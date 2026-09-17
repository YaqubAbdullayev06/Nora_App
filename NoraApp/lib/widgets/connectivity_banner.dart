import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/design_tokens.dart';
import '../services/connectivity_service.dart';

/// Banner that shows when the app is offline.
/// Appears at the top of the screen with a subtle animation.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isConnected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
            vertical: DesignTokens.spacing8,
          ),
          color: DesignTokens.warning.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                const SizedBox(width: DesignTokens.spacing8),
                Text(
                  'You\'re offline. Some features may be limited.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

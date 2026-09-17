import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';

/// Full-screen loading overlay with a subtle animation.
class NoraLoading extends StatelessWidget {
  final String? message;

  const NoraLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesignTokens.background.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.accent,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DesignTokens.spacing16),
              Text(
                message!,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline loading indicator for use within widgets.
class NoraInlineLoading extends StatelessWidget {
  final String? message;

  const NoraInlineLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.accent,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DesignTokens.spacing12),
              Text(
                message!,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error display widget with retry button.
class NoraError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const NoraError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: DesignTokens.warning,
              size: 48,
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBodySmall,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.spacing16),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: DesignTokens.accent,
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

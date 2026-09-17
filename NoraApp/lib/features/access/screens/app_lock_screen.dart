import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/accountability_provider.dart';
import '../../accountability/screens/accountability_verify_screen.dart';

class AppLockScreen extends StatelessWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer<AccountabilityProvider>(
          builder: (context, accountability, _) {
            // If accountability lock is active and not yet verified this session,
            // show the accountability verify screen inline.
            if (accountability.isLockActive && !accountability.isVerified) {
              return AccountabilityVerifyScreen(
                reason: 'Enter guardian PIN to unlock Nora',
                onVerified: () {
                  // After verifying, show the normal unlock screen
                },
              );
            }

            // Normal unlock screen
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacing24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.accent.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: DesignTokens.accent,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing24),
                    Text(
                      'Nora is locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeH2,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyDisplay,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      'Your session is paused until you choose to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeBody,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.read<AuthProvider>().unlockApp(),
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Unlock Nora'),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: SystemNavigator.pop,
                        icon: const Icon(Icons.exit_to_app_rounded),
                        label: const Text('Exit app'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

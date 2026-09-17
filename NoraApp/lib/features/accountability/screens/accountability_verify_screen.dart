import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/accountability_provider.dart';

/// Full-screen PIN verification for accountability lock.
///
/// Shown when user tries to:
/// - Unlock the app
/// - Skip a session
/// - Override a hard cap
///
/// Does NOT dismiss on back button — user must verify or exit.
class AccountabilityVerifyScreen extends StatefulWidget {
  /// Why the user was redirected here.
  final String reason;

  /// Called after successful verification.
  final VoidCallback onVerified;

  const AccountabilityVerifyScreen({
    super.key,
    required this.onVerified,
    this.reason = 'Enter guardian PIN to continue',
  });

  @override
  State<AccountabilityVerifyScreen> createState() =>
      _AccountabilityVerifyScreenState();
}

class _AccountabilityVerifyScreenState extends State<AccountabilityVerifyScreen> {
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _enteredPin =>
      _pinControllers.map((c) => c.text).join();

  void _clearPin() {
    for (final c in _pinControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _submit() async {
    final pin = _enteredPin;
    if (pin.length < 4) return;

    setState(() => _isLoading = true);

    final provider = context.read<AccountabilityProvider>();
    final success = await provider.verifyPin(pin);

    setState(() => _isLoading = false);

    if (success && mounted) {
      widget.onVerified();
    } else if (mounted && provider.isCooldown) {
      // Show cooldown message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Too many attempts'),
          backgroundColor: Colors.red,
          duration: const Duration(minutes: 1),
        ),
      );
    } else {
      _clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back button escape
      child: Scaffold(
        backgroundColor: DesignTokens.darkSurface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Guardian name
                  Consumer<AccountabilityProvider>(
                    builder: (context, provider, _) {
                      if (provider.guardianName != null) {
                        return Text(
                          'Guardian: ${provider.guardianName}',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBodySmall,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 8),

                  // Reason
                  Text(
                    widget.reason,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // PIN input row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 56,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            // Handle backspace on empty field
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.backspace &&
                                _pinControllers[i].text.isEmpty &&
                                i > 0) {
                              _pinControllers[i - 1].clear();
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                          child: TextField(
                            controller: _pinControllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            obscureText: true,
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeH2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.amber,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && i < 3) {
                                _focusNodes[i + 1].requestFocus();
                              }
                              if (value.isNotEmpty && i == 3) {
                                _submit();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  Consumer<AccountabilityProvider>(
                    builder: (context, provider, _) {
                      if (provider.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            provider.error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: DesignTokens.fontSizeSmall,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Attempts remaining
                  Consumer<AccountabilityProvider>(
                    builder: (context, provider, _) {
                      if (!provider.isCooldown &&
                          provider.verifyAttempts > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '${provider.remainingAttempts} attempts remaining',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: DesignTokens.fontSizeCaption,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Loading indicator
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber,
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // Hint text
                  Text(
                    '4-digit PIN set by your guardian',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

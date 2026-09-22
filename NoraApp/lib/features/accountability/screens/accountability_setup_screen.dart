import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/accountability_provider.dart';

/// Setup screen for accountability lock.
///
/// Flow:
/// 1. Guardian enters their name
/// 2. Guardian sets a 4-6 digit PIN
/// 3. Guardian optionally sets a duration (days)
/// 4. PIN is sent to backend (hashed with bcrypt) + stored locally
class AccountabilitySetupScreen extends StatefulWidget {
  const AccountabilitySetupScreen({super.key});

  @override
  State<AccountabilitySetupScreen> createState() =>
      _AccountabilitySetupScreenState();
}

class _AccountabilitySetupScreenState extends State<AccountabilitySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guardianNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _durationController = TextEditingController();
  final _currentPinController = TextEditingController();

  bool _isLoading = false;
  bool _showPin = false;
  int _currentStep = 0; // 0: guardian name, 1: PIN, 2: duration

  @override
  void initState() {
    super.initState();
    // Ensure lock status is loaded so we know if a current PIN is required
    context.read<AccountabilityProvider>().initialize();
  }

  @override
  void dispose() {
    _guardianNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _durationController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AccountabilityProvider>();
    final durationDays = int.tryParse(_durationController.text);
    // Replacing an active lock requires the current PIN
    final needsCurrentPin = provider.isLockActive && !provider.isExpired;

    final success = await provider.setupLock(
      pin: _pinController.text,
      guardianName: _guardianNameController.text.trim(),
      lockDurationDays: durationDays,
      currentPin: needsCurrentPin ? _currentPinController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 32,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lock Activated',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your guardian can now hold you accountable. '
              'You will need their PIN to skip sessions or override limits.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBodySmall,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.darkSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Accountability Lock',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildGuardianNameStep(),
                    _buildPinStep(),
                    _buildDurationStep(),
                  ],
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_currentStep < 2) {
                              if (_validateCurrentStep()) {
                                setState(() => _currentStep++);
                              }
                            } else {
                              _submit();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _currentStep < 2 ? 'Next' : 'Activate Lock',
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.person_outline,
            size: 48,
            color: Colors.amber.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
            const Text(
            'Who is setting this lock?',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitleMedium,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This person will hold you accountable. They choose the PIN.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodySmall,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _guardianNameController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Guardian Name',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              hintText: 'e.g., Mom, Dad, Sarah',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.amber.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Set the accountability PIN',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitleMedium,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '4-6 digits. The user cannot change this PIN themselves.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodySmall,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: !_showPin,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeH2,
              letterSpacing: 8,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • •',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                onPressed: () => setState(() => _showPin = !_showPin),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 4) return 'Minimum 4 digits';
              if (!RegExp(r'^\d+$').hasMatch(v)) return 'Numbers only';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeH2,
              letterSpacing: 8,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • •',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
            ),
            validator: (v) {
              if (v != _pinController.text) return 'PINs do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDurationStep() {
    final provider = context.watch<AccountabilityProvider>();
    final needsCurrentPin = provider.isLockActive && !provider.isExpired;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: Colors.amber.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lock duration',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitleMedium,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How long should this lock stay active?',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodySmall,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeSubhead,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'e.g., 30',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
              suffixText: 'days',
              suffixStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null; // optional
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Enter a positive number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Quick duration chips
          Wrap(
            spacing: 8,
            children: [
              _durationChip('7 days', 7),
              _durationChip('14 days', 14),
              _durationChip('30 days', 30),
              _durationChip('90 days', 90),
            ],
          ),
          // When replacing an active lock, verify the current PIN first
          if (needsCurrentPin) ...[
            const SizedBox(height: 32),
            const Text(
              'Enter current PIN to authorize replacement',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBodySmall,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeH2,
                letterSpacing: 8,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • •',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
              validator: (v) {
                if (!needsCurrentPin) return null;
                if (v == null || v.length < 4) return 'Enter the current PIN';
                if (!RegExp(r'^\d+$').hasMatch(v)) return 'Numbers only';
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _durationChip(String label, int days) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: DesignTokens.fontSizeSmall)),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        setState(() => _durationController.text = days.toString());
      },
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _guardianNameController.text.trim().isNotEmpty;
      case 1:
        return _pinController.text.length >= 4 &&
            _pinController.text == _confirmPinController.text;
      default:
        final provider = context.read<AccountabilityProvider>();
        final needsCurrentPin = provider.isLockActive && !provider.isExpired;
        if (needsCurrentPin && _currentPinController.text.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter the current PIN to authorize replacement'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
    }
  }
}

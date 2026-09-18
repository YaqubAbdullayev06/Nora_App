import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/nora_components.dart';

/// Onboarding Screen — two-step: name + account creation.
///
/// Step 0: Enter name → personalizes greetings
/// Step 1: Create account → email + password to save progress
///
/// Age group defaults to adult. Users can change persona later in Settings.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0 = name, 1 = account

  // Default to adult persona
  AgeGroup _selectedGroup = AgeGroup.adult;

  // Step 1: name
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  // Step 2: account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 1) {
      setState(() => _step++);
      _animController.reset();
      _animController.forward();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _animController.reset();
      _animController.forward();
    }
  }

  void _finish() async {
    final personaProvider = context.read<PersonaProvider>();
    final authProvider = context.read<AuthProvider>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validation
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (password.isEmpty) {
      _showError('Please create a password');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    // Set persona (default adult)
    personaProvider.setAgeGroup(_selectedGroup);

    // Register
    final success = await authProvider.register(
      email,
      name,
      password,
      ageGroup: _selectedGroup,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/setup-wizard');
    } else if (mounted) {
      _showError(authProvider.error ?? 'Registration failed. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button (on steps 1 and 2)
            if (_step > 0)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                  child: IconButton(
                    onPressed: _prevStep,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildStepIndicator(),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: _buildCurrentStep(),
              ),
            ),

            // Bottom area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  _buildBottomButton(),
                  if (_step == 1) ...[
                    const SizedBox(height: DesignTokens.spacing16),
                    _buildSignInLink(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ───

  Widget _buildStepIndicator() {
    final theme = _selectedGroup != null
        ? PersonaTheme.forAgeGroup(_selectedGroup!)
        : PersonaTheme.adultTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone
                ? theme.primary
                : isActive
                    ? theme.primary
                    : DesignTokens.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ─── Step Content Router ───

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildAccountStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Name Input ───

  Widget _buildNameStep() {
    final theme = PersonaTheme.forAgeGroup(_selectedGroup);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: DesignTokens.spacing24),
          NoraMascot(size: 100, showGlow: true, personaOverride: theme),
          const SizedBox(height: DesignTokens.spacing24),
          _buildStepHeader(
            title: 'What should Nora call you?',
            subtitle: 'Your name will appear in greetings and throughout the app.',
          ),
          const SizedBox(height: DesignTokens.spacing32),
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            hint: 'Enter your name',
            icon: Icons.person_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            'You can always change this later in Settings.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Account Creation ───

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing12),
      child: Column(
        children: [
          const SizedBox(height: DesignTokens.spacing16),
          _buildStepHeader(
            icon: Icons.lock_outline_rounded,
            title: 'Create your account',
            subtitle: 'Save your progress and access Nora on any device.',
          ),
          const SizedBox(height: DesignTokens.spacing24),
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DesignTokens.spacing14),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DesignTokens.spacing14),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Confirm password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _finish(),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            'By continuing, you agree to Nora\'s Terms of Service.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ───

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscure = false,
    VoidCallback? toggleObscure,
    void Function(String)? onSubmitted,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = PersonaTheme.forAgeGroup(_selectedGroup);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      style: TextStyle(
        color: DesignTokens.textPrimary,
        fontSize: DesignTokens.fontSizeBody,
        fontFamily: DesignTokens.fontFamilyPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: DesignTokens.textMuted,
          fontFamily: DesignTokens.fontFamilyPrimary,
        ),
        prefixIcon: Icon(icon, color: DesignTokens.textMuted),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: DesignTokens.textMuted,
                ),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          borderSide: BorderSide(color: DesignTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          borderSide: BorderSide(color: DesignTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          borderSide: BorderSide(color: theme.primary, width: 2),
        ),
        filled: true,
        fillColor: DesignTokens.surface,
      ),
    );
  }

  Widget _buildStepHeader({
    IconData? icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 48, color: DesignTokens.accent),
          const SizedBox(height: DesignTokens.spacing12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH1,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeBody,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final theme = PersonaTheme.forAgeGroup(_selectedGroup);

    String label;
    VoidCallback? onPressed;

    switch (_step) {
      case 0:
        label = 'Continue';
        onPressed = _nextStep;
        break;
      case 1:
        label = 'Create Account & Start';
        onPressed = _finish;
        break;
      default:
        label = 'Continue';
        onPressed = null;
    }

    return Consumer<AuthProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.isDark ? DesignTokens.background : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius20),
              ),
              elevation: 0,
            ),
            child: provider.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.isDark ? DesignTokens.background : Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeBodySmall,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: DesignTokens.accent,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

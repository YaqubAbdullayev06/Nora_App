import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Onboarding Screen — three-step personalization + account creation.
///
/// Step 0: Pick age group → sets Nora's persona
/// Step 1: Enter name → personalizes greetings
/// Step 2: Create account → email + password to save progress
///
/// Users arrive here from the Welcome screen (after learning what Nora is).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0 = age, 1 = name, 2 = account
  AgeGroup? _selectedGroup;

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
    if (_step < 2) {
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
    final provider = context.read<AppProvider>();
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

    // Set persona
    provider.setAgeGroup(_selectedGroup!);

    // Register
    final success = await provider.register(
      email,
      name,
      password,
      ageGroup: _selectedGroup!,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (mounted) {
      _showError(provider.error ?? 'Registration failed. Please try again.');
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
                  if (_step == 2) ...[
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
      children: List.generate(3, (i) {
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
        return _buildAgeStep();
      case 1:
        return _buildNameStep();
      case 2:
        return _buildAccountStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Age Group Selection ───

  Widget _buildAgeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing20, vertical: DesignTokens.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            emoji: '👤',
            title: 'Who\'s using Nora?',
            subtitle: 'This helps Nora adapt her personality and content.',
          ),
          const SizedBox(height: DesignTokens.spacing24),

          ...AgeGroup.values.map((group) {
            final theme = PersonaTheme.forAgeGroup(group);
            final isSelected = _selectedGroup == group;
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedGroup = group);
                  context.read<AppProvider>().setAgeGroup(group);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(DesignTokens.spacing16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primary.withValues(alpha: 0.15)
                        : DesignTokens.surface,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius20),
                    border: Border.all(
                      color: isSelected ? theme.primary : DesignTokens.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radius14),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radius14),
                          child: theme.mascotAssetPath != null
                              ? SvgPicture.asset(
                                  theme.mascotAssetPath!,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => Center(
                                    child: Text(theme.mascotEmoji,
                                        style: const TextStyle(fontSize: 26)),
                                  ),
                                )
                              : Center(
                                  child: Text(theme.mascotEmoji,
                                      style: const TextStyle(fontSize: 26)),
                                ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacing14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.primary
                                    : DesignTokens.textPrimary,
                                fontSize: DesignTokens.fontSizeBody,
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                fontFamily: DesignTokens.fontFamilyPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.ageRange,
                              style: TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeCaption,
                                fontFamily: DesignTokens.fontFamilyPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme.tagline,
                              style: TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeCaption,
                                fontStyle: FontStyle.italic,
                                fontFamily: DesignTokens.fontFamilyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: theme.primary, size: 24)
                      else
                        Icon(Icons.radio_button_unchecked,
                            color: DesignTokens.textMuted, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: DesignTokens.spacing12),
        ],
      ),
    );
  }

  // ─── Step 1: Name Input ───

  Widget _buildNameStep() {
    final theme = _selectedGroup != null
        ? PersonaTheme.forAgeGroup(_selectedGroup!)
        : PersonaTheme.adultTheme;

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
            emoji: null,
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
            emoji: '🔐',
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
    final theme = _selectedGroup != null
        ? PersonaTheme.forAgeGroup(_selectedGroup!)
        : PersonaTheme.adultTheme;

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
    String? emoji,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        if (emoji != null) ...[
          Text(emoji, style: const TextStyle(fontSize: 40)),
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
    final theme = _selectedGroup != null
        ? PersonaTheme.forAgeGroup(_selectedGroup!)
        : PersonaTheme.adultTheme;

    String label;
    VoidCallback? onPressed;

    switch (_step) {
      case 0:
        final isEnabled = _selectedGroup != null;
        label = isEnabled ? 'Continue' : 'Select an age group';
        onPressed = isEnabled ? _nextStep : null;
        break;
      case 1:
        label = 'Continue';
        onPressed = _nextStep;
        break;
      case 2:
        label = 'Create Account & Start';
        onPressed = _finish;
        break;
      default:
        label = 'Continue';
        onPressed = null;
    }

    return Consumer<AppProvider>(
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

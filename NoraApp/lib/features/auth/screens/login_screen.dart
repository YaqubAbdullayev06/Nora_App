import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/persona_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildForm(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildDemoButton(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [DesignTokens.accent, DesignTokens.accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accent.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'NORA',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeTitleLarge,
            fontWeight: DesignTokens.fontWeightBold,
            letterSpacing: 8,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Focus. Learn. Grow.',
          style: TextStyle(
            color: DesignTokens.accent,
            fontSize: DesignTokens.fontSizeBodySmall,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: DesignTokens.textPrimary),
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: DesignTokens.textMuted),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: DesignTokens.textPrimary),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline, color: DesignTokens.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: DesignTokens.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: DesignTokens.buttonHeightLarge,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _handleLogin,
            child: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.background,
                    ),
                  )
                : const Text('Sign In'),
          ),
        );
      },
    );
  }

  Widget _buildDemoButton() {
    return SizedBox(
      height: DesignTokens.buttonHeightLarge,
      child: OutlinedButton(
        onPressed: _handleDemoLogin,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: DesignTokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
        ),
        child: Text(
          'Try Demo Mode',
          style: TextStyle(color: DesignTokens.textMuted),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeBodySmall,
          ),
        ),
        GestureDetector(
          onTap: () {
            final personaProvider = context.read<PersonaProvider>();
            Navigator.pushNamed(context, '/register', arguments: personaProvider.ageGroup);
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: DesignTokens.accent,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    final provider = context.read<AuthProvider>();
    final success = await provider.login(email, password);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Login failed'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }

  void _handleDemoLogin() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }
}

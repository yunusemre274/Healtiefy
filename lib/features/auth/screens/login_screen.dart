import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
import '../../../widgets/buttons/soft_button.dart';
import '../../../widgets/inputs/soft_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (_emailController.text.isEmpty) {
        _emailError = AppStrings.emailRequired;
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = AppStrings.invalidEmail;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = AppStrings.passwordRequired;
      } else if (_passwordController.text.length < 6) {
        _passwordError = AppStrings.passwordTooShort;
      }
    });

    if (_emailError == null && _passwordError == null) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (!state.isProfileComplete) {
            context.go('/profile-setup');
          } else {
            context.go('/location-permission');
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo and welcome
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      AppStrings.welcomeBack,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in to continue your journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  // Email field
                  SoftTextField(
                    label: AppStrings.email,
                    hint: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.email_outlined,
                    errorText: _emailError,
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 20),
                  // Password field
                  SoftTextField(
                    label: AppStrings.password,
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outlined,
                    errorText: _passwordError,
                    onSubmitted: (_) => _validateAndSubmit(),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sign in button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SoftButton(
                        text: AppStrings.signIn,
                        onPressed: _validateAndSubmit,
                        isLoading: state is AuthLoading,
                        width: double.infinity,
                      ).animate().fadeIn(delay: 600.ms);
                    },
                  ),
                  const SizedBox(height: 32),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.orContinueWith,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 24),
                  // Social sign in buttons
                  Row(
                    children: [
                      Expanded(
                        child: SocialSignInButton(
                          text: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(AuthGoogleSignInRequested());
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SocialSignInButton(
                          text: 'Apple',
                          icon: Icons.apple,
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(AuthAppleSignInRequested());
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 32),
                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            AppStrings.signUp,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

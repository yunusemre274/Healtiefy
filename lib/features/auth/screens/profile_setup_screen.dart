import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../../../widgets/buttons/soft_button.dart';
import '../../../widgets/inputs/soft_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User data
  String _gender = 'male';
  int _age = 25;
  double _height = 170;
  double _weight = 70;
  int _dailyStepsGoal = 10000;
  int _weeklySessionsGoal = 5;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _completeSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void _completeSetup() {
    context.read<AuthBloc>().add(
          AuthProfileUpdateRequested(
            gender: _gender,
            age: _age,
            height: _height,
            weight: _weight,
            stepGoal: _dailyStepsGoal,
          ),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && state.isProfileComplete) {
          context.go('/location-permission');
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: _previousPage,
                )
              : null,
          title: Text('Profile Setup'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGenderPage(),
                    _buildAgePage(),
                    _buildMeasurementsPage(),
                    _buildGoalsPage(),
                  ],
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SoftButton(
                      text: _currentPage < 3 ? 'Continue' : 'Complete Setup',
                      onPressed: _nextPage,
                      isLoading: state is AuthLoading,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your gender?',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your health metrics accurately',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _GenderOption(
                  icon: Icons.male_rounded,
                  label: 'Male',
                  isSelected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderOption(
                  icon: Icons.female_rounded,
                  label: 'Female',
                  isSelected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How old are you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Age affects your metabolic rate calculations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: _age > 10 ? () => setState(() => _age--) : null,
                    iconSize: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_age',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    ' years',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _age < 100 ? () => setState(() => _age++) : null,
                    iconSize: 32,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }

  Widget _buildMeasurementsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your measurements',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Used to calculate calories burned and BMI',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          // Height
          NumberInputField(
            label: 'Height',
            value: _height.toInt(),
            unit: 'cm',
            min: 100,
            max: 250,
            onChanged: (value) => setState(() => _height = value.toDouble()),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          // Weight
          NumberInputField(
            label: 'Weight',
            value: _weight.toInt(),
            unit: 'kg',
            min: 30,
            max: 200,
            onChanged: (value) => setState(() => _weight = value.toDouble()),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your goals',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'We\'ll help you stay on track',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          // Daily steps goal
          _GoalSelector(
            icon: Icons.directions_walk_rounded,
            label: 'Daily Steps Goal',
            value: _dailyStepsGoal,
            unit: 'steps',
            options: [5000, 7500, 10000, 12500, 15000],
            onChanged: (value) =>
                setState(() => _dailyStepsGoal = value.toInt()),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          // Weekly sessions goal
          _GoalSelector(
            icon: Icons.calendar_today_rounded,
            label: 'Weekly Sessions Goal',
            value: _weeklySessionsGoal,
            unit: 'sessions',
            options: [3, 4, 5, 6, 7],
            onChanged: (value) =>
                setState(() => _weeklySessionsGoal = value.toInt()),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final num value;
  final String unit;
  final List<num> options;
  final ValueChanged<num> onChanged;

  const _GoalSelector({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${value.toInt()} $unit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = option == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        option >= 1000
                            ? '${(option / 1000).toStringAsFixed(option % 1000 == 0 ? 0 : 1)}k'
                            : option.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular progress with percentage in center
class CircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? child;
  final bool showPercentage;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 10,
    this.progressColor = AppColors.primary,
    this.backgroundColor = AppColors.progressBackground,
    this.child,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(backgroundColor),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                );
              },
            ),
          ),
          // Center content
          Center(
            child: child ??
                (showPercentage
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress * 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: size * 0.2,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          );
                        },
                      )
                    : null),
          ),
        ],
      ),
    );
  }
}

/// Linear progress bar with rounded ends
class LinearProgress extends StatelessWidget {
  final double progress;
  final double height;
  final Color? color;
  final Color progressColor;
  final Color backgroundColor;
  final bool animate;

  const LinearProgress({
    super.key,
    required this.progress,
    this.height = 12,
    this.color,
    this.progressColor = AppColors.primary,
    this.backgroundColor = AppColors.progressBackground,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? progressColor;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: animate
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: effectiveColor,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  );
                },
              )
            : FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Step progress indicator
class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? labels;
  final Color activeColor;
  final Color inactiveColor;

  const StepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.progressBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 4,
              color: stepIndex < currentStep ? activeColor : inactiveColor,
            ),
          );
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= currentStep;
          final isCurrent = stepIndex == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 32 : 24,
                height: isCurrent ? 32 : 24,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: activeColor.withValues(alpha: 0.3),
                          width: 4,
                        )
                      : null,
                ),
                child: Center(
                  child: isActive && !isCurrent
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              if (labels != null && stepIndex < labels!.length) ...[
                const SizedBox(height: 8),
                Text(
                  labels![stepIndex],
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          );
        }
      }),
    );
  }
}

/// Ring progress (like Apple Watch activity rings)
class RingProgress extends StatelessWidget {
  final List<double>? values;
  final List<Color>? colors;
  final double? progress;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Widget? child;

  const RingProgress({
    super.key,
    this.values,
    this.colors,
    this.progress,
    this.color,
    this.backgroundColor,
    this.size = 120,
    this.strokeWidth = 12,
    this.center,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Simple single-ring mode
    if (progress != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                backgroundColor ??
                    (color ?? AppColors.primary).withValues(alpha: 0.2),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress!),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation(color ?? AppColors.primary),
                );
              },
            ),
            if (child != null || center != null) Center(child: child ?? center),
          ],
        ),
      );
    }

    // Multi-ring mode (original implementation)
    final ringValues = values ?? [0.0];
    final ringColors = colors ?? [AppColors.primary];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Draw rings from outside to inside
          ...List.generate(ringValues.length, (index) {
            final ringSize = size - (index * strokeWidth * 2.5);
            final offset = index * strokeWidth * 1.25;
            final ringColor = index < ringColors.length
                ? ringColors[index]
                : AppColors.primary;

            return Positioned(
              left: offset,
              top: offset,
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  children: [
                    // Background
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        ringColor.withValues(alpha: 0.2),
                      ),
                    ),
                    // Progress
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ringValues[index]),
                      duration: Duration(milliseconds: 800 + (index * 200)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value.clamp(0.0, 1.0),
                          strokeWidth: strokeWidth,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(ringColor),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          // Center content
          if (center != null || child != null) Center(child: center ?? child),
        ],
      ),
    );
  }
}

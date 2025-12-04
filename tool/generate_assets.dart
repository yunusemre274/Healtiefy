// ignore_for_file: avoid_print
/// Script to generate logo and splash images for Healtiefy
/// Run with: dart run tool/generate_assets.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

Future<void> main() async {
  print('🎨 Generating Healtiefy logo and splash assets...\n');

  // Generate main logo (1024x1024)
  await generateLogo(1024, 'assets/images/logo.png');
  print('✅ Generated: assets/images/logo.png (1024x1024)');

  // Generate foreground for adaptive icon (1024x1024 with padding)
  await generateLogoForeground(1024, 'assets/images/logo_foreground.png');
  print('✅ Generated: assets/images/logo_foreground.png (1024x1024)');

  // Generate splash logo (512x512, centered design)
  await generateSplashLogo(512, 'assets/images/splash_logo.png');
  print('✅ Generated: assets/images/splash_logo.png (512x512)');

  print('\n🎉 All assets generated successfully!');
  print('\nNext steps:');
  print('1. Run: flutter pub get');
  print('2. Run: dart run flutter_launcher_icons');
  print('3. Run: dart run flutter_native_splash:create');
}

Future<void> generateLogo(int size, String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint();

  final center = size / 2;
  final radius = size * 0.47;

  // Background circle (dark)
  paint.color = const ui.Color(0xFF0A0F0F);
  canvas.drawCircle(ui.Offset(center, center), radius, paint);

  // Gradient ring
  paint.style = ui.PaintingStyle.stroke;
  paint.strokeWidth = size * 0.012;
  paint.shader = ui.Gradient.linear(
    ui.Offset(0, 0),
    ui.Offset(size.toDouble(), size.toDouble()),
    [const ui.Color(0xFF17F1C6), const ui.Color(0xFF00FF7D)],
  );
  canvas.drawCircle(ui.Offset(center, center), radius * 0.96, paint);

  // Walking figure
  paint.style = ui.PaintingStyle.fill;
  paint.shader = null;

  // Create gradient paint
  final gradientPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset(center - 100, center - 200),
      ui.Offset(center + 100, center + 100),
      [const ui.Color(0xFF17F1C6), const ui.Color(0xFF00FF7D)],
    );

  // Head
  canvas.drawCircle(
    ui.Offset(center, center - size * 0.18),
    size * 0.045,
    gradientPaint,
  );

  // Body
  gradientPaint.strokeWidth = size * 0.028;
  gradientPaint.style = ui.PaintingStyle.stroke;
  gradientPaint.strokeCap = ui.StrokeCap.round;
  canvas.drawLine(
    ui.Offset(center, center - size * 0.13),
    ui.Offset(center, center - size * 0.02),
    gradientPaint,
  );

  // Arms
  gradientPaint.strokeWidth = size * 0.022;
  canvas.drawLine(
    ui.Offset(center, center - size * 0.10),
    ui.Offset(center - size * 0.07, center - size * 0.05),
    gradientPaint,
  );
  canvas.drawLine(
    ui.Offset(center, center - size * 0.10),
    ui.Offset(center + size * 0.06, center - size * 0.13),
    gradientPaint,
  );

  // Legs
  gradientPaint.strokeWidth = size * 0.024;
  canvas.drawLine(
    ui.Offset(center, center - size * 0.02),
    ui.Offset(center - size * 0.05, center + size * 0.10),
    gradientPaint,
  );
  canvas.drawLine(
    ui.Offset(center, center - size * 0.02),
    ui.Offset(center + size * 0.05, center + size * 0.08),
    gradientPaint,
  );

  // Heart pulse line
  final pulsePath = ui.Path();
  final pulseY = center + size * 0.07;
  pulsePath.moveTo(center - size * 0.30, pulseY);
  pulsePath.lineTo(center - size * 0.18, pulseY);
  pulsePath.lineTo(center - size * 0.14, pulseY - size * 0.06);
  pulsePath.lineTo(center - size * 0.10, pulseY + size * 0.06);
  pulsePath.lineTo(center - size * 0.06, pulseY - size * 0.10);
  pulsePath.lineTo(center - size * 0.02, pulseY + size * 0.02);
  pulsePath.lineTo(center + size * 0.02, pulseY - size * 0.02);
  pulsePath.lineTo(center + size * 0.18, pulseY);
  pulsePath.lineTo(center + size * 0.30, pulseY);

  gradientPaint.strokeWidth = size * 0.010;
  gradientPaint.style = ui.PaintingStyle.stroke;
  canvas.drawPath(pulsePath, gradientPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  }
}

Future<void> generateLogoForeground(int size, String path) async {
  // Similar to generateLogo but with transparent background and more padding
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final center = size / 2;
  final scale = 0.6; // Smaller for adaptive icon safe zone

  // Create gradient paint
  final gradientPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset(center - 100, center - 200),
      ui.Offset(center + 100, center + 100),
      [const ui.Color(0xFF17F1C6), const ui.Color(0xFF00FF7D)],
    );

  // Head
  canvas.drawCircle(
    ui.Offset(center, center - size * 0.18 * scale),
    size * 0.055 * scale,
    gradientPaint,
  );

  // Body
  gradientPaint.strokeWidth = size * 0.035 * scale;
  gradientPaint.style = ui.PaintingStyle.stroke;
  gradientPaint.strokeCap = ui.StrokeCap.round;
  canvas.drawLine(
    ui.Offset(center, center - size * 0.13 * scale),
    ui.Offset(center, center + size * 0.02 * scale),
    gradientPaint,
  );

  // Arms
  gradientPaint.strokeWidth = size * 0.028 * scale;
  canvas.drawLine(
    ui.Offset(center, center - size * 0.08 * scale),
    ui.Offset(center - size * 0.10 * scale, center - size * 0.02 * scale),
    gradientPaint,
  );
  canvas.drawLine(
    ui.Offset(center, center - size * 0.08 * scale),
    ui.Offset(center + size * 0.08 * scale, center - size * 0.12 * scale),
    gradientPaint,
  );

  // Legs
  gradientPaint.strokeWidth = size * 0.030 * scale;
  canvas.drawLine(
    ui.Offset(center, center + size * 0.02 * scale),
    ui.Offset(center - size * 0.08 * scale, center + size * 0.18 * scale),
    gradientPaint,
  );
  canvas.drawLine(
    ui.Offset(center, center + size * 0.02 * scale),
    ui.Offset(center + size * 0.08 * scale, center + size * 0.15 * scale),
    gradientPaint,
  );

  // Heart pulse line
  final pulsePath = ui.Path();
  final pulseY = center + size * 0.25 * scale;
  final pulseScale = scale * 1.2;
  pulsePath.moveTo(center - size * 0.25 * pulseScale, pulseY);
  pulsePath.lineTo(center - size * 0.15 * pulseScale, pulseY);
  pulsePath.lineTo(
      center - size * 0.10 * pulseScale, pulseY - size * 0.05 * pulseScale);
  pulsePath.lineTo(
      center - size * 0.05 * pulseScale, pulseY + size * 0.05 * pulseScale);
  pulsePath.lineTo(center, pulseY - size * 0.08 * pulseScale);
  pulsePath.lineTo(
      center + size * 0.05 * pulseScale, pulseY + size * 0.02 * pulseScale);
  pulsePath.lineTo(center + size * 0.15 * pulseScale, pulseY);
  pulsePath.lineTo(center + size * 0.25 * pulseScale, pulseY);

  gradientPaint.strokeWidth = size * 0.012 * scale;
  gradientPaint.style = ui.PaintingStyle.stroke;
  canvas.drawPath(pulsePath, gradientPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  }
}

Future<void> generateSplashLogo(int size, String path) async {
  // Similar to foreground but optimized for splash
  await generateLogoForeground(size, path);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/core/theme/app_theme.dart';
import 'package:sankar_group/core/theme/app_text_styles.dart';
import 'package:sankar_group/core/theme/app_colors.dart';

Future<Color?> _resolvedBodyColor(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(body: Text('hello', style: AppTextStyles.body)),
  ));
  final textWidget = tester.widget<Text>(find.text('hello'));
  final context = tester.element(find.text('hello'));
  return DefaultTextStyle.of(context).style.merge(textWidget.style).color;
}

void main() {
  testWidgets('AppTextStyles.body is dark-on-light in light theme', (tester) async {
    final color = await _resolvedBodyColor(tester, AppTheme.light);
    expect(color, AppColors.textPrimary);
  });

  testWidgets('AppTextStyles.body is light-on-dark in dark theme', (tester) async {
    final color = await _resolvedBodyColor(tester, AppTheme.dark);
    expect(color, AppColorsDark.textPrimary);
  });
}

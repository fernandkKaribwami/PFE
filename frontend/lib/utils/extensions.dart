import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Extensions utiles pour les widgets Flutter
extension PaddingExtension on Widget {
  Padding paddingAll(double padding) => Padding(
    padding: EdgeInsets.all(padding),
    child: this,
  );

  Padding paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Padding paddingOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
        ),
        child: this,
      );
}

/// Extension pour les espacements rapides
extension SpacingExtension on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

/// Extension pour les décorateurs customs
extension DecorationExtension on Widget {
  Container withRoundedBorder({
    Color borderColor = const Color(0xFFE0E0E0),
    double radius = 12,
    double elevation = 0,
    Color backgroundColor = Colors.white,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.1 * (elevation / 10),
                    ),
                    blurRadius: elevation,
                    offset: Offset(0, elevation / 2),
                  ),
                ]
              : null,
        ),
        child: this,
      );
}

/// Extension pour les responsive layouts
extension ResponsiveExtension on BuildContext {
  bool get isSmallScreen => MediaQuery.of(this).size.width < 480;
  bool get isMediumScreen =>
      MediaQuery.of(this).size.width >= 480 &&
      MediaQuery.of(this).size.width < 840;
  bool get isLargeScreen => MediaQuery.of(this).size.width >= 840;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get topPadding => MediaQuery.of(this).padding.top;
}

/// Extension pour les couleurs
extension ColorExtension on Color {
  Color get lighter => withValues(alpha: 0.5);
  Color get darker => withValues(alpha: 0.8);
  Color withAlpha(int alphaValue) => Color.fromARGB(
    alphaValue,
    (r * 255.0).round() & 0xff,
    (g * 255.0).round() & 0xff,
    (b * 255.0).round() & 0xff,
  );
}

/// Extension pour les styles de texte
extension TextStyleExtension on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle bold() => copyWith(fontWeight: FontWeight.bold);
  TextStyle semiBold() => copyWith(fontWeight: FontWeight.w600);
  TextStyle regular() => copyWith(fontWeight: FontWeight.w400);
}

/// Extension pour les EdgeInsets
extension EdgeInsetsExtension on EdgeInsets {
  EdgeInsets inflateSymmetrically({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.only(
        left: left + horizontal,
        right: right + horizontal,
        top: top + vertical,
        bottom: bottom + vertical,
      );
}

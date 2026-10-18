import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFF26B1D);
  static const primaryDark = Color(0xFFC9520D);
  static const primaryLight = Color(0xFFFFE6D6);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF1F2A44);
  static const secondaryLight = Color(0xFFE8EBF2);
  static const onSecondary = Color(0xFFFFFFFF);

  // Neutrals (light surfaces)
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F6);
  static const border = Color(0xFFE3E6EC);
  static const borderStrong = Color(0xFFC9CED8);
  static const textPrimary = Color(0xFF1B2130);
  static const textSecondary = Color(0xFF5B6475);
  static const textDisabled = Color(0xFF9AA1AF);
  static const overlay = Color(0x661B2130); // 40% opacity

  // Semantic
  static const success = Color(0xFF1E9E5A);
  static const successTint = Color(0xFFE3F6EC);
  static const warning = Color(0xFFE59A0B);
  static const warningTint = Color(0xFFFFF3D6);
  static const error = Color(0xFFD93C3C);
  static const errorTint = Color(0xFFFDE7E7);
  static const info = Color(0xFF2F6FDE);
  static const infoTint = Color(0xFFE4EEFD);
  static const paused = Color(0xFF7A52CC);
  static const pausedTint = Color(0xFFEEE8FA);

  // Hero Gradient
  static const heroGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [primary, Color(0xFFFF8A47)],
  );

  // Chart Palette
  static const chartRevenue = Color(0xFF1E9E5A);
  static const chartExpenses = Color(0xFFD93C3C);
  static const chartNetProfit = Color(0xFFF26B1D);
  static const chartNewMembers = Color(0xFF2F6FDE);
  static const chartGrid = Color(0xFFE3E6EC);

  // Backward-compatibility Aliases
  static const backgroundLight = background;
  static const surfaceLight = surface;
  static const cardLight = surface;
  static const backgroundDark = background;
  static const surfaceDark = surface;
  static const cardDark = surface;

  static const textPrimaryLight = textPrimary;
  static const textSecondaryLight = textSecondary;
  static const textPrimaryDark = textPrimary;
  static const textSecondaryDark = textSecondary;

  static const borderLight = border;
  static const borderDark = border;

  static const danger = error;
  static const accent = primary;

  static const activeMembers = info;
  static const newSubscriptions = success;
  static const expiringSoon = warning;
  static const netProfitPositive = success;
  static const netProfitNegative = error;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';
import '../widgets/settings_group_card.dart';
import 'export_sheet.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_cubit.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_state.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/change_pin_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _notificationsEnabled = true;
  int _daysBeforeExpiry = 3;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final enabledStr = await _storage.read(key: 'notifications_enabled');
      final daysStr = await _storage.read(key: 'notification_days_before');

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabledStr == null || enabledStr == 'true';
          _daysBeforeExpiry = daysStr != null ? int.tryParse(daysStr) ?? 3 : 3;
          _isLoadingPreferences = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _storage.write(key: 'notifications_enabled', value: value.toString());

    final notifService = sl<NotificationService>();
    if (!value) {
      await notifService.cancelAll();
    } else {
      await notifService.requestPermission();
    }
  }

  Future<void> _setDaysBeforeExpiry(int days) async {
    setState(() {
      _daysBeforeExpiry = days;
    });
    await _storage.write(key: 'notification_days_before', value: days.toString());
  }

  String _formatBackupTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months شهر';
    } else if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? "يوم" : "أيام"}';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? "ساعة" : "ساعات"}';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BackupCubit>()..init(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'الإعدادات',
            style: AppTextStyles.titleLarge,
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        body: BlocConsumer<BackupCubit, BackupState>(
          listener: (context, state) {
            if (state.status == BackupStatus.success && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.successMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state.status == BackupStatus.failure && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final backupSubtitle = state.lastBackup != null
                ? 'آخر نسخة: ${_formatBackupTimeAgo(state.lastBackup!.createdAt)}'
                : 'لم يتم إنشاء نسخة احتياطية بعد';

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              children: [
                // Group 1: البيانات
                SettingsGroupCard(
                  title: 'البيانات',
                  tiles: [
                    SettingsTileData(
                      icon: Icons.backup_rounded,
                      iconColor: AppColors.primary,
                      iconBackgroundColor: AppColors.primaryLight,
                      title: 'النسخ الاحتياطي والاستعادة',
                      subtitle: backupSubtitle,
                      onTap: () => context.push(AppRoutes.backup),
                    ),
                    SettingsTileData(
                      icon: Icons.cloud_upload_rounded,
                      iconColor: AppColors.info,
                      iconBackgroundColor: AppColors.infoTint,
                      title: 'نسخ احتياطي الآن',
                      subtitle: 'إنشاء نسخة ومشاركتها فوراً',
                      trailing: state.status == BackupStatus.inProgress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : null,
                      onTap: state.isLoading
                          ? null
                          : () => context.read<BackupCubit>().createBackup(),
                    ),
                    SettingsTileData(
                      icon: Icons.ios_share_rounded,
                      iconColor: AppColors.success,
                      iconBackgroundColor: AppColors.successTint,
                      title: 'تصدير المشتركين',
                      subtitle: 'تصدير بصيغة Excel (CSV) أو PDF',
                      onTap: () => ExportSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Group 2: الأمان وحماية البيانات
                BlocBuilder<SecurityCubit, SecurityState>(
                  builder: (context, securityState) {
                    final hasCustomPin = securityState.hasCustomPin;
                    return SettingsGroupCard(
                      title: 'الأمان وحماية البيانات',
                      tiles: [
                        SettingsTileData(
                          icon: Icons.shield_rounded,
                          iconColor: AppColors.primary,
                          iconBackgroundColor: AppColors.primaryLight,
                          title: 'قفل البيانات المالية والإحصائيات',
                          subtitle: 'تمويه بطاقات لوحة التحكم وقفل الحسابات برمز مرور',
                          trailing: Switch.adaptive(
                            value: securityState.isSecurityEnabled,
                            activeTrackColor: AppColors.primary,
                            activeThumbColor: AppColors.surface,
                            onChanged: (val) {
                              context.read<SecurityCubit>().setSecurityEnabled(val);
                            },
                          ),
                        ),
                        SettingsTileData(
                          icon: Icons.key_rounded,
                          iconColor: AppColors.secondary,
                          iconBackgroundColor: AppColors.secondaryLight,
                          title: 'تغيير رمز المرور',
                          subtitle: hasCustomPin
                              ? 'تم تعيين رمز مرور مخصص'
                              : 'رمز المرور الحالي: 0000 (افتراضي)',
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textDisabled,
                          ),
                          onTap: () async {
                            final changed = await ChangePinDialog.show(context);
                            if (changed == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'تم تحديث رمز المرور بنجاح',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (securityState.isSecurityEnabled && !securityState.isLocked)
                          SettingsTileData(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.warning,
                            iconBackgroundColor: AppColors.warningTint,
                            title: 'قفل البيانات الآن',
                            subtitle: 'إعادة تمويه البطاقات وقفل قسم الحسابات فوراً',
                            onTap: () {
                              context.read<SecurityCubit>().lock();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                  content: Text('تم قفل البيانات الحساسة بنجاح'),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Group 3: التنبيهات
                SettingsGroupCard(
                  title: 'التنبيهات',
                  tiles: [
                    SettingsTileData(
                      icon: Icons.notifications_active_rounded,
                      iconColor: AppColors.primary,
                      iconBackgroundColor: AppColors.primaryLight,
                      title: 'تفعيل التنبيهات',
                      subtitle: 'تنبيهات لاقتراب موعد انتهاء الاشتراكات',
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: AppColors.surface,
                        onChanged: _isLoadingPreferences ? null : _toggleNotifications,
                      ),
                    ),
                    SettingsTileData(
                      icon: Icons.event_available_rounded,
                      iconColor: AppColors.secondary,
                      iconBackgroundColor: AppColors.secondaryLight,
                      title: 'التنبيه قبل الانتهاء',
                      subtitle: '$_daysBeforeExpiry أيام قبل موعد الانتهاء',
                      trailing: DropdownButton<int>(
                        value: _daysBeforeExpiry,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onChanged: _notificationsEnabled && !_isLoadingPreferences
                            ? (val) {
                                if (val != null) _setDaysBeforeExpiry(val);
                              }
                            : null,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('يوم واحد')),
                          DropdownMenuItem(value: 3, child: Text('3 أيام')),
                          DropdownMenuItem(value: 5, child: Text('5 أيام')),
                          DropdownMenuItem(value: 7, child: Text('7 أيام')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Group 3: عن التطبيق
                SettingsGroupCard(
                  title: 'عن التطبيق',
                  tiles: [
                    SettingsTileData(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textSecondary,
                      iconBackgroundColor: AppColors.surfaceVariant,
                      title: 'إصدار التطبيق',
                      subtitle: '1.0.0 (1)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successTint,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'أحدث إصدار',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SettingsTileData(
                      icon: Icons.fitness_center_rounded,
                      iconColor: AppColors.primary,
                      iconBackgroundColor: AppColors.primaryLight,
                      title: 'نظام إدارة الجيم',
                      subtitle: 'إدارة متكاملة للمشتركين والاشتراكات والمدفوعات',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

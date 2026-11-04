import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

class AppSecurityBarrier extends StatefulWidget {
  final Widget child;

  const AppSecurityBarrier({super.key, required this.child});

  @override
  State<AppSecurityBarrier> createState() => _AppSecurityBarrierState();
}

class _AppSecurityBarrierState extends State<AppSecurityBarrier>
    with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (sl.isRegistered<SecurityCubit>()) {
        final cubit = sl<SecurityCubit>();
        if (cubit.state.isSecurityEnabled) {
          cubit.lock();
          if (!_isBackgrounded && mounted) {
            setState(() {
              _isBackgrounded = true;
            });
          }
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isBackgrounded && mounted) {
        setState(() {
          _isBackgrounded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, securityState) {
        final showPrivacyShield =
            _isBackgrounded && securityState.isSecurityEnabled;

        return Stack(
          textDirection: TextDirection.rtl,
          children: [
            widget.child,
            if (showPrivacyShield)
              Positioned.fill(
                child: Container(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'نظام إدارة الجيم محمي',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'البيانات محمية • أدخل رمز المرور عند فتح التطبيق',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

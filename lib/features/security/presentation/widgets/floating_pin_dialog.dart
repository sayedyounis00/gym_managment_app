import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/security_cubit.dart';
import 'pin_pad.dart';

class FloatingPinDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const FloatingPinDialog({
    super.key,
    this.title = 'حماية البيانات',
    this.subtitle = 'أدخل رمز المرور المكون من 4 أرقام للمتابعة',
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'حماية البيانات',
    String subtitle = 'أدخل رمز المرور المكون من 4 أرقام للمتابعة',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FloatingPinDialog(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<FloatingPinDialog> createState() => _FloatingPinDialogState();
}

class _FloatingPinDialogState extends State<FloatingPinDialog>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isChecking = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_isChecking || _enteredPin.length >= 4) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_isChecking || _enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClearPressed() {
    if (_isChecking) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = '';
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isChecking = true;
    });

    final cubit = sl<SecurityCubit>();
    final isSuccess = await cubit.verifyAndUnlock(_enteredPin);

    if (!mounted) return;

    if (isSuccess) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'رمز المرور غير صحيح، يرجى المحاولة مرة أخرى';
        _enteredPin = '';
        _isChecking = false;
      });
      _shakeController.forward(from: 0.0);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.backspace) {
        _onDeletePressed();
      } else if (key == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(false);
      } else {
        final char = event.character;
        if (char != null && RegExp(r'^\d$').hasMatch(char)) {
          _onDigitPressed(char);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityCubit = sl<SecurityCubit>();
    final isDefaultPin = !securityCubit.state.hasCustomPin;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Top close button & Shield Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.textSecondary,
                        tooltip: 'إغلاق',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title & Subtitle
                  Text(
                    widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // PIN Dots with Shake Animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final dx = _shakeController.isAnimating
                          ? (_shakeAnimation.value * (_shakeAnimation.value.toInt().isEven ? 1 : -1))
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _enteredPin.length;
                        final hasError = _errorMessage != null;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? (hasError ? AppColors.error : AppColors.primary)
                                : Colors.transparent,
                            border: Border.all(
                              color: hasError
                                  ? AppColors.error
                                  : (isFilled ? AppColors.primary : AppColors.borderStrong),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorTint,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Numeric Keypad
                  PinPad(
                    onDigitPressed: _onDigitPressed,
                    onDeletePressed: _onDeletePressed,
                    onClearPressed: _onClearPressed,
                  ),

                  if (isDefaultPin) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'الرمز الافتراضي: 0000',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

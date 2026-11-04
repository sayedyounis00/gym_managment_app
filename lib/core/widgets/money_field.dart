import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class MoneyField extends StatefulWidget {
  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;
  final String? errorText;
  final String? helperText;
  final bool enabled;

  const MoneyField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialString = widget.initialValue > 0
        ? (widget.initialValue % 1 == 0
            ? widget.initialValue.toInt().toString()
            : widget.initialValue.toString())
        : '';
    _controller = TextEditingController(text: initialString);
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      final currentParsed = double.tryParse(_controller.text) ?? 0.0;
      if (currentParsed != widget.initialValue) {
        final newStr = widget.initialValue > 0
            ? (widget.initialValue % 1 == 0
                ? widget.initialValue.toInt().toString()
                : widget.initialValue.toString())
            : '';
        _controller.text = newStr;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (text) {
            final val = double.tryParse(text) ?? 0.0;
            widget.onChanged(val);
          },
          style: AppTextStyles.bodyLarge.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: '0',
            errorText: widget.errorText,
            helperText: widget.helperText,
            prefixIcon: const Icon(
              Icons.payments_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'ج.م',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

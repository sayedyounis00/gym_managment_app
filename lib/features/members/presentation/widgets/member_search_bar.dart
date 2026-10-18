import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';

class MemberSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String? initialValue;

  const MemberSearchBar({
    super.key,
    required this.onChanged,
    this.onClear,
    this.initialValue,
  });

  @override
  State<MemberSearchBar> createState() => _MemberSearchBarState();
}

class _MemberSearchBarState extends State<MemberSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (val) {
          widget.onChanged(val);
          setState(() {});
        },
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو رقم الهاتف...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.textDisabled,
                    size: 18,
                  ),
                  tooltip: 'مسح البحث',
                  onPressed: _clear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/add_payment_sheet.dart';

class AddPaymentPage extends StatelessWidget {
  final int? preselectedMemberId;

  const AddPaymentPage({super.key, this.preselectedMemberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تسجيل دفعة', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: AddPaymentSheet(preselectedMemberId: preselectedMemberId),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/empty_state.dart';
import 'package:gym_managment_app/core/widgets/loaders/package_card_skeleton.dart';
import '../cubit/packages/packages_cubit.dart';
import '../cubit/packages/packages_state.dart';
import '../widgets/package_card.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  @override
  void initState() {
    super.initState();
    context.read<PackagesCubit>().init();
  }

  void _openCreatePackage() {
    context.push(AppRoutes.addPackage);
  }

  void _openEditPackage(int id) {
    context.push(AppRoutes.editPackagePath(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الباقات'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePackage,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إنشاء باقة'),
      ),
      body: BlocBuilder<PackagesCubit, PackagesState>(
        builder: (context, state) {
          if (state is PackagesLoading || state is PackagesInitial) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: PackageListSkeleton(count: 4),
            );
          }

          if (state is PackagesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: const BoxDecoration(
                        color: AppColors.errorTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'حدث خطأ أثناء تحميل الباقات',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.message,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => context.read<PackagesCubit>().init(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PackagesEmpty) {
            return EmptyState(
              icon: Icons.card_membership_rounded,
              title: 'لا توجد بااقات بعد',
              subtitle: 'أنشئ باقات باشتراكات شهرية أو يومية لتبدأ في تسجيل المشتركين',
              actionLabel: 'إنشاء أول باقة',
              onAction: _openCreatePackage,
            );
          }

          if (state is PackagesLoaded) {
            final packages = state.packages;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth >= 600;

                Widget content;
                if (isLargeScreen) {
                  content = GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisExtent: 185,
                    ),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      return PackageCard(
                        package: pkg,
                        onEdit: () => _openEditPackage(pkg.id),
                        onToggleActive: (val) => context.read<PackagesCubit>().toggleActive(pkg.id, val),
                      );
                    },
                  );
                } else {
                  content = ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom: 88, // Space for FAB
                    ),
                    itemCount: packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      return PackageCard(
                        package: pkg,
                        onEdit: () => _openEditPackage(pkg.id),
                        onToggleActive: (val) => context.read<PackagesCubit>().toggleActive(pkg.id, val),
                      );
                    },
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: content,
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

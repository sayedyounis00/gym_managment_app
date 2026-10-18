import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/domain/entities/subscription_history_item.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/body_stats_card.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/current_membership_card.dart';
import 'package:gym_managment_app/core/widgets/image_preview_dialog.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/member_avatar.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/member_card.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/member_photo_picker.dart';

void main() {
  Widget wrapWidget(Widget child, {double width = 360, double height = 640}) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: const TextScaler.linear(1.0),
          ),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  group('Member Management Responsive Component Tests', () {
    testWidgets('MemberCard renders correctly on 360dp phone without overflow', (tester) async {
      const summary = MemberSummary(
        id: 1,
        name: 'كابتن عبد الرحمن مصطفى',
        phone: '01012345678',
        packageName: 'باقة اللياقة الذهبية',
        status: MemberStatusType.active,
        daysLeft: 23,
        subscriptionEndDate: null,
      );

      await tester.pumpWidget(
        wrapWidget(
          MemberCard(member: summary, onTap: () {}),
          width: 360,
        ),
      );

      expect(find.text('كابتن عبد الرحمن مصطفى'), findsOneWidget);
      expect(find.text('01012345678 · باقة اللياقة الذهبية'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byTooltip('مراسلة واتساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BodyStatsCard renders 3-cell metric row without overflow', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const BodyStatsCard(
            age: 26,
            weightKg: 82.5,
            heightCm: 184.0,
          ),
          width: 340,
        ),
      );

      expect(find.text('العمر'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('الوزن'), findsOneWidget);
      expect(find.text('82.5'), findsOneWidget);
      expect(find.text('الطول'), findsOneWidget);
      expect(find.text('184'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CurrentMembershipCard renders progress bar and remaining amount', (tester) async {
      final now = DateTime.now();
      final sub = SubscriptionHistoryItem(
        id: 1,
        memberId: 1,
        packageName: 'اشتراك سنوي VIP',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 60)),
        price: 3000.0,
        paidAmount: 2000.0,
        status: MemberStatusType.active,
      );

      await tester.pumpWidget(
        wrapWidget(
          CurrentMembershipCard(
            subscription: sub,
            status: MemberStatusType.active,
            onRenew: () {},
          ),
          width: 360,
        ),
      );

      expect(find.text('اشتراك سنوي VIP'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive text scale 1.3x renders without clipping or overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const Scaffold(
                body: BodyStatsCard(age: 30, weightKg: 75, heightCm: 175),
              ),
            ),
          ),
        ),
      );

      expect(find.text('العمر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemberDetails TabBar renders all 3 tabs fully without overflow on narrow 320dp screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.0),
              ),
              child: Scaffold(
                body: DefaultTabController(
                  length: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const TabBar(
                      labelPadding: EdgeInsets.symmetric(horizontal: 2),
                      tabs: [
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('الاشتراكات', maxLines: 1))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('المدفوعات', maxLines: 1))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('الملاحظات', maxLines: 1))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('الاشتراكات'), findsOneWidget);
      expect(find.text('المدفوعات'), findsOneWidget);
      expect(find.text('الملاحظات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemberPhotoPicker allows tapping photo to open ImagePreviewDialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MemberPhotoPicker(
                name: 'محمد أحمد',
                newPhotoFile: File('dummy.jpg'),
                onPhotoSelected: (_) {},
                onPhotoRemoved: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MemberPhotoPicker), findsOneWidget);

      await tester.tap(find.byType(MemberAvatar));
      await tester.pumpAndSettle();

      expect(find.byType(ImagePreviewDialog), findsOneWidget);
      expect(find.text('محمد أحمد'), findsOneWidget);
      expect(find.text('يمكنك التكبير والتصغير بإصبعين'), findsOneWidget);

      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.byType(ImagePreviewDialog), findsNothing);
    });

    testWidgets('Subscription item renders packageName and paymentMethod chip', (tester) async {
      final now = DateTime.now();
      final sub = SubscriptionHistoryItem(
        id: 1,
        memberId: 1,
        packageName: 'باقة شهرية ذهبية',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        price: 350.0,
        paidAmount: 350.0,
        status: MemberStatusType.active,
        paymentMethod: 'cash',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.xs + 2,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(sub.packageName, style: AppTextStyles.titleMedium),
                            if (sub.paymentMethod != null)
                              StatusChip.paymentMethod(sub.paymentMethod!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('باقة شهرية ذهبية'), findsOneWidget);
      expect(find.text('نقدي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

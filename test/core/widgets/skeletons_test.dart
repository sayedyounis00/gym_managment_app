import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gym_managment_app/core/theme/app_skeleton_theme.dart';
import 'package:gym_managment_app/core/widgets/loading_indicator.dart';
import 'package:gym_managment_app/core/widgets/skeletons/skeletons.dart';

void main() {
  Widget testWrapper(Widget child, {TextDirection direction = TextDirection.rtl}) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: SkeletonizerConfig(
          data: AppSkeletonTheme.config,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('Skeletonizer Theme & Configuration Tests', () {
    test('AppSkeletonTheme provides custom light & dark shimmer effects', () {
      final config = AppSkeletonTheme.config;

      expect(config.enableSwitchAnimation, isTrue);
      expect(config.justifyMultiLineText, isTrue);
      expect(config.ignoreContainers, isFalse);
      expect(config.switchAnimationConfig.duration, const Duration(milliseconds: 250));

      final lightResolved = config.resolveEffect(Brightness.light);
      expect(lightResolved, isA<LiquidGlassEffect>());

      final darkResolved = config.resolveEffect(Brightness.dark);
      expect(darkResolved, isA<LiquidGlassEffect>());
    });
  });

  group('Skeleton Widgets Rendering Tests', () {
    testWidgets('DashboardSkeleton renders correctly without error or overflow', (tester) async {
      await tester.pumpWidget(
        testWrapper(const DashboardSkeleton()),
      );

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(find.byType(AppSkeletonizer), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MembersListSkeleton renders without header by default', (tester) async {
      await tester.pumpWidget(
        testWrapper(const MembersListSkeleton(itemCount: 4)),
      );

      expect(find.byType(MembersListSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MembersListSkeleton renders with header when enabled', (tester) async {
      await tester.pumpWidget(
        testWrapper(const MembersListSkeleton(itemCount: 3, showHeader: true)),
      );

      expect(find.byType(MembersListSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemberDetailsSkeleton renders full member profile skeleton', (tester) async {
      await tester.pumpWidget(
        testWrapper(const MemberDetailsSkeleton()),
      );

      expect(find.byType(MemberDetailsSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AttendanceSkeleton renders calendar day cells and header', (tester) async {
      await tester.pumpWidget(
        testWrapper(const AttendanceSkeleton()),
      );

      expect(find.byType(AttendanceSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NotesSkeleton renders add action and note cards', (tester) async {
      await tester.pumpWidget(
        testWrapper(const NotesSkeleton(itemCount: 2)),
      );

      expect(find.byType(NotesSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemberFormSkeleton renders form input placeholders and buttons', (tester) async {
      await tester.pumpWidget(
        testWrapper(const MemberFormSkeleton()),
      );

      expect(find.byType(MemberFormSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoadingIndicator.skeleton renders skeleton mode', (tester) async {
      await tester.pumpWidget(
        testWrapper(const LoadingIndicator.skeleton()),
      );

      expect(find.byWidgetPredicate((w) => w is LoadingIndicator), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

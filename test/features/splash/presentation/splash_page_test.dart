import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders logo with white background and navigates to dashboard', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(
            duration: Duration(milliseconds: 1000),
          ),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const Scaffold(body: Text('لوحة التحكم')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    // Verify Scaffold background color is white
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);

    // Verify Image.asset is rendered with spear-gym-logo
    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect((imageWidget.image as AssetImage).assetName, 'assets/icons/spear-gym-logo.png');

    // Dashboard should not be visible initially
    expect(find.text('لوحة التحكم'), findsNothing);

    // Forward past the duration
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // Verify navigated to dashboard
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}

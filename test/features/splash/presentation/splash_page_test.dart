import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders animated GIF asset and navigates to dashboard', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const Scaffold(body: Text('لوحة التحكم')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    // Verify Image.asset is rendered
    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect((imageWidget.image as AssetImage).assetName, 'assets/gif/splash-screen.gif');

    // Dashboard should not be visible initially
    expect(find.text('لوحة التحكم'), findsNothing);

    // Fast-forward timer past 3500ms
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    // Verify navigated to dashboard
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}

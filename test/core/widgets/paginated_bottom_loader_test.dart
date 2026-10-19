import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/paginated_bottom_loader.dart';

void main() {
  group('PaginatedBottomLoader Tests', () {
    testWidgets('renders nothing when isLoading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaginatedBottomLoader(isLoading: false),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('جاري تحميل المزيد...'), findsNothing);
    });

    testWidgets('renders loader and text when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaginatedBottomLoader(isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جاري تحميل المزيد...'), findsOneWidget);
    });

    testWidgets('renders custom loading text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaginatedBottomLoader(
              isLoading: true,
              loadingText: 'تحميل المزيد من الباقات...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('تحميل المزيد من الباقات...'), findsOneWidget);
    });
  });
}

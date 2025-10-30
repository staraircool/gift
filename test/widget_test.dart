// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:giftdrop/main.dart';

void main() {
  testWidgets('renders featured airdrops with neubrutal styling', (tester) async {
    await tester.pumpWidget(
      GiftDropApp(
        repository: AirdropRepository(null),
        firebaseReady: false,
      ),
    );

    // Allow async layout to settle without waiting on font loading futures.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('GIFTDROP'), findsOneWidget);
    expect(find.text('FEATURED'), findsOneWidget);
    expect(find.text('Galaxy Gift Drop'), findsOneWidget);
  });
}

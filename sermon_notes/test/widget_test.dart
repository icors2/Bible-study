import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sermon_notes/main.dart';

void main() {
  testWidgets('App shows sermon and bible navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SermonNotesApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sermon outline'), findsOneWidget);
    expect(find.text('Bible'), findsWidgets);
  });
}

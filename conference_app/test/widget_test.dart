import 'package:flutter_test/flutter_test.dart';
import 'package:conference_app/main.dart';

void main() {
  testWidgets('ICSC app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ICSCApp());

    expect(find.text('ICSC 2027'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Speakers'), findsWidgets);
  });
}

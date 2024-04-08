import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Weather data display test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    await tester.pump(Duration(seconds: 3));

    expect(find.text('Loading...'), findsNothing);
    
    expect(find.textContaining('Temperature:'), findsOneWidget);

    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    expect(find.byIcon(Icons.cloud), findsOneWidget);

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

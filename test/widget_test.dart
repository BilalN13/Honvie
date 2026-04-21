import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honvie_v2/main.dart';

void main() {
  testWidgets('loads the main navigation and switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HonvieApp());

    expect(find.text("Today's check-in"), findsOneWidget);
    expect(find.text('Mood chart'), findsOneWidget);

    await tester.tap(find.text('Explorer').last);
    await tester.pumpAndSettle();
    expect(find.text('Lieux recommandes autour de toi'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/honvie-icon-light-128.png',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quelle est ton humeur du moment ?'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Historique').last);
    await tester.pumpAndSettle();
    expect(find.text('Aucun check-in pour le moment'), findsOneWidget);

    await tester.tap(find.text('Stats').last);
    await tester.pumpAndSettle();
    expect(find.text('Pas encore de donnees'), findsOneWidget);
  });
}

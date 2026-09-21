import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_mutex_example/main.dart';

void main() {
  testWidgets('offers separate mutex examples', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Lock for 3 seconds'), findsOneWidget);
    expect(find.text('Lock for 3 seconds (different mutex)'), findsOneWidget);
  });
}

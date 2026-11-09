import 'package:flutter_test/flutter_test.dart';

import 'package:neon_plinko_ai/main.dart';

void main() {
  testWidgets('AI assistant shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NeonAiApp());
    expect(find.text('AI 规则助手'), findsOneWidget);
    expect(find.text('询问 AI 助手'), findsOneWidget);
  });
}

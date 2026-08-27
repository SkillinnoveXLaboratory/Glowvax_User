import 'package:flutter_test/flutter_test.dart';
import 'package:glowvax/app.dart';
import 'package:glowvax/core/storage/token_storage.dart';
import 'package:glowvax/presentation/providers/theme_provider.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(GlowvaxApp(
      tokenStorage: tokenStorage,
      themeProvider: themeProvider,
    ));
    await tester.pump();
    expect(find.byType(GlowvaxApp), findsOneWidget);
  });
}

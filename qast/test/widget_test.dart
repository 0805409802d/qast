// Test de smoke básico para la app QAST
import 'package:flutter_test/flutter_test.dart';
import 'package:qast/main.dart';

void main() {
  testWidgets('App arranca correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const QastAdminApp());
    // Verificar que la pantalla de selección de rol se renderiza
    expect(find.text('Quinindé Seguro'), findsAny);
  });
}

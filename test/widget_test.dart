import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dmbs_frontend/main.dart';

void main() {
  testWidgets('Database Management App açılma testi',
      (WidgetTester tester) async {
    // Uygulamayı oluştur ve ilk ekranın yüklenmesini bekle.
    await tester.pumpWidget(const DatabaseManagementApp());
    await tester.pumpAndSettle();

    // Uygulamanın widget ağacında MaterialApp bulunduğunu kontrol et.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Uygulamanın herhangi bir hata vermeden açıldığını kontrol et.
    expect(tester.takeException(), isNull);
  });
}
enum UserRole {
  superAdmin,
  user,
}

class AppUser {
  final String name;
  final String email;
  final String department;
  final UserRole role;

  const AppUser({
    required this.name,
    required this.email,
    required this.department,
    required this.role,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
}
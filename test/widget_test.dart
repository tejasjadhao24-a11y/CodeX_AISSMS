import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lift/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_lift/core/theme/theme_provider.dart';
import 'package:campus_lift/core/providers/user_provider.dart';

import 'package:campus_lift/services/socket_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create test app with providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (context) => SocketService()),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProxyProvider<SocketService, UserProvider>(
            create: (context) => UserProvider(Provider.of<SocketService>(context, listen: false)),
            update: (context, socket, user) => user!,
          ),
        ],
        child: const CampusLiftApp(),
      ),
    );

    // Wait for initial build and timers to finish
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    // Verify that the app builds and shows basic UI elements
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}

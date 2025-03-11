// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face_recognition_app/main.dart'; // Adjust this import based on your project structure

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const FaceRecognitionApp() as Widget);

    // Verify login fields exist
    expect(find.byType(TextField), findsNWidgets(2)); // Username & Password fields
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login button navigates to camera screen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const FaceRecognitionApp() as Widget);

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'testUser');
    await tester.enterText(find.byType(TextField).last, 'testPassword');

    // Tap login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(); // Wait for animations/navigation

    // Verify navigation to camera screen
    expect(find.text('Camera'), findsOneWidget);
  });
}

class FaceRecognitionApp {
  const FaceRecognitionApp();
}

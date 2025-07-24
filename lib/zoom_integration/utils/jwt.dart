// WARNING:
// This utility generates JWT tokens **on device**, which is insecure for production use.
// In production, generate JWTs securely on your backend server and NEVER expose secrets in the app.

import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';

/// Generates a random string of given [length] consisting of
/// uppercase, lowercase letters and digits.
/// Used to create a unique user identity in the JWT.
String makeId(int length) {
  const characters =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  final rand = Random.secure();
  return List.generate(
      length, (_) => characters[rand.nextInt(characters.length)]).join();
}

/// Generates a JWT token for Zoom Video SDK session authentication.
///
/// Parameters:
/// - [sessionName]: The Zoom session name (topic).
/// - [roleType]: The role type as a string ("0" for attendee, "1" for host).
/// - [appKey]: Your Zoom SDK App Key.
/// - [appSecret]: Your Zoom SDK App Secret.
///
/// Returns:
/// - Signed JWT token as a string if successful.
/// - Empty string if token generation fails.
String generateJwt(
    String sessionName, String roleType, String appKey, String appSecret) {
  try {
    final iat = DateTime.now();
    final exp = iat.add(const Duration(days: 2)); // Token valid for 2 days

    final payload = {
      'app_key': appKey,
      'version': 1,
      'user_identity': makeId(10),
      'iat': (iat.millisecondsSinceEpoch / 1000).round(),
      'exp': (exp.millisecondsSinceEpoch / 1000).round(),
      'tpc': sessionName, // Session/topic name
      'role_type': int.parse(roleType), // Role as int (0=attendee, 1=host)
      'cloud_recording_option': 1, // Enable cloud recording option (optional)
    };

    final jwt = JWT(payload);
    final token = jwt.sign(SecretKey(appSecret));

    debugPrint("[JWT] Token generated successfully.");
    debugPrint("[JWT] Token: $token");

    return token;
  } catch (e, stacktrace) {
    debugPrint("[JWT] Error generating token: $e");
    debugPrint(stacktrace.toString());
    return '';
  }
}

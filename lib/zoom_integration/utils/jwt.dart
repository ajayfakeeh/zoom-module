// This util is to generate JWTs.
// THIS IS NOT A SAFE OPERATION TO DO IN YOUR APP IN PRODUCTION.
// JWTs should be provided by a backend server as they require a secret
// WHICH IS NOT SAFE TO STORE ON DEVICE!
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';


String makeId(int length) {
  String result = "";
  String characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  int charactersLength = characters.length;
  for (var i = 0; i < length; i++) {
    result += characters[Random().nextInt(charactersLength)];
  }
  return result;
}

String generateJwt(String sessionName, String roleType, String appKey, String appSecret) {
  try {
    var iat = DateTime.now();
    var exp = DateTime.now().add(Duration(days: 2));
    final jwt = JWT(
      {
        'app_key': appKey,
        'version': 1,
        'user_identity': makeId(10),
        'iat': (iat.millisecondsSinceEpoch / 1000).round(),
        'exp': (exp.millisecondsSinceEpoch / 1000).round(),
        'tpc': sessionName,
        'role_type': int.parse(roleType),
        'cloud_recording_option': 1,
      },
    );
    var token = jwt.sign(SecretKey(appSecret));
    debugPrint("token.............$token");
    return token;
  } catch (e) {
    debugPrint(e.toString());
    return '';
  }
}

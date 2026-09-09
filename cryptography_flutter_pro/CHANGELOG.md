## 0.1.0

* Initial release of `cryptography_flutter_pro` (based on former `cryptography_flutter` 2.4.0).
* Migrates Android plugin build to AGP 9 / built-in Kotlin (no longer applies `kotlin-android`).
* Example and integration test enable `android.builtInKotlin=true` (AGP 9.4.0, Kotlin 2.4.10).
* Requires Flutter 3.44 / Dart 3.12.
* Enables Swift Package Manager config; wires privacy manifests for iOS / macOS.
* Uses the Flutter plugin registration convention (no need to call `CryptographyFlutter.enable()` in `main`).
* Platform API adapters with tests for:
  * Android: `FlutterAesGcm`, `FlutterChacha20.poly1305Aead()`, HMAC (SHA-1/224/256/384/512), `FlutterPbkdf2()`
  * Apple: `FlutterAesGcm`, `FlutterChacha20.poly1305Aead()`, `FlutterEd25519()`, ECDH/ECDSA (P-256/384/521), HMAC (SHA-256/512), `FlutterX25519()`
* Background isolate helpers (e.g. `BackgroundAesGcm`, `BackgroundChacha20`) for large inputs; small inputs stay on the same isolate.
* Requires `package:cryptography` 2.5.0+ (DER support for Apple CryptoKit ECDH/ECDSA); current constraint is `^2.9.0`.
* Supports reading Android crypto provider names; falls back to Dart implementations with debug logging on plugin errors.

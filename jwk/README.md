[![Pub Package](https://img.shields.io/pub/v/jwk.svg)](https://pub.dev/packages/jwk)
[![Github Actions CI](https://github.com/wanwenfeng4798/cryptography/workflows/Dart%20CI/badge.svg)](https://github.com/wanwenfeng4798/cryptography/actions?query=workflow%3A%22Dart+CI%22)

# Overview
JWK (JSON Web Key) encoding and decoding. Designed to be used with
[package:cryptography_pro](https://pub.dev/packages/cryptography_pro).

Licensed under the [Apache License 2.0](LICENSE).

# Getting started
In _pubspec.yaml_
```yaml
dependencies:
  cryptography_pro: ^2.7.0
  jwk: ^0.2.5
```

# Examples
## Encoding KeyPair
```dart
import 'package:cryptography_pro/cryptography.dart';
import 'package:jwk/jwk.dart';

Future<void> main() async {
  final keyPair = await RsaPss().newKeyPair();
  final jwk = Jwk.fromKeyPair(keyPair);
  final json = jwk.toJson();
}
```

## Decoding SecretKey
```dart
import 'package:jwk/jwk.dart';

void main() {
  final jwk = Jwk.fromJson({
    'kty': 'oct',
    'alg': 'A128KW',
    'k': 'GawgguFyGrWKav7AX4VKUg',
  });
  final secretKey = jwk.toSecretKey();
}
```

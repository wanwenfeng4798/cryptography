// Copyright 2019-2020 Gohilla.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

import 'package:cryptography_pro/cryptography.dart';

import '../../cryptography_flutter_pro.dart';
import '../_flutter_cryptography_implementation.dart';
import '../_internal.dart';

/// [Ecdsa] that uses platform APIs in iOS and macOS.
/// Only the default hash for each curve is supported by the native adapter:
/// SHA-256 for P-256, SHA-384 for P-384, SHA-512 for P-521.
/// Other combinations require an explicit [fallback].
class FlutterEcdsa extends Ecdsa implements PlatformCryptographicAlgorithm {
  @override
  final Ecdsa? fallback;

  /// Optional Android provider name (such as "BC").
  final String? androidCryptoProvider;

  @override
  HashAlgorithm hashAlgorithm;

  @override
  final KeyPairType<KeyPairData, PublicKey> keyPairType;

  /// ECDSA-P256
  FlutterEcdsa.p256(
    this.hashAlgorithm, {
    this.androidCryptoProvider,
    this.fallback,
  }) : keyPairType = KeyPairType.p256,
       super.constructor();

  /// ECDSA-P384
  FlutterEcdsa.p384(
    this.hashAlgorithm, {
    this.androidCryptoProvider,
    this.fallback,
  }) : keyPairType = KeyPairType.p384,
       super.constructor();

  /// ECDSA-P521
  FlutterEcdsa.p521(
    this.hashAlgorithm, {
    this.androidCryptoProvider,
    this.fallback,
  }) : keyPairType = KeyPairType.p521,
       super.constructor();

  @override
  bool get isSupportedPlatform =>
      FlutterCryptography.isPluginPresent &&
      isCupertino &&
      ((keyPairType == KeyPairType.p256 && hashAlgorithm is Sha256) ||
          (keyPairType == KeyPairType.p384 && hashAlgorithm is Sha384) ||
          (keyPairType == KeyPairType.p521 && hashAlgorithm is Sha512));

  String get _curveName {
    switch (keyPairType) {
      case KeyPairType.p256:
        return 'p256';
      case KeyPairType.p384:
        return 'p384';
      case KeyPairType.p521:
        return 'p521';
      default:
        throw StateError('Unsupported key pair type: $keyPairType');
    }
  }

  @override
  Future<EcKeyPair> newKeyPair() async {
    if (isSupportedPlatform) {
      final result = await invokeMethod('Ecdsa.newKeyPair', {
        'curve': keyPairType.name,
      });
      return EcKeyPairData.parseDer(
        result['der'] as Uint8List,
        type: keyPairType,
      );
    }
    final fallback = this.fallback;
    if (fallback == null) {
      throw UnsupportedError(
        'Native ECDSA is unavailable for $keyPairType / $hashAlgorithm; provide a compatible fallback',
      );
    }
    return fallback.newKeyPair();
  }

  @override
  Future<EcKeyPair> newKeyPairFromSeed(List<int> seed) async {
    final fallback = this.fallback;
    if (fallback == null) {
      throw UnsupportedError(
        'Platform ECDSA does not support deterministic key generation',
      );
    }
    return fallback.newKeyPairFromSeed(seed);
  }

  @override
  Future<Signature> sign(List<int> message, {required KeyPair keyPair}) async {
    if (isSupportedPlatform) {
      final keyPairData = await keyPair.extract();
      if (keyPairData is! EcKeyPairData || keyPairData.type != keyPairType) {
        throw ArgumentError.value(keyPairData, 'keyPair');
      }
      final result = await invokeMethod('Ecdsa.sign', {
        'curve': _curveName,
        'data': asUint8List(message),
        'der': keyPairData.toDer(),
      });
      final error = result['error'] as String?;
      if (error != null) {
        throw StateError(
          '"package:cryptography_flutter_pro": $runtimeType.sign failed: $error',
        );
      }
      final signature = result['signature'] as Uint8List;
      final publicKey = await keyPairData.extractPublicKey();
      return Signature(signature, publicKey: publicKey);
    }
    final fallback = this.fallback;
    if (fallback == null) {
      throw UnsupportedError(
        'Native ECDSA is unavailable for $keyPairType / $hashAlgorithm; provide a compatible fallback',
      );
    }
    return await fallback.sign(message, keyPair: keyPair);
  }

  @override
  Future<bool> verify(List<int> message, {required Signature signature}) async {
    if (isSupportedPlatform) {
      final publicKey = signature.publicKey;
      if (publicKey is! EcPublicKey || publicKey.type != keyPairType) {
        throw ArgumentError.value(signature, 'signature');
      }
      final result = await invokeMethod('Ecdsa.verify', {
        'curve': _curveName,
        'data': asUint8List(message),
        'signature': asUint8List(signature.bytes),
        'der': publicKey.toDer(),
      });
      final error = result['error'];
      if (error != null) {
        throw StateError(
          '"package:cryptography_flutter_pro": $runtimeType.verify failed: $error',
        );
      }
      return result['result'] as bool;
    }
    final fallback = this.fallback;
    if (fallback == null) {
      throw UnsupportedError(
        'Native ECDSA is unavailable for $keyPairType / $hashAlgorithm; provide a compatible fallback',
      );
    }
    return await fallback.verify(message, signature: signature);
  }
}

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
import 'package:cryptography_pro/helpers.dart';

/// Opaque reference to RSA key pair.
///
/// The private key bytes of the key may not be in the memory. The private key
/// bytes may not even be extractable. If the private key is in memory, it's an
/// instance of [RsaKeyPairData].
///
/// The public key is always [RsaPublicKey].
///
/// This class is used with algorithms such as [RsaPss] and [RsaSsaPkcs1v15].
///
/// There are many formats for storing RSA key parameters.
/// If you are encoding/decoding JWK (JSON Web Key) format, use
/// [package:jwk](https://pub.dev/packages/jwk).
abstract class RsaKeyPair extends KeyPair {
  @Deprecated('Use RsaKeyPair.constructor')
  RsaKeyPair();

  /// Constructor for subclasses
  RsaKeyPair.constructor();

  @override
  Future<RsaKeyPairData> extract();

  @override
  Future<RsaPublicKey> extractPublicKey();
}

/// RSA private key.
///
/// There are many formats for storing RSA key parameters.
/// If you are encoding/decoding JWK (JSON Web Key) format, use
/// [package:jwk](https://pub.dev/packages/jwk).
///
/// ## Related classes
///   * [RsaKeyPair]
///   * [RsaPublicKey]
class RsaKeyPairData extends KeyPairData implements RsaKeyPair {
  /// RSA modulus. This is public information.
  final List<int> n;

  /// RSA exponent. This is public information.
  final List<int> e;

  /// RSA private key parameter `d`.
  final SensitiveBytes _d;

  List<int> get d {
    _checkNotDestroyed();
    return _d;
  }

  /// RSA private key parameter `p`.
  final SensitiveBytes _p;

  List<int> get p {
    _checkNotDestroyed();
    return _p;
  }

  /// RSA private key parameter `q`.
  final SensitiveBytes _q;

  List<int> get q {
    _checkNotDestroyed();
    return _q;
  }

  /// RSA private key parameter `dp`.
  final SensitiveBytes? _dp;

  List<int>? get dp {
    _checkNotDestroyed();
    return _dp;
  }

  /// RSA private key parameter `dq`.
  final SensitiveBytes? _dq;

  List<int>? get dq {
    _checkNotDestroyed();
    return _dq;
  }

  /// RSA private key parameter `qi`.
  final SensitiveBytes? _qi;

  List<int>? get qi {
    _checkNotDestroyed();
    return _qi;
  }

  /// Public key
  @override
  final RsaPublicKey publicKey;

  RsaKeyPairData({
    required this.n,
    required this.e,
    required List<int> d,
    required List<int> p,
    required List<int> q,
    List<int>? dp,
    List<int>? dq,
    List<int>? qi,
  }) : _d = SensitiveBytes(Uint8List.fromList(d), overwriteWhenDestroyed: true),
       _p = SensitiveBytes(Uint8List.fromList(p), overwriteWhenDestroyed: true),
       _q = SensitiveBytes(Uint8List.fromList(q), overwriteWhenDestroyed: true),
       _dp = dp == null
           ? null
           : SensitiveBytes(
               Uint8List.fromList(dp),
               overwriteWhenDestroyed: true,
             ),
       _dq = dq == null
           ? null
           : SensitiveBytes(
               Uint8List.fromList(dq),
               overwriteWhenDestroyed: true,
             ),
       _qi = qi == null
           ? null
           : SensitiveBytes(
               Uint8List.fromList(qi),
               overwriteWhenDestroyed: true,
             ),
       publicKey = RsaPublicKey(e: e, n: n),
       super(type: KeyPairType.rsa);

  void _checkNotDestroyed() {
    if (hasBeenDestroyed) {
      throw StateError('Private key has been destroyed');
    }
  }

  @override
  void destroy() {
    super.destroy();
    _d.destroy();
    _p.destroy();
    _q.destroy();
    _dp?.destroy();
    _dq?.destroy();
    _qi?.destroy();
  }

  @override
  int get hashCode =>
      11 * constantTimeBytesEquality.hash(n) ^
      7 * constantTimeBytesEquality.hash(e) ^
      (hasBeenDestroyed ? 0 : 3 * constantTimeBytesEquality.hash(d));

  @override
  bool operator ==(other) =>
      other is RsaKeyPairData &&
      !hasBeenDestroyed &&
      !other.hasBeenDestroyed &&
      constantTimeBytesEquality.equals(n, other.n) &&
      constantTimeBytesEquality.equals(e, other.e) &&
      constantTimeBytesEquality.equals(d, other.d) &&
      constantTimeBytesEquality.equals(p, other.p) &&
      constantTimeBytesEquality.equals(q, other.q) &&
      constantTimeBytesEquality.equals(dp ?? const [], other.dp ?? const []) &&
      constantTimeBytesEquality.equals(dq ?? const [], other.dq ?? const []) &&
      constantTimeBytesEquality.equals(qi ?? const [], other.qi ?? const []);

  @override
  RsaKeyPairData copy() {
    if (hasBeenDestroyed) {
      throw StateError('Key has been destroyed');
    }
    return RsaKeyPairData(n: n, e: e, d: d, p: p, q: q, dp: dp, dq: dq, qi: qi);
  }

  @override
  Future<RsaKeyPairData> extract() {
    if (hasBeenDestroyed) {
      throw StateError('Key has been destroyed');
    }
    return Future<RsaKeyPairData>.value(this);
  }

  @override
  Future<RsaPublicKey> extractPublicKey() async {
    return publicKey;
  }

  @override
  String toString() => 'RsaKeyPairData(...)';
}

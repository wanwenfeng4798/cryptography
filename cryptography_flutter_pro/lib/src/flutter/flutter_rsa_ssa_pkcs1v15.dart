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

import 'package:cryptography_pro/cryptography.dart';
import 'package:cryptography_pro/helpers.dart';

import '../_flutter_cryptography_implementation.dart';

/// Compatibility wrapper that delegates to the supplied implementation.
/// Native RSA acceleration is not available.
class FlutterRsaSsaPkcs1v15 extends DelegatingSignatureAlgorithm
    implements PlatformCryptographicAlgorithm, RsaSsaPkcs1v15 {
  @override
  final RsaSsaPkcs1v15 fallback;

  FlutterRsaSsaPkcs1v15(this.fallback);

  @override
  HashAlgorithm get hashAlgorithm => fallback.hashAlgorithm;

  @override
  bool get isSupportedPlatform => false;

  /// Name used by legacy callers of this wrapper.
  String get hashAlgorithmName {
    final hash = hashAlgorithm;
    if (hash is Sha512) return 'SHA-512';
    if (hash is Sha384) return 'SHA-384';
    if (hash is Sha256) return 'SHA-256';
    if (hash is Sha1) return 'SHA-1';
    return '';
  }

  @override
  Future<RsaKeyPair> newKeyPair({
    int modulusLength = RsaSsaPkcs1v15.defaultModulusLength,
    List<int> publicExponent = RsaSsaPkcs1v15.defaultPublicExponent,
  }) => fallback.newKeyPair(
    modulusLength: modulusLength,
    publicExponent: publicExponent,
  );
}

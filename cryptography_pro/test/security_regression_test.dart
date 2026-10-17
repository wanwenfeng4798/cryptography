import 'dart:typed_data';

import 'package:cryptography_pro/cryptography.dart';
import 'package:cryptography_pro/dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'RSA destroys every private parameter and leaves copies independent',
    () async {
      final input = [1, 2, 3];
      final original = RsaKeyPairData(
        n: [7],
        e: [3],
        d: input,
        p: [4],
        q: [5],
        dp: [6],
        dq: [7],
        qi: [8],
      );
      final copy = original.copy();
      final captured = original.d;
      input[0] = 99;
      expect(original.d, [1, 2, 3]);
      original.destroy();
      original.destroy();
      expect(original.hasBeenDestroyed, isTrue);
      expect(() => original.d, throwsStateError);
      expect(() => original.p, throwsStateError);
      expect(() => original.q, throwsStateError);
      expect(() => original.dp, throwsStateError);
      expect(() => original.dq, throwsStateError);
      expect(() => original.qi, throwsStateError);
      expect(() => captured[0], throwsStateError);
      expect(() => original.copy(), throwsStateError);
      expect(() => original.extract(), throwsStateError);
      expect(copy.d, [1, 2, 3]);
      expect(copy.dp, [6]);
      expect(original == copy, isFalse);
      expect(copy == original, isFalse);
      expect(await original.extractPublicKey(), copy.publicKey);
      copy.destroy();
    },
  );

  test(
    'EC and simple private keys own their bytes and independent copies',
    () async {
      final source = Uint8List.fromList([1, 2]);
      final ec = EcKeyPairData(
        d: source,
        x: [3],
        y: [4],
        type: KeyPairType.p256,
      );
      final simple = SimpleKeyPairData(
        source,
        publicKey: SimplePublicKey([5], type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      source[0] = 99;
      expect(ec.d, [1, 2]);
      expect(simple.bytes, [1, 2]);
      final ecCopy = ec.copy();
      final simpleCopy = simple.copy();
      ec.destroy();
      simple.destroy();
      expect(ecCopy.d, [1, 2]);
      expect(simpleCopy.bytes, [1, 2]);
      expect(await ec.extractPublicKey(), ecCopy.publicKey);
      expect(await simple.extractPublicKey(), simpleCopy.publicKey);
      final ecSecondCopy = ecCopy.copy()..destroy();
      final simpleSecondCopy = simpleCopy.copy()..destroy();
      expect(ecSecondCopy.hasBeenDestroyed, isTrue);
      expect(simpleSecondCopy.hasBeenDestroyed, isTrue);
      expect(ecCopy.d, [1, 2]);
      expect(simpleCopy.bytes, [1, 2]);
    },
  );

  test('destroyed secret key equality is symmetric and never reads bytes', () {
    final live = SecretKeyData([1]);
    final dead = SecretKeyData([1])..destroy();
    expect(live == dead, isFalse);
    expect(dead == live, isFalse);
    expect(<SecretKeyData>[dead].contains(live), isFalse);
    expect(<SecretKeyData>[live].contains(dead), isFalse);
  });

  for (final implementation in [
    DartCryptography.defaultInstance,
    Cryptography.defaultInstance,
  ]) {
    group('$implementation HKDF limits', () {
      for (final length in [-1, 8161]) {
        test('rejects length $length', () async {
          await expectLater(
            implementation
                .hkdf(hmac: Hmac.sha256(), outputLength: length)
                .deriveKey(secretKey: SecretKey([1])),
            throwsRangeError,
          );
        });
      }
      for (final length in [0, 32, 64, 8160]) {
        test('accepts length $length', () async {
          final result = await implementation
              .hkdf(hmac: Hmac.sha256(), outputLength: length)
              .deriveKey(secretKey: SecretKey([1]));
          expect(await result.extractBytes(), hasLength(length));
        });
      }
    });
  }

  test('HKDF computes only the required number of HMAC blocks', () async {
    final hmac = _CountingHmac();
    await DartHkdf(
      hmac: hmac,
      outputLength: 64,
    ).deriveKey(secretKey: SecretKey([1]));
    expect(hmac.calls, 3); // One extract and exactly two expand blocks.
  });

  for (final algorithm in [const DartX25519(), X25519()]) {
    test('$algorithm rejects low-order public keys', () async {
      final pair = await algorithm.newKeyPairFromSeed(List.filled(32, 7));
      for (final firstByte in [0, 1]) {
        final bytes = Uint8List(32)..[0] = firstByte;
        await expectLater(
          algorithm.sharedSecretKey(
            keyPair: pair,
            remotePublicKey: SimplePublicKey(bytes, type: KeyPairType.x25519),
          ),
          throwsA(anything),
        );
      }
    });
    test('$algorithm generates correctly typed interoperable keys', () async {
      final alice = await algorithm.newKeyPair();
      final bob = await const DartX25519().newKeyPair();
      final aliceData = await alice.extract();
      expect(aliceData.type, KeyPairType.x25519);
      final a = await algorithm.sharedSecretKey(
        keyPair: alice,
        remotePublicKey: await bob.extractPublicKey(),
      );
      final b = await const DartX25519().sharedSecretKey(
        keyPair: bob,
        remotePublicKey: await alice.extractPublicKey(),
      );
      expect(await a.extractBytes(), await b.extractBytes());
    });
  }
}

class _CountingHmac extends DartHmac {
  int calls = 0;
  _CountingHmac() : super(const DartSha256());

  @override
  DartMacSinkMixin newMacSinkSync({
    required SecretKeyData secretKeyData,
    List<int> nonce = const [],
    List<int> aad = const [],
  }) {
    calls++;
    return super.newMacSinkSync(
      secretKeyData: secretKeyData,
      nonce: nonce,
      aad: aad,
    );
  }
}

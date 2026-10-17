import 'package:cryptography_pro/cryptography.dart';
import 'package:cryptography_pro/dart.dart';
import 'package:cryptography_flutter_pro/cryptography_flutter_pro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'registered native AEAD roundtrips all data and rejects tampering',
    (tester) async {
      expect(FlutterCryptography.isPluginPresent, isTrue);
      const policy = CryptographyChannelPolicy(minLength: 0, maxLength: null);
      final algorithms = [
        FlutterAesGcm.with128bits(channelPolicy: policy),
        FlutterAesGcm.with256bits(channelPolicy: policy),
        FlutterChacha20.poly1305Aead(channelPolicy: policy),
      ];
      for (final cipher in algorithms) {
        // All algorithms in this list support this device.
        expect((cipher as FlutterCipher).isSupportedPlatform, isTrue);
        final key = await cipher.newSecretKey();
        for (final length in [0, 1, 16, 2001, 32769]) {
          final plain = List.generate(length, (i) => i % 256);
          final box = await cipher.encrypt(plain, secretKey: key, aad: [1, 2]);
          expect(await cipher.decrypt(box, secretKey: key, aad: [1, 2]), plain);
          final invalid = SecretBox(
            box.cipherText,
            nonce: box.nonce,
            mac: Mac([...box.mac.bytes]..[0] ^= 1),
          );
          await expectLater(
            cipher.decrypt(invalid, secretKey: key, aad: [1, 2]),
            throwsA(isA<SecretBoxAuthenticationError>()),
          );
        }
      }
    },
  );

  testWidgets(
    'native EC exports fixed-width unsigned parameters and accepts imports',
    (tester) async {
      final algorithms = [
        FlutterEcdh.p256(),
        FlutterEcdh.p384(),
        FlutterEcdh.p521(),
      ];
      for (var i = 0; i < algorithms.length; i++) {
        final algorithm = algorithms[i];
        expect(algorithm.isSupportedPlatform, isTrue);
        final width = [32, 48, 66][i];
        final alice = await (await algorithm.newKeyPair()).extract();
        var bob = await (await algorithm.newKeyPair()).extract();
        if (width != 66) {
          for (
            var attempt = 0;
            bob.x.first < 128 && bob.y.first < 128 && attempt < 32;
            attempt++
          ) {
            bob.destroy();
            bob = await (await algorithm.newKeyPair()).extract();
          }
          expect(bob.x.first >= 128 || bob.y.first >= 128, isTrue);
        }
        for (final key in [alice, bob]) {
          expect(key.d, hasLength(width));
          expect(key.x, hasLength(width));
          expect(key.y, hasLength(width));
        }
        // Recreate objects to exercise externally supplied unsigned parameters.
        final imported = EcKeyPairData(
          d: List.of(alice.d),
          x: List.of(alice.x),
          y: List.of(alice.y),
          type: alice.type,
        );
        final a = await algorithm.sharedSecretKey(
          keyPair: imported,
          remotePublicKey: bob.publicKey,
        );
        final b = await algorithm.sharedSecretKey(
          keyPair: bob,
          remotePublicKey: imported.publicKey,
        );
        expect(await a.extractBytes(), await b.extractBytes());
        alice.destroy();
        expect(await imported.extract(), same(imported));
      }
    },
  );

  testWidgets(
    'native ECDSA defaults verify while unsupported hash and seed are explicit',
    (tester) async {
      final ecdsa = FlutterEcdsa.p256(Sha256());
      if (ecdsa.isSupportedPlatform) {
        final pair = await ecdsa.newKeyPair();
        final signature = await ecdsa.sign([1, 2, 3], keyPair: pair);
        expect(await ecdsa.verify([1, 2, 3], signature: signature), isTrue);
        expect(await ecdsa.verify([3, 2, 1], signature: signature), isFalse);
        final unsupported = FlutterEcdsa.p256(Sha512());
        expect(unsupported.isSupportedPlatform, isFalse);
        await expectLater(
          unsupported.sign([1], keyPair: pair),
          throwsUnsupportedError,
        );
      }
      await expectLater(
        ecdsa.newKeyPairFromSeed(List.filled(32, 1)),
        throwsUnsupportedError,
      );
      await expectLater(
        FlutterEcdh.p256().newKeyPairFromSeed(List.filled(32, 1)),
        throwsUnsupportedError,
      );
    },
  );

  testWidgets(
    'X25519 adapter interoperates with Dart and rejects zero secrets',
    (tester) async {
      final algorithm = FlutterX25519(const DartX25519());
      final alice = await algorithm.newKeyPair();
      final bob = await const DartX25519().newKeyPair();
      final a = await algorithm.sharedSecretKey(
        keyPair: alice,
        remotePublicKey: await bob.extractPublicKey(),
      );
      final b = await const DartX25519().sharedSecretKey(
        keyPair: bob,
        remotePublicKey: await alice.extractPublicKey(),
      );
      expect(await a.extractBytes(), await b.extractBytes());
      await expectLater(
        algorithm.sharedSecretKey(
          keyPair: alice,
          remotePublicKey: SimplePublicKey(
            List.filled(32, 0),
            type: KeyPairType.x25519,
          ),
        ),
        throwsA(anything),
      );
    },
  );
}

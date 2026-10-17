import 'package:cryptography_pro/cryptography.dart';
import 'package:cryptography_pro/dart.dart';
import 'package:cryptography_flutter_pro/android.dart';
import 'package:cryptography_flutter_pro/cryptography_flutter_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cryptography_flutter_pro');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('unregistered Android adapters fall back for HMAC and PBKDF2', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(FlutterCryptography.isPluginPresent, isFalse);
    final cryptography = FlutterCryptography();
    final actual = await cryptography.hmac(const DartSha256()).calculateMac([
      1,
    ], secretKey: SecretKey([]));
    final expected = await DartHmac.sha256().calculateMac([
      1,
    ], secretKey: SecretKey([]));
    expect(actual, expected);
    final kdf = cryptography.pbkdf2(
      macAlgorithm: DartHmac.sha256(),
      iterations: 1,
      bits: 64,
    );
    final result = await kdf.deriveKeyFromPassword(
      password: 'password',
      nonce: [1],
    );
    final reference = await DartPbkdf2(
      macAlgorithm: DartHmac.sha256(),
      iterations: 1,
      bits: 64,
    ).deriveKeyFromPassword(password: 'password', nonce: [1]);
    expect(await result.extractBytes(), await reference.extractBytes());
  });

  test('queue validates configuration and lock lifecycle', () async {
    expect(
      () => CryptographyChannelQueue(
        maxConcurrentSize: 1,
        maxConcurrentRequests: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => CryptographyChannelQueue(
        maxConcurrentSize: 0,
        maxConcurrentRequests: 1,
      ),
      throwsArgumentError,
    );
    final queue = CryptographyChannelQueue(
      maxConcurrentSize: 10,
      maxConcurrentRequests: 2,
    );
    expect(() => queue.newLock(size: -1), throwsRangeError);
    final lock = queue.newLock(size: 5);
    expect(lock.unlock, throwsStateError);
    await lock.lock();
    await expectLater(lock.lock(), throwsStateError);
    lock.unlock();
    expect(lock.unlock, throwsStateError);
    await expectLater(lock.lock(), throwsStateError);
    expect(queue.totalRequests, 0);
    expect(queue.totalSize, 0);
  });

  test(
    'queue honors FIFO and admits exact capacity and oversized requests',
    () async {
      final queue = CryptographyChannelQueue(
        maxConcurrentSize: 10,
        maxConcurrentRequests: 3,
      );
      final first = queue.newLock(size: 6);
      final second = queue.newLock(size: 6);
      final third = queue.newLock(size: 4);
      await first.lock();
      final secondReady = second.lock();
      final thirdReady = third.lock();
      expect(() => second.unlock(), throwsStateError);
      expect(queue.totalSize, 6);
      first.unlock();
      await Future.wait([secondReady, thirdReady]);
      expect(queue.totalRequests, 2);
      expect(queue.totalSize, 10);
      final oversized = queue.newLock(size: 20);
      final oversizedReady = oversized.lock();
      final tail = queue.newLock(size: 1);
      final tailReady = tail.lock();
      second.unlock();
      third.unlock();
      await oversizedReady;
      expect(queue.totalSize, 20);
      expect(queue.totalRequests, 1);
      oversized.unlock();
      await tailReady;
      tail.unlock();
      expect(queue.totalRequests, 0);
      expect(queue.totalSize, 0);
    },
  );

  test('wrappers reject stream offsets on both encrypt and decrypt', () async {
    final key = SecretKey(List.filled(32, 1));
    final nonce = List.filled(12, 0);
    final box = await const DartChacha20.poly1305Aead().encrypt(
      [1],
      secretKey: key,
      nonce: nonce,
    );
    final algorithms = [
      FlutterChacha20.poly1305Aead(
        channelPolicy: CryptographyChannelPolicy.never,
      ),
      BackgroundChacha.poly1305Aead(
        channelPolicy: CryptographyChannelPolicy.never,
      ),
    ];
    // The extra offset is exposed by the concrete wrappers, not by Cipher.
    for (final dynamic algorithm in algorithms) {
      await expectLater(
        () => algorithm.encrypt(
          [1],
          secretKey: key,
          nonce: nonce,
          keyStreamIndex: 16,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => algorithm.decrypt(box, secretKey: key, keyStreamIndex: 16),
        throwsArgumentError,
      );
    }
  });

  test('fallback receives possibleBuffer on encrypt and decrypt', () async {
    final fallback = _RecordingAesGcm();
    final wrappers = [
      FlutterAesGcm(
        secretKeyLength: 32,
        channelPolicy: CryptographyChannelPolicy.never,
        fallback: fallback,
      ),
      BackgroundAesGcm(
        secretKeyLength: 32,
        channelPolicy: CryptographyChannelPolicy.never,
      )..fallback = fallback,
    ];
    final buffer = Uint8List(3);
    final key = SecretKey(List.filled(32, 1));
    for (final cipher in wrappers) {
      final box = await cipher.encrypt(
        [1, 2, 3],
        secretKey: key,
        possibleBuffer: buffer,
      );
      expect(fallback.encryptBuffer, same(buffer));
      expect(
        await cipher.decrypt(box, secretKey: key, possibleBuffer: buffer),
        [1, 2, 3],
      );
      expect(fallback.decryptBuffer, same(buffer));
    }
  });

  test('provider errors can be retried and success is cached', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      if (calls == 1) throw PlatformException(code: 'UNAVAILABLE');
      return null;
    });
    await expectLater(
      AndroidCryptoProvider.add(className: 'test.Provider'),
      throwsA(isA<PlatformException>()),
    );
    await AndroidCryptoProvider.add(className: 'test.Provider');
    await AndroidCryptoProvider.add(className: 'test.Provider');
    expect(calls, 2);
  });

  test(
    'registered Android HMAC supports empty keys without invoking JCA',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterCryptography.registerWith();
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        throw StateError('Empty key must use fallback');
      });
      final hmac = FlutterCryptography().hmac(const DartSha256());
      expect(
        await hmac.calculateMac([1], secretKey: SecretKey([])),
        await DartHmac.sha256().calculateMac([1], secretKey: SecretKey([])),
      );
      await expectLater(
        hmac.calculateMac([1], secretKey: SecretKey([]), aad: [1]),
        throwsArgumentError,
      );
      expect(calls, 0);
    },
  );

  test('ECDSA unsupported hashes never invoke native signing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    FlutterCryptography.registerWith();
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return {};
    });
    final algorithm = FlutterEcdsa.p256(Sha512());
    expect(algorithm.isSupportedPlatform, isFalse);
    final pair = EcKeyPairData(
      d: List.filled(32, 1),
      x: List.filled(32, 2),
      y: List.filled(32, 3),
      type: KeyPairType.p256,
    );
    await expectLater(
      algorithm.sign([1], keyPair: pair),
      throwsUnsupportedError,
    );
    expect(calls, 0);
    final fallback = _SeedEcdsa();
    final wrapped = FlutterEcdsa.p256(Sha512(), fallback: fallback);
    final signature = await wrapped.sign([1], keyPair: pair);
    expect(signature.bytes, [9]);
    expect(calls, 0);
  });

  test(
    'seed APIs delegate the seed or explicitly reject unsupported generation',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      FlutterCryptography.registerWith();
      var nativeCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        nativeCalls++;
        return {};
      });
      final seed = [1, 2, 3];
      final ecdh = _SeedEcdh();
      final ecdsa = _SeedEcdsa();
      await FlutterEcdh.p256(fallback: ecdh).newKeyPairFromSeed(seed);
      await FlutterEcdsa.p256(
        Sha256(),
        fallback: ecdsa,
      ).newKeyPairFromSeed(seed);
      expect(ecdh.seed, same(seed));
      expect(ecdsa.seed, same(seed));
      await expectLater(
        FlutterEcdh.p256().newKeyPairFromSeed(seed),
        throwsUnsupportedError,
      );
      await expectLater(
        FlutterEcdsa.p256(Sha256()).newKeyPairFromSeed(seed),
        throwsUnsupportedError,
      );
      expect(nativeCalls, 0);
    },
  );
}

EcKeyPairData _key(List<int> seed) =>
    EcKeyPairData(d: seed, x: [2], y: [3], type: KeyPairType.p256);

class _SeedEcdh extends DartEcdh {
  List<int>? seed;
  _SeedEcdh() : super.p256();
  @override
  Future<EcKeyPair> newKeyPairFromSeed(List<int> seed) async {
    this.seed = seed;
    return _key(seed);
  }
}

class _SeedEcdsa extends DartEcdsa {
  List<int>? seed;
  _SeedEcdsa() : super.p256(const DartSha512());
  @override
  Future<EcKeyPair> newKeyPairFromSeed(List<int> seed) async {
    this.seed = seed;
    return _key(seed);
  }

  @override
  Future<Signature> sign(
    List<int> message, {
    required KeyPair keyPair,
    PublicKey? publicKey,
  }) async => Signature([9], publicKey: await keyPair.extractPublicKey());
}

class _RecordingAesGcm extends AesGcm {
  final _delegate = DartAesGcm(secretKeyLength: 32);
  @override
  int get secretKeyLength => 32;
  @override
  int get nonceLength => 12;
  Uint8List? encryptBuffer;
  Uint8List? decryptBuffer;
  _RecordingAesGcm() : super.constructor();
  @override
  Future<SecretBox> encrypt(
    List<int> clearText, {
    required SecretKey secretKey,
    List<int>? nonce,
    List<int> aad = const [],
    Uint8List? possibleBuffer,
  }) {
    encryptBuffer = possibleBuffer;
    return _delegate.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad,
      possibleBuffer: possibleBuffer,
    );
  }

  @override
  Future<List<int>> decrypt(
    SecretBox secretBox, {
    required SecretKey secretKey,
    List<int> aad = const [],
    Uint8List? possibleBuffer,
  }) {
    decryptBuffer = possibleBuffer;
    return _delegate.decrypt(
      secretBox,
      secretKey: secretKey,
      aad: aad,
      possibleBuffer: possibleBuffer,
    );
  }
}

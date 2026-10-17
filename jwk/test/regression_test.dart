import 'dart:convert';
import 'package:cryptography_pro/cryptography.dart';
import 'package:jwk/jwk.dart';
import 'package:test/test.dart';

void main() {
  test('standard oct, operations, and certificate chain roundtrip', () async {
    final json = <String, Object>{
      'kty': 'oct',
      'k': 'AQID',
      'key_ops': ['encrypt', 'decrypt'],
      'x5c': [
        base64.encode([251, 255]),
        base64.encode([1, 2]),
      ],
      'cty': 'application/example',
    };
    final key = Jwk.fromJson(json);
    expect(key.keyOps, ['encrypt', 'decrypt']);
    expect(key.x5c, [
      [251, 255],
      [1, 2],
    ]);
    expect(await key.toSecretKey().extractBytes(), [1, 2, 3]);
    expect(key.toJson(), json);
    expect(key.toBuilder().build(), key);
    expect(Jwk.fromUtf8(key.toUtf8()), key);
  });
  test('legacy JSON is read but emitted in standard format', () {
    final key = Jwk.fromJson({
      'kty': 'OCT',
      'key_ops': 'encrypt',
      'x5c': '-_8',
    });
    expect(key.kty, 'oct');
    expect(key.toJson(), {
      'kty': 'oct',
      'key_ops': ['encrypt'],
      'x5c': ['+/8='],
    });
    expect(const Jwk(kty: 'OCT').toJson()['kty'], 'oct');
  });
  test('secret key export uses standard lowercase oct', () async {
    final key = await Jwk.fromSecretKey(
      SecretKey(List.filled(16, 1)),
      cipher: AesGcm.with128bits(),
    );
    expect(key.kty, 'oct');
    expect(key.toJson()['kty'], 'oct');
  });
  test('equality includes key material and compares list contents', () {
    final first = Jwk(
      kty: 'oct',
      k: [1],
      keyOps: ['encrypt'],
      x5c: [
        [2],
      ],
    );
    final equal = Jwk(
      kty: 'oct',
      k: [1],
      keyOps: ['encrypt'],
      x5c: [
        [2],
      ],
    );
    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(
      first,
      isNot(
        Jwk(
          kty: 'oct',
          k: [2],
          keyOps: ['encrypt'],
          x5c: [
            [2],
          ],
        ),
      ),
    );
    expect(
      Jwk(x: [1], y: [2], d: [3], n: [4], e: [5]),
      Jwk(x: [1], y: [2], d: [3], n: [4], e: [5]),
    );
    expect(JwkSet([first]), JwkSet([equal]));
    expect({first, equal}, hasLength(1));
  });
}

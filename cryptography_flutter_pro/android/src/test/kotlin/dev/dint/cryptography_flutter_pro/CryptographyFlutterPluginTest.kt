package dev.dint.cryptography_flutter_pro

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.math.BigInteger
import java.security.Provider
import java.security.Security
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.test.*

class CryptographyFlutterPluginTest {
    @Test fun methodChannelEncryptsAndDecryptsWithStandardKeyAlgorithms() {
        val plugin = CryptographyFlutterPlugin()
        val input = ByteArray(32769) { it.toByte() }
        val arguments = mutableMapOf<String, Any>("algo" to "AES_GCM", "data" to input,
            "key" to ByteArray(16), "nonce" to ByteArray(12), "aad" to ByteArray(0))
        val encrypted = CapturingResult()
        plugin.onMethodCall(MethodCall("encrypt", arguments), encrypted)
        assertEquals(1, encrypted.calls)
        assertNull(encrypted.error)
        val box = encrypted.value as Map<*, *>
        arguments["data"] = box["cipherText"] as ByteArray
        arguments["mac"] = box["mac"] as ByteArray
        val decrypted = CapturingResult()
        plugin.onMethodCall(MethodCall("decrypt", arguments), decrypted)
        assertEquals(1, decrypted.calls)
        assertNull(decrypted.error)
        assertContentEquals(input, (decrypted.value as Map<*, *>)["clearText"] as ByteArray)
    }

    @Test fun ecdhMethodChannelImportsUnsignedCoordinatesAndScalars() {
        val plugin = CryptographyFlutterPlugin()
        fun call(method: String, args: Map<String, Any>): Map<*, *> {
            val result = CapturingResult()
            plugin.onMethodCall(MethodCall(method, args), result)
            assertEquals(1, result.calls)
            assertNull(result.error)
            return result.value as Map<*, *>
        }
        fun generate(highField: String): Map<*, *> {
            repeat(64) {
                val pair = call("Ecdh.newKeyPair", mapOf("curve" to "p256"))
                for (field in listOf("d", "x", "y")) assertEquals(32, (pair[field] as ByteArray).size)
                if ((pair[highField] as ByteArray)[0].toInt() and 0x80 != 0) return pair
            }
            fail("Did not generate a high-bit EC parameter")
        }
        val alice = generate("d")
        val bob = generate("x")
        fun shared(local: Map<*, *>, remote: Map<*, *>): ByteArray =
            call("Ecdh.sharedSecretKey", mapOf("curve" to "p256", "localD" to local["d"]!!,
                "localX" to local["x"]!!, "localY" to local["y"]!!,
                "remoteX" to remote["x"]!!, "remoteY" to remote["y"]!!))["bytes"] as ByteArray
        assertContentEquals(shared(alice, bob), shared(bob, alice))
    }

    @Test fun decryptsAllPlaintextAndAuthenticatesTag() {
        val key = SecretKeySpec(ByteArray(16) { it.toByte() }, "AES")
        val iv = ByteArray(12)
        val plaintext = ByteArray(32769) { it.toByte() }
        val encryptor = Cipher.getInstance("AES/GCM/NoPadding")
        encryptor.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(128, iv))
        val combined = encryptor.doFinal(plaintext)
        val ciphertext = combined.copyOfRange(0, combined.size - 16)
        val tag = combined.copyOfRange(combined.size - 16, combined.size)
        fun decrypt(mac: ByteArray): ByteArray {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
            return CryptoPrimitives.decryptAead(cipher, ciphertext, mac)
        }
        assertContentEquals(plaintext, decrypt(tag))
        tag[0] = (tag[0].toInt() xor 1).toByte()
        assertFails { decrypt(tag) }
    }

    @Test fun ecParametersAreUnsignedAndFixedWidth() {
        for (size in listOf(32, 48, 66)) {
            val bytes = ByteArray(size) { 0x80.toByte() }
            if (size == 66) bytes[0] = 1
            val value = BigInteger(1, bytes)
            assertContentEquals(bytes, CryptoPrimitives.unsignedBytes(value, size))
            val padded = CryptoPrimitives.unsignedBytes(BigInteger.ONE, size)
            assertEquals(size, padded.size)
            assertEquals(1.toByte(), padded.last())
            assertTrue(padded.dropLast(1).all { it == 0.toByte() })
        }
        assertFails { CryptoPrimitives.unsignedBytes(BigInteger.valueOf(-1), 32) }
        assertFails { CryptoPrimitives.unsignedBytes(BigInteger.ONE.shiftLeft(256), 32) }
    }

    @Test fun addingProviderCompletesMethodChannelExactlyOnce() {
        val result = CapturingResult()
        try {
            CryptographyFlutterPlugin().onMethodCall(
                MethodCall("androidCryptoProvidersAdd", AuditProvider::class.java.name), result)
            assertEquals(1, result.calls)
            assertNull(result.error)
            assertNotNull(Security.getProvider("CryptographyAudit"))
        } finally {
            Security.removeProvider("CryptographyAudit")
        }
    }
}

class AuditProvider : Provider("CryptographyAudit", 1.0, "Test-only provider")

private class CapturingResult : MethodChannel.Result {
    var calls = 0
    var error: String? = null
    var value: Any? = null
    override fun success(value: Any?) { calls++; this.value = value }
    override fun error(code: String, message: String?, details: Any?) { calls++; error = code }
    override fun notImplemented() { calls++; error = "NOT_IMPLEMENTED" }
}

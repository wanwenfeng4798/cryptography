package dev.dint.cryptography_flutter_pro

import java.math.BigInteger
import javax.crypto.Cipher

internal object CryptoPrimitives {
    // Authenticate before returning any plaintext to Dart. Do not discard update output.
    fun decryptAead(cipher: Cipher, cipherText: ByteArray, mac: ByteArray): ByteArray =
        cipher.doFinal(cipherText + mac)

    fun unsignedBytes(value: BigInteger, length: Int): ByteArray {
        require(value.signum() >= 0) { "EC parameters must be non-negative" }
        val signed = value.toByteArray()
        val bytes = if (signed.size > 1 && signed[0] == 0.toByte()) signed.copyOfRange(1, signed.size) else signed
        require(bytes.size <= length) { "EC parameter exceeds curve size" }
        return ByteArray(length - bytes.size) + bytes
    }
}

package com.wavesplatform.dex.domain.crypto

import com.wavesplatform.dex.WavesIntegrationSuiteBase
import com.wavesplatform.dex.domain.account.PublicKey
import com.wavesplatform.dex.domain.bytes.ByteStr
import org.scalatest.matchers.should.Matchers

class CryptoSpec extends WavesIntegrationSuiteBase with Matchers {

  "CryptoSpec" - {
    "isWeakPublicKey" - {
      "detects blacklisted keys" in {
        val weakKey = Array.fill(32)(0.toByte)
        isWeakPublicKey(weakKey) shouldBe true

        val weakKey2 = Array(0x01.toByte) ++ Array.fill(31)(0.toByte)
        isWeakPublicKey(weakKey2) shouldBe true

        // Standard valid public key should not be detected as weak
        val seed = Array.fill(32)(1.toByte)
        val (_, pkBytes) = createKeyPair(seed)
        isWeakPublicKey(pkBytes) shouldBe false
      }
    }

    "verify" - {
      "rejects weak public keys by default" in {
        val weakKeyBytes = Array.fill(32)(0.toByte)
        val weakPublicKey = PublicKey(weakKeyBytes)
        val dummyMessage = ByteStr(Array.fill(32)(1.toByte))
        val dummySignature = ByteStr(Array.fill(64)(1.toByte))

        // By default verify should reject weak public keys
        verify(dummySignature, dummyMessage, weakPublicKey) shouldBe false
      }

      "bypasses weak public key check if checkWeakPk is false" in {
        val weakKeyBytes = Array.fill(32)(0.toByte)
        val weakPublicKey = PublicKey(weakKeyBytes)
        val dummyMessage = ByteStr(Array.fill(32)(1.toByte))
        val dummySignature = ByteStr(Array.fill(64)(1.toByte))

        // Curve25519.verify will be called and return false, but it won't be blocked immediately by checkWeakPk
        verify(dummySignature, dummyMessage, weakPublicKey, checkWeakPk = false) shouldBe false
      }

      "successfully verifies standard signatures" in {
        val seed = Array.fill(32)(1.toByte)
        val (skBytes, pkBytes) = createKeyPair(seed)
        val messageBytes = Array.fill(32)(5.toByte)

        val signatureBytes = scorex.crypto.signatures.Curve25519.sign(
          scorex.crypto.signatures.PrivateKey(skBytes),
          messageBytes
        )

        verify(ByteStr(signatureBytes), ByteStr(messageBytes), PublicKey(pkBytes)) shouldBe true
        verify(ByteStr(signatureBytes), ByteStr(messageBytes), PublicKey(pkBytes), checkWeakPk = false) shouldBe true
      }
    }
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc; // Use encrypt package for RSA parsing if available, or just implement simpler one
import 'package:pointycastle/export.dart';
import 'crypto_utils.dart';

/// 网易云音乐加密工具类
class NeteaseCrypto {
  // AES 密钥和向量
  static const String _presetKey = '0CoJUm6Qyw8W8jud';
  static const String _iv = '0102030405060708';
  static const String _publicKey = '''-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB
-----END PUBLIC KEY-----''';

  /// Weapi 加密（用于大部分API）
  static Map<String, String> weapi(Map<String, dynamic> params) {
    try {
      // 1. 生成随机密钥
      final randomKey = _createRandomKey(16);

      // 2. 第一次AES加密
      final text = json.encode(params);
      final firstEncrypt = _aesEncrypt(text, _presetKey, _iv);

      // 3. 第二次AES加密
      final secondEncrypt = _aesEncrypt(firstEncrypt, randomKey, _iv);

      // 4. RSA加密随机密钥
      final encSecKey = _rsaEncrypt(randomKey.split('').reversed.join());

      return {
        'params': secondEncrypt,
        'encSecKey': encSecKey,
      };
    } catch (e) {
      print('❌ [NeteaseCrypto] Weapi加密失败: $e');
      return {};
    }
  }

  /// Eapi 加密（用于部分高级API）
  static Map<String, String> eapi(
    String url,
    Map<String, dynamic> params,
  ) {
    try {
      const eapiKey = 'e82ckenh8dichen8';
      final text = json.encode(params);
      final message = 'nobody${url}use${text}md5forencrypt';
      final digest = md5.convert(utf8.encode(message)).toString();
      final data = '$url-36cd479b6b5-$text-36cd479b6b5-$digest';
      
      return {
        'params': _aesEncrypt(data, eapiKey, _iv),
      };
    } catch (e) {
      print('❌ [NeteaseCrypto] Eapi加密失败: $e');
      return {};
    }
  }

  /// AES-128-CBC 加密
  static String _aesEncrypt(String text, String key, String iv) {
    try {
      final keyBytes = utf8.encode(key);
      final ivBytes = utf8.encode(iv);
      final textBytes = utf8.encode(text);

      // PKCS7 填充
      final padded = CryptoUtils.pkcs7Pad(textBytes, 16);

      // AES-CBC 加密
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(
        KeyParameter(keyBytes),
        ivBytes,
      );
      cipher.init(true, params);

      final encrypted = <int>[];
      for (var i = 0; i < padded.length; i += 16) {
        final block = padded.sublist(i, i + 16);
        encrypted.addAll(cipher.process(Uint8List.fromList(block)));
      }

      return base64.encode(encrypted);
    } catch (e) {
      print('❌ [NeteaseCrypto] AES加密失败: $e');
      return '';
    }
  }

  /// RSA 加密
  static String _rsaEncrypt(String text) {
    try {
      // Manual RSA implementation using BigInt as RSAKeyParser is missing or requires another package
      // The public key is hardcoded, we can extract modulus and exponent manually or use a different approach
      // _publicKey above is PEM format.
      
      // For simplicity in this context, we can hardcode the modulus/exponent extracted from the key
      // Or use basic math if we parse it. 
      // Given dependencies issues, let's try a simpler RSA encryption if possible or fix the parser.
      
      // Let's implement a basic PEM parser or just use the hex modulus directly if we knew it.
      // But to be safe and dynamic, we need to parse.
      // Since RSAKeyParser is not found, it implies 'encrypt' package is not imported or used correctly?
      // Actually 'encrypt' package has RSAKeyParser. 
      
      final parser = enc.RSAKeyParser();
      final publicKey = parser.parse(_publicKey) as RSAPublicKey;

      // RSA 加密
      final cipher = RSAEngine()
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      final textBytes = utf8.encode(text);
      final encrypted = cipher.process(Uint8List.fromList(textBytes));

      // 转换为十六进制
      return CryptoUtils.bytesToHex(encrypted);
    } catch (e) {
      print('❌ [NeteaseCrypto] RSA加密失败: $e');
      return '';
    }
  }

  /// 生成随机密钥
  static String _createRandomKey(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join('');
  }
}

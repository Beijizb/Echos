import 'dart:typed_data';

/// 加密工具类
class CryptoUtils {
  /// PKCS7 填充
  static Uint8List pkcs7Pad(List<int> data, int blockSize) {
    final padding = blockSize - (data.length % blockSize);
    final padValue = padding;
    final padded = Uint8List(data.length + padding);
    
    // 复制原始数据
    padded.setRange(0, data.length, data);
    
    // 添加填充
    for (var i = data.length; i < padded.length; i++) {
      padded[i] = padValue;
    }
    
    return padded;
  }

  /// PKCS7 去填充
  static Uint8List pkcs7Unpad(Uint8List data) {
    if (data.isEmpty) {
      return data;
    }
    
    final padding = data.last;
    if (padding > data.length || padding == 0) {
      return data;
    }
    
    // 验证填充是否有效
    for (var i = data.length - padding; i < data.length; i++) {
      if (data[i] != padding) {
        return data;
      }
    }
    
    return Uint8List.sublistView(data, 0, data.length - padding);
  }

  /// 字节数组转十六进制字符串
  static String bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// 十六进制字符串转字节数组
  static Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}

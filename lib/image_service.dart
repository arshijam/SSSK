import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static Future<File> compressForUpload(File file) async {
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/up_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final r = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
    );
    return r != null ? File(r.path) : file;
  }

  static Future<File> compressForAI(File file) async {
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final r = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 40,
      minWidth: 512,
      minHeight: 512,
    );
    return r != null ? File(r.path) : file;
  }
}
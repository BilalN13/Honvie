import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Widget buildImagePreview(XFile file, Uint8List? bytes) {
  return Image.memory(
    bytes ?? Uint8List(0),
    fit: BoxFit.cover,
  );
}

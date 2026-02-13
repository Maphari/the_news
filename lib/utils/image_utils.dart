import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ImageProvider? resolveImageProvider(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;

  final trimmed = imageUrl.trim();

  if (trimmed.startsWith('data:image')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex == -1) return null;

    try {
      final base64Data = trimmed.substring(commaIndex + 1);
      return MemoryImage(base64Decode(base64Data));
    } catch (_) {
      return null;
    }
  }

  if (trimmed.startsWith('file://')) {
    final path = trimmed.replaceFirst('file://', '');
    return FileImage(File(path));
  }

  if (!kIsWeb) {
    final file = File(trimmed);
    if (file.existsSync()) {
      return FileImage(file);
    }
  }

  return NetworkImage(trimmed);
}

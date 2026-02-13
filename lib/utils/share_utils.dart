import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Rect? _shareOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size.width > 0 && size.height > 0) {
        return renderObject.localToGlobal(Offset.zero) & size;
      }
    }

    final size = MediaQuery.of(context).size;
    if (size.width > 0 && size.height > 0) {
      return Rect.fromLTWH(0, 0, size.width, size.height);
    }

    return null;
  }

  static Rect _fallbackOrigin() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final double width = logicalSize.width > 0 ? logicalSize.width : 1.0;
    final double height = logicalSize.height > 0 ? logicalSize.height : 1.0;
    return Rect.fromLTWH(0, 0, width, height);
  }

  static Future<void> shareText(
    BuildContext context,
    String text, {
    String? subject,
  }) async {
    final origin = _shareOrigin(context) ?? _fallbackOrigin();
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }

  static Future<void> shareTextWithoutContext(
    String text, {
    String? subject,
  }) async {
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: _fallbackOrigin(),
    );
  }

  static Future<void> shareFiles(
    BuildContext context,
    List<XFile> files, {
    String? text,
  }) async {
    final origin = _shareOrigin(context) ?? _fallbackOrigin();
    await Share.shareXFiles(
      files,
      text: text,
      sharePositionOrigin: origin,
    );
  }

  static Future<void> shareFilesWithoutContext(
    List<XFile> files, {
    String? text,
  }) async {
    await Share.shareXFiles(
      files,
      text: text,
      sharePositionOrigin: _fallbackOrigin(),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/ui_kit.dart';

/// A picked file ready to upload.
typedef PickedFile = ({List<int> bytes, String name});

/// Camera, photo library or (with [allowPdf]) a PDF from Files.
Future<PickedFile?> pickUploadFile(BuildContext context, {required String title, bool allowPdf = false, int maxBytes = 10 * 1024 * 1024}) async {
  final source = await showBpSheet<String>(
    context,
    showHandle: true,
    builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: tx(sheet, 16, weight: FontWeight.w800)),
      const SizedBox(height: 12),
      ActionTile(icon: Icons.photo_camera_outlined, title: 'Take a photo', onTap: () => Navigator.pop(sheet, 'camera')),
      ActionTile(icon: Icons.photo_library_outlined, title: 'Choose a photo', onTap: () => Navigator.pop(sheet, 'gallery')),
      if (allowPdf) ActionTile(icon: Icons.picture_as_pdf_outlined, title: 'Choose a PDF', onTap: () => Navigator.pop(sheet, 'pdf')),
    ]),
  );
  if (source == null) return null;

  PickedFile? picked;
  try {
    if (source == 'pdf') {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf'], withData: true);
      final f = r?.files.singleOrNull;
      if (f?.bytes != null) picked = (bytes: f!.bytes!, name: f.name);
    } else {
      final x = await ImagePicker().pickImage(source: source == 'camera' ? ImageSource.camera : ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
      if (x != null) picked = (bytes: await x.readAsBytes(), name: x.name);
    }
  } catch (_) {
    if (context.mounted) showToast(context, 'Couldn’t open that. Check the app’s permissions and try again.');
    return null;
  }

  if (picked != null && picked.bytes.length > maxBytes) {
    if (context.mounted) showToast(context, 'That file is too large (max ${maxBytes ~/ (1024 * 1024)}MB).');
    return null;
  }
  return picked;
}

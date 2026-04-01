import 'dart:io';

import 'package:focusflow_mobile/models/library_note.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentStorageService {
  static const _rootFolderName = 'FocusFlow';
  static const _attachmentsFolderName = 'attachments';

  static bool isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Future<Directory> getAttachmentsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(docsDir.path, _rootFolderName, _attachmentsFolderName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<String>> normalizeAttachmentPaths(
    List<String> paths,
  ) async {
    final normalizedAttachments = await normalizeAttachments(
      paths.map(LibraryNoteAttachment.fromLegacySource).toList(),
    );
    return normalizedAttachments
        .map((attachment) => attachment.source)
        .toList(growable: false);
  }

  static Future<List<LibraryNoteAttachment>> normalizeAttachments(
    List<LibraryNoteAttachment> attachments,
  ) async {
    final normalized = <LibraryNoteAttachment>[];
    for (final attachment in attachments) {
      final nextAttachment = await normalizeAttachment(attachment);
      if (nextAttachment != null && nextAttachment.source.isNotEmpty) {
        normalized.add(nextAttachment);
      }
    }
    return normalized;
  }

  static Future<String?> normalizeAttachmentPath(String path) async {
    final normalized = await normalizeAttachment(
      LibraryNoteAttachment.fromLegacySource(path),
    );
    return normalized?.source;
  }

  static Future<LibraryNoteAttachment?> normalizeAttachment(
    LibraryNoteAttachment attachment,
  ) async {
    final trimmed = attachment.source.trim();
    if (trimmed.isEmpty) return null;
    if (isWebLink(trimmed)) {
      return attachment.copyWith(
        source: trimmed,
        displayName: attachment.displayName,
        kind: LibraryNoteAttachment.detectKind(trimmed),
      );
    }

    final source = File(trimmed);
    if (!await source.exists()) {
      return attachment.copyWith(
        source: trimmed,
        displayName: attachment.displayName,
        kind: LibraryNoteAttachment.detectKind(trimmed),
      );
    }

    final attachmentsDir = await getAttachmentsDirectory();
    final normalizedSource = p.normalize(source.absolute.path);
    final normalizedRoot = p.normalize(attachmentsDir.absolute.path);
    if (_isWithinDirectory(normalizedSource, normalizedRoot)) {
      return attachment.copyWith(
        source: normalizedSource,
        displayName: attachment.displayName,
        kind: LibraryNoteAttachment.detectKind(normalizedSource),
      );
    }

    final fileName = _buildManagedFileName(trimmed);
    final destination = await _nextAvailableFile(
      attachmentsDir,
      preferredName: fileName,
    );
    await source.copy(destination.path);
    final normalizedPath = p.normalize(destination.path);
    return attachment.copyWith(
      source: normalizedPath,
      displayName: attachment.displayName,
      kind: LibraryNoteAttachment.detectKind(normalizedPath),
    );
  }

  static Future<String?> normalizeAttachmentPathLegacy(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (isWebLink(trimmed)) return trimmed;

    final source = File(trimmed);
    if (!await source.exists()) {
      return trimmed;
    }

    final attachmentsDir = await getAttachmentsDirectory();
    final normalizedSource = p.normalize(source.absolute.path);
    final normalizedRoot = p.normalize(attachmentsDir.absolute.path);
    if (_isWithinDirectory(normalizedSource, normalizedRoot)) {
      return normalizedSource;
    }

    final fileName = _buildManagedFileName(trimmed);
    final destination = await _nextAvailableFile(
      attachmentsDir,
      preferredName: fileName,
    );
    await source.copy(destination.path);
    return p.normalize(destination.path);
  }

  static Future<String> writeRestoredAttachment({
    required String originalPath,
    required List<int> bytes,
    String? suggestedFileName,
  }) async {
    final attachmentsDir = await getAttachmentsDirectory();
    final preferredName = _buildManagedFileName(
      suggestedFileName?.trim().isNotEmpty == true
          ? suggestedFileName!
          : originalPath,
      prefix: 'restored',
    );
    final destination = await _nextAvailableFile(
      attachmentsDir,
      preferredName: preferredName,
    );
    await destination.writeAsBytes(bytes, flush: true);
    return p.normalize(destination.path);
  }

  static Future<bool> deleteManagedAttachmentPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty || isWebLink(trimmed)) {
      return false;
    }

    final attachmentsDir = await getAttachmentsDirectory();
    final normalizedPath = p.normalize(File(trimmed).absolute.path);
    final normalizedRoot = p.normalize(attachmentsDir.absolute.path);
    if (!_isWithinDirectory(normalizedPath, normalizedRoot)) {
      return false;
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      return false;
    }

    await file.delete();
    return true;
  }

  static String buildArchiveFileName(int index, String sourcePath) {
    final extension = p.extension(sourcePath);
    final suffix = index.toString().padLeft(4, '0');
    return 'attachment_$suffix$extension';
  }

  static Future<File> _nextAvailableFile(
    Directory directory, {
    required String preferredName,
  }) async {
    var candidate = File(p.join(directory.path, preferredName));
    var counter = 1;
    while (await candidate.exists()) {
      final baseName = p.basenameWithoutExtension(preferredName);
      final extension = p.extension(preferredName);
      candidate = File(
        p.join(directory.path, '${baseName}_$counter$extension'),
      );
      counter++;
    }
    return candidate;
  }

  static String _buildManagedFileName(
    String sourcePath, {
    String prefix = 'attachment',
  }) {
    final basename = p.basename(sourcePath);
    final extension = p.extension(basename);
    final stem = p.basenameWithoutExtension(basename);
    final sanitizedStem =
        stem.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').replaceAll('_', '_');
    final safeStem = sanitizedStem.isEmpty ? prefix : sanitizedStem;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${timestamp}_$safeStem$extension';
  }

  static bool _isWithinDirectory(String path, String directoryPath) {
    final normalizedPath = p.normalize(path).toLowerCase();
    final normalizedDirectory = p.normalize(directoryPath).toLowerCase();
    return normalizedPath == normalizedDirectory ||
        normalizedPath.startsWith('$normalizedDirectory${p.separator}');
  }
}

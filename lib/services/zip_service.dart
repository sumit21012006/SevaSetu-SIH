import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/document.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../utils/format.dart';

class ZipPackResult {
  const ZipPackResult({
    required this.fileName,
    required this.filePath,
    required this.sizeBytes,
    required this.includedFiles,
    required this.missingDocuments,
    required this.expiringDocuments,
  });

  final String fileName;
  final String filePath;
  final int sizeBytes;
  final List<String> includedFiles;

  /// Requirement titles still missing (never faked into the ZIP).
  final List<String> missingDocuments;
  final List<String> expiringDocuments;

  String get sizeLabel => Formatters.bytes(sizeBytes);
}

/// Prepares the "Download Required Documents" ZIP — all currently available
/// documents for one service as a single archive.
abstract class ZipService {
  Future<ZipPackResult> buildServicePack({
    required GovService service,
    required ReadinessSummary summary,
  });
}

class LocalZipService implements ZipService {
  LocalZipService();

  @override
  Future<ZipPackResult> buildServicePack({
    required GovService service,
    required ReadinessSummary summary,
  }) async {
    final docs = summary.zipDocuments;
    final archive = Archive();
    final includedNames = <String>[];

    var index = 1;
    for (final doc in docs) {
      final fileBase = '${index.toString().padLeft(2, '0')}_${_fileBase(doc.type)}';
      
      if (doc.filePath != null && File(doc.filePath!).existsSync()) {
        final sourceFile = File(doc.filePath!);
        final bytes = await sourceFile.readAsBytes();
        final ext = doc.filePath!.contains('.') ? doc.filePath!.split('.').last.toLowerCase() : 'pdf';
        final zipPath = '$fileBase.$ext';
        archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        includedNames.add(zipPath);
      } else {
        final content = _docContent(doc);
        final zipPath = '$fileBase.txt';
        archive.addFile(ArchiveFile(zipPath, content.length, content));
        includedNames.add(zipPath);
      }
      index++;
    }

    final readme = _manifest(service, summary);
    archive.addFile(ArchiveFile('_SevaSetu_README.txt', readme.length, readme));
    includedNames.add('_SevaSetu_README.txt');

    final zipData = ZipEncoder().encode(archive);
    final bytes = Uint8List.fromList(zipData);

    final dir = Directory('${Directory.systemTemp.path}/sevasetu_zips');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final fileName =
        'SevaSetu_${Formatters.fileSafe(service.name)}_Documents.zip';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return ZipPackResult(
      fileName: fileName,
      filePath: file.path,
      sizeBytes: bytes.length,
      includedFiles: includedNames,
      missingDocuments: [
        for (final c in summary.missingChecks) c.requirement.type.title,
      ],
      expiringDocuments: [
        for (final c in summary.expiringChecks) c.requirement.type.title,
      ],
    );
  }

  String _fileBase(DocumentType type) => Formatters.fileSafe(type.title);

  Uint8List _docContent(CitizenDocument doc) {
    final buffer = StringBuffer()
      ..writeln('==============================================')
      ..writeln(' SEVASETU — SAMPLE DOCUMENT PACK')
      ..writeln('==============================================')
      ..writeln()
      ..writeln('Document: ${doc.title}')
      ..writeln('Category: ${doc.type.category.label}')
      ..writeln('Issuer: ${doc.issuer ?? doc.type.issuer}')
      ..writeln(
        'Number: ${Formatters.maskedDocNumber(doc.docNumber ?? doc.type.sampleNumber)}',
      )
      ..writeln('Status: ${_statusLabel(doc.status)}')
      ..writeln(
        doc.expiresAt != null
            ? 'Valid until: ${Formatters.date(doc.expiresAt!)}'
            : 'Validity: No expiry (lifetime)',
      )
      ..writeln('Uploaded: ${Formatters.date(doc.uploadedAt)}')
      ..writeln()
      ..writeln('NOTE: This is a sample placeholder produced by SevaSetu for')
      ..writeln('demonstration. It is NOT an official government document.')
      ..writeln('Replace with the original issued by the authority before');
    buffer.writeln('submitting any application.');
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  Uint8List _manifest(GovService service, ReadinessSummary summary) {
    final buffer = StringBuffer()
      ..writeln('SevaSetu Document Pack')
      ..writeln('======================')
      ..writeln('Service: ${service.name}')
      ..writeln('Prepared on: ${Formatters.dateTime(DateTime.now())}')
      ..writeln(
        'Readiness: ${summary.readyCount} of ${summary.requiredCount} documents',
      )
      ..writeln()
      ..writeln('Included documents (${summary.zipDocuments.length}):');
    var i = 1;
    for (final doc in summary.zipDocuments) {
      buffer.writeln(
        '  ${i.toString().padLeft(2, '0')}. ${doc.title}'
        ' — ${_statusLabel(doc.status)}',
      );
      i++;
    }
    if (summary.missingChecks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Still missing (NOT included):');
      for (final c in summary.missingChecks) {
        buffer.writeln('  • ${c.requirement.type.title}');
      }
    }
    if (summary.expiringChecks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Expiring soon — plan a renewal:');
      for (final c in summary.expiringChecks) {
        buffer.writeln(
          '  • ${c.requirement.type.title}'
          ' (${c.document != null && c.document!.expiresAt != null ? Formatters.date(c.document!.expiresAt!) : ''})',
        );
      }
    }
    if (summary.expiredChecks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Expired — renewal required:');
      for (final c in summary.expiredChecks) {
        buffer.writeln('  • ${c.requirement.type.title}');
      }
    }
    buffer
      ..writeln()
      ..writeln('Remember: sample files are placeholders, not real documents.');
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  String _statusLabel(DocStatus s) {
    switch (s) {
      case DocStatus.verified:
        return 'Verified';
      case DocStatus.available:
        return 'Available';
      case DocStatus.verificationRequired:
        return 'Verification pending';
      case DocStatus.expiringSoon:
        return 'Expiring soon';
      case DocStatus.expired:
        return 'Expired';
      case DocStatus.invalid:
        return 'Invalid';
      case DocStatus.missing:
        return 'Missing';
    }
  }
}

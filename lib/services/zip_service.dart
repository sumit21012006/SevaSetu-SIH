import 'dart:io';
import 'dart:typed_data';

import '../models/document.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../utils/format.dart';
import '../utils/zip_writer.dart';

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
///
/// Future implementation: files stream from Firebase Storage / object
/// storage; ZIP assembly stays server-side. V1 writes a real archive into
/// the app's temp directory using the dependency-free [ZipWriter].
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
    final entries = <ZipEntry>[];

    var index = 1;
    for (final doc in docs) {
      final base = '${index.toString().padLeft(2, '0')}_${_fileBase(doc.type)}';
      entries.add(ZipEntry('$base.txt', _docContent(doc)));
      index++;
    }
    entries.add(ZipEntry('_SevaSetu_README.txt', _manifest(service, summary)));

    final bytes = ZipWriter.write(entries);

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
      includedFiles: [for (final e in entries) e.name],
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

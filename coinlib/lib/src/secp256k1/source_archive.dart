import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

const secp256k1Commit = '69018e5b939d8d540ca6b237945100f4ecb5681e';
const _archiveSha256 =
    '907e2c050a939a1cede05752f1dc2b16c723b4d169dc2c7424c42ea721172e1a';
const _sourceDirectoryName = 'secp256k1-coinlib-$secp256k1Commit';
final _archiveUri = Uri.parse(
  'https://codeload.github.com/peercoin/secp256k1-coinlib/'
  'tar.gz/$secp256k1Commit',
);

/// Downloads, verifies, and caches the pinned secp256k1 source archive.
Future<Uri> ensureSecp256k1Source(Uri cacheRoot) async {
  final cacheDirectory = Directory.fromUri(cacheRoot);
  await cacheDirectory.create(recursive: true);

  final sourceDirectory = Directory.fromUri(
    cacheRoot.resolve('$_sourceDirectoryName/'),
  );
  final completeMarker = File.fromUri(sourceDirectory.uri.resolve('.complete'));
  if (await completeMarker.exists() &&
      await completeMarker.readAsString() == secp256k1Commit) {
    return sourceDirectory.uri;
  }

  if (await sourceDirectory.exists()) {
    await sourceDirectory.delete(recursive: true);
  }

  final archiveFile = File.fromUri(cacheRoot.resolve('source.tar.gz'));
  final temporaryArchive = File.fromUri(
    cacheRoot.resolve('source.tar.gz.download'),
  );
  if (await temporaryArchive.exists()) {
    await temporaryArchive.delete();
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(_archiveUri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to download secp256k1 source: HTTP ${response.statusCode}',
        uri: _archiveUri,
      );
    }
    await response.pipe(temporaryArchive.openWrite());
  } finally {
    client.close();
  }

  final digest = await sha256.bind(temporaryArchive.openRead()).first;
  if (digest.toString() != _archiveSha256) {
    await temporaryArchive.delete();
    throw StateError(
      'Invalid secp256k1 source archive checksum: $digest',
    );
  }

  if (await archiveFile.exists()) {
    await archiveFile.delete();
  }
  await temporaryArchive.rename(archiveFile.path);
  await extractFileToDisk(archiveFile.path, cacheDirectory.path);
  await archiveFile.delete();

  if (!await sourceDirectory.exists()) {
    throw StateError('The secp256k1 source archive has an unexpected layout.');
  }
  await completeMarker.writeAsString(secp256k1Commit);
  return sourceDirectory.uri;
}

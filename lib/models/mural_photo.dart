import 'dart:typed_data';

/// Foto selecionada no cliente antes do upload para o bucket `wall-photos`.
class MuralPhoto {
  const MuralPhoto({
    required this.bytes,
    required this.extensao,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String extensao;
  final String mimeType;

  int get tamanhoBytes => bytes.lengthInBytes;

  bool get dentroDoLimite => tamanhoBytes <= 5 * 1024 * 1024;
}

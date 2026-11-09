/// Normaliza o MIME type aceito pelo bucket `wall-photos`.
///
/// O seletor de arquivos do Linux costuma devolver `mimeType` nulo. O fallback
/// antigo gerava `image/jpg`, que o Storage rejeita porque o bucket aceita
/// apenas `image/jpeg`, `image/png` e `image/webp`.
String mimeDaFoto(String extensao, String? mimeType) {
  final mime = (mimeType ?? '').toLowerCase().trim();
  if (mime == 'image/jpeg' || mime == 'image/jpg') return 'image/jpeg';
  if (mime == 'image/png') return 'image/png';
  if (mime == 'image/webp') return 'image/webp';

  switch (extensao) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

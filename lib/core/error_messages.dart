import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Mensagens amigáveis para falhas de rede/autenticação/RLS.
String mensagemDeErro(Object erro, {String acao = 'carregar os dados'}) {
  if (erro is TimeoutException) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (erro is AuthException) {
    return 'Sua sessão expirou. Entre novamente.';
  }
  if (erro is PostgrestException) {
    if (erro.code == '42501') {
      return 'Você não tem acesso a este conteúdo.';
    }
    return 'Não foi possível $acao. Tente novamente.';
  }
  if (erro is StorageException) {
    final detalhe = '${erro.message} ${erro.error ?? ''}'.toLowerCase();
    if (detalhe.contains('mime') || detalhe.contains('content type')) {
      return 'Formato de foto não suportado. Use JPG, PNG ou WebP.';
    }
    if (detalhe.contains('size') ||
        detalhe.contains('too large') ||
        detalhe.contains('exceeded')) {
      return 'A foto passa do limite de 5 MB.';
    }
    if (detalhe.contains('policy') ||
        detalhe.contains('row-level security') ||
        detalhe.contains('not authorized') ||
        erro.statusCode == '403') {
      return 'Você não tem permissão para enviar esta foto.';
    }
    return 'Não foi possível enviar a foto. Tente novamente.';
  }
  return 'Sem conexão com o servidor. Verifique sua internet e tente novamente.';
}

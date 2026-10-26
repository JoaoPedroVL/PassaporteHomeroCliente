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
  return 'Sem conexão com o servidor. Verifique sua internet e tente novamente.';
}

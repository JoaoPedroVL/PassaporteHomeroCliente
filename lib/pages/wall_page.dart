import 'package:flutter/material.dart';

import '../core/error_messages.dart';
import '../data/consultas.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/responsive_body.dart';
import '../widgets/trip_padlet.dart';

/// Aba global de Padlets: lista as viagens acessíveis e abre o Padlet da
/// viagem selecionada. O Padlet também aparece dentro de cada viagem.
class WallPage extends StatefulWidget {
  const WallPage({super.key, required this.perfil});

  final UserProfile perfil;

  @override
  State<WallPage> createState() => _WallPageState();
}

class _WallPageState extends State<WallPage> {
  List<Trip> _viagens = const [];
  bool _carregando = true;
  bool _buscando = false;
  String? _erro;
  int _recarregarToken = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;

    if (!silencioso) {
      if (!mounted) {
        _buscando = false;
        return;
      }
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final viagens = await Consultas.viagensAcessiveis();
      if (!mounted) return;
      setState(() {
        _viagens = viagens;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar o Padlet');
        });
      }
    } finally {
      _buscando = false;
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _atualizar() {
    setState(() => _recarregarToken++);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: 'Padlet',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_carregando && _viagens.isEmpty) {
      return const LoadingState(mensagem: 'Abrindo o Padlet...');
    }

    if (_erro != null && _viagens.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregar(),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregar(),
        ),
      );
    }

    if (_viagens.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregar(),
        child: const SemViagens(),
      );
    }

    return TripPadlet(
      perfil: widget.perfil,
      viagens: _viagens,
      mostrarSeletor: true,
      mostrarCabecalho: true,
      recarregarToken: _recarregarToken,
    );
  }
}

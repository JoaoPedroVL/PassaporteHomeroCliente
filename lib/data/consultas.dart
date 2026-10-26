import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/formatters.dart';
import '../core/supabase_client.dart';
import '../models/badge.dart';
import '../models/checklist_item.dart';
import '../models/emergency_contact.dart';
import '../models/mural_photo.dart';
import '../models/review.dart';
import '../models/route_step.dart';
import '../models/trip.dart';
import '../models/trip_day.dart';
import '../models/wall_post.dart';

/// Consultas do app cliente. Todas passam pelas policies de RLS.
abstract final class Consultas {
  // ---------------------------------------------------------------------------
  // Viagens
  // ---------------------------------------------------------------------------

  /// Viagens publicadas que ainda não terminaram (Home).
  static Future<List<Trip>> viagensAtuais() async {
    final dados = await supabase
        .from('trips')
        .select('id, title, destination, start_date, end_date, status')
        .eq('status', 'published')
        .gte('end_date', hojeIso())
        .order('start_date', ascending: true);

    return dados
        .map((item) => Trip.fromMap(item))
        .toList(growable: false);
  }

  /// Viagens em que o viajante participou (Passaporte).
  static Future<List<Trip>> viagensDoPassaporte(String userId) async {
    final dados = await supabase
        .from('trip_participants')
        .select(
          'trip:trips(id, title, destination, start_date, end_date, status)',
        )
        .eq('user_id', userId);

    final viagens = <Trip>[];
    for (final item in dados) {
      final row = item;
      final trip = row['trip'];
      if (trip is Map<String, dynamic>) {
        viagens.add(Trip.fromMap(trip));
      }
    }

    viagens.sort((a, b) {
      final da = a.startDate;
      final db = b.startDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return viagens;
  }

  /// Viagens que o viajante pode acessar (para o seletor do mural).
  static Future<List<Trip>> viagensAcessiveis() async {
    final dados = await supabase
        .from('trips')
        .select('id, title, destination, start_date, end_date, status')
        .inFilter('status', ['published', 'closed'])
        .order('start_date', ascending: false);

    return dados
        .map((item) => Trip.fromMap(item))
        .toList(growable: false);
  }

  /// Dados completos de uma viagem.
  static Future<Trip?> viagem(String tripId) async {
    final dados = await supabase
        .from('trips')
        .select(
          'id, title, destination, start_date, end_date, status, description',
        )
        .eq('id', tripId)
        .maybeSingle();

    return dados == null ? null : Trip.fromMap(dados);
  }

  static Future<List<TripDay>> diasDaViagem(String tripId) async {
    final dados = await supabase
        .from('trip_days')
        .select('*')
        .eq('trip_id', tripId)
        .order('day_number', ascending: true);

    return dados
        .map((item) => TripDay.fromMap(item))
        .toList(growable: false);
  }

  static Future<List<RouteStep>> roteiroDaViagem(String tripId) async {
    final dados = await supabase
        .from('route_steps')
        .select('*')
        .eq('trip_id', tripId)
        .order('order_index', ascending: true);

    return dados
        .map((item) => RouteStep.fromMap(item))
        .toList(growable: false);
  }

  static Future<List<EmergencyContact>> contatosDaViagem(String tripId) async {
    final dados = await supabase
        .from('emergency_contacts')
        .select('*')
        .eq('trip_id', tripId)
        .order('name', ascending: true);

    return dados
        .map((item) => EmergencyContact.fromMap(item))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Checklist
  // ---------------------------------------------------------------------------

  static Future<List<ChecklistItem>> checklistDaViagem(
    String tripId,
    String userId,
  ) async {
    final itens = await supabase
        .from('checklist_items')
        .select('id, trip_id, order_index, title')
        .eq('trip_id', tripId)
        .order('order_index', ascending: true);

    if (itens.isEmpty) return const [];

    final ids = itens.map((item) => item['id'].toString()).toList();
    final progresso = await supabase
        .from('checklist_progress')
        .select('checklist_item_id')
        .eq('user_id', userId)
        .inFilter('checklist_item_id', ids);

    final concluidos = progresso
        .map((item) => item['checklist_item_id'].toString())
        .toSet();

    return itens.map((item) {
      final mapa = item;
      final id = mapa['id'].toString();
      return ChecklistItem.fromMap(mapa).copyWith(
        completed: concluidos.contains(id),
      );
    }).toList(growable: false);
  }

  static Future<void> marcarChecklist({
    required String userId,
    required String itemId,
    required bool concluido,
  }) async {
    if (concluido) {
      await supabase.from('checklist_progress').upsert(
        {
          'user_id': userId,
          'checklist_item_id': itemId,
        },
        onConflict: 'user_id,checklist_item_id',
      );
    } else {
      await supabase
          .from('checklist_progress')
          .delete()
          .eq('user_id', userId)
          .eq('checklist_item_id', itemId);
    }
  }

  // ---------------------------------------------------------------------------
  // Anotações
  // ---------------------------------------------------------------------------

  static Future<List<Annotation>> anotacoesDoViajante(String userId) async {
    final dados = await supabase
        .from('annotations')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return dados
        .map((item) => Annotation.fromMap(item))
        .toList(growable: false);
  }

  static Future<void> salvarAnotacao({
    required String userId,
    required String tripDayId,
    required String conteudo,
  }) async {
    await supabase.from('annotations').insert({
      'user_id': userId,
      'trip_day_id': tripDayId,
      'content': conteudo.trim(),
    });
  }

  // ---------------------------------------------------------------------------
  // Insígnias
  // ---------------------------------------------------------------------------

  static Future<List<Badge>> badgesAtivas() async {
    final dados = await supabase
        .from('badges')
        .select('*')
        .eq('active', true)
        .order('name', ascending: true);

    return dados
        .map((item) => Badge.fromMap(item))
        .toList(growable: false);
  }

  /// Mapa badge_id -> data de conquista.
  static Future<Map<String, DateTime?>> badgesDoViajante(
    String userId,
  ) async {
    final dados = await supabase
        .from('user_badges')
        .select('badge_id, awarded_at')
        .eq('user_id', userId);

    final mapa = <String, DateTime?>{};
    for (final item in dados) {
      final row = item;
      mapa[row['badge_id'].toString()] = DateTime.tryParse(
        row['awarded_at']?.toString() ?? '',
      );
    }
    return mapa;
  }

  // ---------------------------------------------------------------------------
  // Mural (Padlet)
  // ---------------------------------------------------------------------------

  static Future<List<WallPost>> mural({
    String? tripId,
    int limite = 60,
  }) async {
    final base = supabase
        .from('wall_posts')
        .select(
          'id, trip_id, user_id, content, moderation, created_at, '
          'trip:trips(title, destination), '
          'wall_post_images(storage_path, sort_order)',
        );

    final filtrada = tripId == null ? base : base.eq('trip_id', tripId);
    final dados = await filtrada
        .order('created_at', ascending: false)
        .limit(limite);

    final posts = dados
        .map((item) => WallPost.fromMap(item))
        .toList(growable: false);

    final caminhos = posts
        .expand((post) => post.imagePaths)
        .toSet()
        .toList(growable: false);

    final urls = <String, String>{};
    if (caminhos.isNotEmpty) {
      try {
        final assinadas = await supabase.storage
            .from('wall-photos')
            .createSignedUrlsResult(caminhos, 3600);
        for (final item in assinadas) {
          if (item is SignedUrlSuccess) {
            urls[item.path] = item.signedUrl;
          }
        }
      } catch (e) {
        // As fotos são opcionais: se a assinatura falhar, o texto continua.
        debugPrint('Erro ao assinar fotos do mural: $e');
      }
    }

    final ids = posts
        .map((post) => post.userId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return _comFotos(posts, urls);
    }

    final perfis = await supabase
        .from('public_profiles')
        .select('id, full_name')
        .inFilter('id', ids);

    final nomes = <String, String>{
      for (final item in perfis)
        item['id'].toString(): item['full_name']?.toString() ?? 'Viajante',
    };

    return _comFotos(
      posts
          .map((post) => post.copyWith(authorName: nomes[post.userId]))
          .toList(growable: false),
      urls,
    );
  }

  static List<WallPost> _comFotos(
    List<WallPost> posts,
    Map<String, String> urls,
  ) {
    return posts
        .map(
          (post) => post.copyWith(
            imageUrls: post.imagePaths
                .map((caminho) => urls[caminho])
                .whereType<String>()
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  /// Publica no Padlet da viagem. As fotos vão para o bucket privado
  /// `wall-photos` e são vinculadas à publicação em `wall_post_images`.
  ///
  /// Se o upload falhar, a publicação é removida para não deixar um
  /// post vazio no mural.
  static Future<void> criarPost({
    required String tripId,
    required String userId,
    required String conteudo,
    List<MuralPhoto> fotos = const [],
  }) async {
    final texto = conteudo.trim();
    final inserido = await supabase
        .from('wall_posts')
        .insert({
          'trip_id': tripId,
          'user_id': userId,
          'content': texto.isEmpty ? 'Memória em fotos' : texto,
          'moderation': 'pending',
        })
        .select('id')
        .single();

    final postId = inserido['id'].toString();
    final enviados = <String>[];

    try {
      for (var i = 0; i < fotos.length; i++) {
        final foto = fotos[i];
        final carimbo = DateTime.now().millisecondsSinceEpoch;
        final caminho =
            '$userId/$postId/${carimbo}_$i.${foto.extensao}';

        await supabase.storage.from('wall-photos').uploadBinary(
              caminho,
              foto.bytes,
              fileOptions: FileOptions(contentType: foto.mimeType),
            );
        enviados.add(caminho);

        await supabase.from('wall_post_images').insert({
          'post_id': postId,
          'storage_path': caminho,
          'sort_order': i,
        });
      }
    } catch (e) {
      for (final caminho in enviados) {
        try {
          await supabase.storage.from('wall-photos').remove([caminho]);
        } catch (_) {
          // Limpeza best-effort.
        }
      }
      try {
        await supabase.from('wall_posts').delete().eq('id', postId);
      } catch (_) {
        // Limpeza best-effort.
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Avaliações
  // ---------------------------------------------------------------------------

  static Future<Review?> minhaAvaliacao({
    required String tripId,
    required String userId,
  }) async {
    final dados = await supabase
        .from('reviews')
        .select('*')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();

    return dados == null ? null : Review.fromMap(dados);
  }

  static Future<void> salvarAvaliacao({
    required String userId,
    required String tripId,
    required int nota,
    String? comentario,
  }) async {
    final texto = comentario?.trim() ?? '';
    await supabase.from('reviews').upsert(
      {
        'user_id': userId,
        'trip_id': tripId,
        'rating': nota,
        'comment': texto.isEmpty ? null : texto,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,trip_id',
    );
  }

  // ---------------------------------------------------------------------------
  // Presença
  // ---------------------------------------------------------------------------

  /// Atualiza o último acesso do próprio viajante.
  static Future<void> registrarAcesso() async {
    await supabase.rpc('touch_last_seen');
  }
}

import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'dart:math';

class CodigoHelper {
  static Future<void> salvarCodigo({
    required int usuarioId,
    required String codigo,
  }) async {
    final db = await DatabaseHelper.instance.database; // pega a instância do DB

    await db.insert(
      'codigos', // tabela onde os códigos são armazenados
      {
        'usuario_id': usuarioId,
        'codigo': codigo,
        'data_criacao': DateTime.now().toIso8601String(),
      },
    );
  }

  static String gerarCodigo() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

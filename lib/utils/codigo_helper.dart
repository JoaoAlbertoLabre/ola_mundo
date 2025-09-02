import 'dart:math';

class CodigoHelper {
  static String gerarCodigo() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

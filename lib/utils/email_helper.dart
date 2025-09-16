import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailHelper {
  static Future<void> enviarEmailAdmin({
    required String nome,
    required String email,
    required String celular,
    required String codigoLiberacao,
    required String identificador,
  }) async {
    String username = 'vendocerto25@gmail.com';
    String password = 'jvzdxcjvozrcccva';

    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: username,
      password: password,
      ignoreBadCertificate: true,
      port: 587,
      ssl: false,
    );

    final message = Message()
      ..from = Address(username, 'Vendo Certo')
      ..recipients.add('vendocerto25@gmail.com')
      ..subject = 'Novo usuário cadastrado'
      ..text =
          'Nome: $nome\nEmail: $email\nCelular: $celular\nCódigo de liberação: $codigoLiberacao\nIdentificador: $identificador';

    try {
      await send(message, smtpServer);
      print('Email enviado com sucesso!');
    } catch (e) {
      print('Erro ao enviar email: $e');
    }
  }
}

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> enviarEmailAdmin({
  required String nome,
  required String email,
  required String celular,
  required String codigoLiberacao,
}) async {
  String username = 'carnesbebidas2022@gmail.com';
  String password = 'kikjmigspgpbivnu';

  // Cria o servidor SMTP ignorando erro de certificado (desenvolvimento apenas)
  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    username: username,
    password: password,
    ignoreBadCertificate: true,
    port: 587,
    ssl: false,
  );

  final message = Message()
    ..from = Address(username, 'App Financeiro')
    ..recipients.add('carnesbebidas2022@gmail.com')
    ..subject = 'Novo usuário cadastrado'
    ..text =
        'Nome: $nome\nEmail: $email\nCelular: $celular\nCódigo de liberação: $codigoLiberacao';

  try {
    await send(message, smtpServer);
    print('Email enviado com sucesso!');
  } catch (e) {
    print('Erro ao enviar email: $e');
  }
}

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'cadastro_screen.dart';
import 'novo_usuario_screen.dart';
import 'confirmacao_screen.dart';
import 'dart:async';
import 'recuperar_senha_screen.dart';
import '../utils/api_service.dart';

// Credenciais fixas para o avaliador do Google Play.
// Atenção: Use um nome de arquivo diferente para o build de produção se não quiser que essas credenciais existam.
const String GOOGLE_REVIEWER_ID = 'google';
const String GOOGLE_REVIEWER_PASSWORD = 'apprevieweraccess';

const int PRAZO_EXPIRACAO_MINUTOS = 43200; // 30 dias

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _exibirNovoUsuario = true;
  bool _senhaVisivel = false;

  Map<String, dynamic>? usuario;

  @override
  void initState() {
    super.initState();
    _verificarUsuariosExistentes();
    // A verificação periódica não precisa ser executada na tela de login,
    // apenas quando o usuário está autenticado e usando o app.
    // Manter por enquanto, mas pode ser movida para a tela principal (CadastroScreen)
    // para evitar chamadas de timer desnecessárias na inicialização.
    _iniciarVerificacaoLicencaPeriodica();
  }

  // Lógica de verificação periódica da licença
  void _iniciarVerificacaoLicencaPeriodica() {
    Timer.periodic(const Duration(minutes: 20), (_) async {
      if (!mounted) return;
      final routeAtual = ModalRoute.of(context);
      // Evita correr a verificação se já estiver na tela de confirmação (que resolve pendências).
      if (routeAtual?.settings.name == 'ConfirmacaoScreen') {
        return;
      }
      await _verificarELimparUsuarioSeLicencaExpirada();
    });
  }

  // Verifica se há usuários não confirmados ou com licença expirada logo na abertura do app
  Future<void> _verificarUsuariosExistentes() async {
    final db = DatabaseHelper.instance;
    final usuarioNaoConfirmado = await db.buscarUltimoUsuarioNaoConfirmado();

    // 1. Usuário não confirmado encontrado
    if (usuarioNaoConfirmado != null) {
      if (!mounted) return;
      // Redireciona para confirmação de cadastro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoScreen(usuario: usuarioNaoConfirmado),
        ),
      );
      return;
    }

    // 2. Verifica se a licença do último usuário expirou
    await _verificarELimparUsuarioSeLicencaExpirada();

    // Verificação para garantir que o estado só é atualizado se a tela ainda estiver "montada"
    if (mounted) {
      setState(() {
        // Assume que deve exibir o botão de novo cadastro se não houver um usuário ativo
        _exibirNovoUsuario = true;
      });
    }
  }

  // Limpa o usuário se a licença estiver expirada e redireciona para a tela de cadastro
  Future<void> _verificarELimparUsuarioSeLicencaExpirada() async {
    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUltimoUsuario();

    if (usuario != null) {
      final expirada = await db.isLicencaExpirada(usuario);
      if (expirada) {
        if (!mounted) return;

        // Atualiza status no servidor
        await ApiService.atualizarStatusCliente(
          identificador: usuario['identificador'].toString(),
          novoStatus: 'AGUARDANDO_PAGAMENTO',
        );

        // Limpa o QR code antigo
        await db.atualizarUsuario({
          'id': usuario['id'],
          'qr_code_data': null,
        });

        // Redireciona para CadastroScreen com aviso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CadastroScreen(licencaExpirada: true),
          ),
        );

        return; // garante que não continue executando o restante da função
      }
    }
  }

  void _entrar() async {
    final db = DatabaseHelper.instance;
    final nomeDigitado = _idController.text.trim();
    final senha = _passwordController.text.trim();

    if (nomeDigitado.isEmpty || senha.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }

    // LÓGICA DE ACESSO PARA O AVALIADOR DO GOOGLE PLAY (Mantida)
    if (nomeDigitado == GOOGLE_REVIEWER_ID &&
        senha == GOOGLE_REVIEWER_PASSWORD) {
      if (!mounted) return;
      // Redireciona diretamente para a tela principal (CadastroScreen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CadastroScreen()),
      );
      return;
    }

    // 🛑 ATUALIZAÇÃO DE SEGURANÇA: Usa uma função de autenticação com hash.
    // O método verificarSenhaHash deve:
    // 1. Buscar o usuário pelo nome.
    // 2. Comparar o hash da senha armazenada com a senha digitada (texto simples).
    // 3. Retornar o mapa do usuário SOMENTE se a senha for válida.
    final usuarioAutenticado = await db.verificarSenhaHash(nomeDigitado, senha);

    if (usuarioAutenticado == null) {
      if (!mounted) return;
      // Mensagem genérica por segurança: não revela se o erro é no nome de usuário ou na senha.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text("Usuário ou senha inválidos")));
      return;
    }

    // Usa o usuário validado
    final usuario = usuarioAutenticado;

    // Verifica se o usuário foi confirmado
    if (usuario['confirmado'] != 1) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Força a confirmação do cadastro
          builder: (_) => ConfirmacaoScreen(usuario: usuario, renovacao: false),
        ),
      );
      return;
    }

    // Verifica a licença
    final expirada = await db.isLicencaExpirada(usuario);
    if (expirada) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Se expirada, redireciona para a tela de renovação (CadastroScreen)
          builder: (_) => const CadastroScreen(licencaExpirada: true),
        ),
      );
      return;
    }

    // Login bem-sucedido
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  void _novoUsuario() async {
    final db = DatabaseHelper.instance;
    final ultimoUsuario = await db.buscarUltimoUsuario();

    // Se houver um usuário ativo e a licença NÃO estiver expirada
    if (ultimoUsuario != null) {
      final expirada = await db.isLicencaExpirada(ultimoUsuario);
      if (!expirada) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) {
            // Formata a data de validade para exibição
            final dataValidade = DateTime.parse(
              ultimoUsuario['data_validade'],
            ).toLocal();
            final dataFormatada =
                "${dataValidade.day.toString().padLeft(2, '0')}/${dataValidade.month.toString().padLeft(2, '0')}/${dataValidade.year}";
            return AlertDialog(
              title: const Text("Licença ativa"),
              content: Text(
                "Sua licença está válida até $dataFormatada.\n\nPara acessar, entre com seu nome de usuário e senha.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    // Se não houver usuário ativo ou a licença estiver expirada, permite novo cadastro
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NovoUsuarioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone e Logo
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.calculate,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.percent,
                      size: 32,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "VENDO CERTO",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Campo de Nome de usuário
              TextField(
                key: const Key(
                    'login_username'), // ← ID do recurso para Play Console
                controller: _idController,
                decoration: InputDecoration(
                  labelText: "Nome de usuário",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Senha
              TextField(
                key: const Key(
                    'login_password'), // ← ID do recurso para Play Console
                controller: _passwordController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: "Senha",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botão Entrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _entrar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Entrar", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 15),
              // Botão Cadastro
              if (_exibirNovoUsuario)
                TextButton(
                  onPressed: _novoUsuario,
                  child: const Text(
                    "Cadastro",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              // Botão Esqueceu a Senha
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecuperarSenhaScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Esqueceu a senha?",
                    style: TextStyle(fontSize: 14, color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

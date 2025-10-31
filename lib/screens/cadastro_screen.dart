// ESTE CÓDIGO ESTÁ GARANTIDAMENTE LIMPO DE CARACTERES U+00A0.

import 'dart:async';
import 'package:flutter/material.dart';
import 'produto_screen.dart';
import 'custo_fixo_screen.dart';
import 'custo_comercial_screen.dart';
import 'faturamento_screen.dart';
import 'lucro_screen.dart';
import 'login_screen.dart';
import 'ajuda_screen.dart';
import '../db/database_helper.dart';
import 'confirmacao_screen.dart';
import '../utils/api_service.dart';
import 'novo_usuario_screen.dart';

class CadastroScreen extends StatefulWidget {
  final bool licencaExpirada;

  const CadastroScreen({Key? key, this.licencaExpirada = false})
      : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // 1. Variável para controlar o Timer de verificação
  Timer? _verificadorLicenca;

  @override
  void initState() {
    super.initState();

    // Se veio da tela de login com licença expirada, mostra o alerta
    if (widget.licencaExpirada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarAlertaRenovacaoComLicencaExpirada();
      });
    }

    // 2. Inicia a verificação da licença periódica
    _iniciarVerificacaoLicenca();
  }

  // 3. Método para configurar e rodar o Timer
  // Verifica se a licença expirou a cada 1 minuto (pode ajustar a duração)
  void _iniciarVerificacaoLicenca() {
    _verificadorLicenca = Timer.periodic(const Duration(minutes: 1), (_) async {
      print("⏱️ Verificação periódica de licença em CadastroScreen rodando.");
      if (!mounted) return;

      final db = DatabaseHelper.instance;
      final usuario = await db.buscarUltimoUsuario();

      if (usuario != null) {
        final expirada = await db.isLicencaExpirada(usuario);

        if (expirada) {
          print(
              "🚨 Licença detectada como expirada pelo Timer. Redirecionando.");

          // Interrompe o Timer
          _verificadorLicenca?.cancel();

          // Redireciona para o fluxo de expiração/renovação (mostra o alerta)
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroScreen(licencaExpirada: true),
            ),
          );
        }
      }
    });
  }

  Future<void> _mostrarAlertaRenovacaoComLicencaExpirada() async {
    final db = DatabaseHelper.instance;
    // Busca o último usuário, mesmo que a licença esteja expirada, para obter os dados.
    final usuario = await db.buscarUltimoUsuario();
    if (usuario != null) {
      _mostrarAlertaRenovacao(usuario);
    }
  }

  // Adicione este método dentro de _CadastroScreenState, mas fora dos outros métodos
  void _mostrarErro(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _mostrarAlertaRenovacao(Map<String, dynamic> usuario) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              "Licença expirada",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          "Sua licença expirou.\nVálida por 30 dias.\n\nDeseja renovar a licença para continuar usando o app?",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              // --- INÍCIO DO FLUXO DE RENOVAÇÃO ---
              print("✅ Usuário clicou em Renovar. Iniciando fluxo de API.");

              // 1. Fecha o diálogo atual
              if (!mounted) return;
              Navigator.of(context).pop();

              // Garante que o usuário ainda está disponível (deve ser o caso)
              if (usuario == null) {
                _mostrarErro(context, 'Dados do usuário não encontrados.');
                return;
              }

              // 2. Chama a API para registrar o cliente novamente no servidor
              final resultadoApi = await ApiService.registrarCliente(
                // Campos de usuário e contato
                nomeFiscal: usuario['usuario'] ?? '',
                nomeUsuario: usuario['usuario'] ?? '',
                email: usuario['email'] ?? '',
                celular: usuario['celular'] ?? '',
                // DADOS FISCAIS
                cpfCnpj: usuario['cpfCnpj'] ?? '',
                cep: usuario['cep'] ?? '',
                logradouro: usuario['logradouro'] ?? '',
                numero: usuario['numero'] ?? '',
                complemento: usuario['complemento'] ?? '',
                bairro: usuario['bairro'] ?? '',
                cidade: usuario['cidade'] ?? '',
                uf: usuario['uf'] ?? '',
              );

              if (!mounted) return;

              // CORREÇÃO: Usamos resultadoApi['status'] == 'sucesso' ou verificamos 'success' explicitamente
              if (resultadoApi['status'] == 'sucesso' ||
                  resultadoApi['success'] == true) {
                // O LOG mostrou: {codigo_liberacao: NBTFJ779, identificador: ZO5BBDFZULJG1F6L, ...}
                // O identificador está na raiz, mas é bom ter um fallback.
                final novoIdentificador = resultadoApi['identificador'] ??
                    (resultadoApi['data']
                        as Map<String, dynamic>?)?['identificador'];

                if (novoIdentificador == null) {
                  _mostrarErro(context,
                      'Sucesso na API, mas o novo identificador está faltando.');
                  return;
                }

                print(
                  "🔹 Cliente registrado para renovação. Novo identificador: $novoIdentificador",
                );

                // 3. Atualiza o usuário LOCAL com o novo identificador e reseta a licença
                final db = DatabaseHelper.instance;
                final usuarioAtualizado = await db.resetarUsuarioParaRenovacao(
                  usuario,
                  novoIdentificador,
                );

                // 4. Vai para a tela de confirmação com os dados atualizados
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfirmacaoScreen(
                      usuario: usuarioAtualizado,
                      renovacao: true,
                    ),
                  ),
                );
              } else {
                // Se a API falhar, mostra um erro claro
                final errorMessage = resultadoApi['message'] ??
                    'Falha ao iniciar renovação. Verifique sua conexão ou tente novamente.';
                _mostrarErro(context, errorMessage);
              }
              // --- FIM DO FLUXO DE RENOVAÇÃO ---
            },
            child: const Text(
              "Renovar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // Redireciona para a tela de Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    // 4. Cancela o Timer quando a tela for descartada para evitar vazamento de memória
    _verificadorLicenca?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Início"),
        backgroundColor: Colors.blueGrey[700],
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text(
              "Sair",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
            context,
            icon: Icons.inventory,
            title: "Produtos",
            subtitle: "Cadastrar produtos e serviços",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProdutoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.business,
            title: "Custo Fixo",
            subtitle: "Cadastrar custos fixos mensais",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustoFixoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.attach_money,
            title: "Custo Comercial",
            subtitle: "Cadastrar custos por venda",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustoComercialScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.receipt_long,
            title: "Faturamento",
            subtitle: "Registrar vendas e faturamento",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FaturamentoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.account_balance_wallet,
            title: "Lucro",
            subtitle: "Analisar lucro e resultados",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LucroScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.help_outline,
            title: "Precisa de ajuda?",
            subtitle: "Clique aqui para suporte",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AjudaScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey[100],
          child: Icon(icon, color: Colors.blueGrey[800]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import '../utils/codigo_helper.dart';
import '../utils/api_service.dart';
import 'confirmacao_screen.dart';
import 'dart:io';

const Color primaryColor = Color(0xFF81D4FA);

// ATENÇÃO: A constante PRAZO_EXPIRACAO_MINUTOS DEVE SER IMPORTADA
// (ex: import 'package:app/config/config.dart';)
// O código abaixo NÃO COMPILARÁ até que você adicione esta constante!

class NovoUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioPreenchido;
  final String? codigoRenovacao;

  const NovoUsuarioScreen({
    super.key,
    this.usuarioPreenchido,
    this.codigoRenovacao,
  });

  @override
  State<NovoUsuarioScreen> createState() => _NovoUsuarioScreenState();
}

class _NovoUsuarioScreenState extends State<NovoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers existentes
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  // NOVOS CONTROLLERS para NFSe
  final TextEditingController _nomeRazaoSocialController =
      TextEditingController(); // NOVO: Nome/Razão Social
  final TextEditingController _cpfCnpjController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController =
      TextEditingController(); // Município
  final TextEditingController _ufController =
      TextEditingController(); // Estado (UF)

  final db = DatabaseHelper.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    // Disposes existentes
    _usuarioController.dispose();
    _senhaController.dispose();
    _emailController.dispose();
    _celularController.dispose();

    // NOVOS Disposes
    _nomeRazaoSocialController.dispose(); // NOVO Dispose
    _cpfCnpjController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();

    super.dispose();
  }

  // --- Funções de Validação de NOVOS Campos ---
  String? _validarCpfCnpj(String? value) {
    if (value == null || value.isEmpty)
      return "CPF/CNPJ é obrigatório para NFSe";
    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (somenteNumeros.length != 11 && somenteNumeros.length != 14) {
      return "CPF (11 dígitos) ou CNPJ (14 dígitos) inválido";
    }
    return null;
  }

  String? _validarCEP(String? value) {
    if (value == null || value.isEmpty) return "CEP é obrigatório";
    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (somenteNumeros.length != 8) {
      return "CEP inválido (8 dígitos)";
    }
    return null;
  }

  String? _validarCampoObrigatorio(String? value, String nomeCampo) {
    if (value == null || value.isEmpty) return "Informe o $nomeCampo";
    return null;
  }
  // ---------------------------------------------

  // Em novo_usuario_screen.dart

  Future<void> _cadastrarUsuario() async {
    print("🚀 Iniciando _cadastrarUsuario, _isLoading=$_isLoading");
    if (_isLoading) return; // Previne múltiplos cliques
    print("⚠️ Saindo porque já está carregando...");
    // Validações combinadas (Contato + Formulário)
    final contatoErro = _validarContatoObrigatorio();
    print("🔎 contatoErro=$contatoErro");
    if (contatoErro != null) {
      print("❌ Falha na validação de contato: $contatoErro");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(contatoErro)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    print("✅ Entrou no fluxo principal, _isLoading=true");
    try {
      print("➡️ Chamando ApiService.registrarCliente...");
      // 1. Envia os dados para o backend registrar o cliente
      final resultadoApi = await ApiService.registrarCliente(
        nomeUsuario: _usuarioController.text.trim(),
        nomeFiscal: _nomeRazaoSocialController.text.trim(),
        email: _emailController.text.trim(),
        celular: _celularController.text.trim(),
        cpfCnpj: _cpfCnpjController.text.trim(),
        cep: _cepController.text.trim(),
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        uf: _ufController.text.trim(),
      );
      print("✅ Resposta da API: $resultadoApi");
      if (!mounted) return;

      if (resultadoApi['success']) {
        print("➡️ Extraindo identificador e txid...");
        // 2. Se o backend registrou com sucesso, pegamos os IDs
        final identificadorDoServidor = resultadoApi['identificador'];
        final txidDoServidor = resultadoApi['txid'];
        print("✅ identificador=$identificadorDoServidor, txid=$txidDoServidor");
        if (identificadorDoServidor == null ||
            identificadorDoServidor.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro interno: O servidor não retornou o Identificador do cliente.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          // Retorna para interromper o fluxo se o dado essencial estiver faltando
          return;
        }

        print(
          "Cliente registrado no servidor. ID: $identificadorDoServidor, TXID: $txidDoServidor",
        );

        // 3. Monta o mapa de usuário para salvar no banco de dados LOCAL
        final agoraUtc = DateTime.now().toUtc();
        final novoUsuarioMap = {
          'usuario': _usuarioController.text.trim(),
          'senha': _senhaController.text.trim(),
          'email': _emailController.text.trim(),
          'celular': _celularController.text.trim(),
          'codigo_liberacao': CodigoHelper.gerarCodigo(),
          'confirmado': 0,
          'data_liberacao': agoraUtc.toIso8601String(),
          'data_validade': agoraUtc
              .add(
                const Duration(minutes: 15),
              ) // ATENÇÃO: Verifique o nome da sua constante de prazo
              .toIso8601String(),
          'identificador': identificadorDoServidor,
          'txid': txidDoServidor, // <--- CRÍTICO: Salvar o TXID no DB local
          'nome_fiscal': _nomeRazaoSocialController.text.trim(),
          'cpfCnpj': _cpfCnpjController.text.trim(),
          'cep': _cepController.text.trim(),
          'logradouro': _logradouroController.text.trim(),
          'numero': _numeroController.text.trim(),
          'complemento': _complementoController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'cidade': _cidadeController.text.trim(),
          'uf': _ufController.text.trim(),
        };

        // 4. Salva no banco de dados local
        print("➡️ Salvando no banco local...");
        await db.inserirUsuario(novoUsuarioMap);
        final usuarioSalvo = await db.buscarUltimoUsuario();
        print("✅ Usuário salvo com sucesso");
        // 5. VERIFICA SE O USUÁRIO FOI SALVO LOCALMENTE ANTES DE NAVEGAR
        if (usuarioSalvo != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmacaoScreen(
                usuario: usuarioSalvo,
              ), // Passa o mapa COMPLETO (com txid)
            ),
          );
        } else {
          // Se, por algum motivo, não encontrar o usuário local, exibe um erro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro crítico: Não foi possível salvar os dados localmente.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        // Se a API retornou um erro, mostra a mensagem
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultadoApi['message'] ?? 'Erro ao se comunicar com o servidor.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Captura qualquer outra exceção inesperada durante o processo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocorreu um erro inesperado: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // O BLOCO FINALLY GARANTE QUE O LOADING SEMPRE SERÁ DESATIVADO
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return "E-mail inválido";
    return null;
  }

  String? _validarCelular(String? value) {
    // Linha adicionada para tornar obrigatório
    if (value == null || value.isEmpty) return "Informe o celular";

    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (somenteNumeros.length < 10 || somenteNumeros.length > 11) {
      return "Celular inválido";
    }
    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) return "Informe a senha";
    if (value.length < 6) return "Senha deve ter pelo menos 6 caracteres";
    return null;
  }

  String? _validarContatoObrigatorio() {
    final email = _emailController.text.trim();
    final celular = _celularController.text.trim();
    if (email.isEmpty && celular.isEmpty) return "Informe e-mail e celular";
    return null;
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool obscure = false,
    String? dica = '',
    TextInputType keyboardType =
        TextInputType.text, // Adicionado tipo de teclado
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType, // Usando o tipo de teclado
          decoration: InputDecoration(
            labelText: label,
            hintText: dica,
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Cadastro Novo Usuário",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: () => exit(0),
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
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              const Text(
                "Dados de Contato e Fiscais para NFSe.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // --- SEÇÃO DE DADOS DE LOGIN E CONTATO ---
              _campoTexto(
                label: "Usuário (login)*", // Rótulo alterado de "Nome (login)*"
                controller: _usuarioController,
                validator: (v) =>
                    v!.isEmpty ? "Informe o nome de usuário" : null,
                icon: Icons.person,
              ),
              _campoTexto(
                label: "E-mail (Obrigatório)*",
                controller: _emailController,
                validator: (v) =>
                    _validarEmail(v) ?? _validarCampoObrigatorio(v, "E-mail"),
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _campoTexto(
                label: "Celular (Obrigatório)*",
                controller: _celularController,
                validator: _validarCelular,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _campoTexto(
                label: "Senha",
                controller: _senhaController,
                validator: _validarSenha,
                icon: Icons.lock,
                obscure: true,
                dica: "Mínimo 6 caracteres",
              ),

              const SizedBox(height: 30),
              // --- SEÇÃO DE DADOS FISCAIS PARA NFSE ---
              const Text(
                "Dados Fiscais (Tomador) - OBRIGATÓRIO para NFSe",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const Divider(),

              // NOVO CAMPO: Nome/Razão Social (Primeiro nos Dados Fiscais)
              _campoTexto(
                label: "Nome/Razão Social*",
                controller: _nomeRazaoSocialController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "Nome/Razão Social"),
                icon: Icons.business,
              ),

              // CPF/CNPJ
              _campoTexto(
                label: "CPF ou CNPJ*",
                controller: _cpfCnpjController,
                validator: _validarCpfCnpj,
                icon: Icons.badge,
                dica: "Apenas números.",
                keyboardType: TextInputType.number,
              ),
              // CEP
              _campoTexto(
                label: "CEP*",
                controller: _cepController,
                validator: _validarCEP,
                icon: Icons.location_on,
                dica: "Apenas 8 números",
                keyboardType: TextInputType.number,
              ),
              // Logradouro
              _campoTexto(
                label: "Logradouro (Rua/Av.)*",
                controller: _logradouroController,
                validator: (v) => _validarCampoObrigatorio(v, "Logradouro"),
                icon: Icons.signpost,
              ),
              // Número
              _campoTexto(
                label: "Número*",
                controller: _numeroController,
                validator: (v) => _validarCampoObrigatorio(v, "Número"),
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              // Complemento (Opcional)
              _campoTexto(
                label: "Complemento (Opcional)",
                controller: _complementoController,
                validator: (v) => null,
                icon: Icons.home_work,
              ),
              // Bairro
              _campoTexto(
                label: "Bairro*",
                controller: _bairroController,
                validator: (v) => _validarCampoObrigatorio(v, "Bairro"),
                icon: Icons.grid_view,
              ),
              // Município
              _campoTexto(
                label: "Município (Cidade)*",
                controller: _cidadeController,
                validator: (v) => _validarCampoObrigatorio(v, "Município"),
                icon: Icons.location_city,
              ),
              // Estado (UF)
              _campoTexto(
                label: "Estado (UF)*",
                controller: _ufController,
                validator: (v) =>
                    v!.length != 2 ? 'UF inválida (2 letras)' : null,
                icon: Icons.flag,
                dica: "Ex: TO",
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  onPressed: _isLoading ? null : _cadastrarUsuario,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : const Text(
                          "Cadastrar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

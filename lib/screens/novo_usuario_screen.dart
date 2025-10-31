import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // UpperCaseTextFormatter, formatters
import 'dart:convert';
import 'package:http/http.dart' as http; // consulta CEP
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../db/database_helper.dart';
import 'confirmacao_screen.dart';
import '../utils/codigo_helper.dart';
import '../utils/api_service.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../screens/login_screen.dart';

const Color primaryColor = Color(0xFF81D4FA);
const Color secondaryColor = Color(0xFF03A9F4);

const String MASK_CPF = '###.###.###-##';
const String MASK_CNPJ = '##.###.###/####-##';
//const int PRAZO_EXPIRACAO_MINUTOS = 15;

class NovoUsuarioScreen extends StatefulWidget {
  const NovoUsuarioScreen({super.key});

  @override
  State<NovoUsuarioScreen> createState() => _NovoUsuarioScreenState();
}

class _NovoUsuarioScreenState extends State<NovoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _nomeRazaoSocialController =
      TextEditingController();
  final TextEditingController _cpfCnpjController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  // Definição das máscaras no início do State
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final db = DatabaseHelper.instance;
  bool _isLoading = false;

  // CEP
  bool _isCepLoading = false;
  bool _cepPreenchido = false;
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Celular mask
  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // CPF/CNPJ mask dynamic
  bool _isCpfSelected = true;
  MaskTextInputFormatter get _activeCpfCnpjMask {
    return MaskTextInputFormatter(
      mask: _isCpfSelected ? MASK_CPF : MASK_CNPJ,
      filter: {"#": RegExp(r'[0-9]')},
    );
  }

  @override
  void initState() {
    super.initState();
    _cepController.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cepController.removeListener(_onCepChanged);
    _usuarioController.dispose();
    _senhaController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _nomeRazaoSocialController.dispose();
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

  // ---------------- CEP ----------------
  void _onCepChanged() {
    String cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 8) {
      _buscarCep(cep);
    } else if (cep.isEmpty) {
      _limparCamposEndereco(manterCep: true);
    }
  }

  Future<void> _buscarCep(String cep) async {
    if (_isCepLoading) return;
    setState(() => _isCepLoading = true);
    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Verifica se a API retornou erro (CEP não existe)
        if (data.containsKey('erro') && data['erro'] == true) {
          _limparCamposEndereco(manterCep: true); // Mantém o CEP digitado
          _showFeedbackSnackbar(
              'CEP não encontrado. Preencha o endereço manualmente.',
              isError: true);
        } else {
          _preencherCamposEndereco(data); // Preenche e mantém editável
        }
      } else {
        // Erro na requisição (servidor fora, etc.)
        _limparCamposEndereco(manterCep: true); // Mantém o CEP digitado
        _showFeedbackSnackbar(
            'Falha ao buscar CEP (${response.statusCode}). Preencha manualmente.',
            isError: true);
      }
    } catch (e) {
      // Erro de conexão, timeout, etc.
      if (!mounted) return;
      print('ERRO DE CONEXÃO CEP: $e'); // Adicionado para depuração
      _limparCamposEndereco(manterCep: true); // Mantém o CEP digitado
      _showFeedbackSnackbar(
        'Erro ao buscar CEP. Verifique a conexão e preencha manualmente.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isCepLoading = false);
    }
  }

  void _preencherCamposEndereco(Map<String, dynamic> data) {
    setState(() {
      // Correção: Usar as chaves corretas da API ViaCEP
      _logradouroController.text = (data['logradouro'] ?? '') as String;
      _bairroController.text = (data['bairro'] ?? '') as String;
      _cidadeController.text =
          (data['localidade'] ?? '') as String; // ViaCEP usa 'localidade'
      _ufController.text = (data['uf'] ?? '') as String;
      // Removido: _cepPreenchido = true; (não bloqueia mais)
    });
    // foca no número após preenchimento automático
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _limparCamposEndereco({bool manterCep = false}) {
    // Só limpa o CEP se explicitamente pedido (manterCep == false)
    if (!manterCep) _cepController.clear();
    setState(() {
      _logradouroController.clear();
      _numeroController.clear();
      _complementoController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _ufController.clear();
      // Removido: _cepPreenchido = false; (não afeta mais a edição)
    });
  }

  void _showFeedbackSnackbar(String message, {bool isError = false}) {
    // Garante que o BuildContext ainda é válido
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ---------------- Validações ----------------
  String? _validarCampoObrigatorio(String? value, String nomeCampo) {
    if (value == null || value.trim().isEmpty) return "Informe o $nomeCampo";
    return null;
  }

  String? _validarCpfCnpj(String? value) {
    if (value == null || value.trim().isEmpty)
      return "CPF/CNPJ é obrigatório para NFSe";

    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (_isCpfSelected) {
      // CPF
      if (somenteNumeros.length != 11) return "CPF inválido";
      if (!_validarCpf(somenteNumeros)) return "CPF inválido";
    } else {
      // CNPJ
      if (somenteNumeros.length != 14) return "CNPJ inválido";
      if (!_validarCnpj(somenteNumeros)) return "CNPJ inválido";
    }

    return null;
  }

  // Função para validar CPF
  bool _validarCpf(String cpf) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false; // todos iguais
    List<int> digitos = cpf.split('').map(int.parse).toList();

    int calc(int n) {
      int soma = 0;
      for (int i = 0; i < n; i++) {
        soma += digitos[i] * ((n + 1) - i);
      }
      int resto = (soma * 10) % 11;
      return resto == 10 ? 0 : resto;
    }

    return calc(9) == digitos[9] && calc(10) == digitos[10];
  }

  // Função para validar CNPJ
  bool _validarCnpj(String cnpj) {
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false; // todos iguais
    List<int> digitos = cnpj.split('').map(int.parse).toList();

    List<int> multiplicador1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> multiplicador2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int calc(List<int> mult) {
      int soma = 0;
      for (int i = 0; i < mult.length; i++) {
        soma += digitos[i] * mult[i];
      }
      int resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    return calc(multiplicador1) == digitos[12] &&
        calc(multiplicador2) == digitos[13];
  }

  String? _validarCEP(String? value) {
    if (value == null || value.trim().isEmpty) return "CEP é obrigatório";
    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (somenteNumeros.length != 8) return "CEP inválido (8 dígitos)";
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty)
      return null; // email opcional? aqui consideramos obrigatório via _validarCampoObrigatorio
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return "E-mail inválido";
    return null;
  }

  String? _validarCelular(String? value) {
    if (value == null || value.trim().isEmpty) return "Informe o celular";
    final somenteNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (somenteNumeros.length < 10 || somenteNumeros.length > 11)
      return "Celular inválido";
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

  // ---------------- Toggle CPF/CNPJ ----------------
  void _toggleCpfCnpj(bool selectCpf) {
    if (_isCpfSelected != selectCpf) {
      setState(() {
        _isCpfSelected = selectCpf;
        _cpfCnpjController.clear();
      });
    }
  }

  // ---------------- CADASTRO ----------------
  Future<void> _cadastrarUsuario() async {
    // evita múltiplos cliques
    if (_isLoading) {
      print("Já está carregando. Saindo.");
      return;
    }

    // primeiro: valida o form (exibe mensagens vermelhas por campo)
    if (!_formKey.currentState!.validate()) {
      print("Form inválido — abortando antes de chamar API.");
      _showFeedbackSnackbar("Corrija os campos em vermelho.", isError: true);
      return;
    }

    // validação extra defensiva do campo usuário (igual ao celular)
    final usuarioTrim = _usuarioController.text.trim();
    if (usuarioTrim.isEmpty) {
      print("Usuário vazio (checagem defensiva) — abortando.");
      _showFeedbackSnackbar("Usuário (login) é obrigatório.", isError: true);
      return;
    }

    // validação combinada de contato
    final contatoErro = _validarContatoObrigatorio();
    if (contatoErro != null) {
      _showFeedbackSnackbar(contatoErro, isError: true);
      print("Contato inválido: $contatoErro — abortando.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // DEBUG: payload antes da API
      final payloadApi = {
        "nomeUsuario": usuarioTrim,
        "nomeFiscal": _nomeRazaoSocialController.text.trim(),
        "email": _emailController.text.trim(),
        "celular": _celularController.text.trim(),
        "cpfCnpj": _cpfCnpjController.text.trim(),
        "cep": _cepController.text.trim(),
        "logradouro": _logradouroController.text.trim(),
        "numero": _numeroController.text.trim(),
        "complemento": _complementoController.text.trim(),
        "bairro": _bairroController.text.trim(),
        "cidade": _cidadeController.text.trim(),
        "uf": _ufController.text.trim(),
      };
      print("➡️ Payload API: $payloadApi");

      final resultadoApi = await ApiService.registrarCliente(
        nomeUsuario: payloadApi['nomeUsuario']!,
        nomeFiscal: payloadApi['nomeFiscal']!,
        email: payloadApi['email']!,
        celular: payloadApi['celular']!,
        cpfCnpj: payloadApi['cpfCnpj']!,
        cep: payloadApi['cep']!,
        logradouro: payloadApi['logradouro']!,
        numero: payloadApi['numero']!,
        complemento: payloadApi['complemento']!,
        bairro: payloadApi['bairro']!,
        cidade: payloadApi['cidade']!,
        uf: payloadApi['uf']!,
      );

      print("✅ Resultado API: $resultadoApi");

      if (!mounted) return;

      if (resultadoApi['status'] == 'sucesso') {
        final identificadorDoServidor = resultadoApi['identificador'] ??
            (resultadoApi['data'] != null
                ? resultadoApi['data']['identificador']
                : null);
        final txidDoServidor = resultadoApi[
                'txid_sugerido'] ?? // ✅ Buscar a chave correta
            (resultadoApi['data'] != null
                ? resultadoApi['data'][
                    'txid_sugerido'] // ✅ Buscar a chave correta dentro de 'data'
                : null);

        if (identificadorDoServidor == null ||
            identificadorDoServidor.toString().isEmpty) {
          _showFeedbackSnackbar(
            'Erro interno: servidor não retornou identificador.',
            isError: true,
          );
          print("Identificador ausente no resultadoApi -> $resultadoApi");
          return;
        }
        final senhaLimpa = _senhaController.text.trim();
        final senhaHash = sha256.convert(utf8.encode(senhaLimpa)).toString();

        final agoraUtc = DateTime.now().toUtc();
        final novoUsuarioMap = {
          'usuario': usuarioTrim,
          'senha': _senhaController.text.trim(),
          'email': _emailController.text.trim(),
          'celular': _celularController.text.trim(),
          'codigo_liberacao': CodigoHelper.gerarCodigo(),
          'confirmado': 0,
          'data_liberacao': agoraUtc.toIso8601String(),
          'data_validade': agoraUtc
              .add(const Duration(minutes: PRAZO_EXPIRACAO_MINUTOS))
              .toIso8601String(),
          'identificador': identificadorDoServidor,
          'txid': txidDoServidor ?? '',
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

        // DEBUG: confirmar antes de inserir
        print("➡️ Mapa que será salvo no DB: $novoUsuarioMap");

        if ((novoUsuarioMap['usuario'] ?? '').toString().trim().isEmpty) {
          _showFeedbackSnackbar(
            'Erro interno: campo usuario vazio (abortando).',
            isError: true,
          );
          print("Abortando: usuario vazio no mapa antes da inserção.");
          return;
        }

        final insertedId = await db.inserirUsuario(novoUsuarioMap);
        print("✅ Inserção local completada. insertedId=$insertedId");

        final usuarioSalvo = await db.buscarUltimoUsuario();
        print("🔎 usuarioSalvo do DB: $usuarioSalvo");

        if (usuarioSalvo != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmacaoScreen(usuario: usuarioSalvo),
            ),
          );
        } else {
          _showFeedbackSnackbar(
            'Erro crítico: Não foi possível salvar os dados localmente.',
            isError: true,
          );
          print("Falha: usuarioSalvo == null após inserção.");
        }
      } else {
        _showFeedbackSnackbar(
          resultadoApi['message'] ?? 'Erro ao se comunicar com o servidor.',
          isError: true,
        );
        print("API retornou sucesso=false -> ${resultadoApi['message']}");
      }
    } catch (e, st) {
      print("❗ Exception em _cadastrarUsuario: $e\n$st");
      if (mounted)
        _showFeedbackSnackbar(
          'Ocorreu um erro inesperado: ${e.toString()}',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- Widgets helpers ----------------
  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool obscure = false,
    String? dica = '',
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: dica,
            prefixIcon: Icon(icon, color: primaryColor),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: !enabled,
            fillColor: Colors.grey[200],
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCpfCnpjToggle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          _buildToggleButton(
            label: 'CPF',
            icon: Icons.person,
            isSelected: _isCpfSelected,
            onPressed: () => _toggleCpfCnpj(true),
          ),
          const SizedBox(width: 10),
          _buildToggleButton(
            label: 'CNPJ',
            icon: Icons.business,
            isSelected: !_isCpfSelected,
            onPressed: () => _toggleCpfCnpj(false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: isSelected ? Colors.white : secondaryColor),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? secondaryColor : Colors.white,
          side: BorderSide(color: secondaryColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isSelected ? 4 : 0,
        ),
      ),
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
          autovalidateMode: AutovalidateMode
              .onUserInteraction, // mostra erros no rodapé automaticamente
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

              // Usuário (agora com validator como os outros campos)
              _campoTexto(
                label: "Usuário (login)*",
                controller: _usuarioController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "Usuário (login)"),
                icon: Icons.person,
              ),

              _campoTexto(
                label: "E-mail (Obrigatório)*",
                controller: _emailController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "E-mail") ?? _validarEmail(v),
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _campoTexto(
                label: "Celular (Obrigatório)*",
                controller: _celularController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "Celular") ??
                    _validarCelular(v),
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                formatters: [_celularMask],
              ),
              _campoTexto(
                label: "Senha*",
                controller: _senhaController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "Senha") ?? _validarSenha(v),
                icon: Icons.lock,
                obscure: true,
                dica: "Mínimo 6 caracteres",
              ),

              const SizedBox(height: 20),
              const Text(
                "Dados Fiscais (Tomador) - OBRIGATÓRIO para NFSe",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const Divider(),

              _campoTexto(
                label: "Nome/Razão Social*",
                controller: _nomeRazaoSocialController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "Nome/Razão Social"),
                icon: Icons.business,
              ),

              // Definição das máscaras no início do State
              _buildCpfCnpjToggle(),
              _campoTexto(
                label: _isCpfSelected
                    ? "CPF (Pessoa Física)*"
                    : "CNPJ (Pessoa Jurídica)*",
                controller: _cpfCnpjController,
                validator: _validarCpfCnpj,
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                formatters: [_isCpfSelected ? _cpfMask : _cnpjMask],
              ),

              _campoTexto(
                label: "CEP*",
                controller: _cepController,
                validator: _validarCEP,
                icon: Icons.location_on,
                dica: "00000-000",
                keyboardType: TextInputType.number,
                formatters: [_cepMask],
                suffixIcon: _isCepLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 10,
                          width: 10,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),

              _campoTexto(
                label: "Logradouro (Rua/Av.)*",
                controller: _logradouroController,
                validator: (v) => _validarCampoObrigatorio(v, "Logradouro"),
                icon: Icons.signpost,
                enabled: !_cepPreenchido,
              ),
              _campoTexto(
                label: "Número*",
                controller: _numeroController,
                validator: (v) => _validarCampoObrigatorio(v, "Número"),
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              _campoTexto(
                label: "Complemento (Opcional)",
                controller: _complementoController,
                validator: (v) => null,
                icon: Icons.home_work,
              ),
              _campoTexto(
                label: "Bairro*",
                controller: _bairroController,
                validator: (v) => _validarCampoObrigatorio(v, "Bairro"),
                icon: Icons.grid_view,
                enabled: !_cepPreenchido,
              ),
              _campoTexto(
                label: "Município (Cidade)*",
                controller: _cidadeController,
                validator: (v) => _validarCampoObrigatorio(v, "Município"),
                icon: Icons.location_city,
                enabled: !_cepPreenchido,
              ),
              _campoTexto(
                label: "Estado (UF)*",
                controller: _ufController,
                validator: (v) =>
                    _validarCampoObrigatorio(v, "UF") ??
                    (v!.length != 2 ? 'UF inválida (2 letras)' : null),
                icon: Icons.flag,
                dica: "Ex: TO",
                enabled: !_cepPreenchido,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(2),
                  UpperCaseTextFormatter(),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.9),
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
                            color: Colors.white,
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

// Força uppercase no TextField
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // Necessário para o TimeoutException
import '../screens/login_screen.dart';

class ApiService {
  static final String _baseUrl = 'https://vendocerto-app.onrender.com';

  /// Envia os dados do novo usuário (incluindo dados fiscais) para o backend e recebe o identificador único.
  static Future<Map<String, dynamic>> registrarCliente({
    required String nomeFiscal,
    required String nomeUsuario,
    required String email,
    required String celular,
    // DADOS FISCAIS OBRIGATÓRIOS:
    required String cpfCnpj,
    required String cep,
    required String logradouro,
    required String numero,
    required String complemento,
    required String bairro,
    required String cidade,
    required String uf,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/registrar-cliente'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'nome': nomeFiscal,
              'nomeUsuario': nomeUsuario,
              'email': email,
              'celular': celular,
              'cpfCnpj': cpfCnpj,
              'cep': cep,
              'logradouro': logradouro,
              'numero': numero,
              'complemento': complemento,
              'bairro': bairro,
              'municipio': cidade, // Mapeado de 'cidade'
              'estado': uf, // Mapeado de 'uf'
            }),
          )
          .timeout(const Duration(seconds: 60));

      // Tenta decodificar o corpo da resposta
      Map<String, dynamic> responseBody;
      try {
        responseBody = json.decode(response.body);
      } catch (e) {
        // Falha ao decodificar JSON (resposta inesperada do servidor)
        return {
          'status': 'erro',
          'message': 'Erro de comunicação: Resposta inválida do servidor.'
        };
      }

      print(
        'Resposta do Servidor (Status ${response.statusCode}): $responseBody',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sucesso
        final identificador = responseBody['identificador'] as String?;

        if (identificador == null || identificador.isEmpty) {
          // Se o servidor retornar 200/201 mas faltar o identificador
          return {
            'status': 'erro',
            'message':
                'Erro de comunicação: Identificador de cliente não retornado pelo servidor.',
          };
        }

        print(
          'SUCESSO API: Identificador retornado e extraído: $identificador',
        );

        // 💡 CORREÇÃO CRÍTICA: Retorna o mapa original do servidor,
        // que contém 'status: sucesso', 'identificador', 'txid_sugerido'.
        // Isso evita o 'NoSuchMethodError: The method '[]' was called on null' na tela.
        return responseBody;
      } else {
        // Erros de Status (4xx, 5xx)
        return {
          'status': 'erro',
          'message': responseBody['erro'] ??
              responseBody['message'] ??
              'Falha ao registrar cliente. Status: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      return {
        'status': 'erro',
        'message':
            'O servidor demorou muito para responder. Tente novamente mais tarde.',
      };
    } catch (e) {
      return {
        'status': 'erro',
        'message':
            'Não foi possível conectar ao servidor. Verifique sua conexão. Erro: ${e.toString()}',
      };
    }
  }

  /// (Função para o Polling) Verifica se o pagamento do usuário foi concluído.
  static Future<Map<String, dynamic>> verificarStatusUsuario(
    String identificador,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/usuario/status-pagamento'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'identificador': identificador}),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        // Se o backend retornar txid dentro do body, pega aqui:
        final txid = responseBody['txid'] as String?;
        return {
          'success': true,
          'data': {'identificador': identificador, 'txid': txid},
        };
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Pagamento ainda não confirmado',
        };
      }
    } on TimeoutException {
      // Adicionando tratamento de Timeout
      return {'success': false, 'message': 'Tempo limite de conexão excedido.'};
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Envia o código de liberação digitado pelo usuário para validação.
  static Future<Map<String, dynamic>> confirmarCodigo(String codigo) async {
    final url = Uri.parse('$_baseUrl/api/confirmar-codigo');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'codigo': codigo}),
          )
          .timeout(const Duration(seconds: 15));
      final responseBody = jsonDecode(response.body);
      switch (response.statusCode) {
        case 200:
          return {
            'success': true,
            'message': responseBody['sucesso'] ?? 'Código confirmado!',
          };
        default: // Combina todos os casos de erro (404, 409, etc)
          return {
            'success': false,
            'message':
                responseBody['erro'] ?? 'Ocorreu um erro. Tente novamente.',
          };
      }
    } on TimeoutException {
      // Adicionando tratamento de Timeout
      return {'success': false, 'message': 'Tempo limite de conexão excedido.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Não foi possível conectar ao servidor.',
      };
    }
  }

  /// Pede ao backend para criar a cobrança PIX e retorna os dados do QR Code.
  static Future<Map<String, dynamic>> criarCobranca(String txid) async {
    // Validação simples para evitar enviar um txid nulo ou vazio
    if (txid.isEmpty) {
      return {
        'success': false,
        'message':
            'Erro interno: TXID inválido fornecido para criar a cobrança.'
      };
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/criar-cobranca'),
            headers: {'Content-Type': 'application/json'},
            // Enviamos o txid com a chave que o backend espera ('txid_sugerido')
            body: json.encode({'txid_sugerido': txid}),
          )
          .timeout(const Duration(seconds: 20));

      print(
          'Resposta RAW do Servidor para criarCobranca (Status ${response.statusCode}): ${response.body}');

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              'ERRO DE ROTA (404): O servidor não encontrou a rota /api/criar-cobranca. Verifique a configuração de rotas no backend (Python/Flask).',
        };
      }

      Map<String, dynamic> responseBody;
      try {
        responseBody = json.decode(response.body);
      } catch (e) {
        print(
            'ERRO: Falha ao decodificar JSON em criarCobranca. Body recebido: ${response.body}. Erro: $e');
        return {
          'success': false,
          'message':
              'Erro ao processar a resposta do servidor. O servidor não retornou um formato JSON válido.'
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['detalhes']?['violacoes']?[0]?['razao'] ??
              responseBody['erro'] ??
              'Falha ao gerar QR Code. (Status: ${response.statusCode})',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Tempo limite de conexão excedido.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão ao gerar QR Code: ${e.toString()}'
      };
    }
  }

  /// Envia o código de recuperação do usuário para o backend (Render)
  static Future<Map<String, dynamic>> enviarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final url = Uri.parse('$_baseUrl/api/atualizar-codigo-recuperacao');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'email': email, 'codigo_recuperacao': codigo}),
          )
          .timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['sucesso'] ?? 'Código enviado com sucesso!',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['erro'] ?? 'Falha ao enviar código.',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Tempo limite de conexão excedido.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Não foi possível conectar ao servidor. Erro: $e',
      };
    }
  }

  /// Atualiza o status do cliente no servidor (ex: CONCLUIDA → AGUARDANDO_PAGAMENTO)
  static Future<Map<String, dynamic>> atualizarStatusCliente({
    required String identificador,
    required String novoStatus,
  }) async {
    final url = Uri.parse('$_baseUrl/api/atualizar-status');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'identificador': identificador,
              'status': novoStatus,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print(
          'Resposta do servidor ao atualizar status (Status ${response.statusCode}): $responseBody');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseBody['mensagem'] ?? 'Status atualizado com sucesso!',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['erro'] ?? 'Falha ao atualizar status.',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Tempo limite de conexão excedido ao atualizar status.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar ao servidor: ${e.toString()}',
      };
    }
  }
}

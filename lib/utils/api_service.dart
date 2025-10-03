// lib/utils/api_service.dart
// Versão corrigida com a URL da API padronizada e novos campos fiscais no registrarCliente.
// CORREÇÃO: Mapeamento correto das chaves 'nomeFiscal' e 'nomeUsuario' para o backend.

import 'dart:convert';
import 'package:http/http.dart' as http;

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
    required String cidade, // Corrigido para ser 'cidade'
    required String uf, // Corrigido para ser 'uf'
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/registrar-cliente'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              // CORREÇÃO: Chaves devem ser 'nomeFiscal' e 'nomeUsuario'
              'nomeFiscal': nomeFiscal, // Chave correta para NFSe
              'nomeUsuario':
                  nomeUsuario, // Chave correta para o nome de contato
              'email': email,
              'celular': celular,

              'cpfCnpj': cpfCnpj,
              'cep': cep,
              'logradouro': logradouro,
              'numero': numero,
              'complemento': complemento,
              'bairro': bairro,
              'cidade': cidade,
              'uf': uf,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final responseBody = json.decode(response.body);

      // DEBUG: Adiciona o print para ver o que o servidor realmente está a retornar
      print(
        'Resposta do Servidor (Status ${response.statusCode}): $responseBody',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🚨 CORREÇÃO PRINCIPAL:
        // 1. Acede à chave 'data' primeiro (onde o backend aninhou o identificador).
        final data = responseBody['data'] as Map<String, dynamic>?;

        // 2. Acede à chave 'identificador' (minúsculo) dentro do mapa 'data'.
        final identificador = data?['identificador'] as String?;
        final txid = data?['txid'] as String?;

        if (identificador == null || identificador.isEmpty) {
          return {
            'success': false,
            'message':
                'Erro de comunicação: Identificador de cliente não retornado pelo servidor.',
          };
        }

        // 🚨 NOVO DEBUG: Imprime o identificador extraído com sucesso
        print(
          'SUCESSO API: Identificador retornado e extraído: $identificador',
        );

        // Retorna sucesso e o identificador
        return {'success': true, 'identificador': identificador, 'txid': txid};
      } else {
        // Se houver qualquer erro (400, 500, etc.), o erro será exibido
        return {
          'success': false,
          'message':
              responseBody['erro'] ??
              responseBody['message'] ??
              'Falha ao registrar cliente.',
        };
      }
    } catch (e) {
      return {
        'success': false,
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
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Envia o código de liberação digitado pelo usuário para validação.
  static Future<Map<String, dynamic>> confirmarCodigo(String codigo) async {
    // A URL está correta e agora o backend tem uma rota para respondê-la.
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
    } catch (e) {
      return {
        'success': false,
        'message': 'Não foi possível conectar ao servidor.',
      };
    }
  }

  /// Pede ao backend para criar a cobrança PIX e retorna os dados do QR Code.
  static Future<Map<String, dynamic>> criarCobranca(
    String identificador,
  ) async {
    try {
      final response = await http
          .post(
            // CORREÇÃO: Padroniza a URL para usar o prefixo /api/
            Uri.parse('$_baseUrl/api/criar-cobranca'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'identificador': identificador}),
          )
          .timeout(const Duration(seconds: 20));

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message':
              responseBody['detalhes']?['violacoes']?[0]?['razao'] ??
              responseBody['erro'] ??
              'Falha ao gerar QR Code.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão ao gerar QR Code.'};
    }
  }
}

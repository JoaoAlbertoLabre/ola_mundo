import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vendo_certo/models/produtos_model.dart';
import 'package:vendo_certo/utils/codigo_helper.dart';
import 'package:vendo_certo/screens/login_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Certifique-se de que este pacote está no seu pubspec.yaml

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calculadora.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // --- 🔑 UTILITY HASHING FUNCTION (REMOVIDA DE DENTRO DO verificarSenhaHash) ---
  String _gerarHashSeguro(String senhaPura) {
    final bytes = utf8.encode(senhaPura);
    final hashDigest = sha256.convert(bytes);
    return hashDigest.toString();
  }
  // --------------------------------------------------------------------------

  // 🔴 Função para resetar o banco
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calculadora.db');

    // Fecha a conexão se estiver aberta
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Apaga o arquivo físico do banco
    await deleteDatabase(path);

    // Recria automaticamente ao chamar database novamente
    _database = await _initDB('calculadora.db');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      final result = await db.rawQuery("PRAGMA table_info(produto)");
      final hasTipo = result.any((column) => column['name'] == 'tipo');
      if (!hasTipo) {
        //await db.execute('ALTER TABLE produto ADD COLUMN tipo TEXT');
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario TEXT NOT NULL,
      senha TEXT NOT NULL,
      email TEXT,
      celular TEXT,
      codigo_liberacao TEXT,
      confirmado INTEGER NOT NULL DEFAULT 0,
      data_liberacao TEXT,
      data_validade TEXT,
      identificador TEXT,
      txid TEXT NOT NULL UNIQUE,
      codigo_recuperacao TEXT,
      qr_code_data TEXT,
      
      -- ADICIONE ESTAS COLUNAS --
      nome_fiscal TEXT,
      cpfCnpj TEXT,
      cep TEXT,
      logradouro TEXT,
      numero TEXT,
      complemento TEXT,
      bairro TEXT,
      cidade TEXT,
      uf TEXT
      )
      ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS codigos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL,
      codigo TEXT NOT NULL,
      data_criacao TEXT NOT NULL,
      FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS produto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        un TEXT,
        custo REAL,
        venda REAL,
        tipo TEXT
      )
      ''');

    // ------------------- CUSTO FIXO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custo_fixo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aluguel REAL,
        contador REAL,
        telefone_internet REAL,
        aplicativos REAL,
        energia REAL,
        agua REAL,
        mat_limpeza REAL,
        combustivel REAL,
        funcionario REAL,
        outros1 REAL,
        outros2 REAL,
        outros3 REAL
      )
      ''');

    // ------------------- CUSTO COMERCIAL -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custo_comercial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comissao REAL,
        impostos REAL,
        cartao REAL,
        outros1 REAL,
        outros2 REAL,
        outros3 REAL
      )
      ''');

    // ------------------- FATURAMENTO -------------------
    await db.execute('''
      CREATE TABLE faturamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mes INTEGER NOT NULL,
        ano INTEGER NOT NULL,
        valor REAL NOT NULL
      )

      ''');

    // ------------------- LUCRO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lucro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mes INTEGER NOT NULL,
        ano INTEGER NOT NULL,
        percentual REAL NOT NULL
      )
      ''');

    // ------------------- MATERIA PRIMA -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS materia_prima (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        un TEXT,
        valor REAL
      )
      ''');

    // ------------------- INSUMO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS insumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        un TEXT,
        valor REAL
      )
      ''');

    // ------------------- COMPOSICAO PRODUTO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS composicao_produto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produto_id INTEGER NOT NULL,
        insumo_id INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        FOREIGN KEY (produto_id) REFERENCES produto(id),
        FOREIGN KEY (insumo_id) REFERENCES insumo(id)
      )
      ''');
  }

  //  =================== USUÁRIO ======================
  Future<Map<String, dynamic>?> buscarUsuarioPorId(int id) async {
    final db = await database;
    final resultado = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (resultado.isNotEmpty) {
      return resultado.first;
    }
    return null;
  }

  // Inserir o usuário (apenas 1 usuário)
  Future<int> inserirUsuario(Map<String, dynamic> usuario) async {
    final db = await database;

    // ⚠️ CORREÇÃO CRÍTICA: Hashear a senha antes de salvar no DB
    if (usuario.containsKey('senha')) {
      final senhaPura = usuario['senha'] as String;
      // Sobrescreve a senha pura com o hash seguro
      usuario['senha'] = _gerarHashSeguro(senhaPura);
    }

    return await db.insert(
      'usuarios',
      usuario,
      //conflictAlgorithm: ConflictAlgorithm.replace, // substitui se id duplicado
    );
  }

  // Buscar o usuário (retorna o único usuário do app)
  Future<Map<String, dynamic>?> buscarUsuario() async {
    final db = await database;
    final res = await db.query('usuarios');
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Atualizar usuário (para confirmar o cadastro ou alterar dados)
  Future<int> atualizarUsuario(Map<String, dynamic> usuario) async {
    final db = await instance.database;
    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [usuario['id']],
    );
  }

  Future<Map<String, dynamic>?> buscarUltimoUsuario() async {
    final db = await instance.database;
    final res = await db.query('usuarios', orderBy: 'id DESC', limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  // Busca usuário pelo email
  Future<Map<String, dynamic>?> buscarUsuarioPorEmail(String email) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> buscarUltimaLicencaValida() async {
    final db = await database;
    final resultado = await db.query(
      'usuarios',
      where: 'confirmado = 1',
      orderBy: 'data_liberacao DESC',
      limit: 1,
    );
    return resultado.isNotEmpty ? resultado.first : null;
  }

  // Remove um usuário pelo ID
  Future<int> removerUsuario(int id) async {
    final db = await database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  // Buscar usuário por celular
  Future<Map<String, dynamic>?> buscarUsuarioPorCelular(String celular) async {
    final db = await database;

    final res = await db.query(
      'usuarios',
      where: 'celular = ?',
      whereArgs: [celular],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    final db = await database;
    final res = await db.query('usuarios');
    return res;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorNome(String nome) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [nome],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> queryUsuarioPorId(int id) async {
    final db = await database;
    final result = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ================-Nova Logica+++++++++++++++

  // ==================== CRUD PRODUTO ====================
  Future<int> inserirProduto(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('produto', row);
  }

  Future<List<Map<String, dynamic>>> listarProdutos() async {
    final db = await instance.database;
    return await db.query('produto');
  }

  Future<int> atualizarProduto(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('produto', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarProduto(int id) async {
    final db = await instance.database;
    return await db.delete('produto', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD CUSTO FIXO ====================
  Future<int> inserirCustoFixo(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('custo_fixo', row);
  }

  Future<List<Map<String, dynamic>>> listarCustosFixos() async {
    final db = await instance.database;
    return await db.query('custo_fixo');
  }

  Future<int> atualizarCustoFixo(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('custo_fixo', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarCustoFixo(int id) async {
    final db = await instance.database;
    return await db.delete('custo_fixo', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD CUSTO COMERCIAL ====================
  Future<int> inserirCustoComercial(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('custo_comercial', row);
  }

  Future<List<Map<String, dynamic>>> listarCustosComerciais() async {
    final db = await instance.database;
    return await db.query('custo_comercial');
  }

  Future<int> atualizarCustoComercial(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'custo_comercial',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarCustoComercial(int id) async {
    final db = await instance.database;
    return await db.delete('custo_comercial', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> somarCustoComercial() async {
    final dbClient = await database;
    final result = await dbClient.rawQuery('''
    SELECT 
      COALESCE(SUM(comissao), 0) +
      COALESCE(SUM(impostos), 0) +
      COALESCE(SUM(cartao), 0) +
      COALESCE(SUM(outros1), 0) +
      COALESCE(SUM(outros2), 0) +
      COALESCE(SUM(outros3), 0) AS total
    FROM custo_comercial
    ''');

    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0;
  }

  // ==================== CRUD FATURAMENTO ====================
  Future<int> inserirFaturamento(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('faturamento', row);
  }

  Future<List<Map<String, dynamic>>> listarFaturamentos() async {
    final db = await instance.database;
    return await db.query('faturamento', orderBy: 'ano DESC, mes DESC');
  }

  Future<int> atualizarFaturamento(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'faturamento',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarFaturamento(int id) async {
    final db = await instance.database;
    return await db.delete('faturamento', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD LUCRO ====================
  Future<int> inserirLucro(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('lucro', row);
  }

  Future<List<Map<String, dynamic>>> listarLucros() async {
    final db = await instance.database;
    return await db.query('lucro');
  }

  Future<int> atualizarLucro(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('lucro', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarLucro(int id) async {
    final db = await instance.database;
    return await db.delete('lucro', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD MATERIA PRIMA ====================
  Future<int> inserirMateriaPrima(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('materia_prima', row);
  }

  Future<List<Map<String, dynamic>>> listarMateriasPrimas() async {
    final db = await instance.database;
    return await db.query('materia_prima');
  }

  Future<int> atualizarMateriaPrima(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'materia_prima',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarMateriaPrima(int id) async {
    final db = await instance.database;
    return await db.delete('materia_prima', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD INSUMO ====================
  Future<int> inserirInsumo(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('insumo', row);
  }

  Future<List<Map<String, dynamic>>> listarInsumos() async {
    final db = await instance.database;
    return await db.query('insumo');
  }

  Future<int> atualizarInsumo(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('insumo', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarInsumo(int id) async {
    final db = await instance.database;
    return await db.delete('insumo', where: 'id = ?', whereArgs: [id]);
  }

  // Retorna lista de produtos que usam o insumo
  Future<List<Map<String, dynamic>>> buscarProdutosPorInsumo(
    int insumoId,
  ) async {
    final dbClient = await database;
    // Supondo que você tenha uma tabela 'composicao_produto' com colunas 'produto_id' e 'insumo_id'
    // E uma tabela 'produto' com 'id' e 'nome'
    final result = await dbClient.rawQuery(
      '''
    SELECT p.nome
    FROM composicao_produto cp
    JOIN produto p ON cp.produto_id = p.id
    WHERE cp.insumo_id = ?
  ''',
      [insumoId],
    );

    return result;
  }

  // ==================== CRUD COMPOSICAO PRODUTO ====================
  Future<int> inserirComposicao(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('composicao_produto', row);
  }

  Future<List<Map<String, dynamic>>> listarComposicoes() async {
    final db = await instance.database;
    return await db.query('composicao_produto');
  }

  Future<int> atualizarComposicao(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'composicao_produto',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarComposicao(int id) async {
    final db = await instance.database;
    return await db.delete(
      'composicao_produto',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //========================FUNÇÕES=============================

  // Somar todos os custos fixos cadastrados
  Future<double> somarCustosFixos() async {
    final dbClient = await database;
    final result = await dbClient.rawQuery('''
    SELECT 
      COALESCE(SUM(aluguel), 0) +
      COALESCE(SUM(contador), 0) +
      COALESCE(SUM(telefone_internet), 0) +
      COALESCE(SUM(aplicativos), 0) +
      COALESCE(SUM(energia), 0) +
      COALESCE(SUM(agua), 0) +
      COALESCE(SUM(mat_limpeza), 0) +
      COALESCE(SUM(combustivel), 0) +
      COALESCE(SUM(funcionario), 0) +
      COALESCE(SUM(outros1), 0) +
      COALESCE(SUM(outros2), 0) +
      COALESCE(SUM(outros3), 0) AS total
    FROM custo_fixo
    ''');

    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0;
  }

  // Média do faturamento (ex: últimos 12 meses)
  Future<double> obterFaturamentoMedia() async {
    final dbClient = await database;
    final result = await dbClient.rawQuery(
      'SELECT AVG(valor) as media FROM faturamento',
    );
    return result.first['media'] != null
        ? (result.first['media'] as num).toDouble()
        : 0;
  }

  // Obter lucro desejado (em percentual)
  /*Future<double> obterLucroDesejado() async {
    final dbClient = await database;
    final result = await dbClient.rawQuery(
      'SELECT percentual FROM configuracoes WHERE chave = "lucro_desejado"',
    );
    return result.isNotEmpty
        ? (result.first['percentual'] as num).toDouble()
        : 0;
  }*/

  Future<List<Produto>> getProdutos() async {
    final dbClient = await database;
    final maps = await dbClient.query('produto');
    return maps.map((map) => Produto.fromMap(map)).toList();
  }

  /// Lista composição de um produto (retorna join com insumo para obter nome/valor)
  Future<List<Map<String, dynamic>>> listarComposicaoPorProduto(
    int produtoId,
  ) async {
    final dbClient = await database;
    return await dbClient.rawQuery(
      '''
      SELECT c.produto_id, c.insumo_id, c.quantidade,
            i.nome AS insumo_nome, i.un AS insumo_un, i.valor AS insumo_valor
      FROM composicao_produto c
      JOIN insumo i ON i.id = c.insumo_id
      WHERE c.produto_id = ?
    ''',
      [produtoId],
    );
  }

  /// Remove todas as composições vinculadas a um produto (usado antes de inserir as novas)
  Future<int> deletarComposicoesPorProduto(int produtoId) async {
    final dbClient = await database;
    return await dbClient.delete(
      'composicao_produto',
      where: 'produto_id = ?',
      whereArgs: [produtoId],
    );
  }

  Future<int> removerComposicao(int id) async {
    final db = await instance.database;
    return await db.delete(
      'composicao_produto',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> removerComposicaoPorProduto(int produtoId) async {
    final db = await database;
    return await db.delete(
      'composicao_produto', // nome da tabela de composição
      where: 'produto_id = ?',
      whereArgs: [produtoId],
    );
  }

  // Verifica se uma tabela possui registros
  Future<bool> temRegistros(String tabela) async {
    final db = await database;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $tabela',
    );
    return (resultado.first['total'] as int) > 0;
  }

  // Obtém o último valor cadastrado da tabela lucro
  Future<double> obterUltimoLucro() async {
    final dbClient = await database;
    final result = await dbClient.rawQuery(
      'SELECT percentual FROM lucro ORDER BY id DESC LIMIT 1',
    );

    return result.isNotEmpty
        ? (result.first['percentual'] as num).toDouble()
        : 0.0;
  }

  // ==================== NOVA LÓGICA DE LICENÇA ====================

  // Verifica se a licença do usuário expirou
  Future<bool> isLicencaExpirada(Map<String, dynamic>? usuario) async {
    if (usuario == null) return true;

    final dataLiberacao = DateTime.parse(usuario['data_liberacao']);
    // O PRAZO_EXPIRACAO_MINUTOS precisa ser definido ou importado
    const PRAZO_EXPIRACAO_MINUTOS = 15; // Valor placeholder
    final dataExpiracao = dataLiberacao.add(
      Duration(minutes: PRAZO_EXPIRACAO_MINUTOS),
    );

    return DateTime.now().isAfter(dataExpiracao);
  }

  // Reseta um usuário expirado: salva os dados temporariamente, limpa a tabela e cria um usuário novo
  Future<Map<String, dynamic>> resetarUsuarioExpirado(
    Map<String, dynamic> usuarioAntigo,
  ) async {
    final db = await database;
    //const PRAZO_EXPIRACAO_MINUTOS = 15; // Valor placeholder

    print("🔹🔹 Função resetarUsuarioExpirado chamada");

    // Limpa todos os usuários
    print("🔹 1. Apagando todos os usuários...");
    await db.delete('usuarios');
    await db.execute("DELETE FROM sqlite_sequence WHERE name='usuarios'");

    // Confere se realmente está vazio após o delete
    final usuariosDepoisDelete = await db.query('usuarios');
    print("✅ 2. Tabela 'usuarios' limpa -> $usuariosDepoisDelete");

    // Salva os dados antigos temporariamente
    final dadosTemp = {
      'usuario': "${usuarioAntigo['usuario']}",
      'senha':
          "${usuarioAntigo['senha']}", // ⚠️ ATENÇÃO: Senha aqui pode ser hash OU texto puro, dependendo de como foi salvo antes. O login vai falhar se for texto puro!
      'email': "${usuarioAntigo['email']}",
      'celular': "${usuarioAntigo['celular']}",
    };
    print("📋 3. Dados temporários preparados: $dadosTemp");

    // 🔑 Garante que a senha salva na variável novoUsuario ESTEJA HASHEADA,
    // usando o hash da senha antiga (se for hash) ou o hash da senha pura (se for pura).
    String senhaParaSalvar = dadosTemp['senha'] as String;
    // Se a senha salva não parecer um hash (ex: for "123456"), devemos hasheá-la.
    // É mais seguro sempre hashear aqui, se a tela de reset está garantindo que o novo usuário será hasheado.
    // Como assumimos que a tela de cadastro e reset agora usa hash, vamos hashear a string aqui,
    // mesmo que ela já seja um hash, para simplificar. O hash de um hash é diferente,
    // mas garantimos que a string salva não seja texto puro.

    // 💡 Melhor abordagem: Apenas garanta que o método de inserção fará o hash
    // (o que já corrigimos em inserirUsuario).

    // Gera novo código de liberação
    final novoCodigo = CodigoHelper.gerarCodigo();
    print("🔑 4. Novo código gerado: $novoCodigo");

    // Cria novo usuário com os dados antigos + novos campos
    final agoraUtc = DateTime.now().toUtc();

    final novoUsuario = {
      'usuario': dadosTemp['usuario'],
      'senha': dadosTemp['senha'], // A senha será hasheada em 'inserirUsuario'
      'email': dadosTemp['email'],
      'celular': dadosTemp['celular'],
      'codigo_liberacao': "$novoCodigo",
      'data_liberacao': agoraUtc.toIso8601String(),
      'data_validade': agoraUtc
          .add(const Duration(minutes: PRAZO_EXPIRACAO_MINUTOS))
          .toIso8601String(),
      'confirmado': 0,
    };
    print("📌 5. Novo usuário preparado para inserção: $novoUsuario");

    // Insere novo usuário no banco e obtém o ID gerado
    // O método 'inserirUsuario' AGORA HASHeará a senha antes de salvar!
    final id = await inserirUsuario(novoUsuario);
    novoUsuario['id'] = id;
    print("✅ 6. Novo usuário inserido com ID $id: $novoUsuario");

    // Confere conteúdo da tabela após inserção
    final usuariosDepoisInsert = await db.query('usuarios');
    print("📂 7. Usuários na tabela após inserção: $usuariosDepoisInsert");

    print("🔹🔹 Reset finalizado com sucesso!");

    return novoUsuario;
  }

  Future<void> limparUsuarios() async {
    final dbClient = await database;
    await dbClient.delete('usuarios'); // deleta todos os registros
    print("🔹 Tabela 'usuarios' limpa via limparUsuarios()");
  }

  Future<Map<String, dynamic>?> buscarUltimoUsuarioNaoConfirmado() async {
    final db = await database;
    final resultado = await db.query(
      'usuarios',
      where: 'confirmado = 0',
      orderBy: 'id DESC',
      limit: 1,
    );
    return resultado.isNotEmpty ? resultado.first : null;
  }

  // Adicione esta função dentro da classe DatabaseHelper em db/database_helper.dart

  Future<Map<String, dynamic>> resetarUsuarioParaRenovacao(
    Map<String, dynamic> usuarioAntigo,
    String novoIdentificador,
  ) async {
    final db = await instance.database;
    const PRAZO_EXPIRACAO_MINUTOS = 15; // Valor placeholder
    final agoraUtc = DateTime.now().toUtc();

    final dadosAtualizados = {
      'codigo_liberacao': CodigoHelper.gerarCodigo(),
      'identificador':
          novoIdentificador, // O mais importante: atualiza com o ID da nova transação
      'confirmado': 0, // Reseta a confirmação
      'data_liberacao': agoraUtc.toIso8601String(),
      'data_validade': agoraUtc
          .add(const Duration(minutes: PRAZO_EXPIRACAO_MINUTOS))
          .toIso8601String(),
    };

    await db.update(
      'usuarios',
      dadosAtualizados,
      where: 'id = ?',
      whereArgs: [usuarioAntigo['id']],
    );

    // Retorna um novo mapa com os dados antigos e os novos combinados
    return {...usuarioAntigo, ...dadosAtualizados};
  }

  // Salvar código de recuperação
  Future<void> salvarCodigoRecuperacao(String usuario, String codigo) async {
    final db = await instance.database;
    await db.update(
      'usuarios',
      {'codigo_recuperacao': codigo},
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }

  Future<void> atualizarSenhaHash(String usuario, String senhaHash) async {
    // 1. O parâmetro agora é 'senhaHash', pois ele JÁ VEM HASHEADO
    //    da tela 'recuperar_senha_screen.dart'.

    final db = await instance.database;

    await db.update(
      'usuarios',
      {
        'senha': senhaHash, // 3. Salva o HASH recebido DIRETAMENTE
        'codigo_recuperacao': null,
      },
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }

  // ==================== NOVA FUNÇÃO DE LOGIN COM HASH ====================

  /// 🔑 Busca o usuário pelo nome e verifica a senha (comparando o hash).
  /// Retorna o mapa do usuário se as credenciais estiverem corretas, ou null.
  Future<Map<String, dynamic>?> verificarSenhaHash(
    String usuario,
    String senhaPura,
  ) async {
    final db = await database;

    // 1. Tenta buscar o usuário pelo nome/login
    final resultado = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );

    if (resultado.isEmpty) {
      // Usuário não encontrado
      return null;
    }

    final usuarioMap = resultado.first;
    final senhaSalvaHash = usuarioMap['senha'] as String?;

    if (senhaSalvaHash == null || senhaSalvaHash.isEmpty) {
      // Senha salva está ausente (problema de dados)
      return null;
    }

    // 2. Calcule o hash da senha pura digitada pelo usuário usando o método auxiliar
    final senhaDigitadaHash = _gerarHashSeguro(senhaPura);

    // 3. Compare os hashes
    if (senhaDigitadaHash == senhaSalvaHash) {
      // Senha correta, retorna o mapa completo do usuário
      return usuarioMap;
    }

    // Senha incorreta
    return null;
  }
}

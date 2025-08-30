import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ola_mundo/models/produtos_model.dart';

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
    // ------------------- PRODUTO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL,
        senha TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        celular TEXT,
        codigo_liberacao TEXT,
        confirmado INTEGER DEFAULT 0
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
      CREATE TABLE IF NOT EXISTS faturamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        valor REAL NOT NULL
      )
    ''');

    // ------------------- LUCRO -------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lucro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
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

  //  =================== USUÁRIO ======================
  // Inserir o usuário (apenas 1 usuário)
  Future<int> inserirUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    return await db.insert('usuarios', usuario);
  }

  // Buscar o usuário (retorna o único usuário do app)
  Future<Map<String, dynamic>?> buscarUsuario() async {
    final db = await database;
    final res = await db.query('usuarios', limit: 1);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Atualizar usuário (para confirmar o cadastro ou alterar dados)
  Future<int> atualizarUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    final id = usuario['id'];
    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [id],
    );
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
    return await db.query('faturamento');
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
}

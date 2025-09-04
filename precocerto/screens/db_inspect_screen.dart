import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBInspectScreen extends StatefulWidget {
  const DBInspectScreen({Key? key}) : super(key: key);

  @override
  _DBInspectScreenState createState() => _DBInspectScreenState();
}

class _DBInspectScreenState extends State<DBInspectScreen> {
  List<String> output = [];

  @override
  void initState() {
    super.initState();
    _listarColunas('insumo'); // coloque a tabela que quer inspecionar
  }

  Future<void> _listarColunas(String tabela) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calculadora.db');
    final db = await openDatabase(path);

    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    List<String> temp = [];
    for (var coluna in colunas) {
      temp.add('Nome: ${coluna['name']}, Tipo: ${coluna['type']}');
    }

    setState(() {
      output = temp;
    });

    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inspecionar DB')),
      body: ListView.builder(
        itemCount: output.length,
        itemBuilder: (_, index) {
          return ListTile(title: Text(output[index]));
        },
      ),
    );
  }
}

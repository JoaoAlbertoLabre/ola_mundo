// lib/utils/unidades_constantes_utils.dart

/// Classe estática para armazenar e fornecer as unidades de medida padrão
/// utilizadas em todo o sistema (Insumos e Produtos).
class UnidadesConstantes {
  // Mapa principal que armazena o CÓDIGO (DB) e a DESCRIÇÃO (Exibição).
  static const Map<String, String> UNIDADES = {
    'KG': 'Quilograma',
    'G': 'Grama',
    'LT': 'Litro',
    'ML': 'Mililitro',
    'UN': 'Unidade (Peça/Saca)',
    'PCT': 'Pacote',
    'CX': 'Caixa',
  };

  /// Retorna a lista de códigos padronizados (ex: 'KG', 'UN') para usar no Dropdown.
  static List<String> get CODIGOS_UNIDADES_DB => UNIDADES.keys.toList();
}

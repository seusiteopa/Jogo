extends Resource
class_name ItemData

## Representa um item do jogo: insumo, produto ou item cosmético.
## Nunca um item de combate/magia — fora do escopo do projeto (GDD, seção 3.2).

enum Categoria { INSUMO, PRODUTO, COSMETICO }

@export var id: String = ""
@export var nome: String = ""
@export var categoria: Categoria = Categoria.INSUMO
@export var valor_base: int = 0
@export var icone: Texture2D

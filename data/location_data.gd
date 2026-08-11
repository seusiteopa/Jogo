extends Resource
class_name LocationData

## Representa um local interagível no mundo (GDD, seção 7).

enum Tipo { VENDA, FORNECEDOR, SOCIAL, BANCO, CASA }

@export var id: String = ""
@export var nome: String = ""
@export var tipo: Tipo = Tipo.VENDA
@export var posicao_no_mapa: Vector2 = Vector2.ZERO

extends CanvasLayer

## HUD permanente — Etapa 3, seção 10 (dinheiro, missão ativa, mini-mapa).
## Nesta etapa, apenas o indicador de dinheiro está funcional de ponta a ponta;
## missão ativa e mini-mapa ficam para quando a Etapa 6/7 destravar os assets visuais.

@onready var label_dinheiro: Label = $Control/LabelDinheiro

func _ready() -> void:
	EconomyManager.dinheiro_alterado.connect(_on_dinheiro_alterado)
	_on_dinheiro_alterado(EconomyManager.obter_dinheiro())

func _on_dinheiro_alterado(novo_valor: int) -> void:
	label_dinheiro.text = "$ %d" % novo_valor

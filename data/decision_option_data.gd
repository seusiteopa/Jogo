extends Resource
class_name DecisionOptionData

## Uma opção dentro de uma decisão (GDD, seção 3.5).
## Regra: resultado nunca é mostrado como preview antes da escolha.

@export var texto: String = ""
@export var efeito_dinheiro: int = 0
@export var efeito_reputacao: int = 0
## Probabilidade (0.0 a 1.0) de o efeito acima realmente ocorrer.
## 1.0 = resultado garantido. Usado para decisões de risco (GDD, seção 9).
@export_range(0.0, 1.0) var probabilidade_resultado: float = 1.0

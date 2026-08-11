extends Resource
class_name MissionData

## Uma missão (GDD, seção 8). Fase 1 é linear (ordem > 0 define sequência);
## Fase 2 é livre (ordem = 0).

enum Fase { FASE_1, FASE_2 }

@export var id: String = ""
@export var titulo: String = ""
@export var fase: Fase = Fase.FASE_1
@export var ordem: int = 0
@export var condicao_conclusao: String = ""
@export var recompensa_dinheiro: int = 0

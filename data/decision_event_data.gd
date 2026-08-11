extends Resource
class_name DecisionEventData

## Um evento de decisão completo (GDD, seção 3.5).
## Regra permanente (Etapa 2/3): "isso ensina fazendo, ou isso ensina explicando?"
## Toda decisão aqui deve ser jogável sem texto didático — `tags_de_aprendizado`
## serve só para rastreamento interno, nunca é mostrado ao jogador.

@export var id: String = ""
@export var contexto: String = ""
@export var opcoes: Array[DecisionOptionData] = []
@export var tags_de_aprendizado: Array[String] = []

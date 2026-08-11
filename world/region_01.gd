extends Node2D

## Controlador da Região 1 (mundo único da v1 — GDD seção 7).
## Interação por teclado (tecla E) é um vínculo provisório de desenvolvimento —
## o botão contextual de toque real (Etapa 3, seção 10) depende dos assets
## de UI ainda bloqueados pela aprovação pendente da Etapa 6/7.

var _local_atual: String = ""

func _ready() -> void:
	for local in $Locais.get_children():
		if local.has_signal("jogador_entrou"):
			local.jogador_entrou.connect(_on_jogador_entrou)
			local.jogador_saiu.connect(_on_jogador_saiu)

	EconomyManager.inicializar(50)  # salário inicial de teste (GDD 3.6) — valor ilustrativo
	InventoryManager.inicializar()

func _on_jogador_entrou(local_id: String) -> void:
	_local_atual = local_id
	print("[interação disponível] %s — pressione E" % local_id)

func _on_jogador_saiu(local_id: String) -> void:
	if _local_atual == local_id:
		_local_atual = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and _local_atual != "":
		_executar_interacao(_local_atual)

func _executar_interacao(local_id: String) -> void:
	match local_id:
		"ponto_venda":
			_realizar_primeira_venda()
		"casa":
			_salvar_progresso()
		_:
			pass

## Liga o mundo jogável aos sistemas de Decisão/Economia/Missão já testados na Etapa 5.
func _realizar_primeira_venda() -> void:
	if MissionManager.esta_concluida("primeira_venda"):
		print("Já realizou a primeira venda.")
		return

	var opcao := DecisionOptionData.new()
	opcao.texto = "Vender produto"
	opcao.efeito_dinheiro = 25
	opcao.efeito_reputacao = 1
	opcao.probabilidade_resultado = 1.0

	var evento := DecisionEventData.new()
	evento.id = "primeira_venda"
	evento.opcoes = [opcao]
	evento.tags_de_aprendizado = ["raciocinio_financeiro"]

	var resultado := DecisionManager.resolver_opcao(evento, 0)
	if resultado.aplicado:
		MissionManager.concluir("primeira_venda")
		print("Venda concluída! Dinheiro atual: %d" % EconomyManager.obter_dinheiro())

func _salvar_progresso() -> void:
	var character := $Character as CharacterBody2D
	var dados := {
		"dinheiro": EconomyManager.obter_dinheiro(),
		"reputacao": ProgressionManager.obter_reputacao(),
		"itens": InventoryManager.obter_itens(),
		"missoes_concluidas": MissionManager.obter_concluidas(),
		"posicao_x": character.global_position.x,
		"posicao_y": character.global_position.y,
	}
	if SaveManager.salvar(dados):
		print("Progresso salvo.")

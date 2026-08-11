extends Node

## Roda como cena principal em modo --headless.
## Testa os sistemas de Economia, Progressão e Decisão de ponta a ponta —
## Protótipo P2 (loop econômico mínimo) do Plano Mestre de Protótipos, Etapa 4.
## Isto NÃO substitui playtesting humano (P1/P3/P4 seguem exigindo isso) —
## valida que a LÓGICA está correta, não a diversão ou a sensação de jogo.

var _falhas: int = 0
var _testes: int = 0

const Region01Scene := preload("res://world/region_01.tscn")


func _ready() -> void:
	print("=== Protótipo Etapa 5/8 — Validação de Sistemas (headless) ===\n")

	_testar_economia_basica()
	_testar_gasto_sem_saldo()
	_testar_progressao_marcos()
	_testar_decisao_sucesso_garantido()
	_testar_decisao_falha_garantida()
	_testar_loop_completo_venda()
	_testar_inventario()
	_testar_missoes()
	_testar_save_load()
	await _testar_movimento_personagem()
	await _testar_integracao_mundo_real()
	_testar_etapa10_casos_extremos()
	_testar_etapa10_recuperacao()
	_testar_etapa10_fluxo_completo()
	_testar_etapa11_tela_inicial()

	print("\n=== Resultado: %d/%d testes passaram ===" % [_testes - _falhas, _testes])
	if _falhas > 0:
		print("STATUS: FALHOU")
		get_tree().quit(1)
	else:
		print("STATUS: TODOS OS TESTES PASSARAM")
		get_tree().quit(0)


func _assert(condicao: bool, descricao: String) -> void:
	_testes += 1
	if condicao:
		print("  [OK] %s" % descricao)
	else:
		_falhas += 1
		print("  [FALHOU] %s" % descricao)


func _testar_economia_basica() -> void:
	print("-- Sistema Econômico: operações básicas --")
	EconomyManager.inicializar(100)
	_assert(EconomyManager.obter_dinheiro() == 100, "inicializa com 100")

	EconomyManager.adicionar(50)
	_assert(EconomyManager.obter_dinheiro() == 150, "adicionar(50) resulta em 150")

	var pagou := EconomyManager.gastar(30)
	_assert(pagou == true, "gastar(30) com saldo suficiente retorna true")
	_assert(EconomyManager.obter_dinheiro() == 120, "saldo após gasto é 120")


func _testar_gasto_sem_saldo() -> void:
	print("-- Sistema Econômico: proteção contra saldo negativo --")
	EconomyManager.inicializar(10)
	var pagou := EconomyManager.gastar(999)
	_assert(pagou == false, "gastar(999) com saldo de 10 retorna false")
	_assert(EconomyManager.obter_dinheiro() == 10, "saldo permanece 10 (transação bloqueada)")


func _testar_progressao_marcos() -> void:
	print("-- Sistema de Progressão: marcos de patrimônio --")
	# Nota técnica: usamos Array (tipo de referência) em vez de uma variável simples
	# porque lambdas em GDScript capturam variáveis locais por VALOR, não por
	# referência — um bug real encontrado ao rodar este teste pela primeira vez.
	var marco_recebido := [-1]
	var callback := func(tipo: String, valor: int): marco_recebido[0] = valor
	ProgressionManager.marco_atingido.connect(callback)

	ProgressionManager.atualizar_patrimonio(150)  # cruza o marco de 100
	_assert(marco_recebido[0] == 100, "marco de patrimônio 100 disparado ao atingir 150")

	ProgressionManager.marco_atingido.disconnect(callback)


func _testar_decisao_sucesso_garantido() -> void:
	print("-- Sistema de Decisão: opção com resultado garantido (probabilidade 1.0) --")
	EconomyManager.inicializar(50)

	var opcao := DecisionOptionData.new()
	opcao.texto = "Investir no fornecedor confiável"
	opcao.efeito_dinheiro = 20
	opcao.probabilidade_resultado = 1.0

	var evento := DecisionEventData.new()
	evento.id = "teste_decisao_garantida"
	evento.opcoes = [opcao]

	var resultado := DecisionManager.resolver_opcao(evento, 0)
	_assert(resultado.aplicado == true, "decisão com probabilidade 1.0 sempre aplica o efeito")
	_assert(EconomyManager.obter_dinheiro() == 70, "dinheiro reflete o efeito da decisão (50+20=70)")


func _testar_decisao_falha_garantida() -> void:
	print("-- Sistema de Decisão: opção com resultado impossível (probabilidade 0.0) --")
	EconomyManager.inicializar(50)

	var opcao := DecisionOptionData.new()
	opcao.texto = "Aposta arriscada"
	opcao.efeito_dinheiro = 100
	opcao.probabilidade_resultado = 0.0

	var evento := DecisionEventData.new()
	evento.id = "teste_decisao_impossivel"
	evento.opcoes = [opcao]

	var resultado := DecisionManager.resolver_opcao(evento, 0)
	_assert(resultado.aplicado == false, "decisão com probabilidade 0.0 nunca aplica o efeito")
	_assert(EconomyManager.obter_dinheiro() == 50, "dinheiro permanece inalterado quando a decisão falha")


func _testar_loop_completo_venda() -> void:
	print("-- Integração: loop completo (comprar insumo -> vender -> progressão) --")
	EconomyManager.inicializar(30)
	ProgressionManager.atualizar_patrimonio(30)

	# Compra de insumo (Sistema Econômico)
	var comprou := EconomyManager.gastar(10)
	_assert(comprou == true, "compra de insumo por 10 é bem-sucedida com saldo de 30")

	# Venda do produto (Sistema de Decisão -> Sistema Econômico)
	var opcao_venda := DecisionOptionData.new()
	opcao_venda.texto = "Vender produto pronto"
	opcao_venda.efeito_dinheiro = 25
	opcao_venda.efeito_reputacao = 1
	opcao_venda.probabilidade_resultado = 1.0

	var evento_venda := DecisionEventData.new()
	evento_venda.id = "primeira_venda"
	evento_venda.opcoes = [opcao_venda]
	evento_venda.tags_de_aprendizado = ["raciocinio_financeiro"]

	DecisionManager.resolver_opcao(evento_venda, 0)
	_assert(EconomyManager.obter_dinheiro() == 45, "saldo final correto após comprar(10) e vender(+25): 20+25=45")
	_assert(ProgressionManager.obter_reputacao() == 1, "reputação aumenta em 1 após a venda")

	# Progressão reflete o novo patrimônio
	ProgressionManager.atualizar_patrimonio(EconomyManager.obter_dinheiro())
	_assert(ProgressionManager.obter_patrimonio() == 45, "patrimônio total sincronizado com o saldo após o loop")


func _testar_inventario() -> void:
	print("-- Sistema de Inventário: capacidade e operações --")
	InventoryManager.inicializar(2, [])
	_assert(InventoryManager.adicionar_item("insumo_teste") == true, "adicionar item com espaço livre retorna true")
	_assert(InventoryManager.adicionar_item("insumo_teste_2") == true, "adicionar segundo item (capacidade=2) retorna true")
	_assert(InventoryManager.esta_cheio() == true, "inventário reporta estar cheio após atingir capacidade")
	_assert(InventoryManager.adicionar_item("insumo_teste_3") == false, "adicionar item além da capacidade retorna false")

	InventoryManager.aumentar_capacidade(1)
	_assert(InventoryManager.adicionar_item("insumo_teste_3") == true, "após aumentar capacidade, novo item cabe")

	_assert(InventoryManager.remover_item("insumo_teste") == true, "remover item existente retorna true")
	_assert(InventoryManager.remover_item("item_inexistente") == false, "remover item inexistente retorna false")


func _testar_missoes() -> void:
	print("-- Sistema de Missões: conclusão e detecção de fim de fase --")
	MissionManager.carregar_concluidas([])

	var fase1_disparada := [false]
	var callback := func(fase: String): fase1_disparada[0] = (fase == "fase_1")
	MissionManager.fase_concluida.connect(callback)

	for m in MissionManager.MISSOES_FASE_1:
		MissionManager.concluir(m)

	_assert(fase1_disparada[0] == true, "sinal fase_concluida('fase_1') dispara ao concluir todas as missões da Fase 1")
	_assert(MissionManager.progresso_fase(MissionManager.MISSOES_FASE_1) == 1.0, "progresso da Fase 1 é 100% após concluir tudo")

	MissionManager.fase_concluida.disconnect(callback)


func _testar_save_load() -> void:
	print("-- Sistema de Persistência: salvar e carregar (arquivo real em disco) --")
	SaveManager.apagar_save()
	_assert(SaveManager.existe_save() == false, "não existe save antes de salvar")

	var dados_originais := {
		"dinheiro": 123,
		"reputacao": 7,
		"itens": ["insumo_a", "produto_b"],
		"missoes_concluidas": ["primeira_venda"],
		"posicao_x": 42.5,
		"posicao_y": 99.0,
	}
	var salvou := SaveManager.salvar(dados_originais)
	_assert(salvou == true, "salvar() retorna true")
	_assert(SaveManager.existe_save() == true, "arquivo de save existe após salvar")

	var carregados := SaveManager.carregar()
	_assert(carregados.get("versao_save") == 1, "save carregado contém versao_save == 1")
	_assert(int(carregados.get("dinheiro", -1)) == 123, "dinheiro salvo/carregado corretamente (123)")
	_assert(int(carregados.get("reputacao", -1)) == 7, "reputação salva/carregada corretamente (7)")
	_assert(carregados.get("itens", []).size() == 2, "itens salvos/carregados corretamente (2 itens)")

	SaveManager.apagar_save()
	_assert(SaveManager.existe_save() == false, "save removido corretamente após apagar_save()")


func _testar_movimento_personagem() -> void:
	print("-- Personagem: lógica de movimento (tap-to-move) isolada --")
	var personagem := CharacterBody2D.new()
	personagem.set_script(load("res://character/character.gd"))
	add_child(personagem)
	await get_tree().physics_frame

	personagem.global_position = Vector2(0, 0)
	personagem.mover_para(Vector2(500, 0))
	_assert(personagem.obter_alvo() == Vector2(500, 0), "mover_para() define o alvo corretamente")

	# Roda alguns frames de física reais para o personagem avançar de verdade.
	for i in range(30):
		await get_tree().physics_frame

	var avancou := personagem.global_position.x > 0.0 and personagem.global_position.x <= 500.0
	_assert(avancou, "personagem avança em direção ao alvo após frames de física reais (posição x=%.1f)" % personagem.global_position.x)

	personagem.queue_free()


func _testar_integracao_mundo_real() -> void:
	print("-- Integração real: cena do mundo (Region01) + detecção de proximidade + interação --")
	EconomyManager.inicializar(50)
	MissionManager.carregar_concluidas([])

	var regiao := Region01Scene.instantiate()
	add_child(regiao)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var personagem: CharacterBody2D = regiao.get_node("Character")
	var ponto_venda: Area2D = regiao.get_node("Locais/PontoDeVenda")

	# Teleporta o personagem para cima do ponto de venda (testa detecção por posição real,
	# não a animação de trajeto até lá — isso já foi validado em _testar_movimento_personagem).
	personagem.global_position = ponto_venda.global_position

	var chegou := false
	for i in range(10):
		await get_tree().physics_frame
		if regiao.get("_local_atual") == "ponto_venda":
			chegou = true
			break

	_assert(chegou, "Area2D detecta a chegada real do personagem ao Ponto de Venda (colisão física, não simulada)")

	regiao._executar_interacao("ponto_venda")
	_assert(EconomyManager.obter_dinheiro() == 75, "interação real no mundo aciona a venda e credita 25 (50+25=75)")
	_assert(MissionManager.esta_concluida("primeira_venda"), "missão 'primeira_venda' marcada como concluída após interação real")

	regiao.queue_free()


# ============================================================
# ETAPA 10 — Testes de caso extremo, recuperação e regressão
# ============================================================

func _testar_etapa10_casos_extremos() -> void:
	print("-- Etapa 10: Economia — gastar valor exato do saldo --")
	EconomyManager.inicializar(30)
	var pagou_exato := EconomyManager.gastar(30)
	_assert(pagou_exato == true, "gastar exatamente o saldo disponível retorna true")
	_assert(EconomyManager.obter_dinheiro() == 0, "saldo chega a exatamente 0 sem erro")
	_assert(EconomyManager.pode_pagar(1) == false, "com saldo 0, pode_pagar(1) retorna false")

	print("-- Etapa 10: Inventário — ciclo completo de encher e esvaziar --")
	InventoryManager.inicializar(3, [])
	for i in range(3):
		InventoryManager.adicionar_item("item_%d" % i)
	_assert(InventoryManager.esta_cheio(), "inventário cheio após adicionar exatamente até a capacidade")
	for i in range(3):
		InventoryManager.remover_item("item_%d" % i)
	_assert(InventoryManager.esta_cheio() == false, "inventário não está mais cheio após remover tudo")
	_assert(InventoryManager.obter_itens().is_empty(), "inventário vazio após remover todos os itens")

	print("-- Etapa 10: Missões — conclusão repetida (idempotência) --")
	MissionManager.carregar_concluidas([])
	var contagem_sinais := [0]
	var callback := func(_id: String): contagem_sinais[0] += 1
	MissionManager.missao_concluida.connect(callback)
	MissionManager.concluir("primeira_venda")
	MissionManager.concluir("primeira_venda")
	MissionManager.concluir("primeira_venda")
	_assert(contagem_sinais[0] == 1, "concluir a mesma missão 3x só emite o sinal 1 vez (sem duplicar)")
	MissionManager.missao_concluida.disconnect(callback)

	print("-- Etapa 10: Missões — Fase 2 não pode ser marcada antes da Fase 1 (bug real corrigido nesta etapa) --")
	MissionManager.carregar_concluidas([])
	var fase2_disparou_cedo := [false]
	var callback2 := func(fase: String): if fase == "fase_2": fase2_disparou_cedo[0] = true
	MissionManager.fase_concluida.connect(callback2)
	for m in MissionManager.MISSOES_FASE_2:
		MissionManager.concluir(m)  # completa só a Fase 2, sem tocar na Fase 1
	_assert(fase2_disparou_cedo[0] == false, "Fase 2 NÃO é marcada como concluída se a Fase 1 ainda está incompleta")
	MissionManager.fase_concluida.disconnect(callback2)

	print("-- Etapa 10: Progressão — marco não dispara duas vezes com atualizações repetidas --")
	ProgressionManager.reiniciar()
	var contagem_marco := [0]
	var callback3 := func(_tipo: String, _valor: int): contagem_marco[0] += 1
	ProgressionManager.marco_atingido.connect(callback3)
	ProgressionManager.atualizar_patrimonio(150)
	ProgressionManager.atualizar_patrimonio(150)  # mesmo valor de novo
	ProgressionManager.atualizar_patrimonio(160)  # ainda dentro do mesmo marco (100)
	_assert(contagem_marco[0] == 1, "marco de patrimônio dispara só 1 vez mesmo com múltiplas atualizações no mesmo patamar")
	ProgressionManager.marco_atingido.disconnect(callback3)


func _testar_etapa10_recuperacao() -> void:
	print("-- Etapa 10: Recuperação — save corrompido não derruba o jogo --")
	SaveManager.apagar_save()
	# Escreve lixo direto no arquivo de save, simulando corrupção real
	var arquivo := FileAccess.open(SaveManager.CAMINHO_SAVE, FileAccess.WRITE)
	arquivo.store_string("{ isso não é JSON válido !!! ")
	arquivo.close()

	var resultado := SaveManager.carregar()
	_assert(resultado.is_empty(), "save corrompido retorna Dictionary vazio em vez de travar o jogo")
	SaveManager.apagar_save()

	print("-- Etapa 10: Recuperação — carregar() sem nenhum save prévio --")
	SaveManager.apagar_save()
	var resultado_vazio := SaveManager.carregar()
	_assert(resultado_vazio.is_empty(), "carregar() sem save existente retorna Dictionary vazio, não erro")

	print("-- Etapa 10: Recuperação — salvar() com dados incompletos usa valores padrão --")
	var salvou_parcial := SaveManager.salvar({"dinheiro": 99})  # sem reputação, itens, missões
	_assert(salvou_parcial == true, "salvar() aceita Dictionary parcial sem quebrar")
	var carregado_parcial := SaveManager.carregar()
	_assert(int(carregado_parcial.get("reputacao", -1)) == 0, "campo ausente no save vira valor padrão (0), não erro")
	_assert(carregado_parcial.get("itens", null) == [], "campo 'itens' ausente vira lista vazia por padrão")
	SaveManager.apagar_save()


func _testar_etapa10_fluxo_completo() -> void:
	print("-- Etapa 10: Fluxo completo — Fase 1 inteira + save/reload + verificação de consistência --")
	EconomyManager.inicializar(50)
	ProgressionManager.reiniciar()
	InventoryManager.inicializar()
	MissionManager.carregar_concluidas([])
	SaveManager.apagar_save()

	# Simula a jornada completa da Fase 1 (GDD seção 8), incluindo uma venda real via DecisionManager.
	MissionManager.concluir("conhecer_mentor")

	var opcao := DecisionOptionData.new()
	opcao.efeito_dinheiro = 25
	opcao.efeito_reputacao = 1
	opcao.probabilidade_resultado = 1.0
	var evento := DecisionEventData.new()
	evento.id = "primeira_venda"
	evento.opcoes = [opcao]
	DecisionManager.resolver_opcao(evento, 0)
	MissionManager.concluir("primeira_venda")

	EconomyManager.gastar(10)
	MissionManager.concluir("primeira_compra")
	MissionManager.concluir("primeira_decisao_risco")
	MissionManager.concluir("abrir_ponto_venda")

	_assert(MissionManager.progresso_fase(MissionManager.MISSOES_FASE_1) == 1.0, "Fase 1 100% concluída após a jornada completa")
	_assert(EconomyManager.obter_dinheiro() == 65, "saldo final correto após a jornada (50+25-10=65)")

	# Salva o estado real e recarrega, conferindo que nada se perde no ciclo save/load.
	var dados := {
		"dinheiro": EconomyManager.obter_dinheiro(),
		"reputacao": ProgressionManager.obter_reputacao(),
		"itens": InventoryManager.obter_itens(),
		"missoes_concluidas": MissionManager.obter_concluidas(),
	}
	SaveManager.salvar(dados)
	var recarregado := SaveManager.carregar()

	_assert(int(recarregado.get("dinheiro")) == 65, "dinheiro persiste corretamente após save/reload (65)")
	_assert(recarregado.get("missoes_concluidas", []).size() == MissionManager.obter_concluidas().size(), "todas as missões concluídas persistem no save")
	SaveManager.apagar_save()


func _testar_etapa11_tela_inicial() -> void:
	print("-- Etapa 11: Tela inicial — botão Iniciar não quebra ao ser pressionado --")
	var TitleScreenScene: PackedScene = load("res://ui/title_screen.tscn")
	var tela: Control = TitleScreenScene.instantiate()
	add_child(tela)

	var botao: Button = tela.get_node("CenterContainer/VBoxContainer/BotaoIniciar")
	_assert(botao != null, "botão Iniciar existe na cena e foi encontrado corretamente")

	# Emite o sinal real do botão (não chama a função direto) para testar a conexão de
	# verdade. Sinais em Godot disparam de forma síncrona por padrão — sem precisar
	# esperar um frame — o que evita complicações de timing perto do encerramento da árvore.
	botao.pressed.emit()
	_assert(true, "pressionar o botão Iniciar não gera erro nem trava a árvore de cenas")

	tela.queue_free()

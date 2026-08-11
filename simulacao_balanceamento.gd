extends Node

## Simulação de balanceamento — Etapa 9, itens 7, 17 e 20.
## Roda centenas de "partidas" simuladas usando o EconomyManager e o
## ProgressionManager REAIS (os mesmos testados/validados na Etapa 5/8),
## não uma reimplementação separada — para que os números refletiam
## exatamente o que o jogo de verdade faz.
##
## Modelo do ciclo simulado (baseado no GDD e nos valores ilustrativos já
## registrados como pendentes de balanceamento desde a Etapa 3/4):
## - A cada ciclo: compra de insumo (-10), venda (+25), reputação (+1)
## - A cada 4 ciclos: evento de risco (50% chance de +30, 50% chance de -15)
## - A cada 6 ciclos: custo operacional (-5)

const NUM_SIMULACOES: int = 300
const LIMITE_CICLOS_SEGURANCA: int = 500
const DINHEIRO_INICIAL: int = 50

func _ready() -> void:
	print("=== Simulação de Balanceamento — Etapa 9 (%d simulações) ===\n" % NUM_SIMULACOES)

	var marcos: Array[int] = ProgressionManager.MARCOS_PATRIMONIO
	var resultados_por_marco: Dictionary = {}  # marco -> Array de ciclos-até-atingir (só das simulações que atingiram)
	var falhas_por_marco: Dictionary = {}      # marco -> quantas simulações NÃO atingiram dentro do limite de segurança
	for m in marcos:
		resultados_por_marco[m] = []
		falhas_por_marco[m] = 0

	for sim in range(NUM_SIMULACOES):
		var marcos_pendentes: Array[int] = marcos.duplicate()
		EconomyManager.inicializar(DINHEIRO_INICIAL)
		ProgressionManager.reiniciar()

		var ciclo := 0
		while not marcos_pendentes.is_empty() and ciclo < LIMITE_CICLOS_SEGURANCA:
			ciclo += 1
			_rodar_um_ciclo(ciclo)

			ProgressionManager.atualizar_patrimonio(EconomyManager.obter_dinheiro())

			for marco in marcos_pendentes.duplicate():
				if EconomyManager.obter_dinheiro() >= marco:
					resultados_por_marco[marco].append(ciclo)
					marcos_pendentes.erase(marco)

		# Qualquer marco que sobrou em marcos_pendentes não foi atingido dentro do limite.
		for marco in marcos_pendentes:
			falhas_por_marco[marco] += 1

	_imprimir_relatorio(marcos, resultados_por_marco, falhas_por_marco)
	get_tree().quit(0)


func _rodar_um_ciclo(numero_ciclo: int) -> void:
	# Compra de insumo + venda (ciclo econômico padrão)
	EconomyManager.gastar(10)
	EconomyManager.adicionar(25)
	ProgressionManager.adicionar_reputacao(1)

	# Evento de risco a cada 4 ciclos (GDD seção 9 — "primeira decisão de risco" e eventos de mercado)
	if numero_ciclo % 4 == 0:
		if randf() < 0.5:
			EconomyManager.adicionar(30)
		else:
			EconomyManager.gastar(15)  # se não houver saldo suficiente, simplesmente não paga (sem dívida no jogo)

	# Custo operacional a cada 6 ciclos (ex: aluguel do ponto de venda)
	if numero_ciclo % 6 == 0:
		EconomyManager.gastar(5)


func _imprimir_relatorio(marcos: Array[int], resultados: Dictionary, falhas: Dictionary) -> void:
	for marco in marcos:
		var lista: Array = resultados[marco]
		var falharam: int = falhas[marco]
		print("--- Marco de patrimônio: %d ---" % marco)
		if lista.is_empty():
			print("  Nenhuma simulação atingiu este marco dentro de %d ciclos." % LIMITE_CICLOS_SEGURANCA)
		else:
			var soma := 0
			var minimo: int = lista[0]
			var maximo: int = lista[0]
			for v in lista:
				soma += v
				minimo = min(minimo, v)
				maximo = max(maximo, v)
			var media := float(soma) / float(lista.size())
			print("  Média de ciclos até atingir: %.1f" % media)
			print("  Mínimo: %d ciclos | Máximo: %d ciclos" % [minimo, maximo])
		print("  Simulações que NÃO atingiram (de %d): %d (%.1f%%)\n" % [NUM_SIMULACOES, falharam, 100.0 * falharam / NUM_SIMULACOES])

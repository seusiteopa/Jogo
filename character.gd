extends CharacterBody2D

## Personagem jogável — GDD seção 3.1 (tap-to-move) e Arquitetura Técnica (Etapa 4, módulo 2).
## Movimento é lógica pura e testável, separada da captura de input,
## para permitir teste automatizado sem precisar simular toque real.

const VELOCIDADE_PADRAO: float = 220.0  # px/s — valor ilustrativo, sujeito a balanceamento

@export var velocidade: float = VELOCIDADE_PADRAO

var _alvo: Vector2

func _ready() -> void:
	_alvo = global_position

## Define o destino do movimento (chamado pelo input de toque, ou diretamente em testes).
func mover_para(destino: Vector2) -> void:
	_alvo = destino

func obter_alvo() -> Vector2:
	return _alvo

func _physics_process(delta: float) -> void:
	_avancar_em_direcao_ao_alvo(delta)

## Lógica de movimento isolada em função própria — testável chamando-a
## diretamente, sem precisar rodar o loop de física completo do motor.
func _avancar_em_direcao_ao_alvo(delta: float) -> void:
	if global_position.distance_to(_alvo) <= 2.0:
		global_position = _alvo
		velocity = Vector2.ZERO
		return

	var direcao := global_position.direction_to(_alvo)
	velocity = direcao * velocidade
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		mover_para(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Suporte a mouse para testes no editor/desktop durante o desenvolvimento.
		mover_para(get_global_mouse_position())

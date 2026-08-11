extends Area2D

## Ponto de interação no mundo (Casa, Ponto de venda, Mercado, etc.) — GDD seção 3.1/3.9.
## Detecta o personagem por proximidade física real (Area2D + CollisionShape2D),
## conforme decidido na Arquitetura Técnica (Etapa 4, módulo 2).

signal jogador_entrou(local_id: String)
signal jogador_saiu(local_id: String)

@export var local_id: String = ""
@export var nome_exibicao: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		jogador_entrou.emit(local_id)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		jogador_saiu.emit(local_id)

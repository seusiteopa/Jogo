extends Control

## Tela inicial — Etapa 11, item 18 (preparação da apresentação).
## Usa apenas placeholders neutros: nenhuma cor da paleta proposta na Etapa 6
## foi usada aqui, porque a Direção de Arte segue sem aprovação. Quando for
## aprovada, só este visual muda — a navegação (botão -> mundo) já está pronta.

@onready var botao_iniciar: Button = $CenterContainer/VBoxContainer/BotaoIniciar

func _ready() -> void:
	botao_iniciar.pressed.connect(_on_botao_iniciar_pressed)

func _on_botao_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://world/region_01.tscn")

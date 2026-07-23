extends Control

func _process(_delta):
	# Se pressionar Espaço (ou a tecla de Pulo/Aceitar)
	if Input.is_action_just_pressed("ui_accept"):
		# Muda para a cena do seu jogo principal
		get_tree().change_scene_to_file("res://mundo.tscn")

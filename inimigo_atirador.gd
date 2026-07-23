extends Area2D

var vida = 3
var cena_projetil = preload("res://projetil_inimigo.tscn")

func _ready():
	area_entered.connect(_on_area_entered)
	iniciar_loop_tiro()

func iniciar_loop_tiro():
	while is_instance_valid(self):
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(self):
			atirar()

func atirar():
	# Procura o jogador na cena pelo grupo "jogador" ou pelo nome
	var jogador = get_tree().get_first_node_in_group("jogador")
	
	# Caso o jogador não esteja em um grupo, busca pelo nome do nó
	if jogador == null:
		jogador = get_parent().get_node_or_null("Jogador")

	if cena_projetil and jogador != null:
		var novo_projetil = cena_projetil.instantiate()
		novo_projetil.global_position = global_position
		
		# Calcula a direção apontando para o jogador
		var direcao_para_jogador = (jogador.global_position - global_position).normalized()
		novo_projetil.direcao = direcao_para_jogador
		
		get_parent().add_child(novo_projetil)
		print("🎯 Inimigo mirou e atirou no jogador!")

func _on_area_entered(area):
	if area.name == "AtaqueArea":
		tomar_dano(1)

func tomar_dano(quantidade):
	vida -= quantidade
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if vida <= 0:
		queue_free()

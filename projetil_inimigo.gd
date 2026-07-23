extends Area2D

const VELOCIDADE = 250.0
var direcao = Vector2.ZERO # Será definida pelo inimigo atirador

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Autodestrói após 4 segundos se não acertar nada
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta):
	# Move o projétil na direção do jogador
	position += direcao * VELOCIDADE * delta

func _on_area_entered(area):
	if area != null and area.name == "DanoRecebidoArea":
		var jogador = area.get_parent()
		if jogador != null and jogador.has_method("tomar_dano"):
			if "invencivel" in jogador and not jogador.invencivel:
				jogador.tomar_dano(15)
		queue_free()

func _on_body_entered(body):
	if body != null and not body.is_in_group("inimigos"):
		queue_free()

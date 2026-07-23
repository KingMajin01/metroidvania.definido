extends Area2D

# Vida do inimigo
var vida = 3

func _ready():
	# Conecta o sinal para detectar quando algo (como a espada) entra nele
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	# Verifica se a área que encostou nele é a área de ataque do jogador
	if area.name == "AtaqueArea":
		tomar_dano(1)

func tomar_dano(quantidade):
	vida -= quantidade
	print("💥 Inimigo tomou dano! Vida restante:", vida)
	
	# Efeito visual rápido: pisca em vermelho/branco
	modulate = Color(1, 0, 0) # Fica vermelho
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1) # Volta ao normal

	# Se a vida acabar, o inimigo morre
	if vida <= 0:
		print("💀 Inimigo derrotado!")
		queue_free() # Destrói o inimigo

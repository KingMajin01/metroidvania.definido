extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# --- Configurações do Dash ---
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2
var pode_dar_dash = true
var esta_dando_dash = false
var direcao_dash = 1.0 # 1 para direita, -1 para esquerda

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Sistema de Vida ---
var vida_maxima = 100
var vida_atual = 100
var invencivel = false

# --- Sistema de Mana ---
var mana_maxima = 100
var mana_atual = 100
var custo_magia = 30
var regeneracao_mana = 10.0 # Quanto recupera por segundo

# --- Sistema de Defesa e Parry ---
var esta_defendendo: bool = false
var tempo_parry: bool = false
const JANELA_PARRY = 0.2 # 0.2 segundos para dar o parry perfeito

# --- Nós (Nodes) ---
@onready var ataque_colisao = $AtaqueArea/CollisionShape2D
@onready var barra_vida = $CanvasLayer/BarraVida
@onready var barra_mana = $CanvasLayer/BarraMana  # Certifique-se de ter essa ProgressBar no CanvasLayer!
@onready var area_dano = $DanoRecebidoArea

# Precarrega o feitiço
var cena_magia = preload("res://magia_jogador.tscn")

var atacando = false

func _ready():
	# Inicializa as barras
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
	
	if barra_mana:
		barra_mana.max_value = mana_maxima
		barra_mana.value = mana_atual
		
	if area_dano:
		area_dano.area_entered.connect(_on_dano_recebido_area_entered)

func _process(delta):
	# --- Regeneração de Mana ---
	if mana_atual < mana_maxima:
		mana_atual += regeneracao_mana * delta
		mana_atual = clamp(mana_atual, 0, mana_maxima)
		if barra_mana:
			barra_mana.value = mana_atual

	# --- Controles de Magia, Ataque e Defesa ---
	# Magia (Tecla K)
	if Input.is_key_pressed(KEY_K) and not atacando and not esta_defendendo:
		usar_magia()

	# Ataque Melee (Tecla Z)
	if Input.is_key_pressed(KEY_Z) and not atacando and not esta_defendendo:
		realizar_ataque()

	# Defesa e Parry (Tecla X)
	if Input.is_key_pressed(KEY_X):
		if not esta_defendendo:
			iniciar_defesa()
	else:
		if esta_defendendo:
			parar_defesa()

func _physics_process(delta):
	# Se estiver executando o Dash, ignora a gravidade e o movimento comum
	if esta_dando_dash:
		velocity.x = direcao_dash * DASH_SPEED
		velocity.y = 0
		move_and_slide()
		return

	# Gravidade normal
	if not is_on_floor():
		velocity.y += gravity * delta

	# Pulo (bloqueado enquanto ataca ou defende)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not atacando and not esta_defendendo:
		velocity.y = JUMP_VELOCITY

	# Movimento lateral
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0 and not atacando and not esta_defendendo:
		velocity.x = direction * SPEED
		direcao_dash = direction # Salva a direção (-1 para esquerda, 1 para direita)
		
		# Vira a área do ataque e o Sprite para o lado correto
		if direction > 0:
			$AtaqueArea.scale.x = 1
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = false
		elif direction < 0:
			$AtaqueArea.scale.x = -1
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Ativar o Dash (Funciona tanto no CHÃO quanto no AR!)
	if Input.is_key_pressed(KEY_SHIFT) and pode_dar_dash and not atacando and not esta_defendendo:
		realizar_dash()

	move_and_slide()

# --- Lógica do Dash ---
func realizar_dash():
	esta_dando_dash = true
	pode_dar_dash = false
	invencivel = true # Fica imune durante o dash!
	
	modulate.a = 0.5 # Fica meio transparente
	print("💨 DASH (Chão/Ar)!")

	await get_tree().create_timer(DASH_DURATION).timeout
	
	esta_dando_dash = false
	invencivel = false
	modulate.a = 1.0 # Volta ao normal
	
	# Cooldown de 0.8s
	await get_tree().create_timer(0.8).timeout
	pode_dar_dash = true

# --- Lógica do Ataque ---
func realizar_ataque():
	atacando = true
	if ataque_colisao:
		ataque_colisao.disabled = false
	print("⚔️ ATAQUE!")
	await get_tree().create_timer(0.2).timeout
	if ataque_colisao:
		ataque_colisao.disabled = true
	atacando = false

# --- Lógica de Magia (Corrigido o lado!) ---
func usar_magia():
	if mana_atual >= custo_magia:
		mana_atual -= custo_magia
		if barra_mana:
			barra_mana.value = mana_atual
		
		if cena_magia:
			var magia = cena_magia.instantiate()
			
			# Usa a direcao_dash (1.0 para direita, -1.0 para esquerda)
			var direcao_vetor = Vector2(direcao_dash, 0)
			
			# Empurra a magia 30 pixels para frente na direção em que o jogador está olhando
			magia.global_position = global_position + (direcao_vetor * 30)
			magia.direcao = direcao_vetor
			
			get_parent().add_child(magia)
			print("✨ Magia disparada para o lado:", direcao_dash)
	else:
		print("❌ Mana insuficiente!")

# --- Lógica de Defesa e Parry ---
func iniciar_defesa():
	esta_defendendo = true
	tempo_parry = true
	modulate = Color(0.5, 0.8, 1.0, 1.0) # Fica azulado indicando postura de defesa
	print("🛡️ Entrou em Defesa / Janela de Parry aberta!")
	
	# Cronômetro da janela de Parry (0.2s)
	await get_tree().create_timer(JANELA_PARRY).timeout
	tempo_parry = false
	print("⏳ Janela de Parry acabou (continua defendendo normal).")

func parar_defesa():
	esta_defendendo = false
	tempo_parry = false
	modulate = Color(1.0, 1.0, 1.0, 1.0) # Cor original
	print("🛡️ Saiu da Defesa.")

# --- Dano e Colisão ---
func _on_dano_recebido_area_entered(area):
	if area.name == "Inimigo" and not invencivel:
		tomar_dano(20)

func tomar_dano(quantidade):
	# 1. PARRY PERFEITO (0 Dano)
	if tempo_parry:
		print("⚡ PARRY PERFEITO! Nenhum dano sofrido!")
		# Efeito visual de brilho rápido
		modulate = Color(2.0, 2.0, 0.0, 1.0) # Brilho amarelo
		await get_tree().create_timer(0.15).timeout
		if esta_defendendo:
			modulate = Color(0.5, 0.8, 1.0, 1.0)
		return

	# 2. DEFESA NORMAL (25% do Dano = Redução de 75%)
	if esta_defendendo:
		quantidade = int(quantidade * 0.25)
		print("🛡️ Ataque bloqueado! Tomou apenas 25% do dano:", quantidade)

	# 3. DANO NORMAL
	vida_atual -= quantidade
	if vida_atual < 0:
		vida_atual = 0
		
	if barra_vida:
		barra_vida.value = vida_atual
	print("💔 Vida restante:", vida_atual)

	if vida_atual <= 0:
		print("💀 GAME OVER!")
		get_tree().reload_current_scene()
		return

	# Efeito de dano (ficando vermelho temporariamente)
	invencivel = true
	modulate = Color(1, 0, 0, 0.6)
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 1)
	invencivel = false

extends Control
class_name RuedaLetras

signal palabra_enviada(palabra: String)

@export var radio_rueda: float = 120.0
@onready var linea_trazo: Line2D = $Line2D

var letras_actuales: Array[String] = []
var botones_letras: Array[Button] = []
var letras_seleccionadas: Array[Button] = []

var arrastrando: bool = false
var posicion_dedo_actual: Vector2 = Vector2.ZERO

func _ready():
	if linea_trazo:
		linea_trazo.width = 12.0
		linea_trazo.default_color = Color("ffcc00")
		
	configurar_rueda("ARMADURA")

func configurar_rueda(palabra_semilla: String):
	# Limpiar botones anteriores
	for b in botones_letras:
		b.queue_free()
	botones_letras.clear()
	letras_seleccionadas.clear()
	
	var caracteres = []
	for i in range(palabra_semilla.length()):
		caracteres.append(palabra_semilla[i].to_upper())
	caracteres.shuffle()
	
	var total_letras = caracteres.size()
	if total_letras == 0: return
	
	var paso_angulo = (2 * PI) / total_letras
	
	# =========================================================================
	# CENTRADO CORRECTO RELATIVO AL NODO PARE
	# =========================================================================
	# Si el nodo Rueda en el editor está estirado a Full Rect (0,0,540,960):
	# Usamos size del contenedor. Si Rueda es un nodo pequeño posicionado abajo,
	# 'size / 2.0' ubicará las letras centradas exactamente dentro del nodo Rueda.
	var centro_rueda: Vector2
	
	if size.y > 500: 
		# Caso A: El nodo Rueda ocupa toda la pantalla -> Ponemos la rueda al 75% de su alto
		centro_rueda = Vector2(size.x / 2.0, size.y * 0.75)
	else:
		# Caso B: El nodo Rueda es una caja pequeña ubicada en la parte inferior del nivel
		centro_rueda = size / 2.0

	for i in range(total_letras):
		var angulo = i * paso_angulo - (PI / 2)
		var offset_x = cos(angulo) * radio_rueda
		var offset_y = sin(angulo) * radio_rueda
		
		var pos_relativa = Vector2(offset_x, offset_y)
		var pos_final = centro_rueda + pos_relativa
		
		# 1. Crear instancia en RAM
		var boton = Button.new()
		boton.text = caracteres[i]
		boton.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		boton.custom_minimum_size = Vector2(50, 50)
		
		# 2. Configurar posición local respecto al padre
		boton.position = pos_final - (boton.custom_minimum_size / 2.0)
		
		# Guardar metadatos para trazado de líneas
		boton.set_meta("letra", caracteres[i])
		boton.set_meta("centro", pos_final)
		
		# 3. Agregar al árbol de escenas (Godot lo pintará en el siguiente frame)
		add_child(boton)
		botones_letras.append(boton)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_iniciar_trazo(event.position)
		else:
			_finalizar_trazo()
			
	elif event is InputEventScreenTouch:
		if event.pressed:
			_iniciar_trazo(event.position)
		else:
			_finalizar_trazo()
			
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and arrastrando:
		posicion_dedo_actual = event.position
		_chequear_colision_con_letras(event.position)
		_actualizar_linea_trazo()

func _iniciar_trazo(pos_inicial: Vector2):
	arrastrando = true
	letras_seleccionadas.clear()
	posicion_dedo_actual = pos_inicial
	_chequear_colision_con_letras(pos_inicial)
	_actualizar_linea_trazo()

func _finalizar_trazo():
	if not arrastrando: return
	arrastrando = false
	
	var palabra_resultado = ""
	for btn in letras_seleccionadas:
		palabra_resultado += str(btn.get_meta("letra"))
		
	if palabra_resultado.length() > 0:
		print("Palabra trazada: ", palabra_resultado)
		emit_signal("palabra_enviada", palabra_resultado)
		
	letras_seleccionadas.clear()
	if linea_trazo:
		linea_trazo.clear_points()

func _chequear_colision_con_letras(pos_dedo: Vector2):
	var radio_deteccion = 35.0 
	
	for btn in botones_letras:
		var centro_btn = btn.get_meta("centro") as Vector2
		if pos_dedo.distance_to(centro_btn) <= radio_deteccion:
			if not btn in letras_seleccionadas:
				letras_seleccionadas.append(btn)
			elif letras_seleccionadas.size() >= 2 and btn == letras_seleccionadas[letras_seleccionadas.size() - 2]:
				letras_seleccionadas.pop_back()

func _actualizar_linea_trazo():
	if not linea_trazo: return
	linea_trazo.clear_points()
	
	for btn in letras_seleccionadas:
		var centro_btn = btn.get_meta("centro") as Vector2
		linea_trazo.add_point(centro_btn)
		
	if arrastrando and letras_seleccionadas.size() > 0:
		linea_trazo.add_point(posicion_dedo_actual)

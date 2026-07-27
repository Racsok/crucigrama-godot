extends Control
class_name RuedaLetras

# Señal para avisarle al juego qué palabra se formó al soltar el dedo
signal palabra_enviada(palabra: String)

@export var radio_rueda: float = 120.0 # Radio del círculo en píxeles
@onready var linea_trazo: Line2D = $Line2D

var letras_actuales: Array[String] = []
var botones_letras: Array[Button] = []
var letras_seleccionadas: Array[Button] = []

var arrastrando: bool = false
var posicion_dedo_actual: Vector2 = Vector2.ZERO

func _ready():
	# Configurar el Line2D
	if linea_trazo:
		linea_trazo.width = 12.0
		linea_trazo.default_color = Color("ffcc00") # Color amarillo/dorado
		
	# Ejemplo de prueba instantáneo (comenta esta línea cuando lo integres con tu nivel)
	configurar_rueda("ARMADURA")

# ==========================================
# 1. GENERACIÓN CIRCULAR DE BOTONES
# ==========================================

func configurar_rueda(palabra_semilla: String):
	
	# Limpiar letras anteriores
	for b in botones_letras:
		b.queue_free()
	botones_letras.clear()
	letras_seleccionadas.clear()
	
	
	# Desordenar/Mezclar las letras
	var caracteres = []
	for i in range(palabra_semilla.length()):
		caracteres.append(palabra_semilla[i].to_upper())
	caracteres.shuffle()
	
	var total_letras = caracteres.size()
	if total_letras == 0: return
	
	var paso_angulo = (2 * PI) / total_letras
	
	# --- CAMBIO PRINCIPAL AQUÍ ---
	# Definimos el centro donde queremos la rueda. 
	# Si tu resolución es 540x960, el centro X es 270 y el centro Y es ~700 (parte inferior)
	var centro_rueda = size / 2.0
	
	# Si el nodo Control de la rueda ya ocupa toda la pantalla, también puedes usar:
	# var centro_rueda = size / 2.0
	
	for i in range(total_letras):
		var angulo = i * paso_angulo - (PI / 2)
		var offset_x = cos(angulo) * radio_rueda
		var offset_y = sin(angulo) * radio_rueda
		
		# Calculamos la posición relativa al centro deseado
		var pos_relativa = Vector2(offset_x, offset_y)
		var pos_final = centro_rueda + pos_relativa
		
		var boton = Button.new()
		boton.text = caracteres[i]
		boton.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		boton.custom_minimum_size = Vector2(50, 50)
		
		# Centramos el botón en las coordenadas exactas
		boton.position = pos_final - (boton.custom_minimum_size / 2.0)
		
		# Importante: Guardamos la posición exacta del centro para la línea
		boton.set_meta("letra", caracteres[i])
		boton.set_meta("centro", pos_final)
		
		add_child(boton)
		botones_letras.append(boton)

# ==========================================
# 2. MANEJO DE ENTRADA (MÓVIL Y RATÓN)
# ==========================================

func _gui_input(event: InputEvent):
	# Iniciar trazo (Tocar pantalla / Clic izquierdo)
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
			
	# Mover dedo/ratón
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
	
	# Construir la palabra final acumulada
	var palabra_resultado = ""
	for btn in letras_seleccionadas:
		palabra_resultado += str(btn.get_meta("letra"))
		
	if palabra_resultado.length() > 0:
		print("Palabra trazada: ", palabra_resultado)
		emit_signal("palabra_enviada", palabra_resultado)
		
	# Limpiar selección visual y la línea
	letras_seleccionadas.clear()
	if linea_trazo:
		linea_trazo.clear_points()

func _chequear_colision_con_letras(pos_dedo: Vector2):
	# Distancia de detección (en píxeles) desde el centro del botón
	var radio_deteccion = 35.0 
	
	for btn in botones_letras:
		var centro_btn = btn.get_meta("centro") as Vector2
		
		# Si el dedo está cerca del centro del botón
		if pos_dedo.distance_to(centro_btn) <= radio_deteccion:
			# Si no ha sido seleccionado en este trazo, lo agregamos
			if not btn in letras_seleccionadas:
				letras_seleccionadas.append(btn)
			# Si vuelve al penúltimo botón seleccionado, deseleccionamos el último (para des-trazar)
			elif letras_seleccionadas.size() >= 2 and btn == letras_seleccionadas[letras_seleccionadas.size() - 2]:
				letras_seleccionadas.pop_back()

# ==========================================
# 3. DIBUJAR LA LÍNEA (Line2D)
# ==========================================

func _actualizar_linea_trazo():
	if not linea_trazo: return
	
	linea_trazo.clear_points()
	
	# Conectar los centros de los botones seleccionados
	for btn in letras_seleccionadas:
		var centro_btn = btn.get_meta("centro") as Vector2
		linea_trazo.add_point(centro_btn)
		
	# Agregar un punto extra hasta la posición actual del dedo para que la línea siga al toque
	if arrastrando and letras_seleccionadas.size() > 0:
		linea_trazo.add_point(posicion_dedo_actual)

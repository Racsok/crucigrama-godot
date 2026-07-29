extends Node
class_name JuegoCrucigrama

@export var tablero: TableroCrucigrama
@export var rueda: Node
var logica: CrucigramaLogica

var mi_diccionario_espanol: Array = []
var mis_frecuencias: Dictionary = {}
var palabra_semilla: String = ""

# Lista para almacenar las palabras adivinadas en el nivel actual
var palabras_adivinadas: Array[String] = []

const RUTA_JSON: String = "res://assets/json/palabras_frecuencia.json" 

func _ready() -> void:
	# 1. Cargar el diccionario de frecuencias desde el JSON
	cargar_datos_desde_json(RUTA_JSON)

	# 2. Conectar la señal de la Rueda una sola vez al iniciar la escena
	if rueda and rueda.has_signal("palabra_enviada"):
		if not rueda.palabra_enviada.is_connected(_on_palabra_trazada):
			rueda.palabra_enviada.connect(_on_palabra_trazada)

	# 3. Iniciar el primer nivel
	nuevo_juego()

func cargar_datos_desde_json(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		push_error("No se encontró el archivo JSON en la ruta: " + ruta)
		return

	var archivo = FileAccess.open(ruta, FileAccess.READ)
	var contenido_texto = archivo.get_as_text()
	archivo.close()

	var datos_parseados = JSON.parse_string(contenido_texto)

	if typeof(datos_parseados) == TYPE_DICTIONARY:
		mis_frecuencias = datos_parseados
		mi_diccionario_espanol = mis_frecuencias.keys()
	else:
		push_error("Error: El archivo JSON no contiene una estructura válida")

func nuevo_juego() -> void:
	if mi_diccionario_espanol.size() == 0:
		push_error("El diccionario está vacío. No se puede generar un nivel.")
		return

	# Resetear el progreso del nivel actual
	
	palabras_adivinadas.clear()

	var palabras_candidatas: Array = []
	for p in mi_diccionario_espanol:
		if p.length() <= 7:
			palabras_candidatas.append(p)
	var nueva_semilla = palabras_candidatas.pick_random()
	while palabras_candidatas.size() > 1 and nueva_semilla == palabra_semilla:
		nueva_semilla = palabras_candidatas.pick_random()
	palabra_semilla = nueva_semilla

	print("\n--- INICIANDO NUEVO NIVEL ---")
	print("Palabra semilla elegida: ", palabra_semilla)

	# Buscar palabras derivadas
	var derivadas = AnalizadorPalabras.buscar_derivadas(palabra_semilla, mi_diccionario_espanol)

	# Generar la grilla lógica
	logica = CrucigramaLogica.new()
	logica.iniciar(palabra_semilla, derivadas, mis_frecuencias)
	
	if not logica.generar():
		print("No se encontró solución completa, usando mejor intento.")

	# Configurar la Rueda de letras
	if rueda:
		rueda.configurar_rueda(palabra_semilla)

	# Dibujar el Tablero visual
	if tablero:
		logica.imprimir_grilla()
		tablero.renderizar_crucigrama(logica.grilla)

func _on_palabra_trazada(palabra: String) -> void:
	var palabra_normalizada = palabra.to_upper()

	for p in logica.palabras_colocadas:
		if p.palabra == palabra_normalizada:
			# Si la palabra es correcta y no había sido adivinada previamente
			if not palabras_adivinadas.has(palabra_normalizada):
				palabras_adivinadas.append(palabra_normalizada)
				
				if tablero:
					await tablero.revelar_palabra_en_grilla(p)
				
				print("¡Correcto! Palabra revelada: ", palabra)
				
				# Comprobar si se completó el nivel
				_comprobar_victoria()
			else:
				print("La palabra '", palabra, "' ya la habías adivinado.")
			return

	print("La palabra '", palabra, "' no está en el crucigrama o es incorrecta.")

func _comprobar_victoria() -> void:
	# Si la cantidad de palabras adivinadas coincide con las colocadas en el crucigrama
	if palabras_adivinadas.size() >= logica.palabras_colocadas.size():
		print("¡FELICIDADES! NIVEL COMPLETADO.")
		
		# Espera 1.5 segundos para que el jugador vea la última palabra en pantalla antes de reiniciar
		await get_tree().create_timer(1.5).timeout
		
		# Generar el nuevo nivel automáticamente
		nuevo_juego()

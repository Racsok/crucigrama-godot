extends Node
class_name JuegoCrucigrama

## Nodo raíz de la escena. Arma la partida (une lógica + tablero) y escucha
## las señales del juego (por ejemplo, la palabra que traza el jugador en Rueda).
##
## En el inspector, arrastrá los nodos "Tablero" y "Rueda" a los campos
## exportados de abajo (no hace falta escribir rutas a mano).

@export var tablero: TableroCrucigrama
@export var rueda: Node
var logica: CrucigramaLogica

var mi_diccionario_espanol: Array = []
var mis_frecuencias: Dictionary = {}
var palabra_semilla: String = ""
	
const RUTA_JSON: String = "res://assets/json/palabras_frecuencia.json" 

func cargar_datos_desde_json(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		push_error("No se encontró el archivo JSON en la ruta: " + ruta)
		return

	# 1. Leer el archivo JSON
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	var contenido_texto = archivo.get_as_text()
	archivo.close()

	# 2. Parsear el JSON a un Diccionario
	var datos_parseados = JSON.parse_string(contenido_texto)

	if typeof(datos_parseados) == TYPE_DICTIONARY:
		mis_frecuencias = datos_parseados
		mi_diccionario_espanol = mis_frecuencias.keys()
		
	else:
		push_error("Error: El archivo JSON no contiene una estructura válida")
		
func nuevo_juego() -> void:
	if mi_diccionario_espanol.size() > 0:
			palabra_semilla = mi_diccionario_espanol.pick_random()
			print("Palabras cargadas: ", mi_diccionario_espanol.size())
			print("Palabra semilla elegida al azar: ", palabra_semilla)
	

func _ready() -> void:
	cargar_datos_desde_json(RUTA_JSON)

	var derivadas = AnalizadorPalabras.buscar_derivadas(palabra_semilla, mi_diccionario_espanol)

	logica = CrucigramaLogica.new()
	logica.iniciar(palabra_semilla, derivadas, mis_frecuencias)
	
	print(rueda)
	if rueda:
		rueda.configurar_rueda(palabra_semilla)
	if logica.generar():
		print("¡Crucigrama generado con éxito!")
	else:
		print("No se encontró solución completa, generando mejor intento.")

	if tablero:
		logica.imprimir_grilla()
		tablero.renderizar_crucigrama(logica.grilla)
		

	if rueda and rueda.has_signal("palabra_enviada"):
		rueda.palabra_enviada.connect(_on_palabra_trazada)

func _on_palabra_trazada(palabra: String) -> void:
	print("El jugador intentó la palabra: ", palabra)
	var palabra_normalizada = palabra.to_upper()

	for p in logica.palabras_colocadas:
		if p.palabra == palabra_normalizada:
			if tablero:
				tablero.revelar_palabra_en_grilla(p)
			print("¡Correcto! Palabra revelada: ", palabra)
			return

	print("La palabra '", palabra, "' no está en el crucigrama o es incorrecta.")

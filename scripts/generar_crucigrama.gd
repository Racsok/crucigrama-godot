extends GridContainer
class_name GeneradorCrucigrama

# Tamaño recomendado para cada casilla del crucigrama (en píxeles)
const CELL_SIZE = Vector2(35, 35)

var semilla: String
var n: int
var alpha: float = 1.0
var beta: float = 2.0
var diccionario_frecuencias: Dictionary
var palabras: Array = []
var casillas_mapa: Dictionary = {}

var grilla: Array = []
var palabras_colocadas: Array = [] # Guardará diccionarios: {"palabra": "", "r": 0, "c": 0, "dir": ""}
var tiene_aislada: bool = false

# ==========================================
# 1. UTILIDADES DE PALABRAS
# ==========================================

func contar_letras(texto: String) -> Dictionary:
	var conteo = {}
	for i in range(texto.length()):
		var letra = texto[i].to_lower()
		conteo[letra] = conteo.get(letra, 0) + 1
	return conteo

func puede_formar(palabra_candidata: String, palabra_semilla: String) -> bool:
	var conteo_semilla = contar_letras(palabra_semilla)
	var conteo_candidata = contar_letras(palabra_candidata)
	
	for letra in conteo_candidata.keys():
		if not conteo_semilla.has(letra) or conteo_semilla[letra] < conteo_candidata[letra]:
			return false
	return true

func buscar_derivadas(palabra_semilla: String, diccionario_completo: Array) -> Array:
	var resultados = []
	for palabra in diccionario_completo:
		if palabra.to_lower() != palabra_semilla.to_lower() and puede_formar(palabra, palabra_semilla):
			resultados.append(palabra.to_upper())
	return resultados

# ==========================================
# 2. LÓGICA DEL CRUCIGRAMA
# ==========================================

func iniciar(p_semilla: String, lista_palabras: Array, frecs: Dictionary = {}):
	semilla = p_semilla.to_upper()
	n = semilla.length()
	diccionario_frecuencias = frecs
	
	# Filtrar palabras que caben
	palabras.clear()
	for p in lista_palabras:
		if p.length() <= n:
			palabras.append(p.to_upper())
			
	# Ordenar usando nuestra función personalizada (Score -> Longitud)
	palabras.sort_custom(Callable(self, "_comparar_palabras"))
	
	# Inicializar grilla vacía (matriz nxn)
	grilla.clear()
	for r in range(n):
		var fila = []
		for c in range(n):
			fila.append(" ")
		grilla.append(fila)

func _calcular_score(palabra: String) -> float:
	var longitud = palabra.length()
	var frecuencia = diccionario_frecuencias.get(palabra, 0.0)
	return (longitud * alpha) + (frecuencia * beta)

func _comparar_palabras(a: String, b: String) -> bool:
	var score_a = _calcular_score(a)
	var score_b = _calcular_score(b)
	if score_a != score_b:
		return score_a > score_b
	return a.length() > b.length()

func puede_colocar(palabra: String, r: int, c: int, direccion: String) -> Array:
	var longitud = palabra.length()
	
	if direccion == "H":
		if c < 0 or c + longitud > n: return [false, 0]
		if c > 0 and grilla[r][c-1] != " ": return [false, 0]
		if c + longitud < n and grilla[r][c + longitud] != " ": return [false, 0]
	else:
		if r < 0 or r + longitud > n: return [false, 0]
		if r > 0 and grilla[r-1][c] != " ": return [false, 0]
		if r + longitud < n and grilla[r + longitud][c] != " ": return [false, 0]
		
	var intersecciones = 0
	
	for i in range(longitud):
		var curr_r = r + (i if direccion == "V" else 0)
		var curr_c = c + (i if direccion == "H" else 0)
		var letra_en_grilla = grilla[curr_r][curr_c]
		var letra_de_palabra = palabra[i]
		
		if letra_en_grilla != " ":
			if letra_en_grilla != letra_de_palabra: return [false, 0]
			intersecciones += 1
		else:
			if direccion == "H":
				if curr_r > 0 and grilla[curr_r - 1][curr_c] != " ": return [false, 0]
				if curr_r < n - 1 and grilla[curr_r + 1][curr_c] != " ": return [false, 0]
			else:
				if curr_c > 0 and grilla[curr_r][curr_c - 1] != " ": return [false, 0]
				if curr_c < n - 1 and grilla[curr_r][curr_c + 1] != " ": return [false, 0]
				
	return [true, intersecciones]

func colocar_palabra(palabra: String, r: int, c: int, direccion: String) -> Array:
	var backup = []
	for i in range(palabra.length()):
		var curr_r = r + (i if direccion == "V" else 0)
		var curr_c = c + (i if direccion == "H" else 0)
		backup.append({"r": curr_r, "c": curr_c, "letra": grilla[curr_r][curr_c]})
		grilla[curr_r][curr_c] = palabra[i]
		
	var info = {"palabra": palabra, "r": r, "c": c, "dir": direccion}
	palabras_colocadas.append(info)
	return backup

func remover_palabra(backup: Array, info_palabra: Dictionary):
	for celda in backup:
		grilla[celda.r][celda.c] = celda.letra
	for i in range(palabras_colocadas.size()):
		var p = palabras_colocadas[i]
		if p.palabra == info_palabra.palabra and p.r == info_palabra.r and p.c == info_palabra.c and p.dir == info_palabra.dir:
			palabras_colocadas.remove_at(i)
			break

func resolver(index: int = 0) -> bool:
	if index >= palabras.size():
		return palabras_colocadas.size() >= 3
		
	var palabra_actual = palabras[index]
	
	if palabra_actual == semilla:
		return resolver(index + 1)
		
	for r in range(n):
		for c in range(n):
			for direccion in ["H", "V"]:
				var chequeo = puede_colocar(palabra_actual, r, c, direccion)
				var es_valido = chequeo[0]
				var intersecciones = chequeo[1]
				
				if es_valido:
					if intersecciones > 0:
						var backup = colocar_palabra(palabra_actual, r, c, direccion)
						if resolver(index + 1): return true
						remover_palabra(backup, {"palabra": palabra_actual, "r": r, "c": c, "dir": direccion})
					elif intersecciones == 0 and not tiene_aislada:
						tiene_aislada = true
						var backup = colocar_palabra(palabra_actual, r, c, direccion)
						if resolver(index + 1): return true
						remover_palabra(backup, {"palabra": palabra_actual, "r": r, "c": c, "dir": direccion})
						tiene_aislada = false
						
	if resolver(index + 1):
		return true
		
	return false

func generar() -> bool:
	# Corrección del Integer Division: cast explícito a float/int
	var fila_centro = int(float(n) / 2.0)
	colocar_palabra(semilla, fila_centro, 0, "H")
	return resolver(0)

func imprimir_grilla():
	print("--- Grilla de %d x %d ---" % [n, n])
	for fila in grilla:
		var linea = "["
		for letra in fila:
			linea += (letra if letra != " " else ".") + " "
		linea += "]"
		print(linea)

# ==========================================
# 3. RENDERIZADO VISUAL EN EL GRIDCONTAINER
# ==========================================



func renderizar_crucigrama(matriz_crucigrama: Array):
	add_theme_constant_override("h_separation", 2) # Espacio horizontal entre celdas
	add_theme_constant_override("v_separation", 2) # Espacio vertical entre celdas
	
	# Limpiar celdas previas y el diccionario de posiciones
	casillas_mapa.clear()
	for child in get_children():
		child.queue_free()
		
	if matriz_crucigrama.size() == 0:
		return
		
	var filas = matriz_crucigrama.size()
	var columnas = matriz_crucigrama[0].size()
	
	# Ajustar el número de columnas del propio GridContainer
	self.columns = columnas

	# Dibujar casilla por casilla
	for r in range(filas):
		for c in range(columnas):
			var valor = matriz_crucigrama[r][c]
			
			if valor != " " and valor != "":
				var casilla = LineEdit.new()
				casilla.custom_minimum_size = CELL_SIZE
				casilla.max_length = 1
				casilla.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
				
				# --- CONFIGURACIÓN PARA EL REVELADO ---
				casilla.text = "" # Inicialmente vacía para que el jugador la adivine
				casilla.editable = false # Bloquea el teclado virtual/físico
				casilla.focus_mode = Control.FOCUS_NONE # Evita que gane foco al tocarla
				
				# Guardamos la letra correcta como metadato por si la necesitas luego
				casilla.set_meta("letra_correcta", valor)
				
				add_child(casilla)
				
				# Guardamos la casilla en el diccionario mapeada por su coordenada (Vector2i)
				casillas_mapa[Vector2i(r, c)] = casilla
			else:
				# Bloque transparente para celdas vacías
				var bloque_invisible = Control.new()
				bloque_invisible.custom_minimum_size = CELL_SIZE
				add_child(bloque_invisible)
				
	# Obliga al contenedor a reajustar su tamaño mínimo según sus hijos
	reset_size()
	
	# Centra el GridContainer horizontalmente en la pantalla
	position.x = (540 - size.x) / 2.0
	# Obliga al contenedor a reajustar su tamaño mínimo según sus hijos
	reset_size()
	
	# Centra el GridContainer horizontalmente en la pantalla (asumiendo resolución 540)
	position.x = (540 - size.x) / 2.0

# ==========================================
# 4. PUNTO DE ENTRADA AL EJECUTAR
# ==========================================
func _on_palabra_trazada(palabra: String):
	print("El jugador intentó la palabra: ", palabra)
	
	# Asumiendo que 'palabras_colocadas' es un Array de diccionarios o Structs 
	# con la información de las palabras generadas en el crucigrama:
	var palabra_encontrada = false
	
	for p in palabras_colocadas: # Ajusta 'palabras_colocadas' al nombre de tu variable/lista de palabras
		if p.palabra == palabra:
			palabra_encontrada = true
			revelar_palabra_en_grilla(p)
			print("¡Correcto! Palabra revelada: ", palabra)
			break
			
	if not palabra_encontrada:
		print("La palabra '", palabra, "' no está en el crucigrama o ya fue revelada.")

func revelar_palabra_en_grilla(info_palabra: Dictionary):
	var r = info_palabra.r
	var c = info_palabra.c
	var es_horizontal = (info_palabra.dir == "H")
	
	for i in range(info_palabra.palabra.length()):
		var pos = Vector2i(r, c)
		
		if casillas_mapa.has(pos):
			var casilla = casillas_mapa[pos] as LineEdit
			# Revelamos la letra en la pantalla
			casilla.text = info_palabra.palabra[i]
			
		# Avanzar posición según la orientación ("H" o "V")
		if es_horizontal:
			c += 1
		else:
			r += 1
	
	# y revelarla en el GridContainer si es correcta.
func _ready():
	var mi_diccionario_espanol = ["ROMA", "AMOR", "MAR", "RAMO", "MORA", "ORO", "ARMAR", "ARMADURA", "DURA", "RADA"]
	var mis_frecuencias = {"ROMA": 5.0, "AMOR": 6.5, "MAR": 4.2}
	
	var palabra_semilla = "ARMADURA"
	
	var derivadas = buscar_derivadas(palabra_semilla, mi_diccionario_espanol)
	iniciar(palabra_semilla, derivadas, mis_frecuencias)
	
	if generar():
		print("¡Crucigrama generado con éxito!")
	else:
		print("No se encontró solución completa, generando mejor intento.")
		
	imprimir_grilla()
	renderizar_crucigrama(grilla)
	
	$"../Rueda".palabra_enviada.connect(_on_palabra_trazada)

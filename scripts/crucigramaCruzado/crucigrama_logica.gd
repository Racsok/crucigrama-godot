class_name CrucigramaLogica
extends RefCounted

## Toda la lógica de generación del crucigrama (backtracking).
## No toca nodos ni UI: solo trabaja sobre una matriz de texto en memoria.
## Se usa así: var logica = CrucigramaLogica.new(); logica.iniciar(...); logica.generar()

var semilla: String
var n: int
var alpha: float = 1.0
var beta: float = 2.0
var diccionario_frecuencias: Dictionary
var palabras: Array = []

var grilla: Array = []
var palabras_colocadas: Array = [] # {"palabra": "", "r": 0, "c": 0, "dir": ""}
var _tiene_aislada: bool = false

func iniciar(p_semilla: String, lista_palabras: Array, frecs: Dictionary = {}) -> void:
	semilla = p_semilla.to_upper()
	n = semilla.length()
	diccionario_frecuencias = frecs

	palabras.clear()
	for p in lista_palabras:
		if p.length() <= n:
			palabras.append(p.to_upper())

	palabras.sort_custom(_comparar_palabras)

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
		if c > 0 and grilla[r][c - 1] != " ": return [false, 0]
		if c + longitud < n and grilla[r][c + longitud] != " ": return [false, 0]
	else:
		if r < 0 or r + longitud > n: return [false, 0]
		if r > 0 and grilla[r - 1][c] != " ": return [false, 0]
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

	palabras_colocadas.append({"palabra": palabra, "r": r, "c": c, "dir": direccion})
	return backup

func remover_palabra(backup: Array, info_palabra: Dictionary) -> void:
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
					elif intersecciones == 0 and not _tiene_aislada:
						_tiene_aislada = true
						var backup = colocar_palabra(palabra_actual, r, c, direccion)
						if resolver(index + 1): return true
						remover_palabra(backup, {"palabra": palabra_actual, "r": r, "c": c, "dir": direccion})
						_tiene_aislada = false

	return resolver(index + 1)

func generar() -> bool:
	if n == 0:
		return false
	var fila_centro = n / 2
	colocar_palabra(semilla, fila_centro, 0, "H")
	return resolver(0)

func imprimir_grilla() -> void:
	print("--- Grilla de %d x %d ---" % [n, n])
	for fila in grilla:
		var linea = "["
		for letra in fila:
			linea += (letra if letra != " " else ".") + " "
		linea += "]"
		print(linea)

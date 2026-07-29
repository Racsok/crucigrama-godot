class_name AnalizadorPalabras
extends RefCounted

## Utilidades para analizar y comparar palabras (letras, subconjuntos, derivadas).
## No depende de ningún nodo de la escena, así que se puede usar desde cualquier script
## llamando directamente a AnalizadorPalabras.funcion(...) sin necesidad de instanciar nada.

static func contar_letras(texto: String) -> Dictionary:
	var conteo = {}
	for i in range(texto.length()):
		var letra = texto[i].to_lower()
		conteo[letra] = conteo.get(letra, 0) + 1
	return conteo

static func puede_formar(palabra_candidata: String, palabra_semilla: String) -> bool:
	var conteo_semilla = contar_letras(palabra_semilla)
	var conteo_candidata = contar_letras(palabra_candidata)

	for letra in conteo_candidata.keys():
		if not conteo_semilla.has(letra) or conteo_semilla[letra] < conteo_candidata[letra]:
			return false
	return true

static func buscar_derivadas(palabra_semilla: String, diccionario_completo: Array) -> Array:
	var resultados = []
	for palabra in diccionario_completo:
		if palabra.to_lower() != palabra_semilla.to_lower() and puede_formar(palabra, palabra_semilla):
			resultados.append(palabra.to_upper())
	return resultados

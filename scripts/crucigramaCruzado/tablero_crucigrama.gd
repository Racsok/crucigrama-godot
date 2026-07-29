extends GridContainer
class_name TableroCrucigrama

## Solo se encarga de dibujar el crucigrama y de revelar palabras en pantalla.
## No sabe nada de backtracking: recibe una matriz ya resuelta y la pinta.
## Este script va en el nodo GridContainer de tu escena.

const CELL_SIZE = Vector2(35, 35)

## Arrastra aquí el archivo casilla.tscn en el Inspector
@export var casilla_scene: PackedScene

## Pausa (en segundos) entre cada casilla al revelar una palabra.
## Es lo que genera el efecto "casilla por casilla" en cascada.
@export var retraso_entre_casillas: float = 0.08

var casillas_mapa: Dictionary = {}

func renderizar_crucigrama(matriz_crucigrama: Array) -> void:
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)

	casillas_mapa.clear()
	for child in get_children():
		child.queue_free()

	if matriz_crucigrama.size() == 0:
		return

	if not casilla_scene:
		push_error("TableroCrucigrama: falta asignar 'Casilla Scene' en el Inspector.")
		return

	var filas = matriz_crucigrama.size()
	var columnas = matriz_crucigrama[0].size()
	self.columns = columnas

	for r in range(filas):
		for c in range(columnas):
			var valor = matriz_crucigrama[r][c]

			if valor != " ":
				var casilla: Casilla = casilla_scene.instantiate()
				casilla.custom_minimum_size = CELL_SIZE
				add_child(casilla)
				casilla.configurar_casilla(valor)
				casillas_mapa[Vector2i(r, c)] = casilla
			else:
				var bloque_invisible = Control.new()
				bloque_invisible.custom_minimum_size = CELL_SIZE
				add_child(bloque_invisible)

	reset_size()
	_centrar_en_pantalla()

func _centrar_en_pantalla() -> void:
	# NOTA: esto solo funciona si este GridContainer NO tiene otro Container
	# como padre directo (VBoxContainer, CenterContainer, etc.), porque esos
	# contenedores recalculan la posición de sus hijos y pisan este valor.
	var tamano_pantalla = get_viewport_rect().size
	position.x = (tamano_pantalla.x - size.x) / 2.0
	position.y = 80.0

## Revela una palabra completa, casilla por casilla, con una pequeña pausa
## entre cada una para lograr el efecto de "ola" al destapar.
## Es async (usa await): quien la llame puede hacer "await tablero.revelar_palabra_en_grilla(p)"
## si necesita esperar a que termine toda la animación antes de seguir.
func revelar_palabra_en_grilla(info_palabra: Dictionary) -> void:
	var r = info_palabra.r
	var c = info_palabra.c
	var es_horizontal = (info_palabra.dir == "H")

	for i in range(info_palabra.palabra.length()):
		var pos = Vector2i(r, c)
		if casillas_mapa.has(pos):
			var casilla = casillas_mapa[pos] as Casilla
			casilla.revelar_letra()
			await get_tree().create_timer(retraso_entre_casillas).timeout

		if es_horizontal:
			c += 1
		else:
			r += 1

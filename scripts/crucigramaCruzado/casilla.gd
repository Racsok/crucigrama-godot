class_name Casilla
extends Control

## Referencias a los nodos hijos
@onready var fondo: Control = $Fondo
@onready var label: Label = $Label

## Texturas opcionales
@export var textura_oculta: Texture2D
@export var textura_revelada: Texture2D

## Colores por defecto mientras no tengas imágenes PNG
@export var color_oculto: Color = Color("2b3a4a")       # Azul/gris oscuro
@export var color_revelado: Color = Color("ffffff")     # Blanco
@export var color_texto_revelado: Color = Color("efefef") # Texto oscuro

@export var duracion_pop: float = 0.35
@export var escala_maxima: float = 1.3

var letra_correcta: String = ""
var esta_revelada: bool = false

func _ready() -> void:
	label.text = ""
	label.visible = false
	
	# Aseguramos que la casilla tenga un tamaño mínimo asignado
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(35, 35)
		
	_actualizar_aspecto_oculto()

func _actualizar_aspecto_oculto() -> void:
	if fondo is TextureRect:
		if textura_oculta:
			(fondo as TextureRect).texture = textura_oculta
		fondo.modulate = Color.WHITE # Asegura que la imagen no se oscurezca
	elif fondo is ColorRect:
		(fondo as ColorRect).color = color_oculto
	else:
		fondo.modulate = color_oculto

func configurar_casilla(p_letra: String) -> void:
	letra_correcta = p_letra.to_upper()

func revelar_letra(con_animacion: bool = true) -> void:
	if esta_revelada:
		return

	esta_revelada = true
	label.text = letra_correcta
	label.visible = true

	if fondo is TextureRect and textura_revelada:
		(fondo as TextureRect).texture = textura_revelada
		fondo.modulate = Color.WHITE
	elif fondo is ColorRect:
		(fondo as ColorRect).color = color_revelado
		label.add_theme_color_override("font_color", color_texto_revelado)
	else:
		fondo.modulate = color_revelado
		label.add_theme_color_override("font_color", color_texto_revelado)

	if con_animacion:
		_animar_pop()

func _animar_pop() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * escala_maxima, duracion_pop * 0.5)
	tween.tween_property(self, "scale", Vector2.ONE, duracion_pop * 0.5)

func obtener_posicion_global() -> Vector2:
	return global_position

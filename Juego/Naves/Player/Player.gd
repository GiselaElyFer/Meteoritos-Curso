class_name Player

extends RigidBody2D


enum ESTADO {SPAWN, VIVO, INVENCIBLE, MUERTO}

export var potencia_motor: int = 20
export var potencia_rotacion: int = 280
export var estela_maxima: int = 150
export var hitpoints: float = 15.0

var empuje:Vector2 = Vector2.ZERO
var dir_rotacion : int = 0
var estado_actual:int = ESTADO.SPAWN


onready var canion:Canion = $Canion
onready var laser:RayoLaser = $LaserBeam2D
onready var estela:Estela = $EstelaPuntoInicio/Trail2D
onready var motor_sfx:Motor = $MotorSFX
onready var colisionador:CollisionShape2D = $CollisionShape2D
onready var impacto_nave = $ImpactoSFX
onready var escudo:Escudo = $Escudo


#func _ready() -> void:
	#controlador_estados(estado_actual)


func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("disparo_secundario"):
		laser.set_is_casting(true)
	
	if event.is_action_released("disparo_secundario"):
		laser.set_is_casting(false)
	
	if event.is_action_pressed("mover_adelante"):
		estela.set_max_points(estela_maxima)
		motor_sfx.sonido_on()
	elif event.is_action_pressed("mover_atras"):
		estela.set_max_points(0)
		motor_sfx.sonido_on()
	if(event.is_action_released("mover_adelante") or event.is_action_released("mover_atras")):
		motor_sfx.sonido_off()
	if event.is_action_pressed("escudo") and not escudo.get_esta_activado():
		escudo.activar()


func controlador_estados(nuevo_estado: int) -> void:
	match nuevo_estado:
		ESTADO.SPAWN:
			colisionador.set_deferred("disabled", true)
			canion.set_puede_disparar(false)
		ESTADO.VIVO:
			canion.set.puede_disparar(true)
			colisionador.set_deferred("disabled", false)
		ESTADO.INVENCIBLE:
			colisionador.set_deferred("disabled", true)
		ESTADO.MUERTO:
			colisionador.set_deferred("disabled", true)
			canion.set_puede_disparar(true)
			Eventos.emit_signal("nave_destruida", global_position, 2)
			queue_free()
		_:
			printerr("Error de estado")
	
	estado_actual = nuevo_estado


func esta_input_activo() -> bool:
	if estado_actual in [ESTADO.MUERTO, ESTADO.SPAWN]:
		return false
	
	return true


func _integrate_forces(_state: Physics2DDirectBodyState) -> void:
	apply_central_impulse(empuje.rotated(rotation))
	apply_torque_impulse(dir_rotacion * potencia_rotacion)


func _process(_delta: float) -> void:
	player_input()


func player_input() -> void:
	
	empuje = Vector2.ZERO
	if Input.is_action_pressed("mover_adelante"):
		empuje = Vector2(potencia_motor, 0)
	elif Input.is_action_pressed("mover_atras"):
		empuje = Vector2(-potencia_motor, 0)
	
	dir_rotacion = 0
	if Input.is_action_pressed("rotar_antihorario"):
		dir_rotacion -= 1
	elif Input.is_action_pressed("rotar_horario"):
		dir_rotacion += 1
	
	if Input.is_action_pressed("disparo_principal"):
		canion.set_esta_disparando(true)
	
	if Input.is_action_just_released("disparo_principal"):
		canion.set_esta_disparando(false)


func recibir_danio(danio: float) ->void:
	impacto_nave.play()
	hitpoints -= danio
	if hitpoints <= 0.0:
		destruir()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "spawn":
		controlador_estados(ESTADO.VIVO)


func destruir() -> void:
	controlador_estados(ESTADO.MUERTO)

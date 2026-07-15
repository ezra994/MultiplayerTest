extends Node3D
class_name PlayerModel

@onready var skeleton: Skeleton3D = %GeneralSkeleton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var data: PlayerData = %Data
@onready var player: CharacterBody3D = $".."
@onready var combat_model: Node3D = $"../CombatModel"
@onready var active_weapon: Sword = $"../Sword"

var current_move : Move

@onready var moves = {
	"idle" : $States/Idle,
	"walk" : $States/Walk,
	"jump" : $States/Jump,
	"sprint": $States/Sprint,
	"midair": $States/Midair,
	"slide_start": $States/Slide_start,
	"slide_loop": $States/Slide_loop,
	"crouch_idle": $States/Crouch_idle,
	"crouch_walk": $States/Crouch_walk,
	"hit_1": $States/Hit1,
	"hit_2": $States/Hit2,
	"hit_3": $States/Hit3,
}

func _ready():
	var bone_idx = skeleton.find_bone("spine")
	print(skeleton.get_bone_pose_position(bone_idx))
	current_move = moves["idle"]
	for move in moves.values():
		print(move.name)
		move.data = data
		move.player = player
	animation_player.playback_default_blend_time = 0.2
	#var anim_list = animation_player.get_animation_list()
	#for anim_name in anim_list:
		#if anim_name != "slide_loop":
			#animation_player.set_blend_time("slide_loop", anim_name, 2.0)


func update(input : InputPackage, delta : float):
	input = combat_model.translate_combat_actions(input)
	var relevance = current_move.check_relevance(input)
	if relevance != "okay":
		switch_to(relevance)
	current_move.update(input, delta)


func switch_to(state : String):
	#test()
	current_move.on_exit_state()
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()

func play(ani: String) -> void:
	if animation_player.has_animation(ani):
		if ani == "midair": print("PLEAS")
		animation_player.play(ani)
	else:
		push_error("Animation not found")
		
func test() -> void:
	var bone_idx = skeleton.find_bone("spine")
	var tween = create_tween()
	tween.tween_property(skeleton, "bones/%d/position" % bone_idx, Vector3(0.0, 1.0099, -0.0552), .1).set_ease(Tween.EASE_OUT)

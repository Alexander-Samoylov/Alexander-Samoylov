class_name Pickup
extends Hazard
# Shield / speed amulets are Hazards with pickup kinds. Kept as a named type
# so scenes and the plan's pickup.gd path exist.


func _ready() -> void:
	if kind_name == "":
		kind_name = "shield"

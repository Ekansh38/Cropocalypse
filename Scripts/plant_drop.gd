extends Area2D

@export var rice: InvItem

func _ready() -> void:
	rotation = randf_range(0, TAU)

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("Player") and not body.inv.is_full():
		body.add_item(rice)
		queue_free()

extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.has_method("score_hole"):
		body.rpc("score_hole")

extends Node2D
var testing_dialogue_path = "res://dialogue/json/mayor.json"
var testing_name = "Robin"


func _ready():
  EventHub.connect("dialogue_finished", self, "_on_dialogue_finished")


func _on_dialogue_finished():
  $Timer.start()


func _on_Timer_timeout():
  load_testing_dialogue()


func load_testing_dialogue():
  EventHub.emit_signal("new_dialogue", testing_dialogue_path, testing_name)

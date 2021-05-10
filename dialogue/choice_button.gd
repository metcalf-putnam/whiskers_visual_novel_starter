extends Button

var mouse_over := false
var buffer := 17


func set_text(text_in):
  text = text_in	
  rect_size.x = get_font("font").get_string_size(text_in).x + buffer


func get_text() -> String:
  return text


func _on_ChoiceButton_mouse_entered():
  mouse_over = true
  $MouseOver.play()


func _on_ChoiceButton_mouse_exited():
  mouse_over = false

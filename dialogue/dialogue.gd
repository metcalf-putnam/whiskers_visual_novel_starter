extends NinePatchRect

var lastBttnPos = 0
var timer = 0

var parser
var dialogue_data
var block
var data = {}
const action_prefix = "<"
var is_final := false
export (PackedScene) var ChoiceButton
enum State {DIALOGUE, TESTING, MESSAGE, HOUSE}
var state = State.DIALOGUE
var characters = []
var format_dictionary = {"player_name" : "Gedric"}

# Voice
enum TEXT_STATE { NA, READY, INPROGRESS, COMPLETE }
var text_state = TEXT_STATE.NA
var ticks_before_next_letter = 5
var current_tick = 0
var text_length = 0

# Button navigation
var current_button_index = 0

signal player_controls_toggle

func _ready():
  set_process(false)
  hide()
  EventHub.connect("new_dialogue", self, "init")
  parser = WhiskersParser.new(Global)


func _process(delta):
  timer += delta
  if text_state == TEXT_STATE.INPROGRESS:
    current_tick += 1
    if current_tick == ticks_before_next_letter:
      current_tick = 0
      get_node("Text").visible_characters += 1
      if get_node("Text").visible_characters == get_node("Text").text.length():
        text_state = TEXT_STATE.COMPLETE
        show_buttons()
  elif state == State.DIALOGUE:
    for i in range(0, get_node("Buttons").get_child_count()):
      if get_node('Buttons').get_child(i).pressed and timer >= 0.5:
        print("is pressed!!")
        $Select.play()
        step_forward(i)


func step_forward(i):
  if i == -1:
    block = parser.next()
  else:
    block = parser.next(block.options[i].key)
  next()
  timer = 0


func init(file_path : String, name := " ", portrait_file := ""):
  text_state = TEXT_STATE.READY
  $PopUp.play()
  EventHub.emit_signal("dialogue_started")
  state = State.DIALOGUE
  
  if portrait_file != "":
    $Portrait.texture = load(portrait_file)
    $Portrait.show()
  
  $Name_NinePatchRect/Name.text = name
  $Name_NinePatchRect.rect_size.x = $Name_NinePatchRect/Name.get_font("font").get_string_size(name).x + 23
  $Name_NinePatchRect.show()
  $Text.show()
  set_process(true)
  parser.set_format_dictionary(format_dictionary)
  
  dialogue_data = parser.open_whiskers(file_path)
  block = parser.start_dialogue(dialogue_data)
  next()


func error():
  $Name_NinePatchRect.hide()
  $Space_NinePatchRect.show()
  show()
  state = State.MESSAGE
  $Text.bbcode_text = "Error :("
  set_process(true)
  is_final = true


func next():
  clear_buttons()
  if block:
    show()
    text_state = TEXT_STATE.INPROGRESS
    animate_letters()


func add_button(button_data):
  var node = ChoiceButton.instance()
  node.set_text(button_data.text)
  node.rect_position = Vector2($ChoicePos.position.x, $ChoicePos.position.y + lastBttnPos)
  self.get_node("Buttons").add_child(node)
  
  # Dialogues contains button choices that are coming from Whisker file
  # With focus and using ui_inputs (ui_up, ui_down) it automatically solves the button navigation
  # NOTE: If WASD controls will be remapped, we need to revisit this code.
  if self.get_node("Buttons").get_child_count() == 1:
    var first_button = get_node("Buttons").get_child(0)
    first_button.grab_focus()
  
  node.show()
  node.set_name(button_data.key)
  print("data.key:", button_data.key)
  lastBttnPos -= node.rect_size.y + 3


func reset():
  data = {}
  lastBttnPos = 0
  clear_buttons()
  $Name_NinePatchRect.hide()


func clear_buttons():
  lastBttnPos = 0
  for child in get_node("Buttons").get_children():
    child.queue_free()


func _unhandled_input(event):
  if !is_processing():
    return
  
  if !event.is_action_pressed("ui_accept"):
    return
  
  if text_state == TEXT_STATE.INPROGRESS:
    current_button_index = 0
    text_state = TEXT_STATE.COMPLETE
    get_node("Text").visible_characters = -1
    show_buttons()
  else:
    if is_final:
      end_dialogue()
    elif $Buttons.get_child_count() == 0 and state == State.DIALOGUE:
      step_forward(-1)
      $Select.play()


func end_dialogue():
  get_tree().set_input_as_handled()
  clear_buttons()
  is_final = false
  set_process(false)
  EventHub.emit_signal("dialogue_finished")
  hide()


func update_name(name_in):
  $Name_NinePatchRect/Name.text = name_in
  $Name_NinePatchRect.rect_size.x = $Name_NinePatchRect/Name.get_font("font").get_string_size(name_in).x + 23


func add_name_button(name : String):
  var node = ChoiceButton.instance()
  node.set_text(name)
  node.rect_position = Vector2($ChoicePos.position.x, $ChoicePos.position.y + lastBttnPos)
  self.get_node("Buttons").add_child(node)
  
  # Dialogues contains button choices that are coming from Whisker file
  # With focus and using ui_inputs (ui_up, ui_down) it automatically solves the button navigation
  # NOTE: If WASD controls will be remapped, we need to revisit this code.
  if self.get_node("Buttons").get_child_count() == 1:
    var first_button = get_node("Buttons").get_child(0)
    first_button.grab_focus()
  
  node.show()
  lastBttnPos -= node.rect_size.y + 3


func animate_letters():
  get_node("Text").parse_bbcode(block.text)
  get_node("Text").visible_characters = 0
  current_tick = 0
  $Space_NinePatchRect.show()


func show_buttons():
  var count = 0
  for option in block.options:
    add_button(option)
    count += 1
  if count > 0:
    $Space_NinePatchRect.hide()
  else:
    $Space_NinePatchRect.show()
  if block.is_final:
    is_final = true

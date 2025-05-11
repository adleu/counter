extends Node
class_name InputHandler

@export var window_handler_node : window_handler
var udp = PacketPeerUDP.new()
var python_process_id = -1

func _ready():
	udp.bind(9090) 
	
	var args = ["files\\inputs_handler.py"]
	python_process_id = OS.create_process("python", args, false)
	print(python_process_id)

func _process(_delta):
	while udp.get_available_packet_count() > 0:
		var input = udp.get_packet().get_string_from_utf8()
		match input:
			"0":
				window_handler_node.change_i(true)
			"9":
				window_handler_node.change_i(false)
				
func quit_input_handler() -> void:
	if python_process_id != -1:
		OS.execute("taskkill", ["/pid", str(python_process_id), "/f"], [], false)

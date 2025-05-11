from pynput import keyboard
import socket
import sys

UDP_IP = "127.0.0.1"
UDP_PORT = 9090

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def on_press(key):
    try:
        if key.char == '+':
            sock.sendto(b"0", (UDP_IP, UDP_PORT))
        elif key.char == '-':
            sock.sendto(b"9", (UDP_IP, UDP_PORT))
    except:
        pass

keyboard.Listener(on_press=on_press).start()
input()
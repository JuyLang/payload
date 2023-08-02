import socket

target_ip = "172.18.0.2"
min_port = 1
max_port = 65535

for port in range(min_port, max_port + 1):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)  # Đặt thời gian chờ cho mỗi kết nối
    result = sock.connect_ex((target_ip, port))
    
    if result == 0:
        print(f"Port {port} is open")
    
    sock.close()

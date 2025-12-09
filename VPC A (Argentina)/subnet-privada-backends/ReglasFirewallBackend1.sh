# 1. Insertar la regla para aceptar el puerto 88 (antes del DROP final)
sudo iptables -I INPUT 1 -p tcp --dport 88 -j ACCEPT

# 2. Guardar para que no se pierda
sudo netfilter-persistent save
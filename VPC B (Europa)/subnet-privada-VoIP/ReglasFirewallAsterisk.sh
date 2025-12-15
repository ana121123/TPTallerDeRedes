#!/bin/bash

# Limpiar reglas anteriores
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -X

# 1. LOOPBACK (Tráfico local de la máquina)
iptables -A INPUT -i lo -j ACCEPT

# 2. CONEXIONES ESTABLECIDAS (Para no cortar lo que ya está hablando)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 3. SSH - SOLO DESDE ROUTER B (Gestión interna)
# Para entrar a la consola ssh, SIEMPRE venís desde el Router B.
# IP Privada Router B: 10.2.1.236
iptables -A INPUT -s 10.2.1.236 -p tcp --dport 22 -j ACCEPT

# 4. ASTERISK (SIP y RTP) - SOLO DESDE TU CASA + VPN
iptables -A INPUT -s 192.168.0.198/32 -p udp --dport 5060 -j ACCEPT
iptables -A INPUT -s 192.168.0.198/32 -p udp --dport 10000:20000 -j ACCEPT

# También permitimos a la VPC A (VPN) para que llamen los internos de allá
iptables -A INPUT -s 10.1.0.0/16 -p udp --dport 5060 -j ACCEPT
iptables -A INPUT -s 10.1.0.0/16 -p udp --dport 10000:20000 -j ACCEPT

# 5. PING (Opcional, útil para probar)
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

# 6. CERRAR TODO LO DEMÁS (Política Restrictiva)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
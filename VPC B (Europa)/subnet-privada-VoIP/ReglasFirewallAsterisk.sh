#!/bin/bash
# Limpiar reglas anteriores
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -X

# 1. LOOPBACK
iptables -A INPUT -i lo -j ACCEPT

# 2. CONEXIONES ESTABLECIDAS
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 3. SSH - SOLO DESDE ROUTER B (Gestión interna)
iptables -A INPUT -s 10.2.1.236/32 -p tcp --dport 22 -j ACCEPT

# 4. ASTERISK (SIP y RTP)
# Permitir tráfico desde la VPN (VPC A)
iptables -A INPUT -s 10.1.0.0/16 -p udp --dport 5060 -j ACCEPT
iptables -A INPUT -s 10.1.0.0/16 -p udp --dport 10000:20000 -j ACCEPT

# --- CRÍTICO: ACCESO EXTERNO ---
# Cuando Router B hace DNAT, el paquete llega a Asterisk con la IP ORIGINAL del cliente (Internet).
# Opción A (Insegura pero funcional para el TP): Aceptar todo en puertos SIP/RTP
iptables -A INPUT -p udp --dport 5060 -j ACCEPT
iptables -A INPUT -p udp --dport 10000:20000 -j ACCEPT

# Opción B (Más segura): Solo si saben la IP pública del profe o del lugar de la demo.
# iptables -A INPUT -s <IP_PUBLICA_DEMO> -p udp --dport 5060 -j ACCEPT
# ...

# 5. PING
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

# 6. CERRAR TODO LO DEMÁS
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
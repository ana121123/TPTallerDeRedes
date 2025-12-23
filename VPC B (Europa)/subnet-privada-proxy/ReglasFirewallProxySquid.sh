#!/bin/bash

# Limpiar reglas
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

#------------LOOPBACK---------------
# Permitir tráfico por loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------CONEXIONES YA ESTABLECIDAS---------------
# Permitir que entren paquetes de respuestas a conexiones que el proxy inició
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Permitir que salgan respuestas a conexiones que entraron
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------REGLAS DE ENTRADA (INPUT)---------------
# SSH - Permitir acceso solo desde el Router B (Bastión)
# IP Privada Router B: 10.2.1.236
iptables -A INPUT -s 10.2.1.236/32 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT

# SQUID - Permitir tráfico al puerto 3128
# Como Router B hace NAT (Masquerade), el tráfico de la VPN llega con la IP del Router B
iptables -A INPUT -s 10.2.1.236/32 -p tcp --sport 1024:65535 --dport 3128 -m state --state NEW -j ACCEPT

# ICMP - Permitir ping desde la red interna (Router B y VPN)
# Permitimos toda la subred de infraestructura o la IP del router
iptables -A INPUT -s 10.2.0.0/16 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT

#------------REGLAS DE SALIDA (OUTPUT)---------------
# DNS - Para resolver dominios (Google, Gobierno, etc.)
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT

# HTTP/HTTPS - Salida a internet para buscar las páginas web
iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# ICMP - Hacer ping hacia afuera
iptables -A OUTPUT -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

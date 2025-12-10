#!/bin/bash

# Limpiar reglas
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

#------------LOOPBACK---------------
# Permitir tráfico por loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------REGLAS DE ENTRADA Y SALIDA (INPUT Y OUTPUT)---------------
# Permitir conexiones establecidas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir SSH desde el router A (falta agregar luego para la VPN)
iptables -A INPUT -p tcp --dport 22 -s 10.1.1.72 -j ACCEPT # ip privada del router A

# Permitir SSH hacia la BDD
iptables -A OUTPUT -p tcp --dport 22 -d 10.1.20.0/24 -j ACCEPT

# Permitir salida MySQL (puerto 3306) hacia la BDD
iptables -A OUTPUT -p tcp --dport 3306 -d 10.1.20.0/24 -j ACCEPT

# Permitir que el proxy reverso (Router A) pueda consultar la web
iptables -A INPUT -p tcp --dport 88 -s 10.1.1.72 -j ACCEPT # ip privada del router A

# Permitir salida a internet a través del Router A
## DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
## HHTP Y HHTPS
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

#Permitir ping desde cualquier equipo conectado al tunel (falta)
iptables -A OUTPUT -p icmp -j ACCEPT # por el momento

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

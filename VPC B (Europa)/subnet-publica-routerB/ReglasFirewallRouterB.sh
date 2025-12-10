#!/bin/bash

# Limpiar reglas
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD
iptables -t nat -F POSTROUTING 

#------------LOOPBACK---------------
# Permitir tráfico por loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------CONEXIONES YA ESTABLECIDAS---------------
# Permitir que entren paquetes de respuestas a conexiones que el router inició
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Permitir que salgan respuestas a conexiones que entraron
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Permitir el paso de paquetes de conexiones ya establecidas en el forwarding
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------REGLAS DE ENTRADA (INPUT)---------------
# Permitir SSH desde cualquier origen
iptables -A INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT
# ICMP - Responder ping
iptables -A INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT

#------------REGLAS DE SALIDA (OUTPUT)---------------
# DNS 
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
# HTTP/HTTPS 
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 443 -m state --state NEW -j ACCEPT
# ICMP - Hacer ping hacia afuera
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT
#SSH
iptables -A OUTPUT -s 0.0.0.0/0 -d 10.1.0.0/16 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT

#------------REGLAS DE FORWARDING Y NAT---------------
# MASQUERADE
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
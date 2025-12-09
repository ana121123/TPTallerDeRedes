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
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# PROXY REVERSO - Permitir HTTP para el Nginx Reverse Proxy
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# ICMP - Responder ping
iptables -A INPUT -p icmp -j ACCEPT

#------------REGLAS DE SALIDA (OUTPUT)---------------
# DNS 
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
# HTTP/HTTPS 
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
# PROXY REVERSO - Nginx Proxy hacia Backends
iptables -A OUTPUT -p tcp --dport 88 -d 10.1.10.0/24 -j ACCEPT
# ICMP - Hacer ping hacia afuera
iptables -A OUTPUT -p icmp -j ACCEPT
#SSH
iptables -A OUTPUT -p tcp --dport 22 -d 10.1.0.0/16 -j ACCEPT

#------------REGLAS DE FORWARDING Y NAT---------------
# MASQUERADE
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
# FORWARDING - Permitir forwarding desde la Subnet Privada backends (10.1.10.0/24)
iptables -A FORWARD -i ens5 -o ens5 -s 10.1.10.0/24 -j ACCEPT
# FORWARDING - Permitir forwarding desde la Subnet Privada bdd (10.1.20.0/24)
iptables -A FORWARD -i ens5 -o ens5 -s 10.1.20.0/24 -j ACCEPT
# Permitir Ping pasante (entre VPCs o internet)
iptables -A FORWARD -p icmp -j ACCEPT

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP





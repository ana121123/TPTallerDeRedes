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

# Permitir SSH desde los backends
iptables -A INPUT -p tcp --dport 22 -s 10.1.10.0/24  -j ACCEPT

# Permitir que los backends se conecten a la base de datos MySQL (puerto 3306)
iptables -A INPUT -p tcp --dport 3306 -s 10.1.10.0/24 -j ACCEPT

# Permitir salida a internet a través de los Backends
## DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
## HHTP Y HHTPS
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
## ICMP
#iptables -A OUTPUT -p icmp -j ACCEPT # por el momento

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
#!/bin/bash

# Limpiar reglas
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

#------------LOOPBACK---------------
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------CONEXIONES ESTABLECIDAS---------------
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------ACCESO SSH---------------
# Permitir SSH desde Router B (Bastión local - 10.2.1.0/24)
iptables -A INPUT -s 10.2.1.0/24 -p tcp --dport 22 -m state --state NEW -j ACCEPT
# Opcional: Permitir SSH desde la VPN (Router A)
iptables -A INPUT -s 10.10.10.0/24 -p tcp --dport 22 -m state --state NEW -j ACCEPT

#------------SERVICIO SQUID PROXY---------------
# Permitir que la VPC A (10.1.0.0/16) se conecte al puerto 3128
# Esto viaja por el túnel WireGuard -> Router B -> Proxy
iptables -A INPUT -s 10.1.0.0/16 -p tcp --dport 3128 -m state --state NEW -j ACCEPT

#------------SALIDA A INTERNET---------------
# Permitir al Proxy salir a internet (HTTP/HTTPS/DNS) para buscar las páginas que le piden
## DNS
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
## HHTP Y HHTPS
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 443 -m state --state NEW -j ACCEPT

#------------PING (ICMP)---------------
# Permitir ping desde Router B y VPN
iptables -A INPUT -s 10.2.1.0/24 -p icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -s 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT

#------------POLITICAS POR DEFECTO---------------
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

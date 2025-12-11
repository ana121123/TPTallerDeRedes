#!/bin/bash

# Limpiar reglas
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

#------------LOOPBACK---------------
# Permitir tráfico por loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------CONEXIONES ESTABLECIDAS---------------
# Permitir conexiones establecidas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------ACCESO SSH---------------
# Permitir SSH desde el router A 
iptables -A INPUT -s 10.1.1.72/32 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT # ip privada del router A
#Permitir SSH des la VPN
iptables -A INPUT -s 10.10.10.0/24 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT
# Permitir SSH hacia la BDD
iptables -A OUTPUT -s 0.0.0.0/0 -d 10.1.20.0/24 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT

#------------CONEXIÓN A BASE DE DATOS---------------
# Permitir salida MySQL (puerto 3306) hacia la BDD
iptables -A OUTPUT -s 0.0.0.0/0 -d 10.1.20.0/24 -p tcp --sport 1024:65535 --dport 3306 -m state --state NEW -j ACCEPT

#------------ACCESO WEB (desde el proxy reverso)---------------
# Permitir que el proxy reverso (Router A) pueda consultar la web
iptables -A INPUT -s 10.1.1.72/32 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 88 -m state --state NEW -j ACCEPT # ip privada del router A

#------------SALIDA A INTERNET---------------
# Permitir salida a internet a través del Router A
## DNS
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
## HHTP Y HHTPS
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 443 -m state --state NEW -j ACCEPT

#------------PING (ICMP)---------------
# Permitir ping desde Router A
# iptables -A INPUT -s 10.1.1.72/32 -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT
# Permitir ping desde la VPN
iptables -A INPUT -s 10.10.10.0/24 -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT
# Permitir hacer ping hacia afuera
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT


#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

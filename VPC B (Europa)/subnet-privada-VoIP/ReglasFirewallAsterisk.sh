#!/bin/bash

# Limpiar reglas
iptables -F OUTPUT
iptables -F INPUT

#------------LOOPBACK---------------
# Permitir tráfico por loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#------------CONEXIONES YA ESTABLECIDAS---------------
# Permitir que entren paquetes de respuestas a conexiones que el router inició
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Permitir que salgan respuestas a conexiones que entraron
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------SSH---------------
# Permitir ssh desde el router B
iptables -A INPUT -s 10.2.1.236/32 -p tcp --dport 22 -j ACCEPT

#------------ASTERISK---------------
# Permitir tráfico SIP desde el router B (VPN y RED EXTERNA)
iptables -A INPUT -s 10.2.1.236/32 -p udp --dport 5060 -j ACCEPT
iptables -A OUTPUT -d 10.2.1.236/32 -p udp --dport 5060 -j ACCEPT

# Permitir tráfico RTP desde el router B (VPN y RED EXTERNA)
iptables -A INPUT -s 10.2.1.236/32 -p udp --dport 10000:20000 -j ACCEPT
iptables -A OUTPUT -d 10.2.1.236/32 -p udp --dport 10000:20000 -j ACCEPT

#------------OTRA REGLAS---------------
# ICMP
iptables -A INPUT -s 10.2.1.236/32 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -d 0.0.0.0/0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT
# DNS 
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 53 -m state --state NEW -j ACCEPT
# HTTP/HTTPS 
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --sport 1024:65535 --dport 443 -m state --state NEW -j ACCEPT

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
#!/bin/bash

# Limpiar reglas
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD
iptables -t nat -F POSTROUTING 
iptables -t nat -F PREROUTING

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
# ICMP - Permitir ping
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
iptables -A OUTPUT -s 0.0.0.0/0 -d 10.2.0.0/16 -p tcp --sport 1024:65535 --dport 22 -m state --state NEW -j ACCEPT

#------------REGLAS DE FORWARDING Y NAT---------------
# MASQUERADE
#iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

# FORWARDING - Permitir forwarding desde las Subnets Privadas de VPC B (10.2.0.0/16)
# iptables -A FORWARD -s 10.2.0.0/16 -d 0.0.0.0/0 -m state --state NEW -j ACCEPT

#------------REGLAS DE WIREGUARD---------------
## Permitir tráfico UDP en el puerto 51820
iptables -A INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --dport 51820 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p udp --dport 51820 -m state --state NEW -j ACCEPT

## Permitir tráfico en la interfaz del tunel (wg0)
# Aceptamos todo lo que venga del túnel destinado al router o a forward
iptables -A INPUT -i wg0 -j ACCEPT
iptables -A OUTPUT -o wg0 -j ACCEPT

## Forwarding entre la VPC local y la remota a tevés del tunel
# Permitir paso de paquetes desde la interfaz wg0 hacia la red interna
iptables -A FORWARD -i wg0 -j ACCEPT
# Permitir paso de paquetes desde la red interna hacia la interfaz wg0
iptables -A FORWARD -o wg0 -j ACCEPT

#------------REGLAS PARA PROXY SQUID---------------
# Permitir que el Router B contacte al Proxy
iptables -A OUTPUT -d 10.2.20.91/32 -p tcp --dport 3128 -m state --state NEW -j ACCEPT
# Permitir VPC A (vía túnel) hacia el Proxy (IP 10.2.20.91)
iptables -A FORWARD -i wg0 -d 10.2.20.91/32 -p tcp --dport 3128 -j ACCEPT
# Bloquear cualquier otro intento de ir al Proxy (Puerto 3128) para evitar que la VPC B use el proxy.
iptables -A FORWARD -d 10.2.20.91/32 -p tcp --dport 3128 -j DROP
# Permitir forwarding general desde VPC B hacia Internet (Salvo al proxy que ya bloqueamos arriba)
iptables -A FORWARD -s 10.2.0.0/16 -d 0.0.0.0/0 -m state --state NEW -j ACCEPT

#------------REGLAS PARA ASTERISK (VOIP)---------------
# Permitir SIP desde Internet hacia el Router (antes de DNAT)
# iptables -A INPUT -i ens5 -p udp --dport 5060 -m state --state NEW -j ACCEPT
# iptables -A INPUT -i ens5 -p udp --dport 10000:20000 -m state --state NEW -j ACCEPT

## DNAT (Port Forwarding) desde Internet hacia Asterisk
# Redirigir SIP (5060) que llega a la interfaz pública hacia la IP privada de Asterisk
iptables -t nat -A PREROUTING -i ens5 -p udp --dport 5060 -j DNAT --to-destination 10.2.10.152
# Redirigir RTP (Audio 10000-20000) hacia la IP privada de Asterisk
iptables -t nat -A PREROUTING -i ens5 -p udp --dport 10000:20000 -j DNAT --to-destination 10.2.10.152

## FORWARDING (Permitir el paso del tráfico redirigido y VPN)
# Permitir tráfico SIP desde Internet (ya redirigido por DNAT) hacia Asterisk
iptables -A FORWARD -d 10.2.10.152/32 -p udp --dport 5060 -m state --state NEW -j ACCEPT
# Permitir tráfico RTP desde Internet (ya redirigido por DNAT) hacia Asterisk
iptables -A FORWARD -d 10.2.10.152/32 -p udp --dport 10000:20000 -m state --state NEW -j ACCEPT

# Permitir tráfico SIP desde VPC A (por túnel wg0) hacia Asterisk
iptables -A FORWARD -i wg0 -d 10.2.10.152/32 -p udp --dport 5060 -j ACCEPT
# Permitir tráfico RTP desde VPC A (por túnel wg0) hacia Asterisk
iptables -A FORWARD -i wg0 -d 10.2.10.152/32 -p udp --dport 10000:20000 -j ACCEPT

## SNAT
iptables -t nat -A POSTROUTING -d 10.2.10.152/32 -j SNAT --to-source 10.2.1.236

# MASQUERADE
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
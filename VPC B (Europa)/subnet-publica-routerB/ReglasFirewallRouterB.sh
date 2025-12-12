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
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
# FORWARDING - Permitir forwarding desde las Subnets Privadas de VPC B (10.2.0.0/16)
iptables -A FORWARD -s 10.2.0.0/16 -d 0.0.0.0/0 -m state --state NEW -j ACCEPT

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
# FORWARD entre wg0 y la subred del proxy / VPC B
# permitir tráfico desde VPC A (vía tunel) hacia la subred del proxy (10.2.20.0/24)
iptables -A FORWARD -s 10.1.0.0/16 -d 10.2.20.0/24 -i wg0 -o ens5 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# permitir retorno
iptables -A FORWARD -s 10.2.20.0/24 -d 10.1.0.0/16 -i ens5 -o wg0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Permitir explícito del backend -> proxy (puerto 3128) a nivel FORWARD
iptables -A FORWARD -s 10.1.0.0/16 -d 10.2.20.91 -p tcp --dport 3128 -i wg0 -j ACCEPT
iptables -A FORWARD -s 10.2.20.91 -d 10.1.0.0/16 -p tcp --sport 3128 -o wg0 -j ACCEPT

# Permitir que el host del proxy salga a Internet por HTTP/HTTPS (necesario)
iptables -A OUTPUT -s 10.2.20.91 -o ens5 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -s 10.2.20.91 -o ens5 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT


#------------POLITICAS POR DEFECTO---------------
# Bloquear todo por defecto (DROP)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
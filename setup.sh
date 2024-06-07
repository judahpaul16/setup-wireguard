#!/bin/bash

# Install WireGuard and QR Code generation tools
sudo apt update
sudo apt install -y wireguard qrencode

# Generate keys for server and client
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Variables for IP Addresses and Port
SERVER_IP="<your-server-public-ip>"  # Replace with your server's public IP
SERVER_PRIVATE_KEY=$(cat server_private.key)
CLIENT_PUBLIC_KEY=$(cat client_public.key)
CLIENT_PRIVATE_KEY=$(cat client_private.key)
SERVER_PORT=51820
CLIENT_IP_RANGE="10.0.0.2/32"
SERVER_IP_RANGE="10.0.0.1/24"

# Configure WireGuard Interface on Server
sudo sh -c "echo '[Interface]
Address = $SERVER_IP_RANGE
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true' > /etc/wireguard/wg0.conf"

# Add client configuration to server
sudo sh -c "echo '[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP_RANGE' >> /etc/wireguard/wg0.conf"

# Bring the WireGuard interface up
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0

# Client Configuration File
echo "[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP_RANGE
DNS = 8.8.8.8

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > ~/client-wg0.conf

# Generate QR Code as an image
qrencode -t PNG -o ~/client-wg0.png < ~/client-wg0.conf

# Output QR Code for Mobile Clients (optional)
qrencode -t ansiutf8 < ~/client-wg0.conf

# Confirm WireGuard is active and display path to QR code
echo "WireGuard is active. Configuration for the client is in 'client-wg0.conf' and QR code image is stored as 'client-wg0.png'."

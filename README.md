# docker-proxy

Simple layer 4 (TCP) proxy based on socat to expose docker.sock in your network. 

> [!WARNING]  
> Use this image at your own risk. Some conigurations might enable attackers to control your docker deamon!

## Example

### Secure

Here is a baisc example on how to protect the endpoint using a Wireguard VPN & docker networks.

#### docker-compose.yml

```yml
version: "3.8"

networks:
  wireguard:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.99.0/24
          gateway: 192.168.99.1

services:
  docker-proxy:
    image: ghcr.io/lucarickli/docker-proxy:latest
    container_name: docker-proxy
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    expose:
      - 80
    networks:
      wireguard:
        ipv4_address: 192.168.99.98

  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      # - SYS_MODULE # optional
    environment:
      PUID: 1000
      PGID: 1000
      TZ: ${TZ:-Etc/UTC}
      SERVERURL: ${HOSTNAME:?required}
      SERVERPORT: 51820
      PEERS: 1
      PEERDNS: auto
      ALLOWEDIPS: 0.0.0.0/0
      LOG_CONFS: true
      # INTERNAL_SUBNET: 10.13.13.0
      # PERSISTENTKEEPALIVE_PEERS: true
    volumes:
      - ./Corefile:/config/coredns/Corefile:ro
      - ./wireguard/:/config:rw
      # - /lib/modules:/lib/modules # optional
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    networks:
      wireguard:
        ipv4_address: 192.168.99.99
    healthcheck:
      test: ifconfig wg0 && netstat -tulpn | grep LISTEN | grep :8080
      start_period: 30s
```

#### Corefile

Change `example.com` to your hostname`

```Corefile
. {
    loop
    health
    hosts {
        192.168.99.98 docker.example.com
        fallthrough
    }
    forward . /etc/resolv.conf
}
```

#### .env

```sh
HOSTNAME=example.com
TZ=Etc/UTC
```

### Start

```sh
docker compose up -d
```

Get the VPN client configuration from the folder `./wireguard` and connect. Once connected you should be able to reach the docker socket over the configured hostname or over `192.168.99.98`. 

#### Docker context

You could use this setup to control a remote server running docker without accessing it over ssh. To do so simply add a new docker context. 

> [Docker context documentation](https://docs.docker.com/engine/context/working-with-contexts/)

Example:

```sh
# Remember to use TCP as the protocol.
docker context create --description docker-proxy --docker "tcp://docker.example.com"
```


### Insecure

> [!WARNING]  
> Only use this behind a proper firewall!

```sh
docker run -d \
  -p 80:80 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/lucarickli/docker-proxy:latest
```

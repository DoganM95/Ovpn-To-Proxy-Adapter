# Intro

Creates proxy servers for locations listed by a VPN provider, e.g. ExpressVPN, Surfshark, etc. 
Each (OpenVPN) location translates into a seperate docker container. The OpenVPN to Proxy conversion is provided by [haugene/docker-transmission-openvpn](https://github.com/haugene/docker-transmission-openvpn).

## Features

- Deletes transmission-ovpn containers which have `status=created` and are non functional
- Iterates over ports, until a free one is found to run a proxy container on in batch mode
- Supports many vpn providers, see the full list at [vpn-configs-contrib](https://github.com/haugene/vpn-configs-contrib).
- Configurable `docker run --restart` argument

## Setup

- Copy `spawn.sh` from this repo to destination machine (linux)
- Retrieve the username & password, which are usually not the vpn login credentials, but special ones created by the provider, shown when choosing manual setup e.g.
  -  [ExpressVPN](https://www.expressvpn.com/setup#manual)
  -  [Surfshark](https://my.surfshark.com/vpn/manual-setup/main/openvpn)
- If only one location should be translated into a proxy server
  - Head over to [vpn-configs-contrib](https://github.com/haugene/vpn-configs-contrib/tree/main/openvpn)
  - Find the folder of the vpn provider used
  - Copy the name of the server needed
  - Skip to the Usage part
- If many proxies need to be created at once, create a file called `ovpn_list` in the same directory as the script
  - Copy each needed location's name into the `ovpn_list`

## Usage

### Notes

- The `.ovpn` file to use is not provided as file, but as a name (string). The Transmission-service fetches the corresponding file and handles the rest 
- The vpn providers supported are listed at [vpn-configs-contrib](https://github.com/haugene/vpn-configs-contrib)
- The script parameters for `spawn.sh` below must be entered in the same order as listed
- when creating a proxy, the `.ovpn` can be added also, it will be removed by the script anyway

### Script parameters

  - `vpn_location`: The desired line chosen from the `ovpn_list`
  - `vpn_provider`: The company of the service used (Internal or External), full list [here](https://haugene.github.io/docker-transmission-openvpn/supported-providers/#internal_providers)
  - `starting_port`: The port on which the proxy should serve in single mode, and where it should start iterating in batch mode (see Features)
  - `vpn_username`: The expressvpn username which you kept handy (see setup above)
  - `vpn_password`: The corresponding password
  - `container_restart`: The docker run restart behaviour like `always`, `unless-stopped`, etc, see [documentation](https://docs.docker.com/config/containers/start-containers-automatically/)
  - `network_cidr`: The host network's range, e.g. `192.168.0.0/24`

### Single proxy creation

```shell
sudo ./spawn.sh \
    <vpn_location> \
    <vpn_provider> \
    <starting_port> \
    <vpn_username> \
    <vpn_password> \
    <container_restart> \
    <network_cidr>
```

#### Example:

Create a proxy server, which connects to "Hong Kong - 2" and be available on port 8900:

```shell
sudo ./spawn.sh \
    my_expressvpn_hong_kong_-_2_udp.ovpn \
    EXPRESSVPN \
    8900 \
    y7v1wwy6wg5vh8s9jfn2sj3c \
    ixay8f10fdljm31zks09x287 \
    always \
    192.168.0.0/24
```

### Multi proxy creation (batch)

```shell
sudo ./spawn.sh \
    list \
    <vpn_provider> \
    <starting_port> \
    <vpn_username> \
    <vpn_password> \
    <container_restart> \
    <network_cidr>
```

#### Example:  

If `ovpn_list` file contains

```text
jp-tok-st014.prod.surfshark.com_udp.ovpn
ua-iev.prod.surfshark.com_udp.ovpn
us-nyc.prod.surfshark.com
```

Then the following would create 3 proxy servers, one for each location. First (Japan) would listen on port 8900, Second (Ukraine) on port 8901, etc.

```shell
sudo ./spawn.sh \
    list \
    SURFSHARK \
    8900 \
    someone@something.com \
    8x5o60nz22gll9o8qsf63to2 \
    always \
    192.168.0.0/24
```

## Useful docker commands

### Stop all openvpn containers
```shell
docker ps -a --format "{{.Names}}" | grep "openvpn" | xargs -r -I {} docker stop {}
```

### Remove all stopped openvpn containers
```shell
docker ps -a --format "{{.Names}}" | grep "openvpn" | xargs -r -I {} docker rm {}
```

### Shell into the container (if only one is running)
```shell
docker exec -it $(docker ps -a --format '{{.Names}}' | grep 'openvpn' | head -n 1) /bin/sh
```

### Show logs of the container (in only one is running)
```shell
docker logs $(docker ps -a --format '{{.Names}}' | grep 'openvpn' | head -n 1)
```

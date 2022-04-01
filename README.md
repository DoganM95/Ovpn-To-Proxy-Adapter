# Description

Creates proxy servers from .ovpn files, which can be downloaded from [expressvpn.com under manual](https://www.expressvpn.com/setup#manual).
Each ovpn file runs in a seperate docker container. The ovpn to proxy conversion is provided by [haugene/docker-transmission-openvpn](https://github.com/haugene/docker-transmission-openvpn).

## Features

- Deletes transmission-ovpn containers which have `status=created` and are non functional
- Iterates over ports until a free one is found to bind a proxy container to
- Configurable docker run --restart behaviour

## Setup

- Copy `spawn.sh` from this repo to destination machine (linux)  
- If many proxies need to be created at once, also copy `ovpn_list`  
  - Delete unneeded lines (proxies), remaining lines will be created
- Keep username and password handy [expressvpn.com](https://www.expressvpn.com/setup#manual)
- Install docker if not done already

## Usage

The .ovpn file to use is not provided as file, only as name. The Transmission-service then fetches the corresponding file and handles the rest. A full list is provided in the `ovpn_list` file. Last modified date is last updated date. `ovpn_list` file needs to be in the same directory as this script for batch.

- ### Script parameters

  - `vpn_location`: the desired line chosen from the `ovpn_list`
  - `port`: the port on which the proxy should serve
  - `starting_port`: first port on which proxy creation should be tried on. If occupied, iterates until free port found
  - `vpn_username`: the expressvpn username which you kept handy (see setup above)
  - `vpn_password`: the corresponding password
  - `container_restart`: docker argument, [quick usage in documentation](https://docs.docker.com/config/containers/start-containers-automatically/)

- ### Single proxy creation

```shell
sudo ./spawn.sh <vpn_location> <vpn_provider> <port> <vpn_username> <vpn_password> <container_restart>
```

  > Example:
  >
  > ```shell
  > sudo ./spawn.sh my_expressvpn_hong_kong_-_2_udp EXPRESSVPN 8900 abc123 def456 always
  > ```
  >
  > would create a proxy server, which connects to "Hong Kong - 2" and be available on port 8900.

- ### Multi proxy creation (batch)  

```shell
sudo ./spawn.sh list vpn_provider port vpn_username vpn_password container_restart
```™

  > Example:  
  > If `ovpn_list` file contained
  >
  > ```text
  >   my_expressvpn_japan_-_tokyo_udp
  >   my_expressvpn_ukraine_udp
  >   my_expressvpn_usa_-_new_york_-_2_udp
  > ```
  >
  > Then the command
  >
  > ```shell
  > sudo ./spawn.sh list EXPRESSVPN 8900 abc123 def456 always
  > ```
  >
  > would create 3 proxy servers, one for each location. First (Japan) would listen on port 8900, Second (Ukraine) on port 8901, etc.

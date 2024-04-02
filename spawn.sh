#!/bin/sh

vpn_location=$(trim_extension "$1") # Location with extension ".ovpn" removed
vpn_provider=$2
starting_port=$3
vpn_username=$4
vpn_password=$5
container_restart=$6
network_cidr=$7

ovpn_list=./ovpn_list
existing_containers=$(docker ps -a --filter "name=haugene-transmission-openvpn" --format {{.Names}})

main() {
    echo "Removing all haugene-transmission-vpn containers with status=created. These are faulty containers and will now be replaced by working ones."
    $(docker rm $(docker ps -a --filter "name=haugene-transmission-openvpn" --filter "status=created" -q)) # Remove non-functional containers
    if [[ "list" = "$vpn_location" ]]; then
        if [ -e "$ovpn_list" ]; then
            sed -i '/^$/d' $ovpn_list
            echo "" >>$ovpn_list
            echo "Found a list with $(wc -l <$ovpn_list) vpn's."
            while read line; do
                line=$(trim_extension "$line")
                if ! [[ $existing_containers =~ $line ]]; then
                    echo "Creating container for $line"
                    create_container "$line"
                else
                    echo "Skipping creation of $line. Equally named container already exists."
                fi
                echo
            done <$ovpn_list
        else
            echo "No ovpn_list file found. Exiting."
            return 1
        fi
    else
        echo "Creating proxy container for location $vpn_location"
        create_container "$vpn_location"
    fi
}

create_container() {
    ports_in_use=$(docker ps --format {{.Ports}} | cut -d ':' -f2 | cut -d '-' -f 1 | cut -d '/' -f 1)
    while [[ $ports_in_use =~ $starting_port ]]; do
        echo "Port $starting_port already in use, trying next port."
        ((starting_port++))
    done

    vpn_name=$1
    echo "Configuring container for $vpn_provider"

    docker run \
        --cap-add=NET_ADMIN \
        -d \
        -e "LOCAL_NETWORK=$network_cidr" \
        -e "OPENVPN_USERNAME=$vpn_username" \
        -e "OPENVPN_PASSWORD=$vpn_password" \
        -e "OPENVPN_PROVIDER=$vpn_provider" \
        -e "OPENVPN_CONFIG=$vpn_name" \
        -e "WEBPROXY_ENABLED=true" \
        -e "WEBPROXY_PORT=8118" \
        --name="haugene-transmission-openvpn-proxy-$vpn_location" \
        -p "$starting_port:8118" \
        --restart "$container_restart" \
        haugene/transmission-openvpn:latest

    echo "Port mapped to this http proxy: $starting_port"
    ((starting_port++))
}

trim_extension() {
    stripped_name=$(echo "$1" | sed 's/.ovpn$//')
    echo "$stripped_name"
}

main

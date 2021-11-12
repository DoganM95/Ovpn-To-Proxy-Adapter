#!/bin/sh
# Single example: sudo ./this_script.sh my_expressvpn_hong_kong_-_2_udp.ovpn EXPRESSVPN 8120 express_vpn_username express_vpn_password
# Batch example: sudo ./this_script.sh list EXPRESSVPN 8120 express_vpn_username express_vpn_password
# The second parameter (8120) dedines the port to begin the container assignment with, incrementing on each container creation.
# If a container creation fails, the script will just continue to create the rest. But non-functional ones will not run, so
# all non-running ones after script is done, are non-functional ones and can be deleted.
# A list extracted from the script can be found here: https://gist.github.com/DoganM95/3edf2654cf26e59ad3ef81ce17927c56

vpn_location=$1
vpn_provider=$2
starting_port=$3
vpn_username=$4
vpn_password=$5
container_restart=$6

main() {
    echo "Removing all haugene-transmission-vpn containers with status=created. These are faulty containers and will now be replaced by working ones."
    $(docker rm $(docker ps -a --filter "name=haugene-transmission-openvpn" --filter "status=created" -q)) # removes all transmission-vpn containers with status = "created" (== non-functional)
    FILE=./ovpn_list
    EXISTING_CONTAINERS=$(docker ps -a --filter "name=haugene-transmission-openvpn" --format {{.Names}})
    if [[ "list" = $vpn_location ]]; then
        if [ -e "$FILE" ]; then
            sed -i '/^$/d' $FILE # blank lines deletion
            echo "" >>$FILE      # blank line addition (eof)
            echo "Found a list with $(wc -l $FILE) vpn's."
            while read line; do
                line=$(trim_extension $line)
                if ! [[ $EXISTING_CONTAINERS =~ $line ]]; then
                    echo "Creating container for $line"
                    create_container $line
                else
                    echo "Skipping creation of $line . Equally named container already exists."
                fi
                echo
            done <$FILE
        else
            echo "No ovpn_list file found. Exiting."
            return 1
        fi
    else
        vpn_location=$(trim_extension $vpn_location)
        echo "Creating container for $vpn_location"
        create_container $vpn_location
    fi
}

create_container() {
    ports_in_use=$(docker ps --format {{.Ports}} | cut -d ':' -f2 | cut -d '-' -f 1 | cut -d '/' -f 1)
    while [[ $ports_in_use =~ $starting_port ]]; do
        echo "Port $starting_port already in use, trying next port."
        ((starting_port++))
    done

    vpn_name=$1
    mkdir /volume1/docker/Transmission-openvpn/data/$vpn_name

    docker run \
        -e "LOCAL_NETWORK=192.168.0.0/24" \
        -e "OPENVPN_USERNAME=$vpn_username" \
        -e "OPENVPN_PASSWORD=$vpn_password" \
        -e "OPENVPN_PROVIDER=$vpn_provider" \
        -e "OPENVPN_CONFIG=$1" \
        -e "WEBPROXY_ENABLED=true" \
        -e "WEBPROXY_PORT=8118" \
        -v "/volume1/docker/Transmission-openvpn/data/$vpn_name:/data" \
        -p $starting_port:8118 \
        -d \
        --restart $container_restart \
        --cap-add=NET_ADMIN \
        --name="haugene-transmission-openvpn-$1" \
        haugene/transmission-openvpn:latest

    echo "Port mapped/exposed to this containers Web Proxy: $starting_port"
    ((starting_port++))
}

trim_extension() {
    stripped_name=$(echo "$1" | sed 's/.ovpn//')
    echo $stripped_name
}

main

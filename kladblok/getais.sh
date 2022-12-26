#!/bin/bash
#shellcheck shell=bash disable=SC2076

#set -x
AIS_URL="https://kx1t.com/ais/ships_full.json"

vesseldata="$(curl -sL "$AIS_URL" | jq -r ".ships[]|to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")"

declare -A VESSELS
declare -a VESSEL_INDEX
declare -a KEY_INDEX

# add any extra indexes for notification mechanisms below.
# use syntax "mechanism_key" - example for last notification sent time at mastodon: mast_last
KEY_INDEX+=("mast_lat" "mast_lon" "mast_last")

while read -r keyvalue
do
    key="${keyvalue%%=*}"
    value="${keyvalue#*=}"
    if [[ "$key" == "mmsi" ]]
    then
        mmsi="$value"
        VESSEL_INDEX+=("$mmsi")
    fi
    [[ ! " ${KEY_INDEX[*]} " =~ " ${key} " ]] && KEY_INDEX+=("${key}")
    [[ -n "$mmsi" ]] && VESSELS["$mmsi:$key"]="$value"

done <<< "$vesseldata"
declare -p KEY_INDEX
declare -p VESSEL_INDEX
declare -p VESSELS

#!/bin/bash
#shellcheck shell=bash disable=SC2076
AIS_URL="https://kx1t.com/aistships_full.json"

vesseldata="$(jq -r ".ships[]|to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" < curl -Ls "$AIS_URL")"

declare -A VESSELS
declare -a VESSEL_INDEX
declare -a KEY_INDEX

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

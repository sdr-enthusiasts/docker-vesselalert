# sdr-enthusiasts/docker-shipxplorer

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [AirNav ShipXplorer](https://www.shipxplorer.com)'s `sxfeeder` and `AIS-catcher`. Builds and runs on `arm64`, `armv7/armhf`, and `amd64/x86`.

`AIS-catcher` pulls AIS information from a RTL-SDR dongle.
`sxfeeder` sends this data to RadarBox.

You can also use this container to feed other AIS services that take NMEA-formatted AIS data over either UDP or HTTP. See below for details.

## Prerequisites

We expect you to have the following:
* a piece of hardware that runs Linux. The prebuilt containers support `armhf`, `arm64`, and `amd64`. Systems with those architectures include Raspberry Pi 3B+, 4, and Linux PCs with Ubuntu.
* a dedicated RTL-SDR dongle that can receive at 160 MHz, with an appropriate antenna
* Docker must be installed on your system. If you don't know how to do that, please read [here](https://github.com/sdr-enthusiasts/docker-install).
* Some basic knowledge on how to use Linux and how to configure docker containers with `docker-compose`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `arm32v7`, `armv7l`, `armhf`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4 32-bit)
* `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)
* `amd64`, `x86_64`: X86 64-bit Linux (Linux PC)

Other architectures (Windows, Mac) are not currently supported, but feel free to see if the container builds and runs for these.
In theory, it should work, but I don't have the time nor inclination to test it.

## Obtaining a ShipXplorer Sharing Key

First-time users should obtain a ShipXplorer sharing key.

In order to obtain a ShipXplorer sharing key, on the first run of the container, it will generate a sharing key and print this to the container log.

```shell
timeout 180s docker run \
    --rm \
    -it \
    ghcr.io/sdr-enthusiasts/shipxplorer:latest
```

This will run the container for 3 minutes, allowing a sharing key to be generated.
Shortly after, you will see something like this:
```
WARNING: SHARING_KEY or SERIAL_NUMBER environment variable was not set!
Please make sure you note down the keys generated and update your docker-compose.yml with these values.
Set environment var SHARING_KEY to the new key displayed below - this is the long hex number
Set environment var SERIAL_NUMBER to the Serial Number displayed below - this is the SXTRPIxxxxxx string
They must be set for this container to run.
Please set it and restart the container.

[2022-11-01 19:48:19]  Your new key is f1xxxxxxxxxxxxxxxxxxxxxxxx57 and Serial Number (SN) is SXTRPIxxxxxx.
Please save this key for future use. You will have to know this key to link this receiver to your account
in https://www.shipxplorer.com/. This key is also saved in configuration file (/etc/sxfeeder.ini)
```
You can wait for the 3 minutes to pass, or you can press CTRL-C now to finish.
Take a note of the Sharing Key (`f1...57` - yours will be a different number) and the Serial Number (`SXTRPIxxxxxx`), and add these to the `SHARING_KEY` and `SERIAL_NUMBER` parameters of your `docker-compose.yml` file.

If you're not a first time user and are migrating from another installation, you can retrieve your sharing key by doing this:

* SSH onto your existing receiver and run the command `cat /etc/sxfeeder.ini`
The `key` and `sn` lines show your current credentials

## Up-and-Running with Docker Compose

```shell
version: '3.8'
services:
  shipxplorer:
    image: ghcr.io/sdr-enthusiasts/shipxplorer
    container_name: shipxplorer
    hostname: shipxplorer
    restart: always
    environment:
      - SHARING_KEY=
      - SERIAL_NUMBER=
      - RTLSDR_DEVICE_SERIAL=device_serial
#    ports:
    devices:
      - /dev/bus/usb
    tmpfs:
      - /tmp
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
```

Replace the `SHARING_KEY`, `SERIAL_NUMBER`, and `RTLSDR_DEVICE_SERIAL` with the appropriate values.
You can use `rtl_test` to see which devices and device serials are connected to your machine, or `rtl_eeprom` to rename the device's serial number.


## Claiming Your Receiver

Once your container is up and running, you should claim your receiver.

1. Go to https://www.shipxplorer.com
2. Create an account or sign in
3. Claim your receiver by visiting <https://www.shipxplorer.com/addcoverage> and following the instructions

Note - you will need your `SHARING_KEY` and the location of your feeder (coordinates or pick on map). As of now, it appears that you don't need your SN or Public IP address.

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         |
| ---------------------- | ------------------------------- |
| `SHARING_KEY`          | Required. Sharing Key generated by `sxfeeder`. See instructions above |
| `SERIAL_NUMBER`        | Required. Serial Number generated by `sxfeeder`. See instructions above |
| `RTLSDR_DEVICE_SERIAL` | Required. Serial Number of your RTL-SDR dongle. See instructions above |
| `UDP_FEEDS`            | Optional. Defines target UDP feeds in addition to ShipExplorer. Format: `UDP_FEEDS=domain1.com:port1,domain2,com:port2,...` |
| `VERBOSE_LOGGING`      | Optional. If empty, a summary is displayed every 60 seconds. If set to a number (`0`-`5`), it's set to the `AIS-Catcher -o` [log level](https://github.com/jvde-github/AIS-catcher#usage). Any other non-empty string corresponds to `-o 2`. To silence `AIS-Catcher` logs, set this parameter to `0` |
| `RTLSDR_DEVICE_GAIN`   | Optional. SDR device gain. If omitted, default value is 33.3 is used |
| `AISCATCHER_EXTRA_OPTIONS` | Optional. Any additional command line parameters you wish to pass to `AIS-catcher`. Default: empty |
| `SXFEEDER_EXTRA_OPTIONS` | Optional. Any additional command line parameters you wish to pass to `sxfeeder`. Default: empty |
| `STATION_NAME` | Optional. Station name displayed on stat web page. If omitted, it will should your ShipXplorer Serial Number |
| `STATION_LINK` | Optional. URL displayed on stat web page. If omitted, it will show your ShipXplorer URL |
| `SXFEEDER_LAT` | Optional. Used for calculating ship distances on web page |
| `SXFEEDER_LON` | Optional. Used for calculating ship distances on web page |

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Workaround for CPU Serial (only needed with non-Raspberry Pi systems)
The `sxfeeder` binary effectively greps for `serial\t\t:` in your `/proc/cpuinfo` file, to determine the RPi's serial number.

For systems that don't have a CPU serial number in `/proc/cpuinfo`, we can "fudge" this by generating a replacement `cpuinfo` file with a random serial number. To do this, copy and paste the following on your host machine:
```
sudo mkdir -m777 -p /opt/shipxplorer/cpuinfo
sudo install -m 666 /proc/cpuinfo /opt/shipxplorer/cpuinfo/
echo -e "serial\t\t: $(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr '[:upper:]' '[:lower:]')" >> /opt/shipxplorer/cpuinfo/cpuinfo
```
You can now map this file into your container:

* If using docker run, simply add `-v /opt/shipxplorer/cpuinfo/cpuinfo:/proc/cpuinfo` to your command.
* If using docker-compose, add the following to the `volumes:` section of your shipxplorer container definition:
```
  - /opt/shipxplorer/cpuinfo/cpuinfo:/proc/cpuinfo
```

## Feeding other services
You can use the `UDP_FEEDS` parameter to feed additional services, as long as they can accept the UDP data format.  for example to feed MarineTraffic:
```
     - UDP_FEEDS=5.9.207.224:5321
```
If you signed up and configured a station at their website, please replace the IP:port by the one allocated to your station. You can add multiple comma-separated UDP feeds here.

If you have a Ham Radio license, you can also feed to `aprs.fi` via HTTP. In this case, configure `AISCATCHER_EXTRA_OPTIONS` like this:
```
     - AISCATCHER_EXTRA_OPTIONS=-H http://aprs.fi/jsonais/post/abcdefghijklmn ID C9LLSIGN PROTOCOL aprs INTERVAL 30 RESPONSE off
```
where you replace `abcdefghijklmn` with the key you get when you sign up at aprs.fi, and `C9LLSIGN` with your Ham Radio callsign.

## Hardware requirements

AIS data is transmitted in the 160 MHz band, for which you'd need a suitable antenna. Note -- ADSB/UAT antennas will definitely not work!
You would need a RTL-SDR dongle, potentially with an LNA, and potentially with a filter. The filter must be dedicated to the 160 MHz band. Dongles with built-in filters for the ADSB or UAT bands won't work.
Last - the software will run on a Raspberry Pi 3B+ or 4, with Raspberry Pi OS, Ubuntu, or a similar Debian-based operating system. It will also run on X86 (Linux PC) systems with Ubuntu. The prebuilt Docker container will work on `armhf`/`arm64`/`x86_64` (`amd64`) architectures. You may be able to build containers for other systems, but for that you're on your own.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-shipxplorer/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
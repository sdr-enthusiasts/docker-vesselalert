# sdr-enthusiasts/docker-vesselalert

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)


## Introduction

Docker container providing social media notification for Vessels that are received with @jvde-github's excellent [AIS-Catcher](https://github.com/jvde-github/AIS-catcher) package.
Builds and runs on `arm64`, `armv7/armhf`, and `amd64/x86`.

Initially, only posts to [Mastodon](https://airwaves.social) are supported. We can consider adding additional social media targets upon request. Post an Issue or vote up an existing feature request.

## Prerequisites

We expect you to have the following:
* An installed and working version of the [AIS-Catcher](https://github.com/jvde-github/AIS-catcher) package with the Web Functionality installed and accessible to this container. This means that you need to be using [v0.42](https://github.com/jvde-github/AIS-catcher/releases/tag/v0.42) or later, and that you must configure the Web Server as per the [documentation](https://github.com/jvde-github/AIS-catcher/blob/main/README.md). We advise to put the Web Server on a fixed and known port number as you will have to configure a link to this for VesselAlert to work. Note -- the version of AIS-Catcher in the official ShipXplorer distribution is too old. You must install a newer version (or switch to the [containerized version](https://github.com/sdr-enthusiasts/docker-shipxplorer), which includes an up-to-date version of AIS-Catcher).
* Docker must be installed on your system. If you don't know how to do that, please read [here](https://github.com/sdr-enthusiasts/docker-install).
* Some basic knowledge on how to use Linux and how to configure docker containers with `docker-compose`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `arm32v7`, `armv7l`, `armhf`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4 32-bit)
* `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)
* `amd64`, `x86_64`: X86 64-bit Linux (Linux PC)

Other architectures (Windows, Mac) are not currently supported, but feel free to see if the container builds and runs for these.

## Configuring Mastodon: create an application and get an `access token`
Please follow the instructions [here](README-Mastodon.md).

## Up-and-Running with Docker Compose
An example `docker-compose.yml` can be found [here](docker-compose.yml).

Make sure to map the `/data` directory to a volume, as per the [example file](docker-compose.yml). If you forget to do this, the ships database will be erased upon container recreation, and a new notification will be sent for every ship that is heard after restart. This will probably spam your Mastodon account!

## Runtime Environment Variables

There are a series of available environment variables:

### General parameters:

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `AIS_URL` | Indicates the URL of the AIS-Catcher website. For example, `https://myserver.com/ais` | empty | yes |
| `SCREENSHOT_URL` | If set to the URL of a screenshot container, the notifier will attempt to get a screenshot to add to the notification. See below for explanation on how to configure | empty | no |
| `NOTIFICATION_MAPURL` | If set to a URL, a link `$NOTIFICATION_MAPURL/mmsi=$mmsi` will be added to the notification. If the value is non-empty but doesn't start with "http" (e.g., if it's set to `on`, `$AIS-URL/mmsi=$mmsi` will be used. | empty | no |
| `NOTIFY_ONLY_NEW_ON_STARTUP` | If set to any non-empty value, when restarting the container, it will not notify for any vessels in its first run, and consider these vessels "already notified". This is to avoid spamming the notification service at initial startup when many non-notified vessels are discovered | empty | no |
| `NOTIFICATION_THROTTLE` | If set to any non-empty value, notifications will pause for 15 seconds for every 10 notifications in a run | empty | no |

### Mastodon notifications related parameters:

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `MASTODON_SERVER` | Name (URL) of the Mastodon Server | `airwaves.social` | no |
| `MASTODON_ACCESS_TOKEN` | The access token of the Mastodon Application you are using. See above for instructions. | empty | yes |
| `MASTODON_SKIP_FILTER` | RegEx that is applied to the `mmsi` of a vessel. If the RegEx matches, the vessel is excluded from notifications. An example of a filter that filters out MMSIs that are 7 digits (too short), and any navigational aids (MMSI starts with 99) is ` MASTODON_SKIP_FILTER=^[9]{2}[0-9]{7}$\|^[0-9]{7}$ `| empty | no |
| `MASTODON_MIN_DIST` | Minimum distance (in nautical miles) a vessel must have traveled before it is eligible for a new notification. | empty | no |
| `MASTODON_NOTIFY_EVERY` | Minimum amount of time (in seconds) between two notifications for the same vessel. | `86400` (1 day) | no |
| `MASTODON_POST_VISIBILITY` | `visibility` setting for the Mastodon notification. Valid values are `public`, `unlisted`, and `private`. | `public` | no |
| `MASTODON_CUSTOM_FIELD` | Custom field attached to the end of the Mastodon notification. Please keep it short and clear-text only. | empty | no |
| `MASTODON_LINK_SHIPXPLORER` | If set to `on`, the Mastodon notification will include a link to the vessel on ShipXplorer | empty | no |
| `MASTODON_LINK_MARINETRAFFIC` | If set to `on`, the Mastodon notification will include a link to the vessel on MarineTraffic | empty | no |
| `MASTODON_LINK_VESSELFINDER` | If set to `on`, the Mastodon notification will include a link to the vessel on VesselFinder | empty | no |

## Discord notifications related parameters:

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `DISCORD_WEBHOOKS` | Comma separated list of Discord Webhook URLs. If omitted, no Discord Notifications will be sent. | empty | no |
| `DISCORD_NAME` | Station name. Use something descriptive of who and where you are, e.g., `kx1t - Boston Harbor` | empty | yes (if Discord notifications are enabled) |
| `DISCORD_AVATAR_URL` | URL to an avatar used with the notification message | empty | no |

### Expert Parameters (only change/set if you know what you're doing)
| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `MIN_MSG_COUNT` * | The minimum number of messages that AIS-Catcher must have received before a vessel can create a notification. This is implemented to ensure that "spurious" vessels that probably have invalid information cause notifications. | `10` | no |
| `MAX_MSG_AGE` * | If a vessel hasn't been heard of for more than this amount of time (in seconds), it will be removed from the notification database | `604800` (1 week) | no |
| `CHECK_INTERVAL` * | Interval (in secs) between "runs" of the Mastodon Notifier. | `30` | no |
| `DEBUG` * | If this variable is set to any non-empty value, (a lot of) debug information will be printer to the Container Logs | empty | no |

\* You probably shouldn't change the value of these parameters unless you really know what you are doing.

## Adding screenshots to your notifications
VesselAlert has an option to add screenshots to your notifications. This is done by adding and configuring a separate screenshot container. The reason for not integrating this functionality directly into VesselAlert is that the screenshot container is  large (~250 Mb) and requires a lot of system resources when running. Although this container is known to be able to run on `armhf` devices like Raspberry Pi 3B+, Thu units will run much faster and smoother on Raspberry Pi 4 or x86 with a 64-bits OS.
The screenshot container had an internal website that is used by VesselAlert to request a screenshot. It uses headless Chromium to make the screenshot and provide it to the requestor.
A configuration example is provided in the sample [docker-compose.yml](docker-compose.yml) file.
The screenshot container is Open Source and can be found [here](https://github.com/kx1t/browser-screenshot-service/tree/aiscatcher).

Please note that you must use the screenshot container's `aiscatcher` tag and branch as these include special configuration options for use with VesselAlert.

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Modifications of Ship Status and Ship Type descriptions
In your `opt/ais/data` directory (if you followed the volume mappings as recommended), there are two files:
- `shipstatus.db` contains the descriptions of the Ship Status for each status ID number
- `shiptype.db` contains the descriptions of the Ship Type for each type number
You can change those with a text editor. Lines that start with "#" are ignored, and you can hashtag words in the description.

## Acknowledgements
Without the help, advice, testing, and kicking the tires of these people, things wouldn't have happened:
- [@jvde-github](https://github.com/jvde-github) for his advice and help. He's also the author of [AIS-Catcher](https://github.com/jvde-github/AIS-catcher), which is a prerequisite for this container to work
- [@kevinelliott](https://github.com/kevinelliott) for his help during the design phase of the project, and to bounce ideas of
- [@hdziban303](https://github.com/hdziban303) for his help testing the early releases and providing feedback
- [@JohnEx](https://github.com/Johnex) for his ideas, research, testing, and feedback
- [@Tedder](https://github.com/tedder) who created the [original screenshot container](https://github.com/tedder/browser-screenshot-service) when we needed it for Planefence
- The engineers at AirNav who helped me understand things through their ShipXplorer project, and who provided the initial trigger for me to create this container

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-vesselalert/issues) on the project's GitHub.
I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse. The #ais-catcher channel is appropriate for conversations about this package.

## Summary of License Terms
Copyright (C) 2022-2023, Ramon F. Kolb (kx1t)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

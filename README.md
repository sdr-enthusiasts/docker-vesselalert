# sdr-enthusiasts/docker-vesselalert

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

## Table of Contents

- [sdr-enthusiasts/docker-vesselalert](#sdr-enthusiastsdocker-vesselalert)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Multi Architecture Support](#multi-architecture-support)
  - [Configuring Mastodon: create an application and get an `access token`](#configuring-mastodon-create-an-application-and-get-an-access-token)
  - [Up-and-Running with Docker Compose](#up-and-running-with-docker-compose)
  - [Runtime Environment Variables](#runtime-environment-variables)
    - [General parameters](#general-parameters)
    - [Tropo Alert parameters](#tropo-alert-parameters)
    - [General Notification related parameters](#general-notification-related-parameters)
    - [Mastodon and other notifications related parameters](#mastodon-and-other-notifications-related-parameters)
  - [Discord notifications related parameters](#discord-notifications-related-parameters)
  - [BlueSky notifications related parameters](#bluesky-notifications-related-parameters)
  - [MQTT notifications related parameters](#mqtt-notifications-related-parameters)
  - [Expert Parameters (only change/set if you know what you're doing)](#expert-parameters-only-changeset-if-you-know-what-youre-doing)
  - [Adding screenshots to your notifications](#adding-screenshots-to-your-notifications)
  - [Logging](#logging)
  - [Modifications of Ship Status and Ship Type descriptions](#modifications-of-ship-status-and-ship-type-descriptions)
  - [Acknowledgements](#acknowledgements)
  - [Getting Help](#getting-help)
  - [Summary of License Terms](#summary-of-license-terms)
    - [VesselAlert](#vesselalert)
    - [Tropo Alert Feature](#tropo-alert-feature)

## Introduction

Docker container providing social media notification for Vessels that are received with @jvde-github's excellent [AIS-Catcher](https://github.com/jvde-github/AIS-catcher) package.
Builds and runs on `arm64`, `armv7/armhf`, and `amd64/x86`.

Currently, posts to [Mastodon](https://airwaves.social), Discord, BlueSky, and MQTT are supported. We can consider adding additional social media targets upon request. Post an Issue or vote up an existing feature request.

## Prerequisites

We expect you to have the following:

- An installed and working version of the [AIS-Catcher](https://github.com/jvde-github/AIS-catcher) package with the Web Functionality installed and accessible to this container. This means that you need to be using [v0.42](https://github.com/jvde-github/AIS-catcher/releases/tag/v0.42) or later, and that you must configure the Web Server as per the [documentation](https://github.com/jvde-github/AIS-catcher/blob/main/README.md). We advise to put the Web Server on a fixed and known port number as you will have to configure a link to this for VesselAlert to work. Note -- the version of AIS-Catcher in the official ShipXplorer distribution is too old. You must install a newer version (or switch to the [containerized version](https://github.com/sdr-enthusiasts/docker-shipxplorer), which includes an up-to-date version of AIS-Catcher).
- Docker must be installed on your system. If you don't know how to do that, please read [here](https://github.com/sdr-enthusiasts/docker-install).
- Some basic knowledge on how to use Linux and how to configure docker containers with `docker-compose`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

- `arm32v7`, `armv7l`, `armhf`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4 32-bit)
- `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)
- `amd64`, `x86_64`: X86 64-bit Linux (Linux PC)

Other architectures (Windows, Mac, armel) are not currently supported, but feel free to see if the container builds and runs for these.

## Configuring Mastodon: create an application and get an `access token`

Please follow the instructions [here](README-Mastodon.md).

## Up-and-Running with Docker Compose

An example `docker-compose.yml` can be found [here](docker-compose.yml).

Make sure to map the `/data` directory to a volume, as per the [example file](docker-compose.yml). If you forget to do this, the ships database will be erased upon container recreation, and a new notification will be sent for every ship that is heard after restart. This will probably spam your Mastodon account!

## Runtime Environment Variables

There are a series of available environment variables:

### General parameters

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `AIS_URL` | Indicates the URL of the AIS-Catcher website. For example, `https://myserver.com/ais` | empty | yes |
| `SCREENSHOT_URL` | If set to the URL of a screenshot container, the notifier will attempt to get a screenshot to add to the notification. See below for explanation on how to configure | empty | no |
| `NOTIFICATION_MAPURL` | If set to a URL, a link `$NOTIFICATION_MAPURL/mmsi=$mmsi` will be added to the notification. If the value is non-empty but doesn't start with "http" (e.g., if it's set to `on`, `$AIS-URL/mmsi=$mmsi` will be used. | empty | no |
| `NOTIFY_ONLY_NEW_ON_STARTUP` | If set to any non-empty value, when restarting the container, it will not notify for any vessels in its first run, and consider these vessels "already notified". This is to avoid spamming the notification service at initial startup when many non-notified vessels are discovered | empty | no |
| `NOTIFICATION_THROTTLE` | If set to any non-empty value, notifications will pause for 15 seconds for every 10 notifications in a run | empty | no |
| `LANGUAGE` | Set to make notifications in one of these supported languages: `ca_ES` (Català); `de_DE` (Deutsch); `en_US` (US English); `es_ES` (Español); `fr_FR` (Français); `gl_ES`(Galego); `nl_NL` (Nederlands); `sv_SE` (Swedish). If omitted or if you select a language that is not supported, it will default to `en_US` | `en_US` | no |
| `LAT` | Latitude of receiver station. If Lat/Lon are included, the notification will contain a "Distance to Receiver" field | empty | no |
| `LON` | Longitude of receiver station. If Lat/Lon are included, the notification will contain a "Distance to Receiver" field | empty | no |

### Tropo Alert parameters

The Tropo Alert feature sends notifications if a distant ship is detected during the `TROPOALERT_INTERVAL` period. This is an indication that there is Tropospheric propagation available that makes long-distance reception possible, such as a temperature inverstion, ducting, or sporadic-E propagation.

For predictions on Tropo conditions for your area, please visit the [DX Info Centre](https://www.dxinfocentre.com/) and select the map of your region.

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `TROPOALERT` | If set to `on`/`enabled`/`true`/`1`/`yes`, Tropo Alert notifications will be sent if a long distance vessel is detected | `enabled` | no |
| `TROPOALERT_INTERVAL` | Interval in which Tropo Alerts are sent. Value should be compatible with the Linux `sleep`command, for example `600`, `10m`, or `3h` | `10m` | no |
| `TROPO_MINDIST` | Minimum detected distance (in nm) for a Tropo Alert to be sent. | `75` | no |

### General Notification related parameters

The following are a few parameters that apply to all notification methods:

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `NOTIFY_SKIP_FILTER` ^ | RegEx that is applied to the `mmsi` of a vessel. If the RegEx matches, the vessel is excluded from notifications. An example of a filter that filters out MMSIs that are 7 digits (too short), and any navigational aids (MMSI starts with 99) is ` MASTODON_SKIP_FILTER=^[9]{2}[0-9]{7}$\|^[0-9]{7}$ `| empty | no |
| `NOTIFY_MIN_DIST` ^ | Minimum distance (in nautical miles) a vessel must have traveled before it is eligible for a new notification. | empty | no |
| `NOTIFY_EVERY` | Minimum amount of time (in seconds) between two notifications for the same vessel. If set to `off`, `disabled`, or `0`, no notifications based on timing will be sent. | `86400` (1 day) | no |
| `NOTIFY_WHEN_SHIPNAME_EMPTY` | If set to `off`, notifications will not be sent if the vessel's `shipname` property is empty | `on` | no |

Note that the parameters above used to be known as `MASTODON_SKIP_FILTER`, `MASTODON_MIN_DIST`, and `MASTODON_NOTIFY_EVERY`. These legacy parameter names are still supported for backward compatibility, but we encourage users to switch to these updated parameter names when possible.

### Mastodon and other notifications related parameters

Note -- parameters that are marked with `^` are applicable to all notification mechanisms, and not only to Mastodon. In the future, we may make the names of these variables more generic.

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `MASTODON_SERVER` | Name (URL) of the Mastodon Server | `airwaves.social` | no |
| `MASTODON_ACCESS_TOKEN` | The access token of the Mastodon Application you are using. See above for instructions. | empty | yes |
| `MASTODON_POST_VISIBILITY` | `visibility` setting for the Mastodon notification. Valid values are `public`, `unlisted`, and `private`. | `unlisted` | no |
| `MASTODON_CUSTOM_FIELD` ^ | Custom field attached to the end of the Mastodon notification. Please keep it short and clear-text only. | empty | no |
| `MASTODON_LINK_AISCATCHER` ^ | If set to `on`, the Mastodon notification will include a link to the vessel on aiscatcher.org. (Set to `off`/`false`/`no`/`0` to disable) | on | no |
| `MASTODON_LINK_SHIPXPLORER` ^ | If set to `on`, the Mastodon notification will include a link to the vessel on ShipXplorer | empty | no |
| `MASTODON_LINK_MARINETRAFFIC` ^ | If set to `on`, the Mastodon notification will include a link to the vessel on MarineTraffic | empty | no |
| `MASTODON_LINK_VESSELFINDER` ^ | If set to `on`, the Mastodon notification will include a link to the vessel on VesselFinder | empty | no |
| `MASTODON_RETENTION_TIME` | Time (in days) that any Toots to Mastodon will be retained. *) Default if omitted is `7` days. Set to `off` to disable | `7`(days) | no |

*) If you are currently sending notifications to Mastodon, the system will automatically delete any Toots you made to your Mastodon account that are older than 7 days, or whatever value you have set this parameter to. If you don't want this to happen, you MUST set MASTODON_RETENTION_TIME=off in your `docker-compose.yml` file. Note that ALL posts to your Mastodon account are affected by this, and not just the posts made by VesselAlert. The reasoning behind this parameter: many Mastodon servers are owned and operated by individuals, and the disk storage costs, which can be substantial due to the number of images we are attaching, are often borne out of their own pockets. This is VesselAlert being social and cost-conscious, and we really appreciate your cooperation!

## Discord notifications related parameters

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `DISCORD_WEBHOOKS` | Comma separated list of Discord Webhook URLs. If omitted, no Discord Notifications will be sent. | empty | no |
| `DISCORD_NAME` | Station name. Use something descriptive of who and where you are, e.g., `kx1t - Boston Harbor` | empty | yes (if Discord notifications are enabled) |
| `DISCORD_AVATAR_URL` | URL to an avatar used with the notification message | empty | no |

## BlueSky notifications related parameters

To enable BlueSky notifications, log into your BlueSky account and then browse to <https://bsky.app/settings/app-passwords>. Once there, create a new App Password and use that in the BLUESKY_APP_PASSWORD parameter below. (It is not necessary to give the application access to your DM messages.). It should look like `BLUESKY_APP_PASSWORD=aaaa-bbbb-cccc-dddd`.

Also populate BLUESKY_HANDLE with your BlueSky Handle. This is the part after the "@" sign and it must include the BlueSky PDS, for example `BLUESKY_HANDLE=abcd.bsky.social`

The parameters `PF_BLUESKY_ENABLED` and `PA_BLUESKY_ENABLED` must be set to `on`/`enabled`/`1`/`yes` to start notifications for Planefence and Plane-Alert respectively.

If you want to post to another federated BlueSky server, you can update `BLUESKY_API`. (If you don't know what this means, then please leave this parameter empty/undefined).

If you want to stop sending notifications to BlueSky, simply remove either the `BLUESKY_APP_PASSWORD` or the `BLUESKY_HANDLE` parameter.

Please note that the length of the text in BlueSky notifications is limited to 300 characters. This may cause some notifications to be truncated.

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `BLUESKY_APP_PASSWORD` | BlueSky App Password as described above | (empty) | Yes |
| `BLUESKY_HANDLE` | BlueSky handle (incl. PDS, for example `abcd.bsky.social`.) | (empty) | Yes |
| `BLUESKY_API` | Alternative API for users who use their own PDS. (Do not set this parameter unless you know what you are doing!) | `https://bsky.social/xrpc` | No |
| `BLUESKY_LINK_AISCATCHER` ^ | If set to `on`, the BlueSky notification will include a link to the vessel on aiscatcher.org. (Set to `off`/`false`/`no`/`0` to disable) | on | no |
| `BLUESKY_LINK_SHIPXPLORER` ^ | If set to `on`, the BlueSky notification will include a link to the vessel on ShipXplorer | empty | no |
| `BLUESKY_LINK_MARINETRAFFIC` ^ | If set to `on`, the BlueSky notification will include a link to the vessel on MarineTraffic | empty | no |
| `BLUESKY_LINK_VESSELFINDER` ^ | If set to `on`, the BlueSky notification will include a link to the vessel on VesselFinder | empty | no |

## MQTT notifications related parameters

If you want to send notifications to an MQTT broker, please use the following parameters.
Note - at this time, only MQTT deliveries via the mqtt protocol are supported. This means specifically that SSL deliveries (mqtts) or WebSocket deliveries (ws:// or wss://) are not supported.

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `MQTT_URL` | MQTT broker target URL. Format: `[mqtt://][user:pass]@host[:port][/group/topic]`. If left empty, sending MQTT notifications is disabled. You can also pass in the `user`, `pass`, `port`, and `group/topic` as separate parameters, see below. Note - parameters passed in this `MQTT_URL` parameter will overrule any values defined in the parameters below. Examples:<br/>`mqtt://admin:password@192.168.0.1:1883/bostonharbor/vesselalert`, `my.mqttbroker.com:1883`, `192.168.0.1` | Empty | Yes (to enable MQTT notifications) |
| `MQTT_PORT` | TCP port of the MQTT server | 1883 | No |
| `MQTT_CLIENT_ID` | MQTT Client ID string (no whitespace please) | `$container_name` | No |
| `MQTT_TOPIC` | MQTT Topic passed to the MQTT broker | `$container_name/vesselalert` | No |
| `MQTT_DATETIME_FORMAT` | Sets the format of the date/time using Linux "date" command formatting for the "`notification:last`" and "`last_updated`" tags. Default value is "%s" (seconds since epoch). See [this link](https://www.man7.org/linux/man-pages/man1/date.1.html) for an overview of the possible formats. | seconds-since-epoch | No |
| `MQTT_QOS` | QOS value passed to the MQTT Broker | `0` | No |
| `MQTT_USERNAME` | Username passed to MQTT Broker | Empty | No |
| `MQTT_PASSWORD` | Password passed to MQTT Broker | Empty | No |

## Expert Parameters (only change/set if you know what you're doing)

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |
| `MIN_MSG_COUNT` * | The minimum number of messages that AIS-Catcher must have received before a vessel can create a notification. This is implemented to ensure that "spurious" vessels that probably have invalid information cause notifications. | `10` | no |
| `MAX_MSG_AGE` * | If a vessel hasn't been heard of for more than this amount of time (in seconds), it will be removed from the notification database | `604800` (1 week) | no |
| `CHECK_INTERVAL` * | Interval (in secs) between "runs" of the Mastodon Notifier. | `30` | no |
| `DEBUG` * | If this variable is set to any non-empty value, (a lot of) debug information will be printer to the Container Logs | empty | no |
| `PHOTOS_RETENTION` * | Expiration time, in minutes, of the cache of downloaded vessel photos. Note that the expiration timer starts counting from the last time the photo was used for a notification. If set to `0`, `disabled`, `off`, or `no`, the cache will never expire and you will need to manage the cache disk space yourself | `20160` (2 weeks) | no |
| `SCREENSHOT_RETENTION` * | Expiration time, in minutes, of the cache of latest screenshot used for notifications. (Note that for each notification, when enabled, a new [screenshot](#adding-screenshots-to-your-notifications) is retrieved. This cache is purely so the user can retrieve or check the screenshot for a short time after the notification was sent.) If set to `0`, `disabled`, `off`, or `no`, the cache will never expire and you will need to manage the cache disk space yourself | `60` (1 hour) | no |

\* You probably shouldn't change the value of these parameters unless you really know what you are doing.

## Adding screenshots to your notifications

VesselAlert has an option to add screenshots to your notifications. This is done by adding and configuring a separate screenshot container. The reason for not integrating this functionality directly into VesselAlert is that the screenshot container is large (~250 Mb) and requires a lot of system resources when running. Although this container is known to be able to run on `armhf` devices like Raspberry Pi 3B+, it will run much faster and smoother on Raspberry Pi 4 or x86 with a 64-bits OS.
The screenshot container accesses the AIS-catcher website to request a screenshot. It uses headless Chromium to make the screenshot and provide it to the requestor.
A configuration example is provided in the sample [docker-compose.yml](docker-compose.yml) file.
The screenshot container is Open Source and can be found [here](https://github.com/kx1t/browser-screenshot-service/tree/aiscatcher).

Please note that you must use the screenshot container's `aiscatcher` tag and branch as these include special configuration options for use with VesselAlert.

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Modifications of Ship Status and Ship Type descriptions

In your `opt/ais/data` directory (if you followed the volume mappings as recommended), there are two files:

- `shipstatus.db` contains the descriptions of the Ship Status for each status ID number
- `shiptype.db` contains the descriptions of the Ship Type for each type number

You can change those with a text editor. Lines that start with "#" are ignored, and you can hashtag words in the description.

## Acknowledgements

Without the help, advice, testing, and kicking the tires of these people, things wouldn't have been possible. In random order:

- [@jvde-github](https://github.com/jvde-github) for his advice and help. He's also the author of [AIS-Catcher](https://github.com/jvde-github/AIS-catcher), which is a prerequisite for this container to work
- [@wiedehopf](https://github.com/wiedehopf) for his continous help, advice, and expertise
- [@kevinelliott](https://github.com/kevinelliott) for his help during the design phase of the project, and to bounce ideas of
- [@dziban303](https://github.com/dziban303) for his help testing the early releases and providing feedback
- [@JohnEx](https://github.com/Johnex) for his ideas, research, testing, and feedback
- [@Tedder](https://github.com/tedder) who created the [original screenshot container](https://github.com/tedder/browser-screenshot-service) when we needed it for Planefence
- [@RandomRobbie](https://github.com/randomrobbie) who [motivated](https://github.com/sdr-enthusiasts/docker-planefence/issues/212) me to implement BlueSky notifications
- [@Minglarn](https://github.com/Minglarn) for help with the Swedish localization
- The engineers at AirNav who helped me understand things through their ShipXplorer project, and who provided the initial trigger for me to create this container

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-vesselalert/issues) on the project's GitHub.
I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse. The #ais-catcher channel is appropriate for conversations about this package.

## Summary of License Terms

### VesselAlert

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

### Tropo Alert Feature

The Tropo Alert feature was based on and inspired by AISTropoAlert version 1.0.0 by Jeffrey Luszcz:

```text
Copyright 2023 Jeffrey Luszcz AISTropoAlert https://github.com/jeff-luszcz/AISTropoAlert
SPDX-License-Identifier: Apache License 2.0
For license terms, see https://github.com/jeff-luszcz/AISTropoAlert/blob/1ed4837b900d7af49645ec10877046e51f82b725/LICENSE
```

All improvements on AISTropoAlert version 1.0.0 are:
Copyright (C) 2022-2023, Ramon F. Kolb (kx1t) and licenseable under GPLv3 in accordance with this summary:

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

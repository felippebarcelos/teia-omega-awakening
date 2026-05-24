# 0081 - Deforestation Solution Ideas

### USUÁRIO

me ajude, nao estou conseguind integrar a url que o aplicativo que eu comprei que torna meu celular uma webcam com url http para integrar no plugin do homebridge camera ui
Loading logs using native method...
File: /Users/felippebarcelos/.homebridge/homebridge.log

rt videoanalysis session..
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:07:55 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:07:55 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:07:55 PM] [CameraUI] 🌸: Restart videoanalysis session..
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:08:09 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:09 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:09 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:08:23 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:23 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:23 PM] [CameraUI] 🌸: Restart videoanalysis session..
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:08:37 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:37 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:37 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:08:52 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:52 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:08:52 PM] [CameraUI] 🌸: Restart videoanalysis session..
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:09:06 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:06 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:06 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:09:11 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /interfaceConfig
[11/23/2023, 11:09:13 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /cameras
[11/23/2023, 11:09:13 PM] [Homebridge UI] [homebridge-camera-ui] 🌸: Probe stream: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -analyzeduration 0 -probesize 5000 -i http://192.168.0.67:8200/
[11/23/2023, 11:09:13 PM] [Homebridge UI] [homebridge-camera-ui] 🌸: {"ffmpegVersion":"v2.1.1-homebridge-darwin-x86_64","probe":true,"timedout":false,"audio":[],"video":[],"bitrate":"? kb/s","mapvideo":"","mapaudio":""}
[11/23/2023, 11:09:17 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /startStream
[11/23/2023, 11:09:17 PM] [Homebridge UI] [homebridge-camera-ui] 🌸: Stream command: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -hide_banner -loglevel error -i http://192.168.0.67:8200/ -f mpegts -vcodec mpeg1video -s 1280x720 -b:v 299k -r 20 -bf 0 -preset:v ultrafast -threads 1 -an -q 1 -max_muxing_queue_size 9999 -
[11/23/2023, 11:09:17 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:09:20 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:20 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:20 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:09:35 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:35 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:35 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:09:48 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:09:49 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /startStream
[11/23/2023, 11:09:49 PM] [Homebridge UI] [homebridge-camera-ui] 🌸: Stream command: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -hide_banner -loglevel error -i http://192.168.0.67:8200/ -f mpegts -vcodec mpeg1video -s 1280x720 -b:v 299k -r 20 -bf 0 -preset:v ultrafast -threads 1 -an -q 1 -max_muxing_queue_size 9999 -
[11/23/2023, 11:09:49 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:09:49 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:49 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:09:49 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:09:55 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:09:55 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /startStream
[11/23/2023, 11:09:55 PM] [Homebridge UI] [homebridge-camera-ui] 🌸: Stream command: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -hide_banner -loglevel error -i http://192.168.0.67:8200/ -f mpegts -vcodec mpeg1video -s 1280x720 -b:v 299k -r 20 -bf 0 -preset:v ultrafast -threads 1 -an -q 1 -max_muxing_queue_size 9999 -
[11/23/2023, 11:09:55 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:10:01 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:10:03 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStreams
[11/23/2023, 11:10:03 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:03 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:03 PM] [CameraUI] 🌸: Restart videoanalysis session..
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:10:17 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:17 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:17 PM] [CameraUI] 🌸: Restart videoanalysis session..
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:10:32 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:32 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:32 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:10:32 PM] [Camera FFmpeg] [Camera da Rua] Failed to fetch snapshot.
[Camera da Rua] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:10:47 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:47 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:10:47 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:11:02 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:11:02 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:11:02 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:11:16 PM] [Homebridge UI] Changes to config.json saved.
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:11:16 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:11:16 PM] [CameraUI]  ERROR  🌸: FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input 
[11/23/2023, 11:11:16 PM] [CameraUI] 🌸: Restart videoanalysis session..
[11/23/2023, 11:11:18 PM] [Homebridge UI] Homebridge restart request received
[11/23/2023, 11:11:18 PM] [Homebridge UI] UI / Bridge settings have not changed; only restarting Homebridge process
[11/23/2023, 11:11:18 PM] [Homebridge UI] Sending SIGTERM to Homebridge
[11/23/2023, 11:11:18 PM] Got SIGTERM, shutting down Homebridge...
[11/23/2023, 11:11:18 PM] Got SIGTERM, shutting down child bridge process...
[11/23/2023, 11:11:23 PM] [HB Supervisor] Homebridge Process Ended. Code: 143, Signal: null
[11/23/2023, 11:11:28 PM] [HB Supervisor] Restarting Homebridge...
[11/23/2023, 11:11:28 PM] [HB Supervisor] Starting Homebridge with extra flags: -I
[11/23/2023, 11:11:28 PM] [HB Supervisor] Started Homebridge v1.7.0 with PID: 99808
[11/23/2023, 11:11:29 PM] Homebridge requires Node.js version of ^18.15.0 || ^20.7.0 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:11:29 PM] Loaded config.json with 0 accessories and 3 platforms.
[11/23/2023, 11:11:29 PM] Loaded 0 cached accessories from cachedAccessories.
[11/23/2023, 11:11:29 PM] ---
[11/23/2023, 11:11:32 PM] Loaded plugin: homebridge-camera-ffmpeg@3.1.4
[11/23/2023, 11:11:32 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:11:32 PM] ---
[11/23/2023, 11:11:33 PM] Loaded plugin: homebridge-camera-ui@5.0.27
[11/23/2023, 11:11:33 PM] Registering platform 'homebridge-camera-ui.CameraUI'
[11/23/2023, 11:11:33 PM] ---
[11/23/2023, 11:11:33 PM] The plugin "homebridge-config-ui-x" requires Node.js version of ^18 || ^20 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:11:33 PM] Loaded plugin: homebridge-config-ui-x@4.52.3
[11/23/2023, 11:11:33 PM] Registering platform 'homebridge-config-ui-x.config'
[11/23/2023, 11:11:33 PM] ---
[11/23/2023, 11:11:33 PM] Loading 3 platforms...
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] Initializing Camera-ffmpeg platform...
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] Initializing child bridge 0E:D0:84:38:AD:36
[11/23/2023, 11:11:33 PM] [CameraUI] Initializing CameraUI platform...
[11/23/2023, 11:11:33 PM] [CameraUI] Config changed through interface, saving...
Setup Payload:
X-HM://0024NWJGUIGGD
Enter this code with your HomeKit app on your iOS device to pair with Homebridge:
                       
    ┌────────────┐     
    │ 721-76-014 │     
    └────────────┘     
                       
[11/23/2023, 11:11:33 PM] Homebridge v1.7.0 (HAP v0.11.1) (Homebridge AEC2) is running on port 51204.
[11/23/2023, 11:11:33 PM] [CameraUI] Accessories refreshed and config.json saved!
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] Launched child bridge with PID 99812
[11/23/2023, 11:11:33 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] Loaded homebridge-camera-ffmpeg v3.1.4 child bridge successfully
[11/23/2023, 11:11:33 PM] Loaded 2 cached accessories from cachedAccessories.0ED08438AD36.
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] [Camera da Rua] Configuring cached bridged accessory...
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] [🌸] Configuring cached bridged accessory...
[11/23/2023, 11:11:33 PM] [Camera FFmpeg] Setting up localhost-only HTTP server on port 8200...
[11/23/2023, 11:11:33 PM] Homebridge v1.7.0 (HAP v0.11.1) (Camera FFmpeg) is running on port 58613.
[11/23/2023, 11:11:48 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /interfaceConfig
[11/23/2023, 11:11:49 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /cameras
(node:99808) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:12:07 PM] [CameraUI] camera.ui v5.0.27 is listening on port 8081 (http)
[11/23/2023, 11:12:07 PM] [CameraUI]  ERROR  HTTP Server: Can not start the HTTP server for motion detection! Port 8200 is already in use
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:14:59 PM] [Homebridge UI] Changes to config.json saved.
[11/23/2023, 11:15:01 PM] [Homebridge UI] Homebridge restart request received
[11/23/2023, 11:15:01 PM] [Homebridge UI] UI / Bridge settings have not changed; only restarting Homebridge process
[11/23/2023, 11:15:01 PM] [Homebridge UI] Sending SIGTERM to Homebridge
[11/23/2023, 11:15:01 PM] Got SIGTERM, shutting down Homebridge...
[11/23/2023, 11:15:01 PM] Got SIGTERM, shutting down child bridge process...
[11/23/2023, 11:15:06 PM] [HB Supervisor] Homebridge Process Ended. Code: 143, Signal: null
[11/23/2023, 11:15:11 PM] [HB Supervisor] Restarting Homebridge...
[11/23/2023, 11:15:11 PM] [HB Supervisor] Starting Homebridge with extra flags: -I
[11/23/2023, 11:15:11 PM] [HB Supervisor] Started Homebridge v1.7.0 with PID: 405
[11/23/2023, 11:15:12 PM] Homebridge requires Node.js version of ^18.15.0 || ^20.7.0 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:15:12 PM] Loaded config.json with 0 accessories and 3 platforms.
[11/23/2023, 11:15:12 PM] Loaded 0 cached accessories from cachedAccessories.
[11/23/2023, 11:15:12 PM] ---
[11/23/2023, 11:15:13 PM] Loaded plugin: homebridge-camera-ffmpeg@3.1.4
[11/23/2023, 11:15:13 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:15:13 PM] ---
[11/23/2023, 11:15:14 PM] Loaded plugin: homebridge-camera-ui@5.0.27
[11/23/2023, 11:15:14 PM] Registering platform 'homebridge-camera-ui.CameraUI'
[11/23/2023, 11:15:14 PM] ---
[11/23/2023, 11:15:14 PM] The plugin "homebridge-config-ui-x" requires Node.js version of ^18 || ^20 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:15:14 PM] Loaded plugin: homebridge-config-ui-x@4.52.3
[11/23/2023, 11:15:14 PM] Registering platform 'homebridge-config-ui-x.config'
[11/23/2023, 11:15:14 PM] ---
[11/23/2023, 11:15:14 PM] Loading 3 platforms...
[11/23/2023, 11:15:14 PM] [Camera FFmpeg] Initializing Camera-ffmpeg platform...
[11/23/2023, 11:15:14 PM] [Camera FFmpeg] Initializing child bridge 0E:D0:84:38:AD:36
[11/23/2023, 11:15:14 PM] [CameraUI] Initializing CameraUI platform...
[11/23/2023, 11:15:14 PM] [CameraUI] Config changed through interface, saving...
Setup Payload:
X-HM://0024NWJGUIGGD
Enter this code with your HomeKit app on your iOS device to pair with Homebridge:
                       
    ┌────────────┐     
    │ 721-76-014 │     
    └────────────┘     
                       
[11/23/2023, 11:15:14 PM] Homebridge v1.7.0 (HAP v0.11.1) (Homebridge AEC2) is running on port 51204.
[11/23/2023, 11:15:14 PM] [CameraUI] 🌼: Configuring unbridged accessory...
[11/23/2023, 11:15:14 PM] [CameraUI] 🌼: Setting up accessory...
[11/23/2023, 11:15:15 PM] [CameraUI] Accessories refreshed and config.json saved!
[11/23/2023, 11:15:15 PM] 🌼 64DB is running on port 49953.
[11/23/2023, 11:15:15 PM] Please add [🌼 64DB] manually in Home app. Setup Code: 721-76-014
[11/23/2023, 11:15:15 PM] [Camera FFmpeg] Launched child bridge with PID 409
[11/23/2023, 11:15:15 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:15:15 PM] [Camera FFmpeg] Loaded homebridge-camera-ffmpeg v3.1.4 child bridge successfully
[11/23/2023, 11:15:15 PM] Loaded 2 cached accessories from cachedAccessories.0ED08438AD36.
[11/23/2023, 11:15:15 PM] [Camera FFmpeg] [Camera da Rua] Configuring cached bridged accessory...
[11/23/2023, 11:15:15 PM] [Camera FFmpeg] [🌸] Configuring cached bridged accessory...
[11/23/2023, 11:15:15 PM] [Camera FFmpeg] Setting up localhost-only HTTP server on port 8200...
[11/23/2023, 11:15:15 PM] Homebridge v1.7.0 (HAP v0.11.1) (Camera FFmpeg) is running on port 58613.
(node:405) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:15:46 PM] [CameraUI] 🌼: Setting up camera, please be patient...
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:15:46 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:15:46 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:15:56 PM] [CameraUI] camera.ui v5.0.27 is listening on port 8081 (http)
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:15:57 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:15:57 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:16:07 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:16:07 PM] [CameraUI] 🌼: Restart prebuffer session..
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:16:18 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:16:18 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:16:28 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:16:28 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:16:39 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:16:39 PM] [CameraUI] 🌼: Restart prebuffer session..
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:17:00 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:17:00 PM] [CameraUI] 🌼: Restart prebuffer session..
[Camera da Rua] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:17:07 PM] [Camera FFmpeg] [Camera da Rua] Fetching snapshot took 10.991 seconds. It is highly recommended you switch to unbridge mode.
[11/23/2023, 11:17:14 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:17:14 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:17:28 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:17:28 PM] [CameraUI] 🌼: Restart prebuffer session..
[🌸] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:17:43 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:17:43 PM] [CameraUI] 🌼: Restart prebuffer session..
[🌸] The image snapshot handler for the given accessory didn't respond at all! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:17:48 PM] [Homebridge UI] Changes to config.json saved.
[11/23/2023, 11:17:50 PM] [Homebridge UI] Homebridge restart request received
[11/23/2023, 11:17:51 PM] [Homebridge UI] UI / Bridge settings have not changed; only restarting Homebridge process
[11/23/2023, 11:17:51 PM] [Homebridge UI] Sending SIGTERM to Homebridge
[11/23/2023, 11:17:51 PM] Got SIGTERM, shutting down Homebridge...
[11/23/2023, 11:17:51 PM] Got SIGTERM, shutting down child bridge process...
[Camera da Rua] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:17:56 PM] [HB Supervisor] Homebridge Process Ended. Code: 143, Signal: null
[11/23/2023, 11:18:01 PM] [HB Supervisor] Restarting Homebridge...
[11/23/2023, 11:18:01 PM] [HB Supervisor] Starting Homebridge with extra flags: -I
[11/23/2023, 11:18:01 PM] [HB Supervisor] Started Homebridge v1.7.0 with PID: 694
[11/23/2023, 11:18:03 PM] Homebridge requires Node.js version of ^18.15.0 || ^20.7.0 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:18:03 PM] Loaded config.json with 0 accessories and 3 platforms.
[11/23/2023, 11:18:03 PM] Loaded 0 cached accessories from cachedAccessories.
[11/23/2023, 11:18:03 PM] ---
[11/23/2023, 11:18:05 PM] Loaded plugin: homebridge-camera-ffmpeg@3.1.4
[11/23/2023, 11:18:05 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:18:05 PM] ---
[11/23/2023, 11:18:08 PM] Loaded plugin: homebridge-camera-ui@5.0.27
[11/23/2023, 11:18:08 PM] Registering platform 'homebridge-camera-ui.CameraUI'
[11/23/2023, 11:18:08 PM] ---
[11/23/2023, 11:18:08 PM] The plugin "homebridge-config-ui-x" requires Node.js version of ^18 || ^20 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:18:08 PM] Loaded plugin: homebridge-config-ui-x@4.52.3
[11/23/2023, 11:18:08 PM] Registering platform 'homebridge-config-ui-x.config'
[11/23/2023, 11:18:08 PM] ---
[11/23/2023, 11:18:08 PM] Loading 3 platforms...
[11/23/2023, 11:18:08 PM] [Camera FFmpeg] Initializing Camera-ffmpeg platform...
[11/23/2023, 11:18:08 PM] [Camera FFmpeg] Initializing child bridge 0E:D0:84:38:AD:36
[11/23/2023, 11:18:08 PM] [CameraUI] Initializing CameraUI platform...
[11/23/2023, 11:18:08 PM] [CameraUI] Config changed through interface, saving...
Setup Payload:
X-HM://0024NWJGUIGGD
Enter this code with your HomeKit app on your iOS device to pair with Homebridge:
                       
    ┌────────────┐     
    │ 721-76-014 │     
    └────────────┘     
                       
[11/23/2023, 11:18:08 PM] Homebridge v1.7.0 (HAP v0.11.1) (Homebridge AEC2) is running on port 51204.
[11/23/2023, 11:18:08 PM] [CameraUI] 🌼: Configuring unbridged accessory...
[11/23/2023, 11:18:08 PM] [CameraUI] 🌼: Setting up accessory...
[11/23/2023, 11:18:09 PM] [CameraUI] Accessories refreshed and config.json saved!
[11/23/2023, 11:18:09 PM] 🌼 64DB is running on port 50140.
[11/23/2023, 11:18:09 PM] Please add [🌼 64DB] manually in Home app. Setup Code: 721-76-014
[11/23/2023, 11:18:09 PM] [Camera FFmpeg] Launched child bridge with PID 705
[11/23/2023, 11:18:09 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:18:09 PM] [Camera FFmpeg] Loaded homebridge-camera-ffmpeg v3.1.4 child bridge successfully
[11/23/2023, 11:18:09 PM] Loaded 2 cached accessories from cachedAccessories.0ED08438AD36.
[11/23/2023, 11:18:09 PM] [Camera FFmpeg] [Camera da Rua] Configuring cached bridged accessory...
[11/23/2023, 11:18:09 PM] [Camera FFmpeg] [🌸] Configuring cached bridged accessory...
[11/23/2023, 11:18:09 PM] [Camera FFmpeg] Setting up localhost-only HTTP server on port 8200...
[11/23/2023, 11:18:09 PM] Homebridge v1.7.0 (HAP v0.11.1) (Camera FFmpeg) is running on port 58613.
(node:694) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
[11/23/2023, 11:18:25 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[Camera da Rua] The image snapshot handler for the given accessory is slow to respond! See https://homebridge.io/w/JtMGR for more info.
[11/23/2023, 11:18:35 PM] [Camera FFmpeg] [Camera da Rua] Fetching snapshot took 9.606 seconds. It is highly recommended you switch to unbridge mode.
[11/23/2023, 11:18:49 PM] [CameraUI] 🌼: Setting up camera, please be patient...
[11/23/2023, 11:18:50 PM] [Camera FFmpeg] [🌸] Starting video stream: 1920 x 1080, 30 fps, 802 kbps (AAC-eld)
[11/23/2023, 11:18:51 PM] [Camera FFmpeg] [🌸] FFmpeg exited with code: 1 and signal: null (Error)
[11/23/2023, 11:18:51 PM] [Camera FFmpeg] [🌸] Stopped video stream.
[11/23/2023, 11:18:54 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:18:54 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:04 PM] [CameraUI] camera.ui v5.0.27 is listening on port 8081 (http)
[11/23/2023, 11:19:04 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:04 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:17 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:17 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:27 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:27 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:38 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:38 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:48 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:48 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:19:53 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:19:53 PM] [Camera FFmpeg] [Camera da Rua] Starting video stream: 1920 x 1080, native fps, 802 kbps (AAC-eld)
[11/23/2023, 11:19:53 PM] [Camera FFmpeg] [Camera da Rua] Stopped video stream.
[11/23/2023, 11:19:54 PM] [Camera FFmpeg] [Camera da Rua] FFmpeg exited with code: 1 and signal: null (Error)
[11/23/2023, 11:19:54 PM] [Camera FFmpeg] [Camera da Rua] Stopped video stream.
[11/23/2023, 11:19:58 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:19:58 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:08 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:08 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:13 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:20:18 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:18 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:29 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:29 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:39 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:39 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:43 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:20:49 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:49 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:20:59 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:20:59 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:09 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:21:09 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:19 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:21:19 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:25 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:21:30 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:21:30 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:40 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /interfaceConfig
[11/23/2023, 11:21:40 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:21:40 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:43 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /cameras
[11/23/2023, 11:21:43 PM] [Homebridge UI] [homebridge-camera-ui] 🌼: Probe stream: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -analyzeduration 0 -probesize 5000 -i http://192.168.0.67:8200/
[11/23/2023, 11:21:43 PM] [Homebridge UI] [homebridge-camera-ui] 🌼: {"ffmpegVersion":"v2.1.1-homebridge-darwin-x86_64","probe":true,"timedout":false,"audio":[],"video":[],"bitrate":"? kb/s","mapvideo":"","mapaudio":""}
[11/23/2023, 11:21:46 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /startStream
[11/23/2023, 11:21:46 PM] [Homebridge UI] [homebridge-camera-ui] 🌼: Stream command: /usr/local/lib/node_modules/homebridge-camera-ui/node_modules/ffmpeg-for-homebridge/ffmpeg -hide_banner -loglevel error -rtsp_transport http -i http://192.168.0.67:8200/ -f mpegts -vcodec mpeg1video -s 1280x720 -b:v 299k -r 20 -bf 0 -preset:v ultrafast -threads 1 -an -q 1 -max_muxing_queue_size 9999 -
[11/23/2023, 11:21:46 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStream
[11/23/2023, 11:21:50 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:21:50 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:21:53 PM] [Homebridge UI] [homebridge-camera-ui] Incoming Request: /stopStreams
[11/23/2023, 11:22:00 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:00 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:22:11 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:11 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:22:16 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:22:21 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:21 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:22:32 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:32 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:22:42 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:42 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:22:52 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:22:52 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:02 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:02 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:12 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:12 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:16 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:23:23 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:23 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:33 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:33 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:43 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:43 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:23:54 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:23:54 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:24:04 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:24:04 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:24:08 PM] [Homebridge UI] Changes to config.json saved.
[11/23/2023, 11:24:10 PM] [Homebridge UI] Homebridge restart request received
[11/23/2023, 11:24:10 PM] [Homebridge UI] UI / Bridge settings have not changed; only restarting Homebridge process
[11/23/2023, 11:24:10 PM] [Homebridge UI] Sending SIGTERM to Homebridge
[11/23/2023, 11:24:10 PM] Got SIGTERM, shutting down Homebridge...
[11/23/2023, 11:24:10 PM] Got SIGTERM, shutting down child bridge process...
[11/23/2023, 11:24:14 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input - 
[11/23/2023, 11:24:14 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:24:15 PM] [HB Supervisor] Homebridge Process Ended. Code: 143, Signal: null
[11/23/2023, 11:24:20 PM] [HB Supervisor] Restarting Homebridge...
[11/23/2023, 11:24:20 PM] [HB Supervisor] Starting Homebridge with extra flags: -I
[11/23/2023, 11:24:20 PM] [HB Supervisor] Started Homebridge v1.7.0 with PID: 1339
[11/23/2023, 11:24:23 PM] Homebridge requires Node.js version of ^18.15.0 || ^20.7.0 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:24:23 PM] Loaded config.json with 0 accessories and 3 platforms.
[11/23/2023, 11:24:23 PM] Loaded 0 cached accessories from cachedAccessories.
[11/23/2023, 11:24:23 PM] ---
[11/23/2023, 11:24:25 PM] Loaded plugin: homebridge-camera-ffmpeg@3.1.4
[11/23/2023, 11:24:25 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:24:25 PM] ---
[11/23/2023, 11:24:26 PM] Loaded plugin: homebridge-camera-ui@5.0.27
[11/23/2023, 11:24:26 PM] Registering platform 'homebridge-camera-ui.CameraUI'
[11/23/2023, 11:24:26 PM] ---
[11/23/2023, 11:24:26 PM] The plugin "homebridge-config-ui-x" requires Node.js version of ^18 || ^20 which does not satisfy the current Node.js version of v21.1.0. You may need to upgrade your installation of Node.js - see https://homebridge.io/w/JTKEF
[11/23/2023, 11:24:26 PM] Loaded plugin: homebridge-config-ui-x@4.52.3
[11/23/2023, 11:24:26 PM] Registering platform 'homebridge-config-ui-x.config'
[11/23/2023, 11:24:26 PM] ---
[11/23/2023, 11:24:26 PM] Loading 3 platforms...
[11/23/2023, 11:24:26 PM] [Camera FFmpeg] Initializing Camera-ffmpeg platform...
[11/23/2023, 11:24:26 PM] [Camera FFmpeg] Initializing child bridge 0E:D0:84:38:AD:36
[11/23/2023, 11:24:26 PM] [CameraUI] Initializing CameraUI platform...
[11/23/2023, 11:24:26 PM] [CameraUI] Config changed through interface, saving...
Setup Payload:
X-HM://0024NWJGUIGGD
Enter this code with your HomeKit app on your iOS device to pair with Homebridge:
                       
    ┌────────────┐     
    │ 721-76-014 │     
    └────────────┘     
                       
[11/23/2023, 11:24:26 PM] Homebridge v1.7.0 (HAP v0.11.1) (Homebridge AEC2) is running on port 51204.
[11/23/2023, 11:24:26 PM] [CameraUI] 🌼: Configuring unbridged accessory...
[11/23/2023, 11:24:26 PM] [CameraUI] 🌼: Setting up accessory...
[11/23/2023, 11:24:27 PM] [CameraUI] Accessories refreshed and config.json saved!
[11/23/2023, 11:24:27 PM] 🌼 64DB is running on port 50659.
[11/23/2023, 11:24:27 PM] Please add [🌼 64DB] manually in Home app. Setup Code: 721-76-014
[11/23/2023, 11:24:27 PM] [Camera FFmpeg] Launched child bridge with PID 1344
[11/23/2023, 11:24:27 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:24:27 PM] [Camera FFmpeg] Loaded homebridge-camera-ffmpeg v3.1.4 child bridge successfully
[11/23/2023, 11:24:27 PM] Loaded 2 cached accessories from cachedAccessories.0ED08438AD36.
[11/23/2023, 11:24:27 PM] [Camera FFmpeg] [Camera da Rua] Configuring cached bridged accessory...
[11/23/2023, 11:24:27 PM] [Camera FFmpeg] [🌸] Configuring cached bridged accessory...
[11/23/2023, 11:24:27 PM] [Camera FFmpeg] Setting up localhost-only HTTP server on port 8200...
[11/23/2023, 11:24:27 PM] Homebridge v1.7.0 (HAP v0.11.1) (Camera FFmpeg) is running on port 58613.
(node:1339) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
[11/23/2023, 11:24:31 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:24:43 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:25:03 PM] [CameraUI] 🌼: Setting up camera, please be patient...
[11/23/2023, 11:25:03 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:25:03 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/video: Invalid data found when processing input - 
[11/23/2023, 11:25:03 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:25:13 PM] [CameraUI]  ERROR  Interface: Can not start the User Interface! Port 8200 is already in use
[11/23/2023, 11:25:13 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/video: Invalid data found when processing input - 
[11/23/2023, 11:25:13 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:25:24 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/video: Invalid data found when processing input - 
[11/23/2023, 11:25:24 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:25:34 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:25:34 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/video: Invalid data found when processing input - 
[11/23/2023, 11:25:34 PM] [CameraUI] 🌼: Restart prebuffer session..
[11/23/2023, 11:25:44 PM] [CameraUI]  ERROR  🌼: FFmpeg prebuffer process exited with error! (null) - http://192.168.0.67:8200/video: Invalid data found when processing input - 
[11/23/2023, 11:25:44 PM] [CameraUI] 🌼: Restart prebuffer session..


---

### ASSISTENTE

Parece que você está enfrentando alguns problemas com a integração de uma câmera HTTP com o plugin Homebridge Camera UI. A partir dos logs que você compartilhou, posso identificar alguns pontos-chave que podem estar causando os erros:

1. **Problemas com o FFmpeg**: Os erros repetidos `FFmpeg videoanalysis process exited with error! (null) - http://192.168.0.67:8200/: Invalid data found when processing input` indicam que o FFmpeg (o programa usado pelo Homebridge para processar o vídeo da câmera) está tendo problemas para interpretar os dados recebidos da câmera. Isso pode ser devido a uma configuração incorreta ou incompatibilidade entre o formato de vídeo da câmera e o que o FFmpeg espera.

2. **Porta já em uso**: A mensagem `ERROR HTTP Server: Can not start the HTTP server for motion detection! Port 8200 is already in use` sugere que a porta 8200, que você está tentando usar, já está sendo utilizada por outro processo. Isso pode impedir que o servidor do Homebridge inicie corretamente.

3. **Versão do Node.js**: O log indica `Homebridge requires Node.js version of ^18.15.0 || ^20.7.0 which does not satisfy the current Node.js version of v21.1.0`. Isso significa que a versão do Node.js que você está usando não é compatível com a versão requerida pelo Homebridge.

Para solucionar esses problemas, você pode tentar o seguinte:

- **Verifique a Configuração da Câmera**: Certifique-se de que a câmera está configurada corretamente e transmitindo em um formato compatível com o FFmpeg. Isso pode incluir ajustes nas configurações de vídeo da câmera.

- **Alterar a Porta**: Tente mudar a porta usada pelo Homebridge para uma que não esteja em uso. Isso pode ser feito no arquivo de configuração do Homebridge.

- **Atualizar ou Reverter o Node.js**: Verifique se a versão do Node.js é compatível com o Homebridge. Se necessário, atualize para uma versão compatível ou reverta para uma versão anterior que seja compatível.

- **Reinstalar o FFmpeg**: Em alguns casos, reinstalar ou atualizar o FFmpeg pode resolver problemas de compatibilidade.

- **Consultar Documentação ou Fóruns**: Consulte a documentação do Homebridge e fóruns de discussão para casos semelhantes. Muitas vezes, problemas comuns têm soluções já documentadas pela comunidade.

Se precisar de mais ajuda com algum desses passos ou se tiver mais informações sobre a configuração da câmera ou do sistema, fique à vontade para compartilhar!

---

### USUÁRIO

[11/23/2023, 11:34:40 PM] Registering platform 'homebridge-camera-ffmpeg.Camera-ffmpeg'
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] Loaded homebridge-camera-ffmpeg v3.1.4 child bridge successfully
[11/23/2023, 11:34:40 PM] Loaded 2 cached accessories from cachedAccessories.0ED08438AD36.
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] [Camera da Rua] Configuring cached bridged accessory...
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] [🌸] Configuring cached bridged accessory...
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] [🏠] Configuring bridged accessory...
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] Setting up localhost-only HTTP server on port 8200...
[11/23/2023, 11:34:40 PM] [Camera FFmpeg] [Camera da Rua] Removing bridged accessory...
[11/23/2023, 11:34:40 PM] Homebridge v1.7.0 (HAP v0.11.1) (Camera FFmpeg) is running on port 58613.
[11/23/2023, 11:34:43 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:34:54 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!
[11/23/2023, 11:35:04 PM] [Camera FFmpeg] [🌸] Failed to fetch snapshot.
[🌸] Snapshot request handler provided empty image buffer!


---

### ASSISTENTE

Os logs mais recentes que você compartilhou indicam que o Homebridge está enfrentando problemas específicos com a captura de snapshots pela câmera configurada com o plugin Camera FFmpeg. Aqui estão algumas sugestões para solucionar esses problemas:

1. **Falha ao Capturar Snapshots**: As mensagens `[🌸] Failed to fetch snapshot. Snapshot request handler provided empty image buffer!` indicam que o Homebridge está tendo dificuldades para obter imagens estáticas (snapshots) da câmera. Isso pode ser devido a uma incompatibilidade entre o formato do snapshot fornecido pela câmera e o esperado pelo Homebridge ou por problemas de conectividade.

2. **Remoção de Acessório**: O log `[Camera FFmpeg] [Camera da Rua] Removing bridged accessory...` sugere que uma câmera foi removida da configuração do Homebridge. Se isso não foi intencional, verifique sua configuração para garantir que todas as câmeras estejam corretamente configuradas.

Para resolver esses problemas, você pode tentar as seguintes abordagens:

- **Revisar Configurações da Câmera**: Verifique as configurações da câmera no arquivo de configuração do Homebridge. Certifique-se de que o URL do snapshot, as credenciais (se necessário), e outros parâmetros estejam corretos.

- **Testar URL do Snapshot**: Tente acessar o URL do snapshot diretamente em um navegador ou usando uma ferramenta como cURL para garantir que a câmera esteja fornecendo as imagens corretamente.

- **Verificar Conectividade**: Certifique-se de que o Homebridge tem acesso à rede e que não há problemas de firewall ou roteador que possam estar bloqueando a comunicação com a câmera.

- **Consultar Logs Detalhados**: Se possível, habilite logs mais detalhados para o plugin Camera FFmpeg para obter mais informações sobre o que pode estar causando o problema.

- **Atualizar o Plugin**: Verifique se há atualizações disponíveis para o plugin Camera FFmpeg que possam resolver problemas conhecidos.

- **Reiniciar o Homebridge**: Às vezes, simplesmente reiniciar o serviço Homebridge pode resolver problemas temporários de conectividade ou configuração.

Se você continuar enfrentando problemas, compartilhar detalhes adicionais sobre a configuração da câmera ou quaisquer outras mudanças recentes no sistema pode ajudar a identificar a causa raiz do problema.

---

### USUÁRIO

ao abrir o link http da webcam do meu iphone apareceu essa pagina:
Super NetCam
📽 Video (HTML)
/video
Watch a live video stream designed for web browsers. Includes camera settings if remote control is enabled in the app

📽 Video (MJPEG)
/video.mjpeg
Watch a live MJPEG video stream designed for use with Octoprint, OBS, IP camera viewers, and similar

📸 Take photo
/photo.jpg
Take a photo at the maximum camera resolution and quality. Fires the device flash if present and enabled

🎞 Capture frame
/frame.jpg
Capture the most recent live video frame, using the specified resolution and stream quality
qual eu escolho

---

### ASSISTENTE

Para integrar a webcam do seu iPhone com o Homebridge usando o plugin Camera FFmpeg, você deve escolher a URL que melhor se adequa ao formato esperado pelo Homebridge e que forneça a melhor qualidade e compatibilidade. Aqui estão as opções que você listou e uma breve explicação sobre cada uma:

1. **Video (HTML) - `/video`**: Esta opção fornece um stream de vídeo ao vivo projetado para navegadores da web. Se o Homebridge e o plugin Camera FFmpeg suportarem esse formato, pode ser uma boa escolha, especialmente se houver configurações adicionais de câmera disponíveis.

2. **Video (MJPEG) - `/video.mjpeg`**: MJPEG é um formato de vídeo comum usado em muitos sistemas de câmeras IP e pode ser uma boa opção para integração com o Homebridge. Esta opção é projetada para trabalhar com sistemas como Octoprint e OBS, o que sugere boa compatibilidade.

3. **Take photo - `/photo.jpg`**: Esta URL tira uma foto com a máxima resolução e qualidade da câmera. Embora forneça imagens de alta qualidade, não é um stream de vídeo, então é mais adequada para capturar imagens estáticas (snapshots) do que para vídeo ao vivo.

4. **Capture frame - `/frame.jpg`**: Esta opção captura o frame mais recente do vídeo ao vivo, usando a resolução e qualidade especificadas. Pode ser uma boa opção para snapshots se você quiser uma imagem do que está acontecendo em tempo real, mas novamente, não é um stream de vídeo contínuo.

Para a integração com o Homebridge, você provavelmente desejará usar as opções de vídeo, e eu recomendaria começar com o **Video (MJPEG) - `/video.mjpeg`**. Este formato tende a ser mais compatível com diversos sistemas e plugins, incluindo o Camera FFmpeg.

Depois de escolher a URL, você precisará configurá-la no arquivo de configuração do Homebridge para a sua câmera. Lembre-se de que pode ser necessário ajustar outras configurações para garantir a compatibilidade e a melhor qualidade possível.

---


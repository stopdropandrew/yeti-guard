# yeti-guard

Keeps a preferred microphone (default: anything named "Yeti") as the macOS default input device.

macOS switches the default mic to AirPods (or any new headset) whenever they connect. `yeti-guard` is a tiny
CoreAudio listener that notices the change and immediately switches back — as long as the preferred mic is
plugged in. If it's not connected, it does nothing and macOS behaves normally.

- Event-driven (CoreAudio property listeners), no polling, ~0 CPU
- Re-checks 1.5s after each event, since macOS sometimes reassigns the default late
- Only touches input; output still follows your AirPods

## Install

Requires Xcode command line tools (`swiftc`).

```sh
make install                 # matches devices containing "Yeti"
make install MATCH="Shure"   # or any other substring of the device name
```

This builds the binary to `~/.local/bin/yeti-guard` and loads a LaunchAgent so it runs at login.

## Use

```sh
make logs       # tail ~/Library/Logs/yeti-guard.log
make restart
make uninstall
```

Device names can be listed with `system_profiler SPAudioDataType`.

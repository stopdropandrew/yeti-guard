// yeti-guard: keep the Yeti as the default input device whenever it's connected.
// Listens for CoreAudio default-input and device-list changes (no polling).
import CoreAudio
import Foundation

let match = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Yeti"
let system = AudioObjectID(kAudioObjectSystemObject)

func addr(_ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func log(_ s: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("\(ts) \(s)"); fflush(stdout)
}

func name(_ id: AudioObjectID) -> String {
    var a = addr(kAudioObjectPropertyName)
    var n: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(id, &a, 0, nil, &size, &n) == noErr, let n else { return "?" }
    return n.takeRetainedValue() as String
}

func hasInput(_ id: AudioObjectID) -> Bool {
    var a = addr(kAudioDevicePropertyStreams, kAudioObjectPropertyScopeInput)
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr && size > 0
}

func devices() -> [AudioObjectID] {
    var a = addr(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &a, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &a, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}

func defaultInput() -> AudioObjectID {
    var a = addr(kAudioHardwarePropertyDefaultInputDevice)
    var id = AudioObjectID(0)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    AudioObjectGetPropertyData(system, &a, 0, nil, &size, &id)
    return id
}

func enforce() {
    guard let yeti = devices().first(where: { hasInput($0) && name($0).localizedCaseInsensitiveContains(match) }) else { return }
    let current = defaultInput()
    guard current != yeti else { return }
    var a = addr(kAudioHardwarePropertyDefaultInputDevice)
    var id = yeti
    let err = AudioObjectSetPropertyData(system, &a, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &id)
    log(err == noErr ? "switched input: \(name(current)) -> \(name(yeti))" : "failed to set \(name(yeti)): \(err)")
}

// Coalesce bursts of notifications (AirPods connecting fires several), and
// re-check shortly after since macOS sometimes reassigns the default late.
var pending: DispatchWorkItem?
func schedule() {
    pending?.cancel()
    let work = DispatchWorkItem { enforce(); DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: enforce) }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
}

for sel in [kAudioHardwarePropertyDefaultInputDevice, kAudioHardwarePropertyDevices] {
    var a = addr(sel)
    AudioObjectAddPropertyListenerBlock(system, &a, DispatchQueue.main) { _, _ in schedule() }
}

log("yeti-guard watching for input devices matching \"\(match)\"")
enforce()
dispatchMain()

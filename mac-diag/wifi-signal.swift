// Prints Wi-Fi RSSI, noise, tx rate and channel for the default interface.
// Reads local CoreWLAN state only; no scan, no network traffic.
import CoreWLAN
guard let i = CWWiFiClient.shared().interface() else { print("wifi: no interface"); exit(0) }
let name = i.interfaceName ?? "?"
guard i.powerOn() else { print("wifi: \(name) power off"); exit(0) }
let ch = i.wlanChannel().map { "\($0.channelNumber)" } ?? "?"
print("wifi: \(name) rssi=\(i.rssiValue()) dBm noise=\(i.noiseMeasurement()) dBm snr=\(i.rssiValue() - i.noiseMeasurement()) dB tx=\(Int(i.transmitRate())) Mbps channel=\(ch)")

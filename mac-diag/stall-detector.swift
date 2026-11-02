// stall-detector: wakes four times a second and records each wake-up that comes late.
//
//   stall-detector <dir>     appends to <dir>/stalls-YYYY-MM-DD.log
//
// A wake-up delayed by more than `threshold` means this process could not run for
// that long: the symptom of the freezes, when the pointer stopped for seconds at a
// time. Time is measured on CLOCK_UPTIME_RAW, which stops while the Mac sleeps, so
// sleep never counts as a stall. Each line records when the stall began and how long
// it lasted. A "started" line marks each launch.
//
// A freeze that ends in a forced restart or a panic never lets the detector wake to
// record it. So every 10 s it also overwrites <dir>/stall-detector.alive with the
// time, synced to disk, and on the next launch the "started" line reports when the
// previous run was last alive: within 10 s of when such a freeze began.
import Foundation

let threshold = 0.5      // seconds late before a wake-up is recorded
let interval: UInt32 = 250_000     // microseconds

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: stall-detector <dir>\n".data(using: .utf8)!)
    exit(2)
}
let dir = CommandLine.arguments[1]

// Run at the highest QoS so that timer coalescing and background throttling don't
// delay the wake-ups and pass for stalls.
pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0)

let stamp = DateFormatter()
stamp.locale = Locale(identifier: "en_US_POSIX")
stamp.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
let day = DateFormatter()
day.locale = Locale(identifier: "en_US_POSIX")
day.dateFormat = "yyyy-MM-dd"

func record(_ line: String, at date: Date) {
    let path = "\(dir)/stalls-\(day.string(from: date)).log"
    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    guard let fh = FileHandle(forWritingAtPath: path) else { return }
    fh.seekToEndOfFile()
    fh.write("\(stamp.string(from: date)) \(line)\n".data(using: .utf8)!)
    fh.closeFile()
}

func uptime() -> Double { Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW)) / 1e9 }

let alivePath = "\(dir)/stall-detector.alive"

func markAlive() {
    FileManager.default.createFile(atPath: alivePath, contents: stamp.string(from: Date()).data(using: .utf8))
    if let fh = FileHandle(forWritingAtPath: alivePath) {
        fh.synchronizeFile()
        fh.closeFile()
    }
}

let previous = (try? String(contentsOfFile: alivePath, encoding: .utf8))?
    .trimmingCharacters(in: .whitespacesAndNewlines)
record("started (threshold \(threshold)s; previous run last alive \(previous ?? "unknown"))", at: Date())
markAlive()
var lastAlive = uptime()
while true {
    let before = uptime()
    usleep(interval)
    let late = uptime() - before - Double(interval) / 1e6
    if late > threshold {
        let now = Date()
        let began = now.addingTimeInterval(-late)
        record(String(format: "stall %.2fs", late), at: began)
    }
    if uptime() - lastAlive >= 10 {
        markAlive()
        lastAlive = uptime()
    }
}

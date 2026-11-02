// stall-detector: records moments when this Mac stops responding.
//
//   stall-detector <dir>     appends to <dir>/stalls-YYYY-MM-DD.log
//
// Two checks, each recording when the problem began and how long it lasted:
//
// - CPU stalls ("stall 2.18s"). The main thread wakes four times a second; a wake-up
//   delayed by more than `threshold` means this process could not run for that long.
//
// - WindowServer stalls ("windowserver 1.40s"). A second thread asks WindowServer for
//   the session dictionary once a second, a round trip of about 0.1 ms. A blocked
//   WindowServer freezes the pointer and gives the spinning cursor while everything
//   else keeps running, so the CPU check alone would miss it. A request outstanding
//   for more than `notResponding` is recorded straight away as "windowserver not
//   responding", in case it never returns.
//
// Time is measured on CLOCK_UPTIME_RAW, which stops while the Mac sleeps, so sleep
// never counts as a stall. A "started" line marks each launch.
//
// A freeze that ends in a forced restart or a panic never lets the detector record
// it. So every 10 s it also overwrites <dir>/stall-detector.alive with the time,
// synced to disk, and on the next launch the "started" line reports when the
// previous run was last alive: within 10 s of when such a freeze began.
import CoreGraphics
import Foundation

let threshold = 0.5               // seconds late before a stall is recorded
let notResponding = 2.0           // seconds a WindowServer request may take before it is reported unfinished
let interval: UInt32 = 250_000    // microseconds between CPU checks
let probeInterval: UInt32 = 1_000_000

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
let lock = NSLock()               // both threads record, and DateFormatter isn't thread-safe

func uptime() -> Double { Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW)) / 1e9 }

// The wall-clock time at which an uptime reading was taken.
func date(atUptime u: Double) -> Date { Date().addingTimeInterval(u - uptime()) }

func record(_ line: String, at date: Date) {
    lock.lock()
    defer { lock.unlock() }
    let path = "\(dir)/stalls-\(day.string(from: date)).log"
    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    guard let fh = FileHandle(forWritingAtPath: path) else { return }
    fh.seekToEndOfFile()
    fh.write("\(stamp.string(from: date)) \(line)\n".data(using: .utf8)!)
    fh.closeFile()
}

let alivePath = "\(dir)/stall-detector.alive"

func markAlive() {
    lock.lock()
    let now = stamp.string(from: Date())
    lock.unlock()
    FileManager.default.createFile(atPath: alivePath, contents: now.data(using: .utf8))
    if let fh = FileHandle(forWritingAtPath: alivePath) {
        fh.synchronizeFile()
        fh.closeFile()
    }
}

// When the WindowServer request now in flight was sent (uptime), or 0 if none is.
// Read by the main thread, so it can report a request that never comes back.
var probeSentAt = 0.0
var probeReported = false

func probeWindowServer() {
    pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0)
    while true {
        let sent = uptime()
        lock.lock(); probeSentAt = sent; probeReported = false; lock.unlock()
        _ = CGSessionCopyCurrentDictionary()
        let took = uptime() - sent
        lock.lock(); probeSentAt = 0; lock.unlock()
        if took > threshold {
            record(String(format: "windowserver %.2fs", took), at: date(atUptime: sent))
        }
        usleep(probeInterval)
    }
}

let previous = (try? String(contentsOfFile: alivePath, encoding: .utf8))?
    .trimmingCharacters(in: .whitespacesAndNewlines)
record("started (threshold \(threshold)s; previous run last alive \(previous ?? "unknown"))", at: Date())
markAlive()
Thread.detachNewThread(probeWindowServer)

var lastAlive = uptime()
while true {
    let before = uptime()
    usleep(interval)
    let now = uptime()
    let late = now - before - Double(interval) / 1e6
    if late > threshold {
        record(String(format: "stall %.2fs", late), at: date(atUptime: now - late))
    }

    lock.lock()
    let sent = probeSentAt
    let report = sent > 0 && !probeReported && now - sent > notResponding
    if report { probeReported = true }
    lock.unlock()
    if report {
        record(String(format: "windowserver not responding (no reply after %.1fs)", now - sent),
               at: date(atUptime: sent))
    }

    if now - lastAlive >= 10 {
        markAlive()
        lastAlive = uptime()
    }
}

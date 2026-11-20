import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window?.close()

        let vc = MainViewController()
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 640),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.contentViewController = vc
        w.title = "Chartwell"
        w.minSize = NSSize(width: 780, height: 460)
        w.center()
        w.makeKeyAndOrderFront(nil)
        mainWindow = w
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

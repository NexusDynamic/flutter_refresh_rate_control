import Cocoa
import FlutterMacOS
import QuartzCore

public class FlutterRefreshRateControlPlugin: NSObject, FlutterPlugin {
    // A CADisplayLink, which only exists on macOS 14+
    private var displayLink: AnyObject?
    private var lastFrameInterval: CFTimeInterval?
    private let registrar: FlutterPluginRegistrar
    private static let channelName = "com.zeyus.flutter_refresh_rate_control/manage"
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
        let instance = FlutterRefreshRateControlPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "requestHighRefreshRate":
            requestHighRefreshRate(result: result)
        case "stopHighRefreshRate":
            stopHighRefreshRate(result: result)
        case "getRefreshRateInfo":
            getRefreshRateInfo(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// The screen the Flutter view is on, falling back to the main screen.
    private var screen: NSScreen? {
        return registrar.view?.window?.screen ?? NSScreen.main
    }
    
    private func requestHighRefreshRate(result: @escaping FlutterResult) {
        guard #available(macOS 14.0, *) else {
            // No display link frame rate API before macOS 14
            result(false)
            return
        }
        
        invalidateDisplayLink()
        
        // A display link from the view follows it across screens, the
        // screen one is a fallback for when there is no view yet.
        let selector = #selector(displayCallback)
        guard let link = registrar.view?.displayLink(target: self, selector: selector)
            ?? screen?.displayLink(target: self, selector: selector)
        else {
            result(FlutterError(code: "NO_DISPLAY", message: "Could not access display", details: nil))
            return
        }
        
        if let maximumFramesPerSecond = screen?.maximumFramesPerSecond {
            let rate = Float(maximumFramesPerSecond)
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: rate,
                maximum: rate,
                preferred: rate
            )
        }
        
        link.add(to: .main, forMode: .common)
        displayLink = link
        result(true)
    }
    
    private func stopHighRefreshRate(result: @escaping FlutterResult) {
        let wasEnabled = displayLink != nil
        invalidateDisplayLink()
        result(wasEnabled)
    }
    
    private func invalidateDisplayLink() {
        if #available(macOS 14.0, *) {
            (displayLink as? CADisplayLink)?.invalidate()
        }
        displayLink = nil
        lastFrameInterval = nil
    }
    
    private func getRefreshRateInfo(result: @escaping FlutterResult) {
        var info: [String: Any] = [:]
        
        if #available(macOS 12.0, *), let screen = screen {
            info["maximumFramesPerSecond"] = screen.maximumFramesPerSecond
            // Equal on fixed rate displays, a range on variable rate ones
            info["minimumRefreshInterval"] = screen.minimumRefreshInterval
            info["maximumRefreshInterval"] = screen.maximumRefreshInterval
        }
        
        info["highRefreshRateEnabled"] = displayLink != nil
        
        if #available(macOS 14.0, *), let displayLink = displayLink as? CADisplayLink {
            // Only known once the display link has fired at least once
            if let interval = lastFrameInterval, interval > 0 {
                info["currentFramesPerSecond"] = 1.0 / interval
            }
            info["duration"] = displayLink.duration
            info["timestamp"] = displayLink.timestamp
            info["targetTimestamp"] = displayLink.targetTimestamp
            info["preferredFrameRateRange"] = [
                "minimum": displayLink.preferredFrameRateRange.minimum,
                "maximum": displayLink.preferredFrameRateRange.maximum,
                "preferred": displayLink.preferredFrameRateRange.preferred
            ]
        }
        
        result(info)
    }
    
    @available(macOS 14.0, *)
    @objc private func displayCallback(_ displayLink: CADisplayLink) {
        // This callback is called on each frame
        lastFrameInterval = displayLink.targetTimestamp - displayLink.timestamp
    }
}

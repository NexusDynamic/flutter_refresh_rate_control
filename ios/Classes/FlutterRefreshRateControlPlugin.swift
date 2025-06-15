import Flutter
import UIKit

public class FlutterRefreshRateControlPlugin: NSObject, FlutterPlugin {
    private var displayLink: CADisplayLink?
    private static let channelName = "com.zeyus.flutter_refresh_rate_control/manage"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = FlutterRefreshRateControlPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
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
    
    private func requestHighRefreshRate(result: @escaping FlutterResult) {
        displayLink?.invalidate()
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayCallback))
        
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: 120,
                maximum: 120,
                preferred: 120
            )
        } else {
            displayLink?.preferredFramesPerSecond = 120
        }
        
        displayLink?.add(to: .main, forMode: .default)
        result(true)
    }
    
    private func stopHighRefreshRate(result: @escaping FlutterResult) {
        displayLink?.invalidate()
        displayLink = nil
        result(true)
    }
    
    private func getRefreshRateInfo(result: @escaping FlutterResult) {
        var info: [String: Any] = [:]
        
        if #available(iOS 10.3, *) {
            let mainScreen = UIScreen.main
            info["maximumFramesPerSecond"] = mainScreen.maximumFramesPerSecond
            
            if let displayLink = displayLink {
                info["currentFramesPerSecond"] = 1.0 / (displayLink.targetTimestamp - displayLink.timestamp)
                info["duration"] = displayLink.duration
                info["timestamp"] = displayLink.timestamp
                info["targetTimestamp"] = displayLink.targetTimestamp
                
                if #available(iOS 15.0, *) {
                    info["preferredFrameRateRange"] = [
                        "minimum": displayLink.preferredFrameRateRange.minimum,
                        "maximum": displayLink.preferredFrameRateRange.maximum,
                        "preferred": displayLink.preferredFrameRateRange.preferred
                    ]
                }
            }
        }
        
        result(info)
    }
    
    @objc private func displayCallback(_ displayLink: CADisplayLink) {
        // This callback is called on each frame
    }
}

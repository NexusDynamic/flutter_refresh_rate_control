import Flutter
import UIKit

public class FlutterRefreshRateControlPlugin: NSObject, FlutterPlugin {
    private var displayLink: CADisplayLink?
    private var lastFrameInterval: CFTimeInterval?
    private static let channelName = "com.zeyus.flutter_refresh_rate_control/manage"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = FlutterRefreshRateControlPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            getPlatformVersion(result: result)
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

    private func getPlatformVersion(result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }

    private func requestHighRefreshRate(result: @escaping FlutterResult) {
        displayLink?.invalidate()
        lastFrameInterval = nil

        let maximumFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        let link = CADisplayLink(target: self, selector: #selector(displayCallback))

        if #available(iOS 15.0, *) {
            let rate = Float(maximumFramesPerSecond)
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: rate,
                maximum: rate,
                preferred: rate
            )
        } else {
            link.preferredFramesPerSecond = maximumFramesPerSecond
        }

        link.add(to: .main, forMode: .common)
        displayLink = link
        result(true)
    }

    private func stopHighRefreshRate(result: @escaping FlutterResult) {
        displayLink?.invalidate()
        displayLink = nil
        lastFrameInterval = nil
        result(true)
    }

    private func getRefreshRateInfo(result: @escaping FlutterResult) {
        var info: [String: Any] = [:]

        info["maximumFramesPerSecond"] = UIScreen.main.maximumFramesPerSecond

        if let displayLink = displayLink {
            // Only known once the display link has fired at least once
            if let interval = lastFrameInterval, interval > 0 {
                info["currentFramesPerSecond"] = 1.0 / interval
            }
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

        result(info)
    }

    @objc private func displayCallback(_ displayLink: CADisplayLink) {
        // This callback is called on each frame
        lastFrameInterval = displayLink.targetTimestamp - displayLink.timestamp
    }
}

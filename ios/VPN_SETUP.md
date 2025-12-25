# iOS VPN Setup Guide (Freedom-style blocking)

## Overview
iOS VPN blocking requires a Network Extension target that runs separately from the main app.

## Requirements
1. **Apple Developer Account** (paid - $99/year)
2. **Xcode** on macOS
3. **Provisioning profiles** with Network Extension capability

## Steps

### 1. Add Network Extension Target
In Xcode:
1. File > New > Target
2. Select "Network Extension"
3. Choose "Packet Tunnel Provider"
4. Name it "TotalControlTunnel"

### 2. Create Entitlements
Add to both main app and extension:
```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
```

### 3. Implement PacketTunnelProvider.swift
```swift
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    // Blocked domains
    let blockedDomains = [
        "netflix.com", "youtube.com", "hulu.com",
        "disneyplus.com", "twitch.tv", "tiktok.com"
    ]

    // Allowed domains (whitelist)
    let allowedDomains = ["music.youtube.com"]

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        settings.mtu = 1500

        // DNS settings - use local filtering
        let dnsSettings = NEDNSSettings(servers: ["10.0.0.1"])
        settings.dnsSettings = dnsSettings

        // IPv4 settings
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings

        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            self.startPacketProcessing()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    private func startPacketProcessing() {
        // Read packets and filter DNS queries
        packetFlow.readPackets { packets, protocols in
            for (index, packet) in packets.enumerated() {
                if self.isDNSQuery(packet) {
                    if let domain = self.extractDomain(from: packet) {
                        if self.shouldBlock(domain) {
                            // Drop packet (don't forward)
                            continue
                        }
                    }
                }
                // Forward allowed packets
                self.packetFlow.writePackets([packet], withProtocols: [protocols[index]])
            }
            // Continue reading
            self.startPacketProcessing()
        }
    }

    private func isDNSQuery(_ packet: Data) -> Bool {
        // Check for UDP port 53
        guard packet.count > 28 else { return false }
        let destPort = (UInt16(packet[22]) << 8) | UInt16(packet[23])
        return destPort == 53
    }

    private func extractDomain(from packet: Data) -> String? {
        // Parse DNS query to extract domain name
        // Implementation details...
        return nil
    }

    private func shouldBlock(_ domain: String) -> Bool {
        let lower = domain.lowercased()

        // Whitelist check
        for allowed in allowedDomains {
            if lower.contains(allowed) { return false }
        }

        // Blacklist check
        for blocked in blockedDomains {
            if lower.contains(blocked) { return true }
        }

        return false
    }
}
```

### 4. App Group (for shared data)
Enable App Groups capability in both targets to share blocklist data.

### 5. Flutter Integration
Call NE from Flutter via MethodChannel:
```swift
// In AppDelegate.swift
let channel = FlutterMethodChannel(name: "com.rhodesai.totalcontrol/vpn", binaryMessenger: controller.binaryMessenger)
channel.setMethodCallHandler { call, result in
    switch call.method {
    case "startVpn":
        self.startVPN(result: result)
    case "stopVpn":
        self.stopVPN(result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

## Testing
1. Build and run on physical device (simulator doesn't support NE)
2. Go to Settings > VPN to see the profile
3. Toggle VPN and test blocked sites

## Notes
- iOS only allows ONE VPN at a time
- Users can disable the VPN from Settings at any time
- Consider using Screen Time API as backup (limited to 50 URLs)

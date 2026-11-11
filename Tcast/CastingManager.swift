import Foundation
import SwiftCast
import UPnPCast
import AVKit

@MainActor
@Observable
class CastingManager {
    var chromecastDevices: [CastDevice] = []
    var dlnaDevices: [MediaRenderer] = []
    var isScanning = false
    var statusMessage = "Ready"
    
    private var castClient: CastClient?
    private var mediaController: MediaController?
    
    func scan() async {
        isScanning = true
        statusMessage = "Scanning..."
        
        // Chromecast
        do {
            let devices = try await CastDiscovery.scan(for: .seconds(4))
            chromecastDevices = devices
        } catch {
            print("Cast scan error: \(error)")
        }
        
        // DLNA
        do {
            let renderers = try await MediaRenderer.discover(duration: .seconds(4))
            dlnaDevices = renderers
        } catch {
            print("DLNA scan error: \(error)")
        }
        
        isScanning = false
        statusMessage = "Found \(chromecastDevices.count) Cast, \(dlnaDevices.count) DLNA"
    }
    
    func castToChromecast(_ device: CastDevice, url: URL, title: String) async {
        do {
            let client = CastClient(device: device)
            try await client.connect()
            let media = try await client.launchMediaReceiver()
            let info = MediaInformation(
                url: url,
                contentType: mimeType(for: url),
                metadata: .movie(title: title)
            )
            try await media.load(info)
            castClient = client
            mediaController = media
            statusMessage = "Casting to \(device.name ?? "Chromecast")"
        } catch {
            statusMessage = "Cast failed: \(error.localizedDescription)"
        }
    }
    
    func castToDLNA(_ renderer: MediaRenderer, url: URL, title: String) async {
        do {
            let item = MediaItem(
                url: url,
                mimeType: mimeType(for: url),
                title: title
            )
            try await renderer.play(item)
            statusMessage = "Casting to DLNA device"
        } catch {
            statusMessage = "DLNA cast failed: \(error.localizedDescription)"
        }
    }
    
    func stopCast() async {
        try? await mediaController?.stop()
        await castClient?.disconnect()
        castClient = nil
        mediaController = nil
        statusMessage = "Stopped"
    }
    
    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "m3u8": return "application/x-mpegurl"
        case "mp4": return "video/mp4"
        case "webm": return "video/webm"
        case "mkv": return "video/x-matroska"
        default: return "video/mp4"
        }
    }
}

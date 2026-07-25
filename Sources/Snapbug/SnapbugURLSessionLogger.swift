import Foundation

#if canImport(SnapbugSDK)
import SnapbugSDK

// MARK: - SnapbugURLSession

/// URLSession wrappers that log every request/response to the Snapbug inspector's
/// Network (and Images) tab. AsyncImage and other framework-internal URLSession
/// traffic cannot be intercepted without swizzling, so route your calls through
/// these helpers (or `SnapbugURLSessionLogger` manually) instead:
///
/// ```swift
/// let (data, response) = try await SnapbugURLSession.data(from: url)
/// ```
public enum SnapbugURLSession {

    /// `URLSession.data(for:)` with Snapbug network logging.
    public static func data(
        for request: URLRequest,
        session: URLSession = .shared
    ) async throws -> (Data, URLResponse) {
        let callId = SnapbugURLSessionLogger.generateCallId()
        SnapbugURLSessionLogger.logRequest(callId: callId, request: request)
        let start = Date()
        do {
            let (data, response) = try await session.data(for: request)
            SnapbugURLSessionLogger.logResponse(
                callId: callId,
                durationMs: Date().timeIntervalSince(start) * 1000,
                data: data,
                response: response
            )
            return (data, response)
        } catch {
            SnapbugURLSessionLogger.logFailure(
                callId: callId,
                durationMs: Date().timeIntervalSince(start) * 1000,
                error: error
            )
            throw error
        }
    }

    /// `URLSession.data(from:)` with Snapbug network logging.
    public static func data(
        from url: URL,
        session: URLSession = .shared
    ) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url), session: session)
    }
}

// MARK: - SnapbugURLSessionLogger

/// Manual network logging over the generic Snapbug bridge. Message shapes mirror
/// the Kotlin interceptors (`logNetworkCallRequest` / `logNetworkCallResponse`),
/// so responses with an `image/*` content type light up the Images tab too.
public enum SnapbugURLSessionLogger {

    /// Images above this size are not inlined as base64 thumbnails (mirrors the Ktor interceptor cap).
    public static let maxImageBytes = 512 * 1024

    private static var callCounter = 0
    private static let counterLock = NSLock()

    public static func generateCallId() -> String {
        counterLock.lock()
        defer { counterLock.unlock() }
        callCounter += 1
        return "ios_\(Int(Date().timeIntervalSince1970 * 1000))_\(callCounter)"
    }

    public static func logRequest(callId: String, request: URLRequest) {
        var payload: [String: Any] = [
            "snapbugCallId": callId,
            "snapbugNetworkType": "HTTP",
            "isMocked": false,
            "url": request.url?.absoluteString ?? "",
            "method": request.httpMethod ?? "GET",
            "startTime": Int(Date().timeIntervalSince1970 * 1000),
            "requestHeaders": request.allHTTPHeaderFields ?? [:],
        ]
        if let body = request.httpBody {
            payload["requestBody"] = String(data: body, encoding: .utf8) ?? "<binary \(body.count) bytes>"
            payload["requestSize"] = body.count
        }
        send(method: "logNetworkCallRequest", payload: payload)
    }

    public static func logResponse(
        callId: String,
        durationMs: Double,
        data: Data,
        response: URLResponse
    ) {
        let http = response as? HTTPURLResponse
        let contentType = http?.value(forHTTPHeaderField: "Content-Type") ?? response.mimeType
        let isImage = contentType?.hasPrefix("image/") ?? false

        var payload: [String: Any] = [
            "snapbugCallId": callId,
            "durationMs": durationMs,
            "snapbugNetworkType": "HTTP",
            "isMocked": false,
            "responseSize": data.count,
            "isImage": isImage,
        ]
        if let statusCode = http?.statusCode {
            payload["responseHttpCode"] = statusCode
        }
        if let contentType {
            payload["responseContentType"] = contentType
        }
        if let headers = http?.allHeaderFields {
            var stringHeaders: [String: String] = [:]
            for (key, value) in headers {
                stringHeaders["\(key)"] = "\(value)"
            }
            payload["responseHeaders"] = stringHeaders
        }
        if isImage {
            if data.count <= maxImageBytes {
                payload["imageBase64"] = data.base64EncodedString()
            }
        } else {
            payload["responseBody"] = String(data: data, encoding: .utf8) ?? "<binary \(data.count) bytes>"
        }
        send(method: "logNetworkCallResponse", payload: payload)
    }

    public static func logFailure(callId: String, durationMs: Double, error: Error) {
        send(method: "logNetworkCallResponse", payload: [
            "snapbugCallId": callId,
            "durationMs": durationMs,
            "snapbugNetworkType": "HTTP",
            "isMocked": false,
            "responseError": error.localizedDescription,
            "isImage": false,
        ])
    }

    private static func send(method: String, payload: [String: Any]) {
        guard let json = try? JSONSerialization.data(withJSONObject: payload),
              let body = String(data: json, encoding: .utf8) else { return }
        SnapbugSDK.Snapbug.companion.instance?.sendPluginMessage(
            plugin: "network",
            method: method,
            body: body
        )
    }
}
#endif

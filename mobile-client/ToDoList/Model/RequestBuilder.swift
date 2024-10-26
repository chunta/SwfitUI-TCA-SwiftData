import Foundation

/// Utility for building URL requests with specified parameters.
enum RequestBuilder {
    /// Constructs a `URLRequest` with the provided URL, HTTP method, headers, and body data.
    ///
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - method: The HTTP method as a `String` (e.g., "GET", "POST").
    ///   - headers: An optional dictionary of HTTP headers, where keys are header fields and values are their respective values.
    ///   - body: An optional `Data` object containing the body of the request.
    /// - Returns: A configured `URLRequest` with the specified properties.
    static func build(url: URL, method: String, headers: [String: String]?, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        return request
    }
}

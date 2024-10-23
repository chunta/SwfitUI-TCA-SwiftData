import Foundation

enum RequestBuilder {
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

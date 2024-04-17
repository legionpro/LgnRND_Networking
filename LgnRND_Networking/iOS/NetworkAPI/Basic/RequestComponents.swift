//
//  RequestComponents.swift
//  RNDNetworkingSUI_iOS
//
//  Created by Oleh Poremskyy on 12.04.2024.
//

import Foundation

protocol RequestComponents {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: [String: Any]? { get }
    var contentType: String { get }
    var queryParams: [String: Any]? { get}
    associatedtype ReturnType: Codable

}

extension RequestComponents {
    var scheme: String {
        return "https"
    }

    var host: String {
        return "api.themoviedb.org" //!!!!!!!!!!!!!!!!!!
    }
    
    var method: RequestMethod { return .get }
    var contentType: String { return "application/json" }
    var queryParams: [String: Any]? { return nil }
    var body: [String: Any]? { return nil }
    var headers: [String: String]? { return nil }
    
    private func requestBodyFrom(params: [String: Any]?) -> Data? {
        guard let params = params else { return nil }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else { return nil }
        return httpBody
    }
    
    func addQueryItems(queryParams: [String: Any]?) -> [URLQueryItem]? {
        guard let queryParams = queryParams else { return nil }
        return queryParams.map({URLQueryItem(name: $0.key, value: "\($0.value)")})
    }
    
    func setURLRequest(baseURL: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: baseURL) else { return nil }
        urlComponents.path = "\(urlComponents.path)\(path)"
        urlComponents.queryItems = addQueryItems(queryParams: queryParams)
        guard let finalURL = urlComponents.url else { return nil }
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = requestBodyFrom(params: body)
        request.allHTTPHeaderFields = headers
        
        ///Set your Common Headers here
        ///Like: api secret key for authorization header
        ///Or set your content type
        //request.setValue("Your API Token key", forHTTPHeaderField: HTTPHeaderField.authorization.rawValue)
        request.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
      
        return request
    }
}

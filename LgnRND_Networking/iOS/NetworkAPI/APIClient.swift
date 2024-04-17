//
//  ApiClient.swift
//  HICH
//
//  Created by Sajjad Sarkoobi on 2.09.2022.
//

import Foundation
import Combine

/*
 This class based on this github project
 https://gist.github.com/afterxleep/29c9af650deadf779e15bb00a8643ee6
 https://danielbernal.co/writing-a-networking-library-with-combine-codable-and-swift-5/
 Created by: Daniel Bernal
 It changed to be more robust and useful.
 APIRouter and APIParametes class aded
 It also Log all networks request and errors in console
 */

// The Request Method
enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
}

enum NetworkRequestError: LocalizedError, Equatable {
    case invalidRequest
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case error4xx(_ code: Int)
    case serverError
    case error5xx(_ code: Int)
    case decodingError( _ description: String)
    case urlSessionFailed(_ error: URLError)
    case timeOut
    case unknownError
}

// Extending Encodable to Serialize a Type into a Dictionary
extension Encodable {
    var asDictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }

        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}

// Our Request Protocol
protocol Request {
    var path: String { get }
    var method: HTTPMethod { get }
    var contentType: String { get }
    var body: [String: Any]? { get }
    var queryParams: [String: Any]? { get }
    var headers: [String: String]? { get }
    associatedtype ReturnType: Codable
}


// Defaults and Helper Methods
extension Request {
    
    // Defaults
    var method: HTTPMethod { return .get }
    var contentType: String { return "application/json" }
    var queryParams: [String: Any]? { return nil }
    var body: [String: Any]? { return nil }
    var headers: [String: String]? { return nil }
    
    /// Serializes an HTTP dictionary to a JSON Data Object
    /// - Parameter params: HTTP Parameters dictionary
    /// - Returns: Encoded JSON
    private func requestBodyFrom(params: [String: Any]?) -> Data? {
        guard let params = params else { return nil }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
    }
    
    func addQueryItems(queryParams: [String: Any]?) -> [URLQueryItem]? {
        guard let queryParams = queryParams else {
            return nil
        }
        return queryParams.map({URLQueryItem(name: $0.key, value: "\($0.value)")})
    }
    
    /// Transforms an Request into a standard URL request
    /// - Parameter baseURL: API Base URL to be used
    /// - Returns: A ready to use URLRequest
    func asURLRequest(baseURL: String) -> URLRequest? {
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

struct NetworkDispatcher {
    
    let urlSession: URLSession!
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Dispatches an URLRequest and returns a publisher
    /// - Parameter request: URLRequest
    /// - Returns: A publisher with the provided decoded data or an error
    func dispatch<ReturnType: Codable>(request: URLRequest) -> AnyPublisher<ReturnType, NetworkRequestError> {
        print("[\(request.httpMethod?.uppercased() ?? "")] '\(request.url!)'")
        return urlSession
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .default))
            .tryMap({ data, response in
                guard let response = response as? HTTPURLResponse else { throw httpError(0) }
                print("[\(response.statusCode)] '\(request.url!)'")
                if !(200...299).contains(response.statusCode) { throw httpError(response.statusCode) }
                return data
            })
            .receive(on: DispatchQueue.main)
            .decode(type: ReturnType.self, decoder: JSONDecoder())
            .mapError { error in
                Log.error("\(error)")
                return handleError(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Parses a HTTP StatusCode and returns a proper error
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Mapped Error
    private func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 402, 405...499: return .error4xx(statusCode)
        case 500: return .serverError
        case 501...599: return .error5xx(statusCode)
        default: return .unknownError
        }
    }
    
    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NetworkRequestError
    private func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError:
            return .decodingError(error.localizedDescription)
        case let urlError as URLError:
            return .urlSessionFailed(urlError)
        case let error as NetworkRequestError:
            return error
        default:
            return .unknownError
        }
    }
}

struct APIClient {
    
    static var networkDispatcher: NetworkDispatcher = NetworkDispatcher()
    
    /// Dispatches a Request and returns a publisher
    /// - Parameter request: Request to Dispatch
    /// - Returns: A publisher containing decoded data or an error
    static func dispatch<R: Request>(_ request: R) -> AnyPublisher<R.ReturnType, NetworkRequestError> {
        guard let urlRequest = request.asURLRequest(baseURL: APIConstants.basedURL) else {
            return Fail(outputType: R.ReturnType.self, failure: NetworkRequestError.badRequest).eraseToAnyPublisher()
            
        }
        typealias RequestPublisher = AnyPublisher<R.ReturnType, NetworkRequestError>
        let requestPublisher: RequestPublisher = networkDispatcher.dispatch(request: urlRequest)
        return requestPublisher.eraseToAnyPublisher()
    }
}




final class APIConstants {
    static var basedURL: String = "https://dummyjson.com"
}

enum HTTPHeaderField: String {
    case authentication = "Authentication"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case authorization = "Authorization"
    case acceptLanguage = "Accept-Language"
    case userAgent = "User-Agent"
}

enum ContentType: String {
    case json = "application/json"
    case xwwwformurlencoded = "application/x-www-form-urlencoded"
}


protocol DictionaryConvertor: Codable {}


//MARK: APIParameters for using in URLrequests
/// Structs that containg all parameters that needed for passing data as body or queary strings to urlrequest
/// it is conforimig to DictionaryConvertor
struct APIParameters{
    
    struct ProductParams: Encodable  {
        var skip: Int?
        var limit: Int?
    }
    
    struct AddProductParams: Encodable {
        var title: String?
    }
}


import Foundation

// MARK: - Products
struct ProductsModel: Codable {
    let products: [ProductModel]
    let total: Int
    let skip: String
    let limit: Int
}

// MARK: - Product
struct ProductModel: Codable, Hashable {
    let id: Int
    let title, productDescription: String
    let price: Int
    let discountPercentage, rating: Double
    let stock: Int
    let brand: String
    let category: String
    let thumbnail: String
    let images: [String]

    enum CodingKeys: String, CodingKey {
        case id, title
        case productDescription = "description"
        case price, discountPercentage, rating, stock, brand, category, thumbnail, images
    }
}


//Model for adding product
struct AddedProductModel: Codable {
    let id: Int
}



class APIRouter {
    
    // GET Request
    struct GetProducts: Request {
        typealias ReturnType = ProductsModel
        var path: String = "/products"
        var method: HTTPMethod = .get
        var queryParams: [String : Any]?
        init(queryParams: APIParameters.ProductParams) {
            self.queryParams = queryParams.asDictionary
        }
    }
    
    struct AddProduct: Request {
        typealias ReturnType = AddedProductModel
        var path: String = "/products/add"
        var method: HTTPMethod = .post
        var body: [String : Any]?
        init(body: APIParameters.AddProductParams) {
            self.body = body.asDictionary
        }
    }
}

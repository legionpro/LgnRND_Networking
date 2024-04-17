//
//  RequestErrors.swift
//  RNDNetworkingSUI_iOS
//
//  Created by Oleh Poremskyy on 12.04.2024.
//

import Foundation

enum RequestErrors: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
    
    var customErrorMessage: String {
        switch self {
        case .decode:
            return "Decode error"
        case .unauthorized:
            return "Session expired"
        default:
            return "Unknown error"
        }
    }
}



//
//  DummyData.swift
//  RNDNetworkingSUI_iOS
//
//  Created by Oleh Poremskyy on 12.04.2024.
//

import Foundation
enum Fileds {
    case title, href, results
}

struct ReqModel: Decodable {
    let user = ""
    let name = ""
    
    
    enum ReqEn: Decodable {
        case user, name
        
        
    }
}


struct RequestProvider {
    private let kServerUrl = "https://gist.githubusercontent.com/Disconnecter/ba9872ace953e382b3497ba358940ca9/raw/90f9f3344b0539a71e7abcb69578c6dadb817a86/gistfile1.txt"
    /**
     Response from request:
     {
         "title": "Car Models Collection",
         "version": "1.0",
         "href": "https://example.com/car-models",
         "results": [
             {
                 "title": "Toyota Corolla",
                 "href": "https://example.com/car-models/toyota-corolla",
                 "description": "The Toyota Corolla is a compact car that has been popular for decades due to its reliability and fuel efficiency.",
                 "thumbnail": "https://example.com/thumbnails/toyota-corolla.jpg"
             },
             {
                 "title": "Tesla Model S",
                 "href": "https://example.com/car-models/tesla-model-s",
                 "description": "The Tesla Model S is an all-electric luxury sedan known for its groundbreaking technology and impressive performance.",
                 "thumbnail": "https://example.com/thumbnails/tesla-model-s.jpg"
             }
            ...
         ]
     }
     */
    var request: URLRequest {
        URLRequest(url: URL(string: kServerUrl)!)
    }
}

//
//  BoundlessAPIClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/13/18.
//

import Foundation

internal enum BoundlessAPIEndpoint {
    case track, report, refresh
    
    var url: URL! { return URL(string: path)! }
    
    var path:String{ switch self{
    case .track: return "https://api.usedopamine.com/v4/app/track/"
    case .report: return "https://api.usedopamine.com/v4/app/report/"
    case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
        }
    }
}

internal class BoundlessAPIClient : HTTPClient {
    
    var properties: BoundlessProperties
    
    init(properties: BoundlessProperties, session: URLSessionProtocol = URLSession.shared) {
        self.properties = properties
        super.init(session: session)
    }
    
}

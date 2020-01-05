//
//  WKPennLogin.swift
//  WKPennLogin
//
//  Created by Josh Doman on 1/4/20.
//  Copyright © 2020 pennlabs. All rights reserved.
//

import Foundation

class WKPennLogin {
    static var clientID: String!
    static var redirectURI: String!
    
    static func setupCredentials(clientID: String, redirectURI: String) {
        WKPennLogin.clientID = clientID
        WKPennLogin.redirectURI = redirectURI
    }
}
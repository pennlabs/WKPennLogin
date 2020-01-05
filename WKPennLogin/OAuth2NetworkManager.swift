//
//  OAuth2NetworkManager.swift
//  WKPennLogin
//
//  Created by Josh Doman on 1/4/20.
//  Copyright © 2020 pennlabs. All rights reserved.
//

import Foundation

struct AccessToken: Codable {
    let value: String
    let expiration: Date
}

struct PennUser: Codable {
    let firstName: String
    let lastName: String
    let pennid: Int
    let username: String
    let email: String?
    let affiliation: [String]
}

extension URLRequest {
    // Sets the appropriate header field given an access token
    // NOTE: Should ONLY be used for requests to Labs servers. Otherwise, access token will be compromised.
    init(url: URL, accessToken: AccessToken) {
        self.init(url: url)
        // Authorization headers are restricted on iOS and not supposed to be set. They can be removed at any time.
        // Thus, we et an X-Authorization header to carry the bearer token in addition to the regular Authorization header.
        // For more info: see https://developer.apple.com/documentation/foundation/nsurlrequest#1776617
        setValue("Bearer \(accessToken.value)", forHTTPHeaderField: "Authorization")
        setValue("Bearer \(accessToken.value)", forHTTPHeaderField: "X-Authorization")
    }
}

class OAuth2NetworkManager: NSObject {
    static let instance = OAuth2NetworkManager()
    private override init() {}
    
    fileprivate var currentAccessToken: AccessToken?
}

// MARK: - Initiate Authentication
extension OAuth2NetworkManager {
    /// Input: One-time code from login
    /// Output: Temporary access token
    /// Saves refresh token in keychain for future use
    func authenticate(code: String, codeVerifier: String, _ callback: @escaping (_ accessToken: AccessToken?) -> Void) {
        let url = URL(string: "https://platform.pennlabs.org/accounts/token/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let params = [
            "code": code,
            "grant_type": "authorization_code",
            "client_id": WKPennLogin.clientID,
            "redirect_uri": WKPennLogin.redirectURI,
            "code_verifier": codeVerifier,
        ]
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = String.getPostString(params: params).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                struct ResponseData: Decodable {
                    let expiresIn: Int
                    let accessToken: String
                    let refreshToken: String
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let result = try? decoder.decode(ResponseData.self, from: data) {
                    let expiration = Calendar.current.date(byAdding: .second, value: result.expiresIn, to: Date())!
                    let accessToken = AccessToken(value: result.accessToken, expiration: expiration)
                    self.saveRefreshToken(token: result.refreshToken)
                    self.currentAccessToken = accessToken
                    callback(accessToken)
                    return
                }
            }
            callback(nil)
        }
        task.resume()
    }
}

// MARK: - Get + Refresh Access Token
extension OAuth2NetworkManager {
    func getAccessToken(_ callback: @escaping (_ accessToken: AccessToken?) -> Void) {
        if let accessToken = self.currentAccessToken, Date() < accessToken.expiration {
            callback(accessToken)
        } else {
            self.refreshAccessToken(callback)
        }
    }
    
    fileprivate func refreshAccessToken(_ callback: @escaping (_ accessToken: AccessToken?) -> Void ) {
        guard let refreshToken = self.getRefreshToken() else {
            callback(nil)
            return
        }
        
        let url = URL(string: "https://platform.pennlabs.org/accounts/token/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let params = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": WKPennLogin.clientID,
        ]
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = String.getPostString(params: params).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                if httpResponse.statusCode == 200 {
                    struct ResponseData: Decodable {
                        let expiresIn: Int
                        let accessToken: String
                        let refreshToken: String
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if let result = try? decoder.decode(ResponseData.self, from: data) {
                        let expiration = Calendar.current.date(byAdding: .second, value: result.expiresIn, to: Date())!
                        let accessToken = AccessToken(value: result.accessToken, expiration: expiration)
                        self.saveRefreshToken(token: result.refreshToken)
                        self.currentAccessToken = accessToken
                        callback(accessToken)
                        return
                    }
                } else if httpResponse.statusCode == 400 {
                    struct ResponseData: Decodable {
                        let error: String
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if let result = try? decoder.decode(ResponseData.self, from: data) {
                        if result.error == "invalid_grant" {
                            self.clearRefreshToken()
                        }
                    }
                }
            }
            callback(nil)
        }
        task.resume()
        
    }
}

// MARK: - Retrieve Account
extension OAuth2NetworkManager {
    func getUserInfo(accessToken: AccessToken, _ callback: @escaping (_ user: PennUser?) -> Void) {
        let url = URL(string: "https://platform.pennlabs.org/accounts/introspect/")!
        var request = URLRequest(url: url, accessToken: accessToken)
        request.httpMethod = "POST"
        
        let params = [
            "token": accessToken.value,
        ]
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = String.getPostString(params: params).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 {
                struct ResponseData: Decodable {
                    let user: PennUser
                }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let userWrapper = try? decoder.decode(ResponseData.self, from: data)
                if let userWrapper = userWrapper {
                    callback(userWrapper.user)
                    return
                }
            }
            callback(nil)
        }
        task.resume()
    }
}

// MARK: - Save + Get Refresh Token
extension OAuth2NetworkManager {
    private var refreshKey: String {
        return "Labs Refresh Token"
    }
    
    fileprivate func saveRefreshToken(token: String) {
        UserDefaults.standard.set(token, forKey: refreshKey)
    }
    
    fileprivate func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshKey)
    }
    
    func clearRefreshToken() {
        UserDefaults.standard.removeObject(forKey: refreshKey)
    }
    
    func hasRefreshToken() -> Bool {
        return getRefreshToken() != nil
    }
}

extension String {
    static func getPostString(params: [String: Any]) -> String {
        let characterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        let parameterArray = params.map { key, value -> String in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
            if let strValue = value as? String {
                let escapedValue = strValue.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
                return "\(escapedKey)=\(escapedValue)"
            } else if let arr = value as? Array<Any> {
                let str = arr.map { String(describing: $0).addingPercentEncoding(withAllowedCharacters: characterSet) ?? "" }.joined(separator: ",")
                return "\(escapedKey)=\(str)"
            } else {
                return "\(escapedKey)=\(value)"
            }
        }
        let encodedParams = parameterArray.joined(separator: "&")
        return encodedParams
    }
}

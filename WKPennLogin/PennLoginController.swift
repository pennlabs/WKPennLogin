//
//  PennLoginController.swift
//  WKPennLogin
//
//  Created by Josh Doman on 1/4/20.
//  Copyright © 2020 pennlabs. All rights reserved.
//

import Foundation
import WebKit
import CryptoKit
import CommonCrypto

typealias PennLoginCompletion = (_ user: PennUser?) -> Void

class PennLoginController: UIViewController, WKUIDelegate {
    
    private var urlStr: String {
        return "https://platform.pennlabs.org/accounts/authorize/?response_type=code&client_id=\(clientID)&redirect_uri=\(escapedRedirectURI)&code_challenge_method=S256&code_challenge=\(codeChallenge)&scope=read+introspection&state="
    }
    
    private var clientID: String {
        WKPennLogin.clientID
    }
    
    private var escapedRedirectURI: String {
        let characterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return WKPennLogin.redirectURI.addingPercentEncoding(withAllowedCharacters: characterSet)!
    }
    
    /// A random 64-character string
    private let codeVerifier: String = {
        // Source: https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift/33860834
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<64).map{ _ in letters.randomElement()! })
    }()
    
    /// The SHA256 hash of the code verifier
    private var codeChallenge: String {
        let inputData = Data(codeVerifier.utf8)
        if #available(iOS 13, *) {
            // CryptoKit not available until iOS 13
            let hashed = SHA256.hash(data: inputData)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            return hashString
        } else {
            // Use CommonCrypto if CryptoKit not available
            // https://www.agnosticdev.com/content/how-use-commoncrypto-apis-swift-5
            var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
            _ = inputData.withUnsafeBytes {
               CC_SHA256($0.baseAddress, UInt32(inputData.count), &digest)
            }
    
            var sha256String = ""
            for byte in digest {
               sha256String += String(format:"%02x", UInt8(byte))
            }
            return sha256String
        }
    }
    
    private var completion: PennLoginCompletion!
    
    convenience init(completion: @escaping PennLoginCompletion) {
        self.init()
        self.completion = completion
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.title = "PennKey Login"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view = webView

        let myURL = URL(string: self.urlStr)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - WKNavigationDelegate
extension PennLoginController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse, let url = response.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.absoluteString.contains(WKPennLogin.redirectURI) {
            // Successfully logged in and navigated to redirect URI
            guard let code = url.absoluteString.split(separator: "=").last else {
                self.completion(nil)
                return
            }
            
            // Authenticate code
            OAuth2NetworkManager.instance.authenticate(code: String(code), codeVerifier: codeVerifier) { (token) in
                guard let token = token else {
                    self.completion(nil)
                    return
                }
                
                // Get user info from Penn Labs Platform
                OAuth2NetworkManager.instance.getUserInfo(accessToken: token) { (user) in
                    self.completion(user)
                }
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Cancel
extension PennLoginController {
    @objc fileprivate func cancel(_ sender: Any) {
        _ = self.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
}

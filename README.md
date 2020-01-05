# WKPennLogin
An iOS library for logging users into the Penn Labs platform.

# Installation

## [CocoaPods](http://cocoapods.org)

To integrate `WKPennLogin` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
target 'MyApp' do
  pod 'WKPennLogin'
end
```

Then, run the following command:

```bash
$ pod install
```

# Usage

## Setup
Set up your credentials when the app first loads. Include the following ine in `didFinishLaunchingWithOptions` in `AppDelegate.swift`:
```swift
WKPennLogin.setupCredentials(clientID: <CLIENT ID>, redirectURI: <REDIRECT URI>)
```

## Login
```swift
import UIKit
import WKPennLogin

class ViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let plc = WKPennLoginController(delegate: self)
        let nvc = UINavigationController(rootViewController: plc)
        present(nvc, animated: true, completion: nil)
    }
}

extension ViewController: WKPennLoginDelegate {
    func handleLogin(user: WKPennUser) {
        print(user)
    }
}
```

## Platform Auth
To communicate with any account-specific Penn Labs resources, you must include an access token in your request.
```swift
WKPennNetworkManager.instance.getAccessToken { (token) in
    guard let token = token else {
        // User is unable to authenticate with the Penn Labs platform
        return
    }
    
    let url = URL(string: <TARGET URL>)!
    let request = URLRequest(url: url, accessToken: token)
    
    // ... Continue making request
}
```

## Check login
```swift
if WKPennLogin.isLoggedIn {
    ...
}
```
## Logout
```swift
WKPennLogin.logout()
```

## Error Handling (Optional)
```swift
extension ViewController: WKPennLoginDelegate {
    func handleError(error: WKPennLoginError) {
        switch error {
        case .missingCredentials:
            // Missing credentials
        case .invalidCredentials:
            // Invalid credential
        case .platformAuthError:
            // Unable to authenticate with the Penn Labs platform.
        }
    }
}
```

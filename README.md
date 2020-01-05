# WKPennLogin
An iOS library for logging users into Platform.

# Installation

## [CocoaPods](http://cocoapods.org)

To integrate `WKPennLogin` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
use_frameworks!

pod 'WKPennLogin', :git => 'https://github.com/pennlabs/WKPennLogin', :branch => 'master'
```

Then, run the following command:

```bash
$ pod install
```

# Usage

## Setup
Set your client ID immediately when the app loads. Include the following ine in `didFinishLaunchingWithOptions` in `AppDelegate.swift`:
```
WKPennLogin.setupCredentials(clientID: <CLIENT ID>, redirectURI: <REDIRECT URI>)
```

## Login
```
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
```
WKPennNetworkManager.instance.getAccessToken { (token) in
    guard let token = token else {
        // User is not logged in
        return
    }
    
    let url = URL(string: <TARGET URL>)!
    let request = URLRequest(url: url, accessToken: token)
    
    ... Continue request as usual
}
```

## Error Handling (Optional)
```
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

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

# Example Usage

## Login
```
import UIKit
import WKPennLogin

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        WKPennLogin.setupCredentials(clientID: <CLIENT ID>, redirectURI: <REDIRECT URI>)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Do any additional setup after loading the view.
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

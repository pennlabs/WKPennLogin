# WKPennLogin
An iOS library for logging users into Platform.

# Example
```
import UIKit
import WKPennLogin

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
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
    func handleLogin(user: PennUser) {
        print(user)
    }
}
```

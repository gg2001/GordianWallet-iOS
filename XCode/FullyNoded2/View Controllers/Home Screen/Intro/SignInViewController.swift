//
//  SignInViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices

class SignInViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var authenticateOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    let signInWithAppleUrl = "https://www.macrumors.com/guide/sign-in-with-apple/"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        authenticateOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.text = """
        FullyNoded 2 uses the "Sign in with Apple" tool for 2FA (two-factor authentication) purposes. It saves your Apple ID username to the device's Secure Enclave upon a successful sign-in.

        Then, whenever you broadcast a transaction or expose a private key/seed, FullyNoded 2 will prompt you to authenticate again, ensuring that only you can spend your bitcoins. Depending on your device's settings, you will either be prompted with biometrics or manual password entry for your Apple ID.

        Blockchain Commons and Fully Noded 2 never share any data with any third party ever. The only server the app connects to is your specified node, and only using Tor. "Sign in with Apple" is simply a secure way of ensuring no one else can spend your funds.
        """
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["Sign in with Apple": signInWithAppleUrl])
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.jpg"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == signInWithAppleUrl) {
            UIApplication.shared.open(URL) { (Bool) in }
        }
        return false
    }
    
    @IBAction func authenticate(_ sender: Any) {
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
            
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            DispatchQueue.main.async {
                
                let userIdentifier = appleIDCredential.user
                if KeyChain.set(userIdentifier.dataUsingUTF8StringEncoding, forKey: "userIdentifier") {
                    self.navigationController?.popToRootViewController(animated: true)
                }                
            }
            
        default:
            break
        }

    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return self.view.window!
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
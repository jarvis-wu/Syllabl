//
//  LandingViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-02-20.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import GoogleSignIn

class LandingViewController: UIViewController, GIDSignInDelegate {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var googleSignInButton: SButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var databaseRef = Database.database().reference()
    var refHandle: DatabaseHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil) // remove back button title
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
//        GIDSignIn.sharedInstance().signIn()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.googleSignInButton.enable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func didTapSignInButton(_ sender: SButton) {
        GIDSignIn.sharedInstance()?.signIn()
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error { print(error.localizedDescription); return }
        guard let auth = user.authentication else { return }
        activityIndicator.startAnimating()
        googleSignInButton.disable()
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        Auth.auth().signIn(with: credentials) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.activityIndicator.stopAnimating()
                guard let uid = Auth.auth().currentUser?.uid else {
                    print("Error: no uid.")
                    return
                }
                self.refHandle = self.databaseRef.child("users/\(uid)").observe(DataEventType.value, with: { (snapshot) in
                    let isNewUser = (snapshot.value == nil)
                    if isNewUser { // sign up
                        self.performSegue(withIdentifier: "ShowOnboardingViewController", sender: self)
                    } else { // directly go to home screen
                        self.performSegue(withIdentifier: "ShowTabController", sender: self)
                    }
                })
            }
        }
    }

    private func setupUI() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        iconImageView.image = UIImage(named: "banner-icon")
    }

}

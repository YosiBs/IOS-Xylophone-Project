//
//  LoginViewController.swift
//  Noam_Yosi_Xylophone
//
//  Created by nir nir on 17/08/2024.
//

import UIKit
import FirebaseAuth
class LoginViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
   
    
    @IBAction func loginClicked(_ sender: UIButton) {
           guard let email = emailTextField.text, !email.isEmpty else {
               showAlert(title: "Missing Email", message: "Please enter your email.")
               return
           }
           
           guard let password = passwordTextField.text, !password.isEmpty else {
               showAlert(title: "Missing Password", message: "Please enter your password.")
               return
           }
           
           Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
               if let error = error {
                   self?.showAlert(title: "Login Error", message: error.localizedDescription)
               } else {
                   self?.performSegue(withIdentifier: "goToNext", sender: self)
               }
           }
       }
    
    func showAlert(title: String, message: String) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    

}

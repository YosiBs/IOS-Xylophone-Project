//
//  CreateAccountViewController.swift
//  Noam_Yosi_Xylophone
//
//  Created by nir nir on 17/08/2024.
//

import UIKit
import FirebaseAuth
class CreateAccountViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func signupClicked(_ sender: UIButton) {
        
        guard let email = emailTextField.text else { return}
        
        guard let password = passwordTextField.text else {return }
        
        Auth.auth().createUser(withEmail: email, password: password) { Firebaseresult, error in
           if let e = error {
                print("error")
           }else{
               self.performSegue(withIdentifier: "goToNext", sender: self)
            }
        }
        
        
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

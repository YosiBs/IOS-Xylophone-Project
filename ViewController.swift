//
//  ViewController.swift
//  Xylophone_2_Noam_Yosi
//
//  Created by Student26 on 21/08/2024.
//
import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseAuth
class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var recordBTN: UIImageView!
    var isAnimating = false
    var isRecording = false
    @IBOutlet weak var noteB: UIImageView!
    @IBOutlet weak var noteA: UIImageView!
    @IBOutlet weak var noteG: UIImageView!
    @IBOutlet weak var noteF: UIImageView!
    @IBOutlet weak var noteE: UIImageView!
    @IBOutlet weak var noteD: UIImageView!
    @IBOutlet weak var noteC: UIImageView!
    var currentRecord: Record?
    var lastNoteTime: Date?
    
    var audioPlayer: AVAudioPlayer!
    
    @IBOutlet weak var listMenuBTN: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add tap gesture recognizers to each note image
        let notes = [noteB, noteA, noteG, noteF, noteE, noteD, noteC]
        
        for note in notes {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(noteTapped(_:)))
            note?.isUserInteractionEnabled = true
            note?.addGestureRecognizer(tapRecognizer)
        }
        
        
        // Add tap gesture recognizer to the recordBTN image view
               let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordBTNClicked))
               recordBTN.isUserInteractionEnabled = true
               recordBTN.addGestureRecognizer(tapRecognizer)
        
    
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
   
    
    // Function to handle the image click
    @objc func recordBTNClicked() {
        if isAnimating {
            stopAnimation()
            isRecording = false  // Stop recording
            showSaveRecordingPopup()
        } else {
            startAnimation()
            startNewRecording(named: "Unnamed Recording")
        }
    }
    
    func startNewRecording(named recordingName: String) {
           currentRecord = Record(name: recordingName)
           lastNoteTime = Date()
           isRecording = true
       }
    
    
       // Function to start the grow/shrink animation
    func startAnimation() {
           isAnimating = true
           UIView.animate(withDuration: 0.5, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
               self.recordBTN.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
           }, completion: nil)
       }

       // Function to stop the animation
       func stopAnimation() {
           isAnimating = false
           recordBTN.layer.removeAllAnimations()
           recordBTN.transform = CGAffineTransform.identity
       }
    
    
    @objc func noteTapped(_ sender: UITapGestureRecognizer) {
        if let noteView = sender.view as? UIImageView, let noteName = getNoteName(for: noteView) {
            vibrate(noteView)
            playSound(for: noteView)
            
            if isRecording {
                recordNotePlayed(note: noteName)
            }
        }
    }
    
    func recordNotePlayed(note: String) {
        guard let currentRecord = currentRecord else { return }
        
        let now = Date()
        let timeInterval: TimeInterval
        
        if currentRecord.notes.isEmpty {
            // First note, no interval needed
            timeInterval = 0.0
        } else {
            // Subsequent notes, calculate the time interval
            timeInterval = now.timeIntervalSince(lastNoteTime ?? now)
        }
        
        // Add the note and its corresponding time interval
        currentRecord.notes.append(note)
        if currentRecord.notes.count > 1 {
            currentRecord.timeIntervals.append(timeInterval)
        }
        
        lastNoteTime = now
    }
     
    
    
 
   
    
    // Function to create the vibration/shake effect
    func vibrate(_ view: UIView) {
        let shakeAnimation = CABasicAnimation(keyPath: "position")
        shakeAnimation.duration = 0.04
        shakeAnimation.repeatCount = 3
        shakeAnimation.autoreverses = true
        
        let fromPoint = CGPoint(x: view.center.x - 3, y: view.center.y)
        let toPoint = CGPoint(x: view.center.x + 3, y: view.center.y)
        
        shakeAnimation.fromValue = NSValue(cgPoint: fromPoint)
        shakeAnimation.toValue = NSValue(cgPoint: toPoint)
        
        view.layer.add(shakeAnimation, forKey: "position")
    }
   
    
    // Helper function to get the name of the note from the image view
      func getNoteName(for note: UIImageView) -> String? {
          switch note {
          case noteB:
              return "soundB"
          case noteA:
              return "soundA"
          case noteG:
              return "soundG"
          case noteF:
              return "soundF"
          case noteE:
              return "soundE"
          case noteD:
              return "soundD"
          case noteC:
              return "soundC"
          default:
              return nil
          }
      }
      
    
    
  
    
    // Function to display the popup
    func showSaveRecordingPopup() {
           let alertController = UIAlertController(title: "Save Recording", message: "Enter a name for your recording:", preferredStyle: .alert)
           
           alertController.addTextField { (textField) in
               textField.placeholder = "Recording Name"
           }
           
           let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
               if let recordingName = alertController.textFields?.first?.text, !recordingName.isEmpty {
                   self?.saveRecording(named: recordingName)
               } else {
                   print("Recording name was not entered.")
               }
           }
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
           
           alertController.addAction(saveAction)
           alertController.addAction(cancelAction)
           
           present(alertController, animated: true, completion: nil)
       }
    
    func saveRecording(named recordingName: String) {
        guard let currentRecord = currentRecord else { return }
        guard let user = Auth.auth().currentUser else {
            print("No user is logged in.")
            return
        }
        
        currentRecord.name = recordingName
        
        let db = Firestore.firestore()
        let userID = user.uid
        
        // Create a unique document ID for the recording
        let recordingID = UUID().uuidString
        
        // Save the recording under the user's collection with a unique ID
        db.collection("users").document(userID).collection("recordings").document(recordingID).setData(currentRecord.toDictionary()) { error in
            if let error = error {
                print("Error saving recording: \(error.localizedDescription)")
            } else {
                print("Recording saved successfully.")
            }
        }
    }
    
    
    
    
    // Function to play a sound by its name
    func playSound(for note: UIImageView) {
           if let soundFileName = getNoteName(for: note), let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav", subdirectory: "Sounds") {
               do {
                   audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                   audioPlayer!.play()
               } catch {
                   print("Could not load sound file: \(error.localizedDescription)")
               }
           }
       }
    
}

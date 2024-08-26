import UIKit
import FirebaseFirestore
import FirebaseAuth
import AVFoundation

class RecordListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    
    var data: [Record] = []
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        // Fetch recordings from Firestore
        fetchRecordings()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let record = data[indexPath.row]
        
        let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomeTableViewCell
        
        cell.label.text = record.name
        cell.iconImageView.image = UIImage(named: record.imageName)
        
        // Add tap gesture recognizer to the play button
        let playTapGesture = UITapGestureRecognizer(target: self, action: #selector(playRecording(_:)))
        cell.iconImageView.isUserInteractionEnabled = true
        cell.iconImageView.tag = indexPath.row // Store the index for reference
        cell.iconImageView.addGestureRecognizer(playTapGesture)
        
        // Add tap gesture recognizer to the label (for showing delete popup)
        let labelTapGesture = UITapGestureRecognizer(target: self, action: #selector(showDeletePopup(_:)))
        cell.label.isUserInteractionEnabled = true
        cell.label.tag = indexPath.row // Store the index for reference
        cell.label.addGestureRecognizer(labelTapGesture)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @objc func playRecording(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let record = data[index]
        
        playNotes(record)
    }
    
    @objc func showDeletePopup(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let record = data[index]
        
        let alertController = UIAlertController(title: "Manage Recording", message: "What would you like to do with this recording?", preferredStyle: .alert)
        
        // Delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteRecordFromDatabase(record)
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    


    func playNotes(_ record: Record) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for (index, note) in record.notes.enumerated() {
                let delay: TimeInterval
                if index == 0 {
                    delay = 0.0 // Play the first note immediately
                } else {
                    delay = record.timeIntervals[index - 1] // Use the previous interval for delay
                }
                
                // Sleep for the delay interval
                Thread.sleep(forTimeInterval: delay)
                
                // Play the sound on the main thread to ensure UI updates
                DispatchQueue.main.async {
                    self?.playSound(noteName: note)
                    print("Playing note: \(note) after \(delay) seconds")
                }
            }
        }
    }


    
    func playSound(noteName: String) {
        if let soundURL = Bundle.main.url(forResource: noteName, withExtension: "wav", subdirectory: "Sounds") {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                self.audioPlayer?.play()
            } catch {
                print("Could not load sound file: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found for note: \(noteName)")
        }
    }
    
    func deleteRecordFromDatabase(_ record: Record) {
        guard let user = Auth.auth().currentUser else {
            print("No user is logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let userID = user.uid
        
        // Find the document ID based on the record's name (assuming name is unique)
        db.collection("users").document(userID).collection("recordings").whereField("name", isEqualTo: record.name).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching record to delete: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No matching record found to delete.")
                return
            }
            
            // Delete the document
            document.reference.delete { error in
                if let error = error {
                    print("Error deleting record: \(error.localizedDescription)")
                } else {
                    print("Record deleted successfully.")
                    
                    // Remove the record from the local array and reload the table view
                    if let index = self?.data.firstIndex(where: { $0.name == record.name }) {
                        self?.data.remove(at: index)
                        self?.table.reloadData()
                    }
                }
            }
        }
    }
    
    func fetchRecordings() {
        guard let user = Auth.auth().currentUser else {
            print("No user is logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let userID = user.uid
        
        db.collection("users").document(userID).collection("recordings").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching recordings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No recordings found.")
                return
            }
            
            self?.data.removeAll()
            for document in documents {
                let data = document.data()
                if let name = data["name"] as? String,
                   let notes = data["notes"] as? [String],
                   let timeIntervals = data["timeIntervals"] as? [TimeInterval] {
                    
                    let record = Record(name: name, notes: notes, timeIntervals: timeIntervals, imageName: "play")
                    self?.data.append(record)
                }
            }
            
            // Reload the table view with the fetched data
            self?.table.reloadData()
        }
    }
}


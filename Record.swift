import Foundation

class Record {
    var name: String
    var notes: [String]  // List of notes played
    var timeIntervals: [TimeInterval]  // List of time intervals (delta) between notes
    var imageName: String  // Name of the image associated with the record, e.g., "play"
    
    init(name: String, notes: [String] = [], timeIntervals: [TimeInterval] = [], imageName: String = "play") {
        self.name = name
        self.notes = notes
        self.timeIntervals = timeIntervals
        self.imageName = imageName
    }
    
    // Function to add a note with its corresponding time interval
    func addNote(note: String, timeInterval: TimeInterval) {
        notes.append(note)
        timeIntervals.append(timeInterval)
    }
    
    // Function to convert the Record object to a dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "notes": notes,
            "timeIntervals": timeIntervals,
            "imageName": imageName
        ]
    }
    
    // Function to create a Record object from a dictionary (for fetching from Firestore)
    static func fromDictionary(_ dictionary: [String: Any]) -> Record? {
        guard let name = dictionary["name"] as? String,
              let notes = dictionary["notes"] as? [String],
              let timeIntervals = dictionary["timeIntervals"] as? [TimeInterval],
              let imageName = dictionary["imageName"] as? String else {
            return nil
        }
        
        return Record(name: name, notes: notes, timeIntervals: timeIntervals, imageName: imageName)
    }
}

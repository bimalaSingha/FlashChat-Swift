
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    var messages : [Message] = []
//    var messages : [Message] = [
//    Message(sender: "bms@xyz.com", body: "Hey!"),
//    Message(sender: "bms@xyz.com", body: "How are you?")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
//        tableView.delegate = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages(){
        
        db.collection(K.collectionName)
            .order(by: K.dateField)
            .addSnapshotListener { (querySnapshot, error) in
            
            self.messages = []
            
            if let e = error {
                print("there was an issue retrieving data from firbase. \(e)")
            } else {
                if let snapshotdocuments = querySnapshot?.documents{
                    for doc in snapshotdocuments{
                        let data = doc.data()
                        if let messageSender = data[K.senderField] as? String, let messageBody = data[K.bodyField] as? String{
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                                
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
        
    
    
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email{
            db.collection(K.collectionName).addDocument(data: [
                K.senderField: messageSender,
                K.bodyField: messageBody,
                K.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("Issue in saving the data to Firestore, \(e)")
                } else {
                    print("Data saved Succesfully")
                    
                    DispatchQueue.main.async{
                        self.messageTextfield.text = ""
                    }
                }
            }
        }
    }
    
    
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
}



extension ChatViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        as! MessageCell
        cell.label.text = message.body        
        
        //message from the current user
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: BrandColors.purple)
        }
        
        //message rom another user
        else{
            cell.rightImageView.isHidden = true
            cell.leftImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: BrandColors.purple)
            cell.label.textColor = UIColor(named: BrandColors.lightPurple)
        }
        
        return cell
    }
}

//Runs when an user taps a message
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        }
}


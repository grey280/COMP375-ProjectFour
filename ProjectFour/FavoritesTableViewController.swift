//
//  FavoritesTableViewController.swift
//  ProjectFour
//
//  Created by Grey Patterson on 2017-05-08.
//  Copyright © 2017 Grey Patterson. All rights reserved.
//

import UIKit
import RealmSwift
import SafariServices

class FavoritesTableViewController: UITableViewController {
    
    var realm: Realm!
    var notificationToken: NotificationToken!
    var favorites = List<Video>()
    
    func setUpRealm() {
        // Note: you need a file somewhere in here that declares
        /*
         struct login{
            static let username = "[the relevant Realm username]"
            static let password = "[the relevant Realm password]"
            static let serverURL: URL // the URL of the Realm server to use
         }
        */
        //        let syncCredentials = SyncCredentials.usernamePassword(username: username, password: password, register: false)
        let syncCredentials = SyncCredentials.usernamePassword(username: login.username, password: login.password)
        
        // log in the user with the given credentials to the specified server
        SyncUser.logIn(with: syncCredentials, server: login.serverURL) {
            (user, error) in
            if let user = user {
                // Create a Realm configuration with the specified user and realm directory
                let url = URL(string: "\(login.serverURL.absoluteString)/~/videolist")!
                let syncConfiguration = SyncConfiguration(user: user, realmURL: url)
                let realmConfiguration = Realm.Configuration(syncConfiguration: syncConfiguration)
                
                // Realm instances are only valid on a single thread and notification blocks need to be added to a thread with a runloop.
                // The main thread, thread 0, has a built in run loop.
                // DispatchQueue.main.async is the way in Swift 3 to add function calls, asynchronously, to the main thread
                DispatchQueue.main.async {
                    
                    // create a Realm instance with the specified configuration
                    self.realm = try! Realm(configuration: realmConfiguration)
                    if self.realm.objects(VideoList.self).first == nil{
                        try! self.realm.write {
                            self.realm.add(VideoList())
                        }
                    }
                    self.updateList()
                    
                    // Add a handler, i.e, the closure, containing the call to updateList(),
                    //  to realm.
                    // The closure is called after each realm write is committed until notificationToken.stop() is executed
                    let block: NotificationBlock = {_ in
                        self.updateList()
                    }
                    self.notificationToken = self.realm.addNotificationBlock(block)
                }
            } else if let error = error {
                fatalError(String(describing: error))
            }
            
        }
    }
    
    func updateList() {
        if self.favorites.realm == nil, let list = self.realm.objects(VideoList.self).first {
            self.favorites = list.items
        }
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    /// Handles a cell being tapped; figures out which cell it was, then fires the proper event
    ///
    /// - Parameter sender: the sending UITapGestureRecognizer
    func cellTap(_ sender: UITapGestureRecognizer){
        let sendLocation = sender.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: sendLocation)
        let videoURL = favorites[path?.row ?? 0].watchURL
        let sfVC = SFSafariViewController(url: videoURL)
        self.present(sfVC, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let thumbURL = favorites[indexPath.row].thumbURL{
            cell.imageView?.downloadedFrom(url: thumbURL)
        }
        cell.textLabel?.text = favorites[indexPath.row].title
        cell.detailTextLabel?.text = favorites[indexPath.row].detail
        
        // I *could* subclass UITableViewCell and handle this that way, but this is more fun
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(FavoritesTableViewController.cellTap(_:)))
        cell.addGestureRecognizer(tapRecognizer)
        cell.showsReorderControl = true // and this way we can always rearrange things, hopefully
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        try! realm.write{
            favorites.move(from: fromIndexPath.row, to: to.row) // Turns out the List class is part of Realm, I spent a while trying to find it in the Swift docs
        }
    }
 

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension UIImageView { // thank you Stack Overflow (http://stackoverflow.com/questions/24231680/loading-downloading-image-from-url-on-swift)
    
    /// Fills the image with a URL
    ///
    /// - Parameters:
    ///   - url: URL to load the file from
    ///   - mode: UIViewContentMode to use, defaults .scaleAspectFit
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    /// Fills the image with a URL
    ///
    /// - Parameters:
    ///   - link: URL to load the file from, as a String
    ///   - mode: UIViewContentMode to use, defaults .scaleAspectFit
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

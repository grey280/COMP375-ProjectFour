//
//  FavoritesTableViewController.swift
//  ProjectFour
//
//  Created by Grey Patterson on 2017-05-08.
//  Copyright © 2017 Grey Patterson. All rights reserved.
//

import UIKit
import RealmSwift

class FavoritesTableViewController: UITableViewController {
    
    var realm: Realm!
    var notificationToken: NotificationToken!
    var favorites = List<Video>()
    
    func setUpRealm() {
        
        // Log in existing user with their username and password
        
        
        // replace localhost with the url of the professors laptop, i.e. his realm server
        //        let syncCredentials = SyncCredentials.usernamePassword(username: username, password: password, register: false)
        let syncCredentials = SyncCredentials.usernamePassword(username: username, password: password)
        let url = URL(string: "http://localhost:9080")!
        
        // log in the user with the given credentials to the specified server
        SyncUser.logIn(with: syncCredentials, server: url) {
            (user, error) in
            if let user = user {
                
                // Create a Realm configuration with the specified user and realm directory
                let url = URL(string: "realm://localhost:9080/~/realmtasks")!
                let syncConfiguration = SyncConfiguration(user: user, realmURL: url)
                let realmConfiguration = Realm.Configuration(syncConfiguration: syncConfiguration)
                
                // Realm instances are only valid on a single thread and
                //  notification blocks need to be added to a thread with a runloop.
                // The main thread, thread 0, has a built in run loop.
                // DispatchQueue.main.async is the way in Swift 3 to
                //  add function calls, asynchronously, to the main thread
                DispatchQueue.main.async {
                    
                    // create a Realm instance with the specified configuration
                    self.realm = try! Realm(configuration: realmConfiguration)
                    if self.realm.objects(TaskList.self).first == nil{
                        try! self.realm.write {
                            self.realm.add(TaskList())
                        }
                    }
                    self.updateList()
                    
                    // Add a handler, i.e, the closure, containing the call to updateList(),
                    //  to realm.
                    // The closure is called after each realm write is committed
                    //  until notificationToken.stop() is executed
                    let block: NotificationBlock = {_ in
                        print("NotificationBlock fired")
                        self.updateList()
                    }
                    self.notificationToken = self.realm.addNotificationBlock(block)
                }
            } else if let error = error {
                fatalError(String(describing: error))
            }
            
        }
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let thumbURL = favorites[indexPath.row].thumbURL{
            cell.imageView?.downloadedFrom(url: thumbURL)
        }
        cell.textLabel?.text = favorites[indexPath.row].title
        cell.detailTextLabel?.text = favorites[indexPath.row].detail
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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

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

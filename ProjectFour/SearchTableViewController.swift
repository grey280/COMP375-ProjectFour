//
//  SearchTableViewController.swift
//  ProjectFour
//
//  Created by Grey Patterson on 2017-05-12.
//  Copyright © 2017 Grey Patterson. All rights reserved.
//

import UIKit
import RealmSwift
import SafariServices

class SearchTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    
    var results = [Video]()
    var favorites = List<Video>()
    var realm: Realm!
    var notificationToken: NotificationToken!
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        if let query = searchBar.text{
            search(query)
        }
    }
    
    func search(_ query: String){
        results = [Video]() // Clear old results
        tableView.reloadData()
        
        let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(query)&key=\(google.APIKey)&type=video")
        URLSession.shared.dataTask(with: url!) {
            (data, response, err) in
            if let err = err {
                print("err: \(err)")
            }
            else if let data = data {
                if let json = try! JSONSerialization.jsonObject(with: data) as? [String: AnyObject] {
                    print(json)
                    for result in json["items"] as! [[String: AnyObject]]{
                        let IDblock = result["id"] as! [String: AnyObject]
                        let ID = IDblock["videoId"] as! String
                        
                        let snippet = result["snippet"] as! [String: AnyObject]
                        
                        let title = snippet["title"] as! String
                        
                        let description = snippet["description"] as! String
                        
                        let thumbnails = snippet["thumbnails"] as! [String: AnyObject]
                        let defaultThumb = thumbnails["default"] as! [String: AnyObject]
                        let defaultThumbURL = URL(string: defaultThumb["url"] as! String)!

                        let tempVideo = Video(ID, title: title, description: description, thumbnailURL: defaultThumbURL)
                        
                        self.results.append(tempVideo)
                    }
                    if (self.results.count > 0) {
                        self.tableView.reloadData()
                    }
                }
            }
        }.resume()
        print("Done!")
    }
    
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
        SyncUser.logIn(with: syncCredentials, server: URL(string: login.serverURL)!) {
            (user, error) in
            if let user = user {
                // Create a Realm configuration with the specified user and realm directory
                let url = URL(string: login.fullURL)!
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
//        self.tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpRealm()
        searchBar.delegate = self

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
        return results.count
    }

    func cellPress(_ sender: UILongPressGestureRecognizer){
        let sendLocation = sender.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: sendLocation)
        try! realm.write {
            favorites.append(results[path?.row ?? 0])
        }
    }
    
    func cellTap(_ sender: UITapGestureRecognizer){ // Handle a tap
        let sendLocation = sender.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: sendLocation)
        let videoURL = results[path?.row ?? 0].watchURL
        let sView = SFSafariViewController(url: videoURL)
        self.present(sView, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let thumbURL = results[indexPath.row].thumbURL{
            cell.imageView?.downloadedFrom(url: thumbURL)
        }
        cell.textLabel?.text = results[indexPath.row].title
        cell.detailTextLabel?.text = results[indexPath.row].detail
        
        let pressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(SearchTableViewController.cellPress(_:)))
        cell.addGestureRecognizer(pressRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchTableViewController.cellTap(_:)))
        cell.addGestureRecognizer(tapRecognizer)
        
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

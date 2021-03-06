//
//  Video.swift
//  ProjectFour
//
//  Created by Grey Patterson on 2017-05-08.
//  Copyright © 2017 Grey Patterson. All rights reserved.
//

import UIKit
import RealmSwift

class Video: Object{
    dynamic var title = ""
    dynamic var detail = ""
    dynamic private var thumbnailUrl = ""
    
    
//    var thumbnail: UIImage?
    
    var thumbURL: URL?{
        get{
            return URL(string: thumbnailUrl)
        }
        set{
            thumbnailUrl = newValue?.absoluteString ?? ""
        }
    }
    
    override static func ignoredProperties() -> [String] {
        return ["thumbURL", "watchURL", "thumbnail"]
    }
    
    dynamic var videoId = ""
    
    var watchURL: URL{
        return URL(string: "https://www.youtube.com/watch?v=\(videoId)") ?? URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
    }
    
    convenience init(_ ID: String){
        self.init()
        self.videoId = ID
    }
    
    convenience init(_ ID: String, title: String, description detail: String, thumbnailURL thumbURL: URL){
        self.init()
        self.videoId = ID
        self.title = title
        self.detail = detail
        self.thumbnailUrl = thumbURL.absoluteString
    }
    
    override static func primaryKey() -> String? {
        return "videoId"
    }
}

class VideoList: Object {
    dynamic var id = ""
    let items = List<Video>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

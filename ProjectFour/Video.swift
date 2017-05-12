//
//  Video.swift
//  ProjectFour
//
//  Created by Grey Patterson on 2017-05-08.
//  Copyright © 2017 Grey Patterson. All rights reserved.
//

import Foundation
import RealmSwift

class Video: Object{
    dynamic var title = ""
    dynamic var detail = ""
    dynamic private var thumbURLi = ""
    var thumbURL: URL?{
        get{
            return URL(string: thumbURLi)
        }
        set{
            thumbURLi = newValue?.absoluteString ?? ""
        }
    }
    dynamic var videoID = ""
    var watchURL: URL{
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)") ?? URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
    }
    
    convenience init(_ ID: String){
        self.init()
        self.videoID = ID
    }
    
    convenience init(_ ID: String, title: String, description detail: String, thumbnailURL thumbURL: URL){
        self.init()
        self.videoID = ID
        self.title = title
        self.detail = detail
        self.thumbURL = thumbURL
    }
    
    override static func primaryKey() -> String? {
        return "videoID"
    }
}

class VideoList: Object {
    dynamic var id = ""
    let items = List<Video>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

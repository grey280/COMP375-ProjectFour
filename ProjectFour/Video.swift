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
    
    convenience init(_ ID: String){
        self.init()
        self.videoID = ID
    }
    
    override static func primaryKey() -> String? {
        return "videoID"
    }
}

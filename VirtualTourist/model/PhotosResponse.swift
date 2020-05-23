//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Andy on 21.05.2020.
//  Copyright © 2020 AndyRadionov. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
    let photos: PhotosList
}

struct PhotosList: Codable {
    let photo: [PhotoResponse]
    let pages: Int
}

struct PhotoResponse: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}

//
//  ApiClient.swift
//  VirtualTourist
//
//  Created by Andy on 19.05.2020.
//  Copyright © 2020 AndyRadionov. All rights reserved.
//

import Foundation

class ApiClient {
    
    enum Endpoints {
        static let baseUrl = "https://api.flickr.com/services/rest/?"
        static let apiKey = "PUT_YOUR_FLICKR_API_KEY_HERE"
        
        case list(latitude: Double, longitude: Double)
        case detail(farmId: String, serverId: String, photoId: String, secret: String)
        
        var stringValue: String {
            switch self {
            case .list(let latitude, let longitude):
                return "\(Endpoints.baseUrl)method=flickr.photos.search&api_key=\(Endpoints.apiKey)&format=json&privacy_filter=1&lat=\(latitude)&lon=\(longitude)&nojsoncallback=1&radius=10"
            case .detail(let farmId, let serverId, let photoId, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret)_s.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
        
    enum ApiError: LocalizedError {
        case networkError
        case commonError
        
        var localizedDescription: String {
            switch self {
            case .networkError:
                return "Network Error\nPlease try Again later"
            case .commonError:
                return "Something went wrong\nPlease Try Again later"
            }
        }
    }
        
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    
    class func loadList(latitude: Double, longitude: Double, completion: @escaping (PhotosResponse?, ApiError?) -> Void) {
        taskForGETRequest(url: Endpoints.list(latitude: latitude, longitude: longitude).url, responseType: PhotosResponse.self) {
            (photosResponse, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            
            completion(photosResponse, nil)
        }
    }
    
    class func loadPhoto(photo: Photo, result: @escaping (Data?, ApiError?) -> Void) {
        let request = URLRequest(url: Endpoints.detail(farmId: photo.farmId!, serverId: photo.serverId!, photoId: photo.id!, secret: photo.secret!).url)
        let task = URLSession.shared.dataTask(with: request) {data, response, error in
            if error != nil {
                result(nil, .networkError)
                return
            }
            result(data, nil)
        }
        task.resume()
    }
    
    private class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, ApiError?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, .networkError)
                return
            }
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, .commonError)
            }
        }
        task.resume()
    }
}

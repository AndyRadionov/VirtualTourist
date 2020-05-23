//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Andy on 19.05.2020.
//  Copyright © 2020 AndyRadionov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var selectedPin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var dataController: DataController {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.dataController
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initMap()
        initFetchedResultsController()
        if (fetchedResultsController.sections![0].numberOfObjects == 0) {
            loadPhotosFromNetwork()
        }
    }
    
    @IBAction func reloadPhotos(_ sender: Any) {
        loadPhotosFromNetwork()
    }
        
    fileprivate func initFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
            
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(selectedPin.latitude)\(selectedPin.longitude)")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            showErrorAlert(.commonError, self)
        }
    }
        
    func initMap() {
        let latitude = CLLocationDegrees(selectedPin.latitude)
        let longitude = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setCenter(coordinate, animated: true)
    }
        
    func loadPhotosFromNetwork() {
        self.refreshButton.isEnabled = false
        ApiClient.loadList(latitude: selectedPin.latitude, longitude: selectedPin.longitude) { (photosResponse, error) in
            if error != nil {
                self.showErrorAlert(error!, self)
                return
            }
                
            let photos = photosResponse!.photos.photo.map { (photoResponse) -> Photo in
                let photo = Photo(context: self.dataController.viewContext)
                photo.id = photoResponse.id
                photo.farmId = "\(photoResponse.farm)"
                photo.serverId = photoResponse.server
                photo.secret = photoResponse.secret
                return photo
            }
        
            DispatchQueue.main.async {
                self.selectedPin.removeFromPhotos(self.selectedPin.photos!)
                try? self.dataController.viewContext.save()
                
                photos.forEach({ (photo) in
                    photo.pin = self.selectedPin
                    ApiClient.loadPhoto(photo: photo) { (data, error) in
                        if (error != nil) { return }
                        photo.photo = data
                        DispatchQueue.main.async {
                            try? self.dataController.backgroundContext.save()
                            self.refreshButton.isEnabled = true
                        }
                    }
                })
                try? self.dataController.viewContext.save()
            }
        }
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photosCollectionView.reloadData()
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = fetchedResultsController.object(at: indexPath)
        if (photo.photo != nil) {
            cell.imageView.image = UIImage(data: photo.photo!)
            cell.activityIndicator.isHidden = true
        }
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataController.viewContext.delete(fetchedResultsController.object(at: indexPath))
        try? dataController.viewContext.save()
    }
}

//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Andy on 19.05.2020.
//  Copyright © 2020 AndyRadionov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    var dataController: DataController {
       let object = UIApplication.shared.delegate
       let appDelegate = object as! AppDelegate
       return appDelegate.dataController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        let coordinate = view.annotation!.coordinate
        let selectedPin = pins.first { (pin) -> Bool in
            return pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude
        }
        let viewController = storyboard?.instantiateViewController(withIdentifier: "showPhotoAlbum") as! PhotoAlbumViewController
        viewController.selectedPin = selectedPin
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        mapView.region.save(withKey: "mapRegion")
    }
    
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        try? dataController.viewContext.save()
        
        pins.append(pin)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coordinate
        annotation.title = "\(pins.firstIndex(of: pin)!)"
        mapView.addAnnotation(annotation)
    }
    
    private func loadPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            if (result.count > 0) {
                pins = result
                var annotations = [MKPointAnnotation]()
                for pin in result {
                    let lat = CLLocationDegrees(pin.latitude)
                    let long = CLLocationDegrees(pin.longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    annotations.append(annotation)
                }
                DispatchQueue.main.async {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.mapView.addAnnotations(annotations)
                }
            }
        }
    }
    
    private func initMap() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        gestureRecognizer.minimumPressDuration = 2.0
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        if let region = MKCoordinateRegion.load(withKey: "mapRegion") {
            mapView.region = region
        }
        loadPins()
    }
}

extension MKCoordinateRegion {
    public func save(withKey key:String) {
        let locationData = [center.latitude, center.longitude, span.latitudeDelta, span.longitudeDelta]
        UserDefaults.standard.set(locationData, forKey: key)
    }

    public static func load(withKey key:String) -> MKCoordinateRegion? {
        guard let region = UserDefaults.standard.object(forKey: key) as? [Double] else { return nil }
        let center = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
        let span = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
        return MKCoordinateRegion(center: center, span: span)
    }
}

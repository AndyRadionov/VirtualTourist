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

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    var selectedPin: Pin!
    
    var dataController: DataController {
       let object = UIApplication.shared.delegate
       let appDelegate = object as! AppDelegate
       return appDelegate.dataController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showInstructionsIfNeeded()
        initMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let locationInView = sender.location(in: mapView)
            let tappedCoordinate = mapView.convert(locationInView , toCoordinateFrom: mapView)
            savePin(tappedCoordinate)
            addAnnotation(tappedCoordinate)
        }
    }
    
    private func showInstructionsIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "showInstruction") {
            showAlert(title: "Instructions", message: "Long press on location to put pin", presenter: self)
            UserDefaults.standard.set(true, forKey: "showInstruction")
        }
    }
    
    private func savePin(_ coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        try? dataController.viewContext.save()
        pins.append(pin)
    }
    
    private func addAnnotation(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    private func loadPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    
        if let pinsResult = try? dataController.viewContext.fetch(fetchRequest) {
            if (pinsResult.count > 0) {
                pins = pinsResult
                var annotations = [MKPointAnnotation]()
                for pin in pinsResult {
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
        if let region = MKCoordinateRegion.load(withKey: "mapRegion") {
            mapView.region = region
        }
        loadPins()
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! PhotoAlbumViewController
        controller.selectedPin = selectedPin
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let coordinate = view.annotation!.coordinate
        selectedPin = pins.first { (pin) -> Bool in
            return pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude
        }
        performSegue(withIdentifier: "showPhotoAlbum", sender: self)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        mapView.region.save(withKey: "mapRegion")
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

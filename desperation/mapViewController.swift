//
//  mapViewController.swift
//  desperation
//
//  Created by kaguya on 2020/02/01.
//  Copyright © 2020 kaguya. All rights reserved.
//

import UIKit
import MapKit

class mapViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var map: MKMapView!
    var mapresult:[MKRoute]?
    var locManager:CLLocationManager!
    var userLocation:CLLocationCoordinate2D!
    var destLocation:CLLocationCoordinate2D!
    @IBOutlet weak var btn:UIButton!
    @IBOutlet weak var Circlebtn: UIButton!
    var CircleCheck:Int = 0
    var mkCircle = MKCircle(center:CLLocationCoordinate2DMake(0.0, 0.0),radius:1000)
    var mapViewCheck = 0
    var polyline = MKPolyline()
    var pointAno:MKPointAnnotation = MKPointAnnotation()
    
    @IBAction func AR(_ sender: Any) {
        let storyboard:UIStoryboard = self.storyboard!
        let arpage = storyboard.instantiateViewController(identifier: "arpage") as ViewController
        arpage.routes = mapresult
        self.present(arpage,animated:true,completion:nil)
    }
    
    @IBAction func CircleSet(_ sender: Any) {
        mapViewCheck = 0
        if CircleCheck == 0{
            CircleCheck = 1
            Circlebtn.setTitle("円を非表示", for: .normal)
            let userCoordinate = map.userLocation.coordinate
            mkCircle = MKCircle(center:userCoordinate,radius: 3000)
            map.addOverlay(mkCircle)
        }else{
            CircleCheck = 0
            Circlebtn.setTitle("円を表示", for: .normal)
            map.removeOverlay(mkCircle)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways:
                locManager.startUpdatingLocation()
            case .authorizedWhenInUse:
                locManager.startUpdatingLocation()
            default:
                break
            }
        initmap()
        }
    }
    
    func initmap(){
        var region:MKCoordinateRegion = map.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        map.setRegion(region,animated:true)
        map.showsUserLocation = true
        map.userTrackingMode = MKUserTrackingMode.followWithHeading
        map.userLocation.title = ""
        if pointAno.coordinate.latitude == 0{
            btn.isEnabled = false
        }
    }
    
    @IBAction func longpress(_ sender: UILongPressGestureRecognizer) {
               if sender.state == .began{
                map.removeAnnotation(pointAno)
               }
               else if sender.state == .ended{
                   let tappoint = sender.location(in: map)
                   let center = map.convert(tappoint,toCoordinateFrom:map)
                   
                   pointAno.coordinate = center
                   map.addAnnotation(pointAno)
                   btn.isEnabled = true
                   map.removeOverlay(polyline)
                   let sourceLocation = map.userLocation.coordinate
                   let destinationLocation = pointAno.coordinate
                   let sourcePlaceMark = MKPlacemark(coordinate:sourceLocation)
                   let destinationPlaceMark = MKPlacemark(coordinate:destinationLocation)
                   let directionRequest = MKDirections.Request()
                   directionRequest.source = MKMapItem(placemark:sourcePlaceMark)
                   directionRequest.destination = MKMapItem(placemark:destinationPlaceMark)
                   directionRequest.transportType = .walking
                   let directions = MKDirections(request:directionRequest)
                   directions.calculate{(response,error)in
                       guard let directionResponse = response else{
                           if let error = error{
                               print("error")
                           }
                           return
                       }
                    let route = directionResponse.routes[0]
                    self.mapViewCheck = 1
                    self.polyline = route.polyline
                    self.map.addOverlay(self.polyline, level: .aboveRoads)
                    let rect = route.polyline.boundingMapRect
                    self.map.setRegion(MKCoordinateRegion(rect),animated:true)
                    self.mapresult = response?.routes
                   }
               }
           }
    
    func locationManager(manager:CLLocationManager!,didUpdateLocations locations:[AnyObject]!){
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude,manager.location!.coordinate.longitude)
        let userLocAnnotation:MKPointAnnotation = MKPointAnnotation()
        userLocAnnotation.coordinate = userLocation
        userLocAnnotation.title = "現在値"
        map.addAnnotation(userLocAnnotation)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if mapViewCheck == 0{
            let circle = MKCircleRenderer(overlay: overlay);
            circle.strokeColor = UIColor.green
            circle.fillColor = UIColor(red: 0.0, green: 0.2, blue: 0.5, alpha: 0.3)
            circle.lineWidth = 1.0
            return circle
        }else{
        let renderer = MKPolylineRenderer(overlay:overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
        }
    }
}

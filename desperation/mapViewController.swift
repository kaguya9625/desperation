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

    @IBOutlet weak var UIsearchbtn: UISearchBar!
    @IBOutlet weak var map: MKMapView!
    var mapresult:[MKRoute]?
    var locManager:CLLocationManager!
    var userLocation:CLLocationCoordinate2D!
    var destLocation:CLLocationCoordinate2D!
    @IBOutlet weak var btn:UIButton!
    var mapViewCheck = 0
    var polyline = MKPolyline()
    var pointAno:MKPointAnnotation = MKPointAnnotation()
    
    @IBAction func AR(_ sender: Any) {
        let storyboard:UIStoryboard = self.storyboard!
        let arpage = storyboard.instantiateViewController(identifier: "arpage") as ViewController
        arpage.routes = mapresult
        arpage.pointAno = pointAno
        self.present(arpage,animated:true,completion:nil)
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
        btn.layer.cornerRadius = 15.0
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
            btn.setTitleColor(UIColor.gray,for:.normal)
        
        }
        setmapUI()
    }
    func setmapUI(){
        
        let displaySize:CGSize = UIScreen.main.bounds.size
        let width = Int(displaySize.width)
        let height = Int(displaySize.height)
        let compass = MKCompassButton(mapView: map)
        compass.compassVisibility = .visible
        compass.frame = CGRect(x: width - 50,y:height - 550,width:40,height:40)
        self.view.addSubview(compass)
        map.showsCompass = false
        
        let trackingBtn = MKUserTrackingButton(mapView:map)
        trackingBtn.layer.backgroundColor = UIColor(white:1,alpha: 0.7).cgColor
        trackingBtn.frame = CGRect(x: width - 50,y:height - 50,width:40,height:40)
        self.view.addSubview(trackingBtn)
        
        UIsearchbtn.backgroundImage = UIImage()
                UIsearchbtn.searchTextField.backgroundColor = UIColor(red: 239/255, green: 248/255, blue: 254/255, alpha: 1)
 
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
                btn.setTitleColor(UIColor(red: 135/255, green: 207/255, blue: 233/255, alpha: 1), for: .normal)
                   map.removeOverlay(polyline)
                   userLocation = map.userLocation.coordinate
                   destLocation = CLLocationCoordinate2DMake(pointAno.coordinate.latitude, pointAno.coordinate.longitude)
                   let sourcePlaceMark = MKPlacemark(coordinate:userLocation)
                   let destinationPlaceMark = MKPlacemark(coordinate:destLocation)
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
                    var region:MKCoordinateRegion = self.map.region
                    region.span.latitudeDelta = 0.02
                    region.span.longitudeDelta = 0.02
                    self.map.regionThatFits(region)
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
        let renderer = MKPolylineRenderer(overlay:overlay)
        renderer.strokeColor = UIColor(red: 145/255, green: 201/255, blue: 121/225, alpha: 1)
        renderer.lineWidth = 4.0
        return renderer
    }
    
}

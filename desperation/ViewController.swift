//
//  ViewController.swift
//  desperation
//
//  Created by kaguya on 2020/01/31.
//  Copyright © 2020 kaguya. All rights reserved.
//

import UIKit
import ARCL
import ARKit
import SceneKit
import MapKit


class ViewController: UIViewController,
                      ARSCNViewDelegate,
                      MKMapViewDelegate,
                      CLLocationManagerDelegate {
    
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var map: MKMapView!
    let sceneLocationView = SceneLocationView()
    
    var locationEstimateAnnotaion: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?

    var updateUserLocationTimer: Timer?
    var updateInfoLabelTimer: Timer?

    var centerMapOnUserLocation: Bool = true
    var userAnnotation: MKPointAnnotation?
    var routes: [MKRoute]?
    var pointAno:MKPointAnnotation = MKPointAnnotation()
    @IBOutlet var longpress: UILongPressGestureRecognizer!
    var locmanager:CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
            initmap()
            let displayDebugging = false
            sceneLocationView.showAxesNode = true
            sceneLocationView.showFeaturePoints = displayDebugging
            sceneLocationView.arViewDelegate = self
            addSceneModels()
            contentView.addSubview(sceneLocationView)
            sceneLocationView.frame = contentView.bounds
            sceneLocationView.run()
        
        routes?.forEach{map.addOverlay($0.polyline)}
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = contentView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    func initmap(){
        locmanager = CLLocationManager()
        locmanager.delegate = self
        locmanager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locmanager.distanceFilter = kCLDistanceFilterNone
        locmanager.headingFilter = kCLHeadingFilterNone
        locmanager.pausesLocationUpdatesAutomatically = false
        var region:MKCoordinateRegion = map.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        map.delegate = self
        map.setRegion(region, animated: true)
        map.showsUserLocation = true
        map.userTrackingMode = MKUserTrackingMode.followWithHeading
        locmanager.requestWhenInUseAuthorization()
        locmanager.startUpdatingHeading()
        locmanager.startUpdatingLocation()
    
    }

    func addSceneModels(){
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[weak self] in
                self?.addSceneModels()
            }
            return
        }
        print(" route")
        if let routes = routes{
        sceneLocationView.addRoutes(routes: routes){ distance -> SCNBox in
            let box = SCNBox(width: 1.75, height: 0.5, length: distance, chamferRadius: 0.25)
            box.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.7)
            return box
        }
        sceneLocationView.autoenablesDefaultLighting = true
        }
    }
    
    func mapView(_ mapView:MKMapView,viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        guard !(annotation is MKUserLocation),
            let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
        
        let marker = MKMarkerAnnotationView(annotation:annotation,reuseIdentifier: nil)
        
        if pointAnnotation == self.userAnnotation{
            marker.displayPriority = .required
            marker.glyphImage = UIImage(named:"user")
        }else{
            marker.displayPriority = .required
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named:"compass")
        }
        return marker
    }
    
    func updateUserLocation(){
        guard let currentLocation = sceneLocationView.sceneLocationManager.currentLocation else{
            return
        }
        
        DispatchQueue.main.async{[weak self] in
            guard let self = self else{
                return
            }
        
        if self.userAnnotation == nil{
            self.userAnnotation = MKPointAnnotation()
            self.map.addAnnotation(self.userAnnotation!)
        }
        
        UIView.animate(withDuration: 0.5, delay:0,options: .allowUserInteraction, animations:{
            self.userAnnotation?.coordinate = currentLocation.coordinate
            },completion:nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        let renderer = MKPolylineRenderer(overlay:overlay)
        renderer.lineWidth = 3
        renderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
        
        return renderer
       }

}
    



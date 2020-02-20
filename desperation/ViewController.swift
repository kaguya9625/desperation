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
import CoreLocation


class ViewController: UIViewController,
                      ARSCNViewDelegate,
                      MKMapViewDelegate,
                      CLLocationManagerDelegate {
    
    override var prefersStatusBarHidden: Bool{ return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{ return .slide}
    var userLocation:CLLocationCoordinate2D!
    @IBOutlet var contentView: UIView!
    @IBOutlet var map: MKMapView!
    let sceneLocationView = SceneLocationView()
    var annotationHeightAdjustmentFactor = 10.5
    var continuallyAdjustNodePositionWhenWithinRange = true
    var continuallyUpdatePositionandScale = true
    var pointAno:MKPointAnnotation = MKPointAnnotation()
    @IBOutlet weak var BackButton: UIButton!
    var locationEstimateAnnotaion: MKPointAnnotation?
    var centerMapOnUserLocation: Bool = true
    var userAnnotation: MKPointAnnotation?
    var routes: [MKRoute]?
    @IBOutlet var longpress: UILongPressGestureRecognizer!
    
    var locmanager:CLLocationManager!

    @IBAction func back(_ sender: Any) {
        let storyboard:UIStoryboard = self.storyboard!
        let mappage = storyboard.instantiateViewController(identifier: "mappage")
        self.present(mappage,animated:true,completion:nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        alert()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
            locmanager = CLLocationManager()
            locmanager.delegate = self
            locmanager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            initmap()
            BackButton.layer.cornerRadius = 15
            let displayDebugging = false
            sceneLocationView.showFeaturePoints = displayDebugging
            sceneLocationView.arViewDelegate = self
        
            addSceneModels()
            contentView.addSubview(sceneLocationView)
            sceneLocationView.frame = contentView.bounds
            sceneLocationView.run()
            map.addAnnotation(pointAno)
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
        if let routes = routes{
        sceneLocationView.addRoutes(routes: routes){ distance -> SCNBox in
            let box = SCNBox(width: 1.75, height: 0.5, length: distance, chamferRadius: 0.5)
            box.firstMaterial?.diffuse.contents = UIColor(red: 122/255, green: 186/255, blue: 224/225, alpha: 1)
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
        }
        return marker
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        let renderer = MKPolylineRenderer(overlay:overlay)
        renderer.lineWidth = 3
        renderer.strokeColor = UIColor(red: 122/255, green: 186/255, blue: 224/225, alpha: 1)
        return renderer
       }
    

    
    func alert(){
        let alert:UIAlertController = UIAlertController(title:"注意",message:"周囲に気をつけて歩行してください",preferredStyle: UIAlertController.Style.alert)
        let confirmAction = UIAlertAction(title:"OK",style:UIAlertAction.Style.default,handler:{
        (action:UIAlertAction!)-> Void in
        })
        alert.addAction(confirmAction)
        present(alert,animated:true,completion:nil)
    }
    
    func addScenewideNodeSettings(_ node:LocationNode)
    {
        if let annoNode = node as? LocationAnnotationNode{
            annoNode.annotationHeightAdjustmentFactor = annotationHeightAdjustmentFactor
        }
        node.scalingScheme = ScalingScheme.normal
        node.continuallyAdjustNodePositionWhenWithinRange = continuallyAdjustNodePositionWhenWithinRange
        node.continuallyUpdatePositionAndScale = continuallyUpdatePositionandScale
    }
    
    func locationManager(manager:CLLocationManager!,didUpdateLocations locations:[AnyObject]!){
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)

               let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
               userLocAnnotation.coordinate = userLocation
               userLocAnnotation.title = "現在地"
               map.addAnnotation(userLocAnnotation)
        map.setCenter(map.userLocation.coordinate, animated: true)
    }
    
}
    



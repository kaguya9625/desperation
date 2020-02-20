//
//  mapViewController.swift
//  desperation
//
//  Created by kaguya on 2020/02/01.
//  Copyright © 2020 kaguya. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class mapViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate,UISearchBarDelegate{
    //UI宣言
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var btn:UIButton!
    //変数、配列宣言
    var mapresult:[MKRoute]?
    var annotationArray:[MKPointAnnotation] = []
    var locManager:CLLocationManager!
    var userLocation:CLLocationCoordinate2D!
    var destLocation:CLLocationCoordinate2D!
    
    var polyline = MKPolyline()
    
    //遷移処理
    //ARpageにルートとピンの受け渡し
    @IBAction func AR(_ sender: Any) {
        let storyboard:UIStoryboard = self.storyboard!
        let arpage = storyboard.instantiateViewController(identifier: "arpage") as ViewController
        arpage.routes = mapresult
        arpage.pointAno = annotationArray[0]
        self.present(arpage,animated:true,completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
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
        setmapUI()
    }
    func setmapUI(){
        btn.isEnabled = false
        btn.setTitleColor(UIColor.gray,for:.normal)
        btn.layer.cornerRadius = 15.0
        let displaySize:CGSize = UIScreen.main.bounds.size
        let width = Int(displaySize.width)
        let height = Int(displaySize.height)
        let compass = MKCompassButton(mapView: map)
        compass.compassVisibility = .visible
        compass.frame = CGRect(x: width - 50,y:height - 600,width:40,height:40)
        self.view.addSubview(compass)
        map.showsCompass = false
        
        let trackingBtn = MKUserTrackingButton(mapView:map)
        trackingBtn.layer.backgroundColor = UIColor(white:1,alpha: 0.7).cgColor
        trackingBtn.frame = CGRect(x: width - 50,y:height - 50,width:40,height:40)
        trackingBtn.layer.cornerRadius = 10.0
        self.view.addSubview(trackingBtn)
        
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.textColor = UIColor.black
        searchBar.searchTextField.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)

    }
    //map長押し時の処理
    @IBAction func longpress(_ sender: UILongPressGestureRecognizer) {
               if sender.state == .began{
                map.removeAnnotations(annotationArray)
                annotationArray.removeAll()
               }
               else if sender.state == .ended{
                   let tappoint = sender.location(in: map)
                   let center = map.convert(tappoint,toCoordinateFrom:map)
                   let pointAno = MKPointAnnotation()
                   pointAno.coordinate = center
                   annotationArray.append(pointAno)
                   map.addAnnotation(pointAno)
                   rootsearch(pointAno)
               }
           }
    //ルート検索関数
    func rootsearch(_ pointano:MKPointAnnotation){
        map.removeOverlay(polyline)
        userLocation = map.userLocation.coordinate
        destLocation = CLLocationCoordinate2DMake(pointano.coordinate.latitude, pointano.coordinate.longitude)
        let sourcePlaceMark = MKPlacemark(coordinate:userLocation)
        let destinationPlaceMark = MKPlacemark(coordinate:destLocation)
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark:sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark:destinationPlaceMark)
        directionRequest.transportType = .walking
        let directions = MKDirections(request:directionRequest)
        directions.calculate{(response,error)in
            guard let directionResponse = response else{
                if error != nil{
                    print("error")
                }
                return
            }
         let route = directionResponse.routes[0]
         self.polyline = route.polyline
         self.map.addOverlay(self.polyline, level: .aboveRoads)
         var region:MKCoordinateRegion = self.map.region
         region.span.latitudeDelta = 0.02
         region.span.longitudeDelta = 0.02
         self.map.regionThatFits(region)
         self.btn.isEnabled = true
         self.btn.setTitleColor(UIColor(red: 135/255, green: 207/255, blue: 233/255, alpha: 1), for: .normal)
         self.mapresult = response?.routes
        }
    }
    
    //現在地が更新された際の処理
    func locationManager(manager:CLLocationManager!,didUpdateLocations locations:[AnyObject]!){
   if let coordinate = locations.last?.coordinate {
          // 現在地を拡大して表示する
          let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
          let region = MKCoordinateRegion(center: coordinate, span: span)
          map.region = region
        }
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)

               let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
               userLocAnnotation.coordinate = userLocation
               userLocAnnotation.title = "現在地"
               map.addAnnotation(userLocAnnotation)
    }
    
    //ピンを追加する処理
       func addAnnotation(_ latitude:CLLocationDegrees,_ longitude:CLLocationDegrees,_ title:String,_ subtitle:String){
           let annotation = MKPointAnnotation()
           annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
           annotation.title = title
           annotation.subtitle = subtitle
           annotationArray.append(annotation)
           map.addAnnotation(annotation)
       }
    
    //経路表示の際に表示するoverlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay:overlay)
        renderer.strokeColor = UIColor(red: 122/255, green: 186/255, blue: 224/225, alpha: 1)
        renderer.lineWidth = 4.0
        return renderer
    }
    
    //Searchbarのキャンセルボタンをクリックした際の処理
    func searchBarCancelButtonClicked(_ serachBar:UISearchBar){
        searchBar.text = ""
        deleteother()
        self.searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.map.removeAnnotations(annotationArray)
        deleteother()
    }
    
    func deleteother(){
        self.map.removeAnnotations(annotationArray)
        annotationArray.removeAll()
        map.removeOverlay(polyline)
    }
    
    //キーボードの検索を押した際の処理
    func searchBarSearchButtonClicked(_ searchBar:UISearchBar){
        self.map.removeAnnotations(annotationArray)
        self.map.removeOverlay(polyline)
        self.searchBar.endEditing(true)
        let coordinate = map.userLocation.coordinate
        let region = MKCoordinateRegion(center:coordinate,latitudinalMeters: 1000.0,longitudinalMeters: 1000.0)
        annotationArray.removeAll()
        btn.isEnabled = false
        btn.setTitleColor(UIColor.gray,for:.normal)
        Map.search(query: searchBar.text!, region: region){(result) in
            switch result {
            case .success(let mapItems):
                for map in mapItems {
                    self.addAnnotation(map.placemark.coordinate.latitude, map.placemark.coordinate.longitude, (map.name ?? "no name"), map.placemark.address)
                }
            case .failure(let error):
                print("error \(error.localizedDescription)")
            }
        }
    }
   
    //画面タップでキーボードを閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.endEditing(true)
        }
    
    //pinを選択した際の処理
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        for anno in annotationArray{
            if(annotation?.title == anno.title){
                let title:String = annotation!.title!!
                       let latitude:CLLocationDegrees = (annotation?.coordinate.latitude)!
                       let longtitude:CLLocationDegrees = (annotation?.coordinate.longitude)!
                       let alert:UIAlertController = UIAlertController(title:"目的地を設定",message:"\(title) を目的地に設定します",preferredStyle: UIAlertController.Style.alert)
                                let confirmAction = UIAlertAction(title:"OK",style:UIAlertAction.Style.default,handler:{
                                (action:UIAlertAction!)-> Void in
                                   
                                   self.map.removeAnnotations(self.annotationArray)
                                   self.addAnnotation(latitude,longtitude,title,"")
                                   self.rootsearch(annotation as! MKPointAnnotation)
                                })
                       
                       
                       let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                           (action:UIAlertAction!) -> Void in
                           for annotation in self.map.selectedAnnotations{
                               self.map.deselectAnnotation(annotation, animated: false)
                           }
                       })
                                alert.addAction(confirmAction)
                                alert.addAction(cancelAction)
                                present(alert,animated:true,completion:nil)
                           }
                       }
        }
    }




extension MKPlacemark{
    var address: String {
    let components = [self.administrativeArea, self.locality, self.thoroughfare, self.subThoroughfare]
    return components.compactMap { $0 }.joined(separator: "")
    }
}
struct Map{
    enum Result<T>{
        case success(T)
        case failure(Error)
    }
    
    static func search(query: String, region: MKCoordinateRegion? = nil, completionHandler: @escaping (Result<[MKMapItem]>) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let region = region {
            request.region = region
        }

        MKLocalSearch(request: request).start { (response, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            completionHandler(.success(response?.mapItems ?? []))
        }
    }
    
}

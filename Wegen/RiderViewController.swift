//
//  RiderViewController.swift
//  Wegen
//
//  Created by Adrien Maranville on 6/26/17.
//  Copyright © 2017 Adrien Maranville. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    
    var locationManager = CLLocationManager()
    
    var riderRequestActive = true
    
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    @IBOutlet var map: MKMapView!
    @IBOutlet weak var btnCallCar: UIButton!
    @IBAction func btnCallCarPressed(_ sender: Any) {
        if !riderRequestActive {
            if userLocation.latitude != 0 && userLocation.longitude != 0 {
                riderRequestActive = true
                self.btnCallCar.setTitle("Cancel Request", for: [])
                let riderRequest = PFObject(className: "RiderRequest")
                riderRequest["username"] = PFUser.current()?.username
                riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
                riderRequest.saveInBackground(block: { (success, error) in
                    if success {
                        print("called a car")
                    
                    } else {
                        self.btnCallCar.setTitle("Request A Car", for: [])
                        self.riderRequestActive = false
                        self.createAlert(title: "Could not call a car", message: "Please try again")
                    }
                })
            } else {
                self.createAlert(title: "Could not find location", message: "Please try a bit later")
            }
        } else {
            btnCallCar.setTitle("Request A Car", for: [])
            riderRequestActive = false
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    print(error!)
                } else if let riderRequests = objects {
                    for riderRequest in riderRequests {
                        riderRequest.deleteInBackground()
                    }
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutSegue" {
            PFUser.logOut()
            self.locationManager.stopUpdatingLocation()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        btnCallCar.isHidden = true
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        query.findObjectsInBackground(block: { (objects, error) in
            if error != nil {
                print(error!)
            } else if let riderRequests = objects {
                self.riderRequestActive = true
                self.btnCallCar.setTitle("Cancel Request", for: [])
                
            }
            
            self.btnCallCar.isHidden = false
        })
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location?.coordinate {
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.map.setRegion(region, animated: true)
            
            self.map.removeAnnotations(self.map.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation
            annotation.title = "Your Location"
            self.map.addAnnotation(annotation)
            if PFUser.current() != nil {
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("username", equalTo: (PFUser.current()?.username)!)
                query.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print(error!)
                    } else if let riderRequests = objects {
                        for riderRequest in riderRequests {
                            riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                            riderRequest.saveInBackground()
                        }
                    }
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  CustomOverlayDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/5.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class CustomOverlayDemoViewController: UIViewController, BMKMapViewDelegate  {
    
    @IBOutlet weak var _mapView: BMKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        addCustomOverlay()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
    }
    
    func addCustomOverlay() {
        let points = [
            BMKMapPointForCoordinate(CLLocationCoordinate2DMake(39.915, 116.504)),
            BMKMapPointForCoordinate(CLLocationCoordinate2DMake(40.015, 116.504)),
            BMKMapPointForCoordinate(CLLocationCoordinate2DMake(39.965, 116.604))]
        let customOverlay = CustomOverlay(points: points, count: 3)
        _mapView.addOverlay(customOverlay)
    }

    
    // MARK: - BMKMapViewDelegate
    /**
    *根据overlay生成对应的View
    *@param mapView 地图View
    *@param overlay 指定的overlay
    *@return 生成的覆盖物View
    */
    func mapView(mapView: BMKMapView!, viewForOverlay overlay: BMKOverlay!) -> BMKOverlayView! {
        
        if (overlay as? CustomOverlay) != nil {
            let customOverlayView = CustomOverlayView()
            customOverlayView.customOverlay = overlay as! CustomOverlay
            return customOverlayView
        }
        return nil
    }
}

//
//  MapViewDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/3.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class MapViewDemoViewController: UIViewController, BMKMapViewDelegate {
    
    var _mapView: BMKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _mapView = BMKMapView(frame: CGRect(x: 0, y: 190, width: self.view.frame.width, height: self.view.frame.height - 190))
        _mapView.trafficEnabled = false
        _mapView.buildingsEnabled = true
        _mapView.showMapPoi = true
        self.view.addSubview(_mapView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
    }
    
    // MARK: - IBAction
    @IBAction func changeMapTypeAction(sender: AnyObject) {
        let segment: UISegmentedControl = sender as! UISegmentedControl
        
        switch segment.selectedSegmentIndex {
        case 0:
            _mapView.mapType = UInt(BMKMapTypeStandard)
        case 1:
            _mapView.mapType = UInt(BMKMapTypeSatellite)
        default:
            break
        }
    }
    
    @IBAction func switchValueChangedAction(sender: AnyObject) {
        let switchControl = sender as! UISwitch
        let value = switchControl.on
        
        switch switchControl.tag {
        case 0://路况
            _mapView.trafficEnabled = value
        case 1://3D楼宇
            _mapView.buildingsEnabled = value
        case 2://百度热力图
            _mapView.baiduHeatMapEnabled = value
        case 3://底图标注
            _mapView.showMapPoi = value
        default:
            break
        }
    }
}
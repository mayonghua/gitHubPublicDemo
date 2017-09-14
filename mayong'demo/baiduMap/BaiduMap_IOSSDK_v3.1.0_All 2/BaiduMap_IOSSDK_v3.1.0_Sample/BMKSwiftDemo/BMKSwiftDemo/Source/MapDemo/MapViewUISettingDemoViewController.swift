//
//  MapViewUISettingDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/5.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class MapViewUISettingDemoViewController: UIViewController, BMKMapViewDelegate  {
    
    @IBOutlet weak var _mapView: BMKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _mapView.showMapScaleBar = true
        _mapView.mapScaleBarPosition = CGPointMake(10, _mapView.frame.height - 45)
        setMapPadding()
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
    
    func setMapPadding() {
        ///地图预留边界，默认：UIEdgeInsetsZero。设置后，会根据mapPadding调整logo、比例尺、指南针的位置，以及targetScreenPt(BMKMapStatus.targetScreenPt)
        _mapView.mapPadding = UIEdgeInsetsMake(0, 0, 28, 0)
        
        let label = UILabel(frame: CGRectMake(0, _mapView.frame.origin.y + _mapView.frame.size.height - 28, self.view.frame.size.width, 28))
        label.text = "已设置mapPadding为(0, 0, 28, 0)"
        label.font = UIFont.systemFontOfSize(13)
        label.textAlignment = .Center
        label.backgroundColor = UIColor.whiteColor()
        label.alpha = 0.7
        self.view.addSubview(label)
        self.view.bringSubviewToFront(label)
    }
    
    // MARK: - IBAction
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        switch sender.tag {
        case 0://手势缩放
            _mapView.zoomEnabled = sender.on
        case 1://平移
            _mapView.scrollEnabled = sender.on
        case 2://比例尺
            _mapView.showMapScaleBar = sender.on
            _mapView.mapScaleBarPosition = CGPointMake(10, _mapView.frame.height - 70)
        case 3://所有手势
            _mapView.gesturesEnabled = sender.on
        default:
            return
        }

    }

    //改变指南针位置
    @IBAction func compassPositionChange(sender: UISegmentedControl) {
        var point: CGPoint
        if sender.selectedSegmentIndex == 0 {
            point = CGPointMake(10, 10)
        } else {
            point = CGPointMake(_mapView.frame.width - 50, 10)
        }
        _mapView.compassPosition = point
    }
    
    // MARK: - BMKMapViewDelegate
    
}

//
//  WayPointsSearchDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/6.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class WayPointsSearchDemoViewController: UIViewController, BMKMapViewDelegate, BMKRouteSearchDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var _mapView: BMKMapView!
    @IBOutlet weak var startAddressField: UITextField!
    @IBOutlet weak var endAddressField: UITextField!
    @IBOutlet weak var wayPointAddressField: UITextField!
    
    var routeSearch: BMKRouteSearch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeSearch = BMKRouteSearch()
        
        startAddressField.delegate = self
        wayPointAddressField.delegate = self
        endAddressField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        routeSearch.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
        routeSearch.delegate = nil
    }
    
    // MARK: - IBAction
    
    @IBAction func wayPointsCarRouteSearch(sender: UIButton) {
        let from = BMKPlanNode()
        from.name = startAddressField.text
        from.cityName = "北京"
        let to = BMKPlanNode()
        to.name = endAddressField.text
        to.cityName = "北京"
        
        let wayPoint = BMKPlanNode()
        wayPoint.name = wayPointAddressField.text
        wayPoint.cityName = "北京"
        
        let drivingRouteSearchOption = BMKDrivingRoutePlanOption()
        drivingRouteSearchOption.from = from
        drivingRouteSearchOption.to = to
        drivingRouteSearchOption.wayPointsArray = [wayPoint]
        
        let flag = routeSearch.drivingSearch(drivingRouteSearchOption)
        if flag {
            print("驾乘-途经点 检索发送成功")
        }else {
            print("驾乘-途经点 检索发送失败")
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        startAddressField.resignFirstResponder()
        wayPointAddressField.resignFirstResponder()
        endAddressField.resignFirstResponder()
        return true
    }
    
    // MARK: - BMKRouteSearchDelegate

    /**
    *返回驾乘搜索结果
    *@param searcher 搜索对象
    *@param result 搜索结果，类型为BMKDrivingRouteResult
    *@param error 错误号，@see BMKSearchErrorCode
    */
    func onGetDrivingRouteResult(searcher: BMKRouteSearch!, result: BMKDrivingRouteResult!, errorCode error: BMKSearchErrorCode) {
        print("onGetDrivingRouteResult: \(error)")
        
        _mapView.removeAnnotations(_mapView.annotations)
        _mapView.removeOverlays(_mapView.overlays)
        
        if error == BMK_SEARCH_NO_ERROR {
            let plan = result.routes[0] as! BMKDrivingRouteLine
            
            let size = plan.steps.count
            var planPointCounts = 0
            for i in 0..<size {
                let transitStep = plan.steps[i] as! BMKDrivingStep
                if i == 0 {
                    let item = RouteAnnotation()
                    item.coordinate = plan.starting.location
                    item.title = "起点"
                    item.type = 0
                    _mapView.addAnnotation(item)  // 添加起点标注
                }else if i == size - 1 {
                    let item = RouteAnnotation()
                    item.coordinate = plan.terminal.location
                    item.title = "终点"
                    item.type = 1
                    _mapView.addAnnotation(item)  // 添加终点标注
                }
                
                // 添加 annotation 节点
                let item = RouteAnnotation()
                item.coordinate = transitStep.entrace.location
                item.title = transitStep.instruction
                item.degree = Int(transitStep.direction) * 30
                item.type = 4
                _mapView.addAnnotation(item)
                
                // 轨迹点总数累计
                planPointCounts = Int(transitStep.pointsCount) + planPointCounts
            }
            
            // 添加途径点
            if plan.wayPoints != nil {
                for tempNode in plan.wayPoints as! [BMKPlanNode] {
                    let item = RouteAnnotation()
                    item.coordinate = tempNode.pt
                    item.type = 5
                    item.title = tempNode.name
                    _mapView.addAnnotation(item)
                }
            }
            
            // 轨迹点
            var tempPoints = Array(count: planPointCounts, repeatedValue: BMKMapPoint(x: 0, y: 0))
            var i = 0
            for j in 0..<size {
                let transitStep = plan.steps[j] as! BMKDrivingStep
                for k in 0..<Int(transitStep.pointsCount) {
                    tempPoints[i].x = transitStep.points[k].x
                    tempPoints[i].y = transitStep.points[k].y
                    i++
                }
            }
            
            // 通过 points 构建 BMKPolyline
            let polyLine = BMKPolyline(points: &tempPoints, count: UInt(planPointCounts))
            // 添加路线 overlay
            _mapView.addOverlay(polyLine)
            mapViewFitPolyLine(polyLine)
        }
    }

    
    // MARK: - BMKMapViewDelegate
    
    /**
    *根据anntation生成对应的View
    *@param mapView 地图View
    *@param annotation 指定的标注
    *@return 生成的标注View
    */
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if let routeAnnotation = annotation as! RouteAnnotation? {
            return getViewForRouteAnnotation(routeAnnotation)
        }
        return nil
    }
    
    /**
     *根据overlay生成对应的View
     *@param mapView 地图View
     *@param overlay 指定的overlay
     *@return 生成的覆盖物View
     */
    func mapView(mapView: BMKMapView!, viewForOverlay overlay: BMKOverlay!) -> BMKOverlayView! {
        if overlay as! BMKPolyline? != nil {
            let polylineView = BMKPolylineView(overlay: overlay as! BMKPolyline)
            polylineView.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.7)
            polylineView.lineWidth = 3
            return polylineView
        }
        return nil
    }
    
    // MARK: -
    
    func getViewForRouteAnnotation(routeAnnotation: RouteAnnotation!) -> BMKAnnotationView? {
        var view: BMKAnnotationView?
        
        var imageName: String?
        switch routeAnnotation.type {
        case 0:
            imageName = "nav_start"
        case 1:
            imageName = "nav_end"
        case 2:
            imageName = "nav_bus"
        case 3:
            imageName = "nav_rail"
        case 4:
            imageName = "direction"
        case 5:
            imageName = "nav_waypoint"
        default:
            return nil
        }
        let identifier = "\(imageName)_annotation"
        view = _mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if view == nil {
            view = BMKAnnotationView(annotation: routeAnnotation, reuseIdentifier: identifier)
            view?.centerOffset = CGPointMake(0, -(view!.frame.size.height * 0.5))
            view?.canShowCallout = true
        }
        
        view?.annotation = routeAnnotation
        
        let bundlePath = NSBundle.mainBundle().resourcePath?.stringByAppendingString("/mapapi.bundle/")
        let bundle = NSBundle(path: bundlePath!)
        if let imagePath = bundle?.resourcePath?.stringByAppendingString("/images/icon_\(imageName!).png") {
            var image = UIImage(contentsOfFile: imagePath)
            if routeAnnotation.type == 4 {
                image = imageRotated(image, degrees: routeAnnotation.degree)
            }
            if image != nil {
                view?.image = image
            }
        }
        
        return view
    }
    
    
    //根据polyline设置地图范围
    func mapViewFitPolyLine(polyline: BMKPolyline!) {
        if polyline.pointCount < 1 {
            return
        }
        
        let pt = polyline.points[0]
        var ltX = pt.x
        var rbX = pt.x
        var ltY = pt.y
        var rbY = pt.y
        
        for i in 1..<polyline.pointCount {
            let pt = polyline.points[Int(i)]
            if pt.x < ltX {
                ltX = pt.x
            }
            if pt.x > rbX {
                rbX = pt.x
            }
            if pt.y > ltY {
                ltY = pt.y
            }
            if pt.y < rbY {
                rbY = pt.y
            }
        }
        
        let rect = BMKMapRectMake(ltX, ltY, rbX - ltX, rbY - ltY)
        _mapView.visibleMapRect = rect
        _mapView.zoomLevel = _mapView.zoomLevel - 0.3
    }
    
    //旋转图片
    func imageRotated(image: UIImage!, degrees: Int!) -> UIImage {
        let width = CGImageGetWidth(image.CGImage)
        let height = CGImageGetHeight(image.CGImage)
        let rotatedSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(rotatedSize);
        let bitmap = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        CGContextRotateCTM(bitmap, CGFloat(Double(degrees) * M_PI / 180.0));
        CGContextRotateCTM(bitmap, CGFloat(M_PI));
        CGContextScaleCTM(bitmap, -1.0, 1.0);
        CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), image.CGImage);
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }

}

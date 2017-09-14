//
//  FavoritesDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

let INDEX_TAG_DIS = 1000


class MyFavoriteAnnotation: BMKPointAnnotation {
    var favIndex: Int = 0
    var favPoiInfo: BMKFavPoiInfo?
}

class FavoritesDemoViewController: UIViewController, BMKMapViewDelegate  {
    
    @IBOutlet weak var _mapView: BMKMapView!
    
    @IBOutlet weak var coorLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var updateView: UIControl!
    @IBOutlet weak var updateLatTextField: UITextField!
    @IBOutlet weak var updateLonTextField: UITextField!
    @IBOutlet weak var updateNameTextField: UITextField!
    
    var favManager: BMKFavPoiManager!
    var coordinate: CLLocationCoordinate2D?
    var favPoiInfos = [BMKFavPoiInfo]()
    var curFavIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView.hidden = true
        updateView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        favManager = BMKFavPoiManager()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(FavoritesDemoViewController.hiddenKeyBoard))
        tap.cancelsTouchesInView = false//添加自定义手势时，需设置，否则影响地图的操作
        tap.delaysTouchesEnded = false//添加自定义手势时，需设置，否则影响地图的操作
        self.view.addGestureRecognizer(tap)
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
    //收藏点
    @IBAction func saveAction(sender: UIButton) {
        hiddenKeyBoard()
        if nameTextField.text?.characters.count == 0 {
            PromptInfo.showText("请输入名称")
            return;
        }
        if coordinate == nil {
            PromptInfo.showText("请获取经纬度")
            return;
        }
        let poiInfo = BMKFavPoiInfo()
        poiInfo.pt = coordinate!
        poiInfo.poiName = nameTextField.text
        let res = favManager.addFavPoi(poiInfo)
        if res == 1 {
            PromptInfo.showText("保存成功")
        } else {
            PromptInfo.showText("保存失败")
        }

    }
    
    //获取所有收藏点
    @IBAction func getAllAction(sender: UIButton) {
        hiddenKeyBoard()
        if let favPois = favManager.getAllFavPois() as? [BMKFavPoiInfo] {
            favPoiInfos.removeAll()
            favPoiInfos.appendContentsOf(favPois)
            updateMapAnnotations()
        }
    }
    
    //删除所有收藏点
    @IBAction func deleteAllAction(sender: UIButton) {
        hiddenKeyBoard()
        let res = favManager.clearAllFavPois()
        if res {
            PromptInfo.showText("清除成功")
            favPoiInfos.removeAll()
            updateMapAnnotations()
        } else {
            PromptInfo.showText("清除失败")
        }
    }
    
    ///取消更新
    @IBAction func updateCancelAction(sender: AnyObject) {
        cancelUpdateView()
    }
    
    ///保存更新
    @IBAction func updateSaveAction(sender: UIButton) {
        let lat = Double(updateLatTextField.text!)
        if (lat == 0 || lat < -90 || lat > 90) {
            PromptInfo.showText("请输入正确的纬度")
            return;
        }
        let lon = Double(updateLonTextField.text!)
        if (lon == 0 || lon < -180 || lon > 180) {
            PromptInfo.showText("请输入正确的经度")
            return;
        }
        if updateNameTextField.text?.characters.count == 0 {
            PromptInfo.showText("请输入名称")
            return;
        }
        
        let favInfo = favPoiInfos[curFavIndex]
        favInfo.pt = CLLocationCoordinate2DMake(lat!, lon!)
        favInfo.poiName = updateNameTextField.text
        let res = favManager.updateFavPoi(favInfo.favId, favPoiInfo: favInfo)
        if res {
            PromptInfo.showText("更新成功")
            cancelUpdateView()
            updateMapAnnotations()
        } else {
            PromptInfo.showText("更新失败")
        }
    }
    
    // MARK: - BMKMapViewDelegate
    /**
    *点中底图空白处会回调此接口
    *@param mapview 地图View
    *@param coordinate 空白处坐标点的经纬度
    */
    func mapView(mapView: BMKMapView!, onClickedMapBlank coordinate: CLLocationCoordinate2D) {
        hiddenKeyBoard()
    }
    
    /**
    *双击地图时会回调此接口
    *@param mapview 地图View
    *@param coordinate 返回双击处坐标点的经纬度
    */
    func mapView(mapView: BMKMapView!, onClickedMapPoi mapPoi: BMKMapPoi!) {
        hiddenKeyBoard()
    }
    
    /**
    *长按地图时会回调此接口
    *@param mapview 地图View
    *@param coordinate 返回长按事件坐标点的经纬度
    */
    func mapview(mapView: BMKMapView!, onLongClick coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        coorLabel.text = "\(coordinate.longitude),\(coordinate.latitude)"
    }
    
    // 根据anntation生成对应的View
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if let myAnotation = annotation as? MyFavoriteAnnotation {
            let annotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: "FavPoiMark")
            // 设置颜色
            annotationView.pinColor = UInt(BMKPinAnnotationColorPurple)
            // 从天上掉下效果
            annotationView.animatesDrop = false
            annotationView.canShowCallout = true
            annotationView.annotation = annotation
            
            ///添加更新按钮
            let updateButton = UIButton(type: .System)
            updateButton.frame = CGRectMake(10, 0, 32, 41)
            updateButton.setTitle("更新", forState: .Normal)
            updateButton.addTarget(self, action: Selector("updateAction:"), forControlEvents: .TouchUpInside)
            updateButton.tag = myAnotation.favIndex + INDEX_TAG_DIS
            annotationView.leftCalloutAccessoryView = updateButton
            ///添加删除按钮
            let delButton = UIButton(type: .System)
            delButton.frame = CGRectMake(10, 0, 32, 41)
            delButton.setTitle("删除", forState: .Normal)
            delButton.addTarget(self, action: Selector("deleteAction:"), forControlEvents: .TouchUpInside)
            delButton.tag = myAnotation.favIndex + INDEX_TAG_DIS
            annotationView.rightCalloutAccessoryView = delButton
            
            return annotationView
        }
        return nil
    }

    
    // MARK: - 
    ///点击paopao更新按钮
    func updateAction(sender: UIButton) {
        curFavIndex = sender.tag - INDEX_TAG_DIS;
        if curFavIndex < favPoiInfos.count {
            let favInfo = favPoiInfos[curFavIndex]
            updateLatTextField.text = "\(favInfo.pt.latitude)"
            updateLonTextField.text = "\(favInfo.pt.longitude)"
            updateNameTextField.text = favInfo.poiName;
            updateLatTextField.becomeFirstResponder()
            updateView.hidden = false
        }
    }
    
    ///点击paopao删除按钮
    func deleteAction(sender: UIButton) {
        let favIndex = sender.tag - INDEX_TAG_DIS;
        if favIndex < favPoiInfos.count {
            let favInfo = favPoiInfos[favIndex]
            if favManager.deleteFavPoi(favInfo.favId) {
                favPoiInfos.removeAtIndex(favIndex)
                updateMapAnnotations()
                PromptInfo.showText("删除成功")
            } else {
                PromptInfo.showText("删除失败")
            }
        }
    }
    
    
    ///更新地图标注
    func updateMapAnnotations() {
        _mapView.removeAnnotations(_mapView.annotations)
        var annos = [MyFavoriteAnnotation]()
        var index = 0
        for info in favPoiInfos {
            let favAnnotation = MyFavoriteAnnotation()
            favAnnotation.title = info.poiName
            favAnnotation.coordinate = info.pt
            favAnnotation.favPoiInfo = info
            favAnnotation.favIndex = index
            
            annos.append(favAnnotation)
            index++
        }
        _mapView.addAnnotations(annos)
    }

    
    ///取消显示更新view
    func cancelUpdateView() {
        updateLatTextField.resignFirstResponder()
        updateLonTextField.resignFirstResponder()
        updateNameTextField.resignFirstResponder()
        updateView.hidden = true
    }
    
    func hiddenKeyBoard() {
        nameTextField.resignFirstResponder()
    }
}

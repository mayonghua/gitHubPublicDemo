//
//  HeatMapDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class HeatMapDemoViewController: UIViewController, BMKMapViewDelegate {
    
    @IBOutlet weak var _mapView: BMKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化导航栏右侧按钮“说明”
        let customRightBarBuutonItem = UIBarButtonItem(title: "说明", style: .Plain, target: self, action: Selector("showGuide"))
        self.navigationItem.rightBarButtonItem = customRightBarBuutonItem
        
        _mapView.zoomLevel = 5
        _mapView.setCenterCoordinate(CLLocationCoordinate2DMake(35.718, 111.581), animated: false)
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
    
    @IBAction func onClickAddHeatMap(sender: UIButton) {
        // 读取数据
        let jsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("locations", ofType: "json")!)
        if jsonData != nil {
            let json = try? NSJSONSerialization.JSONObjectWithData(jsonData!, options:NSJSONReadingOptions.AllowFragments)
            let array: Array<Dictionary<String, Double>>? = json as? Array<Dictionary<String, Double>>

            if array != nil {
                // 创建热力图数据类
                let heatMap = BMKHeatMap()
                // 创建热力图数据数组
                let heatData = NSMutableArray()

                for dic in array! {
                    // 创建 BMKHeatMapNode
                    let heatMapNode = BMKHeatMapNode()
                    let coordinate = CLLocationCoordinate2DMake(dic["lat"]!, dic["lng"]!)
                    heatMapNode.pt = coordinate
                    // 随机生成点强度
                    heatMapNode.intensity = Double(arc4random())
                    // 添加 BMKHeatMapNode 到数组
                    heatData.addObject(heatMapNode)
                }
                
                heatMap.mData = heatData
                // 调用 mapView 中的方法根据热力图数据添加热力图
                _mapView.addHeatMap(heatMap)
            }
        }
    }
    
    @IBAction func onClickRemoveHeatMap(sender: UIButton) {
        _mapView.removeHeatMap()
    }
    
    // 说明按钮
    func showGuide() {
        let alertView = UIAlertController(title: "说明", message: "此处为热力图绘制功能，需要开发者传入空间位置数据，由SDK帮助实现本地的渲染绘制", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
        alertView.addAction(okAction)
        self.presentViewController(alertView, animated: true, completion: nil)
    }

}
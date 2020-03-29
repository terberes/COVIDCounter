//
//  CounterViewController.swift
//  COVIDCounter
//
//  Created by Nikita Kurlaev on 29.03.2020.
//  Copyright © 2020 Nikita Kurlaev. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

public struct TotalData {
   // let date: Date
    let cases: Int
    let deaths: Int
    let recovered: Int
}

class CounterViewController: NSViewController {

    @IBOutlet weak var infectedLabel: NSTextField!
    @IBOutlet weak var recoveredLabel: NSTextField!
    @IBOutlet weak var deadLabel: NSTextField!
    @IBOutlet weak var updateButton: NSButton!
    @IBOutlet weak var updateLabel: NSTextField!
    @IBOutlet weak var moreButton: NSButton!
    @IBOutlet var moreMenu: NSMenu!
    
    @IBOutlet weak var clearCacheMenuItem: NSMenuItem!
    @IBOutlet weak var quitMenuItem: NSMenuItem!
    
    @objc func clearCache(_ sender: Any?) {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        let def = UserDefaults.standard
        def.set(0, forKey: "cases")
        def.set(0, forKey: "deaths")
        def.set(0, forKey: "recovered")
    }
    
    @objc func showMenu(_ sender: Any?) {
        let point = CGPoint(x: moreButton.frame.minX, y: moreButton.frame.minY)
        moreMenu.popUp(positioning: moreMenu.item(at: 0), at: point, in: view)
    }
    
    let apiUrl = "https://covidapi.info/api/v1/"
    
    func setVals(data: TotalData) {
        infectedLabel.stringValue = String(data.cases)
        deadLabel.stringValue = String(data.deaths)
        recoveredLabel.stringValue = String(data.recovered)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButton.keyEquivalent = "r"
        updateButton.action = #selector(updateGlobalData(_:))
        updateButton.focusRingType = .none
        clearCacheMenuItem.action = #selector(clearCache(_:))
        quitMenuItem.action = #selector(NSApplication.terminate(_:))
        moreButton.action = #selector(showMenu(_:))
        let def = UserDefaults.standard
        let cases = def.integer(forKey: "cases")
        let deaths = def.integer(forKey: "deaths")
        let recovered = def.integer(forKey: "recovered")
        guard cases != 0 && deaths != 0 && recovered != 0 else {
            updateGlobalData(nil)
            return
        }
        setVals(data: TotalData(cases: cases, deaths: deaths, recovered: recovered))
    }
    
    @objc func updateGlobalData(_ sender: Any?) {
        updateLabel.isHidden = false
        updateLabel.stringValue = "Updating..."
        AF.request(apiUrl + "global").validate(statusCode: 200..<300).responseJSON { responseData in
            guard responseData.response?.statusCode != nil && responseData.response?.statusCode == 200 else
            { self.updateLabel.stringValue = "Failed to update, please try again!"; return }
            guard let val = responseData.value else
            { self.updateLabel.stringValue = "Failed to update, please try again!"; return }
            let json = JSON(val)
            guard let result = json["result"].dictionary else
            { self.updateLabel.stringValue = "Failed to update, please try again!"; return }
            let def = UserDefaults.standard
            def.set(result["confirmed"]!.intValue, forKey: "cases")
            def.set(result["deaths"]!.intValue, forKey: "deaths")
            def.set(result["recovered"]!.intValue, forKey: "recovered")
            self.updateLabel.isHidden = true
            self.setVals(data: TotalData(cases: result["confirmed"]!.intValue, deaths: result["deaths"]!.intValue, recovered: result["recovered"]!.intValue))
        }
    }
    
}

extension CounterViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> CounterViewController {
    //1.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    //2.
    let identifier = NSStoryboard.SceneIdentifier("CounterViewController")
    //3.
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? CounterViewController else {
      fatalError("Why cant i find CounterViewController? - Check Main.storyboard")
    }
    return viewcontroller
  }
}

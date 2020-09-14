//
//  SwiftViewController.swift
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 2020/9/14.
//  Copyright © 2020 Nicholas.Xu. All rights reserved.
//

import UIKit
import CoreDataEnvir

@objc(SwiftViewController)
class SwiftViewController: UIViewController {
    
    @objc override func viewDidLoad() {
        super.viewDidLoad()
        CoreDataEnvir.mainInstance()
        print("Team.totalCount:", Team.totalCount())
        print("Member.totalCount:", Member.totalCount())
    }
    
}

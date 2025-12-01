//
//  ViewController.swift
//  LeakTest
//
//  Created by Parkdaeho on 2023/07/05.
//

import UIKit

class A {
    var b: B
    
    init() { b = B() }
    
    init(b: B) {
        self.b = b
    }
}

class B {
    var a: A
    
    init() { self.a = A() }
    
    init(a: A) {
        self.a = a
    }
}

final class ViewController: UIViewController {
    
    var arrData: [Data] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }

    @IBAction func triggerMemoryWarning(_ sender: Any) {
        let d = Data.init(repeating: 100, count: 1200000000)
        arrData.append(d)
    }

}


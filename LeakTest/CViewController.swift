//
//  CViewController.swift
//  LeakTest
//
//  Created by Parkdaeho on 11/13/25.
//

import UIKit

final actor MyActor {
    struct Framework {
        func increment() {}
        func decrement() {}
    }
    let framework = Framework()
    func increment() {
        framework.increment()
    }
    
    func decrement() {
        framework.decrement()
    }
}

final class CViewController: UIViewController {
    
    let actor = MyActor()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func increment(_ sender: Any) {
//        actor.increment()
    }
    
    @IBAction func decrement(_ sender: Any) {
//        actor.decrement()
    }
    
}

final class OuterType {
    let actor = MyActor()
    
    func increment() {
        Task {
            await actor.increment()
            await MainActor.run {
                updateUI()
            }
        }
    }
    
    func updateUI() {
    }
}

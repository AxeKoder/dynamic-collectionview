//
//  BViewController.swift
//  LeakTest
//
//  Created by Parkdaeho on 2023/09/07.
//

import UIKit




class BViewController: UIViewController {
    var closure: (() -> Void)?
    
    var cellItems: [String] = (0..<10).map(String.init)
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        asyncWeakSelf()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.performBatchUpdates(nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(performBatchUpdate(_:)), name: NSNotification.Name("PerformBatchUpdate"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func asyncWeakSelf() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: { [weak self] in
            guard let self = self else { return }
            self.setClosure {
                let view = UIView(frame: .zero)
                self.view.addSubview(view)
                print("======= addSubview Done =======")
            }
        })
    }
    
    private func setClosure(closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000), execute: {
            closure()
        })
    }
    
    @IBAction func doClosure(_ sender: Any) {
        self.closure?()
    }
    
    @IBAction func actionPlus(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("AddItem"), object: nil, userInfo: nil)
        tableView.performBatchUpdates({})
    }
    
    @IBAction func actionMinus(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("RemoveItem"), object: nil, userInfo: nil)
        tableView.performBatchUpdates({})
    }
    
    @IBAction func resize(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("Resize"), object: nil, userInfo: nil)
    }
    
    @objc func performBatchUpdate(_ sender: Any) {
        tableView.performBatchUpdates({})
    }
}

extension BViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SmallTableCell.identifier, for: indexPath) as? SmallTableCell else {
                return .init()
            }
            cell.setupUI()
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LargeTableCell.identifier, for: indexPath) as? LargeTableCell else {
                return .init()
            }
            return cell
        }
        
        return .init()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


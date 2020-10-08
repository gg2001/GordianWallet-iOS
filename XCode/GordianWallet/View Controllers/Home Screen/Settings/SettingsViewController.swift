//
//  SettingsViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var doneBlock : ((Bool) -> Void)?
    let ud = UserDefaults.standard
    @IBOutlet var settingsTable: UITableView!
    var exportPressed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTable.delegate = self
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        load()
        
    }
    
    @IBAction func goToSeeds(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToSeeds", sender: vc)
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        doneBlock!(true)
        
    }
    
    
    func load() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.settingsTable.reloadData()
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let label = settingsCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        let thumbnail = settingsCell.viewWithTag(2) as! UIImageView
        settingsCell.selectionStyle = .none
        
        switch indexPath.section {
            
        case 0:
            thumbnail.image = UIImage(systemName: "lock.shield")
            label.text = "Export Tor V3 Authentication Public Key"
            return settingsCell
            
        case 1:
            thumbnail.image = UIImage(systemName: "desktopcomputer")
            label.text = "Node Manager"
            return settingsCell
            
        case 2:
            thumbnail.image = UIImage(systemName: "desktopcomputer")
            label.text = "Spotbit Server"
            return settingsCell
            
        case 3:
            if (exportPressed) {
                let spinnerCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
                let spinnerLabel = spinnerCell.viewWithTag(1) as! UILabel
                spinnerLabel.textColor = .lightGray
                let spinnerThumbnail = spinnerCell.viewWithTag(2) as! UIImageView
                spinnerCell.selectionStyle = .none
                let spinner = UIActivityIndicatorView()
                spinner.frame = CGRect(x: settingsTable.frame.maxX - 80, y: (spinnerCell.frame.height / 2) - 10, width: 20, height: 20)
                spinnerCell.addSubview(spinner)
                spinner.startAnimating()
                
                spinnerThumbnail.image = UIImage(systemName: "desktopcomputer")
                spinnerLabel.text = "Export Transactions"
                return spinnerCell
            } else {
                thumbnail.image = UIImage(systemName: "desktopcomputer")
                label.text = "Export Transactions"
                return settingsCell
            }
        
        case 4:
            thumbnail.image = UIImage(systemName: "exclamationmark.triangle")
            label.text = "Delete Core Data"
            return settingsCell
            
        case 5:
            thumbnail.image = UIImage(systemName: "exclamationmark.triangle")
            label.text = "Delete Keychain Items"
            return settingsCell
            
        default:
            let cell = UITableViewCell()
            cell.backgroundColor = UIColor.clear
            return cell
            
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 6
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 20
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
        case 0:
            
            return 50
            
        default:
            
            return 30
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
        switch indexPath.section {
            
        case 0:
            
            goToAuth()
            
        case 1:
            
            nodeManager()
            
        case 2:
            
            segueToPrice()
            
        case 3:
        
            exportTxs()
        
        case 4:
        
            resetApp()
            
        case 5:
            
            promptToDeleteKeychain()
            
        default:
            
            break
            
        }
        
    }
    
    func exportTxs() {
        let exportTransactions = ExportTransactions()
        if (exportTransactions.check()) {
            DispatchQueue.main.async { [unowned vc = self] in
                let alert = UIAlertController(title: "Transactions unavailable", message: "Please wait until transactions have loaded", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                vc.present(alert, animated: true, completion: nil)
            }
        } else {
            if (exportPressed == false) {
                exportPressed = true
                settingsTable.reloadData()
                let group = DispatchGroup()
                group.enter()
                let fx = FiatConverter.sharedInstance
                fx.getFxRate() { (fxRate) in
                    self.exportPressed = false
                    group.leave()
                }
                group.notify(queue: .main) {
                    DispatchQueue.main.async { [unowned vc = self] in
                        self.settingsTable.reloadData()
                        let alert = UIAlertController(title: "Export Transactions", message: "Export to CSV or Beancount?", preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "CSV", style: .default, handler: { [unowned vc = self] action in
                            let csvString: String = exportTransactions.createCSV()
                            let fileManager = FileManager.default
                            do {
                                let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                                let fileURL = path.appendingPathComponent("gordian.csv")
                                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                                let objectsToShare = [fileURL]
                                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

                                vc.present(activityVC, animated: true, completion: nil)
                            } catch {
                                print("error creating file")
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Beancount", style: .default, handler: { [unowned vc = self] action in
                            let beancountString: String = exportTransactions.createBeancount()
                            let fileManager = FileManager.default
                            do {
                                let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                                let fileURL = path.appendingPathComponent("gordian.beancount")
                                try beancountString.write(to: fileURL, atomically: true, encoding: .utf8)
                                let objectsToShare = [fileURL]
                                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

                                vc.present(activityVC, animated: true, completion: nil)
                            } catch {
                                print("error creating file")
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        #if !targetEnvironment(macCatalyst)
                            alert.popoverPresentationController?.sourceView = vc.settingsTable
                        #endif
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        /*
        let exportTransactions = ExportTransactions()
        let csvString: String = exportTransactions.createCSV()
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("gordian.csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            let objectsToShare = [fileURL]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

            self.present(activityVC, animated: true, completion: nil)
        } catch {
            print("error creating file")
        }
        */
    }
    
    private func promptToDeleteKeychain() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Are you sure!?", message: "After performing this action you need to force quit the app and restart it.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes, delete", style: .destructive, handler: { [unowned vc = self] action in
                vc.deleteKeychainItems()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            #if !targetEnvironment(macCatalyst)
                alert.popoverPresentationController?.sourceView = vc.settingsTable
            #endif
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteKeychainItems() {
        KeyChain.removeAll()
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        showAlert(vc: self, title: "keychain cleared", message: "You will need to force quit and restart the app for changes to take effect.")
    }
    
    func resetApp() {
        
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "Are you sure!?", message: "This will delete ALL your wallets from your device, nodes, auth keys, encryption keys and will completely wipe the app!\n\nAfter using this button you should force quit the app and reopen it to prevent weird behavior and possible crashes.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Yes, reset now!", style: .destructive, handler: { action in
                var deleted = true
                let entities = [ENTITY.nodes, ENTITY.wallets, ENTITY.seeds, ENTITY.transactions, ENTITY.lockedUtxos]
                for (i, entity) in entities.enumerated() {
                    CoreDataService.deleteAllData(entity: entity) { success in
                        if i == entities.count + 1 {
                            if !success {
                                deleted = false
                            }
                            if deleted {
                                showAlert(vc: vc, title: "Data deleted", message: "App data has been deleted.")
                            } else {
                                showAlert(vc: vc, title: "Error", message: "There was an error deleting the apps data.")
                            }
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            #if !targetEnvironment(macCatalyst)
                alert.popoverPresentationController?.sourceView = vc.settingsTable
            #endif
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func nodeManager() {
        
        DispatchQueue.main.async { [unowned vc = self] in
        
            vc.performSegue(withIdentifier: "nodeManager", sender: vc)
            
        }
        
    }
    
    func goToAuth() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goToAuth", sender: vc)
            
        }
        
    }
    
    func segueToPrice() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "segueToPrice", sender: vc)
        
        }
    }
    
}

//
//  ConfirmRecoveryViewController.swift
//  FullyNoded2
//
//  Created by Peter on 17/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ConfirmRecoveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    weak var nodeLogic = NodeLogic.sharedInstance
    let connectingView = ConnectingView()
    var words:String?
    var walletNameHash = ""
    var walletDict = [String:Any]()
    var derivation:String?
    var confirmedDoneBlock: ((Bool) -> Void)?
    var addresses = [String]()
    var descriptorStruct:DescriptorStruct!
    
    @IBOutlet var walletLabel: UILabel!
    @IBOutlet var walletName: UILabel!
    @IBOutlet var walletDerivation: UILabel!
    @IBOutlet var walletBirthdate: UILabel!
    @IBOutlet var walletType: UILabel!
    @IBOutlet var walletNetwork: UILabel!
    @IBOutlet var walletBalance: UILabel!
    @IBOutlet var addressTable: UITableView!
    @IBOutlet var cancelOutlet: UIButton!
    @IBOutlet var confirmOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        addressTable.delegate = self
        addressTable.dataSource = self
        addressTable.clipsToBounds = true
        addressTable.layer.cornerRadius = 8
        cancelOutlet.layer.cornerRadius = 8
        confirmOutlet.layer.cornerRadius = 8
        
        // QR only
        if words == nil && walletDict["birthdate"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            
            if descriptorStruct.isMulti {
                
                walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
                walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
                loadMultiSigAddressesFromQR()
                
            } else {
                
                walletType.text = "Single-sig"
                walletDerivation.text = descriptorStruct.derivation + "/0"
                loadSingleSigAddressesFromQR()
                
            }
            
        // Words only
        } else if words != nil && walletDict["birthdate"] == nil {
            
            loadAddressesFromLibWally()
            
        // Full multisig recovery
        } else if words != nil && walletDict["birthdate"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
            walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
            loadMultiSigAddressesFromQR()
            
        }
        
    }
    
    private func loadAddressesFromLibWally() {
        
        if derivation != nil && words != nil {
         
            walletLabel.text = "unknown"
            walletName.text = reducedName(name: walletNameHash)
            if derivation!.contains("1") {
                walletNetwork.text = "Testnet"
            } else {
                walletNetwork.text = "Mainnet"
            }
            walletBirthdate.text = "unknown"
            walletBalance.text = "...fetching balance"
            walletType.text = "Single-sig"
            walletDerivation.text = "\(derivation!)/0"
            
            let mnemonicCreator = MnemonicCreator()
            mnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in
                
                if !error && mnemonic != nil {
                    
                    let mk = HDKey(mnemonic!.seedHex(), network(path: vc.derivation!))!
                    
                    for i in 0...4 {
                        
                        do {
                            
                            let key = try mk.derive(BIP32Path("\(vc.derivation!)/0/\(i)")!)
                            var addressType:AddressType!
                            
                            if vc.derivation!.contains("84") {
                                
                                addressType = .payToWitnessPubKeyHash
                                
                            } else if vc.derivation!.contains("44") {
                                
                                addressType = .payToPubKeyHash
                                
                            } else if vc.derivation!.contains("49") {
                                
                                addressType = .payToScriptHashPayToWitnessPubKeyHash
                                
                            }
                            
                            let address = key.address(addressType).description
                            vc.addresses.append(address)
                            
                        } catch {
                            
                            displayAlert(viewController: vc, isError: false, message: "error deriving addresses from those words")
                            
                        }
                        
                    }
                    
                    var zombieDict = [String:Any]()
                    zombieDict["name"] = vc.walletNameHash
                    let wallet = WalletStruct(dictionary: zombieDict)
                    vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                        
                        if success && dictToReturn != nil {
                            
                            let s = HomeStruct(dictionary: dictToReturn!)
                            let doub = (s.coldBalance).doubleValue
                            vc.walletDict["lastBalance"] = doub
                            
                            DispatchQueue.main.async {
                                
                                vc.walletBalance.text = "\(doub)"
                                
                            }
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                
                                vc.walletBalance.text = "unknown"
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: vc, isError: true, message: "error deriving addresses from those words")
                    
                }
                
            }
            
        }
        
    }
    
    private func loadSingleSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        let xprv = descriptorStruct.accountXprv
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let walletName = walletNameHash
        
        DispatchQueue.main.async {
            
            self.walletName.text = self.reducedName(name: walletName)
            
        }
        
        Reducer.makeCommand(walletName: walletName, command: .getdescriptorinfo, param: "\"\(desc)\"") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                let descriptor = result["descriptor"] as! String
                Reducer.makeCommand(walletName: walletName, command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") { [unowned vc = self] (object, errorDesc) in
                    
                    if let result = object as? NSArray {
                        
                        for address in result {
                            
                            vc.addresses.append(address as! String)
                            
                        }
                        
                        vc.connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async {
                            
                            vc.addressTable.reloadData()
                            
                        }
                        
                        vc.walletDict["name"] = walletName
                        let wallet = WalletStruct(dictionary: vc.walletDict)
                        vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                            
                            if success && dictToReturn != nil {
                                
                                let s = HomeStruct(dictionary: dictToReturn!)
                                let doub = (s.coldBalance).doubleValue
                                vc.walletDict["lastBalance"] = doub
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletBalance.text = "\(doub)"
                                    
                                }
                                
                            } else {
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletBalance.text = "error fetching balance"
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.connectingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "getdesriptorinfo error: \(errorDesc ?? "")")
                
            }
            
        }
        
    }
    
    
    private func loadMultiSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        // need to replace xprv with xpub so the checksum is valid
        let xprv = descriptorStruct.multiSigKeys[1]
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let walletName = walletNameHash
        
        DispatchQueue.main.async {
            
            self.walletName.text = self.reducedName(name: walletName)
            
        }
        
        Reducer.makeCommand(walletName: walletName, command: .deriveaddresses, param: "\"\(desc)\", [0,4]") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSArray {
                
                for address in result {
                    
                    vc.addresses.append(address as! String)
                    
                }
                
                vc.connectingView.removeConnectingView()
                                
                DispatchQueue.main.async {
                    
                    vc.addressTable.reloadData()
                    
                }
                
                vc.walletDict["name"] = walletName
                let wallet = WalletStruct(dictionary: vc.walletDict)
                vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                    
                    if success && dictToReturn != nil {
                    
                        let s = HomeStruct(dictionary: dictToReturn!)
                        let doub = (s.coldBalance).doubleValue
                        vc.walletDict["lastBalance"] = doub
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "\(doub)"
                            
                        }
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "error fetching balance"
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                
            }
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        addresses.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row).  \(addresses[indexPath.row])"
        cell.textLabel?.textColor = .white
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 30
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
        print("cancel")
        DispatchQueue.main.async {
            
            self.dismiss(animated: true) { [unowned vc = self] in
                
                vc.confirmedDoneBlock!(false)
                
            }
            
        }
        
    }
    
    private func recover(dict: [String:Any]) {
        
        let connectingView = ConnectingView()
        connectingView.addConnectingView(vc: self, description: "recovering your wallet")
        let recovery = RecoverWallet.sharedInstance
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                recovery.recover(node: node!, json: dict, words: vc.words, derivation: vc.derivation) { [unowned vc = self] (success, error) in
                    
                    if success {
                        
                        /// Use this notifaction to refresh all wallet data on the wallets page, this will ensure rescan labels show up and balances
                        ///  - only really necessary for wallets that have been recovered on the node.
                        NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                        
                        connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async { [unowned vc = self] in
                                        
                            let alert = UIAlertController(title: "Wallet recovered!", message: "Your recovered wallet will now show up in \"Wallets\"", preferredStyle: .actionSheet)

                            alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
                                
                                DispatchQueue.main.async { [unowned vc = self] in
                                    
                                    vc.navigationController?.popToRootViewController(animated: true)
                                    
                                }
                                
                            }))
                            alert.popoverPresentationController?.sourceView = self.view
                            vc.present(alert, animated: true, completion: nil)
                            
                        }
                        
                    } else {
                        
                        connectingView.removeConnectingView()
                        
                        if error != nil {
                            
                            showAlert(vc: vc, title: "Error!", message: "Wallet recovery error: \(error!)")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                connectingView.removeConnectingView()
                
                showAlert(vc: vc, title: "Error!", message: "Recovering wallets requires an active node!")
                
            }
            
        }
        
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        
        print("confirm")
        recover(dict: walletDict)
        
    }
    
    private func getDate(unixTime: Int32) -> String {
        
        let dateFormatter = DateFormatter()
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    private func reducedName(name: String) -> String {
        
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
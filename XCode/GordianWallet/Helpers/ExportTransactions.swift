//
//  ExportTransactions.swift
//  GordianWallet
//
//  Created by Gautham Elango on 8/10/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit

class ExportTransactions {
    
    var transactionArray: [[String : Any]]
    
    init() {
        transactionArray = MainMenuViewController.returnTransactionArray
    }
    
    init(txArray: [[String : Any]]) {
        transactionArray = txArray
    }
    
    func createCSV() -> String {
        var csvString = "\("Date"),\("Action"),\("Symbol"),\("Account"),\("Volume"),\("Price"),\("Currency"),\("Fee"),\("Total"),\("TxHash")\n"
        for dct in transactionArray {
            if (String(describing: dct["amount"]!).prefix(1) == "-") {
                csvString = csvString.appending("\(String(describing: dct["date"]!)) ,\("SPEND"),\("BTC"),\("Gordian"),\(String(describing: dct["amount"]!).dropFirst()),\("10000"),\("USD"),\(String(describing: dct["fee"]!).dropFirst()),\("10000"),\(String(describing: dct["txID"]!))\n")
            } else {
                csvString = csvString.appending("\(String(describing: dct["date"]!)) ,\("INCOME"),\("BTC"),\("Gordian"),\(String(describing: dct["amount"]!)),\("10000"),\("USD"),,\("10000"),\(String(describing: dct["txID"]!))\n")
            }
        }
        return csvString
    }
    
}

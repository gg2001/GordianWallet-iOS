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
    let tempPrice: Double = 10000
    let localeConfig = LocaleConfig()
    let monthConvert: [String:String] = ["Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04", "May": "05", "Jun": "06", "Jul": "07", "Aug": "08", "Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"]
    
    init() {
        transactionArray = MainMenuViewController.returnTransactionArray
    }
    
    init(txArray: [[String : Any]]) {
        transactionArray = txArray
    }
    
    func check() -> Bool {
        return transactionArray.isEmpty
    }
    
    func createCSV() -> String {
        var csvString = "\("Date"), \("Action"), \("Symbol"), \("Account"), \("Volume"), \("Price"), \("Currency"), \("Fee"), \("Total"), \("TxHash")\n"
        for dct in transactionArray {
            if (String(describing: dct["amount"]!).prefix(1) == "-") {
                var totalAmount = Double(String(describing: dct["amount"]!).dropFirst()) ?? Double(1)
                totalAmount = totalAmount * tempPrice
                csvString = csvString.appending("\(String(describing: dct["date"]!)), \("SPEND"), \("BTC"), \("Gordian"), \(String(describing: dct["amount"]!).dropFirst()), \(tempPrice), \(localeConfig.getSavedLocale()), \(String(describing: dct["fee"]!).dropFirst()), \(String(describing: totalAmount)), \(String(describing: dct["txID"]!))\n")
            } else {
                var totalAmount = Double(String(describing: dct["amount"]!)) ?? Double(1)
                totalAmount = totalAmount * tempPrice
                csvString = csvString.appending("\(String(describing: dct["date"]!)), \("INCOME"), \("BTC"), \("Gordian"), \(String(describing: dct["amount"]!)), \(tempPrice), \(localeConfig.getSavedLocale()),, \(String(describing: totalAmount)), \(String(describing: dct["txID"]!))\n")            }
        }
        return csvString
    }
    
    func createBeancount() -> String {
        var beancountString = "; Beancount Ledger for Account \"Gordian\"\n\n"
        if self.check() == false {
            let dateStr = String(describing: transactionArray[0]["date"]!)
            let start = dateStr.index(dateStr.startIndex, offsetBy: 7)
            let end = dateStr.index(dateStr.endIndex, offsetBy: -6)
            let range = start..<end
            let transactionYear = String(dateStr[range])
            beancountString = beancountString.appending("\(transactionYear)-01-01 open Assets:Cryptocurrency:BTC       BTC \"NONE\"                    ; My Account\n")
            beancountString = beancountString.appending("\(transactionYear)-01-01 open Expenses:Value-Sent-BTC         \(localeConfig.getSavedLocale())\n")
            beancountString = beancountString.appending("\(transactionYear)-01-01 open Expenses:Fees:Transaction-BTC   \(localeConfig.getSavedLocale())\n")
            beancountString = beancountString.appending("\(transactionYear)-01-01 open Income:Value-Received-BTC       \(localeConfig.getSavedLocale())\n\n")
        } else {
            return beancountString
        }
        for dct in transactionArray {
            if (String(describing: dct["amount"]!).prefix(1) == "-") {
                let dateStr = String(describing: dct["date"]!)
                var start = dateStr.index(dateStr.startIndex, offsetBy: 7)
                var end = dateStr.index(dateStr.endIndex, offsetBy: -6)
                let yearRange = start..<end
                start = dateStr.index(dateStr.startIndex, offsetBy: 0)
                end = dateStr.index(dateStr.endIndex, offsetBy: -14)
                let monthRange = start..<end
                start = dateStr.index(dateStr.startIndex, offsetBy: 4)
                end = dateStr.index(dateStr.endIndex, offsetBy: -11)
                let dayRange = start..<end
                let transactionDate = String(dateStr[yearRange]) + "-" + monthConvert[String(dateStr[monthRange])]! + "-" + String(dateStr[dayRange])
                
                var totalAmount = Double(String(describing: dct["amount"]!).dropFirst()) ?? Double(1)
                totalAmount = totalAmount * tempPrice
                
                var feeTotal = Double(String(describing: dct["fee"]!).dropFirst()) ?? Double(1)
                feeTotal = feeTotal * tempPrice
                
                beancountString = beancountString.appending("\(transactionDate) * \"Sent Bitcoin\" \"\(String(describing: dct["txID"]!))\"\n")
                beancountString = beancountString.appending("  Assets:Cryptocurrency:BTC         \(String(describing: dct["amount"]!)) BTC {\(tempPrice) \(localeConfig.getSavedLocale())}    ; at \(String(describing: dct["date"]!))\n")
                beancountString = beancountString.appending("  Expenses:Fees:Transaction-BTC           -\(feeTotal) \(localeConfig.getSavedLocale())                             ; \(String(describing: dct["fee"]!).dropFirst())\n")
                beancountString = beancountString.appending("  Expenses:Value-Sent-BTC                                                       ; Transaction value \(totalAmount) \(localeConfig.getSavedLocale())\n\n")
            } else {
                let dateStr = String(describing: dct["date"]!)
                var start = dateStr.index(dateStr.startIndex, offsetBy: 7)
                var end = dateStr.index(dateStr.endIndex, offsetBy: -6)
                let yearRange = start..<end
                start = dateStr.index(dateStr.startIndex, offsetBy: 0)
                end = dateStr.index(dateStr.endIndex, offsetBy: -14)
                let monthRange = start..<end
                start = dateStr.index(dateStr.startIndex, offsetBy: 4)
                end = dateStr.index(dateStr.endIndex, offsetBy: -11)
                let dayRange = start..<end
                let transactionDate = String(dateStr[yearRange]) + "-" + monthConvert[String(dateStr[monthRange])]! + "-" + String(dateStr[dayRange])
                
                var totalAmount = Double(String(describing: dct["amount"]!).dropFirst()) ?? Double(1)
                totalAmount = totalAmount * tempPrice
                
                beancountString = beancountString.appending("\(transactionDate) * \"Received Bitcoin\" \"\(String(describing: dct["txID"]!))\"\n")
                beancountString = beancountString.appending("  Assets:Cryptocurrency:BTC         \(String(describing: dct["amount"]!)) BTC {\(tempPrice) \(localeConfig.getSavedLocale())}  ; at \(String(describing: dct["date"]!))\n")
                beancountString = beancountString.appending("  Income:Value-Received-BTC                                                     ; Transaction value \(totalAmount) \(localeConfig.getSavedLocale())\n\n")
            }
        }
        return beancountString
    }
    
}

//
//  LocaleConfig.swift
//  FullyNoded2
//
//  Created by Gautham Ganesh Elango on 10/8/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit

class PriceServer {
    
    let localeConfig = LocaleConfig()
    
    let defaultServerString: String = "h6zwwkcivy2hjys6xpinlnz2f74dsmvltzsd4xb42vinhlcaoe7fdeqd.onion"
    let defaultServerIndex: Int = 0
    let defaultServers: [String] = ["h6zwwkcivy2hjys6xpinlnz2f74dsmvltzsd4xb42vinhlcaoe7fdeqd.onion"]
    let exchangeList: [String] = ["okcoin", "liquid", "zaif", "coinbasepro", "upbit", "bitstamp", "coinbase", "coincheck", "ftx", "kraken", "bitflyer", "bitbank", "bithumb", "coinone", "indodax", "binance", "bittrex", "bitfinex", "gemini", "indoex"]
    let defaultExchange: String = "coinbase"
    let localeToExchange: [String:[String]] = [
        "USD": ["Average", "bitflyer", "bittrex", "ftx", "gemini", "liquid", "coinbase", "coinbasepro", "okcoin", "bitfinex", "kraken", "bitstamp"],
        "GBP": ["Average", "binance", "bitfinex", "coinbase", "coinbasepro", "bitstamp", "kraken", "bitstamp", "cex"],
        "EUR": ["Average", "kraken", "coinbase", "liquid", "bitflyer", "bittrex", "coinbasepro", "bitstamp", "bitfinex", "indoex"],
        "JPY": ["Average", "bitflyer", "coinbase", "liquid", "coincheck", "bitbank", "zaif"],
        "AUD": ["binance", "coinbase", "liquid","kraken"],
        "BRL": ["coinbase", "ftx"],
        "KRW": ["bithumb", "coinbase", "coinone", "upbit"],
        "ZAR": ["binance", "coinbase"],
        "TRY": ["binance", "coinbase"],
        "INR": ["coinbase"],
        "CAD": ["coinbase", "kraken"],
        "IDR": ["coinbase", "indodax"]
    ]
    
    func getServers() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "priceServers") ?? defaultServers
    }
    
    func getDefaultExchange() -> String {
        return localeToExchange[localeConfig.getSavedLocale()]?[0] ?? defaultExchange
    }
    
    func onStartup() -> Void {
        if UserDefaults.standard.stringArray(forKey: "priceServers") == nil {
            UserDefaults.standard.set(defaultServers, forKey: "priceServers")
        }
        if (UserDefaults.standard.string(forKey: "currentServer") == nil) || (UserDefaults.standard.string(forKey: "currentServerIndex") == nil) {
            UserDefaults.standard.set(defaultServerString, forKey: "currentServer")
            UserDefaults.standard.set(defaultServerIndex, forKey: "currentServerIndex")
        }
        if UserDefaults.standard.string(forKey: "currentExchange") == nil {
            UserDefaults.standard.set(self.getDefaultExchange(), forKey: "currentExchange")
        }
    }
    
    func changeServers(newServers: [String]) -> Void {
        UserDefaults.standard.set(newServers, forKey: "priceServers")
    }
    
    func setCurrentServer(server: String, index: Int) -> Void {
        UserDefaults.standard.set(server, forKey: "currentServer")
        UserDefaults.standard.set(index, forKey: "currentServerIndex")
    }
    
    func getCurrentServerString() -> String {
        return UserDefaults.standard.string(forKey: "currentServer") ?? defaultServerString
    }
    
    func getCurrentServerIndex() -> Int {
        return UserDefaults.standard.integer(forKey: "currentServerIndex")
    }
    
    func addServer(server: String) -> Void {
        var currentServers = self.getServers()
        currentServers.append(server)
        self.changeServers(newServers: currentServers)
    }
    
    func removeServerByString(server: String) -> Void {
        var currentServers = self.getServers()
        if let index = currentServers.firstIndex(of: server) {
            currentServers.remove(at: index)
            self.changeServers(newServers: currentServers)
        }
    }
    
    func removeServerByIndex(index: Int) -> Void {
        var currentServers = self.getServers()
        currentServers.remove(at: index)
        self.changeServers(newServers: currentServers)
    }
    
    func getCurrentExchange() -> String {
        return UserDefaults.standard.string(forKey: "currentExchange") ?? self.getDefaultExchange()
    }
    
    func changeExchange(newExchange: String) -> Void {
        UserDefaults.standard.set(newExchange, forKey: "currentExchange")
    }
    
    func getExchangeList() -> [String] {
        return localeToExchange[localeConfig.getSavedLocale()] ?? exchangeList
    }
    
    func createSpotBitURL() -> String {
        if self.getCurrentExchange() == "Average" {
            return "http://" + self.getCurrentServerString() + "/now/" + localeConfig.getSavedLocale()
        } else {
            return "http://" + self.getCurrentServerString() + "/now/" + localeConfig.getSavedLocale() + "/" + self.getCurrentExchange().lowercased()
        }
    }
    
    func getSavedExchangeIndex() -> Int {
        if self.getExchangeList().firstIndex(of: self.getCurrentExchange()) == nil {
            self.changeExchange(newExchange: self.getExchangeList()[0])
            return self.getExchangeList().firstIndex(of: self.getCurrentExchange()) ?? 0
        } else {
            return self.getExchangeList().firstIndex(of: self.getCurrentExchange()) ?? 0
        }
    }
}

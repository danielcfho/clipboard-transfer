//
//  clipboard_transferApp.swift
//  clipboard-transfer
//
//  Created by Daniel Ho on 14/11/2023.
//

import SwiftUI

@main
struct clipboard_transferApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizabilityContentSize()
    }
}
extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}

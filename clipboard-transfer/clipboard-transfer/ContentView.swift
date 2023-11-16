//
//  ContentView.swift
//  clipboard-transfer
//
//  Created by Daniel Ho on 14/11/2023.
//

import SwiftUI
import ZIPFoundation
import AppKit
import CryptoKit

struct ContentView: View {

    @State private var selectedPath = ""
    @State private var selectedFiles: Set<URL> = Set()

    @State private var encodeFiles = [String]()
    @State private var fileURLs: [URL] = []
    @State private var isClearing = false
    @State private var clearEncodeTemp = true
    @State private var clearDecodeTemp = true
    @State private var override = false
    
    @State private var clipboardData = ""
    @State private var clipboardSize = 0.0
    @State private var clipboardMd5Hash = ""
    
    var body: some View {

        VStack(alignment:.leading) {
            
            HStack {
                Button(action: encodeFile) {
                    Text("Encode")
                        .frame(width: 120.0, height: 60.0)
                }
                VStack(alignment:.leading){
                    Toggle(isOn: $clearEncodeTemp){
                        Text("Clear Temp Encode Files afterwards")
                    }
                    Text("Drop files or folders here:")
                }
                Spacer()
                Button(action: clearList){
                    Text("Clear List")
                }
                

            }
            List(selection: $selectedFiles) {
                ForEach(fileURLs, id: \.self) { fileURL in
                    Text(fileURL.path)
                }
            }
            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers, _ in
                handleDrop(providers: providers)
                return true
            }
            .onDeleteCommand {
                fileURLs.removeAll { selectedFiles.contains($0) }
                selectedFiles.removeAll()
            }
            .frame(height: 200)
            
            Spacer()
            HStack{
                Button(action: getClipboardInfo){
                    Text("Get Clipboard")
                }
                Button(action: clearClipboard){
                    Text("Clear Clipboard")
                }
            }
            Text("MD5 Hash: \(clipboardMd5Hash.uppercased())")
            Text("Clipboard Size: \(clipboardSize * 0.001) Kb")
            Spacer()

            HStack {
                TextField("Output Location", text: $selectedPath)
                    .frame(width: 350, height: 23)
                Button(action: openBrowser) {
                    Text("Browse...")
                }
            }
            HStack {
                Button(action: decodeFile) {
                    Text("Decode")
                        .frame(width: 120.0, height: 60.0)
                }
                VStack(alignment:.leading){
                    Toggle(isOn: $clearDecodeTemp) {
                        Text("Clear Temp Encode Files")
                    }
                    Toggle(isOn: $override) {
                        Text("Override Exist Files")
                    }
                }
            }
            
        }
        .padding()
        .frame(width: 500.0, height: 550.0)
        
    }
    func clearList(){
        fileURLs.removeAll()
    }
    
    func clearClipboard(){
        NSPasteboard.general.clearContents()
    }
    
    func encodeFile() {
        guard !fileURLs.isEmpty else { return }
        
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            // Create a Zip archive at the specified path
            let zipFilePath = tempDir.appendingPathComponent("encodeTemp.zip")
            let archive = try Archive(url: zipFilePath, accessMode: .create)
            
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                try archive.addEntry(with: fileName, relativeTo: fileURL.deletingLastPathComponent())
            }
            
            print("Files zipped successfully to \(zipFilePath.path)")
            
            // Convert the zip archive to Base64
            if let zipData = try? Data(contentsOf: zipFilePath) {
                let base64String = zipData.base64EncodedString()
                
                // Save the Base64 string to base64.txt
                let base64FileURL = tempDir.appendingPathComponent("base64.txt")
                try base64String.write(to: base64FileURL, atomically: true, encoding: .utf8)
                
                print("Files zipped and saved as Base64 to \(base64FileURL.path)")
                
                // Copy Base64 string to clipboard
                let clipboard = NSPasteboard.general
                clipboard.clearContents()
                clipboard.setString(base64String, forType: .string)
                print("Base64 string copied to clipboard.")
                
                getClipboardInfo()
                
                if clearEncodeTemp {
                    // Remove base64.txt and zip archive file
                    try FileManager.default.removeItem(at: base64FileURL)
                    try FileManager.default.removeItem(at: zipFilePath)
                }
            } else {
                print("Error reading zip file.")
            }
            
        } catch {
            print("Error zipping files: \(error.localizedDescription)")
        }
    }
    
    func decodeFile() {
        guard !selectedPath.isEmpty else { return }
        
        // Decode logic
        let tempDir = FileManager.default.temporaryDirectory
        let clipboard = NSPasteboard.general
        guard let base64String = clipboard.string(forType: .string) else { return }
        let decodedData = Data(base64Encoded: base64String)
        let decodeFilePath = tempDir.appendingPathComponent("decode.zip")
        let dictPath = URL(fileURLWithPath: selectedPath)
        
        do {
            try decodedData?.write(to: decodeFilePath)
            print("Decoded data saved to \(decodeFilePath.path)")
            
            // Use ZIPFoundation to unzip the file
            let archive = try Archive(url: decodeFilePath, accessMode: .read)
            for entry in archive {
                let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(entry.path)
                let toPath = dictPath.appendingPathComponent(entry.path)
                
                //clear temp folder before unzip
                try? FileManager.default.removeItem(at: tempPath)
                //overwrite files if files exist
                if(self.override){
                    try? FileManager.default.removeItem(at: toPath)
                }
                
                if entry.type == .directory {
                    try FileManager.default.createDirectory(at: tempPath, withIntermediateDirectories: true, attributes: nil)
                } else {
                    // Extract files into temp directory first
                    try archive.extract(entry, to: tempPath)
                    
                    try FileManager.default.moveItem(at: tempPath, to: toPath)
                }
            }
            
            if clearDecodeTemp {
                // Remove base64.txt and zip archive file
                try FileManager.default.removeItem(at: decodeFilePath)
            }
        } catch {
            print("Error saving decoded data: \(error.localizedDescription)")
        }
    }
    
    func getClipboardInfo() {
        // Get clipboard data
        if let data = NSPasteboard.general.string(forType: .string) {
            clipboardData = data
            clipboardSize = Double(data.utf16.count)
            
            // Calculate MD5 hash
            if let asciiData = data.data(using: .ascii) {
                let md5Digest = Insecure.MD5.hash(data: asciiData)
                clipboardMd5Hash = md5Digest.map { String(format: "%02hhx", $0) }.joined()
            }
            
        } else {
            // Reset values if clipboard is empty
            clipboardData = ""
            clipboardSize = 0
            clipboardMd5Hash = ""
        }
    }
    func openBrowser() {
        // Open file browser
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        
        openPanel.begin { response in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let selectedFolderURL = openPanel.url {
                    self.selectedPath = selectedFolderURL.path()
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                if let urlData = data as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.fileURLs.append(url)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

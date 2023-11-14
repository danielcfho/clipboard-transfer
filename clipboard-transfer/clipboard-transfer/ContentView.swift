//
//  ContentView.swift
//  clipboard-transfer
//
//  Created by Daniel Ho on 14/11/2023.
//

import SwiftUI
import Zip
import AppKit

struct ContentView: View {

    
    
    @State private var selectedPath = ""
    @State private var selectedFiles: Set<URL> = Set()

    @State private var encodeFiles = [String]()
    @State private var fileURLs: [URL] = []
    @State private var isClearing = false
    @State private var clearEncodeTemp = true
    @State private var clearDecodeTemp = true
    
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
                    Toggle(isOn: .constant(true)) {
                        Text("Override Exist Files")
                    }
                }
            }
            
        }
        .padding()
        .frame(width: 500.0, height: 450.0)
        
    }
    func clearList(){
        fileURLs.removeAll()
    }
    
    func encodeFile() {
        guard !selectedFiles.isEmpty else {return}
        
        let tempDir = FileManager.default.temporaryDirectory

        do {
            // Create a Zip archive at the specified path
            let zipFilePath = try Zip.quickZipFiles(fileURLs, fileName: "encodeTemp")
            
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
                
                if(clearEncodeTemp){
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
            try Zip.unzipFile(decodeFilePath, destination: dictPath, overwrite: true, password: nil)
            if(clearDecodeTemp){
                // Remove base64.txt and zip archive file
                try FileManager.default.removeItem(at: decodeFilePath)
            }
        } catch {
            print("Error saving decoded data: \(error.localizedDescription)")
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
            _ = provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
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

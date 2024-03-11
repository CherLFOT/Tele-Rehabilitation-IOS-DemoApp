//
//  Tele_RehabApp.swift
//  Tele-Rehab
//
//  Created by cc on 2023/11/17.
//

import SwiftUI
import AVFoundation

@main
struct Tele_RehabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().edgesIgnoringSafeArea(.all)
                .background(Color("AccentColor"))
        }
    }
}




struct DemoAppView: View {
    @State var cameraPermissionGranted = false
    var body: some View {
        GeometryReader { geometry in
            if cameraPermissionGranted {
                ContentView()
            }
        }.onAppear {
            AVCaptureDevice.requestAccess(for: .video) { accessGranted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = accessGranted
                }
            }
        }
    }
}




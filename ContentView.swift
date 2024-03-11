//
//  ContentView.swift
//  Tele-Rehab
//
//  Created by cc on 2023/11/17.
//
//import UIKit
import SwiftUI
import QuickPoseCore
import QuickPoseSwiftUI



struct ContentView: View {

    indirect enum ViewState: Equatable {
        case notinitialized
        case introToApp
        case introToMeasurement(frontal:Bool)
        case loadingAfterThumbsUp(delaySeconds:Double,nextState: ViewState)
        case updateAndAddFeaturesAfterDelay(nextState:ViewState,delaySeconds:Double,features:[QuickPose.Feature])
        case measuring(frontal:Bool)
        case captureResult(frontal:Bool)
        case showResult(frontal:Bool)
        case Completed
//        case Acute(frontal:Bool)
//        case Abtuse(frontal:Bool)
        
       func prompt(shoulderLateralResult:QuickPose.FeatureResult?,shoulderFrontalResult:QuickPose.FeatureResult?) -> String?{
            switch self{
            case .notinitialized,.updateAndAddFeaturesAfterDelay:
                return nil
            case .introToApp:
                return "Welcome to the upper limb measuring app.\n\nWhen you are ready,give a right thumb up"
            case .loadingAfterThumbsUp:
                return "Awesome,continuing..."
            case .introToMeasurement:
                return "Please pose"
            case .measuring:
                return "Measuring"
            case .captureResult:
                return nil
            case.showResult(let frontal):
                if frontal {
                    return "Your frontal shoulder range of motion is\n\(shoulderFrontalResult!.stringValue)\n\nThumb up to continue\nThumb down to repeat"
                    
                }else{
                    return "Your Lateral auxiliary shoulder range of motion is\n\(shoulderLateralResult!.stringValue)\n\nThumb up to continue\nThumb down to repeat"
                }
            case .Completed:
              return "Measuring Complete\n\nLeft shoulder Frontal\t\(shoulderFrontalResult!.stringValue)\nLeft shoulder Lateral(auxiliary)\t\(shoulderLateralResult!.stringValue)"
            }
       
        }
        
   
    }
    var quickPose = QuickPose(sdkKey:"01HFC5ANEM9X635V3JTYQKK4BB")
    @State var overlayImage :UIImage?
    @State var showOverlay: Bool = false
    @State var viewState = ViewState.notinitialized
    @State var shoulderLateralResult:QuickPose.FeatureResult?
    @State var shoulderFrontalResult:QuickPose.FeatureResult?
    
    var unchangedDetector = QuickPoseDoubleUnchangedDetector(similarDuration: TimeInterval(0.3),leniency: 0.05)
    
    
    let shoulderFrontal = QuickPose.Feature.rangeOfMotion(.shoulder(side: .left, clockwiseDirection: false))
    let shoulderLateral = QuickPose.Feature.measureAngleBody(origin: .shoulder(side:.left), p1: .elbow(side:.left), p2: nil, clockwiseDirection: false)
   // let shoulderFrontal_AcuteAngel = QuickPose.Feature.fitness(.frontRaises, style: <#T##QuickPose.Style#>)
 //   let shoulderLateral_AcuteAngel = QuickPose.Feature.measureAngleBody(origin: .elbow(side:.left), p1: .shoulder(side:.left), p2: nil, clockwiseDirection: true)
//    let shoulderFrontal_AbtuseAngel = QuickPose.Feature.rangeOfMotion(.shoulder(side: .left, clockwiseDirection: false))
//    let shoulderLateral_AbtuseAngel = QuickPose.Feature.measureAngleBody(origin: .shoulder(side:.left), p1: .elbow(side:.left), p2: nil, clockwiseDirection: true)

    
 
    
    var body: some View {
        GeometryReader{ geometry in
            VStack{
                Image(systemName:"cat")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Button("Start") {
                    showOverlay = true
                }
            }
            .padding()
            .frame(width:geometry.size.width,height:geometry.size.height)
            .fullScreenCover(isPresented: $showOverlay){
                ZStack{
                    QuickPoseCameraView(useFrontCamera:true, delegate:quickPose)
                        //viewState = .updateAndAddFeaturesAfterDelay(nextState: .introToApp, delaySeconds: 2, features: [.thumbsUp()])
                    QuickPoseOverlayView(overlayImage: $overlayImage)
                }
                .frame(width:geometry.size.width,height:geometry.size.height)
                .onAppear{
                    quickPose.start(features:[]){ _,outputImage, results,_,arg  in
                        overlayImage = outputImage
                        
                        if viewState == .introToApp, let measurementResult = results[.thumbsUp()]{
                            if measurementResult.value > 0.7{
                                viewState = .loadingAfterThumbsUp(delaySeconds: 2.0, nextState:.introToMeasurement(frontal: true))
                            }
                        }
                       
                        if case let .captureResult(frontal) = viewState, let measurementResult =
                            results[frontal ? shoulderFrontal : shoulderLateral]{
                            
                            unchangedDetector.count(result: measurementResult.value) {
                                if frontal{
                                    shoulderFrontalResult = measurementResult
                                    //print(shoulderFrontalResult!.stringValue)
                                    viewState = .updateAndAddFeaturesAfterDelay(nextState: .showResult(frontal: frontal), delaySeconds: 2, features: [.thumbsUpOrDown()])
                                }else {
                                    shoulderLateralResult = measurementResult
                                    viewState = .updateAndAddFeaturesAfterDelay(nextState: .showResult(frontal: frontal), delaySeconds: 2, features: [.thumbsUpOrDown()])
                                }
                                
//                                viewState = .updateAndAddFeaturesAfterDelay(nextState: .showResult(frontal: true), delaySeconds: 2, features: [.thumbsUpOrDown()])
                            }
                        }
                        
                        if case let .showResult(frontal) = viewState, let measurementResult =
                            results[.thumbsUpOrDown()]{
                            if measurementResult.value > 0.7{
                                print(measurementResult.stringValue)
                                
                                if measurementResult.stringValue == "Thumbs Up 0.80"{
                                    viewState = .loadingAfterThumbsUp(delaySeconds: 2.0, nextState: frontal ? .introToMeasurement(frontal: false) : .Completed)
                                }else if measurementResult.stringValue == "Thumbs Down 0.80"{
                                    viewState = .introToMeasurement(frontal: frontal)
                               }
                            }
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline:.now() + 2) {
                        viewState = .updateAndAddFeaturesAfterDelay(nextState: .introToApp, delaySeconds: 2, features: [.thumbsUp()])
                    }
                    
                }.onChange(of: viewState) {oldViewState, newViewState in
                    if case let .introToMeasurement(frontal) = viewState {
                        quickPose.update(features: [frontal ? shoulderFrontal : shoulderLateral])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewState = .measuring(frontal: frontal)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewState = .captureResult(frontal: frontal)
                            }
                        }
                    }
                    
                                                          
                   if case.updateAndAddFeaturesAfterDelay(let nextState, let delay, let features)
                        = newViewState{
                       viewState = nextState
                       quickPose.update(features: [])
                       DispatchQueue.main.asyncAfter(deadline:.now() + delay){
                           quickPose.update(features: features)
                       }
                   }
                  if case.loadingAfterThumbsUp(let delaySeconds, let nextState)
                        = viewState {
                        DispatchQueue.main.asyncAfter(deadline:.now() + delaySeconds){
                            viewState = nextState
                        }
                    }
                }
                .onDisappear{
                    quickPose.stop()
                }
                .overlay(alignment:.topTrailing){
                    Button("End"){
                        showOverlay = false
                    }.foregroundColor(Color.white).font(.system(size:30)).padding(.trailing,16)
                }
                .overlay(alignment: .bottom){
                    if let prompt = viewState.prompt(shoulderLateralResult:shoulderLateralResult,shoulderFrontalResult:shoulderFrontalResult){
                        Text(prompt)
                            .font(.system(size: 32))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color.white))
                            .padding(.bottom,100)
                            .multilineTextAlignment(.center)
                    }
                }
                
                
                
            }
        }
    }
}
                
         
     
//#Preview {
//    ContentView()
//}


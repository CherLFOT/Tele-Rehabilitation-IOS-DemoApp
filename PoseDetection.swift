//
//  PoseDetection.swift
//  Tele-Rehab
//
//  Created by cc on 2024/3/11.
//
import SwiftUI
import QuickPoseCore
import QuickPoseSwiftUI
import ARKit



struct ContentView: View {
    var quickPose = QuickPose(sdkKey:"01HFC5ANEM9X635V3JTYQKK4BB")
    @State var overlayImage :UIImage?
    @State var showOverlay: Bool = false
    @State var LateralRaiseCounter = QuickPoseThresholdCounter()
    @State var LateralRaiseCounter_left = QuickPoseThresholdCounter()
    @State var LateralRaiseCounter_right = QuickPoseThresholdCounter()
    @State var ShoulderLateralRaiseCounter = QuickPoseThresholdCounter()
    @State var RightShoulderLateralRaiseCounter = QuickPoseThresholdCounter()
    @State var LeftShoulderLateralRaiseCounter = QuickPoseThresholdCounter()
    @State var count: Int?
    @State var Lcount: Int?
    @State var Rcount: Int?
    @State var feedbackText: String?
    @State var scale = 1.0
    var body: some View {
        GeometryReader{ geometry in
            VStack{
                Image(systemName:"cat")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Button("Start") {
                    showOverlay = true
                    ARViewContainer()
                }
            }
            .padding()
            .frame(width:geometry.size.width,height:geometry.size.height)
            .fullScreenCover(isPresented: $showOverlay){
                ZStack{
                    QuickPoseCameraView(useFrontCamera:true, delegate:quickPose)
                    QuickPoseOverlayView(overlayImage: $overlayImage)
                }
                .frame(width:geometry.size.width,height:geometry.size.height)
                .overlay(alignment:.topTrailing){
                    Button("End"){
                        showOverlay = false
                    }.foregroundColor(Color.white).font(.system(size:30)).padding(.trailing,16)
                }.overlay(alignment: .top) {
                    HStack {
                        if let count = count {
                            Text("Both:\(count)")
                                .foregroundColor(Color.white)
                                .font(.system(size: 40))
                                .padding(0)
                                .scaleEffect(scale)
                        }
                        if let lcount = Lcount {
                            Text("Left: \(lcount)")
                                .foregroundColor(Color.white)
                                .font(.system(size: 36))
                                .padding(0)
                                .scaleEffect(scale)
                        }
                    
                        if let rcount = Rcount {
                            Text("Right: \(rcount)")
                                .foregroundColor(Color.white)
                                .font(.system(size: 36))
                                .padding(0)
                                .scaleEffect(scale)
                        }
                        
                        
                    }
                }.overlay(alignment: .bottom) {
                    if let feedback = feedbackText {
                        Text(feedback).foregroundColor(Color.white).font(.system(size: 28)).multilineTextAlignment(.center)
                            .padding(100)
                    }
                }.onAppear{
                    let smallStyle = QuickPose.Style(relativeFontSize: 0.3,relativeArcSize:0.3,relativeLineWidth:0.3,conditionalColors:[QuickPose.Style.ConditionalColor(min: 90, max: 180, color: UIColor.green)])
                    
                    let redStyle = QuickPose.Style(relativeFontSize: 0.3, relativeArcSize: 0.3, relativeLineWidth: 0.3, color: UIColor.red)
                    let LateralRaiseCounterFeature = QuickPose.Feature.fitness(.lateralRaises,style: smallStyle)
                    let LateralRaiseCounterFeature_left = QuickPose.Feature.fitness(.lateralRaises,style: smallStyle)
                    let LateralRaiseCounterFeature_right = QuickPose.Feature.fitness(.lateralRaises,style: smallStyle)
                    let LeftShoulderRom = QuickPose.Feature.rangeOfMotion(.shoulder(side:.left, clockwiseDirection: false),style: smallStyle)
                    let RightShoulderRom = QuickPose.Feature.rangeOfMotion(.shoulder(side:.right, clockwiseDirection: true),style: smallStyle)
                    // let LateralRaiseCounterFeature = QuickPose.Feature.measureLineBody(p1: .shoulder(side: .left), p2: .shoulder(side: //.right), userHeight: 166, format:, style: smallStyle)
                    let features = [LateralRaiseCounterFeature,LeftShoulderRom,RightShoulderRom]
                    let features_left = [LateralRaiseCounterFeature_left,LeftShoulderRom,RightShoulderRom]
                    let features_right = [LateralRaiseCounterFeature_right,LeftShoulderRom,RightShoulderRom]
                    
                    quickPose.start(features: features) { status, outputImage, result, feedback, _ in
                        overlayImage = outputImage
                        if let feedback = feedback[LateralRaiseCounterFeature]  {
                            feedbackText = feedback.displayString
                        }else if let fitnessResult = result[LateralRaiseCounterFeature],let fitnessResult_left = result[LateralRaiseCounterFeature_left],let fitnessResult_right = result[LateralRaiseCounterFeature_right],let leftshoulderRomResult = result[LeftShoulderRom],let rightshoulderRomResult = result[RightShoulderRom]{
                            
                            _ = ShoulderLateralRaiseCounter.count((leftshoulderRomResult.value  > 90) && (rightshoulderRomResult.value > 90) ? fitnessResult.value : 0)
                             _ = LeftShoulderLateralRaiseCounter.count(leftshoulderRomResult.value  > 90 ? fitnessResult_left.value : 0)
                             _ = RightShoulderLateralRaiseCounter.count(rightshoulderRomResult.value > 90 ? fitnessResult_right.value : 0)
                            
                            _ = LateralRaiseCounter.count(fitnessResult.value) { status  in
                                if case let .poseComplete(LateralRaiseCount) = status {
                                    
                                    if ShoulderLateralRaiseCounter.state.count != LateralRaiseCount {
                                        
                                        LateralRaiseCounter.state = ShoulderLateralRaiseCounter.state
                                        quickPose.update(features: [LateralRaiseCounterFeature , LeftShoulderRom, RightShoulderRom])
                                    }else{
                                       feedbackText = nil
                                        count = LateralRaiseCount
                                        withAnimation(.easeInOut(duration: 0.1)){
                                            scale = 2.0
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scale = 1.0
                                            }
                                        }
                                    }
                                    
                                }else{
                                    feedbackText = nil
                                    quickPose.update(features: features)
                                }
                            }
                            _ = LateralRaiseCounter_left.count(fitnessResult_left.value) { status  in
                                if case let .poseComplete(LateralRaiseCount_left) = status {
                                    if LeftShoulderLateralRaiseCounter.state.count != LateralRaiseCount_left {
                                        LateralRaiseCounter_left.state = LeftShoulderLateralRaiseCounter.state
                                        feedbackText = "Please Put You Left Arm Higher"
                                        quickPose.update(features: [LateralRaiseCounterFeature_left , LeftShoulderRom.restyled(redStyle), RightShoulderRom])
                                    }else{
                                        feedbackText = nil
                                        Lcount = LateralRaiseCount_left
                                        withAnimation(.easeInOut(duration: 0.1)){
                                            scale = 1.1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scale = 1.0
                                            }
                                        }
                                    }
                                    
                                }else{
                                    feedbackText = nil
                                    quickPose.update(features: features_left)
                                }
                                
                            }
                            _ = LateralRaiseCounter_right.count(fitnessResult_right.value) { status  in
                                if case let .poseComplete(LateralRaiseCount_right) = status {
                                    if RightShoulderLateralRaiseCounter.state.count != LateralRaiseCount_right {
                                        LateralRaiseCounter_right.state = RightShoulderLateralRaiseCounter.state
                                        feedbackText = "Please Put You Right Arm Higher"
                                        quickPose.update(features: [LateralRaiseCounterFeature_right , LeftShoulderRom, RightShoulderRom.restyled(redStyle)])
                                    }else{
                                        feedbackText = nil
                                        Rcount = LateralRaiseCount_right
                                        withAnimation(.easeInOut(duration: 0.1)){
                                            scale = 1.1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scale = 1.0
                                            }
                                        }
                                    }
                                    
                                }else{
                                    feedbackText = nil
                                    quickPose.update(features: features_right)
                                }
                            }
                        }
                    }
                }.onDisappear{
                    quickPose.stop()
                }
            }
        }
    }
}
    

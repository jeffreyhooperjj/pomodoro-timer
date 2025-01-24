//
//  ContentView.swift
//  pomodoro task timer
//
//  Created by Jeffrey Hooper on 1/21/25.
//

import SwiftUI
import AppKit

let window = NSApp.mainWindow
let width = window!.frame.size.width
let height = window!.frame.size.height


class CountdownTimer: ObservableObject {
    @Published var timeRemaining: Int
    var timer: Timer?
    var totalTime: Int
    
    init(time: Int) {
        self.totalTime = time
        self.timeRemaining = totalTime
    }
    
    @objc func updateTime() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func start() -> Void {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil,  repeats: true)
    }
    
    func timeRemainingAsString() -> String {
        // we want format to be mins:secs
        let minsRemaining = self.timeRemaining / 60
        let secsRemaining = self.timeRemaining % 60
        let paddedSecs = String(format: "%02d", secsRemaining)
        return "\(minsRemaining):\(paddedSecs)"
    }
    
    func pause() {
        self.timer?.invalidate()
    }
    
    func reset() {
        self.timer?.invalidate()
        self.timeRemaining = self.totalTime
    }
}

class PomodoroTimer: CountdownTimer {
    var breakTime: Int
    var taskTime: Int
    var isBreakTime: Bool
    
    init(breakTime: Int, taskTime: Int) {
        self.breakTime = breakTime
        self.taskTime = taskTime
        self.isBreakTime = false
        super.init(time: taskTime)
    }
    
    func setTotalTime() {
        if self.isBreakTime {
            self.totalTime = self.breakTime
        } else {
            self.totalTime = self.taskTime
        }
        self.timeRemaining = self.totalTime
        self.objectWillChange.send()
    }
    
    @objc func updatePomodoroTime() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.invalidate()
            timer = nil
            self.objectWillChange.send()
            self.isBreakTime = !self.isBreakTime
            self.setTotalTime()
        }
    }
    
    override func start() -> Void {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePomodoroTime), userInfo: nil,  repeats: true)
    }
    
    override func reset() {
        super.reset()
        self.objectWillChange.send()
        self.isBreakTime = false
        self.setTotalTime()
    }
    
    
}

enum Direction {
    case left
    case right
    case up
    case down
}

class CanvasViewModel: ObservableObject {
    @Published var x = 200 - 20
    @Published var y = 200 - 20
    @Published var rotation = 0
    @Published var isMoving = false
    var width = 200
    var height = 200
    var dx: Int
    var dy: Int
    var dir: Direction = Direction.left
    var stepAnimation = -5
    
    init() {
        dx = width / 2 / 30
        dy = height / 2 / 30
    }
    
    func updateState(imgWidth: Int, imgHeight: Int) {
        if !isMoving {
            return
        }
//        print(x, y, stepAnimation)
        switch dir {
        case .left:
            if x - imgWidth < 0 {
                dir = Direction.up
                rotation = 90
            }
        case .right:
            if x + imgWidth > width {
                dir = Direction.down
                rotation = 270
            }
        case .up:
            if y - imgHeight < 0 {
                dir = Direction.right
                rotation = 180
            }
        case .down:
            if y + imgHeight > height {
                dir = Direction.left
                rotation = 0
            }
        }
        // update position
        switch dir {
        case .left:
            x -= dx
        case .right:
            x += dx
        case .up:
            y -= dy
        case .down:
            y += dy
        }
        stepAnimation = -stepAnimation
//        var newX = x + 1
    }
}

struct CanvasView: View {
    var cWidth = CGFloat(200)
    var cHeight = CGFloat(200)
    var img = Image("Image")
    var imgSize = CGFloat(20)
    @ObservedObject var viewModel: CanvasViewModel
    var body: some View {
        TimelineView(.periodic(from:Date(), by: 1.0)) { tCtx in
            Canvas {context, size in
                var imgRect = CGRect(x: 0, y:0, width: imgSize, height: imgSize)
                var resolvedImg = context.resolve(img)
//                v/*ar x = startX + (CGFloat(viewModel.counter) * dx)*/
                context.drawLayer { ctx in
                    // entire traversal should take 1 minute
                    ctx.translateBy(
                        x: CGFloat(viewModel.x),
                        y: CGFloat(viewModel.y))
                    ctx.rotate(by: Angle(degrees: Double(viewModel.rotation) + Double(viewModel.stepAnimation))) // rotate
                    ctx.translateBy(x: -imgRect.width/2, y: -imgRect.width/2)
                    ctx.draw(resolvedImg, in: imgRect)
                }
            }
            .frame(width:cWidth, height:cHeight)
            .onChange(of: tCtx.date) { _ in
                            // Update the state when the timeline updates
                viewModel.updateState(imgWidth: Int(imgSize), imgHeight: Int(imgSize))
                        }
        }
    }
}

struct ContentView: View {
    // constructing a task timer for 25 mins
    var time = 25 * 60
    @StateObject var timer = PomodoroTimer(breakTime: 5 * 60, taskTime: 25 * 60)
    @StateObject var viewModel = CanvasViewModel()
//    var pokemon = NSImage(named: "arceus.png")
//    @StateObject var taskTimer = CountdownTimer(time: 25 * 60)
//    @StateObject var breakTimer = CountdownTimer(time: 5 * 60)
    var body: some View {
        ZStack {
            CanvasView(viewModel: viewModel)
            VStack {
                //            Image(systemName: "globe")
                //                .imageScale(.large)
                //                .foregroundColor(.accentColor)
                if timer.isBreakTime {
                    Text("Break Time!")
                } else {
                    Text("Focus time")
                }
                Text("Time remaining: \(timer.timeRemainingAsString())")
                // conditionally show Resume when paused
                HStack {
                    Button("Start", action: {
                        timer.start()
                        viewModel.isMoving = true
                    })
                    Button("Pause", action: {
                        timer.pause()
                        viewModel.isMoving = false
                    })
                    Button("Reset", action: {
                        timer.reset()
                        viewModel.isMoving = false
                        viewModel.x = viewModel.width - 20
                        viewModel.y = viewModel.height - 20
                    })
                }
                //            Text("is break time? \(String(timer.isBreakTime))")
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

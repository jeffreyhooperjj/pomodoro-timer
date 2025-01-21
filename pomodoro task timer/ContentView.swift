//
//  ContentView.swift
//  pomodoro task timer
//
//  Created by Jeffrey Hooper on 1/21/25.
//

import SwiftUI



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
    
    @objc override func updateTime() {
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
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil,  repeats: true)
    }
    
    override func reset() {
        super.reset()
        self.objectWillChange.send()
        self.isBreakTime = false
        self.setTotalTime()
    }
    
    
}

struct ContentView: View {
    // constructing a task timer for 25 mins
    var time = 25 * 60
    @StateObject var timer = PomodoroTimer(breakTime: 5 * 60, taskTime: 25 * 60)
//    @StateObject var taskTimer = CountdownTimer(time: 25 * 60)
//    @StateObject var breakTimer = CountdownTimer(time: 5 * 60)
    var body: some View {
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
                })
                Button("Pause", action: {
                    timer.pause()
                })
                Button("Reset", action: {
                    timer.reset()
                })
            }
//            Text("is break time? \(String(timer.isBreakTime))")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

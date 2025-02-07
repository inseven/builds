// Copyright (c) 2021-2025 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

class RefreshScheduler {

    private let syncQueue = DispatchQueue(label: "TaskScheduler.syncQueue")
    private let perform: () async -> TimeInterval?
    private var activeTask: Task<(), Never>? = nil  // Synchronized on syncQueue.
    private var timer: DispatchSourceTimer? = nil  // Synchornized on syncQueue.

    init(_ perform: @escaping () async -> TimeInterval?) {
        self.perform = perform
    }

    func start() {
        Task {
            await self.run()
        }
    }

    private func scheduledTimer(timeInterval: TimeInterval) -> DispatchSourceTimer {
        print("Scheduling next refresh in \(timeInterval)s")
        let timer = DispatchSource.makeTimerSource(queue: syncQueue)
        timer.schedule(deadline: .now() + timeInterval, repeating: .never)
        timer.setEventHandler { [weak self] in
            _ = self?.syncQueue_scheduledTask()
        }
        timer.activate()
        return timer
    }

    private func syncQueue_scheduledTask() -> Task<(), Never> {
        dispatchPrecondition(condition: .onQueue(syncQueue))

        // We perform work on the syncQueue to ensure atomicity of activeTask and refreshTimer.

        // If there's already an active task, then we return it to allow the caller to monitor it.
        if let activeTask = self.activeTask {
            return activeTask
        }

        // If there's no active task, then we cancel any scheduled timers to ensure we don't get overlapping tasks.
        timer?.cancel()
        timer = nil

        // Next, we create a new task which will perform our operation.
        // This task is responsible for scheduling the timeout for the ntext task.
        let activeTask = Task { [weak self] in
            guard let self else {
                return
            }

            // Run the task.
            let timeInterval = await perform()

            // Schedule the next task and clear the current task.
            syncQueue.async { [weak self] in
                guard let self else {
                    return
                }
                self.activeTask = nil
                guard let timeInterval else {
                    return
                }
                self.timer = self.scheduledTimer(timeInterval: timeInterval)
            }
        }

        // Update the active task to our newly created task.
        self.activeTask = activeTask
        return activeTask
    }

    func run() async {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        let task = syncQueue.sync {
            return self.syncQueue_scheduledTask()
        }
        await task.value
    }

    func cancel() {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync {
            timer?.cancel()
            timer = nil
            activeTask?.cancel()
            activeTask = nil
        }
    }

}

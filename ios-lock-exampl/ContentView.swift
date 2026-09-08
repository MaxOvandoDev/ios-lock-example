//
//  ContentView.swift
//  ios-lock-example
//
//  Created by Maximiliano Ovando Ramirez on 07/09/26.
//

import SwiftUI
import os

// MARK: - Models / Data Structures

/// Represents an execution log entry captured during concurrent operations.
struct OperationLog: Identifiable {
    let id = UUID()
    let timestamp: String
    let threadName: String
    let valueAfterDeposit: Int
}

// MARK: - 0. Unsafe Implementation (Race Condition Demo)

/// Demonstrates unsynchronized memory access. Multiple threads read and write simultaneously.
final class UnsafeAccount {
    var balance: Int = 0
    
    func deposit(completion: @escaping (Int) -> Void) {
        let current = balance
        // Simulate heavy work inside the thread to force a thread collision
        Thread.sleep(forTimeInterval: 1)
        balance = current + 10
        completion(balance)
    }
}

// MARK: - 1. NSLock Implementation

/// Traditional synchronization using NSLock to protect critical sections.
final class NSLockAccount {
    private(set) var balance: Int = 0
    private let lock = NSLock()
    
    func deposit(completion: @escaping (Int) -> Void) {
        lock.lock() // Acquires the lock; blocks other threads from entering
        defer { lock.unlock() } // Releases the lock upon exiting function scope
        
        let current = balance
        Thread.sleep(forTimeInterval: 0.05)
        balance = current + 10
        completion(balance)
    }
}

// MARK: - 2. Actor Implementation (Modern Swift Concurrency)

/// Swift Actor automatically isolates mutable state at compile time.
actor ActorAccount {
    private(set) var balance: Int = 0
    
    func deposit() -> Int {
        let current = balance
        Thread.sleep(forTimeInterval: 0.05)
        balance = current + 10
        return balance
    }
}

// MARK: - 3. DispatchQueue Implementation (GCD Serial Queue)

/// Serial queue synchronization ensuring tasks are processed sequentially.
final class GCDAccount {
    private(set) var balance: Int = 0
    private let queue = DispatchQueue(label: "com.example.gcd")
    
    func deposit(completion: @escaping (Int) -> Void) {
        queue.async {
            let current = self.balance
            Thread.sleep(forTimeInterval: 0.05)
            self.balance = current + 10
            completion(self.balance)
        }
    }
}

// MARK: - 4. OSAllocatedUnfairLock Implementation (iOS 16+ High Performance)

/// High-performance, lightweight lock ideal for modern iOS development.
final class UnfairLockAccount {
    private let lock = OSAllocatedUnfairLock(initialState: 0)
    
    var balance: Int {
        lock.withLock { $0 }
    }
    
    func deposit(completion: @escaping (Int) -> Void) {
        lock.withLock { balance in
            let current = balance
            Thread.sleep(forTimeInterval: 0.05)
            balance = current + 10
            completion(balance)
        }
    }
}

// MARK: - SwiftUI View

struct ContentView: View {
    @State private var balanceResult: Int = 0
    @State private var selectedMethod: String = "Ninguno"
    @State private var isProcessing: Bool = false
    @State private var logs: [OperationLog] = []
    
    private let iterations = 50 // Expected result: 50 * 10 = 500

    var body: some View {
        VStack(spacing: 20) {
            // Header summary card
            VStack(spacing: 8) {
                Text("Método actual: \(selectedMethod)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Saldo final: \(balanceResult)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(balanceResult == 500 ? .green : (balanceResult == 0 ? .primary : .red))
                
                Text("Resultado esperado: 500")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
            
            // Interactive test controls
            if isProcessing {
                ProgressView("Ejecutando \(iterations) hilos...")
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Button("1. Sin Protección (Unsafe)") {
                        runUnsafeTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    HStack(spacing: 8) {
                        Button("2. Con NSLock") {
                            runNSLockTest()
                        }
                        .buttonStyle(.bordered)

                        Button("3. Con Actor") {
                            runActorTest()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 8) {
                        Button("4. Con GCD Queue") {
                            runGCDTest()
                        }
                        .buttonStyle(.bordered)

                        Button("5. OSUnfairLock") {
                            runUnfairLockTest()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // Real-time execution logs list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Logs de ejecución (\(logs.count))")
                        .font(.headline)
                    Spacer()
                    if !logs.isEmpty {
                        Button("Limpiar") { logs.removeAll() }
                            .font(.caption)
                    }
                }

                List(logs) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.threadName)
                                .font(.caption2)
                                .monospaced()
                                .foregroundColor(.blue)
                            Text(item.timestamp)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Saldo: \(item.valueAfterDeposit)")
                            .font(.subheadline)
                            .bold()
                            .monospacedDigit()
                    }
                }
                .listStyle(.plain)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
            }
        }
        .padding()
    }

    // MARK: - Test Runners

    private func runUnsafeTest() {
        prepareTest(methodName: "Sin Protección")
        let account = UnsafeAccount()
        let group = DispatchGroup()
        
        for _ in 1...iterations {
            DispatchQueue.global().async(group: group) {
                account.deposit { newBalance in
                    self.recordLog(balance: newBalance)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.balanceResult = account.balance
            self.isProcessing = false
        }
    }

    private func runNSLockTest() {
        prepareTest(methodName: "NSLock")
        let account = NSLockAccount()
        let group = DispatchGroup()
        
        for _ in 1...iterations {
            DispatchQueue.global().async(group: group) {
                account.deposit { newBalance in
                    self.recordLog(balance: newBalance)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.balanceResult = account.balance
            self.isProcessing = false
        }
    }

    private func runActorTest() {
        prepareTest(methodName: "Actor (Swift Concurrency)")
        let account = ActorAccount()
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for _ in 1...iterations {
                    group.addTask {
                        let newBalance = await account.deposit()
                        self.recordLog(balance: newBalance)
                    }
                }
            }
            let finalBalance = await account.balance
            await MainActor.run {
                self.balanceResult = finalBalance
                self.isProcessing = false
            }
        }
    }

    private func runGCDTest() {
        prepareTest(methodName: "DispatchQueue (GCD)")
        let account = GCDAccount()
        let group = DispatchGroup()
        
        for _ in 1...iterations {
            group.enter()
            account.deposit { newBalance in
                self.recordLog(balance: newBalance)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.balanceResult = account.balance
            self.isProcessing = false
        }
    }

    private func runUnfairLockTest() {
        prepareTest(methodName: "OSAllocatedUnfairLock")
        let account = UnfairLockAccount()
        let group = DispatchGroup()
        
        for _ in 1...iterations {
            DispatchQueue.global().async(group: group) {
                account.deposit { newBalance in
                    self.recordLog(balance: newBalance)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.balanceResult = account.balance
            self.isProcessing = false
        }
    }

    // MARK: - Helper Methods

    private func prepareTest(methodName: String) {
        selectedMethod = methodName
        balanceResult = 0
        logs.removeAll()
        isProcessing = true
    }

    /// Thread-safe logger capturing the current thread address and accurate timestamp.
    private func recordLog(balance: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        
        let threadName = Thread.isMainThread ? "Main Thread" : "Thread-\(String(format: "%p", Thread.current))"
        let newLog = OperationLog(timestamp: timestamp, threadName: threadName, valueAfterDeposit: balance)
        
        DispatchQueue.main.async {
            self.logs.append(newLog)
        }
    }
}

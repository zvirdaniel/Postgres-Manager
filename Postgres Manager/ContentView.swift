import SwiftUI

struct ContentView: View {
    @State private var status: String = "Unknown"
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // Full path to brew
    private let brewPath = "/opt/homebrew/bin/brew"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PostgreSQL@14 Status")
                .font(.title)
            
            Text(status)
                .font(.headline)
                .foregroundColor(status == "Running" ? .green : .red)
            
            HStack(spacing: 20) {
                Button("Start") {
                    executeBrewCommand("services start postgresql@14")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Stop") {
                    executeBrewCommand("services stop postgresql@14")
                }
                .buttonStyle(.bordered)
            }
            
            Button(action: fetchStatus) {
                Label("Refresh Status", systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear(perform: fetchStatus)
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Run a brew command via login zsh shell
    private func executeBrewCommand(_ command: String) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let output = runBrew(command)
            
            if output.isEmpty {
                showAppError("Failed to run brew command: \(command)")
            }
            
            fetchStatus()
        }
    }
    
    private func fetchStatus() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let output = runBrew("services info postgresql@14 --json")
            
            DispatchQueue.main.async {
                if let newStatus = parseStatus(from: output) {
                    self.status = newStatus
                } else {
                    self.status = "Unknown"
                    self.showAppError("Failed to parse JSON from brew:\n\(output)")
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Run brew inside a login zsh shell
    private func runBrew(_ arguments: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // -l = login shell, -c = run command
        process.arguments = ["-l", "-c", "\(brewPath) \(arguments)"]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            DispatchQueue.main.async {
                self.showAppError("Failed to run brew: \(error)")
            }
            return ""
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    // MARK: - Parse JSON from brew services info
    private func parseStatus(from jsonString: String) -> String? {
        struct BrewServiceInfo: Codable {
            let running: Bool
        }
        
        guard let data = jsonString.data(using: .utf8), !jsonString.isEmpty else { return nil }
        
        do {
            let decoded = try JSONDecoder().decode([BrewServiceInfo].self, from: data)
            if let first = decoded.first {
                return first.running ? "Running" : "Stopped"
            }
            return nil
        } catch {
            print("Failed to parse JSON:", error)
            print("Raw output:", jsonString)
            return nil
        }
    }
    
    // MARK: - Show error alert
    private func showAppError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

//
//  Hi. Good morning and welcome.
//  Made by Taj C (@forcequitOS) with some kind of emotion.
//

import Foundation
import FoundationModels
import Swifter

// Defines the fields accepted in the request
// This should be relatively compatible with OpenAI/Ollama's API I want to say? This just has no stream option or model option, so if those are passed through, they'll be ignored.
struct RequestBody: Codable {
    let prompt: String
    let system: String?
    let temperature: Double?
    let max_tokens: Int?
}
let server = HttpServer()
let portNumber: in_port_t = in_port_t(ProcessInfo.processInfo.environment["IRIS_PORT"].flatMap(UInt16.init) ?? 2526)

@main
struct Iris {
    static func main() {
        let model = SystemLanguageModel.default
        
        // Check model availability FIRST before even allowing you to host the server
        switch model.availability {
        case .available:
            print("Apple Intelligence is available and supported! Starting Iris server...")
            Iris().hostServer()
        case .unavailable(.deviceNotEligible):
            print("This device is unsupported by Apple Intelligence and cannot be used as a server with Iris.")
            exit(1)
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Apple Intelligence is currently disabled on this device. Iris will be available after enabling Apple Intelligence from System Settings.")
            exit(1)
        case .unavailable(.modelNotReady):
            print("Models for Apple Intelligence are downloading, please wait and try again.")
            exit(0)
        case .unavailable(_):
            print("Apple Intelligence is unavailable.")
            exit(1)
        }
    }
    
    func hostServer() {
        func handleGenerateRequest(_ request: HttpRequest) -> HttpResponse {
            guard request.method == "POST" else {
                return HttpResponse.badRequest(nil)
            }
            // Handle getting the actual data from the request
            let rawData = request.body
            guard !rawData.isEmpty else {
                return HttpResponse.badRequest(nil)
            }
            let jsonData = Data(rawData)
            
            do {
                let decoder = JSONDecoder()
                let body = try decoder.decode(RequestBody.self, from: jsonData)
                
                // All the FoundationModels stuff (That I actually bothered learning how to use the API for instead of vibe coding!)
                let prompt = body.prompt
                let sysInstructions = body.system ?? ProcessInfo.processInfo.environment["IRIS_SYSTEM"] ?? nil
                let temp = body.temperature ?? Double(ProcessInfo.processInfo.environment["IRIS_TEMPERATURE"] ?? "") ?? nil
                let maxTokens = body.max_tokens ?? Int(ProcessInfo.processInfo.environment["IRIS_MAX_TOKENS"] ?? "") ?? nil
                let genOptions = GenerationOptions(temperature: temp, maximumResponseTokens: maxTokens)
                let session = LanguageModelSession(instructions: sysInstructions)
                func generateResponse() async -> String {
                    do {
                        let response = try await session.respond(to: prompt, options: genOptions)
                        return response.content
                    } catch LanguageModelSession.GenerationError.guardrailViolation {
                        return "Your request has been filtered, please try again."
                    } catch {
                        return "An error occurred while processing your request: \(error.localizedDescription)"
                    }
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                var httpResponse: HttpResponse = .internalServerError
                
                Task {
                    do {
                        let result = await generateResponse()
                        let jsonResponse: [String: String] = ["response": result]
                        let responseData = try JSONEncoder().encode(jsonResponse)
                        httpResponse = HttpResponse.ok(.data(responseData, contentType: "application/json"))
                        // Extremely simple logging of requests to the command line since I felt like it. If you don't like it, just mute it's output. If you want to redirect to a file, just do that. I was considering having those both as options for an environment variable but got lazy.
                        print("""
                            Request Received:
                                \(prompt)
                            Response:
                                \(result)
                            Timestamp:
                                \(Date.now.formatted(date: .numeric, time: .complete))
                            """)
                    } catch {
                        print("Error generating response: \(error)")
                        httpResponse = HttpResponse.internalServerError
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()
                return httpResponse
                
            } catch {
                print("Error decoding request: \(error)")
                return HttpResponse.internalServerError
            }
        }
        
        // My original, simple, plain route (With an extra bit of Ollama client compatibility)
        server["/"] = { request in
            if request.method != "POST" {
                return HttpResponse.ok(.text("OK"))
            } else {
                return handleGenerateRequest(request)
            }
        }
        
        // The silly Ollama route for compatibility's sake
        server["/api/generate"] = { request in
            return handleGenerateRequest(request)
        }

        do {
            // This is entirely just for Ollama API compatibility for some fussy examples I've seen.
            server["/api/tags"] = { request in
                let dummyResponse = """
                {
                  "models": [
                    {
                      "name": "apple-intelligence:latest",
                      "model": "apple-intelligence:latest",
                    }
                  ]
                }
                """
                return HttpResponse.ok(.data(Data(dummyResponse.utf8), contentType: "application/json"))
            }
            
            // Supports just running Iris without leaving it accessible to other devices on the local network
            let bindToLocalhost = ProcessInfo.processInfo.environment["IRIS_LOCAL_ONLY"]?.lowercased() == "true"
            let bindAddressIPv4 = bindToLocalhost ? "127.0.0.1" : "0.0.0.0"
            let bindAddressIPv6 = bindToLocalhost ? "::1" : "::"
            server.listenAddressIPv4 = bindAddressIPv4
            server.listenAddressIPv6 = bindAddressIPv6
            
            try server.start(portNumber)
            print("Iris started on port \(portNumber)!")
            // This used to be some wacky async nonsense but I realized this function as a whole does not have to be in an async context.
            RunLoop.main.run()
        } catch {
            print("Iris failed to start: \(error)")
        }
    }
}

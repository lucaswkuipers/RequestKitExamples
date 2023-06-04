import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("Send request") {
            Task {
                let response = await URL(string: "https://api.openai.com/v1/chat/completions")?
                    .request
                    .method(.post)
                    .authorizationBearer("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")
                    .contentType(.json)
                    .body(ChatCompletionRequest(model: .gpt_3, messages: [.init(role: .user, content: "My name is Lucas. What is my name?")]).encoded())
                    .perform()?
                    .data
                    .decoded(of: ChatCompletionResponse.self)?
                    .choices.first?.message.content

                print(response?.debugDescription)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import RequestKit

struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: RemoteMessage
    }
}

struct RemoteMessage: Codable {
    let role: Role
    let content: String

    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
}

struct ChatCompletionRequest: Encodable {
    let model: Model
    let messages: [RemoteMessage]

    enum Model: String, Encodable {
        case gpt_4 = "gpt-4"
        case gpt_3 = "gpt-3.5-turbo"
    }
}

import Foundation

extension Data {
    func describe() {
        let json = try? JSONSerialization.jsonObject(with: self, options: [])
        print(json.debugDescription)
    }
}

import SwiftUI
import RequestKit

struct ContentView: View {
    @State var response = "What do you want to know?"
    @State var prompt = ""

    @State var service = ChatService()

    var body: some View {
        VStack {
            Text(response)
            TextField("Ask me something...", text: $prompt)
                .onSubmit {
                    service.fetchAnswer(for: prompt) { answer in
                        guard let answer else { return }
                        self.response = answer
                    }
                    prompt = ""
                }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ChatService {
    let name = "ChatGPT"
    lazy var preText = "The following is a chat between someone and \(name)"

    lazy var conversation = preText
    lazy var api = OpenAICompletionAPI(
        model: "text-davinci-003",
        temperature: 0.9,
        maxTokens: 150,
        topP: 1,
        frequencyPenalty: 0.1,
        presencePenalty: 0.6,
        stop: [" Someone:", "\(name):"]
    )

    mutating func fetchAnswer(for prompt: String, completion: @escaping (String?) -> Void) {
        conversation +=
"""
Someone: \(prompt)
\(name):
""" + " "
        api.fetchCompletion(for: conversation) {
            completion($0?.choices.first?.text)
        }
    }
}

struct OpenAICompletionAPI {
    let model: String
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    let frequencyPenalty: Double
    let presencePenalty: Double
    let stop: [String]

    let apiKey = "replace-with-your-api-key"

    func fetchCompletion(for prompt: String, completion: @escaping (OpenAICompletionAPIResponse?) -> Void) {
        URL(string: "https://api.openai.com/v1/completions")?
            .request
            .method(.post)
            .contentType(.json)
            .authorizationBearer(apiKey)
            .body(
                [
                    "model": model,
                    "prompt": prompt,
                    "temperature": temperature,
                    "max_tokens": maxTokens,
                    "top_p": topP,
                    "frequency_penalty": frequencyPenalty,
                    "presence_penalty": presencePenalty,
                    "stop": stop
                ]
            )
            .perform { (result: Result<OpenAICompletionAPIResponse, Error>) in
                switch result {
                case .success(let success):
                    print("Got API response: \(success)")
                    completion(success)
                case .failure(let error):
                    print("Failed to get API response: \(error)")
                }
            }
    }
}

struct OpenAICompletionAPIResponse: Decodable {
    struct Choice: Decodable {
        let finishReason: String
        let index: Int
        let logprobs: String?
        let text: String

        enum CodingKeys: String, CodingKey {
            case finishReason = "finish_reason"
            case index, logprobs, text
        }
    }

    struct Usage: Decodable {
        let completionTokens: Int
        let promptTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case completionTokens = "completion_tokens"
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }

    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
    let usage: Usage
}

import Foundation

public struct OpenAITranslator: Sendable {
    public init() {}

    public func translate(
        text: String,
        systemPrompt: String,
        apiKey: String,
        baseURL: String,
        model: String
    ) async throws -> String {
        let request = try Self.buildRequest(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model,
            systemPrompt: systemPrompt,
            sourceText: text
        )
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw TranslationError.httpStatus(httpResponse.statusCode, message)
        }

        return try Self.parseTranslationResponse(data)
    }

    public static func buildRequest(
        apiKey: String,
        baseURL: String,
        model: String,
        systemPrompt: String,
        sourceText: String
    ) throws -> URLRequest {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TranslationError.missingAPIKey
        }

        let trimmedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TranslationError.emptyText
        }

        let endpointURL = try responsesEndpointURL(from: baseURL)
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "instructions": systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
            "input": trimmedText
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return request
    }

    public static func responsesEndpointURL(from baseURL: String) throws -> URL {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty,
              var components = URLComponents(string: trimmed),
              components.scheme != nil,
              components.host != nil else {
            throw TranslationError.invalidBaseURL
        }

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path == "v1/responses" {
            components.path = "/v1/responses"
        } else if path.hasSuffix("/v1/responses") {
            components.path = "/\(path)"
        } else if path == "v1" || path.hasSuffix("/v1") {
            components.path = "/\(path)/responses"
        } else if path.isEmpty {
            components.path = "/v1/responses"
        } else {
            components.path = "/\(path)/v1/responses"
        }

        guard let url = components.url else {
            throw TranslationError.invalidBaseURL
        }
        return url
    }

    public static func parseTranslationResponse(_ data: Data) throws -> String {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(ResponseEnvelope.self, from: data)

        if let outputText = envelope.outputText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !outputText.isEmpty {
            return outputText
        }

        for item in envelope.output ?? [] {
            for content in item.content ?? [] {
                if content.type == "output_text",
                   let text = content.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !text.isEmpty {
                    return text
                }
            }
        }

        throw TranslationError.invalidResponse
    }
}

private struct ResponseEnvelope: Decodable {
    let outputText: String?
    let output: [ResponseOutput]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private struct ResponseOutput: Decodable {
    let content: [ResponseContent]?
}

private struct ResponseContent: Decodable {
    let type: String?
    let text: String?
}

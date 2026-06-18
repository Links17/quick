import XCTest
@testable import QuickCore

final class OpenAITranslatorTests: XCTestCase {
    func testBuildRequestUsesResponsesAPIAndTranslationInstructions() throws {
        let request = try OpenAITranslator.buildRequest(
            apiKey: "sk-test",
            baseURL: "https://api.openai.com",
            model: "gpt-5.4-mini",
            systemPrompt: "If I input English, translate it into Chinese; if I input Chinese, translate it into English.",
            sourceText: "Hello world"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["model"] as? String, "gpt-5.4-mini")

        XCTAssertEqual(
            json?["instructions"] as? String,
            "If I input English, translate it into Chinese; if I input Chinese, translate it into English."
        )
        XCTAssertEqual(json?["input"] as? String, "Hello world")
    }

    func testBuildRequestAcceptsThirdPartyBaseURLWithoutV1() throws {
        let request = try OpenAITranslator.buildRequest(
            apiKey: "sk-test",
            baseURL: "https://llm.example.com",
            model: "openai-compatible-model",
            systemPrompt: "Translate.",
            sourceText: "Hello"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://llm.example.com/v1/responses")
    }

    func testBuildRequestAcceptsBaseURLWithV1() throws {
        let request = try OpenAITranslator.buildRequest(
            apiKey: "sk-test",
            baseURL: "https://llm.example.com/v1",
            model: "openai-compatible-model",
            systemPrompt: "Translate.",
            sourceText: "Hello"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://llm.example.com/v1/responses")
    }

    func testBuildRequestAcceptsFullResponsesEndpoint() throws {
        let request = try OpenAITranslator.buildRequest(
            apiKey: "sk-test",
            baseURL: "https://llm.example.com/v1/responses",
            model: "openai-compatible-model",
            systemPrompt: "Translate.",
            sourceText: "Hello"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://llm.example.com/v1/responses")
    }

    func testParseResponsesAPIOutputText() throws {
        let data = """
        {
          "output": [
            {
              "content": [
                {
                  "type": "output_text",
                  "text": "你好，世界"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let translated = try OpenAITranslator.parseTranslationResponse(data)

        XCTAssertEqual(translated, "你好，世界")
    }
}

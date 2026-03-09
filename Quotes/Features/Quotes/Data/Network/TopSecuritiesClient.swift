//
//  TopSecuritiesClient.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

protocol TopSecuritiesFetching: AnyObject {
    func fetch(
        using method: RequestMethod,
        completion: @escaping (Result<Data, QuoteServiceError>) -> Void
    )
}

final class TopSecuritiesClient: TopSecuritiesFetching {
    private struct Configuration {
        let type: String
        let exchange: String
        let gainers: Int
        let limit: Int
    }

    private let session: URLSession
    private let endpoint: URL?
    private let callbackQueue: DispatchQueue
    private let configuration: Configuration

    init(
        session: URLSession,
        endpoint: URL?,
        callbackQueue: DispatchQueue,
        type: String,
        exchange: String,
        gainers: Int,
        limit: Int
    ) {
        self.session = session
        self.endpoint = endpoint
        self.callbackQueue = callbackQueue
        self.configuration = Configuration(
            type: type,
            exchange: exchange,
            gainers: gainers,
            limit: limit
        )
    }

    func fetch(
        using method: RequestMethod,
        completion: @escaping (Result<Data, QuoteServiceError>) -> Void
    ) {
        guard let request = makeRequest(for: method) else {
            callbackQueue.async {
                completion(.failure(.topSecuritiesTransport(URLError(.badURL))))
            }
            return
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            self.callbackQueue.async {
                if let error {
                    completion(.failure(.topSecuritiesTransport(error)))
                    return
                }

                if
                    let httpResponse = response as? HTTPURLResponse,
                    !((200 ..< 300) ~= httpResponse.statusCode)
                {
                    completion(.failure(.topSecuritiesHTTPStatus(httpResponse.statusCode)))
                    return
                }

                guard let data else {
                    completion(.failure(.topSecuritiesEmptyPayload))
                    return
                }

                completion(.success(data))
            }
        }.resume()
    }
}

private extension TopSecuritiesClient {
    enum ParameterKey {
        static let type = "type"
        static let exchange = "exchange"
        static let gainers = "gainers"
        static let limit = "limit"
    }

    func makeRequest(for method: RequestMethod) -> URLRequest? {
        switch method {
        case .post:
            makePostRequest()
        case .get:
            makeGetRequest()
        }
    }

    func makePostRequest() -> URLRequest? {
        guard let endpoint else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = RequestMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        return request
    }

    func makeGetRequest() -> URLRequest? {
        guard
            let endpoint,
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        components.queryItems = queryItems
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.get.rawValue
        return request
    }

    var payload: [String: Any] {
        Dictionary(uniqueKeysWithValues: parameterPairs.map { ($0.name, $0.value) })
    }

    var queryItems: [URLQueryItem] {
        parameterPairs.map { URLQueryItem(name: $0.name, value: String(describing: $0.value)) }
    }

    var parameterPairs: [(name: String, value: Any)] {
        [
            (ParameterKey.type, configuration.type),
            (ParameterKey.exchange, configuration.exchange),
            (ParameterKey.gainers, configuration.gainers),
            (ParameterKey.limit, configuration.limit)
        ]
    }
}

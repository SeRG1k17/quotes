//
//  LogoImageLoader.swift
//  Quotes
//
//  Created by s pugach on 5.03.26.
//

import UIKit

protocol LogoImageLoading {
    @discardableResult
    func loadLogo(for symbol: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask?
}

final class LogoImageLoader: LogoImageLoading {
    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }
    
    convenience init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        let session = URLSession(configuration: configuration)
        
        self.init(session: session)
    }

    @discardableResult
    func loadLogo(for symbol: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        let normalizedSymbol = symbol.lowercased()
        let cacheKey = normalizedSymbol as NSString

        if let cached = cachedImage(for: cacheKey) {
            completion(cached)
            return nil
        }

        guard let url = logoURL(for: normalizedSymbol) else {
            completion(nil)
            return nil
        }

        let task = makeLoadTask(url: url, cacheKey: cacheKey, completion: completion)
        task.resume()
        return task
    }
}

private extension LogoImageLoader {
    func cachedImage(for key: NSString) -> UIImage? {
        cache.object(forKey: key)
    }

    func logoURL(for normalizedSymbol: String) -> URL? {
        guard var components = URLComponents(string: "https://tradernet.com/logos/get-logo-by-ticker") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "ticker", value: normalizedSymbol)]
        return components.url
    }

    func makeLoadTask(
        url: URL,
        cacheKey: NSString,
        completion: @escaping (UIImage?) -> Void
    ) -> URLSessionDataTask {
        session.dataTask(with: url) { [weak self] data, response, _ in
            guard let image = self?.parseImage(data: data, response: response) else {
                completion(nil)
                return
            }

            self?.cache.setObject(image, forKey: cacheKey)
            completion(image)
        }
    }

    func parseImage(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data,
            let httpResponse = response as? HTTPURLResponse,
            (200..<300) ~= httpResponse.statusCode
        else {
            return nil
        }

        return UIImage(data: data)
    }
}

import Foundation

final class NetworkServiceImpl: NetworkService {
    private let session: URLSession

    init(config: URLSessionConfiguration = .default) {
        session = URLSession(configuration: config)
    }

    deinit {
        print("\(self) deinit")
    }

    func fetchAccounts(completion: @escaping (Result<AccountsResponse, Error>) -> Void) {
        request(target: API.fetchAccounts, completion: completion)
    }
}

private extension NetworkServiceImpl {
    func request<Target, Output, U>(target: Target,
                                    keyPath: KeyPath<Output, U>,
                                    decoder: JSONDecoder? = nil,
                                    requestQueue: DispatchQueue = .global(),
                                    parsingQueue: DispatchQueue = .global(),
                                    responseQueue: DispatchQueue = .global(),
                                    completion: @escaping (Result<U, Error>) -> Void) where Target: TargetType, Output: Decodable {
        request(target: target, decoder: decoder,
                requestQueue: requestQueue, parsingQueue: parsingQueue,
                responseQueue: responseQueue) { (result: Result<Output, Error>) in
            switch result {
            case let .success(value):
                completion(.success(value[keyPath: keyPath]))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func request<Target, Output>(target: Target,
                                 decoder: JSONDecoder? = nil,
                                 requestQueue: DispatchQueue = .global(),
                                 parsingQueue: DispatchQueue = .global(),
                                 responseQueue: DispatchQueue = .global(),
                                 completion: @escaping (Result<Output, Error>) -> Void) where Target: TargetType, Output: Decodable {
        requestQueue.async {
            do {
                let request = try target.asURLRequest()

                let task = self.session.dataTask(with: request, completion: { response in
                    Parser.parse(response, decoder: decoder, queue: parsingQueue, completion: { parsed in
                        responseQueue.async {
                            completion(parsed)
                        }
                    })
                })

                task.resume()
            } catch {
                responseQueue.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

extension URLSession {
    func dataTask(with request: URLRequest, completion: @escaping (SessionResponse) -> Void) -> URLSessionDataTask {
        dataTask(with: request) { data, response, error in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(.init(statusCode: -1, result: .failure(SessionResponse.Error.invalidResponse)))
                return
            }

            let resp: SessionResponse

            switch (data, error) {
            case let (data?, _):
                resp = SessionResponse(statusCode: statusCode, result: .success(data))
            case let (_, error?):
                resp = SessionResponse(statusCode: statusCode, result: .failure(error))
            default:
                resp = SessionResponse(statusCode: -1, result: .failure(SessionResponse.Error.invalidResponse))
            }

            completion(resp)
        }
    }
}
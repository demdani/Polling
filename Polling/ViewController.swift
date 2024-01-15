import UIKit
import Combine

class ViewController: UIViewController {

    private var subscriptions: Set<AnyCancellable> = []
    
    private let repository = Repository()
    private let pollingDelays = [1, 2, 4, 8, 16]
    private var pollingCounter = 0
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func didTapButton(_ sender: Any) {
        guard !isLoading else { return }
        isLoading.toggle()
        
        repository.poll()
            .tryCatch { [weak self, repository, pollingDelays] _ -> AnyPublisher<Void, PollingError> in
                let counter = self?.pollingCounter ?? 0
                let delay = pollingDelays[counter]
                
                print("retry after \(delay)")
                
                self?.pollingCounter += 1
                
                return Just(Void.self)
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                    .setFailureType(to: PollingError.self)
                    .eraseToAnyPublisher()
                    .flatMap { _ in
                        repository.poll()
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .retry(pollingDelays.count - 1)
            .sink { [weak self] result in
                self?.isLoading.toggle()
                self?.pollingCounter = 0
                
                guard case let .failure(error as PollingError) = result else { return }
                
                switch error {
                case .wait:
                    print("polling finished wait")
                case .error:
                    print("polling finished error")
                case .combine(_):
                    print("polling finished other error")
                }
            } receiveValue: { _ in
                print("polling finished success")
            }
            .store(in: &subscriptions)
    }
}


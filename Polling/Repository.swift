import Foundation
import Combine

enum CombineError: Error {
    case network
    case json
    case unknonw
}

enum PollingError: Error {
    case wait
    case error
    case combine(CombineError)
}

struct PollingResponse {}

class Repository {
    
    private var counter = 0
    
    func poll() -> Future<Void, PollingError> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.counter += 1
            
            DispatchQueue.main.async {
                print("response arrived")
                
                if self.counter % 6 == 0 {
                    promise(.success(()))
                    //promise(.failure(.wait))
                } else {
                    promise(.failure(.wait))
                }
            }
        }
    }
}

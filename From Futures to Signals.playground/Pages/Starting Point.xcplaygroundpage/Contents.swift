import Cocoa

enum Result<A> {
    case success(A)
    case error(Error)
    
    init(_ value: A?, or error: Error) {
        if let value = value {
            self = .success(value)
        } else {
            self = .error(error)
        }
    }
}

final class KeyValueObserver<A>: NSObject {
    let block: (A) -> ()
    let keyPath: String
    var object: NSObject
    init(object: NSObject, keyPath: String, _ block: @escaping (A) -> ()) {
        self.block = block
        self.keyPath = keyPath
        self.object = object
        super.init()
        object.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
    }
    
    deinit {
        object.removeObserver(self, forKeyPath: keyPath)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        block(change![.newKey] as! A)
    }
}


extension Result {
    func map<B>(_ transform: (A) -> B) -> Result<B> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .error(let error): return .error(error)
        }
    }
}

extension String: Error { }

final class Future<A> {
    var callbacks: [(Result<A>) -> ()] = []
    var cached: Result<A>?
    
    init(compute: (@escaping (Result<A>) -> ()) -> ()) {
        compute(self.send)
    }
    
    private func send(_ value: Result<A>) {
        assert(cached == nil)
        cached = value
        for callback in callbacks {
            callback(value)
        }
        callbacks = []
    }
    
    func onResult(callback: @escaping (Result<A>) -> ()) {
        if let value = cached {
            callback(value)
        } else {
            callbacks.append(callback)
        }
    }
}

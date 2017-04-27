// See also
// https://gist.github.com/calebd/93fa347397cec5f88233
// https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html

import Foundation
import Async

class AsyncOperation: Operation {

    // MARK: - Types

    enum State {
        case ready, executing, finished
        func keyPath() -> String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }

    // MARK: - Properties

    var state: State {
        willSet {
            willChangeValue(forKey: newValue.keyPath())
            willChangeValue(forKey: state.keyPath())
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath())
            didChangeValue(forKey: state.keyPath())
        }
    }

    // MARK: - Initializers

    override init() {
        state = .ready
        super.init()
    }

    // MARK: - NSOperation

    override var isReady: Bool {
        return super.isReady && state == .ready
    }

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    override var isAsynchronous: Bool {
        return true
    }

}

class AsyncBlockOperation: AsyncOperation {

    let executionBlock: (_ op: AsyncBlockOperation) -> Void

    init(_ executionBlock: @escaping (_ op: AsyncBlockOperation) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override func start() {
        super.start()
        state = .executing
        executionBlock(self)
    }

    override func cancel() {
        super.cancel()
        state = .finished
    }

    func finish() {
        state = .finished
    }

}

class MainBlockOperation: AsyncOperation {

    let executionBlock: (_ op: MainBlockOperation) -> Void

    init(_ executionBlock: @escaping (_ op: MainBlockOperation) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override func start() {
        super.start()
        state = .executing
        Async.main {
            self.executionBlock(self)
        }
    }

    override func cancel() {
        super.cancel()
        state = .finished
    }

    func finish() {
        state = .finished
    }

}

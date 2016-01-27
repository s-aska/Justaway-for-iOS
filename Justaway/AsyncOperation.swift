// See also
// https://gist.github.com/calebd/93fa347397cec5f88233
// https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html

import Foundation
import Async

class AsyncOperation: NSOperation {

    // MARK: - Types

    enum State {
        case Ready, Executing, Finished
        func keyPath() -> String {
            switch self {
            case Ready:
                return "isReady"
            case Executing:
                return "isExecuting"
            case Finished:
                return "isFinished"
            }
        }
    }

    // MARK: - Properties

    var state: State {
        willSet {
            willChangeValueForKey(newValue.keyPath())
            willChangeValueForKey(state.keyPath())
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath())
            didChangeValueForKey(state.keyPath())
        }
    }

    // MARK: - Initializers

    override init() {
        state = .Ready
        super.init()
    }

    // MARK: - NSOperation

    override var ready: Bool {
        return super.ready && state == .Ready
    }

    override var executing: Bool {
        return state == .Executing
    }

    override var finished: Bool {
        return state == .Finished
    }

    override var asynchronous: Bool {
        return true
    }

}

class AsyncBlockOperation: AsyncOperation {

    let executionBlock: (op: AsyncBlockOperation) -> Void

    init(_ executionBlock: (op: AsyncBlockOperation) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override func start() {
        super.start()
        state = .Executing
        executionBlock(op: self)
    }

    override func cancel() {
        super.cancel()
        state = .Finished
    }

    func finish() {
        state = .Finished
    }

}

class MainBlockOperation: AsyncOperation {

    let executionBlock: (op: MainBlockOperation) -> Void

    init(_ executionBlock: (op: MainBlockOperation) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override func start() {
        super.start()
        state = .Executing
        Async.main {
            self.executionBlock(op: self)
        }
    }

    override func cancel() {
        super.cancel()
        state = .Finished
    }

    func finish() {
        state = .Finished
    }

}

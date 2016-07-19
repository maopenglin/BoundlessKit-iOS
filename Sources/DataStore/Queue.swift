//
//  Queue.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation

internal class QueueElement<T> {
    let value: T!
    var next: QueueElement?
    
    init(_ newValue: T?) {
        self.value = newValue
    }
}

public class Queue<T> {
    
    var _head: QueueElement<T>
    var _tail: QueueElement<T>
    
    public var size = 0
    
    public init () {
        // Insert dummy item. Will disappear when the first item is added.
        _tail = QueueElement(nil)
        _head = _tail
    }
    
    /// Add a new item to the back of the queue.
    public func enqueue (value: T) {
        _tail.next = QueueElement(value)
        _tail = _tail.next!
        size+=1
    }
    
    /// Return and remove the item at the front of the queue.
    public func dequeue () -> T? {
        if let newHead = _head.next {
            _head = newHead
            size-=1
            return newHead.value
        } else {
            return nil
        }
    }
    
    public func isEmpty() -> Bool {
        return _head === _tail
    }
}
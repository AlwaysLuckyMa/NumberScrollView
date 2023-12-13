//
//  ViewController.swift
//  NumberScrollview
//
//  Created by satoshi_umaM1 on 2023/12/6.
//

/// 一个计算两个字符串之间差异的函数。
public struct DiffingFunction {
    /// 可以对字符串执行的操作。
    public enum Operation: Equatable {
        /// 在给定偏移量处插入字符。
        case insert(offset: Int, element: Character)
        /// 在给定偏移量处删除字符。
        case remove(offset: Int, element: Character)
    }

    let diff: (String, String) -> [Operation]

    /// 使用给定的差异函数创建一个新的`DiffingFunction`。
    ///
    /// - Parameters:
    ///   - diff: 一个计算两个字符串之间差异的函数。
    public init(_ diff: @escaping (String, String) -> [Operation]) {
        self.diff = diff
    }

    /// 调用差异函数。
    ///
    /// - Parameters:
    ///   - oldValue: 旧值。
    ///   - newValue: 新值。
    /// - Returns: 旧值和新值之间的差异。
    public func callAsFunction(from oldValue: String, to newValue: String) -> [Operation] {
        return diff(oldValue, newValue)
    }
}

public extension DiffingFunction {
    /// 使用`String.difference(from:)`计算两个字符串之间差异的差异函数。
    static var system: DiffingFunction {
        DiffingFunction { oldValue, newValue in
            let changes = newValue.difference(from: oldValue)
            return changes.map { change in
                switch change {
                case .insert(offset: let offset, element: let element, associatedWith: _):
                    return .insert(offset: offset, element: element)
                case .remove(offset: let offset, element: let element, associatedWith: _):
                    return .remove(offset: offset, element: element)
                }
            }
        }
    }

    /// 默认的差异函数。
    ///
    /// 该函数通过始终移除第一个不匹配的字符来最小化移动。
    static var `default`: DiffingFunction {
        DiffingFunction { oldValue, newValue in
            var insertions: [Operation] = []
            var removals: [Operation] = []

            let newChars = Array(newValue)
            let oldChars = Array(oldValue)

            for (index, char) in newValue.enumerated() {
                if index >= oldChars.count {
                    insertions.append(.insert(offset: index, element: char))
                    continue
                }

                if char != oldChars[index] {
                    removals.append(.remove(offset: index, element: oldChars[index]))
                    insertions.append(.insert(offset: index, element: char))
                }
            }

            if newChars.count < oldChars.count {
                for index in newChars.count ..< oldChars.count {
                    removals.append(.remove(offset: index, element: oldChars[index]))
                }
            }

            return removals.reversed() + insertions
        }
    }

    /// 一个将插入操作从第一个不匹配的字符开始分组的差异函数。
    static var grouped: DiffingFunction {
        DiffingFunction { oldValue, newValue in
            var insertions: [Operation] = []
            var removals: [Operation] = []

            let newChars = Array(newValue)
            let oldChars = Array(oldValue)

            let startIndex = zip(oldChars.indices, newChars.indices)
                .first { oldChars[$0] != newChars[$1] }
                .map { $0.0 } ?? 0

            if startIndex < oldChars.count {
                for index in startIndex ..< oldChars.count {
                    removals.append(.remove(offset: index, element: oldChars[index]))
                }
            }

            if startIndex < newChars.count {
                for index in startIndex ..< newChars.count {
                    insertions.append(.insert(offset: index, element: newChars[index]))
                }
            }

            return removals.reversed() + insertions
        }
    }
}

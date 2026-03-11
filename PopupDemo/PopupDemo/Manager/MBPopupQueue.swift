//
//  MBPopupQueue.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import Foundation

/// 弹窗队列管理器
@objc(MBPopupQueue)
@objcMembers
public class MBPopupQueue: NSObject {
    
    // MARK: - Properties
    
    /// 队列中的弹窗列表（按优先级降序排列）
    private var popups: [MBPopupTaskProtocol] = []
    
    /// 队列长度
    public var count: Int {
        return popups.count
    }
    
    /// 是否为空
    public var isEmpty: Bool {
        return popups.isEmpty
    }
    
    // MARK: - Queue Operations
        
    /// 加入队列（根据弹窗自身优先级）
    public func enqueue(_ popup: MBPopupTaskProtocol) {
        // 检查是否已存在相同ID的弹窗
        if popups.contains(where: { $0.popupId == popup.popupId }) {
            return
        }
        
        // 找到插入位置
        let insertIndex = findInsertIndex(for: popup)
        popups.insert(popup, at: insertIndex)
    }
    
    /// 查找插入位置（按优先级排序，同优先级 FIFO）
    /// - Parameter popup: 要插入的弹窗
    /// - Returns: 插入位置索引
    private func findInsertIndex(for popup: MBPopupTaskProtocol) -> Int {
        return popups.firstIndex { $0.priority.rawValue < popup.priority.rawValue } ?? popups.count
    }
    
    /// 出队（取出最高优先级弹窗）
    @discardableResult
    public func dequeue() -> MBPopupTaskProtocol? {
        guard !popups.isEmpty else {
            return nil
        }
        
        return popups.removeFirst()
    }
    
    /// 查看队首弹窗（不移除）
    public func peek() -> MBPopupTaskProtocol? {
        return popups.first
    }
    
    /// 查找指定ID的弹窗
    public func find(popupId: String) -> MBPopupTaskProtocol? {
        return popups.first { $0.popupId == popupId }
    }
    
    /// 根据popupId移除弹窗
    @discardableResult
    public func remove(popupId: String) -> Bool {
        if let index = popups.firstIndex(where: { $0.popupId == popupId }) {
            popups.remove(at: index)
            return true
        }
        
        return false
    }
    
    /// 清空所有队列
    public func clear() {
        popups.removeAll()
    }
    
    // MARK: - Debug
    
    /// 调试信息
    public func debugInfo() -> [String: Any] {
        let popupsPayload: [[String: Any]] = popups.enumerated().map { index, popup in
            [
                "index": index,
                "popupId": popup.popupId,
                "priority": popup.priority.rawValue,
                "scene": popup.scene.stringValue()
            ]
        }
        return [
            "name": "MBPopupQueue",
            "count": popups.count,
            "popups": popupsPayload
        ]
    }
}

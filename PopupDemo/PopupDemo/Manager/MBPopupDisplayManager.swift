//
//  MBPopupDisplayManager.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import Foundation

/// 弹窗显示管理器
/// 负责管理当前正在显示的弹窗列表
@objc(MBPopupDisplayManager)
@objcMembers
public class MBPopupDisplayManager: NSObject {
    
    // MARK: - Properties
    
    /// 当前显示的所有弹窗
    /// 数组顺序即为显示顺序，后添加的自然覆盖先添加的
    private var showingPopups: [MBPopupTaskProtocol] = []

    /// suspend 策略下，新弹窗 popupId -> 被暂停的弹窗
    /// 当新弹窗 dismiss 时，恢复对应的被暂停弹窗
    /// - Note: 使用 popupId 作为 key 存储，resume 后立即移除，避免循环引用
    private var suspendedBy: [String: MBPopupTaskProtocol] = [:]
    
    // MARK: - Public Methods
    
    /// 添加弹窗到显示列表
    public func add(_ popup: MBPopupTaskProtocol) {
        showingPopups.append(popup)
    }
    
    /// 移除指定的弹窗
    /// - Parameter popupId: 弹窗ID
    /// - Returns: 是否成功移除
    @discardableResult
    public func remove(popupId: String) -> Bool {
        let beforeCount = showingPopups.count
        showingPopups.removeAll { $0.popupId == popupId }
        return showingPopups.count < beforeCount
    }
    
    /// 获取最顶层的弹窗（最后添加的）
    public func getTopPopup() -> MBPopupTaskProtocol? {
        return showingPopups.last
    }
        
    /// 检查是否为空
    public var isEmpty: Bool {
        return showingPopups.isEmpty
    }
    
    /// 当前显示的弹窗数量
    public var count: Int {
        return showingPopups.count
    }
        
    /// 清空所有显示的弹窗
    public func clear() {
        showingPopups.removeAll()
    }
    
    /// 查找指定ID的弹窗
    public func find(popupId: String) -> MBPopupTaskProtocol? {
        return showingPopups.first { $0.popupId == popupId }
    }
    
    /// 查找指定互斥组中正在展示的弹窗（同组内最多一个）
    /// - Parameter mutexGroup: 互斥组标识
    /// - Returns: 该组内正在展示的弹窗，若无则返回 nil
    public func findInMutexGroup(_ mutexGroup: String) -> MBPopupTaskProtocol? {
        return showingPopups.first { $0.mutexGroup == mutexGroup }
    }

    // MARK: - Suspend 状态管理

    /// 记录被 suspend 的弹窗（新弹窗 dismiss 时恢复）
    /// - Parameters:
    ///   - byPopupId: 新弹窗的 popupId（触发 suspend 的弹窗）
    ///   - suspended: 被暂停的弹窗
    public func addSuspended(by byPopupId: String, suspended: MBPopupTaskProtocol) {
        suspendedBy[byPopupId] = suspended
    }

    /// 取出并移除被 suspend 的弹窗
    /// - Parameter byPopupId:
    ///   - 优先按触发 suspend 的新弹窗 popupId 匹配（主路径）
    ///   - 若未命中，再按被暂停弹窗自身 popupId 匹配（补充分支）
    /// - Returns: 被暂停的弹窗，若无则返回 nil
    @discardableResult
    public func removeSuspended(by byPopupId: String) -> MBPopupTaskProtocol? {
        if let suspended = suspendedBy.removeValue(forKey: byPopupId) {
            return suspended
        }
        guard let matched = suspendedBy.first(where: { $0.value.popupId == byPopupId }) else {
            return nil
        }
        suspendedBy.removeValue(forKey: matched.key)
        return matched.value
    }
    
    /// 查找被 suspend 的弹窗（通过弹窗自己的 popupId）
    /// - Parameter popupId: 被暂停弹窗的 popupId
    /// - Returns: 被暂停的弹窗，若无则返回 nil
    public func findSuspended(popupId: String) -> MBPopupTaskProtocol? {
        return suspendedBy.values.first { $0.popupId == popupId }
    }
    
    // MARK: - Debug
    
    /// 调试信息
    public func debugInfo() -> [String: Any] {
        let popupsPayload: [[String: Any]] = showingPopups.enumerated().map { index, popup in
            [
                "index": index,
                "popupId": popup.popupId,
                "priority": popup.priority.rawValue,
                "scene": popup.scene.stringValue()
            ]
        }
        let suspendedPayload: [[String: Any]] = suspendedBy.map { byId, popup in
            [
                "byPopupId": byId,
                "suspendedPopupId": popup.popupId
            ]
        }
        return [
            "name": "MBPopupDisplayManager",
            "showingCount": showingPopups.count,
            "popups": popupsPayload,
            "suspendedCount": suspendedPayload.count,
            "suspended": suspendedPayload
        ]
    }
}

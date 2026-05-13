//
//  MBPopupManager.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 弹窗管理器
/// 职责：仅负责show/dismiss的时机控制（队列管理、冲突处理、优先级调度）
@objc(MBPopupManager)
@objcMembers
public class MBPopupManager: NSObject {
        
    // MARK: - Properties
    
    /// 容器视图控制器
    private weak var container: UIViewController?
    
    /// 队列管理器
    private let queue = MBPopupQueue()
    
    /// 显示管理器
    private let displayManager = MBPopupDisplayManager()
    
    // MARK: - Public Methods
    
    /// 展示弹窗
    public func show(_ popup: MBPopupTaskProtocol) {
        MBPopupExecuteOnMainQueue { [weak self] in
            self?.processShowByRule(popup)
        }
    }
    
    /// 关闭弹窗
    public func dismiss(popupId: String) {
        MBPopupExecuteOnMainQueue { [weak self] in
            self?.performDismiss(popupId)
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化弹窗管理器
    /// - Parameter container: 容器视图控制器
    public init(container: UIViewController) {
        self.container = container
        super.init()
        print("[MBPopupManager] init")
    }
    
    // MARK: - Private Methods
    
    /// 按规则处理弹窗
    ///
    /// ## 互斥组、优先级（黑白名单）
    /// - **执行顺序**：互斥组先 → 优先级（黑白名单）后
    /// - **依赖关系**：两者独立；互斥组命中则不走优先级
    /// - **互斥组**：同组只展示一个，按 mutexPolicy 决策
    /// - **优先级（黑白名单）**：展示顺序；叠加时由 coverRule 约束（click 跳过）
    ///
    /// - Parameter popup: 要处理的弹窗
    private func processShowByRule(_ popup: MBPopupTaskProtocol) {
        let popupId = popup.popupId
        // 1. 去重：若相同 popupId 已在展示、队列或挂起列表中，则忽略
        if displayManager.find(popupId: popupId) != nil {
            print("[MBPopupManager] deduplicate: popup already showing, skip, popup:\(popup)")
            return
        }
        if queue.find(popupId: popupId) != nil {
            print("[MBPopupManager] deduplicate: popup already in queue, skip, popup:\(popup)")
            return
        }
        if displayManager.findSuspended(popupId: popupId) != nil {
            print("[MBPopupManager] deduplicate: popup already suspended, skip, popup:\(popup)")
            return
        }
        // 2. 设置进入队列时间
        popup.entryTime = Date().timeIntervalSince1970
        
        // 3. 设置 close 闭包，确保在任何状态下都能调用
        popup.close = { [weak self] in
            MBPopupExecuteOnMainQueue { [weak self] in
                self?.performDismiss(popupId)
            }
        }
        
        // 4. 兜底开关，防止业务没正确调用移除方法，导致队列里面的弹窗出不来
        if MBPopupSceneConfigEnabled(scene: popup.scene) {
            print("[MBPopupManager] queue bypass by config, scene:\(popup.scene.stringValue()), popup:\(popup)")
            performShow(popup)
            return
        }
        
        // 5. 设置为等待状态
        popup.state = .waiting
        
        // 6. 如果没有显示的弹窗，直接显示
        if displayManager.isEmpty {
            performShow(popup)
            return
        }
        
        // 7. 互斥组：同组只展示一个，按 mutexPolicy 决策
        if let mutexGroup = popup.mutexGroup, mutexGroup.isEmpty == false,
           let currentInGroup = displayManager.findInMutexGroup(mutexGroup) {
            switch popup.mutexPolicy {
            case .none:
                print("[MBPopupManager] mutex none, \(popup)")
            case .reject:
                print("[MBPopupManager] mutex reject, \(popup)")
                return
            case .replace:
                print("[MBPopupManager] mutex replace, \(popup)")
                performDismiss(currentInGroup.popupId, thenShow: popup)
                return
            case .suspend:
                print("[MBPopupManager] mutex suspend, \(popup)")
                performSuspend(currentInGroup, thenShow: popup)
                return
            }
        }
        
        // 8. 优先级（黑白名单）：展示顺序 + 叠加约束
        // 8.1 click：直接叠加（click 优先级无视任何约束）
        if popup.priority == .click {
            performShow(popup)
            return
        }
        
        // 8.2 黑白名单：顶层 coverRule 决定能否叠加
        if let coverRule = displayManager.getTopPopup()?.coverRule {
            // 检查黑名单，在黑名单中，加入队列
            if coverRule.isBlacklisted(popup.scene) {
                print("[MBPopupManager] enqueue blacklisted, \(String(describing: popup))")
                queue.enqueue(popup)
                return
            }
            // 检查白名单，在白名单中，直接展示
            if coverRule.isWhitelisted(popup.scene) {
                performShow(popup)
                return
            }
        }
        
        // 8.3 force：叠加（顶层 coverRule 为 nil 或未命中白名单时，force 仍可叠加，但受黑名单约束）
        if popup.priority == .force {
            performShow(popup)
            return
        }
        
        // 8.4 普通优先级：顶层 coverRule 为 nil 或未命中白名单时，入队等待
        print("[MBPopupManager] enqueue normal, \(String(describing: popup))")
        queue.enqueue(popup)
    }
        
    /// 真正执行弹窗显示操作（设置时间、添加到显示列表、调用弹窗的show方法）
    /// - Parameter popup: 要显示的弹窗
    private func performShow(_ popup: MBPopupTaskProtocol) {
        // 0. 展示前拦截：业务方返回 true 则丢弃本次展示
        if popup.onShowIntercept?() == true {
            print("[MBPopupManager] show intercepted, discard popup, \(String(describing: popup))")
            popup.dismissTime = Date().timeIntervalSince1970
            popup.state = .closed
            processNextPopup()
            return
        }
        guard let container = container else {
            print("[MBPopupManager] show failed, container is nil, \(String(describing: popup))")
            return
        }
        print("[MBPopupManager] show popup, \(String(describing: popup))")
        // 1. 设置展示时间
        popup.showTime = Date().timeIntervalSince1970
        // 2. 设置状态为展示中
        popup.state = .showing
        // 3. 添加到显示列表
        displayManager.add(popup)
        // 4. 调用弹窗的show方法（view、动画、生命周期都由弹窗自己处理）
        popup.show(in: container) {
            
        }
    }
        
    /// 执行 suspend：暂停当前弹窗，展示新弹窗
    /// - Parameters:
    ///   - currentPopup: 当前展示的弹窗（将被暂停）
    ///   - nextPopup: 要展示的新弹窗
    ///
    /// - Note: 含超时保护。若 `pause(completion:)` 未在 3 秒内回调，超时后强制展示新弹窗，避免弹窗队列卡死。
    private func performSuspend(_ currentPopup: MBPopupTaskProtocol, thenShow nextPopup: MBPopupTaskProtocol) {
        currentPopup.state = .suspended
        displayManager.addSuspended(by: nextPopup.popupId, suspended: currentPopup)
        displayManager.remove(popupId: currentPopup.popupId)

        // 用数组作为可变引用容器（避免值类型闭包拷贝）
        var completed = [false]
        
        // 超时保护：3 秒后若 pause 仍未完成，强制展示新弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, !completed[0] else { return }
            completed[0] = true
            print("[MBPopupManager] pause timeout: \(currentPopup.popupId) -> \(nextPopup.popupId)")
            self.performShow(nextPopup)
        }
        
        // 暂停当前弹窗（completion 可能来自任意线程）
        currentPopup.pause { [weak self] in
            guard let self = self else { return }
            MBPopupExecuteOnMainQueue {
                guard !completed[0] else { return }
                completed[0] = true
                self.performShow(nextPopup)
            }
        }
    }

    /// 执行弹窗关闭操作（处理显示中、队列中、挂起中的弹窗）
    /// - Parameters:
    ///   - popupId: 弹窗唯一标识
    ///   - thenShow: 关闭完成后要展示的弹窗，nil 则走队列逻辑
    private func performDismiss(_ popupId: String, thenShow nextPopup: MBPopupTaskProtocol? = nil) {
        // 1. 检查是否在显示列表中
        if let popup = displayManager.find(popupId: popupId) {
            if popup.state == .closed {
                print("[MBPopupManager] dismiss popup already closed:\(popup)")
                return
            }
            print("[MBPopupManager] dismiss popup from display, \(String(describing: popup))")
            // 设置关闭时间
            popup.dismissTime = Date().timeIntervalSince1970
            // 设置状态为已关闭
            popup.state = .closed
            // 调用弹窗的dismiss方法（view、动画、生命周期都由弹窗自己处理）
            popup.dismiss { [weak self, weak popup] in
                guard let self = self, let popup = popup else { return }
                // 从显示列表移除
                self.displayManager.remove(popupId: popup.popupId)
                // 监控弹窗关闭
                MBPopupAPMTracker.trackPopupDismiss(popup: popup)
                // 若有被 suspend 的弹窗，恢复它；否则展示指定弹窗或检查队列
                if let suspended = self.displayManager.removeSuspended(by: popup.popupId) {
                    self.performResume(suspended)
                } else if let next = nextPopup {
                    self.performShow(next)
                } else {
                    self.processNextPopup()
                }
            }
            return
        }
        
        // 2. 检查是否在队列中
        if let popup = queue.find(popupId: popupId) {
            print("[MBPopupManager] remove popup from queue, popupId:\(popupId)")
            // 设置关闭时间和状态
            popup.dismissTime = Date().timeIntervalSince1970
            popup.state = .closed
            // 从队列移除
            queue.remove(popupId: popupId)
            // 监控弹窗关闭
            MBPopupAPMTracker.trackPopupDismiss(popup: popup)
            // 如果指定了下一个要展示的弹窗，展示它
            if let next = nextPopup {
                performShow(next)
            }
            return
        }
        
        // 3. 检查是否在挂起列表中
        if let suspended = displayManager.removeSuspended(by: popupId) {
            print("[MBPopupManager] remove popup from suspended, popup:\(suspended)")
            // 设置关闭时间和状态
            suspended.dismissTime = Date().timeIntervalSince1970
            suspended.state = .closed
            // 监控弹窗关闭
            MBPopupAPMTracker.trackPopupDismiss(popup: suspended)
            // 如果指定了下一个要展示的弹窗，展示它；否则检查队列
            if let next = nextPopup {
                performShow(next)
            } else {
                processNextPopup()
            }
            return
        }
        
        // 4. 未找到，记录日志
        print("[MBPopupManager] popup not found for dismiss, popupId:\(popupId)")
    }

    /// 恢复被 suspend 的弹窗
    /// - Parameter suspended: 被暂停的弹窗
    private func performResume(_ suspended: MBPopupTaskProtocol) {
        print("[MBPopupManager] resume popup, \(String(describing: suspended))")
        // 1. 更新展示时间（恢复也算重新展示）
        suspended.showTime = Date().timeIntervalSince1970
        // 2. 设置状态为展示中
        suspended.state = .showing
        // 3. 添加到显示列表
        displayManager.add(suspended)
        // 4. 调用弹窗的resume方法
        suspended.resume { }
    }
    
    /// 处理队列中的下一个弹窗
    ///
    /// ## 出队规则
    /// - **displayManager 为空**：队头直接出队展示
    /// - **click 优先级**：直接叠加，无视黑白名单
    /// - **force 优先级**：检查顶层黑名单，未命中则出队展示
    /// - **普通优先级**：检查顶层白名单，命中则出队展示；否则等待
    ///
    private func processNextPopup() {
        guard let nextPopup = queue.peek() else { return }
        
        // 1. 无弹窗展示时，队头直接出队
        if displayManager.isEmpty {
            queue.dequeue()
            performShow(nextPopup)
            return
        }
        
        // 2. 获取顶层弹窗的 coverRule
        guard let topPopup = displayManager.getTopPopup(), let coverRule = topPopup.coverRule else {
            // 顶层未配置 coverRule，普通弹窗不出队（保守策略）
            // force 优先级无 coverRule 约束，直接叠加
            if nextPopup.priority == .force {
                queue.dequeue()
                performShow(nextPopup)
            }
            return
        }
        
        // 3. force 优先级：检查黑名单
        if nextPopup.priority == .force {
            if coverRule.isBlacklisted(nextPopup.scene) {
                print("[MBPopupManager] dequeue blocked: force popup in blacklist, \(String(describing: nextPopup))")
                return
            }
            queue.dequeue()
            performShow(nextPopup)
            return
        }
        
        // 4. 普通优先级：检查白名单
        if coverRule.isWhitelisted(nextPopup.scene) {
            print("[MBPopupManager] dequeue allowed: normal popup in whitelist, \(String(describing: nextPopup))")
            queue.dequeue()
            performShow(nextPopup)
            return
        }
        
        // 5. 其他情况：普通弹窗不在白名单中，继续等待
        print("[MBPopupManager] dequeue blocked: normal popup not in whitelist, \(String(describing: nextPopup))")
    }
    
    deinit {
        // 监控弹窗泄漏
        let showingCount = displayManager.count
        let queueCount = queue.count
        MBPopupAPMTracker.trackPopupLeak(
            showingCount: showingCount,
            queueCount: queueCount,
            displayInfo: displayManager.debugInfo(),
            queueInfo: queue.debugInfo()
        )
        print("[MBPopupManager] deinit")
    }
}

//
//  MBPopupTask.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 弹窗基类，提供通用实现
/// 开发者可以继承此类快速创建弹窗，或直接遵循 MBPopupTaskProtocol 协议
@objc(MBPopupTask)
@objcMembers
public class MBPopupTask: NSObject, MBPopupTaskProtocol {
    
    // MARK: - Properties
    
    /// 弹窗唯一标识
    public let popupId: String
    
    /// 弹窗场景
    public let scene: MBPopupScene
    
    /// 优先级
    public var priority: MBPopupPriority = .normal
    
    /// 当前状态
    public var state: MBPopupState = .waiting
            
    /// 遮盖规则配置（控制后续弹窗能否叠加在本弹窗之上）
    /// - nil：允许 force 叠加，普通优先级入队等待
    /// - 非 nil：通过黑白名单精确控制可叠加的场景
    public var coverRule: MBPopupCoverRule?
    
    /// 互斥组标识，同组内仅展示一个弹窗，冲突时按 mutexPolicy 处理；nil 表示不参与互斥
    public var mutexGroup: String?
    
    /// 互斥组冲突时的处理策略；默认 .none 表示不参与互斥，走优先级策略
    public var mutexPolicy: MBPopupMutexPolicy = .none
    
    /// 关闭回调（由 Manager 注入，业务可调用此 block 主动关闭弹窗）
    public var close: (() -> Void)?
    
    /// 进入队列时间（Unix 时间戳，秒，由 Manager 赋值）
    public var entryTime: TimeInterval = 0
    
    /// 展示时间（Unix 时间戳，秒，由 Manager 赋值）
    public var showTime: TimeInterval = 0
    
    /// 关闭时间（Unix 时间戳，秒，由 Manager 赋值）
    public var dismissTime: TimeInterval = 0
    
    /// 在队列中的等待时长（秒）
    public var waitDuration: TimeInterval {
        if showTime > 0 && entryTime > 0 {
            return showTime - entryTime
        }
        if entryTime > 0 {
            return Date().timeIntervalSince1970 - entryTime
        }
        return 0
    }
    
    /// 展示时长（秒）
    public var showDuration: TimeInterval {
        if dismissTime > 0 && showTime > 0 {
            return dismissTime - showTime
        }
        if showTime > 0 {
            return Date().timeIntervalSince1970 - showTime
        }
        return 0
    }

    /// 描述信息
    public override var description: String {
        return "\(type(of: self))(popupId: \(popupId), scene: \(scene.stringValue()), priority: \(priority.rawValue),"
            + "mutexGroup: \(mutexGroup ?? ""), mutexPolicy: \(mutexPolicy.rawValue),"
            + "waitDuration: \(waitDuration), showDuration: \(showDuration)"
    }

    // MARK: - Initialization
    
    /// 初始化弹窗
    /// - Parameters:
    ///   - popupId: 弹窗唯一标识，为 nil 或空串时自动生成 UUID
    ///   - scene: 弹窗场景
    /// - Note: 子类必须使用此初始化方法，不能创建其他初始化方法
    required public init(
        popupId: String? = nil,
        scene: MBPopupScene
    ) {
        if let popupId = popupId, popupId.isEmpty == false  {
            self.popupId = popupId
        } else {
            self.popupId = UUID().uuidString
        }
        self.scene = scene
        super.init()
    }
    
    // MARK: - Show & Dismiss
    
    /// 展示弹窗（由Manager在合适时机调用）
    /// - Parameters:
    ///   - container: 容器视图控制器
    ///   - completion: 展示完成回调
    /// - Note: 子类必须重写此方法实现具体的展示逻辑
    public func show(in container: UIViewController, completion: @escaping () -> Void) {
        assertionFailure("⚠️ \(type(of: self)) 必须重写 show(in:completion:) 方法")
        completion()
    }
    
    /// 消失弹窗（由Manager在合适时机调用）
    /// - Parameter completion: 消失完成回调
    /// - Note: 子类必须重写此方法实现具体的消失逻辑
    public func dismiss(completion: @escaping () -> Void) {
        assertionFailure("⚠️ \(type(of: self)) 必须重写 dismiss(completion:) 方法")
        completion()
    }

    // MARK: - Pause & Resume (Suspend 策略)

    /// 暂停展示（默认空实现，支持 suspend 策略的子类需重写）
    public func pause(completion: @escaping () -> Void) {
        completion()
    }

    /// 恢复展示（默认空实现，支持 suspend 策略的子类需重写）
    public func resume(completion: @escaping () -> Void) {
        completion()
    }
}

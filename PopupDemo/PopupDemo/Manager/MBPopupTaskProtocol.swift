//
//  MBPopupTaskProtocol.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//
//  弹窗协议族：按职责拆分，支持灵活组合
//
//  协议关系：
//  - MBPopupIdentifiable: 标识信息（ID、场景、优先级）
//  - MBPopupPolicy: 策略配置（互斥组、遮盖规则）
//  - MBPopupPresentation: 展示行为（show、dismiss、pause、resume）
//  - MBPopupControllable: 控制能力（close 回调，业务可主动关闭）
//  - MBPopupStateful: 状态管理（state、时间信息）
//  - MBPopupTaskProtocol: 完整协议，组合所有子协议（向下兼容）
//

import UIKit

// MARK: - 1. 标识信息

/// 弹窗标识信息
/// 包含弹窗的基础标识：ID、场景、优先级
@objc(MBPopupIdentifiable)
public protocol MBPopupIdentifiable: NSObjectProtocol {
    /// 弹窗唯一标识
    var popupId: String { get }
    
    /// 弹窗场景
    var scene: MBPopupScene { get }
    
    /// 优先级（决定展示顺序、队列排序；click/force 可叠加）
    var priority: MBPopupPriority { get }
}

// MARK: - 2. 策略配置

/// 弹窗策略配置
/// 定义互斥组、遮盖规则等冲突处理策略
@objc(MBPopupPolicy)
public protocol MBPopupPolicy: MBPopupIdentifiable {
    /// 互斥组标识，同组内仅展示一个弹窗，冲突时按 mutexPolicy 处理
    /// - nil：不参与互斥，走优先级策略
    /// - 推荐使用 MBPopupMutexGroup 常量（如 MBPopupMutexGroup.lottery）；也支持 ActionLink 动态下发的字符串
    var mutexGroup: String? { get }
    
    /// 互斥组冲突时的处理策略；默认 .none 表示走优先级策略
    var mutexPolicy: MBPopupMutexPolicy { get }
    
    /// 遮盖规则（黑白名单），本弹窗为顶层时约束后续弹窗能否叠加
    var coverRule: MBPopupCoverRule? { get }
}

// MARK: - 3. 展示行为

/// 弹窗展示行为
/// 定义弹窗的显示、消失、暂停、恢复等生命周期方法
@objc(MBPopupPresentation)
public protocol MBPopupPresentation: NSObjectProtocol {
    /// 展示弹窗（由 Manager 调用）
    /// - Parameters:
    ///   - container: 容器视图控制器
    ///   - completion: 展示完成回调
    func show(in container: UIViewController, completion: @escaping () -> Void)
    
    /// 消失弹窗（由 Manager 调用）
    /// - Parameter completion: 消失完成回调
    func dismiss(completion: @escaping () -> Void)
    
    /// 暂停展示（由 Manager 调用）
    /// - Parameter completion: 暂停完成回调
    /// - Note: 用于互斥组 suspend 策略，需要实现才能支持该策略
    func pause(completion: @escaping () -> Void)
    
    /// 恢复展示（由 Manager 调用）
    /// - Parameter completion: 恢复完成回调
    /// - Note: 用于互斥组 suspend 策略，需要实现才能支持该策略
    func resume(completion: @escaping () -> Void)
}

// MARK: - 4. 控制能力

/// 弹窗控制能力
/// 提供给业务方的控制接口，可主动触发弹窗关闭
@objc(MBPopupControllable)
public protocol MBPopupControllable: NSObjectProtocol {
    /// 关闭回调（由 Manager 注入，业务可调用触发弹窗关闭）
    /// - Manager 会在弹窗加入队列时注入此回调
    /// - 业务方调用此 block 可主动关闭弹窗
    var close: (() -> Void)? { get set }
}

// MARK: - 5. 状态管理

/// 弹窗状态管理
/// Manager 内部使用，记录弹窗的状态和时间信息
@objc(MBPopupStateful)
public protocol MBPopupStateful: MBPopupIdentifiable {
    /// 当前状态
    var state: MBPopupState { get set }
    
    /// 进入队列时间（秒，由 Manager 赋值）
    var entryTime: TimeInterval { get set }
    
    /// 展示时间（秒，由 Manager 赋值）
    var showTime: TimeInterval { get set }
    
    /// 关闭时间（秒，由 Manager 赋值）
    var dismissTime: TimeInterval { get set }
    
    /// 在队列中的等待时长（秒，由实现方计算）
    var waitDuration: TimeInterval { get }
    
    /// 展示时长（秒，由实现方计算）
    var showDuration: TimeInterval { get }
}

// MARK: - 6. 完整协议

/// 完整弹窗任务协议
///
/// ## 处理顺序
/// 互斥组 → 优先级（黑白名单）。互斥组命中则不走优先级。
///
@objc(MBPopupTaskProtocol)
public protocol MBPopupTaskProtocol:
    MBPopupIdentifiable,
    MBPopupPolicy,
    MBPopupPresentation,
    MBPopupControllable,
    MBPopupStateful {
}

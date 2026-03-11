//
//  MBPopupBlockTask.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 基于闭包的弹窗任务类
/// 职责：通过闭包回调的方式处理弹窗的展示和消失逻辑
/// 适用于需要灵活自定义展示逻辑的场景
@objc(MBPopupBlockTask)
@objcMembers
public class MBPopupBlockTask: MBPopupTask {
    
    // MARK: - Properties
    
    /// 展示逻辑闭包
    /// 当弹窗需要展示时，Manager 会调用此闭包执行展示逻辑
    /// 调用方可以在此闭包中实现显示行为
    public var showBlock: (() -> Void)
    
    /// 消失回调闭包
    /// 当弹窗需要移除时，Manager 会调用此闭包执行移除逻辑
    /// 调用方可以在此闭包中实现移除行为
    public var dismissBlock: (() -> Void)?

    /// 暂停回调闭包（suspend 策略下，被新弹窗替换时调用）
    /// 业务可在此实现隐藏视图等逻辑，初始化后按需赋值
    public var pauseBlock: ((@escaping () -> Void) -> Void)?

    /// 恢复回调闭包（suspend 策略下，新弹窗 dismiss 后调用）
    /// 业务可在此实现重新显示视图等逻辑，初始化后按需赋值
    public var resumeBlock: ((@escaping () -> Void) -> Void)?

    // MARK: - Initialization

    /// 初始化弹窗
    /// - Parameters:
    ///   - popupId: 弹窗唯一标识，如果为 nil 则自动生成
    ///   - scene: 弹窗场景
    ///   - showBlock: 展示逻辑闭包，由调用方提供，用于控制弹窗的展示行为
    ///   - dismissBlock: 消失回调闭包
    public init(
        popupId: String? = nil,
        scene: MBPopupScene,
        showBlock: @escaping (() -> Void),
        dismissBlock: (() -> Void)? = nil
    ) {
        self.showBlock = showBlock
        self.dismissBlock = dismissBlock
        super.init(popupId: popupId, scene: scene)
    }
    
    required public init(popupId: String? = nil, scene: MBPopupScene) {
        fatalError("init(popupId:scene:) has not been implemented")
    }
    
    // MARK: - Show & Dismiss
    
    /// 展示弹窗（由Manager在合适时机调用）
    /// - Parameters:
    ///   - container: 容器视图控制器
    ///   - completion: 展示完成回调
    public override func show(in container: UIViewController, completion: @escaping () -> Void) {
        showBlock()
        completion()
    }
    
    /// 消失弹窗（由Manager在合适时机调用）
    /// - Parameter completion: 消失完成回调
    public override func dismiss(completion: @escaping () -> Void) {
        // 调用消失回调
        dismissBlock?()
        completion()
    }

    // MARK: - Pause & Resume (Suspend 策略)

    /// 暂停展示（调用 pauseBlock，业务自行实现隐藏逻辑）
    public override func pause(completion: @escaping () -> Void) {
        if let block = pauseBlock {
            block(completion)
        } else {
            completion()
        }
    }

    /// 恢复展示（调用 resumeBlock，业务自行实现显示逻辑）
    public override func resume(completion: @escaping () -> Void) {
        if let block = resumeBlock {
            block(completion)
        } else {
            completion()
        }
    }
}

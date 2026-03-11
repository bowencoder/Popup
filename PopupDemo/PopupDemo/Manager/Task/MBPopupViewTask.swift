//
//  MBPopupViewTask.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 基于 View 的弹窗任务类（继承自 MBPopupBaseViewTask）
/// 职责：管理自定义 UIView 的展示和消失
/// 适用于需要展示自定义 View 的弹窗场景
@objc(MBPopupViewTask)
@objcMembers
public class MBPopupViewTask: MBPopupBaseViewTask {
    
    // MARK: - Properties
    
    /// 弹窗内容视图
    private var _contentView: UIView
    
    /// 重写：返回内容视图
    public override var contentView: UIView? {
        return _contentView
    }

    // MARK: - Initialization
    
    /// 初始化弹窗（满足父类 required init 要求）
    /// - Parameters:
    ///   - popupId: 弹窗唯一标识，如果为 nil 则自动生成
    ///   - scene: 弹窗场景
    ///   - contentView: 弹窗视图，内部强引用
    /// - Note: 子类必须使用此初始化方法，不能创建其他初始化方法
    required public init(
        popupId: String? = nil,
        scene: MBPopupScene,
        contentView: UIView,
    ) {
        self._contentView = contentView
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
        onWillShow?()
        performShowAnimation(in: container) {
            self.onDidShow?()
            completion()
        }
    }
    
    /// 消失弹窗（由Manager在合适时机调用）
    /// - Parameter completion: 消失完成回调
    public override func dismiss(completion: @escaping () -> Void) {
        onWillDismiss?()
        performDismissAnimation {
            self.onDidDismiss?()
            completion()
        }
    }
    
    // MARK: - Animation Methods
    
    /// 执行展示动画
    /// - Parameters:
    ///   - container: 容器视图控制器
    ///   - completion: 动画完成回调
    open func performShowAnimation(in container: UIViewController, completion: @escaping () -> Void) {
        addRootView(to: container.view)
        addDimmingView()
        guard let rootView = rootView else {
            completion()
            return
        }
        _contentView.frame = MBPopupLayout.contentFrame(
            rootBounds: rootView.bounds,
            animationType: animationType,
            contentWidth: contentWidth,
            contentWidthRatio: contentWidthRatio,
            contentHeight: contentHeight,
            contentHeightRatio: contentHeightRatio
        )
        _contentView.autoresizingMask = MBPopupLayout.contentAutoresizingMask(animationType: animationType)
        rootView.addSubview(_contentView)
        animator.performShowAnimation(
            rootView: rootView,
            contentView: _contentView,
            dimmingView: dimmingView,
            animationType: animationType,
            animationDuration: animationDuration,
            completion: completion
        )
    }

    /// 执行消失动画
    /// - Parameter completion: 动画完成回调
    open func performDismissAnimation(completion: @escaping () -> Void) {
        guard let rootView = rootView else {
            completion()
            return
        }
        animator.performDismissAnimation(
            rootView: rootView,
            contentView: _contentView,
            dimmingView: dimmingView,
            animationType: animationType,
            animationDuration: animationDuration
        ) {
            self.cleanupViews(completion: completion)
        }
    }
}

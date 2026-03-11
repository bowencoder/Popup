//
//  MBPopupBaseViewTask.swift
//  Popup
//
//  Created by AI on 2026/02/06.
//  Copyright © 2026 bowen. All rights reserved.
//

import UIKit

/// 基于视图的弹窗基类（抽取 View/ViewController/RN Task 的公共实现）
/// 职责：rootView 管理、dimmingView、动画配置、生命周期回调、pause/resume
/// - Note: 子类需实现 `contentView` 计算属性，返回内容视图
@objc(MBPopupBaseViewTask)
@objcMembers
public class MBPopupBaseViewTask: MBPopupTask {
    
    // MARK: - Public Properties
    
    /// 生命周期回调
    public var onWillShow: (() -> Void)?
    public var onDidShow: (() -> Void)?
    public var onWillDismiss: (() -> Void)?
    public var onDidDismiss: (() -> Void)?
    
    /// 动画配置
    public var animationType: MBPopupAnimationType = .none
    public var animationDuration: TimeInterval = 0.25
    
    /// 遮罩背景色
    public var dimmingColor: UIColor?
    
    /// 内容视图尺寸配置
    public var contentWidth: CGFloat?
    public var contentWidthRatio: CGFloat = 1.0
    public var contentHeight: CGFloat?
    public var contentHeightRatio: CGFloat = 0.75
    
    // MARK: - Internal Properties
    
    /// 根视图容器（包含 dimmingView 和 contentView）
    internal var rootView: UIView?
    
    /// 遮罩视图（仅负责背景色）
    internal var dimmingView: UIView?
    
    /// 动画管理器
    internal let animator = MBPopupAnimator()
    
    /// 内容视图（子类需重写此计算属性）
    public var contentView: UIView? {
        assertionFailure("⚠️ \(type(of: self)) 必须重写 contentView 计算属性")
        return nil
    }
    
    // MARK: - Pause & Resume (Suspend 策略)
    
    /// 暂停展示（隐藏 rootView，不移除）
    public override func pause(completion: @escaping () -> Void) {
        rootView?.isHidden = true
        completion()
    }
    
    /// 恢复展示（重新显示 rootView）
    public override func resume(completion: @escaping () -> Void) {
        rootView?.isHidden = false
        completion()
    }
    
    // MARK: - Protected Methods (子类可调用)
    
    /// 创建并添加 rootView 到父视图
    /// - Parameter view: 父视图（如 container.view）
    internal func addRootView(to view: UIView) {
        let rootView = UIView()
        rootView.frame = view.bounds
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        rootView.backgroundColor = .clear
        rootView.isUserInteractionEnabled = true
        rootView.accessibilityIdentifier = "MBPopupRootView_\(scene.stringValue())"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRootViewTap(_:)))
        rootView.addGestureRecognizer(tapGesture)
        view.addSubview(rootView)
        self.rootView = rootView
    }
    
    /// 添加遮罩视图（仅负责背景色，不处理点击事件）
    internal func addDimmingView() {
        guard let rootView = rootView, dimmingColor != nil else { return }
        let view = UIView()
        view.frame = rootView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = dimmingColor ?? UIColor.black.withAlphaComponent(0.3)
        view.accessibilityIdentifier = "MBPopupDimmingView_\(scene.stringValue())"
        view.isUserInteractionEnabled = false
        rootView.addSubview(view)
        self.dimmingView = view
    }
    
    /// 处理 rootView 点击（点击背景区域关闭弹窗）
    @objc private func handleRootViewTap(_ gesture: UITapGestureRecognizer) {
        guard let rootView = rootView, let contentView = contentView else { return }
        let location = gesture.location(in: rootView)
        if !contentView.frame.contains(location) {
            close?()
        }
    }
    
    /// 清理视图（移除 rootView）
    /// - Parameter completion: 清理完成回调
    internal func cleanupViews(completion: @escaping () -> Void) {
        rootView?.removeFromSuperview()
        rootView = nil
        dimmingView = nil
        completion()
    }
}

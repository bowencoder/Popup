//
//  MBPopupViewControllerTask.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 以 UIViewController 为内容的弹窗任务类（继承自 MBPopupBaseViewTask）
/// 职责：将传入的 ViewController 作为子 VC 展示，管理完整 VC 生命周期
/// 适用于需要完整 VC 生命周期的弹窗场景
@objc(MBPopupViewControllerTask)
@objcMembers
public class MBPopupViewControllerTask: MBPopupBaseViewTask {

    // MARK: - Properties

    /// 弹窗内容视图控制器
    private var contentViewController: UIViewController
    
    /// 重写：返回 ViewController 的 view
    public override var contentView: UIView? {
        return contentViewController.view
    }

    // MARK: - Initialization

    /// 初始化弹窗
    /// - Parameters:
    ///   - popupId: 弹窗唯一标识，如果为 nil 则自动生成
    ///   - scene: 弹窗场景
    ///   - contentViewController: 弹窗内容视图控制器，内部强引用
    required public init(
        popupId: String? = nil,
        scene: MBPopupScene,
        contentViewController: UIViewController
    ) {
        self.contentViewController = contentViewController
        super.init(popupId: popupId, scene: scene)
    }

    required public init(popupId: String? = nil, scene: MBPopupScene) {
        fatalError("init(popupId:scene:) has not been implemented")
    }

    // MARK: - Show & Dismiss

    /// 展示弹窗（由 Manager 在合适时机调用）
    public override func show(in container: UIViewController, completion: @escaping () -> Void) {
        onWillShow?()
        performShowAnimation(in: container) {
            self.onDidShow?()
            completion()
        }
    }

    /// 消失弹窗（由 Manager 在合适时机调用）
    public override func dismiss(completion: @escaping () -> Void) {
        onWillDismiss?()
        performDismissAnimation {
            self.onDidDismiss?()
            completion()
        }
    }

    // MARK: - Animation Methods

    /// 执行展示动画
    open func performShowAnimation(in container: UIViewController, completion: @escaping () -> Void) {
        addRootView(to: container.view)
        addDimmingView()

        guard let rootView = rootView else {
            completion()
            return
        }

        // ViewController 生命周期管理
        container.addChild(contentViewController)
        rootView.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: container)

        contentViewController.view.frame = MBPopupLayout.contentFrame(
            rootBounds: rootView.bounds,
            animationType: animationType,
            contentWidth: contentWidth,
            contentWidthRatio: contentWidthRatio,
            contentHeight: contentHeight,
            contentHeightRatio: contentHeightRatio
        )
        contentViewController.view.autoresizingMask = MBPopupLayout.contentAutoresizingMask(animationType: animationType)

        animator.performShowAnimation(
            rootView: rootView,
            contentView: contentViewController.view,
            dimmingView: dimmingView,
            animationType: animationType,
            animationDuration: animationDuration,
            completion: completion
        )
    }

    /// 执行消失动画
    open func performDismissAnimation(completion: @escaping () -> Void) {
        guard let rootView = rootView else {
            completion()
            return
        }

        animator.performDismissAnimation(
            rootView: rootView,
            contentView: contentViewController.view,
            dimmingView: dimmingView,
            animationType: animationType,
            animationDuration: animationDuration
        ) { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            // ViewController 生命周期管理
            self.contentViewController.willMove(toParent: nil)
            self.contentViewController.view.removeFromSuperview()
            self.contentViewController.removeFromParent()
            // 清理视图
            self.cleanupViews(completion: completion)
        }
    }
}

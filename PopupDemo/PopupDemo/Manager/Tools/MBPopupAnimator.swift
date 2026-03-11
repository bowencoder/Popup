//
//  MBPopupAnimator.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 弹窗动画管理器
/// 职责：负责所有弹窗的动画执行
@objc(MBPopupAnimator)
@objcMembers
class MBPopupAnimator: NSObject {
    
    // MARK: - Public Methods
    
    /// 执行展示动画
    /// - Parameters:
    ///   - rootView: 根视图容器
    ///   - contentView: 弹窗视图
    ///   - dimmingView: 遮罩视图（可选，仅负责背景色）
    ///   - animationType: 动画类型
    ///   - animationDuration: 动画时长
    ///   - completion: 动画完成回调
    func performShowAnimation(
        rootView: UIView?,
        contentView: UIView,
        dimmingView: UIView?,
        animationType: MBPopupAnimationType,
        animationDuration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        guard let rootView = rootView else { return completion() }
        switch animationType {
        case .none:
            showNoAnimation(completion: completion)
        case .fade:
            showFadeAnimation(rootView: rootView, duration: animationDuration, completion: completion)
        case .bottomSheet:
            showBottomSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        case .topSheet:
            showTopSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        case .centerSheet:
            showCenterSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        }
    }
    
    /// 执行消失动画
    /// - Parameters:
    ///   - rootView: 根视图容器（动画完成后由调用方移除）
    ///   - contentView: 弹窗视图
    ///   - dimmingView: 遮罩视图（可选）
    ///   - animationType: 动画类型
    ///   - animationDuration: 动画时长
    ///   - completion: 动画完成回调（调用方在此回调中移除 rootView）
    func performDismissAnimation(
        rootView: UIView?,
        contentView: UIView,
        dimmingView: UIView?,
        animationType: MBPopupAnimationType,
        animationDuration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        guard let rootView = rootView else { return completion() }
        switch animationType {
        case .none:
            dismissNoAnimation(completion: completion)
        case .fade:
            dismissFadeAnimation(rootView: rootView, duration: animationDuration, completion: completion)
        case .bottomSheet:
            dismissBottomSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        case .topSheet:
            dismissTopSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        case .centerSheet:
            dismissCenterSheetAnimation(rootView: rootView, contentView: contentView, dimmingView: dimmingView, duration: animationDuration, completion: completion)
        }
    }
    
    // MARK: - No Animation
    
    private func showNoAnimation( completion: @escaping () -> Void) {
        completion()
    }
    
    private func dismissNoAnimation(completion: @escaping () -> Void) {
        completion()
    }
    
    // MARK: - Fade Animation
    
    private func showFadeAnimation(
        rootView: UIView,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        // 设置初始透明度
        rootView.alpha = 0
        UIView.animate(
            withDuration: duration,
            animations: {
                rootView.alpha = 1
            },
            completion: { _ in
                completion()
            }
        )
    }
    
    private func dismissFadeAnimation(
        rootView: UIView,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: duration,
            animations: {
                rootView.alpha = 0
            },
            completion: { _ in
                completion()
            }
        )
    }
    
    // MARK: - BottomSheet Animation
    
    private func showBottomSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        // 保存目标 frame
        let originalFrame = contentView.frame
        contentView.frame.origin.y = rootView.bounds.height
        // 设置初始状态（rootView 已由 ViewTask 添加）
        dimmingView?.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                contentView.frame = originalFrame
                dimmingView?.alpha = 1
            },
            completion: { _ in
                completion()
            }
        )
    }
    
    private func dismissBottomSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                contentView.frame.origin.y = rootView.bounds.height
                dimmingView?.alpha = 0
            },
            completion: { _ in
                completion()
            }
        )
    }

    // MARK: - TopSheet Animation

    private func showTopSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        let originalFrame = contentView.frame
        contentView.frame.origin.y = -contentView.frame.height
        dimmingView?.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                contentView.frame = originalFrame
                dimmingView?.alpha = 1
            },
            completion: { _ in
                completion()
            }
        )
    }

    private func dismissTopSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                contentView.frame.origin.y = -contentView.frame.height
                dimmingView?.alpha = 0
            },
            completion: { _ in
                completion()
            }
        )
    }

    // MARK: - CenterSheet Animation

    private func showCenterSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        contentView.alpha = 0
        dimmingView?.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                contentView.transform = .identity
                contentView.alpha = 1
                dimmingView?.alpha = 1
            },
            completion: { _ in
                completion()
            }
        )
    }

    private func dismissCenterSheetAnimation(
        rootView: UIView,
        contentView: UIView,
        dimmingView: UIView?,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                contentView.alpha = 0
                dimmingView?.alpha = 0
            },
            completion: { _ in
                completion()
            }
        )
    }
}

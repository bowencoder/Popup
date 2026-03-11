//
//  MBPopupLayout.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import UIKit

/// 弹窗内容布局工具类
/// 职责：根据 animationType、contentWidth/Height 计算内容 frame 与 autoresizingMask，供 ViewTask / ViewControllerTask / ReactNativeTask 共用
@objc(MBPopupLayout)
@objcMembers
public class MBPopupLayout: NSObject {

    /// 根据动画类型与尺寸参数计算内容 frame
    /// 位置由动画类型决定：bottomSheet=下，topSheet=上，centerSheet=中，none/fade=全屏
    /// - Parameters:
    ///   - rootBounds: 根视图容器的 bounds（通常为 rootView.bounds）
    ///   - animationType: 动画类型
    ///   - contentWidth: 内容宽度（nil 则用 contentWidthRatio）
    ///   - contentWidthRatio: 宽度比 0–1
    ///   - contentHeight: 内容高度（nil 则用 contentHeightRatio）
    ///   - contentHeightRatio: 高度比 0–1
    /// - Returns: 内容视图的 frame
    public static func contentFrame(
        rootBounds: CGRect,
        animationType: MBPopupAnimationType,
        contentWidth: CGFloat?,
        contentWidthRatio: CGFloat,
        contentHeight: CGFloat?,
        contentHeightRatio: CGFloat
    ) -> CGRect {
        let containerWidth = rootBounds.width
        let containerHeight = rootBounds.height
        switch animationType {
        case .none, .fade:
            return rootBounds
        case .bottomSheet, .topSheet, .centerSheet:
            var targetWidth = containerWidth * contentWidthRatio
            if let w = contentWidth, w > 0 {
                targetWidth = min(w, containerWidth)
            }
            var targetHeight = containerHeight * contentHeightRatio
            if let h = contentHeight, h > 0 {
                targetHeight = min(h, containerHeight)
            }
            let x = (containerWidth - targetWidth) / 2
            let y: CGFloat
            switch animationType {
            case .topSheet:
                y = 0
            case .centerSheet:
                y = (containerHeight - targetHeight) / 2
            case .bottomSheet:
                y = containerHeight - targetHeight
            default:
                y = containerHeight - targetHeight
            }
            return CGRect(x: x, y: y, width: targetWidth, height: targetHeight)
        }
    }

    /// 根据动画类型返回合适的 autoresizingMask
    /// - Parameter animationType: 动画类型
    /// - Returns: 内容视图的 autoresizingMask
    public static func contentAutoresizingMask(animationType: MBPopupAnimationType) -> UIView.AutoresizingMask {
        switch animationType {
        case .none, .fade:
            return [.flexibleWidth, .flexibleHeight]
        case .topSheet:
            return [.flexibleWidth, .flexibleBottomMargin]
        case .centerSheet:
            return [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        case .bottomSheet:
            return [.flexibleWidth, .flexibleTopMargin]
        }
    }
}

//
//  ViewController.swift
//  PopupDemo
//
//  Created by bowen on 2026/3/11.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var popupManager = MBPopupManager(container: self)
    private var knownPopupIds = Set<String>()
    private var stableDedupId = "demo_dedup_id"
    private var queuedPopupId: String?
    
    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.alignment = .fill
        v.distribution = .fill
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MBPopup Demo Cases"
        view.backgroundColor = .systemBackground
        setupUI()
        setupCases()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupCases() {
        addCaseButton("Case 01 - Normal View Popup") { [weak self] in
            self?.showBasicPopup(scene: .coupon, title: "Normal", color: .systemBlue)
        }
        
        addCaseButton("Case 02 - Priority Queue (low/high/normal)") { [weak self] in
            self?.runPriorityQueueCase()
        }
        
        addCaseButton("Case 03 - Force Overlay") { [weak self] in
            self?.runForceCase()
        }
        
        addCaseButton("Case 04 - Click Overlay") { [weak self] in
            self?.runClickCase()
        }
        
        addCaseButton("Case 05 - Mutex Reject") { [weak self] in
            self?.runMutexCase(policy: .reject, label: "Reject")
        }
        
        addCaseButton("Case 06 - Mutex Replace") { [weak self] in
            self?.runMutexCase(policy: .replace, label: "Replace")
        }
        
        addCaseButton("Case 07 - Mutex Suspend/Resume") { [weak self] in
            self?.runMutexCase(policy: .suspend, label: "Suspend")
        }
        
        addCaseButton("Case 08 - CoverRule Blacklist Queue") { [weak self] in
            self?.runCoverRuleBlacklistCase()
        }
        
        addCaseButton("Case 09 - CoverRule Whitelist Allow") { [weak self] in
            self?.runCoverRuleWhitelistCase()
        }
        
        addCaseButton("Case 10 - ViewController Task") { [weak self] in
            self?.runViewControllerTaskCase()
        }
        
        addCaseButton("Case 11 - Deduplicate by popupId") { [weak self] in
            self?.runDeduplicateCase()
        }
        
        addCaseButton("Case 12 - Dismiss Queued Popup") { [weak self] in
            self?.runDismissQueuedPopupCase()
        }
        
        addCaseButton("Dismiss All Known Popups") { [weak self] in
            self?.dismissAllKnownPopups()
        }
    }
    
    private func addCaseButton(_ title: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.numberOfLines = 2
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
    
    private func showBasicPopup(
        popupId: String? = nil,
        scene: MBPopupScene,
        title: String,
        color: UIColor,
        priority: MBPopupPriority = .normal,
        autoDismissAfter: TimeInterval? = nil
    ) {
        let id = popupId ?? "demo_\(scene.stringValue())_\(UUID().uuidString.prefix(6))"
        let contentView = makeContentView(title: title, message: "scene: \(scene.stringValue())", color: color)
        var taskRef: MBPopupViewTask?
        let closeButton = makeCloseButton {
            taskRef?.close?()
        }
        contentView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
        
        let task = MBPopupViewTask(popupId: id, scene: scene, contentView: contentView)
        taskRef = task
        task.priority = priority
        task.animationType = .centerSheet
        task.dimmingColor = UIColor.black.withAlphaComponent(0.25)
        task.contentWidthRatio = 0.86
        task.contentHeight = 220
        knownPopupIds.insert(id)
        popupManager.show(task)
        
        if let delay = autoDismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.popupManager.dismiss(popupId: id)
            }
        }
    }
    
    private func runPriorityQueueCase() {
        showBasicPopup(
            popupId: "case_priority_anchor",
            scene: .coupon,
            title: "Anchor Popup",
            color: .systemGray,
            priority: .normal,
            autoDismissAfter: 3
        )
        showBasicPopup(popupId: "case_priority_low", scene: .shoppingBag, title: "Low", color: .systemGreen, priority: .low)
        showBasicPopup(popupId: "case_priority_high", scene: .shoppingRedPacket, title: "High", color: .systemRed, priority: .high)
        showBasicPopup(popupId: "case_priority_normal", scene: .coupon, title: "Normal", color: .systemBlue, priority: .normal)
    }
    
    private func runForceCase() {
        showBasicPopup(scene: .coupon, title: "Bottom Normal", color: .systemBlue, priority: .normal)
        showBasicPopup(scene: .shoppingRedPacket, title: "Force Overlay", color: .systemOrange, priority: .force)
    }
    
    private func runClickCase() {
        showBasicPopup(scene: .shoppingBag, title: "Bottom Normal", color: .systemTeal, priority: .normal)
        showBasicPopup(scene: .coupon, title: "Click Overlay", color: .systemPink, priority: .click)
    }
    
    private func runMutexCase(policy: MBPopupMutexPolicy, label: String) {
        let first = MBPopupViewTask(
            popupId: "case_mutex_first_\(policy.rawValue)",
            scene: .coupon,
            contentView: makeContentView(title: "Mutex First", message: "policy: \(label)", color: .systemIndigo)
        )
        first.mutexGroup = MBPopupMutexGroup.lottery
        first.mutexPolicy = .none
        first.animationType = .centerSheet
        first.dimmingColor = UIColor.black.withAlphaComponent(0.2)
        first.contentWidthRatio = 0.84
        first.contentHeight = 200
        
        let second = MBPopupViewTask(
            popupId: "case_mutex_second_\(policy.rawValue)",
            scene: .shoppingRedPacket,
            contentView: makeContentView(title: "Mutex Second", message: "policy: \(label)", color: .systemPurple)
        )
        second.mutexGroup = MBPopupMutexGroup.lottery
        second.mutexPolicy = policy
        second.animationType = .centerSheet
        second.dimmingColor = UIColor.black.withAlphaComponent(0.2)
        second.contentWidthRatio = 0.84
        second.contentHeight = 200
        
        knownPopupIds.insert(first.popupId)
        knownPopupIds.insert(second.popupId)
        popupManager.show(first)
        popupManager.show(second)
    }
    
    private func runCoverRuleBlacklistCase() {
        let blocker = MBPopupViewTask(
            popupId: "case_blacklist_blocker",
            scene: .shoppingBag,
            contentView: makeContentView(title: "Top Blacklist Blocker", message: "blacklist coupon", color: .brown)
        )
        blocker.coverRule = MBPopupCoverRule(blacklistScenes: [.coupon])
        blocker.animationType = .centerSheet
        blocker.contentWidthRatio = 0.86
        blocker.contentHeight = 210
        
        let blocked = MBPopupViewTask(
            popupId: "case_blacklist_target",
            scene: .coupon,
            contentView: makeContentView(title: "Should Queue", message: "blocked by blacklist", color: .systemRed)
        )
        
        knownPopupIds.insert(blocker.popupId)
        knownPopupIds.insert(blocked.popupId)
        popupManager.show(blocker)
        popupManager.show(blocked)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.popupManager.dismiss(popupId: blocker.popupId)
        }
    }
    
    private func runCoverRuleWhitelistCase() {
        let top = MBPopupViewTask(
            popupId: "case_whitelist_top",
            scene: .shoppingBag,
            contentView: makeContentView(title: "Top Whitelist", message: "whitelist coupon", color: .darkGray)
        )
        top.coverRule = MBPopupCoverRule(whitelistScenes: [.coupon])
        top.animationType = .centerSheet
        top.contentWidthRatio = 0.86
        top.contentHeight = 210
        
        let allowed = MBPopupViewTask(
            popupId: "case_whitelist_allowed",
            scene: .coupon,
            contentView: makeContentView(title: "Allowed Directly", message: "in whitelist", color: .systemGreen)
        )
        
        knownPopupIds.insert(top.popupId)
        knownPopupIds.insert(allowed.popupId)
        popupManager.show(top)
        popupManager.show(allowed)
    }
    
    private func runViewControllerTaskCase() {
        let vc = DemoPopupContentViewController(
            titleText: "VC Popup",
            messageText: "MBPopupViewControllerTask"
        )
        let popupId = "case_vc_task"
        vc.onClose = { [weak self] in
            self?.popupManager.dismiss(popupId: popupId)
        }
        
        let task = MBPopupViewControllerTask(
            popupId: popupId,
            scene: .shoppingRedPacket,
            contentViewController: vc
        )
        task.animationType = .bottomSheet
        task.contentWidthRatio = 1.0
        task.contentHeight = 300
        task.dimmingColor = UIColor.black.withAlphaComponent(0.2)
        knownPopupIds.insert(task.popupId)
        popupManager.show(task)
    }
    
    private func runDeduplicateCase() {
        showBasicPopup(
            popupId: stableDedupId,
            scene: .coupon,
            title: "Dedup First",
            color: .systemBlue
        )
        showBasicPopup(
            popupId: stableDedupId,
            scene: .coupon,
            title: "Dedup Second (should be skipped)",
            color: .systemOrange
        )
    }
    
    private func runDismissQueuedPopupCase() {
        let blockerId = "case_queue_blocker"
        let queuedId = "case_queue_to_remove"
        
        showBasicPopup(
            popupId: blockerId,
            scene: .shoppingBag,
            title: "Blocker",
            color: .systemGray,
            priority: .normal,
            autoDismissAfter: 4
        )
        showBasicPopup(
            popupId: queuedId,
            scene: .coupon,
            title: "Queued Then Removed",
            color: .systemMint,
            priority: .normal
        )
        queuedPopupId = queuedId
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, let id = self.queuedPopupId else { return }
            self.popupManager.dismiss(popupId: id)
            self.queuedPopupId = nil
        }
    }
    
    private func dismissAllKnownPopups() {
        for id in knownPopupIds {
            popupManager.dismiss(popupId: id)
        }
    }
    
    private func makeContentView(title: String, message: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        messageLabel.numberOfLines = 0
        
        let hintLabel = UILabel()
        hintLabel.text = "Tap outside to close"
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, hintLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 8
        card.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    private func makeCloseButton(action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 13)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}

private final class DemoPopupContentViewController: UIViewController {
    let titleText: String
    let messageText: String
    var onClose: (() -> Void)?
    
    init(titleText: String, messageText: String) {
        self.titleText = titleText
        self.messageText = messageText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPurple
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        
        let messageLabel = UILabel()
        messageLabel.text = messageText
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Dismiss VC Popup", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 10
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        closeButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, closeButton])
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }
}


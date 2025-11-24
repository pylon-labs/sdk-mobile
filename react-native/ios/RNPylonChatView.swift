//
//  RNPylonChatView.swift
//  RNPylonChat
//
//  Wrapper around PylonChatView for React Native
//

import Foundation
import UIKit
import React
import WebKit

// Import PylonChat from parent directory
// Note: PylonChat files will be added to Xcode project from ../../ios/PylonChat/

class RNPylonChatView: UIView {
    
    private var pylonChatView: PylonChatView?
    private var config: PylonConfig?
    private var user: PylonUser?
    
    // Config properties
    @objc var appId: NSString = "" {
        didSet { updateConfig() }
    }
    
    @objc var widgetBaseUrl: NSString? {
        didSet { updateConfig() }
    }
    
    @objc var widgetScriptUrl: NSString? {
        didSet { updateConfig() }
    }
    
    @objc var enableLogging: Bool = true {
        didSet { updateConfig() }
    }
    
    @objc var debugMode: Bool = false {
        didSet { updateConfig() }
    }
    
    @objc var primaryColor: NSString? {
        didSet { updateConfig() }
    }
    
    // User properties
    @objc var userEmail: NSString? {
        didSet { updateUser() }
    }
    
    @objc var userName: NSString? {
        didSet { updateUser() }
    }
    
    @objc var userAvatarUrl: NSString? {
        didSet { updateUser() }
    }
    
    @objc var userEmailHash: NSString? {
        didSet { updateUser() }
    }
    
    @objc var userAccountId: NSString? {
        didSet { updateUser() }
    }
    
    @objc var userAccountExternalId: NSString? {
        didSet { updateUser() }
    }
    
    // Safe area top inset for coordinate space adjustment
    @objc var topInset: NSNumber = 0 {
        didSet {
            if let pylonView = pylonChatView {
                pylonView.topInset = CGFloat(truncating: topInset)
            }
        }
    }
    
    // Event callbacks - renamed to avoid collision with PylonChatListener methods
    @objc var rctOnPylonLoaded: RCTBubblingEventBlock?
    @objc var rctOnPylonInitialized: RCTBubblingEventBlock?
    @objc var rctOnPylonReady: RCTBubblingEventBlock?
    @objc var rctOnChatOpened: RCTBubblingEventBlock?
    @objc var rctOnChatClosed: RCTBubblingEventBlock?
    @objc var rctOnUnreadCountChanged: RCTBubblingEventBlock?
    @objc var rctOnMessageReceived: RCTBubblingEventBlock?
    @objc var rctOnPylonError: RCTBubblingEventBlock?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
    
    // Override pointInside to make React Native call hitTest
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Always return true so React Native will call hitTest
        // The actual hit detection happens in hitTest
        return true
    }
    
    // Forward hit testing to the embedded PylonChatView
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If we have a PylonChatView, let it handle hit testing
        if let pylonView = pylonChatView {
            // Convert point to pylonView's coordinate space
            let convertedPoint = convert(point, to: pylonView)
            return pylonView.hitTest(convertedPoint, with: event)
        }
        
        // If no PylonChatView yet, pass through (return nil)
        return nil
    }
    
    private func updateConfig() {
        guard (appId as String).isEmpty == false else { return }
        
        config = PylonConfig(
            appId: appId as String,
            enableLogging: enableLogging,
            primaryColor: primaryColor as String?,
            debugMode: debugMode,
            widgetBaseUrl: widgetBaseUrl as String?,
            widgetScriptUrl: widgetScriptUrl as String?
        )
        
        recreatePylonView()
    }
    
    private func updateUser() {
        guard let email = userEmail as String?,
              let name = userName as String? else { return }
        
        user = PylonUser(
            email: email,
            name: name,
            avatarUrl: userAvatarUrl as String?,
            emailHash: userEmailHash as String?,
            accountId: userAccountId as String?,
            accountExternalId: userAccountExternalId as String?
        )
        
        recreatePylonView()
    }
    
    private func recreatePylonView() {
        guard let config = config, let user = user else { return }
        
        // Remove old view
        pylonChatView?.removeFromSuperview()
        
        // Create new PylonChatView
        let newView = PylonChatView(config: config, user: user)
        newView.listener = self
        newView.topInset = CGFloat(truncating: topInset)
        newView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(newView)
        
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: topAnchor),
            newView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        pylonChatView = newView
        
        // Force layout
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // Imperative methods (called from React Native)
    func openChat() {
        pylonChatView?.openChat()
    }
    
    func closeChat() {
        pylonChatView?.closeChat()
    }
    
    func showChatBubble() {
        pylonChatView?.showChatBubble()
    }
    
    func hideChatBubble() {
        pylonChatView?.hideChatBubble()
    }
    
    func showNewMessage(_ message: String, isHtml: Bool) {
        pylonChatView?.showNewMessage(message, isHtml: isHtml)
    }
    
    func setNewIssueCustomFields(_ fields: [String: Any]) {
        pylonChatView?.setNewIssueCustomFields(fields)
    }
    
    func setTicketFormFields(_ fields: [String: Any]) {
        pylonChatView?.setTicketFormFields(fields)
    }
    
    func updateEmailHash(_ emailHash: String?) {
        pylonChatView?.updateEmailHash(emailHash)
    }
    
    func showTicketForm(_ slug: String) {
        pylonChatView?.showTicketForm(slug)
    }
    
    func showKnowledgeBaseArticle(_ articleId: String) {
        pylonChatView?.showKnowledgeBaseArticle(articleId)
    }
}

// MARK: - PylonChatListener
extension RNPylonChatView: PylonChatListener {
    func onPylonLoaded() {
        rctOnPylonLoaded?([:])
    }
    
    func onPylonInitialized() {
        rctOnPylonInitialized?([:])
    }
    
    func onPylonReady() {
        rctOnPylonReady?([:])
    }
    
    func onMessageReceived(message: String) {
        rctOnMessageReceived?(["message": message])
    }
    
    func onChatOpened() {
        rctOnChatOpened?([:])
    }
    
    func onChatClosed(wasOpen: Bool) {
        rctOnChatClosed?(["wasOpen": wasOpen])
    }
    
    func onPylonError(error: String) {
        rctOnPylonError?(["error": error])
    }
    
    func onUnreadCountChanged(count: Int) {
        rctOnUnreadCountChanged?(["count": count])
    }
}

// MARK: - Imperative method helpers
extension RNPylonChatViewManager {
    @objc func openChat(_ reactTag: NSNumber) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.openChat()
        }
    }
    
    @objc func closeChat(_ reactTag: NSNumber) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.closeChat()
        }
    }
    
    @objc func showChatBubble(_ reactTag: NSNumber) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.showChatBubble()
        }
    }
    
    @objc func hideChatBubble(_ reactTag: NSNumber) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.hideChatBubble()
        }
    }
    
    @objc func showNewMessage(_ reactTag: NSNumber, message: NSString, isHtml: Bool) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.showNewMessage(message as String, isHtml: isHtml)
        }
    }
    
    @objc func setNewIssueCustomFields(_ reactTag: NSNumber, fields: NSDictionary) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.setNewIssueCustomFields(fields as! [String: Any])
        }
    }
    
    @objc func setTicketFormFields(_ reactTag: NSNumber, fields: NSDictionary) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.setTicketFormFields(fields as! [String: Any])
        }
    }
    
    @objc func updateEmailHash(_ reactTag: NSNumber, emailHash: NSString?) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.updateEmailHash(emailHash as String?)
        }
    }
    
    @objc func showTicketForm(_ reactTag: NSNumber, slug: NSString) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.showTicketForm(slug as String)
        }
    }
    
    @objc func showKnowledgeBaseArticle(_ reactTag: NSNumber, articleId: NSString) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? RNPylonChatView else { return }
            view.showKnowledgeBaseArticle(articleId as String)
        }
    }
}

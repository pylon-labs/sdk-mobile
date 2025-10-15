package com.example.probe

/**
 * Listener interface for Probe widget events
 */
interface PylonChatListener {
    /**
     * Called when the Probe widget has finished loading
     */
    fun onProbeLoaded()

    /**
     * Called when Probe is initialized with user data
     */
    fun onProbeInitialized()

    /**
     * Called when Probe JavaScript is ready
     */
    fun onProbeReady()

    /**
     * Called when a message is received
     */
    fun onMessageReceived(message: String)

    /**
     * Called when the chat is opened
     */
    fun onChatOpened()

    /**
     * Called when the chat is closed
     */
    fun onChatClosed()

    /**
     * Called when there's an error loading Probe
     */
    fun onProbeError(error: String)

    /**
     * Called when a file chooser is launched.
     * This is only called when ProbeWidget is used from a non-Activity context.
     *
     * Developers can simply forward activity results to [Pylon.handleActivityResult]
     * and ignore request codes altogether. The provided request code is only kept
     * for backwards compatibility.
     *
     * @param requestCode The legacy request code identifier.
     */
    fun onFileChooserLaunched(requestCode: Int) {
        // Default implementation - can be overridden if needed
    }

    /**
     * Called whenever the unread message count changes.
     */
    fun onUnreadCountChanged(unreadCount: Int) {
        // Default implementation - can be overridden if needed
    }
}

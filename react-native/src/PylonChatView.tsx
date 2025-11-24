import React, { useImperativeHandle, useRef } from "react";
import {
  findNodeHandle,
  requireNativeComponent,
  UIManager,
  ViewStyle,
} from "react-native";
import type { PylonChatListener, PylonConfig, PylonUser } from "./types";

// Public API exposed to SDK users.
export interface PylonChatViewRef {
  openChat: () => void;
  closeChat: () => void;
  showChatBubble: () => void;
  hideChatBubble: () => void;
  showNewMessage: (message: string, isHtml?: boolean) => void;
  setNewIssueCustomFields: (fields: Record<string, any>) => void;
  setTicketFormFields: (fields: Record<string, any>) => void;
  updateEmailHash: (emailHash: string | null) => void;
  showTicketForm: (slug: string) => void;
  showKnowledgeBaseArticle: (articleId: string) => void;
}

// Internal interface with additional methods for platform-specific implementations.
export interface PylonChatViewInternalRef extends PylonChatViewRef {
  clickElementAtSelector: (selector: string) => void;
}

interface PylonChatViewProps {
  config: PylonConfig;
  user?: PylonUser;
  style?: ViewStyle;
  listener?: PylonChatListener;
  topInset?: number;
}

interface NativePylonChatViewProps {
  style?: ViewStyle;
  pointerEvents?: "box-none" | "none" | "box-only" | "auto";
  appId: string;
  widgetBaseUrl?: string;
  widgetScriptUrl?: string;
  enableLogging?: boolean;
  debugMode?: boolean;
  primaryColor?: string;
  userEmail?: string;
  userName?: string;
  userAvatarUrl?: string;
  userEmailHash?: string;
  userAccountId?: string;
  userAccountExternalId?: string;
  topInset?: number;
  onPylonLoaded?: () => void;
  onPylonInitialized?: () => void;
  onPylonReady?: () => void;
  onChatOpened?: () => void;
  onChatClosed?: (event: { nativeEvent: { wasOpen: boolean } }) => void;
  onUnreadCountChanged?: (event: { nativeEvent: { count: number } }) => void;
  onMessageReceived?: (event: { nativeEvent: { message: string } }) => void;
  onPylonError?: (event: { nativeEvent: { error: string } }) => void;
  onInteractiveBoundsChanged?: (event: {
    nativeEvent: {
      selector: string;
      left: number;
      top: number;
      right: number;
      bottom: number;
    };
  }) => void;
}

const NativePylonChatView =
  requireNativeComponent<NativePylonChatViewProps>("RNPylonChatView");

const COMMANDS = {
  openChat: "openChat",
  closeChat: "closeChat",
  showChatBubble: "showChatBubble",
  hideChatBubble: "hideChatBubble",
  showNewMessage: "showNewMessage",
  setNewIssueCustomFields: "setNewIssueCustomFields",
  setTicketFormFields: "setTicketFormFields",
  updateEmailHash: "updateEmailHash",
  showTicketForm: "showTicketForm",
  showKnowledgeBaseArticle: "showKnowledgeBaseArticle",
  clickElementAtSelector: "clickElementAtSelector",
};

export const PylonChatView = React.forwardRef<
  PylonChatViewInternalRef,
  PylonChatViewProps
>(({ config, user, style, listener, topInset = 0 }, ref) => {
  const nativeRef = useRef(null);

  const dispatchCommand = (commandName: string, args: any[] = []) => {
    const handle = findNodeHandle(nativeRef.current);
    if (handle) {
      UIManager.dispatchViewManagerCommand(handle, commandName, args);
    }
  };

  // Expose imperative methods via ref
  useImperativeHandle(
    ref,
    () => ({
      openChat: () => dispatchCommand(COMMANDS.openChat),
      closeChat: () => dispatchCommand(COMMANDS.closeChat),
      showChatBubble: () => dispatchCommand(COMMANDS.showChatBubble),
      hideChatBubble: () => dispatchCommand(COMMANDS.hideChatBubble),
      showNewMessage: (message: string, isHtml = false) =>
        dispatchCommand(COMMANDS.showNewMessage, [message, isHtml]),
      setNewIssueCustomFields: (fields: Record<string, any>) =>
        dispatchCommand(COMMANDS.setNewIssueCustomFields, [fields]),
      setTicketFormFields: (fields: Record<string, any>) =>
        dispatchCommand(COMMANDS.setTicketFormFields, [fields]),
      updateEmailHash: (emailHash: string | null) =>
        dispatchCommand(COMMANDS.updateEmailHash, [emailHash]),
      showTicketForm: (slug: string) =>
        dispatchCommand(COMMANDS.showTicketForm, [slug]),
      showKnowledgeBaseArticle: (articleId: string) =>
        dispatchCommand(COMMANDS.showKnowledgeBaseArticle, [articleId]),
      clickElementAtSelector: (selector: string) =>
        dispatchCommand(COMMANDS.clickElementAtSelector, [selector]),
    }),
    []
  );

  return (
    <NativePylonChatView
      ref={nativeRef}
      style={style}
      appId={config.appId}
      widgetBaseUrl={config.widgetBaseUrl}
      widgetScriptUrl={config.widgetScriptUrl}
      enableLogging={config.enableLogging}
      debugMode={config.debugMode}
      primaryColor={config.primaryColor}
      userEmail={user?.email}
      userName={user?.name}
      userAvatarUrl={user?.avatarUrl}
      userEmailHash={user?.emailHash}
      userAccountId={user?.accountId}
      userAccountExternalId={user?.accountExternalId}
      topInset={topInset}
      onPylonLoaded={() => listener?.onPylonLoaded?.()}
      onPylonInitialized={() => listener?.onPylonInitialized?.()}
      onPylonReady={() => listener?.onPylonReady?.()}
      onChatOpened={() => listener?.onChatOpened?.()}
      onChatClosed={(event) =>
        listener?.onChatClosed?.(event.nativeEvent.wasOpen)
      }
      onUnreadCountChanged={(event) =>
        listener?.onUnreadCountChanged?.(event.nativeEvent.count)
      }
      onMessageReceived={(event) =>
        listener?.onMessageReceived?.(event.nativeEvent.message)
      }
      onPylonError={(event) =>
        listener?.onPylonError?.(event.nativeEvent.error)
      }
      onInteractiveBoundsChanged={(event) =>
        listener?.onInteractiveBoundsChanged?.(event.nativeEvent)
      }
    />
  );
});

PylonChatView.displayName = "PylonChatView";

export default PylonChatView;

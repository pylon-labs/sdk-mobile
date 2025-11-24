import type {
  PylonChatListener,
  PylonChatViewRef,
} from "@pylon/react-native-chat";
import { PylonChatWidget } from "@pylon/react-native-chat";
import { StatusBar } from "expo-status-bar";
import React, { useRef, useState } from "react";
import {
  Modal,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import {
  SafeAreaProvider,
  SafeAreaView,
  useSafeAreaInsets,
} from "react-native-safe-area-context";

function AppContent() {
  const pylonRef = useRef<PylonChatViewRef>(null);
  const insets = useSafeAreaInsets();
  const [unreadCount, setUnreadCount] = useState(0);
  const [nativeMessage, setNativeMessage] = useState(
    "<p>Hello from React Native!</p>"
  );
  const [sendHtml, setSendHtml] = useState(true);
  const [ticketFormSlug, setTicketFormSlug] = useState("test-ticket-form");
  const [articleId, setArticleId] = useState("6486988972");
  const [emailHash, setEmailHash] = useState("");
  const [showDrawer, setShowDrawer] = useState(false);
  const [showModal, setShowModal] = useState(false);

  // Configuration - loads from .env file (copy env.example to .env)
  const config = {
    appId: process.env.EXPO_PUBLIC_PYLON_APP_ID,
    widgetBaseUrl:
      process.env.EXPO_PUBLIC_PYLON_WIDGET_BASE_URL ||
      "https://widget.usepylon.com",
    enableLogging: process.env.EXPO_PUBLIC_PYLON_ENABLE_LOGGING === "true",
    debugMode: process.env.EXPO_PUBLIC_PYLON_DEBUG_MODE === "true",
  };

  console.log("App component mounted");
  console.log("Config:", config);

  const user = {
    email: process.env.EXPO_PUBLIC_PYLON_USER_EMAIL || "demo@example.com",
    name: process.env.EXPO_PUBLIC_PYLON_USER_NAME || "Demo User",
  };

  const listener: PylonChatListener = {
    onPylonLoaded: () => {
      console.log("✅ [EVENT] Pylon loaded");
    },
    onPylonInitialized: () => {
      console.log("✅ [EVENT] Pylon initialized");
    },
    onPylonReady: () => {
      console.log("✅ [EVENT] Pylon ready");
    },
    onChatOpened: () => {
      console.log("✅ [EVENT] Chat opened");
    },
    onChatClosed: (wasOpen) => {
      console.log("✅ [EVENT] Chat closed (was previously open:", wasOpen, ")");
    },
    onUnreadCountChanged: (count) => {
      console.log("✅ [EVENT] Unread count:", count);
      setUnreadCount(count);
    },
    onMessageReceived: (message) => {
      console.log("✅ [EVENT] Message received:", message);
    },
    onPylonError: (error) => {
      console.error("❌ [EVENT] Pylon error:", error);
    },
  };

  return (
    <View style={styles.container}>
      <StatusBar style="auto" />

      {/* Main Content Layer */}
      <SafeAreaView style={styles.contentLayer}>
        {/* Control Toolbar */}
        <View style={styles.mainContent}>
          <ScrollView
            style={styles.toolbar}
            contentContainerStyle={styles.toolbarContent}
          >
            <Text style={styles.sectionTitle}>Controls</Text>
            <Text style={styles.unreadText}>
              Unread messages: {unreadCount}
            </Text>

            {/* Chat Bubble Controls */}
            <View style={styles.buttonRow}>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() => pylonRef.current?.showChatBubble()}
              >
                <Text style={styles.buttonText}>Show Bubble</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() => pylonRef.current?.hideChatBubble()}
              >
                <Text style={styles.buttonText}>Hide Bubble</Text>
              </TouchableOpacity>
            </View>

            {/* Chat Window Controls */}
            <View style={styles.buttonRow}>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() => pylonRef.current?.openChat()}
              >
                <Text style={styles.buttonText}>Open Chat</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() => pylonRef.current?.closeChat()}
              >
                <Text style={styles.buttonText}>Close Chat</Text>
              </TouchableOpacity>
            </View>

            {/* UI Test Controls */}
            <View style={styles.buttonRow}>
              <TouchableOpacity
                style={[styles.button, styles.buttonSecondary]}
                onPress={() => setShowDrawer(true)}
              >
                <Text style={styles.buttonSecondaryText}>Open Drawer</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.button, styles.buttonSecondary]}
                onPress={() => setShowModal(true)}
              >
                <Text style={styles.buttonSecondaryText}>Open Modal</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.divider} />

            <Text style={styles.subsectionTitle}>Native Messaging</Text>

            <TextInput
              style={styles.textInput}
              value={nativeMessage}
              onChangeText={setNativeMessage}
              placeholder="Message"
              multiline
              numberOfLines={3}
            />

            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>Send as HTML</Text>
              <Switch value={sendHtml} onValueChange={setSendHtml} />
            </View>

            <TouchableOpacity
              style={[
                styles.button,
                styles.buttonPrimary,
                styles.fullWidthButton,
              ]}
              onPress={() =>
                pylonRef.current?.showNewMessage(nativeMessage, sendHtml)
              }
            >
              <Text style={styles.buttonText}>Send Message</Text>
            </TouchableOpacity>

            <View style={styles.buttonRow}>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() =>
                  pylonRef.current?.setNewIssueCustomFields({
                    ben_hawaii_test_field: "hello",
                  })
                }
              >
                <Text style={styles.buttonText}>Set Custom Fields</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.button, styles.buttonPrimary]}
                onPress={() =>
                  pylonRef.current?.setTicketFormFields({
                    description: nativeMessage,
                  })
                }
              >
                <Text style={styles.buttonText}>Set Ticket Fields</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.divider} />

            <Text style={styles.subsectionTitle}>Support Actions</Text>

            <TextInput
              style={styles.textInput}
              value={emailHash}
              onChangeText={setEmailHash}
              placeholder="Email Hash (SHA-256)"
            />

            <TouchableOpacity
              style={[
                styles.button,
                styles.buttonPrimary,
                styles.fullWidthButton,
              ]}
              onPress={() =>
                pylonRef.current?.updateEmailHash(
                  emailHash.trim() === "" ? null : emailHash
                )
              }
            >
              <Text style={styles.buttonText}>Apply Email Hash</Text>
            </TouchableOpacity>

            <TextInput
              style={styles.textInput}
              value={ticketFormSlug}
              onChangeText={setTicketFormSlug}
              placeholder="Ticket Form Slug"
            />

            <TouchableOpacity
              style={[
                styles.button,
                styles.buttonPrimary,
                styles.fullWidthButton,
              ]}
              onPress={() => pylonRef.current?.showTicketForm(ticketFormSlug)}
            >
              <Text style={styles.buttonText}>Show Ticket Form</Text>
            </TouchableOpacity>

            <TextInput
              style={styles.textInput}
              value={articleId}
              onChangeText={setArticleId}
              placeholder="Knowledge Base Article ID"
            />

            <TouchableOpacity
              style={[
                styles.button,
                styles.buttonPrimary,
                styles.fullWidthButton,
              ]}
              onPress={() =>
                pylonRef.current?.showKnowledgeBaseArticle(articleId)
              }
            >
              <Text style={styles.buttonText}>Show KB Article</Text>
            </TouchableOpacity>
          </ScrollView>
        </View>
      </SafeAreaView>

      {/* Pylon Chat Widget - Overlay Layer */}
      <PylonChatWidget
        ref={pylonRef}
        config={config}
        user={user}
        listener={listener}
        topInset={-insets.top}
      />

      {/* Drawer */}
      {showDrawer && (
        <TouchableOpacity
          style={styles.drawerOverlay}
          activeOpacity={1}
          onPress={() => setShowDrawer(false)}
        >
          <TouchableOpacity
            style={styles.drawer}
            activeOpacity={1}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={styles.drawerHeader}>
              <Text style={styles.drawerTitle}>Test Drawer</Text>
              <TouchableOpacity onPress={() => setShowDrawer(false)}>
                <Text style={styles.drawerClose}>✕</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.drawerText}>
              This drawer tests overlay interaction with the Pylon chat widget.
            </Text>
            <Text style={styles.drawerText}>
              The chat bubble should remain functional.
            </Text>
          </TouchableOpacity>
        </TouchableOpacity>
      )}

      {/* Modal */}
      <Modal
        visible={showModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modal}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Test Modal</Text>
              <TouchableOpacity onPress={() => setShowModal(false)}>
                <Text style={styles.modalClose}>✕</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.modalText}>
              This modal tests overlay interaction with the Pylon chat widget.
            </Text>
            <Text style={styles.modalText}>
              The chat bubble should remain functional.
            </Text>
            <TouchableOpacity
              style={[
                styles.button,
                styles.buttonPrimary,
                styles.fullWidthButton,
              ]}
              onPress={() => setShowModal(false)}
            >
              <Text style={styles.buttonText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  contentLayer: {
    flex: 1,
  },
  mainContent: {
    flex: 1,
  },
  toolbar: {
    flex: 1,
    backgroundColor: "#f5f5f5",
  },
  toolbarContent: {
    padding: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 4,
  },
  subsectionTitle: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 8,
  },
  unreadText: {
    fontSize: 12,
    color: "#666",
    marginBottom: 8,
  },
  buttonRow: {
    flexDirection: "row",
    gap: 8,
    marginBottom: 8,
  },
  button: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 6,
    alignItems: "center",
  },
  buttonPrimary: {
    backgroundColor: "#007AFF",
  },
  buttonSecondary: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#007AFF",
  },
  buttonText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "600",
  },
  buttonSecondaryText: {
    color: "#007AFF",
    fontSize: 12,
    fontWeight: "600",
  },
  fullWidthButton: {
    marginBottom: 8,
  },
  textInput: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 6,
    padding: 10,
    marginBottom: 8,
    fontSize: 14,
  },
  switchRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
  },
  switchLabel: {
    fontSize: 14,
  },
  divider: {
    height: 1,
    backgroundColor: "#ddd",
    marginVertical: 12,
  },
  drawerOverlay: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "flex-end",
  },
  drawer: {
    width: "75%",
    height: "100%",
    backgroundColor: "#fff",
    padding: 20,
  },
  drawerHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  drawerTitle: {
    fontSize: 24,
    fontWeight: "bold",
  },
  drawerClose: {
    fontSize: 24,
    color: "#666",
  },
  drawerText: {
    fontSize: 16,
    marginBottom: 12,
    color: "#333",
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "center",
  },
  modal: {
    width: "80%",
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 20,
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: "bold",
  },
  modalClose: {
    fontSize: 24,
    color: "#666",
  },
  modalText: {
    fontSize: 16,
    marginBottom: 12,
    color: "#333",
  },
});

export default function App() {
  return (
    <SafeAreaProvider>
      <AppContent />
    </SafeAreaProvider>
  );
}

import SwiftUI
import PylonChat

struct ContentView: View {
    @State private var pylonChatView: PylonChatView?
    @State private var unreadCount = 0
    @State private var nativeMessage = "<p>Hello from iOS native!</p>"
    @State private var sendHtml = true
    @State private var ticketFormSlug = "test-ticket-form"
    @State private var articleId = "6486988972"
    @State private var emailHash = ""
    @State private var showDrawer = false
    @State private var showModal = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Control Toolbar
                ControlToolbar(
                    onShowBubble: { pylonChatView?.showChatBubble() },
                    onHideBubble: { pylonChatView?.hideChatBubble() },
                    onShowChat: { pylonChatView?.openChat() },
                    onHideChat: { pylonChatView?.closeChat() },
                    onOpenDrawer: { showDrawer = true },
                    onOpenModal: { showModal = true },
                    unreadCount: unreadCount,
                    messageText: $nativeMessage,
                    isHtmlMessage: $sendHtml,
                    onSendMessage: {
                        pylonChatView?.showNewMessage(nativeMessage, isHtml: sendHtml)
                    },
                    onSetCustomFields: {
                        pylonChatView?.setNewIssueCustomFields([
                            "ben_hawaii_test_field": "hello",
                        ])
                    },
                    onSetTicketFields: {
                        pylonChatView?.setTicketFormFields([
                            "description": nativeMessage,
                        ])
                    },
                    emailHash: $emailHash,
                    onApplyEmailHash: {
                        pylonChatView?.updateEmailHash(emailHash.isEmpty ? nil : emailHash)
                    },
                    ticketFormSlug: $ticketFormSlug,
                    onShowTicketForm: {
                        pylonChatView?.showTicketForm(ticketFormSlug)
                    },
                    knowledgeBaseArticleId: $articleId,
                    onShowKnowledgeBaseArticle: {
                        pylonChatView?.showKnowledgeBaseArticle(articleId)
                    }
                )

                // Main content area
                Spacer()
            }

            // Pylon Chat Widget
            PylonChatHostView(chatView: $pylonChatView, unreadCount: $unreadCount)

            // Drawer
            if showDrawer {
                HStack {
                    Spacer()
                    TestDrawer(isOpen: $showDrawer)
                        .transition(.move(edge: .trailing))
                }
                .background(Color.black.opacity(0.3))
                .onTapGesture {
                    showDrawer = false
                }
            }
        }
        .sheet(isPresented: $showModal) {
            TestModal()
        }
    }
}


struct ControlToolbar: View {
    let onShowBubble: () -> Void
    let onHideBubble: () -> Void
    let onShowChat: () -> Void
    let onHideChat: () -> Void
    let onOpenDrawer: () -> Void
    let onOpenModal: () -> Void
    let unreadCount: Int
    @Binding var messageText: String
    @Binding var isHtmlMessage: Bool
    let onSendMessage: () -> Void
    let onSetCustomFields: () -> Void
    let onSetTicketFields: () -> Void
    @Binding var emailHash: String
    let onApplyEmailHash: () -> Void
    @Binding var ticketFormSlug: String
    let onShowTicketForm: () -> Void
    @Binding var knowledgeBaseArticleId: String
    let onShowKnowledgeBaseArticle: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Controls")
                    .font(.headline)
                    .padding(.horizontal)

                Text("Unread messages: \(unreadCount)")
                    .font(.caption)
                    .padding(.horizontal)

                // Chat Bubble Controls
                HStack(spacing: 4) {
                    Button("Show Bubble") { onShowBubble() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)

                    Button("Hide Bubble") { onHideBubble() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                // Chat Window Controls
                HStack(spacing: 4) {
                    Button("Open Chat") { onShowChat() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)

                    Button("Close Chat") { onHideChat() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                // UI Test Controls
                HStack(spacing: 4) {
                    Button("Open Drawer") { onOpenDrawer() }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        .frame(maxWidth: .infinity)

                    Button("Open Modal") { onOpenModal() }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 4)

                Text("Native Messaging")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal)

                HStack {
                    Toggle("Send as HTML", isOn: $isHtmlMessage)
                        .font(.caption)

                    Spacer()

                    Button("Send Message") { onSendMessage() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                }
                .padding(.horizontal)

                HStack(spacing: 4) {
                    Button("Set Custom Fields") { onSetCustomFields() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)

                    Button("Set Ticket Fields") { onSetTicketFields() }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 4)

                Text("Support Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                TextField("Email Hash (SHA-256)", text: $emailHash)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Apply Email Hash") { onApplyEmailHash() }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                TextField("Ticket Form Slug", text: $ticketFormSlug)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Show Ticket Form") { onShowTicketForm() }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                TextField("Knowledge Base Article ID", text: $knowledgeBaseArticleId)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Show KB Article") { onShowKnowledgeBaseArticle() }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

struct TestDrawer: View {
    @Binding var isOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Test Drawer")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Close") {
                    isOpen = false
                }
            }

            Divider()

            Text("This drawer should appear OVER the chat widget.")
                .font(.body)

            Spacer()

            ForEach(1...10, id: \.self) { index in
                VStack(alignment: .leading) {
                    Text("Drawer Item \(index)")
                        .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(uiColor: .systemBackground))
        .shadow(radius: 10)
    }
}

struct TestModal: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("This modal should appear OVER the chat widget.")
                        .padding()

                    Text("The chat widget should not interfere with this dialog.")
                        .padding()

                    ForEach(1...5, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text("Modal Item \(index)")
                                .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Test Modal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

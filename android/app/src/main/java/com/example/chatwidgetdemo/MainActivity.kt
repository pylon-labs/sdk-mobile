package com.example.chatwidgetdemo

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.chatwidgetdemo.ui.theme.ChatWidgetDemoTheme
import com.pylon.chatwidget.Pylon
import com.pylon.chatwidget.PylonChat
import com.pylon.chatwidget.PylonChatController
import com.pylon.chatwidget.PylonChatListener

class MainActivity : ComponentActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (Pylon.handleActivityResult(resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Pylon SDK
        Pylon.initialize(
            applicationContext,
            appId = "d48c8c5b-f96c-45e0-bb0f-dfbcecd75c6b"
        ) {
            enableLogging = true
            debugMode = true
        }

        // Set user
        Pylon.setUser(
            email = "ben@ben.com",
            name = "Ben Song"
        )

        setContent {
            ChatWidgetDemoTheme(darkTheme = true) {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    MainContent(
                        modifier = Modifier
                            .padding(innerPadding)
                            .fillMaxSize()
                    )
                }
            }
        }
    }
}

@Composable
fun MainContent(modifier: Modifier = Modifier) {
    var isDrawerOpen by remember { mutableStateOf(false) }
    var isModalOpen by remember { mutableStateOf(false) }
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }
    var unreadCount by remember { mutableIntStateOf(0) }
    var nativeMessage by remember { mutableStateOf("<p>Hello from Android native!</p>") }
    var sendHtml by remember { mutableStateOf(true) }
    var ticketFormSlug by remember { mutableStateOf("default") }
    var articleId by remember { mutableStateOf("getting-started") }
    var emailHash by remember { mutableStateOf("") }

    Box(modifier = modifier) {

        DisposableEffect(pylonChat) {
            val controller = pylonChat
            if (controller != null) {
                val listener = object : PylonChatListener {
                    override fun onPylonLoaded() {}
                    override fun onPylonInitialized() {}
                    override fun onPylonReady() {}
                    override fun onMessageReceived(message: String) {}
                    override fun onChatOpened() {}
                    override fun onChatClosed() {}
                    override fun onPylonError(error: String) {}
                    override fun onFileChooserLaunched(requestCode: Int) {}
                    override fun onUnreadCountChanged(count: Int) {
                        unreadCount = count
                    }
                }
                controller.setListener(listener)
                onDispose { controller.setListener(null) }
            } else {
                onDispose { }
            }
        }

        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Toolbar at the top
            ControlToolbar(
                onShowBubble = { pylonChat?.showChatBubble() },
                onHideBubble = { pylonChat?.hideChatBubble() },
                onShowChat = { pylonChat?.openChat() },
                onHideChat = { pylonChat?.closeChat() },
                onOpenDrawer = { isDrawerOpen = true },
                onOpenModal = { isModalOpen = true },
                unreadCount = unreadCount,
                messageText = nativeMessage,
                onMessageTextChanged = { nativeMessage = it },
                isHtmlMessage = sendHtml,
                onToggleHtml = { sendHtml = it },
                onSendMessage = { pylonChat?.showNewMessage(nativeMessage, sendHtml) },
                onSetCustomFields = {
                    pylonChat?.setNewIssueCustomFields(
                        mapOf(
                            "source" to "android-demo",
                            "priority" to "high",
                            "timestamp" to System.currentTimeMillis()
                        )
                    )
                },
                onSetTicketFields = {
                    pylonChat?.setTicketFormFields(
                        mapOf(
                            "subject" to "Android SDK toolbar test",
                            "description" to nativeMessage,
                            "is_html" to sendHtml
                        )
                    )
                },
                emailHash = emailHash,
                onEmailHashChanged = { emailHash = it },
                onApplyEmailHash = { pylonChat?.setEmailHash(emailHash.ifBlank { null }) },
                ticketFormSlug = ticketFormSlug,
                onTicketFormSlugChanged = { ticketFormSlug = it },
                onShowTicketForm = { pylonChat?.showTicketForm(ticketFormSlug) },
                knowledgeBaseArticleId = articleId,
                onKnowledgeBaseArticleIdChanged = { articleId = it },
                onShowKnowledgeBaseArticle = { pylonChat?.showKnowledgeBaseArticle(articleId) },
                modifier = Modifier.fillMaxWidth()
            )

            // Main content
            Box(modifier = Modifier.weight(1f)) { }
        }

        // Chat Widget
        PylonChatHost(
            onControllerChanged = { pylonChat = it },
            modifier = Modifier.fillMaxSize()
        )

        // Drawer on top of everything
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.CenterEnd
        ) {
            TestDrawer(
                isOpen = isDrawerOpen,
                onClose = { isDrawerOpen = false }
            )
        }

        // Modal dialog
        if (isModalOpen) {
            TestModal(onDismiss = { isModalOpen = false })
        }
    }
}

@Composable
fun ControlToolbar(
    onShowBubble: () -> Unit,
    onHideBubble: () -> Unit,
    onShowChat: () -> Unit,
    onHideChat: () -> Unit,
    onOpenDrawer: () -> Unit,
    onOpenModal: () -> Unit,
    unreadCount: Int,
    messageText: String,
    onMessageTextChanged: (String) -> Unit,
    isHtmlMessage: Boolean,
    onToggleHtml: (Boolean) -> Unit,
    onSendMessage: () -> Unit,
    onSetCustomFields: () -> Unit,
    onSetTicketFields: () -> Unit,
    emailHash: String,
    onEmailHashChanged: (String) -> Unit,
    onApplyEmailHash: () -> Unit,
    ticketFormSlug: String,
    onTicketFormSlugChanged: (String) -> Unit,
    onShowTicketForm: () -> Unit,
    knowledgeBaseArticleId: String,
    onKnowledgeBaseArticleIdChanged: (String) -> Unit,
    onShowKnowledgeBaseArticle: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = "Controls",
                style = MaterialTheme.typography.titleSmall,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
            )

            Text(
                text = "Unread messages: $unreadCount",
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(horizontal = 8.dp)
            )

            // Chat Bubble Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Button(
                    onClick = onShowBubble,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(text = "Show Bubble", style = MaterialTheme.typography.labelSmall)
                }
                Button(
                    onClick = onHideBubble,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(text = "Hide Bubble", style = MaterialTheme.typography.labelSmall)
                }
            }

            // Chat Window Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Button(
                    onClick = onShowChat,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(text = "Open Chat", style = MaterialTheme.typography.labelSmall)
                }
                Button(
                    onClick = onHideChat,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(text = "Close Chat", style = MaterialTheme.typography.labelSmall)
                }
            }

            // UI Test Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Button(
                    onClick = onOpenDrawer,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondary
                    )
                ) {
                    Text(text = "Open Drawer", style = MaterialTheme.typography.labelSmall)
                }
                Button(
                    onClick = onOpenModal,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondary
                    )
                ) {
                    Text(text = "Open Modal", style = MaterialTheme.typography.labelSmall)
                }
            }

            Divider(modifier = Modifier.padding(vertical = 4.dp))

            Text(
                text = "Native Messaging",
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier.padding(horizontal = 8.dp)
            )

            OutlinedTextField(
                value = messageText,
                onValueChange = onMessageTextChanged,
                label = { Text("Message") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Checkbox(checked = isHtmlMessage, onCheckedChange = onToggleHtml)
                Text(text = "Send as HTML", style = MaterialTheme.typography.bodySmall)
                Spacer(modifier = Modifier.weight(1f))
                Button(onClick = onSendMessage) {
                    Text("Send Message")
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Button(
                    onClick = onSetCustomFields,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Set Custom Fields", style = MaterialTheme.typography.labelSmall)
                }

                Button(
                    onClick = onSetTicketFields,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Set Ticket Fields", style = MaterialTheme.typography.labelSmall)
                }
            }

            Divider(modifier = Modifier.padding(vertical = 4.dp))

            Text(
                text = "Support Actions",
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier.padding(horizontal = 8.dp)
            )

            OutlinedTextField(
                value = emailHash,
                onValueChange = onEmailHashChanged,
                label = { Text("Email Hash (SHA-256)") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            )

            Button(
                onClick = onApplyEmailHash,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            ) {
                Text("Apply Email Hash")
            }

            OutlinedTextField(
                value = ticketFormSlug,
                onValueChange = onTicketFormSlugChanged,
                label = { Text("Ticket Form Slug") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            )

            Button(
                onClick = onShowTicketForm,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            ) {
                Text("Show Ticket Form")
            }

            OutlinedTextField(
                value = knowledgeBaseArticleId,
                onValueChange = onKnowledgeBaseArticleIdChanged,
                label = { Text("Knowledge Base Article ID") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            )

            Button(
                onClick = onShowKnowledgeBaseArticle,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            ) {
                Text("Show KB Article")
            }
        }
    }
}

@Composable
fun TestModal(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Test Modal") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("This modal should appear OVER the chat widget.")
                Text("The chat widget should not interfere with this dialog.")
                repeat(5) { index ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    ) {
                        Text(
                            text = "Modal Item ${index + 1}",
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}

@Composable
fun PylonChatHost(
    onControllerChanged: (PylonChatController?) -> Unit,
    modifier: Modifier = Modifier
) {
    AndroidView(
        factory = { context ->
            Pylon.createChat(context).also { controller ->
                onControllerChanged(controller)
            }.view
        },
        modifier = modifier,
        onRelease = { view ->
            if (view is PylonChat) {
                view.destroy()
            }
            onControllerChanged(null)
        }
    )
}

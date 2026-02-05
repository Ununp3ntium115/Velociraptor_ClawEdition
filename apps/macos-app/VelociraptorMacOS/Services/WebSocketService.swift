//
//  WebSocketService.swift
//  VelociraptorMacOS
//
//  WebSocket service for real-time Velociraptor updates
//  Gap: 0x08 - WebSocket Real-Time Updates
//
//  CDIF Pattern: Actor-isolated WebSocket with reconnection
//  Swift 6 Concurrency: Strict mode compliant
//

import Foundation
import Combine

// MARK: - WebSocket Event Types

/// WebSocket message types from Velociraptor
enum WebSocketEventType: String, Codable, Sendable {
    case ping = "ping"
    case pong = "pong"
    case huntProgress = "hunt_progress"
    case huntCompleted = "hunt_completed"
    case clientConnected = "client_connected"
    case clientDisconnected = "client_disconnected"
    case flowProgress = "flow_progress"
    case flowCompleted = "flow_completed"
    case notification = "notification"
    case error = "error"
}

/// WebSocket message envelope
struct WebSocketMessage: Codable, Sendable {
    let type: String
    let payload: WebSocketPayload?
    let timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case type
        case payload
        case timestamp
    }
}

/// WebSocket payload (varies by message type)
struct WebSocketPayload: Codable, Sendable {
    let huntId: String?
    let clientId: String?
    let flowId: String?
    let progress: Double?
    let message: String?
    let data: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case huntId = "hunt_id"
        case clientId = "client_id"
        case flowId = "flow_id"
        case progress
        case message
        case data
    }
}

// MARK: - WebSocket State

/// WebSocket connection state
enum WebSocketState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - WebSocket Service

/// WebSocket service for real-time updates
/// Actor-isolated for thread safety
@MainActor
final class WebSocketService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WebSocketService()
    
    // MARK: - Published Properties
    
    /// Current connection state
    @Published private(set) var state: WebSocketState = .disconnected
    
    /// Hunt progress updates
    @Published private(set) var huntProgress: [String: Double] = [:]
    
    /// Client online status updates
    @Published private(set) var clientOnlineStatus: [String: Bool] = [:]
    
    /// Recent activity events
    @Published private(set) var recentEvents: [ActivityEvent] = []
    
    /// Last error
    @Published private(set) var lastError: String?
    
    // MARK: - Event Publishers
    
    /// Publisher for hunt progress updates
    let huntProgressPublisher = PassthroughSubject<(huntId: String, progress: Double), Never>()
    
    /// Publisher for client status changes
    let clientStatusPublisher = PassthroughSubject<(clientId: String, online: Bool), Never>()
    
    /// Publisher for flow completions
    let flowCompletedPublisher = PassthroughSubject<(clientId: String, flowId: String), Never>()
    
    /// Publisher for notifications
    let notificationPublisher = PassthroughSubject<String, Never>()
    
    // MARK: - Private Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var serverURL: URL?
    private var apiKey: String?
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    private init() {
        Logger.shared.info("WebSocket service initialized", component: "WebSocket")
    }
    
    deinit {
        // Cancel tasks directly without calling isolated methods
        pingTask?.cancel()
        receiveTask?.cancel()
        reconnectTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    // MARK: - Connection Management
    
    /// Configure and connect to WebSocket
    /// - Parameters:
    ///   - serverURL: Velociraptor server URL (will be converted to ws/wss)
    ///   - apiKey: API key for authentication
    func connect(serverURL: URL, apiKey: String) {
        self.serverURL = serverURL
        self.apiKey = apiKey
        
        reconnectAttempt = 0
        establishConnection()
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        state = .disconnected
        
        pingTask?.cancel()
        receiveTask?.cancel()
        reconnectTask?.cancel()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        Logger.shared.info("WebSocket disconnected", component: "WebSocket")
    }
    
    /// Reconnect after disconnect
    func reconnect() {
        guard let serverURL = serverURL, let apiKey = apiKey else {
            Logger.shared.warning("Cannot reconnect: not configured", component: "WebSocket")
            return
        }
        
        disconnect()
        connect(serverURL: serverURL, apiKey: apiKey)
    }
    
    // MARK: - Private Methods
    
    /// Establish WebSocket connection
    private func establishConnection() {
        guard let serverURL = serverURL, let apiKey = apiKey else {
            state = .failed("Not configured")
            return
        }
        
        state = .connecting
        
        // Convert HTTP URL to WebSocket URL
        var wsURL = serverURL
        if let scheme = wsURL.scheme {
            let wsScheme = scheme == "https" ? "wss" : "ws"
            var components = URLComponents(url: wsURL, resolvingAgainstBaseURL: true)!
            components.scheme = wsScheme
            components.path = "/api/v1/WatchEvents"
            wsURL = components.url!
        }
        
        Logger.shared.info("Connecting to WebSocket: \(wsURL)", component: "WebSocket")
        
        // Create session with auth
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let session = URLSession(configuration: config)
        webSocketTask = session.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        
        // Start receiving messages
        startReceiving()
        
        // Start ping/pong heartbeat
        startHeartbeat()
        
        state = .connected
        reconnectAttempt = 0
        
        Logger.shared.success("WebSocket connected", component: "WebSocket")
    }
    
    /// Start receiving WebSocket messages
    private func startReceiving() {
        receiveTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                do {
                    guard let message = try await self.webSocketTask?.receive() else {
                        break
                    }
                    
                    await self.handleMessage(message)
                    
                } catch {
                    if !Task.isCancelled {
                        Logger.shared.error("WebSocket receive error: \(error)", component: "WebSocket")
                        await self.handleDisconnect()
                    }
                    break
                }
            }
        }
    }
    
    /// Handle incoming WebSocket message
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            parseMessage(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(text)
            }
            
        @unknown default:
            Logger.shared.warning("Unknown WebSocket message type", component: "WebSocket")
        }
    }
    
    /// Parse and process message
    private func parseMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            processMessage(message)
        } catch {
            Logger.shared.debug("Failed to parse WebSocket message: \(error)", component: "WebSocket")
        }
    }
    
    /// Process decoded message
    private func processMessage(_ message: WebSocketMessage) {
        guard let eventType = WebSocketEventType(rawValue: message.type) else {
            Logger.shared.debug("Unknown WebSocket event type: \(message.type)", component: "WebSocket")
            return
        }
        
        switch eventType {
        case .ping:
            sendPong()
            
        case .pong:
            // Heartbeat acknowledged
            break
            
        case .huntProgress:
            if let payload = message.payload,
               let huntId = payload.huntId,
               let progress = payload.progress {
                huntProgress[huntId] = progress
                huntProgressPublisher.send((huntId: huntId, progress: progress))
                
                addActivityEvent(
                    type: .huntCreated,
                    message: "Hunt \(huntId) progress: \(Int(progress * 100))%",
                    huntId: huntId
                )
            }
            
        case .huntCompleted:
            if let payload = message.payload,
               let huntId = payload.huntId {
                huntProgress[huntId] = 1.0
                huntProgressPublisher.send((huntId: huntId, progress: 1.0))
                
                addActivityEvent(
                    type: .huntCompleted,
                    message: "Hunt \(huntId) completed",
                    huntId: huntId
                )
            }
            
        case .clientConnected:
            if let payload = message.payload,
               let clientId = payload.clientId {
                clientOnlineStatus[clientId] = true
                clientStatusPublisher.send((clientId: clientId, online: true))
                
                addActivityEvent(
                    type: .clientConnected,
                    message: "Client \(clientId) connected",
                    clientId: clientId
                )
            }
            
        case .clientDisconnected:
            if let payload = message.payload,
               let clientId = payload.clientId {
                clientOnlineStatus[clientId] = false
                clientStatusPublisher.send((clientId: clientId, online: false))
                
                addActivityEvent(
                    type: .clientDisconnected,
                    message: "Client \(clientId) disconnected",
                    clientId: clientId
                )
            }
            
        case .flowProgress:
            if let payload = message.payload,
               let clientId = payload.clientId,
               let flowId = payload.flowId,
               let progress = payload.progress {
                Logger.shared.debug("Flow \(flowId) progress: \(progress)", component: "WebSocket")
            }
            
        case .flowCompleted:
            if let payload = message.payload,
               let clientId = payload.clientId,
               let flowId = payload.flowId {
                flowCompletedPublisher.send((clientId: clientId, flowId: flowId))
                
                addActivityEvent(
                    type: .collectionCompleted,
                    message: "Collection completed on \(clientId)",
                    clientId: clientId
                )
            }
            
        case .notification:
            if let payload = message.payload,
               let messageText = payload.message {
                notificationPublisher.send(messageText)
                
                addActivityEvent(
                    type: .systemEvent,
                    message: messageText
                )
            }
            
        case .error:
            if let payload = message.payload,
               let errorMessage = payload.message {
                lastError = errorMessage
                Logger.shared.error("WebSocket error: \(errorMessage)", component: "WebSocket")
            }
        }
    }
    
    /// Add activity event to recent events
    private func addActivityEvent(
        type: ActivityEvent.ActivityType,
        message: String,
        clientId: String? = nil,
        huntId: String? = nil
    ) {
        let event = ActivityEvent(
            id: UUID().uuidString,
            type: type,
            message: message,
            timestamp: Date(),
            clientId: clientId,
            huntId: huntId
        )
        
        recentEvents.insert(event, at: 0)
        
        // Keep only last 100 events
        if recentEvents.count > 100 {
            recentEvents = Array(recentEvents.prefix(100))
        }
    }
    
    /// Start heartbeat ping/pong
    private func startHeartbeat() {
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                guard !Task.isCancelled else { break }
                
                await self?.sendPing()
            }
        }
    }
    
    /// Send ping message
    private func sendPing() {
        let ping = #"{"type":"ping"}"#
        webSocketTask?.send(.string(ping)) { error in
            if let error = error {
                Logger.shared.debug("Ping failed: \(error)", component: "WebSocket")
            }
        }
    }
    
    /// Send pong message
    private func sendPong() {
        let pong = #"{"type":"pong"}"#
        webSocketTask?.send(.string(pong)) { _ in }
    }
    
    /// Handle disconnection
    private func handleDisconnect() async {
        guard state != .disconnected else { return }
        
        pingTask?.cancel()
        receiveTask?.cancel()
        
        if reconnectAttempt < maxReconnectAttempts {
            reconnectAttempt += 1
            state = .reconnecting(attempt: reconnectAttempt)
            
            Logger.shared.info("Reconnecting (attempt \(reconnectAttempt)/\(maxReconnectAttempts))", component: "WebSocket")
            
            // Exponential backoff
            let delay = reconnectDelay * pow(2, Double(reconnectAttempt - 1))
            
            reconnectTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                await self?.establishConnection()
            }
        } else {
            state = .failed("Max reconnection attempts reached")
            Logger.shared.error("WebSocket reconnection failed after \(maxReconnectAttempts) attempts", component: "WebSocket")
        }
    }
    
    // MARK: - Subscription Methods
    
    /// Subscribe to hunt progress updates
    func subscribeToHunt(huntId: String) {
        let message = """
        {"type":"subscribe","channel":"hunt_progress","hunt_id":"\(huntId)"}
        """
        
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                Logger.shared.error("Failed to subscribe to hunt: \(error)", component: "WebSocket")
            }
        }
    }
    
    /// Unsubscribe from hunt progress
    func unsubscribeFromHunt(huntId: String) {
        let message = """
        {"type":"unsubscribe","channel":"hunt_progress","hunt_id":"\(huntId)"}
        """
        
        webSocketTask?.send(.string(message)) { _ in }
    }
    
    /// Subscribe to client status updates
    func subscribeToClientStatus() {
        let message = #"{"type":"subscribe","channel":"client_status"}"#
        webSocketTask?.send(.string(message)) { _ in }
    }
}

// MARK: - Accessibility Identifiers

extension WebSocketService {
    enum AccessibilityID {
        static let connectionStatus = "websocket.status.indicator"
        static let reconnectButton = "websocket.reconnect.button"
        static let activityFeed = "websocket.activity.feed"
    }
}

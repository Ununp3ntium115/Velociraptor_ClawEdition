//
//  ArtifactManagerViewModel.swift
//  VelociraptorMacOS
//
//  View model for Artifact Manager
//  Gap: 0x08 - Artifact Manager Business Logic
//

import Foundation
import SwiftUI
import Combine

// MARK: - Artifact Manager ViewModel

/// View model for managing artifacts, collections, and MCP recommendations
@MainActor
class ArtifactManagerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading = false
    @Published var showDetailPane = false
    @Published var showMCPAssistant = false
    @Published var error: Error?
    
    // Artifacts
    @Published var allArtifacts: [ArtifactModel] = []
    @Published var filteredArtifacts: [ArtifactModel] = []
    
    // Selection
    @Published var selectedCategory: ArtifactCategory?
    @Published var selectedArtifactId: String? {
        didSet {
            if selectedArtifactId != nil {
                showDetailPane = true
                showMCPAssistant = false
            }
        }
    }
    
    // Search and Filters
    @Published var searchQuery = "" {
        didSet { applyFilters() }
    }
    @Published var showFavoritesOnly = false {
        didSet { applyFilters() }
    }
    @Published var showCustomOnly = false {
        didSet { applyFilters() }
    }
    
    // View Settings
    @Published var viewMode: ArtifactViewMode = .list
    @Published var sortOrder: ArtifactSortOrder = .name {
        didSet { applyFilters() }
    }
    
    // Collections
    @Published var artifactCollections: [ArtifactCollection] = []
    @Published var currentCollection: ArtifactCollection?
    
    // MCP Recommendations
    @Published var mcpRecommendations: [ArtifactRecommendation] = []
    
    // Favorites (persisted)
    @Published var favoriteArtifacts: [ArtifactModel] = []
    
    // MARK: - Services
    
    private let searchService = ArtifactSearchService()
    private let mcpRecommender = MCPArtifactRecommender()
    private let apiClient = VelociraptorAPIClient.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var selectedSubcategory: String?
    
    // MARK: - Computed Properties
    
    var selectedArtifact: ArtifactModel? {
        guard let id = selectedArtifactId else { return nil }
        return allArtifacts.first { $0.id == id }
    }
    
    var selectedCategoryTitle: String {
        if let subcategory = selectedSubcategory {
            return "\(selectedCategory?.displayName ?? "All") - \(subcategory)"
        } else if let category = selectedCategory {
            return category.displayName
        } else if showFavoritesOnly {
            return "Favorites"
        } else if showCustomOnly {
            return "Custom Artifacts"
        } else if !searchQuery.isEmpty {
            return "Search Results"
        } else {
            return "All Artifacts"
        }
    }
    
    var customArtifacts: [ArtifactModel] {
        allArtifacts.filter { !($0.builtIn ?? false) }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
        loadFavorites()
        loadCollections()
    }
    
    private func setupSubscriptions() {
        // Auto-apply filters when artifacts change
        $allArtifacts
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// Load all artifacts from Velociraptor
    func loadArtifacts() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let artifacts = try await apiClient.listArtifacts()
                allArtifacts = artifacts.map { ArtifactModel(from: $0) }
                Logger.shared.info("Loaded \(allArtifacts.count) artifacts", component: "ArtifactManager")
            } catch {
                self.error = error
                Logger.shared.error("Failed to load artifacts: \(error)", component: "ArtifactManager")
            }
        }
    }
    
    /// Refresh artifacts
    func refreshArtifacts() async {
        loadArtifacts()
    }
    
    // MARK: - Filtering and Search
    
    private func applyFilters() {
        Task {
            var artifacts = allArtifacts
            
            // Apply category filter
            if let category = selectedCategory {
                if let subcategory = selectedSubcategory {
                    artifacts = await searchService.filterBySubcategory(
                        artifacts: artifacts,
                        category: category,
                        subcategory: subcategory
                    )
                } else {
                    artifacts = await searchService.filterByCategory(
                        artifacts: artifacts,
                        category: category
                    )
                }
            }
            
            // Apply favorites filter
            if showFavoritesOnly {
                artifacts = await searchService.filterFavorites(artifacts: artifacts)
            }
            
            // Apply custom filter
            if showCustomOnly {
                artifacts = await searchService.filterCustom(artifacts: artifacts)
            }
            
            // Apply search
            if !searchQuery.isEmpty {
                artifacts = await searchService.search(
                    artifacts: artifacts,
                    query: searchQuery
                )
            }
            
            // Sort
            artifacts = await searchService.sort(artifacts: artifacts, by: sortOrder)
            
            filteredArtifacts = artifacts
        }
    }
    
    func resetFilters() {
        selectedCategory = nil
        selectedSubcategory = nil
        showFavoritesOnly = false
        showCustomOnly = false
        searchQuery = ""
    }
    
    func selectSubcategory(_ category: ArtifactCategory, subcategory: String) {
        selectedCategory = category
        selectedSubcategory = subcategory
        applyFilters()
    }
    
    // MARK: - Category Management
    
    func artifactCount(for category: ArtifactCategory) -> Int {
        allArtifacts.filter { $0.category == category }.count
    }
    
    func artifactCount(for category: ArtifactCategory, subcategory: String) -> Int {
        allArtifacts.filter {
            $0.category == category && $0.subcategory == subcategory
        }.count
    }
    
    func subcategories(for category: ArtifactCategory) -> [String] {
        Task {
            return await searchService.getSubcategories(
                artifacts: allArtifacts,
                category: category
            )
        }
        
        // Synchronous fallback
        let artifacts = allArtifacts.filter { $0.category == category }
        return Array(Set(artifacts.compactMap { $0.subcategory })).sorted()
    }
    
    // MARK: - Favorites
    
    func isFavorite(_ artifact: ArtifactModel) -> Bool {
        favoriteArtifacts.contains { $0.id == artifact.id }
    }
    
    func toggleFavorite(_ artifact: ArtifactModel) {
        if isFavorite(artifact) {
            favoriteArtifacts.removeAll { $0.id == artifact.id }
            
            // Update in main list
            if let index = allArtifacts.firstIndex(where: { $0.id == artifact.id }) {
                var updated = allArtifacts[index]
                updated.isFavorite = false
                allArtifacts[index] = updated
            }
        } else {
            var updated = artifact
            updated.isFavorite = true
            favoriteArtifacts.append(updated)
            
            // Update in main list
            if let index = allArtifacts.firstIndex(where: { $0.id == artifact.id }) {
                allArtifacts[index] = updated
            }
        }
        
        saveFavorites()
        applyFilters()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "ArtifactFavorites"),
           let favorites = try? JSONDecoder().decode([String].self, from: data) {
            // Will be populated when artifacts are loaded
            Logger.shared.info("Loaded \(favorites.count) favorite artifact IDs", component: "ArtifactManager")
        }
    }
    
    private func saveFavorites() {
        let favoriteIds = favoriteArtifacts.map { $0.id }
        if let data = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(data, forKey: "ArtifactFavorites")
        }
    }
    
    // MARK: - Collections
    
    func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "ArtifactCollections"),
           let collections = try? JSONDecoder().decode([ArtifactCollection].self, from: data) {
            artifactCollections = collections
            Logger.shared.info("Loaded \(collections.count) artifact collections", component: "ArtifactManager")
        }
    }
    
    func saveCollections() {
        if let data = try? JSONEncoder().encode(artifactCollections) {
            UserDefaults.standard.set(data, forKey: "ArtifactCollections")
        }
    }
    
    func createCollection(name: String, description: String? = nil) {
        let collection = ArtifactCollection(
            name: name,
            description: description,
            artifacts: []
        )
        artifactCollections.append(collection)
        saveCollections()
    }
    
    func addToCollection(_ artifact: ArtifactModel) {
        // TODO: Show collection picker
        Logger.shared.info("Add to collection: \(artifact.name)", component: "ArtifactManager")
    }
    
    // MARK: - MCP Integration
    
    func generateMCPRecommendations(
        incidentType: IncidentType,
        platform: ArtifactPlatform,
        urgency: IncidentUrgency,
        scope: CollectionScope
    ) async {
        do {
            let recommendations = try await mcpRecommender.getRecommendations(
                incidentType: incidentType,
                platform: platform,
                urgency: urgency,
                scope: scope,
                allArtifacts: allArtifacts
            )
            
            mcpRecommendations = recommendations
            showMCPAssistant = true
            showDetailPane = true
            
            Logger.shared.info("Generated \(recommendations.count) MCP recommendations", component: "ArtifactManager")
        } catch {
            self.error = error
            Logger.shared.error("Failed to generate recommendations: \(error)", component: "ArtifactManager")
        }
    }
    
    func addRecommendationToCollection(_ recommendation: ArtifactRecommendation) {
        // Add to current collection or create new one
        Logger.shared.info("Adding recommendation: \(recommendation.artifact.name)", component: "ArtifactManager")
    }
    
    func addAllRecommendationsToCollection() {
        let artifactNames = mcpRecommendations.map { $0.artifact.name }
        
        let collectionName = "Incident Response - \(Date().formatted(date: .abbreviated, time: .shortened))"
        let collection = ArtifactCollection(
            name: collectionName,
            description: "Generated from MCP recommendations",
            artifacts: artifactNames
        )
        
        artifactCollections.append(collection)
        saveCollections()
        
        Logger.shared.info("Created collection with \(artifactNames.count) artifacts", component: "ArtifactManager")
    }
    
    func closeMCPAssistant() {
        showMCPAssistant = false
        showDetailPane = false
        mcpRecommendations = []
    }
    
    // MARK: - Artifact Actions
    
    func showArtifactDetails(_ artifact: ArtifactModel) {
        selectedArtifactId = artifact.id
        showDetailPane = true
        showMCPAssistant = false
    }
    
    func closeDetailPane() {
        selectedArtifactId = nil
        showDetailPane = false
    }
    
    func collectArtifact(_ artifact: ArtifactModel) {
        // TODO: Launch collection interface
        Logger.shared.info("Collect artifact: \(artifact.name)", component: "ArtifactManager")
        
        // Update last used
        if let index = allArtifacts.firstIndex(where: { $0.id == artifact.id }) {
            var updated = allArtifacts[index]
            updated.lastUsed = Date()
            updated.collectionCount += 1
            allArtifacts[index] = updated
        }
    }
    
    func showVQLSource(_ artifact: ArtifactModel) {
        Logger.shared.info("Show VQL source: \(artifact.name)", component: "ArtifactManager")
        // Switch to VQL tab in detail pane
    }
    
    func editArtifact(_ artifact: ArtifactModel) {
        Logger.shared.info("Edit artifact: \(artifact.name)", component: "ArtifactManager")
        // TODO: Open artifact editor
    }
    
    func importArtifact(yaml: String) async throws {
        // TODO: Parse YAML and upload to server
        Logger.shared.info("Import artifact from YAML", component: "ArtifactManager")
        
        // Simulate import
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Refresh artifacts
        await refreshArtifacts()
    }
    
    // MARK: - Dependencies
    
    func dependencies(for artifact: ArtifactModel) -> [ArtifactModel] {
        Task {
            return await searchService.findDependencies(
                for: artifact,
                in: allArtifacts
            )
        }
        
        // Synchronous fallback
        return []
    }
}

// MARK: - Preview Support

extension ArtifactManagerViewModel {
    /// Create view model with mock data for previews
    static func preview() -> ArtifactManagerViewModel {
        let vm = ArtifactManagerViewModel()
        
        // Mock artifacts
        vm.allArtifacts = [
            ArtifactModel(
                id: "Windows.System.ProcessList",
                name: "Windows.System.ProcessList",
                description: "Enumerate all running processes with detailed information",
                author: "Velociraptor Team",
                type: "CLIENT",
                parameters: [],
                sources: [],
                requiredPermissions: nil,
                builtIn: true,
                category: .windows,
                platform: .windows,
                isFavorite: true
            ),
            ArtifactModel(
                id: "Windows.Network.Netstat",
                name: "Windows.Network.Netstat",
                description: "List all active network connections",
                author: "Velociraptor Team",
                type: "CLIENT",
                parameters: [],
                sources: [],
                requiredPermissions: nil,
                builtIn: true,
                category: .windows,
                platform: .windows
            ),
            ArtifactModel(
                id: "Linux.System.ProcessInfo",
                name: "Linux.System.ProcessInfo",
                description: "Collect detailed process information on Linux systems",
                author: "Velociraptor Team",
                type: "CLIENT",
                parameters: [],
                sources: [],
                requiredPermissions: nil,
                builtIn: true,
                category: .linux,
                platform: .linux
            )
        ]
        
        vm.favoriteArtifacts = [vm.allArtifacts[0]]
        
        return vm
    }
}

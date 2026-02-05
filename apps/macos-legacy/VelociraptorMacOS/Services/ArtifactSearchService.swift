//
//  ArtifactSearchService.swift
//  VelociraptorMacOS
//
//  Search and filter service for artifacts
//  Gap: 0x08 - Artifact Search Logic
//

import Foundation

// MARK: - Artifact Search Service

/// Service for searching and filtering artifacts
actor ArtifactSearchService {
    // MARK: - Search Methods
    
    /// Search artifacts by query string
    func search(artifacts: [ArtifactModel], query: String) -> [ArtifactModel] {
        guard !query.isEmpty else { return artifacts }
        
        let lowercaseQuery = query.lowercased()
        
        return artifacts.filter { artifact in
            // Search in name
            if artifact.name.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in display name
            if artifact.displayName.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in description
            if let description = artifact.description,
               description.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in author
            if let author = artifact.author,
               author.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in type
            if let type = artifact.type,
               type.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in subcategory
            if let subcategory = artifact.subcategory,
               subcategory.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in parameters
            if let parameters = artifact.parameters {
                for param in parameters {
                    if param.name?.lowercased().contains(lowercaseQuery) == true {
                        return true
                    }
                    if let desc = param.description,
                       desc.lowercased().contains(lowercaseQuery) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    /// Filter artifacts by category
    func filterByCategory(artifacts: [ArtifactModel], category: ArtifactCategory) -> [ArtifactModel] {
        artifacts.filter { $0.category == category }
    }
    
    /// Filter artifacts by platform
    func filterByPlatform(artifacts: [ArtifactModel], platform: ArtifactPlatform) -> [ArtifactModel] {
        artifacts.filter { $0.platform == platform }
    }
    
    /// Filter artifacts by subcategory (e.g., "System", "Network")
    func filterBySubcategory(artifacts: [ArtifactModel], category: ArtifactCategory, subcategory: String) -> [ArtifactModel] {
        artifacts.filter { artifact in
            artifact.category == category && artifact.subcategory == subcategory
        }
    }
    
    /// Filter favorites
    func filterFavorites(artifacts: [ArtifactModel]) -> [ArtifactModel] {
        artifacts.filter { $0.isFavorite }
    }
    
    /// Filter custom artifacts (not built-in)
    func filterCustom(artifacts: [ArtifactModel]) -> [ArtifactModel] {
        artifacts.filter { !($0.builtIn ?? false) }
    }
    
    /// Get recently used artifacts
    func getRecentlyUsed(artifacts: [ArtifactModel], limit: Int = 10) -> [ArtifactModel] {
        artifacts
            .filter { $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get most frequently collected artifacts
    func getMostCollected(artifacts: [ArtifactModel], limit: Int = 10) -> [ArtifactModel] {
        artifacts
            .filter { $0.collectionCount > 0 }
            .sorted { $0.collectionCount > $1.collectionCount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Grouping Methods
    
    /// Group artifacts by category
    func groupByCategory(artifacts: [ArtifactModel]) -> [ArtifactCategory: [ArtifactModel]] {
        Dictionary(grouping: artifacts) { $0.category }
    }
    
    /// Group artifacts by subcategory within a category
    func groupBySubcategory(artifacts: [ArtifactModel], category: ArtifactCategory) -> [String: [ArtifactModel]] {
        let categoryArtifacts = artifacts.filter { $0.category == category }
        
        var grouped: [String: [ArtifactModel]] = [:]
        for artifact in categoryArtifacts {
            if let subcategory = artifact.subcategory {
                grouped[subcategory, default: []].append(artifact)
            } else {
                grouped["Other", default: []].append(artifact)
            }
        }
        
        return grouped
    }
    
    /// Get all unique subcategories for a category
    func getSubcategories(artifacts: [ArtifactModel], category: ArtifactCategory) -> [String] {
        let categoryArtifacts = artifacts.filter { $0.category == category }
        let subcategories = Set(categoryArtifacts.compactMap { $0.subcategory })
        return Array(subcategories).sorted()
    }
    
    // MARK: - Sorting Methods
    
    /// Sort artifacts
    func sort(artifacts: [ArtifactModel], by order: ArtifactSortOrder) -> [ArtifactModel] {
        switch order {
        case .name:
            return artifacts.sorted { $0.name < $1.name }
        case .platform:
            return artifacts.sorted { artifact1, artifact2 in
                if artifact1.category != artifact2.category {
                    return artifact1.category.rawValue < artifact2.category.rawValue
                }
                return artifact1.name < artifact2.name
            }
        case .type:
            return artifacts.sorted { artifact1, artifact2 in
                if artifact1.type != artifact2.type {
                    return (artifact1.type ?? "") < (artifact2.type ?? "")
                }
                return artifact1.name < artifact2.name
            }
        case .recentlyUsed:
            return artifacts.sorted { artifact1, artifact2 in
                let date1 = artifact1.lastUsed ?? .distantPast
                let date2 = artifact2.lastUsed ?? .distantPast
                return date1 > date2
            }
        }
    }
    
    // MARK: - Dependency Resolution
    
    /// Find artifact dependencies (artifacts referenced in VQL)
    func findDependencies(for artifact: ArtifactModel, in allArtifacts: [ArtifactModel]) -> [ArtifactModel] {
        var dependencies: Set<String> = []
        
        // Parse VQL sources for artifact references
        if let sources = artifact.sources {
            for source in sources {
                if let query = source.query {
                    // Simple regex-based extraction (production would use proper VQL parsing)
                    let artifactPattern = #"Artifact\.([A-Za-z0-9_.]+)"#
                    if let regex = try? NSRegularExpression(pattern: artifactPattern) {
                        let range = NSRange(query.startIndex..., in: query)
                        let matches = regex.matches(in: query, range: range)
                        
                        for match in matches {
                            if let artifactRange = Range(match.range(at: 1), in: query) {
                                let artifactName = String(query[artifactRange])
                                dependencies.insert(artifactName)
                            }
                        }
                    }
                }
            }
        }
        
        // Return matching artifacts
        return allArtifacts.filter { dependencies.contains($0.name) }
    }
    
    /// Check if artifact has dependencies
    func hasDependencies(artifact: ArtifactModel) -> Bool {
        guard let sources = artifact.sources else { return false }
        
        for source in sources {
            if let query = source.query, query.contains("Artifact.") {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Smart Recommendations
    
    /// Get related artifacts based on category and type
    func getRelatedArtifacts(for artifact: ArtifactModel, in allArtifacts: [ArtifactModel], limit: Int = 5) -> [ArtifactModel] {
        var related: [ArtifactModel] = []
        
        // Same subcategory
        if let subcategory = artifact.subcategory {
            related += allArtifacts.filter {
                $0.id != artifact.id &&
                $0.category == artifact.category &&
                $0.subcategory == subcategory
            }
        }
        
        // Same category
        related += allArtifacts.filter {
            $0.id != artifact.id &&
            $0.category == artifact.category &&
            !related.contains($0)
        }
        
        // Same type
        if let type = artifact.type {
            related += allArtifacts.filter {
                $0.id != artifact.id &&
                $0.type == type &&
                !related.contains($0)
            }
        }
        
        return Array(related.prefix(limit))
    }
    
    // MARK: - Statistics
    
    /// Get artifact statistics
    func getStatistics(for artifacts: [ArtifactModel]) -> ArtifactStatistics {
        ArtifactStatistics(
            total: artifacts.count,
            byCategory: Dictionary(grouping: artifacts) { $0.category }
                .mapValues { $0.count },
            byPlatform: Dictionary(grouping: artifacts) { $0.platform }
                .mapValues { $0.count },
            builtIn: artifacts.filter { $0.builtIn ?? false }.count,
            custom: artifacts.filter { !($0.builtIn ?? false) }.count,
            favorites: artifacts.filter { $0.isFavorite }.count,
            withParameters: artifacts.filter { ($0.parameters?.count ?? 0) > 0 }.count
        )
    }
}

// MARK: - Artifact Statistics

/// Statistics about artifacts
struct ArtifactStatistics: Sendable {
    let total: Int
    let byCategory: [ArtifactCategory: Int]
    let byPlatform: [ArtifactPlatform: Int]
    let builtIn: Int
    let custom: Int
    let favorites: Int
    let withParameters: Int
}

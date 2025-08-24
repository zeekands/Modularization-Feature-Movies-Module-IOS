//
//  MovieDetailViewModel.swift
//  FeatureMovies
//
//  Created by zeekands on 04/07/25.
//


import Foundation
import SharedDomain // Untuk MovieEntity, Use Cases, AppNavigatorProtocol
import SharedUI     // Untuk LoadingIndicator, ErrorView
import SwiftUI      // Untuk ObservableObject

@MainActor
public final class MovieDetailViewModel: ObservableObject {
    @Published public var movie: MovieEntity? // Detail film yang akan ditampilkan
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let movieId: Int // ID film yang sedang dilihat

    // Dependensi Use Case
    private let getMovieDetailUseCase: GetMovieDetailUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
    
    // Dependensi Navigasi
    private let appNavigator: AppNavigatorProtocol

    public init(
        movieId: Int,
        getMovieDetailUseCase: GetMovieDetailUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        appNavigator: AppNavigatorProtocol
    ) {
        self.movieId = movieId
        self.getMovieDetailUseCase = getMovieDetailUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.appNavigator = appNavigator

        Task {
            await loadMovieDetail() // Muat detail film saat ViewModel dibuat
        }
    }

    public func loadMovieDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            self.movie = try await getMovieDetailUseCase.execute(id: movieId)
        } catch {
            errorMessage = "Failed to load movie details: \(error.localizedDescription)"
            print("Error loading movie detail: \(error)")
        }
        isLoading = false
    }

    public func toggleFavorite() async {
        guard var currentMovie = movie else { return }
        do {
            try await toggleFavoriteUseCase.execute(movieId: currentMovie.id, isFavorite: !currentMovie.isFavorite)
            currentMovie.isFavorite.toggle() // Perbarui status favorit lokal
            self.movie = currentMovie // Memicu update UI
        } catch {
            errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
            print("Error toggling favorite: \(error)")
        }
    }

    // MARK: - Navigasi
    public func navigateBack() {
      appNavigator.pop(inTab: .movies) // Kembali di stack navigasi tab .movies
    }
    
    public func retryLoadMovieDetail() {
        Task {
            await loadMovieDetail()
        }
    }
}

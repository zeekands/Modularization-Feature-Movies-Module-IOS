//
//  MovieListViewModel.swift
//  FeatureMovies
//
//  Created by zeekands on 04/07/25.
//


import Foundation
import SharedDomain // Untuk MovieEntity, Use Cases, AppNavigatorProtocol
import SharedUI     // Untuk LoadingIndicator, ErrorView
import SwiftUI      // Untuk ObservableObject

@MainActor
public final class MovieListViewModel: ObservableObject {
  @Published public var movies: [MovieEntity] = []
  @Published public var isLoading: Bool = false
  @Published public var errorMessage: String? = nil
  
  // MARK: - Properti untuk Infinite Scrolling
  @Published public var currentPage: Int = 1 // Halaman saat ini
  @Published public var canLoadMorePages: Bool = true // Apakah ada halaman berikutnya untuk dimuat
  @Published public var isLoadingMore: Bool = false // Indikator loading untuk "load more"
  
  private let getPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol
  private let getTrendingMoviesUseCase: GetTrendingMoviesUseCaseProtocol
  private let getMovieDetailUseCase: GetMovieDetailUseCaseProtocol
  private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
  
  let appNavigator: AppNavigatorProtocol
  
  public init(
    getPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol,
    getTrendingMoviesUseCase: GetTrendingMoviesUseCaseProtocol,
    getMovieDetailUseCase: GetMovieDetailUseCaseProtocol,
    toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
    appNavigator: AppNavigatorProtocol
  ) {
    self.getPopularMoviesUseCase = getPopularMoviesUseCase
    self.getTrendingMoviesUseCase = getTrendingMoviesUseCase
    self.getMovieDetailUseCase = getMovieDetailUseCase
    self.toggleFavoriteUseCase = toggleFavoriteUseCase
    self.appNavigator = appNavigator
    
    // Hanya panggil loadMovies() secara default jika daftar kosong saat init
    // Ini memastikan kita tidak memuat ulang jika data sudah di-cache dari sebelumnya.
    if movies.isEmpty {
      Task { await loadMovies() }
    }
  }
  
  public func loadMovies(isInitialLoad: Bool = true) async {
    if isInitialLoad {
      guard movies.isEmpty || errorMessage != nil else { return } // Hanya muat awal jika kosong/ada error
      isLoading = true
      currentPage = 1 // Reset halaman ke 1 untuk pemuatan awal
      canLoadMorePages = true // Asumsikan bisa memuat lebih banyak
    } else {
      // Jika bukan pemuatan awal, cek apakah bisa memuat lebih banyak
      guard canLoadMorePages && !isLoadingMore else { return }
      isLoadingMore = true // Set indikator loading untuk "load more"
    }
    
    errorMessage = nil
    
    do {
      // Ambil film populer dan trending untuk halaman saat ini
      let popularMovies = try await getPopularMoviesUseCase.execute(page: currentPage)
      let trendingMovies = try await getTrendingMoviesUseCase.execute(page: currentPage)
      
      var newMovies: [MovieEntity] = []
      var seenIds: Set<Int> = Set(movies.map { $0.id }) // Lacak ID yang sudah ada di daftar 'movies' saat ini
      
      // Prioritaskan popular, lalu tambahkan trending jika belum terlihat
      for movie in popularMovies {
        if !seenIds.contains(movie.id) {
          newMovies.append(movie)
          seenIds.insert(movie.id)
        }
      }
      for movie in trendingMovies {
        if !seenIds.contains(movie.id) {
          newMovies.append(movie)
          seenIds.insert(movie.id)
        }
      }
      
      // Perbarui daftar film utama
      // Jika ini pemuatan awal, ganti semua film. Jika bukan, tambahkan film baru.
      if isInitialLoad {
        self.movies = newMovies.sorted { $0.title < $1.title }
      } else {
        // Tambahkan film baru ke daftar yang sudah ada
        self.movies.append(contentsOf: newMovies.sorted { $0.title < $1.title })
      }
      
      // Atur status `canLoadMorePages`
      // Ini adalah logika penting: jika jumlah film yang baru diambil kurang dari ukuran halaman yang diharapkan,
      // itu berarti kita sudah mencapai akhir data. Asumsikan ukuran halaman API adalah sekitar 20 per jenis.
      // Anda mungkin perlu menyesuaikan logika ini berdasarkan respons API yang sebenarnya.
      if popularMovies.count < 20 && trendingMovies.count < 20 { // Atau gabungan total
        canLoadMorePages = false
      } else {
        currentPage += 1 // Maju ke halaman berikutnya
      }
      
    } catch {
      errorMessage = "Failed to load movies: \(error.localizedDescription)"
      print("Error loading movies: \(error)")
      canLoadMorePages = false // Hentikan pemuatan jika ada error
    }
    
    if isInitialLoad {
      isLoading = false
    } else {
      isLoadingMore = false
    }
  }
  
  // MARK: - Metode untuk memuat halaman berikutnya
  public func loadNextPage() async {
    await loadMovies(isInitialLoad: false)
  }
  
  public func retryLoadMovies() {
    Task {
      currentPage = 1
      canLoadMorePages = true
      await loadMovies(isInitialLoad: true)
    }
  }
  
  
  public func toggleFavorite(movie: MovieEntity) async {
    do {
      try await toggleFavoriteUseCase.execute(movieId: movie.id, isFavorite: !movie.isFavorite)
      // Perbarui status favorit di daftar lokal tanpa me-reload penuh
      if let index = movies.firstIndex(where: { $0.id == movie.id }) {
        movies[index].isFavorite.toggle()
      }
    } catch {
      errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
      print("Error toggling favorite: \(error)")
    }
  }
  
  // MARK: - Navigasi
  public func navigateToMovieDetail(movieId: Int) {
    appNavigator.navigate(to: .movieDetail(movieId: movieId), inTab: .movies)
  }
  
  public func presentGlobalSearch() {
    appNavigator.navigate(to: .search, inTab: .movies, hideTabBar: true)
  }
  
  public func showSheet() {
    appNavigator.presentSheet(.search)
  }

}

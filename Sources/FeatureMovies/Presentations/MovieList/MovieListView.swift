//
//  MovieListView.swift
//  FeatureMovies
//
//  Created by zeekands on 04/07/25.
//


import SwiftUI
import SharedDomain // Untuk MovieEntity, AppRoute, AppTab
import SharedUI     // Untuk LoadingIndicator, ErrorView, PosterImageView

public struct MovieListView: View {
  @StateObject private var viewModel: MovieListViewModel
  
  public init(viewModel: MovieListViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    Group {
      if viewModel.isLoading {
        LoadingIndicator()
      } else if let errorMessage = viewModel.errorMessage {
        ErrorView(message: errorMessage, retryAction: viewModel.retryLoadMovies)
      } else if viewModel.movies.isEmpty && !viewModel.isLoadingMore { // Cek isLoadingMore juga
        ContentUnavailableView("No Movies Found", systemImage: "film.stack")
      } else {
        movieGrid // Pindah ke ScrollView dengan LazyVGrid
      }
    }
    .navigationTitle("Movies")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          viewModel.presentGlobalSearch()
        } label: {
          Image(systemName: "magnifyingglass")
        }
      }
    }
  }
  
  // MARK: - Movie Grid View
  private var movieGrid: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
        ForEach(viewModel.movies) { movie in
          MovieGridItemView(movie: movie)
            .onTapGesture {
              viewModel.navigateToMovieDetail(movieId: movie.id)
            }
            .contextMenu {
              Button {
                Task { await viewModel.toggleFavorite(movie: movie) }
              } label: {
                Label(movie.isFavorite ? "Unfavorite" : "Favorite", systemImage: movie.isFavorite ? "star.slash.fill" : "star.fill")
              }
            }
          // MARK: - Deteksi Scroll untuk Infinite Scrolling
            .onAppear {
              // Jika ini adalah item terakhir atau mendekati terakhir, muat halaman berikutnya
              if movie.id == viewModel.movies.last?.id {
                Task {
                  await viewModel.loadNextPage()
                }
              }
            }
        }
      }
      .padding()
      
      if viewModel.isLoadingMore {
        ProgressView()
          .padding()
      } else if !viewModel.canLoadMorePages && !viewModel.movies.isEmpty {
        // Tampilkan pesan "akhir daftar" jika tidak ada lagi halaman dan daftar tidak kosong
        Text("You've reached the end of the list.")
          .font(.caption)
          .foregroundColor(.gray)
          .padding()
      }
    }
  }
}

public struct MovieGridItemView: View {
  public let movie: MovieEntity
  
  public init(movie: MovieEntity) {
    self.movie = movie
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      PosterImageView(imagePath: movie.posterPath, imageType: .poster)
        .frame(height: 220)
        .cornerRadius(12)
        .shadow(radius: 5)
      
      Text(movie.title)
        .font(.headline)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.yellow)
        Text(String(format: "%.1f", movie.voteAverage ?? 0.0))
          .font(.caption)
          .foregroundColor(.textSecondary)
        Spacer()
        if movie.isFavorite {
          Image(systemName: "heart.fill")
            .foregroundColor(.red)
        }
      }
    }
    .padding(.bottom, 8)
  }
}

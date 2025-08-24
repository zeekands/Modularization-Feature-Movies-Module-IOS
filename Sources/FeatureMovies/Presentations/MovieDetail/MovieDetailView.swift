import SwiftUI
import SharedDomain // Untuk MovieEntity
import SharedUI     // Untuk LoadingIndicator, ErrorView, PosterImageView

@MainActor
public struct MovieDetailView: View {
  @StateObject private var viewModel: MovieDetailViewModel
  
  public init(viewModel: MovieDetailViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    Group{
      if viewModel.isLoading {
        LoadingIndicator()
      } else if let errorMessage = viewModel.errorMessage {
        ErrorView(message: errorMessage, retryAction: viewModel.retryLoadMovieDetail)
      } else if let movie = viewModel.movie {
        movieDetailContent(movie: movie)
      } else {
        ContentUnavailableView("Movie Not Found", systemImage: "tv.slash.fill")
      }
    }
    .navigationTitle(viewModel.movie?.title ?? "TV Show Detail")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if let movie = viewModel.movie {
          Button(action: {
            Task { await viewModel.toggleFavorite() }
          }) {
            Image(systemName: movie.isFavorite ? "heart.fill" : "heart")
              .foregroundColor(movie.isFavorite ? .red : .gray)
          }
        }
      }
    }
    .onAppear {
      Task { await viewModel.loadMovieDetail() }
    }
  }
  
  private func movieDetailContent(movie: MovieEntity) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // Poster dan Backdrop
        ZStack(alignment: .bottomLeading) {
          PosterImageView(imagePath: movie.backdropPath, imageType: .backdrop)
            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 250)
            .clipped()
          
          PosterImageView(imagePath: movie.posterPath, imageType: .poster)
            .frame(width: 120, height: 180)
            .cornerRadius(10)
            .shadow(radius: 8)
            .padding(.leading)
            .offset(y: 60) // Mengangkat poster di atas backdrop
        }
        .frame(maxHeight: 250) // Batasi tinggi ZStack
        .padding(.bottom, 60) // Padding untuk poster yang offset
        
        // Judul dan Info Utama
        VStack(alignment: .leading, spacing: 8) {
          Text(movie.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrimary)
          
          HStack {
            Image(systemName: "star.fill")
              .foregroundColor(.yellow)
            Text(String(format: "%.1f", movie.voteAverage ?? 0.0))
              .font(.caption)
              .foregroundColor(.textSecondary)
            
            if let firstAirDate = movie.releaseDate {
              Text("(\(firstAirDate.formatted(date: .numeric, time: .omitted)))")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
            
            // Genres
            if !movie.genres.isEmpty {
              Text(movie.genres.map { $0.name }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
          }
          
          Text(movie.overview ?? "No overview available.")
            .font(.body)
            .foregroundColor(.textPrimary)
            .padding(.top, 10)
        }
        .padding(.horizontal)
      }
    }
  }
}

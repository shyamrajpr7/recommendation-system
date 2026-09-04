class Movie {
  final int id;
  final String title;
  final String genre;
  final int year;
  final double rating;
  final String synopsis;
  final String director;

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.synopsis,
    required this.director,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      year: json['year'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      synopsis: json['synopsis'] ?? '',
      director: json['creator'] ?? json['director'] ?? '',
    );
  }
}

class Theater {
  final int id;
  final String name;
  final String city;
  final String screenName;

  Theater({
    required this.id,
    required this.name,
    required this.city,
    required this.screenName,
  });

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      screenName: json['screen_name'] ?? '',
    );
  }
}

class Showtime {
  final int id;
  final int movieId;
  final String movieTitle;
  final String movieGenre;
  final String theaterName;
  final String screenName;
  final String city;
  final String showDate;
  final String showTime;
  final double basePrice;
  final int availableSeats;

  Showtime({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.movieGenre,
    required this.theaterName,
    required this.screenName,
    required this.city,
    required this.showDate,
    required this.showTime,
    required this.basePrice,
    required this.availableSeats,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    return Showtime(
      id: json['id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      movieTitle: json['movie_title'] ?? '',
      movieGenre: json['movie_genre'] ?? '',
      theaterName: json['theater_name'] ?? '',
      screenName: json['screen_name'] ?? '',
      city: json['city'] ?? '',
      showDate: json['show_date'] ?? '',
      showTime: json['show_time'] ?? '',
      basePrice: (json['base_price'] ?? 0).toDouble(),
      availableSeats: json['available_seats'] ?? 0,
    );
  }
}

class SeatMap {
  final List<List<String>> seats;

  SeatMap({required this.seats});

  factory SeatMap.fromJson(Map<String, dynamic> json) {
    return SeatMap(
      seats: (json['seats'] as List)
          .map((row) => (row as List).map((s) => s.toString()).toList())
          .toList(),
    );
  }
}

class BookingResponse {
  final String bookingRef;
  final String movieTitle;
  final String movieGenre;
  final String theaterName;
  final String screenName;
  final String city;
  final String showDate;
  final String showTime;
  final List<String> seats;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final bool paymentMock;
  final String? paymentUrl;
  final bool paymentEnabled;

  BookingResponse({
    required this.bookingRef,
    required this.movieTitle,
    required this.movieGenre,
    required this.theaterName,
    required this.screenName,
    required this.city,
    required this.showDate,
    required this.showTime,
    required this.seats,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMock,
    this.paymentUrl,
    required this.paymentEnabled,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      bookingRef: json['booking_ref'] ?? '',
      movieTitle: json['movie_title'] ?? '',
      movieGenre: json['movie_genre'] ?? '',
      theaterName: json['theater_name'] ?? '',
      screenName: json['screen_name'] ?? '',
      city: json['city'] ?? '',
      showDate: json['show_date'] ?? '',
      showTime: json['show_time'] ?? '',
      seats: List<String>.from(json['seats'] ?? []),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMock: json['payment_mock'] ?? true,
      paymentUrl: json['payment_url'],
      paymentEnabled: json['payment_enabled'] ?? false,
    );
  }
}

class BookingVerifyResponse {
  final String bookingRef;
  final String status;
  final String paymentStatus;
  final String? paymentId;

  BookingVerifyResponse({
    required this.bookingRef,
    required this.status,
    required this.paymentStatus,
    this.paymentId,
  });

  factory BookingVerifyResponse.fromJson(Map<String, dynamic> json) {
    return BookingVerifyResponse(
      bookingRef: json['booking_ref'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentId: json['payment_id'],
    );
  }
}

class ChatResponse {
  final String reply;

  ChatResponse({required this.reply});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(reply: json['reply'] ?? '');
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cinema.dart';
import 'api_client.dart';

class CinemaService {
  final Dio _dio;
  CinemaService(this._dio);

  Future<List<Movie>> fetchMovies() async {
    final res = await _dio.get('/movies');
    return (res.data['movies'] as List).map((m) => Movie.fromJson(m)).toList();
  }

  Future<List<String>> fetchGenres() async {
    final res = await _dio.get('/genres');
    return List<String>.from(res.data['genres'] ?? []);
  }

  Future<List<Theater>> fetchTheaters() async {
    final res = await _dio.get('/theaters');
    return (res.data['theaters'] as List).map((t) => Theater.fromJson(t)).toList();
  }

  Future<List<String>> fetchDates() async {
    final res = await _dio.get('/dates');
    return List<String>.from(res.data['dates'] ?? []);
  }

  Future<List<Showtime>> fetchShowtimes({String? date}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    final res = await _dio.get('/showtimes', queryParameters: params);
    return (res.data['showtimes'] as List).map((s) => Showtime.fromJson(s)).toList();
  }

  Future<SeatMap> fetchSeats(int showtimeId) async {
    final res = await _dio.get('/seats', queryParameters: {'showtime_id': showtimeId});
    return SeatMap.fromJson(res.data);
  }

  Future<BookingResponse> createBooking({
    required int showtimeId,
    required String name,
    required String email,
    required List<String> seats,
  }) async {
    final res = await _dio.post('/bookings', data: {
      'showtime_id': showtimeId,
      'customer_name': name,
      'customer_email': email,
      'seats': seats,
    });
    return BookingResponse.fromJson(res.data);
  }

  Future<BookingResponse> fetchBooking(String ref) async {
    final res = await _dio.get('/bookings/$ref');
    return BookingResponse.fromJson(res.data);
  }

  Future<BookingVerifyResponse> verifyPayment(String bookingRef) async {
    final res = await _dio.post('/bookings/$bookingRef/verify', data: {
      'booking_ref': bookingRef,
    });
    return BookingVerifyResponse.fromJson(res.data);
  }

  Future<ChatResponse> chat(String message, List<Map<String, String>> history) async {
    final res = await _dio.post('/chat', data: {
      'message': message,
      'history': history,
    });
    return ChatResponse.fromJson(res.data);
  }
}

final cinemaServiceProvider = Provider<CinemaService>((ref) {
  return CinemaService(ref.watch(dioProvider));
});

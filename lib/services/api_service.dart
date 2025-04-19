import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final String _newsApiKey;
  late final String _weatherApiKey;
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _newsApiKey = dotenv.env['NEWS_API_KEY'] ?? '';
    _weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    
    if (_newsApiKey.isEmpty) {
      throw Exception('NEWS_API_KEY not found in environment variables');
    }
    if (_weatherApiKey.isEmpty) {
      throw Exception('WEATHER_API_KEY not found in environment variables');
    }
  }

  Future<Map<String, dynamic>> getNews(String query) async {
    try {
      final url = 'https://newsapi.org/v2/everything?q=${Uri.encodeComponent(query)}&sortBy=publishedAt&apiKey=$_newsApiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'articles': (data['articles'] as List).take(5).map((article) => {
            'title': article['title'],
            'description': article['description'],
            'url': article['url'],
            'publishedAt': article['publishedAt'],
            'source': article['source']['name'],
          }).toList(),
        };
      } else {
        print('News API error: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch news',
        };
      }
    } catch (e) {
      print('Error fetching news: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getWeather(String city) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city)}&appid=$_weatherApiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': {
            'temperature': data['main']['temp'],
            'feels_like': data['main']['feels_like'],
            'humidity': data['main']['humidity'],
            'description': data['weather'][0]['description'],
            'city': data['name'],
            'country': data['sys']['country'],
          },
        };
      } else {
        print('Weather API error: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch weather data',
        };
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
} 
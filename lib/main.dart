import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Previsao do Tempo',
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late String _apiKey;
  String _cityName = 'Sao Paulo';
  Map<String, dynamic> _weatherData = {};
  TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['API_KEY'] ?? '';
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final coordinatesResponse = await http.get(Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$_cityName&limit=1&appid=$_apiKey'));
    if (coordinatesResponse.statusCode == 200) {
      final coordinatesData = json.decode(coordinatesResponse.body);
      final lat = coordinatesData[0]['lat'];
      final lon = coordinatesData[0]['lon'];

      final weatherResponse = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&lang=pt_br&appid=$_apiKey&units=metric'));
      if (weatherResponse.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(weatherResponse.body);
        });
      } else {
        throw Exception('Falha ao obter clima');
      }
    } else {
      throw Exception('Falha ao obter as coordenadas');
    }
  }

  Future<void> _searchWeather(String cityName) async {
    final coordinatesResponse = await http.get(Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$cityName&limit=1&appid=$_apiKey'));
    if (coordinatesResponse.statusCode == 200) {
      final coordinatesData = json.decode(coordinatesResponse.body);
      if (coordinatesData.isEmpty) {
        // Se não houver dados para a cidade, exiba uma mensagem ou solicite ao usuário que tente novamente
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Erro'),
              content: Text('Cidade não encontrada. Por favor, tente novamente.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      final lat = coordinatesData[0]['lat'];
      final lon = coordinatesData[0]['lon'];

      final weatherResponse = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&lang=pt_br&appid=$_apiKey&units=metric'));
      if (weatherResponse.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(weatherResponse.body);
        });
      } else {
        throw Exception('Falha ao obter clima');
      }
    } else {
      throw Exception('Falha ao obter as coordenadas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previsao do Tempo'),
      ),
      body: Center(
        child: _weatherData.isNotEmpty
            ? _buildWeatherList()
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Digite o nome da cidade'),
                content: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Nome da cidade',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      String cityName = _cityController.text;
                      _searchWeather(cityName);
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.search),
      ),
    );
  }

  Widget _buildWeatherList() {
    return ListView.builder(
      itemCount: _weatherData['list'].length,
      itemBuilder: (context, index) {
        final weather = _weatherData['list'][index];
        final temp = weather['main']['temp'];
        final date = DateTime.fromMillisecondsSinceEpoch(weather['dt'] * 1000);
        final description = _capitalizeFirstLetter(weather['weather'][0]['description']); // Capitalize a descrição

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature: $temp °C',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                WeatherIcon(temp),
                Text(
                  '$description - ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return '';
    }
    return input.substring(0, 1).toUpperCase() + input.substring(1);
  }
}

class WeatherIcon extends StatelessWidget {
  final double temperature;

  WeatherIcon(this.temperature);

  @override
  Widget build(BuildContext context) {
    if (temperature > 25) {
      return Icon(Icons.wb_sunny);
    } else if (temperature < 15) {
      return Icon(Icons.ac_unit);
    } else {
      return Icon(Icons.cloud);
    }
  }
}

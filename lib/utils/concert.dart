import '../utils/globals.dart';

class Concert {
  late String title;
  late int id;
  late String maestro;
  late List<String> performers;
  late List<String> tags;
  late String description;
  late String date;


  Concert({this.title = '', this.id = -1, this.maestro = '', this.performers = const [], this.tags = const [], this.description = '', this.date = '',});

  static Concert songFromJson(Map<String, dynamic> json) {
    String title = json.containsKey('title') ? json['title'] : '';
    int id = json['id'];
    String maestro = json.containsKey('maestro') ? json['maestro'] : '';

    List<String> perfs = [];
    if (json.containsKey('performers')) {
      perfs = (json['performers'] as List).map((entry) => entry as String).toList();
    }

    List<String> tags = [];
    if (json.containsKey('tags')) {
      tags = (json['tags'] as List).map((entry) => entry as String).toList();
    }

    String description = json.containsKey('description') ? json['description'] : '';
    String date = json.containsKey('date') ? json['date'] : '';
    Concert newConcert = Concert(title: title, id: id, maestro: maestro, performers: perfs, tags: tags, description: description, date: date);
    return newConcert;
  }

  String toString() {
    String concert = 'Title: ${this.title}\nID: ${this.id}\nPerformers: ${this.performers}\nTags: ${this.tags}\nDescription: ${this.description}\nDate: ${this.date}';
    return concert;
  }
}

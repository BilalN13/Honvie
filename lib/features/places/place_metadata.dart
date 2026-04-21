import 'package:flutter/material.dart';

abstract final class PlaceMetadata {
  static const List<String> selectableTypes = <String>[
    'cafe calme',
    'cafe',
    'parc',
    'musee',
    'atelier',
    'expo',
    'librairie',
    'cinema',
    'bar',
    'evenement',
    'bord de mer',
  ];

  static List<String> expandInternalTypes(String type) {
    switch (type) {
      case 'cafe calme':
        return const <String>['cafe calme', 'cafe'];
      case 'cafe':
        return const <String>['cafe', 'cafe calme'];
      case 'parc':
        return const <String>['parc', 'nature'];
      case 'musee':
        return const <String>['musee'];
      case 'atelier':
        return const <String>['atelier', 'expo'];
      case 'expo':
        return const <String>['expo', 'atelier'];
      case 'librairie':
        return const <String>['librairie'];
      case 'cinema':
        return const <String>['cinema'];
      case 'bar':
        return const <String>['bar', 'cafe'];
      case 'evenement':
        return const <String>['evenement'];
      case 'bord de mer':
        return const <String>['bord de mer', 'nature'];
      default:
        return <String>[type];
    }
  }

  static String categoryLabel({
    String? primaryType,
    required List<String> internalTypes,
  }) {
    if (internalTypes.contains('cafe calme') ||
        internalTypes.contains('cafe')) {
      return 'Cafe';
    }
    if (internalTypes.contains('parc') || internalTypes.contains('nature')) {
      return 'Nature';
    }
    if (internalTypes.contains('musee')) {
      return 'Culture';
    }
    if (internalTypes.contains('atelier') || internalTypes.contains('expo')) {
      return 'Creative';
    }
    if (internalTypes.contains('librairie')) {
      return 'Books';
    }
    if (internalTypes.contains('cinema')) {
      return 'Cinema';
    }
    if (internalTypes.contains('bar') || internalTypes.contains('evenement')) {
      return 'Meetup';
    }
    if (internalTypes.contains('bord de mer')) {
      return 'Coast';
    }

    switch (primaryType) {
      case 'museum':
        return 'Culture';
      case 'park':
        return 'Nature';
      case 'movie_theater':
        return 'Cinema';
      case 'book_store':
        return 'Books';
      default:
        return 'Place';
    }
  }

  static IconData iconForTypes(List<String> internalTypes) {
    if (internalTypes.contains('cafe calme') ||
        internalTypes.contains('cafe')) {
      return Icons.local_cafe_rounded;
    }
    if (internalTypes.contains('parc') || internalTypes.contains('nature')) {
      return Icons.park_rounded;
    }
    if (internalTypes.contains('musee')) {
      return Icons.museum_rounded;
    }
    if (internalTypes.contains('atelier') || internalTypes.contains('expo')) {
      return Icons.palette_rounded;
    }
    if (internalTypes.contains('librairie')) {
      return Icons.menu_book_rounded;
    }
    if (internalTypes.contains('cinema')) {
      return Icons.local_movies_rounded;
    }
    if (internalTypes.contains('bord de mer')) {
      return Icons.waves_rounded;
    }
    if (internalTypes.contains('bar') || internalTypes.contains('evenement')) {
      return Icons.groups_rounded;
    }

    return Icons.place_rounded;
  }

  static String labelForType(String type) {
    switch (type) {
      case 'cafe calme':
        return 'Cafe calme';
      case 'cafe':
        return 'Cafe';
      case 'parc':
        return 'Parc';
      case 'musee':
        return 'Musee';
      case 'atelier':
        return 'Atelier';
      case 'expo':
        return 'Expo';
      case 'librairie':
        return 'Librairie';
      case 'cinema':
        return 'Cinema';
      case 'bar':
        return 'Bar';
      case 'evenement':
        return 'Evenement';
      case 'bord de mer':
        return 'Bord de mer';
      default:
        return type;
    }
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckinMappings {
  const CheckinMappings._();

  static String emojiForEmotion(String? emotion) {
    switch (emotion) {
      case 'enerve':
        return '\u{1F620}';
      case 'triste':
        return '\u{1F614}';
      case 'neutre':
        return '\u{1F610}';
      case 'content':
        return '\u{1F642}';
      case 'joyeux':
        return '\u{1F604}';
      default:
        return '\u{1F642}';
    }
  }

  static String labelForEmotion(String? emotion) {
    switch (emotion) {
      case 'enerve':
        return 'Enerve';
      case 'triste':
        return 'Triste';
      case 'neutre':
        return 'Neutre';
      case 'content':
        return 'Content';
      case 'joyeux':
        return 'Joyeux';
      default:
        return 'Check-in';
    }
  }

  static String labelForDesiredEmotion(String? emotion) {
    switch (emotion) {
      case 'motive':
        return 'motive';
      case 'pose':
        return 'pose';
      case 'curieux':
        return 'curieux';
      case 'creatif':
        return 'creatif';
      case 'social':
        return 'social';
      case 'introspectif':
        return 'introspectif';
      default:
        return 'apaise';
    }
  }

  static Color colorForEmotion(String? emotion) {
    switch (emotion) {
      case 'enerve':
        return AppColors.error;
      case 'triste':
        return AppColors.info;
      case 'neutre':
        return AppColors.lavender;
      case 'content':
        return AppColors.success;
      case 'joyeux':
        return AppColors.primaryOrange;
      default:
        return AppColors.primaryPink;
    }
  }

  static String summaryForReasons(List<String> reasons) {
    if (reasons.isEmpty) {
      return 'Aucune raison renseignee';
    }
    if (reasons.length == 1) {
      return reasons.first;
    }
    if (reasons.length == 2) {
      return '${reasons.first}, ${reasons.last}';
    }

    return '${reasons[0]}, ${reasons[1]} +${reasons.length - 2}';
  }

  static String associatedText({
    required String? currentEmotion,
    required List<String> reasons,
    required String? desiredEmotion,
  }) {
    final reasonSummary = summaryForReasons(reasons);

    switch (currentEmotion) {
      case 'enerve':
        return '$reasonSummary. Besoin de retrouver un peu de ${labelForDesiredEmotion(desiredEmotion)}.';
      case 'triste':
        return '$reasonSummary. Une dose de douceur peut aider.';
      case 'neutre':
        return '$reasonSummary. Un petit elan peut faire la difference.';
      case 'content':
        return '$reasonSummary. Une belle base a prolonger.';
      case 'joyeux':
        return '$reasonSummary. Une energie positive a cultiver.';
      default:
        return '$reasonSummary. Ton ressenti du jour apparaitra ici.';
    }
  }

  static String validationMessage({
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
  }) {
    if (currentEmotion == 'neutre' && desiredEmotion == 'social') {
      return 'Tu veux t ouvrir un peu plus aujourd hui, c est un bon pas.';
    }
    if (currentEmotion == 'enerve' && desiredEmotion == 'pose') {
      return 'Tu prends le temps de ralentir, c est exactement ce qu il te faut.';
    }
    if (currentEmotion == 'triste' && activity == 'respiration') {
      return 'Tu prends soin de toi aujourd hui, meme doucement.';
    }
    if (currentEmotion == 'triste' && desiredEmotion == 'pose') {
      return 'Tu cherches du calme avec douceur, c est une bonne direction.';
    }
    if (currentEmotion == 'content' && desiredEmotion == 'creatif') {
      return 'Tu t appuies sur une bonne energie pour aller vers quelque chose de vivant.';
    }
    if (currentEmotion == 'joyeux' && desiredEmotion == 'social') {
      return 'Tu prolonges une belle energie vers le lien, c est tres juste.';
    }
    if (activity == 'respiration') {
      return 'Tu choisis de revenir a toi, c est deja un vrai geste pour aujourd hui.';
    }
    if (activity == 'marcher') {
      return 'Tu te remets doucement en mouvement, cela peut vraiment alleger ta journee.';
    }
    if (desiredEmotion != null) {
      return 'Tu identifies ce dont tu as besoin maintenant, et c est deja utile.';
    }

    return 'Tu prends un moment pour toi aujourd hui, et cela compte vraiment.';
  }

  static String validationSuggestion(String? activity) {
    switch (activity) {
      case 'marcher':
        return 'Pourquoi ne pas commencer par une courte marche maintenant ?';
      case 'cafe calme':
        return 'Pourquoi ne pas te poser dans un endroit calme des maintenant ?';
      case 'musee':
        return 'Pourquoi ne pas chercher un lieu inspirant pour changer d ambiance ?';
      case 'lecture':
        return 'Pourquoi ne pas ouvrir quelques pages tout de suite ?';
      case 'ecrire':
        return 'Pourquoi ne pas noter en quelques mots ce que tu ressens maintenant ?';
      case 'bord de mer':
        return 'Pourquoi ne pas te rapprocher d un endroit qui te donne de l espace ?';
      case 'cinema':
        return 'Pourquoi ne pas t offrir une vraie pause pour decrocher un peu ?';
      case 'respiration':
        return 'Pourquoi ne pas commencer maintenant par trois respirations lentes ?';
      case 'pause gourmande':
        return 'Pourquoi ne pas commencer par une petite pause reconfortante ?';
      default:
        return 'Pourquoi ne pas commencer maintenant ?';
    }
  }
}

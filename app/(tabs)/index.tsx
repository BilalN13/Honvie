import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { Heart, Clock, Target, MapPin, Star, Coffee, Trees, Leaf, Sparkles } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

const MOODS = [
  { emoji: '😊', label: 'Joyeux', color: '#FFE4B5' },
  { emoji: '😌', label: 'Serein', color: '#B8E6D3' },
  { emoji: '😔', label: 'Triste', color: '#E6D3F7' },
  { emoji: '😰', label: 'Stressé', color: '#FFB6C1' },
  { emoji: '🤗', label: 'Reconnaissant', color: '#F0E68C' },
];

const PLACES = [
  {
    id: 1,
    name: 'Café des Lumières',
    description: 'Un café cozy parfait pour lire ou travailler en solo',
    address: '12 rue de la Paix, Paris',
    rating: 4.5,
    icon: Coffee,
    color: '#FFE4B5',
    badge: 'Solo-friendly',
  },
  {
    id: 2,
    name: 'Parc des Buttes-Chaumont',
    description: 'Un magnifique parc pour une balade contemplative',
    address: '1 rue Botzaris, Paris',
    rating: 4.8,
    icon: Trees,
    color: '#B8E6D3',
    badge: 'Solo-friendly',
  },
  {
    id: 3,
    name: 'Jardin du Luxembourg',
    description: 'Magnifique jardin pour se ressourcer en pleine nature',
    address: 'Rue de Médicis, Paris',
    rating: 4.9,
    icon: Leaf,
    color: '#E6D3F7',
    badge: 'Solo-friendly',
  },
];

export default function HomeScreen() {
  const [selectedMood, setSelectedMood] = useState<string>('😊');

  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['#F8B2DD', '#E6D3F7']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.header}
      >
        <View style={styles.headerContent}>
          <View style={styles.logoContainer}>
            <Heart color="#FFFFFF" size={24} />
            <Text style={styles.logo}>HonVie</Text>
          </View>
          <TouchableOpacity style={styles.connectButton}>
            <Text style={styles.connectText}>Se connecter</Text>
          </TouchableOpacity>
        </View>
      </LinearGradient>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Mood Selection */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Comment vous sentez-vous aujourd'hui ?</Text>
          <View style={styles.moodContainer}>
            {MOODS.map((mood) => (
              <TouchableOpacity
                key={mood.emoji}
                style={[
                  styles.moodButton,
                  { backgroundColor: mood.color },
                  selectedMood === mood.emoji && styles.selectedMood,
                ]}
                onPress={() => setSelectedMood(mood.emoji)}
              >
                <Text style={styles.moodEmoji}>{mood.emoji}</Text>
                <Text style={styles.moodLabel}>{mood.label}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Daily Challenge */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionTitleRow}>
              <Sparkles color="#4ADE80" size={20} />
              <Text style={styles.sectionTitle}>Défi du jour</Text>
            </View>
            <Text style={styles.difficultyTag}>facile</Text>
          </View>
          
          <View style={styles.challengeCard}>
            <Text style={styles.challengeTitle}>Méditation de 10 minutes</Text>
            <Text style={styles.challengeDescription}>
              Prenez un moment pour vous recentrer avec une méditation guidée. 
              Trouvez un endroit calme et laissez-vous porter par votre respiration.
            </Text>
            <View style={styles.challengeDetails}>
              <View style={styles.challengeTag}>
                <Clock color="#6B7280" size={16} />
                <Text style={styles.challengeTagText}>10 min</Text>
              </View>
              <View style={styles.challengeTag}>
                <Target color="#6B7280" size={16} />
                <Text style={styles.challengeTagText}>méditation</Text>
              </View>
            </View>
            <TouchableOpacity style={styles.challengeButton}>
              <Text style={styles.challengeButtonText}>Relever le défi</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Nearby Places */}
        <View style={styles.section}>
          <View style={styles.sectionTitleRow}>
            <MapPin color="#F8B2DD" size={20} />
            <Text style={styles.sectionTitle}>Lieux à proximité</Text>
          </View>
          
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.placesContainer}>
            {PLACES.map((place) => (
              <View key={place.id} style={styles.placeCard}>
                <View style={[styles.placeIcon, { backgroundColor: place.color }]}>
                  <place.icon color="#4B5563" size={24} />
                </View>
                <Text style={styles.placeName}>{place.name}</Text>
                <Text style={styles.placeDescription}>{place.description}</Text>
                <View style={styles.placeDetails}>
                  <MapPin color="#6B7280" size={14} />
                  <Text style={styles.placeAddress}>{place.address}</Text>
                </View>
                <View style={styles.placeFooter}>
                  <View style={styles.ratingContainer}>
                    <Star color="#FCD34D" size={16} fill="#FCD34D" />
                    <Text style={styles.rating}>{place.rating}</Text>
                  </View>
                  <View style={styles.badge}>
                    <Text style={styles.badgeText}>{place.badge}</Text>
                  </View>
                </View>
              </View>
            ))}
          </ScrollView>
        </View>

        {/* Statistics */}
        <View style={styles.section}>
          <View style={styles.statsContainer}>
            <View style={styles.statCard}>
              <Text style={styles.statNumber}>7</Text>
              <Text style={styles.statLabel}>Jours consécutifs</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statNumber}>12</Text>
              <Text style={styles.statLabel}>Défis relevés</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statNumber}>5</Text>
              <Text style={styles.statLabel}>Lieux visités</Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    paddingVertical: 20,
    paddingHorizontal: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  logo: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  connectButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  connectText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  section: {
    marginBottom: 32,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  difficultyTag: {
    backgroundColor: '#D1FAE5',
    color: '#065F46',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    fontSize: 12,
    fontWeight: '500',
  },
  moodContainer: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 16,
  },
  moodButton: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedMood: {
    borderColor: '#F8B2DD',
  },
  moodEmoji: {
    fontSize: 24,
    marginBottom: 4,
  },
  moodLabel: {
    fontSize: 12,
    fontWeight: '500',
    color: '#374151',
  },
  challengeCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  challengeTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 8,
  },
  challengeDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
    marginBottom: 16,
  },
  challengeDetails: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 16,
  },
  challengeTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  challengeTagText: {
    fontSize: 12,
    color: '#6B7280',
  },
  challengeButton: {
    backgroundColor: '#F8B2DD',
    paddingVertical: 12,
    borderRadius: 16,
    alignItems: 'center',
  },
  challengeButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  placesContainer: {
    marginTop: 16,
  },
  placeCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    marginRight: 16,
    width: 280,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  placeIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  placeName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 4,
  },
  placeDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 18,
    marginBottom: 8,
  },
  placeDetails: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 12,
  },
  placeAddress: {
    fontSize: 12,
    color: '#9CA3AF',
  },
  placeFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  rating: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  badge: {
    backgroundColor: '#D1FAE5',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  badgeText: {
    fontSize: 12,
    color: '#065F46',
    fontWeight: '500',
  },
  statsContainer: {
    flexDirection: 'row',
    gap: 16,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  statNumber: {
    fontSize: 28,
    fontWeight: '700',
    color: '#F8B2DD',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
});
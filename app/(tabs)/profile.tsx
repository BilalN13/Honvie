import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { Heart, User, Settings, ChartBar as BarChart3, Calendar, MapPin, Target } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

const MOOD_HISTORY = [
  { date: 'Lun', mood: '😊' },
  { date: 'Mar', mood: '😌' },
  { date: 'Mer', mood: '😊' },
  { date: 'Jeu', mood: '🤗' },
  { date: 'Ven', mood: '😊' },
  { date: 'Sam', mood: '😌' },
  { date: 'Dim', mood: '😊' },
];

const INTERESTS = [
  'Méditation', 'Lecture', 'Marche', 'Café', 'Nature', 'Art', 'Musique', 'Yoga'
];

export default function ProfileScreen() {
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
        {/* Profile Header */}
        <View style={styles.profileHeader}>
          <View style={styles.avatarContainer}>
            <User color="#9CA3AF" size={40} />
          </View>
          <Text style={styles.userName}>Utilisateur Solo</Text>
          <Text style={styles.userSubtitle}>Membre depuis janvier 2024</Text>
        </View>

        {/* Stats Overview */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Votre progression</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Calendar color="#F8B2DD" size={24} />
              <Text style={styles.statNumber}>7</Text>
              <Text style={styles.statLabel}>Jours consécutifs</Text>
            </View>
            <View style={styles.statCard}>
              <Target color="#10B981" size={24} />
              <Text style={styles.statNumber}>12</Text>
              <Text style={styles.statLabel}>Défis relevés</Text>
            </View>
            <View style={styles.statCard}>
              <MapPin color="#F59E0B" size={24} />
              <Text style={styles.statNumber}>5</Text>
              <Text style={styles.statLabel}>Lieux visités</Text>
            </View>
          </View>
        </View>

        {/* Mood Tracking */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Suivi émotionnel</Text>
            <TouchableOpacity>
              <BarChart3 color="#6B7280" size={20} />
            </TouchableOpacity>
          </View>
          <View style={styles.moodGrid}>
            {MOOD_HISTORY.map((day, index) => (
              <View key={index} style={styles.moodDay}>
                <Text style={styles.moodEmoji}>{day.mood}</Text>
                <Text style={styles.moodDate}>{day.date}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Interests */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Vos intérêts</Text>
          <View style={styles.interestsContainer}>
            {INTERESTS.map((interest, index) => (
              <View key={index} style={styles.interestTag}>
                <Text style={styles.interestText}>{interest}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Settings */}
        <View style={styles.section}>
          <TouchableOpacity style={styles.settingsButton}>
            <Settings color="#6B7280" size={20} />
            <Text style={styles.settingsText}>Paramètres du compte</Text>
          </TouchableOpacity>
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
  profileHeader: {
    alignItems: 'center',
    marginBottom: 32,
  },
  avatarContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#F3F4F6',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  userName: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 4,
  },
  userSubtitle: {
    fontSize: 14,
    color: '#6B7280',
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
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  statsGrid: {
    flexDirection: 'row',
    gap: 16,
    marginTop: 16,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  statNumber: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1F2937',
    marginVertical: 8,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  moodGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  moodDay: {
    alignItems: 'center',
  },
  moodEmoji: {
    fontSize: 24,
    marginBottom: 8,
  },
  moodDate: {
    fontSize: 12,
    color: '#6B7280',
  },
  interestsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 16,
  },
  interestTag: {
    backgroundColor: '#F3E8FF',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  interestText: {
    fontSize: 12,
    color: '#7C3AED',
    fontWeight: '500',
  },
  settingsButton: {
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderRadius: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  settingsText: {
    fontSize: 16,
    color: '#1F2937',
    fontWeight: '500',
  },
});
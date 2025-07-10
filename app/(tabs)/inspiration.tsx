import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { Heart, Sparkles, RefreshCw, Clock, Target, Sun, Heart as HeartIcon, Lightbulb, Smile } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

const INSPIRATION_CATEGORIES = [
  { id: 1, name: 'Motivation', icon: Target, color: '#F87171' },
  { id: 2, name: 'Sérénité', icon: Sun, color: '#FBBF24' },
  { id: 3, name: 'Créativité', icon: Lightbulb, color: '#F472B6' },
  { id: 4, name: 'Confiance', icon: Smile, color: '#FBBF24' },
];

const WELLNESS_TIPS = [
  {
    id: 1,
    title: 'Routine matinale',
    description: 'Commencez chaque journée par une routine qui vous fait du bien : méditation, étirements, ou simplement savourer votre café.',
    icon: Sun,
    color: '#FEF3C7',
  },
  {
    id: 2,
    title: 'Temps pour soi',
    description: 'Accordez-vous du temps chaque jour pour une activité qui vous plaît, sans culpabilité.',
    icon: HeartIcon,
    color: '#E0E7FF',
  },
];

export default function InspirationScreen() {
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
        <View style={styles.titleContainer}>
          <Sparkles color="#A855F7" size={24} />
          <Text style={styles.screenTitle}>Inspiration</Text>
        </View>
        
        <Text style={styles.subtitle}>
          Trouvez votre dose quotidienne de motivation et de bien-être
        </Text>

        {/* Inspirational Quote */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Citation inspirante</Text>
            <TouchableOpacity style={styles.refreshButton}>
              <RefreshCw color="#6B7280" size={18} />
              <Text style={styles.refreshText}>Nouvelle</Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.quoteCard}>
            <View style={styles.quoteIconContainer}>
              <Text style={styles.quoteIcon}>"</Text>
            </View>
            <Text style={styles.quoteText}>
              "La solitude est le moment où vous découvrez qui vous êtes vraiment."
            </Text>
            <Text style={styles.quoteAuthor}>— Mandy Hale</Text>
          </View>
        </View>

        {/* Daily Challenge */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Roppëï</Text>
            <TouchableOpacity style={styles.refreshButton}>
              <RefreshCw color="#6B7280" size={18} />
              <Text style={styles.refreshText}>Nouvelle</Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.challengeCard}>
            <View style={styles.challengeHeader}>
              <View style={styles.challengeIconContainer}>
                <HeartIcon color="#10B981" size={24} />
              </View>
              <Text style={styles.challengeTitle}>Méditation matinale</Text>
            </View>
            <Text style={styles.challengeDescription}>
              Commencez votre journée par 10 minutes de méditation guidée
            </Text>
            <View style={styles.challengeTags}>
              <View style={styles.challengeTag}>
                <Text style={styles.challengeTagText}>10 min</Text>
              </View>
              <View style={styles.challengeTag}>
                <Text style={styles.challengeTagText}>Facile</Text>
              </View>
              <View style={styles.challengeTag}>
                <Text style={styles.challengeTagText}>Mental</Text>
              </View>
            </View>
          </View>
        </View>

        {/* Wellness Tips */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Conseils bien-être</Text>
          
          <View style={styles.tipsContainer}>
            {WELLNESS_TIPS.map((tip) => (
              <View key={tip.id} style={styles.tipCard}>
                <View style={[styles.tipIcon, { backgroundColor: tip.color }]}>
                  <tip.icon color="#4B5563" size={20} />
                </View>
                <View style={styles.tipContent}>
                  <Text style={styles.tipTitle}>{tip.title}</Text>
                  <Text style={styles.tipDescription}>{tip.description}</Text>
                </View>
              </View>
            ))}
          </View>
        </View>

        {/* Inspiration Categories */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Catégories d'inspiration</Text>
          
          <View style={styles.categoriesContainer}>
            {INSPIRATION_CATEGORIES.map((category) => (
              <TouchableOpacity key={category.id} style={styles.categoryCard}>
                <View style={[styles.categoryIcon, { backgroundColor: `${category.color}30` }]}>
                  <category.icon color={category.color} size={24} />
                </View>
                <Text style={styles.categoryName}>{category.name}</Text>
              </TouchableOpacity>
            ))}
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
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 8,
  },
  screenTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1F2937',
  },
  subtitle: {
    fontSize: 16,
    color: '#6B7280',
    marginBottom: 32,
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
    fontSize: 20,
    fontWeight: '600',
    color: '#1F2937',
  },
  refreshButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  refreshText: {
    fontSize: 14,
    color: '#6B7280',
  },
  quoteCard: {
    backgroundColor: '#F3E8FF',
    borderRadius: 20,
    padding: 24,
    borderLeftWidth: 4,
    borderLeftColor: '#A855F7',
  },
  quoteIconContainer: {
    marginBottom: 12,
  },
  quoteIcon: {
    fontSize: 32,
    color: '#A855F7',
    fontWeight: 'bold',
  },
  quoteText: {
    fontSize: 16,
    color: '#1F2937',
    fontStyle: 'italic',
    lineHeight: 24,
    marginBottom: 12,
  },
  quoteAuthor: {
    fontSize: 14,
    color: '#A855F7',
    fontWeight: '600',
  },
  challengeCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#10B981',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  challengeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  challengeIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: '#D1FAE5',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  challengeTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  challengeDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
    marginBottom: 16,
  },
  challengeTags: {
    flexDirection: 'row',
    gap: 8,
  },
  challengeTag: {
    backgroundColor: '#D1FAE5',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  challengeTagText: {
    fontSize: 12,
    color: '#065F46',
    fontWeight: '500',
  },
  tipsContainer: {
    gap: 16,
    marginTop: 16,
  },
  tipCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    flexDirection: 'row',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  tipIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  tipContent: {
    flex: 1,
  },
  tipTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 4,
  },
  tipDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
  },
  categoriesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    marginTop: 16,
  },
  categoryCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    width: '45%',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  categoryIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  categoryName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
});
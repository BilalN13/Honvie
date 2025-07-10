import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { Heart, Users, Share2, MessageCircle, ThumbsUp, User } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

const COMMUNITY_POSTS = [
  {
    id: 1,
    author: 'Anonyme',
    date: '15 janvier 2024',
    type: 'expérience',
    title: 'Ma première sortie solo au restaurant',
    content: "J'ai enfin osé aller au restaurant seule hier soir. Au début j'étais nerveuse, mais finalement j'ai passé un excellent moment à savourer mon repas en toute tranquillité...",
    likes: 24,
    comments: 8,
    typeColor: '#E0E7FF',
    typeTextColor: '#3730A3',
  },
  {
    id: 2,
    author: 'Anonyme',
    date: '14 janvier 2024',
    type: 'conseil',
    title: "L'art de profiter de son temps libre",
    content: "Voici mes conseils pour transformer vos moments de solitude en véritables bulles de bien-être. D'abord, créez-vous un espace cozy...",
    likes: 18,
    comments: 5,
    typeColor: '#D1FAE5',
    typeTextColor: '#065F46',
  },
  {
    id: 3,
    author: 'Anonyme',
    date: '13 janvier 2024',
    type: 'inspiration',
    title: "La beauté d'un weekend solo",
    content: "Ce weekend, j'ai décidé de m'offrir une journée complète rien que pour moi. Réveil tardif, petit-déjeuner au lit, lecture...",
    likes: 32,
    comments: 12,
    typeColor: '#FEF3C7',
    typeTextColor: '#92400E',
  },
];

export default function CommunityScreen() {
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
          <Users color="#A855F7" size={24} />
          <Text style={styles.screenTitle}>Communauté</Text>
        </View>
        
        <Text style={styles.subtitle}>
          Partagez vos expériences et inspirez-vous des autres
        </Text>

        {/* Share Button */}
        <TouchableOpacity style={styles.shareButton}>
          <Share2 color="#FFFFFF" size={20} />
          <Text style={styles.shareButtonText}>Partager mon histoire</Text>
        </TouchableOpacity>

        {/* Community Posts */}
        <View style={styles.postsContainer}>
          {COMMUNITY_POSTS.map((post) => (
            <View key={post.id} style={styles.postCard}>
              <View style={styles.postHeader}>
                <View style={styles.authorContainer}>
                  <View style={styles.avatarContainer}>
                    <User color="#9CA3AF" size={20} />
                  </View>
                  <View style={styles.authorInfo}>
                    <Text style={styles.authorName}>{post.author}</Text>
                    <Text style={styles.postDate}>{post.date}</Text>
                  </View>
                </View>
                <View style={[styles.typeTag, { backgroundColor: post.typeColor }]}>
                  <Text style={[styles.typeTagText, { color: post.typeTextColor }]}>
                    {post.type}
                  </Text>
                </View>
              </View>
              
              <Text style={styles.postTitle}>{post.title}</Text>
              <Text style={styles.postContent}>{post.content}</Text>
              
              <View style={styles.postFooter}>
                <View style={styles.interactions}>
                  <TouchableOpacity style={styles.interactionButton}>
                    <ThumbsUp color="#6B7280" size={18} />
                    <Text style={styles.interactionText}>{post.likes}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.interactionButton}>
                    <MessageCircle color="#6B7280" size={18} />
                    <Text style={styles.interactionText}>{post.comments}</Text>
                  </TouchableOpacity>
                </View>
                <TouchableOpacity style={styles.moreButton}>
                  <Share2 color="#6B7280" size={18} />
                </TouchableOpacity>
              </View>
            </View>
          ))}
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
    marginBottom: 24,
  },
  shareButton: {
    backgroundColor: '#F8B2DD',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 16,
    borderRadius: 20,
    marginBottom: 32,
  },
  shareButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  postsContainer: {
    gap: 20,
  },
  postCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  postHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  authorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  avatarContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    alignItems: 'center',
    justifyContent: 'center',
  },
  authorInfo: {
    flex: 1,
  },
  authorName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  postDate: {
    fontSize: 12,
    color: '#9CA3AF',
  },
  typeTag: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  typeTagText: {
    fontSize: 12,
    fontWeight: '500',
  },
  postTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  postContent: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
    marginBottom: 16,
  },
  postFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  interactions: {
    flexDirection: 'row',
    gap: 20,
  },
  interactionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  interactionText: {
    fontSize: 14,
    color: '#6B7280',
  },
  moreButton: {
    padding: 4,
  },
});
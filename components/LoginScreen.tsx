import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { Heart, Mail } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

interface LoginScreenProps {
  onLogin: () => void;
}

export default function LoginScreen({ onLogin }: LoginScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['#B8E6D3', '#E6D3F7']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        <View style={styles.content}>
          <View style={styles.logoContainer}>
            <Heart color="#FFFFFF" size={48} />
            <Text style={styles.logo}>HonVie</Text>
            <Text style={styles.slogan}>L'art de vivre en solo</Text>
          </View>

          <View style={styles.welcomeContainer}>
            <Text style={styles.welcomeTitle}>Bienvenue</Text>
            <Text style={styles.welcomeSubtitle}>
              Rejoignez une communauté bienveillante dédiée à l'épanouissement en solo
            </Text>
          </View>

          <View style={styles.buttonsContainer}>
            <TouchableOpacity style={styles.socialButton} onPress={onLogin}>
              <Text style={styles.socialButtonText}>Se connecter avec Google</Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={styles.socialButton} onPress={onLogin}>
              <Text style={styles.socialButtonText}>Se connecter avec Facebook</Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={styles.emailButton} onPress={onLogin}>
              <Mail color="#6B7280" size={20} />
              <Text style={styles.emailButtonText}>Créer un compte</Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity style={styles.exampleLink}>
            <Text style={styles.exampleLinkText}>Citer un exemple d'usage</Text>
          </TouchableOpacity>
        </View>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 40,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 48,
  },
  logo: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 16,
    marginBottom: 8,
  },
  slogan: {
    fontSize: 16,
    color: '#FFFFFF',
    opacity: 0.9,
  },
  welcomeContainer: {
    marginBottom: 48,
  },
  welcomeTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 12,
    textAlign: 'center',
  },
  welcomeSubtitle: {
    fontSize: 16,
    color: '#FFFFFF',
    opacity: 0.9,
    textAlign: 'center',
    lineHeight: 24,
  },
  buttonsContainer: {
    gap: 16,
    marginBottom: 32,
  },
  socialButton: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  socialButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  emailButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  emailButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  exampleLink: {
    alignItems: 'center',
  },
  exampleLinkText: {
    fontSize: 14,
    color: '#FFFFFF',
    opacity: 0.8,
    textDecorationLine: 'underline',
  },
});
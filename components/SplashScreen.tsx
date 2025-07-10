import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Heart } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

interface SplashScreenProps {
  onFinish: () => void;
}

export default function SplashScreen({ onFinish }: SplashScreenProps) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onFinish();
    }, 3000);

    return () => clearTimeout(timer);
  }, [onFinish]);

  return (
    <LinearGradient
      colors={['#B8E6D3', '#E6D3F7']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.container}
    >
      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <Heart color="#FFFFFF" size={64} />
          <Text style={styles.logo}>HonVie</Text>
        </View>
        <Text style={styles.slogan}>L'art de vivre en solo</Text>
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    alignItems: 'center',
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 24,
  },
  logo: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 16,
  },
  slogan: {
    fontSize: 18,
    color: '#FFFFFF',
    fontWeight: '500',
    textAlign: 'center',
    opacity: 0.9,
  },
});
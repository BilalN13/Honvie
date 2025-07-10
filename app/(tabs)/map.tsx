import React from 'react';
import { View, Text, StyleSheet, SafeAreaView } from 'react-native';
import { Map } from 'lucide-react-native';

export default function MapScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Carte Interactive</Text>
        <Text style={styles.subtitle}>Découvrez des lieux solo-friendly près de vous</Text>
      </View>
      
      <View style={styles.mapContainer}>
        <Map color="#F8B2DD" size={64} />
        <Text style={styles.comingSoon}>Carte interactive</Text>
        <Text style={styles.comingSoonDesc}>
          Explorez les meilleurs endroits pour profiter de votre temps en solo
        </Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    padding: 20,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#6B7280',
  },
  mapContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
  },
  comingSoon: {
    fontSize: 20,
    fontWeight: '600',
    color: '#1F2937',
    marginTop: 20,
    marginBottom: 8,
  },
  comingSoonDesc: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
  },
});
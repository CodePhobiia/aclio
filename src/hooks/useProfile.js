// User Profile Hook
import { useState, useCallback, useEffect } from 'react';
import { 
  loadUserProfile, 
  saveUserProfile,
  hasOnboarded,
  setOnboarded as markOnboarded,
  clearOnboarded,
  loadNotificationsEnabled,
  saveNotificationsEnabled,
  loadLocation,
  saveLocation
} from '../utils/storage';

export function useProfile() {
  const [profile, setProfileState] = useState(() => loadUserProfile() || { name: '', age: '', gender: '' });
  const [isOnboarded, setIsOnboarded] = useState(() => hasOnboarded());
  const [notificationsEnabled, setNotificationsEnabledState] = useState(() => loadNotificationsEnabled());
  const [location, setLocationState] = useState(() => loadLocation());
  const [locationLoading, setLocationLoading] = useState(false);

  // Save profile
  const setProfile = useCallback((newProfile) => {
    setProfileState(newProfile);
    saveUserProfile(newProfile);
  }, []);

  // Update specific profile field
  const updateProfile = useCallback((field, value) => {
    setProfileState(prev => {
      const updated = { ...prev, [field]: value };
      saveUserProfile(updated);
      return updated;
    });
  }, []);

  // Complete onboarding
  const completeOnboarding = useCallback(() => {
    markOnboarded();
    setIsOnboarded(true);
  }, []);

  // Reset onboarding (for logout)
  const resetOnboarding = useCallback(() => {
    clearOnboarded();
    setIsOnboarded(false);
  }, []);

  // Toggle notifications
  const setNotificationsEnabled = useCallback((enabled) => {
    setNotificationsEnabledState(enabled);
    saveNotificationsEnabled(enabled);
  }, []);

  // Fetch user location
  const fetchLocation = useCallback(async () => {
    if (!navigator.geolocation) {
      console.warn('Geolocation not supported');
      return null;
    }

    setLocationLoading(true);
    
    try {
      const position = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject);
      });

      // Reverse geocode to get city/country
      const { latitude, longitude } = position.coords;
      
      try {
        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`
        );
        const data = await response.json();
        
        const locationData = {
          latitude,
          longitude,
          city: data.address?.city || data.address?.town || data.address?.village,
          country: data.address?.country,
          display: data.display_name
        };

        setLocationState(locationData);
        saveLocation(locationData);
        return locationData;
      } catch {
        // If geocoding fails, just save coordinates
        const locationData = { latitude, longitude };
        setLocationState(locationData);
        saveLocation(locationData);
        return locationData;
      }
    } catch (error) {
      console.error('Failed to get location:', error);
      return null;
    } finally {
      setLocationLoading(false);
    }
  }, []);

  // Clear location
  const clearLocation = useCallback(() => {
    setLocationState(null);
    saveLocation(null);
  }, []);

  // Get greeting based on time of day
  const getGreeting = useCallback(() => {
    const hour = new Date().getHours();
    const name = profile.name || 'there';
    
    if (hour < 12) return `Good morning, ${name}!`;
    if (hour < 18) return `Good afternoon, ${name}!`;
    return `Good evening, ${name}!`;
  }, [profile.name]);

  return {
    profile,
    setProfile,
    updateProfile,
    isOnboarded,
    completeOnboarding,
    resetOnboarding,
    notificationsEnabled,
    setNotificationsEnabled,
    location,
    locationLoading,
    fetchLocation,
    clearLocation,
    getGreeting
  };
}


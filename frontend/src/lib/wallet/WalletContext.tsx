'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { AppConfig, UserSession, showConnect, authenticate } from '@stacks/connect';
import { StacksMocknet, StacksTestnet, StacksMainnet } from '@stacks/network';

const appConfig = new AppConfig(['store_write', 'publish_data']);
const userSession = new UserSession({ appConfig });

interface WalletContextType {
  userSession: UserSession;
  userData: any;
  isLoggedIn: boolean;
  login: () => void;
  logout: () => void;
  network: StacksMocknet | StacksTestnet | StacksMainnet;
}

const WalletContext = createContext<WalletContextType | null>(null);

export const WalletProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [userData, setUserData] = useState<any>(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [mounted, setMounted] = useState(false);
  const network = new StacksMocknet(); // Defaulting to Mocknet for development

  useEffect(() => {
    setMounted(true);
    try {
      if (userSession.isUserSignedIn()) {
        const data = userSession.loadUserData();
        setUserData(data);
        setIsLoggedIn(true);
      }
    } catch (error) {
      console.error('Failed to load Stacks session:', error);
      // If session is corrupted, sign out to clear it
      userSession.signUserOut();
    }
  }, []);

  const login = useCallback(() => {
    showConnect({
      appDetails: {
        name: 'TradeLink Protocol',
        icon: '/logo.png',
      },
      userSession,
      onFinish: () => {
        try {
          const data = userSession.loadUserData();
          setUserData(data);
          setIsLoggedIn(true);
          window.location.reload();
        } catch (e) {
          console.error('Login success but data load failed:', e);
        }
      },
      onCancel: () => {
        console.log('Connect cancelled');
      },
    });
  }, []);

  const logout = useCallback(() => {
    userSession.signUserOut();
    setUserData(null);
    setIsLoggedIn(false);
    window.location.reload();
  }, []);

  // Prevent hydration mismatch by returning null or a loader until mounted
  if (!mounted) return null;

  return (
    <WalletContext.Provider value={{ userSession, userData, isLoggedIn, login, logout, network }}>
      {children}
    </WalletContext.Provider>
  );
};

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error('useWallet must be used within a WalletProvider');
  }
  return context;
};

'use client';

import { useWallet } from '@/lib/wallet/WalletContext';
import { ShoppingBag, User, LogOut, Menu } from 'lucide-react';
import Link from 'next/link';

export const Navbar = () => {
  const { userData, isLoggedIn, login, logout } = useWallet();

  return (
    <nav className="fixed top-0 left-0 right-0 h-16 glass z-50 px-6 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <Link href="/" className="text-xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
          TradeLink Protocol
        </Link>
      </div>

      <div className="flex items-center gap-6">
        <div className="hidden md:flex items-center gap-6 text-sm font-medium">
          <Link href="/marketplace" className="hover:text-primary transition-colors">Marketplace</Link>
          <Link href="/dao" className="hover:text-primary transition-colors">Governance</Link>
        </div>

        {isLoggedIn ? (
          <div className="flex items-center gap-4 border-l border-white/10 pl-6">
            <Link href="/profile" className="flex items-center gap-2 hover:text-primary transition-colors text-sm">
              <User size={18} />
              <span className="max-w-[100px] truncate">
                {userData.profile.stxAddress.mainnet || userData.profile.stxAddress.testnet}
              </span>
            </Link>
            <button onClick={logout} className="p-2 hover:text-red-400 transition-colors">
              <LogOut size={18} />
            </button>
          </div>
        ) : (
          <button
            onClick={login}
            className="px-4 py-2 bg-primary text-white rounded-lg font-medium hover:bg-primary/80 transition-all shadow-lg shadow-primary/20"
          >
            Connect Wallet
          </button>
        )}
      </div>
    </nav>
  );
};

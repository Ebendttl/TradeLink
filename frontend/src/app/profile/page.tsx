'use client';

import { Navbar } from '@/components/ui/Navbar';
import { useWallet } from '@/lib/wallet/WalletContext';
import { User, Mail, Shield, ShieldCheck, ExternalLink } from 'lucide-react';

export default function ProfilePage() {
  const { userData, isLoggedIn, login } = useWallet();

  if (!isLoggedIn) return (
    <div className="min-h-screen flex items-center justify-center flex-col gap-6">
      <h1 className="text-2xl font-bold">Please connect your wallet to view your profile</h1>
      <button onClick={login} className="px-6 py-3 bg-primary rounded-xl font-bold">Connect Wallet</button>
    </div>
  );

  return (
    <main className="min-h-screen pt-24 pb-12 px-6">
      <Navbar />
      
      <div className="max-w-4xl mx-auto">
        <header className="mb-12 text-center">
          <div className="w-24 h-24 bg-gradient-to-br from-primary to-accent rounded-full mx-auto mb-6 flex items-center justify-center border-4 border-white/10 p-1">
             <div className="w-full h-full bg-background rounded-full flex items-center justify-center">
                <User size={40} className="text-primary" />
             </div>
          </div>
          <h1 className="text-4xl font-black mb-2 truncate max-w-lg mx-auto">
             {userData.profile.stxAddress.mainnet || userData.profile.stxAddress.testnet}
          </h1>
          <div className="flex items-center justify-center gap-2 text-white/40">
             <ShieldCheck size={16} className="text-green-400" />
             <span className="text-sm font-medium">Protocol Authenticated</span>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
            <div className="glass p-8 rounded-3xl">
               <h3 className="text-lg font-bold mb-6 flex items-center gap-3">
                  <Mail size={20} className="text-primary" />
                  <span>Contact Information</span>
               </h3>
               <div className="space-y-4">
                  <div>
                     <label className="text-xs font-bold text-white/20 uppercase block mb-1">Email Address</label>
                     <p className="font-medium">{userData.profile.email || 'Not Provided'}</p>
                  </div>
                  <div>
                     <label className="text-xs font-bold text-white/20 uppercase block mb-1">User Principal</label>
                     <p className="font-mono text-sm break-all">{userData.profile.stxAddress.mainnet || userData.profile.stxAddress.testnet}</p>
                  </div>
               </div>
            </div>

            <div className="glass p-8 rounded-3xl">
               <h3 className="text-lg font-bold mb-6 flex items-center gap-3">
                  <Shield size={20} className="text-accent" />
                  <span>Protocol Reputation</span>
               </h3>
               <div className="space-y-6">
                  <div>
                    <div className="flex justify-between items-end mb-2">
                       <label className="text-xs font-bold text-white/20 uppercase block">Trust Score</label>
                       <span className="text-xl font-black text-accent">750/1000</span>
                    </div>
                    <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                       <div className="h-full bg-accent" style={{ width: '75%' }} />
                    </div>
                  </div>
                  <div className="flex gap-4">
                     <div className="px-3 py-1 bg-green-500/10 text-green-400 rounded-md text-[10px] font-bold uppercase">No Penalties</div>
                     <div className="px-3 py-1 bg-primary/10 text-primary rounded-md text-[10px] font-bold uppercase">High Volume</div>
                  </div>
               </div>
            </div>
        </div>

        <div className="text-center">
           <button className="inline-flex items-center gap-2 text-white/20 hover:text-white underline text-sm transition-all">
              <span>View On-Chain Profile</span>
              <ExternalLink size={14} />
           </button>
        </div>
      </div>
    </main>
  );
}

'use client';

import { Navbar } from '@/components/ui/Navbar';
import { useWallet } from '@/lib/wallet/WalletContext';
import { Plus, BarChart3, TrendingUp, DollarSign } from 'lucide-react';

export default function SellerPage() {
  const { isLoggedIn, login } = useWallet();

  return (
    <main className="min-h-screen pt-24 pb-12 px-6">
      <Navbar />
      
      <div className="max-w-6xl mx-auto">
        <header className="mb-12 flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div>
            <h1 className="text-4xl font-black mb-2">Seller Dashboard</h1>
            <p className="text-white/40">Manage your listings, track revenue, and grow your on-chain reputation.</p>
          </div>
          <button className="px-6 py-4 bg-primary rounded-2xl font-black text-lg shadow-xl shadow-primary/20 flex items-center gap-3">
            <Plus size={24} />
            <span>Create New Listing</span>
          </button>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
           <StatCard icon={<TrendingUp className="text-primary" />} label="Total Sales" value="124" />
           <StatCard icon={<DollarSign className="text-accent" />} label="Volume" value="12.5k STX" />
           <StatCard icon={<BarChart3 className="text-blue-400" />} label="Views" value="4.2k" />
           <StatCard icon={<TrendingUp className="text-green-400" />} label="Reputation" value="750" />
        </div>

        <section className="glass p-8 rounded-3xl">
          <h2 className="text-xl font-bold mb-6">Active Listings</h2>
          <div className="space-y-4">
             <div className="p-4 bg-white/5 rounded-2xl flex items-center justify-between group hover:bg-white/10 transition-all border border-transparent hover:border-primary/20">
                <div className="flex items-center gap-6">
                   <div className="w-16 h-16 bg-white/5 rounded-xl overflow-hidden">
                      <img src="https://images.unsplash.com/photo-1523275335684-37898b6baf30" className="w-full h-full object-cover" />
                   </div>
                   <div>
                      <h4 className="font-bold">Premium Modular Watch</h4>
                      <p className="text-xs text-white/40 leading-relaxed uppercase font-bold tracking-widest mt-1">Electronics • 5 in Stock</p>
                   </div>
                </div>
                <div className="text-right flex items-center gap-8">
                   <div>
                      <p className="text-xs text-white/20 uppercase font-black">Price</p>
                      <p className="font-black text-lg">500 STX</p>
                   </div>
                   <button className="px-4 py-2 bg-white/5 hover:bg-white/20 rounded-lg text-sm font-bold transition-all">Edit</button>
                </div>
             </div>
          </div>
        </section>
      </div>
    </main>
  );
}

function StatCard({ icon, label, value }: { icon: any, label: string, value: any }) {
  return (
    <div className="glass p-6 rounded-2xl flex items-center gap-4 border border-white/5">
      <div className="p-3 bg-white/5 rounded-xl">{icon}</div>
      <div>
        <p className="text-xs font-bold text-white/40 uppercase tracking-wider">{label}</p>
        <p className="text-2xl font-black">{value}</p>
      </div>
    </div>
  );
}

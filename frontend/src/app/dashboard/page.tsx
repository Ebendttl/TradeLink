'use client';

import { useQuery } from '@tanstack/react-query';
import { Navbar } from '@/components/ui/Navbar';
import { useWallet } from '@/lib/wallet/WalletContext';
import { Package, Award, Clock, AlertCircle } from 'lucide-react';

export default function DashboardPage() {
  const { userData, isLoggedIn, login } = useWallet();

  const { data: stats } = useQuery({
    queryKey: ['dashboard-stats', userData?.profile?.stxAddress?.mainnet],
    queryFn: async () => {
      // Simulated stats
      return {
        purchases: 5,
        points: 1250,
        activeEscrows: 2,
        activeDisputes: 0,
      };
    },
    enabled: !!userData,
  });

  if (!isLoggedIn) return (
    <div className="min-h-screen flex items-center justify-center flex-col gap-6">
      <h1 className="text-2xl font-bold">Please connect your wallet to view your dashboard</h1>
      <button onClick={login} className="px-6 py-3 bg-primary rounded-xl font-bold">Connect Wallet</button>
    </div>
  );

  return (
    <main className="min-h-screen pt-24 pb-12 px-6">
      <Navbar />
      
      <div className="max-w-6xl mx-auto">
        <header className="mb-12">
          <h1 className="text-4xl font-black mb-2">User Dashboard</h1>
          <p className="text-white/40">Manage your purchases, rewards, and active protocol interactions.</p>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          <StatCard icon={<Package className="text-primary" />} label="Receipts" value={stats?.purchases || 0} />
          <StatCard icon={<Award className="text-accent" />} label="Loyalty Points" value={stats?.points || 0} />
          <StatCard icon={<Clock className="text-blue-400" />} label="Active Escrows" value={stats?.activeEscrows || 0} />
          <StatCard icon={<AlertCircle className="text-red-400" />} label="Disputes" value={stats?.activeDisputes || 0} />
        </div>

        <section className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="glass p-8 rounded-3xl">
            <h2 className="text-xl font-bold mb-6">Recent Receipts (NFTs)</h2>
            <div className="space-y-4">
              <div className="p-4 bg-white/5 rounded-2xl flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-primary/20 rounded-xl flex items-center justify-center font-bold text-primary">#1</div>
                  <div>
                    <h4 className="font-bold">Premium Watch Receipt</h4>
                    <p className="text-xs text-white/20">Sale ID: 1042 • 2 days ago</p>
                  </div>
                </div>
                <button className="text-xs font-bold text-primary underline">View NFT</button>
              </div>
            </div>
          </div>

          <div className="glass p-8 rounded-3xl">
            <h2 className="text-xl font-bold mb-6">Active Escrows</h2>
            <div className="space-y-4">
               <div className="p-4 bg-white/5 rounded-2xl border border-primary/10">
                <div className="flex justify-between mb-4">
                  <h4 className="font-bold text-primary">Escrow #74</h4>
                  <span className="text-xs font-bold text-blue-400 px-2 py-0.5 bg-blue-400/10 rounded-md">Pending Delivery</span>
                </div>
                <div className="w-full h-1.5 bg-white/5 rounded-full overflow-hidden mb-4">
                  <div className="w-1/2 h-full bg-primary" />
                </div>
                <p className="text-xs text-white/40 leading-relaxed capitalize">Waiting for seller to confirm shipping or buyer to release milestone.</p>
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

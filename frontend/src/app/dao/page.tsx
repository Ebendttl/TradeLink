'use client';

import { useQuery } from '@tanstack/react-query';
import { Navbar } from '@/components/ui/Navbar';
import { useWallet } from '@/lib/wallet/WalletContext';
import { Gavel, Vote, Users, Target } from 'lucide-react';

export default function DAOPage() {
  const { isLoggedIn, login } = useWallet();

  const { data: disputes } = useQuery({
    queryKey: ['disputes'],
    queryFn: async () => {
      // Simulated disputes
      return [
        {
          id: 1,
          title: "Resolution for Escrow #42",
          status: "Active",
          votesFor: 150,
          votesAgainst: 20,
          deadline: "2026-03-30",
          description: "Buyer claims item was not received, seller provides tracking. Community vote required for fund release."
        }
      ];
    },
  });

  return (
    <main className="min-h-screen pt-24 pb-12 px-6">
      <Navbar />
      
      <div className="max-w-6xl mx-auto">
        <header className="mb-12 flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div>
            <h1 className="text-4xl font-black mb-2 flex items-center gap-4">
              <Gavel className="text-accent" />
              <span>Dispute DAO</span>
            </h1>
            <p className="text-white/40">Participate in protocol governance and resolve decentralized commerce disputes.</p>
          </div>
          
          <div className="flex gap-4">
             <div className="glass px-4 py-2 rounded-xl flex items-center gap-2">
                <Users size={16} className="text-primary" />
                <span className="text-sm font-bold">4.2k Active Voters</span>
             </div>
             <div className="glass px-4 py-2 rounded-xl flex items-center gap-2">
                <Target size={16} className="text-green-400" />
                <span className="text-sm font-bold">100% On-Chain Governance</span>
             </div>
          </div>
        </header>

        <section className="grid grid-cols-1 gap-8">
          {disputes?.map((dispute) => (
            <div key={dispute.id} className="glass p-8 rounded-3xl border border-white/5 relative overflow-hidden group">
              <div className="absolute top-0 right-0 w-1.5 h-full bg-accent" />
              
              <div className="mb-6 flex justify-between items-start">
                <div>
                  <h2 className="text-2xl font-bold mb-2">{dispute.title}</h2>
                  <p className="text-secondary-foreground/60 leading-relaxed max-w-3xl">{dispute.description}</p>
                </div>
                <div className="text-right">
                  <span className="text-xs font-bold uppercase text-white/20 block mb-1">Voting Ends</span>
                  <span className="text-sm font-bold">{dispute.deadline}</span>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-8">
                <div className="space-y-4">
                  <div className="flex justify-between text-sm font-bold">
                    <span>Release Funds (Yes)</span>
                    <span className="text-green-400">{dispute.votesFor} Votes</span>
                  </div>
                  <div className="w-full h-3 bg-white/5 rounded-full overflow-hidden">
                    <div className="h-full bg-green-400" style={{ width: '85%' }} />
                  </div>
                </div>
                <div className="space-y-4">
                  <div className="flex justify-between text-sm font-bold">
                    <span>Refund Buyer (No)</span>
                    <span className="text-red-400">{dispute.votesAgainst} Votes</span>
                  </div>
                  <div className="w-full h-3 bg-white/5 rounded-full overflow-hidden">
                    <div className="h-full bg-red-400" style={{ width: '15%' }} />
                  </div>
                </div>
              </div>

              <div className="flex gap-4">
                <button className="flex-1 py-4 bg-green-500/10 hover:bg-green-500/20 border border-green-500/20 text-green-400 rounded-2xl font-bold transition-all flex items-center justify-center gap-2">
                  <Vote size={20} />
                  <span>Vote to Release</span>
                </button>
                <button className="flex-1 py-4 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 text-red-400 rounded-2xl font-bold transition-all flex items-center justify-center gap-2">
                  <Vote size={20} />
                  <span>Vote to Refund</span>
                </button>
              </div>
            </div>
          ))}
        </section>
      </div>
    </main>
  );
}

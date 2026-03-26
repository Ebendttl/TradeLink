'use client';

import { Navbar } from '@/components/ui/Navbar';
import { ShoppingBag, ShieldCheck, Zap, ArrowRight } from 'lucide-react';
import Link from 'next/link';

export default function LandingPage() {
  return (
    <main className="min-h-screen relative overflow-hidden">
      <Navbar />
      
      {/* Background Orbs */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-primary/20 blur-[120px] rounded-full z-0" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-accent/10 blur-[120px] rounded-full z-0" />

      <div className="relative z-10 pt-40 px-6 max-w-7xl mx-auto text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 glass rounded-full text-xs font-bold text-accent mb-8 animate-bounce">
          <Zap size={14} fill="currentColor" />
          <span>V2 MODULAR PROTOCOL IS LIVE</span>
        </div>
        
        <h1 className="text-6xl md:text-8xl font-black tracking-tighter mb-8 leading-[0.9]">
          The Future of <br />
          <span className="bg-gradient-to-r from-primary via-white to-accent bg-clip-text text-transparent italic">
             On-Chain Commerce
          </span>
        </h1>

        <p className="text-xl text-white/40 max-w-2xl mx-auto mb-12 leading-relaxed font-medium">
          Secure, modular, and trustless marketplace powered by the Stacks blockchain. 
          Trade digital and physical goods with milestone-based escrow.
        </p>

        <div className="flex flex-col md:flex-row items-center justify-center gap-6">
          <Link
            href="/marketplace"
            className="px-8 py-5 bg-primary text-white rounded-2xl font-black text-xl hover:scale-105 transition-all shadow-2xl shadow-primary/40 flex items-center gap-3"
          >
            <span>Enter Marketplace</span>
            <ArrowRight size={24} />
          </Link>
          
          <Link
            href="/dao"
            className="px-8 py-5 glass border border-white/10 text-white rounded-2xl font-black text-xl hover:bg-white/5 transition-all flex items-center gap-3"
          >
            <span>Governance DAO</span>
          </Link>
        </div>

        <div className="mt-40 grid grid-cols-1 md:grid-cols-3 gap-8 text-left pb-20">
           <FeatureCard 
             icon={<ShieldCheck className="text-primary" />} 
             title="Milestone Escrow" 
             desc="Funds are locked and released only when milestones are met or community votes approve."
           />
           <FeatureCard 
             icon={<ShoppingBag className="text-accent" />} 
             title="Multi-Token Payments" 
             desc="Pay with STX or any supported SIP-010 token with automatic normalization."
           />
           <FeatureCard 
             icon={<Zap className="text-green-400" />} 
             title="Reputation Scoring" 
             desc="Advanced reputation oracle calculates trust scores based on historical protocol activity."
           />
        </div>
      </div>
    </main>
  );
}

function FeatureCard({ icon, title, desc }: { icon: any, title: string, desc: string }) {
  return (
    <div className="glass p-8 rounded-3xl border border-white/5 group hover:border-white/20 transition-all">
       <div className="p-4 bg-white/5 rounded-2xl w-fit mb-6 group-hover:scale-110 transition-transform">{icon}</div>
       <h3 className="text-xl font-bold mb-3">{title}</h3>
       <p className="text-white/40 leading-relaxed text-sm font-medium">{desc}</p>
    </div>
  );
}

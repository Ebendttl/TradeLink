'use client';

import { useQuery } from '@tanstack/react-query';
import { fetchMarketplaceItems } from '@/indexer/client';
import { ProductCard } from '@/components/ui/ProductCard';
import { Navbar } from '@/components/ui/Navbar';
import { Search, Filter, LayoutGrid, List } from 'lucide-react';

export default function MarketplacePage() {
  const { data: items, isLoading } = useQuery({
    queryKey: ['marketplace-items'],
    queryFn: fetchMarketplaceItems,
  });

  return (
    <main className="min-h-screen pt-24 px-6 md:px-12 pb-12">
      <Navbar />
      
      <div className="max-w-7xl mx-auto">
        <header className="mb-12">
          <h1 className="text-4xl font-black mb-4">Discover Products</h1>
          <p className="text-secondary-foreground/60 max-w-2xl">
            Explore the TradeLink decentralized marketplace. Secure, modular, and trustless commerce powered by Stacks.
          </p>
        </header>

        <div className="flex flex-col md:flex-row gap-6 mb-12">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-white/20" size={20} />
            <input
              type="text"
              placeholder="Search items, categories, or sellers..."
              className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 focus:ring-2 focus:ring-primary/50 outline-none transition-all"
            />
          </div>

          <div className="flex gap-4">
            <button className="flex items-center gap-2 px-4 py-3 bg-white/5 border border-white/10 rounded-xl hover:bg-white/10 transition-all font-medium">
              <Filter size={20} />
              <span>Filters</span>
            </button>
            
            <div className="flex items-center gap-1 bg-white/5 border border-white/10 p-1 rounded-xl">
              <button className="p-2 bg-primary text-white rounded-lg"><LayoutGrid size={20} /></button>
              <button className="p-2 text-white/40 hover:text-white"><List size={20} /></button>
            </div>
          </div>
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-[400px] glass rounded-2xl animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {items?.map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

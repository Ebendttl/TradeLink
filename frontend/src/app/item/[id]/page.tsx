'use client';

import { useQuery } from '@tanstack/react-query';
import { fetchMarketplaceItems, fetchUserReputation } from '@/indexer/client';
import { Navbar } from '@/components/ui/Navbar';
import { useWallet } from '@/lib/wallet/WalletContext';
import { executeContractCall } from '@/lib/contracts/transactions';
import { protocolContracts } from '@/lib/contracts/registry';
import { Shield, Truck, Package, Star, ArrowLeft } from 'lucide-react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { uintCV } from '@stacks/transactions';

export default function ItemDetailsPage() {
  const { id } = useParams();
  const { isLoggedIn, login, userData } = useWallet();

  const { data: item, isLoading } = useQuery({
    queryKey: ['item', id],
    queryFn: async () => {
      const items = await fetchMarketplaceItems();
      return items.find((i) => i.id === Number(id));
    },
  });

  const { data: reputation } = useQuery({
    queryKey: ['reputation', item?.seller],
    queryFn: () => fetchUserReputation(item?.seller || ''),
    enabled: !!item?.seller,
  });

  const handlePurchase = async () => {
    if (!isLoggedIn) {
      login();
      return;
    }

    if (!item) return;

    const TradeLinkContract = await protocolContracts.get('TradeLink');
    const [contractAddress, contractName] = TradeLinkContract.split('.');

    await executeContractCall({
      contractAddress,
      contractName,
      functionName: 'buy-item',
      functionArgs: [uintCV(item.id)],
      onFinish: (data) => {
        console.log('Purchase transaction successful:', data);
      },
    });
  };

  if (isLoading) return <div className="min-h-screen bg-background" />;
  if (!item) return <div className="min-h-screen flex items-center justify-center">Item not found</div>;

  return (
    <main className="min-h-screen pt-24 pb-12 px-6">
      <Navbar />
      
      <div className="max-w-6xl mx-auto">
        <Link href="/marketplace" className="inline-flex items-center gap-2 text-white/40 hover:text-white mb-8 transition-colors">
          <ArrowLeft size={20} />
          <span>Back to Marketplace</span>
        </Link>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
          {/* Left: Image Container */}
          <div className="relative aspect-square rounded-3xl overflow-hidden glass">
            <img src={item.imageUrl} alt={item.name} className="w-full h-full object-cover" />
            <div className="absolute bottom-6 left-6 flex gap-2">
              <span className="px-3 py-1 glass rounded-full text-xs font-bold text-primary italic uppercase tracking-widest">Limited Edition</span>
            </div>
          </div>

          {/* Right: Info Container */}
          <div className="flex flex-col">
            <div className="mb-6">
              <div className="flex items-center gap-2 text-accent text-sm font-bold mb-2 uppercase tracking-widest">
                <Package size={14} />
                <span>{item.category}</span>
              </div>
              <h1 className="text-5xl font-black mb-4 tracking-tight">{item.name}</h1>
              
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-1.5 px-3 py-1.5 bg-primary/10 rounded-full border border-primary/20">
                  <Star size={16} className="text-primary fill-primary" />
                  <span className="text-sm font-bold">{reputation || 0} / 1000 Trust Score</span>
                </div>
                <span className="text-white/20 text-sm">|</span>
                <span className="text-sm text-secondary-foreground/60">Seller: {item.seller.slice(0, 10)}...</span>
              </div>
            </div>

            <div className="glass p-8 rounded-3xl mb-8">
              <div className="mb-8">
                <span className="text-sm text-secondary-foreground/40 font-bold uppercase block mb-1">Price</span>
                <span className="text-4xl font-black text-primary">{(item.price / 1000000).toLocaleString()} <span className="text-xl">STX</span></span>
              </div>

              <button
                onClick={handlePurchase}
                className="w-full py-4 bg-primary hover:bg-primary/80 text-white rounded-2xl font-black text-lg transition-all shadow-xl shadow-primary/20 flex items-center justify-center gap-3"
              >
                <span>Purchase with Secure Escrow</span>
              </button>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-8">
              <div className="p-4 glass rounded-2xl flex flex-col items-center justify-center text-center">
                <Shield size={24} className="text-green-400 mb-2" />
                <span className="text-xs font-bold uppercase tracking-tighter text-white/40">Secured</span>
              </div>
              <div className="p-4 glass rounded-2xl flex flex-col items-center justify-center text-center">
                <Truck size={24} className="text-blue-400 mb-2" />
                <span className="text-xs font-bold uppercase tracking-tighter text-white/40">Verified Shipping</span>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="font-bold text-lg">Product Description</h3>
              <p className="text-secondary-foreground/60 leading-relaxed">
                {item.description} This item is managed via the TradeLink Protocol, 
                guaranteeing milestone-based fund releases and decentralized dispute resolution.
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

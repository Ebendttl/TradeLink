'use client';

import { MarketplaceItem } from '@/indexer/client';
import { ShoppingCart, ShieldCheck } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

interface ProductCardProps {
  item: MarketplaceItem;
}

export const ProductCard = ({ item }: ProductCardProps) => {
  return (
    <div className="group glass rounded-2xl overflow-hidden hover:scale-[1.02] transition-all duration-300">
      <div className="relative h-48 w-full overflow-hidden">
        <img
          src={item.imageUrl}
          alt={item.name}
          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
        />
        <div className="absolute top-3 right-3 px-2 py-1 glass rounded-md text-xs font-semibold text-accent">
          {item.category}
        </div>
      </div>

      <div className="p-5">
        <h3 className="text-lg font-bold truncate mb-1">{item.name}</h3>
        <p className="text-secondary-foreground/60 text-sm line-clamp-2 mb-4 h-10">
          {item.description}
        </p>

        <div className="flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-xs text-secondary-foreground/40 uppercase font-bold tracking-wider">Price</span>
            <span className="text-xl font-black text-primary">{(item.price / 1000000).toLocaleString()} STX</span>
          </div>

          <Link
            href={`/item/${item.id}`}
            className="p-3 bg-white/5 hover:bg-primary hover:text-white rounded-xl transition-all"
          >
            <ShoppingCart size={20} />
          </Link>
        </div>
        
        <div className="mt-4 pt-4 border-t border-white/5 flex items-center gap-2 text-[10px] text-secondary-foreground/40">
          <ShieldCheck size={12} className="text-green-400" />
          <span>Verified by TradeLink Protocol</span>
        </div>
      </div>
    </div>
  );
};

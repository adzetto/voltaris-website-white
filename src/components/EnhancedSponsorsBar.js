import React from 'react';
import { ExternalLink } from "lucide-react";

const EnhancedSponsorsBar = ({ sponsors }) => {
  // Improved tier configuration with more distinctive colors
  const getTierConfig = (tier) => {
    const config = {
      platinum: {
        height: "42px",
        color: "#E5D085", // More elegant platinum color
        barWidth: "100%",
        barClass: "tier-platinum"
      },
      gold: {
        height: "38px",
        color: "#FFC233", // More vibrant gold color
        barWidth: "90%",
        barClass: "tier-gold" 
      },
      silver: {
        height: "36px",
        color: "#C0C0C0", // Silver color
        barWidth: "80%",
        barClass: "tier-silver"
      },
      bronze: {
        height: "34px",
        color: "#CD7F32", // Bronze color
        barWidth: "70%",
        barClass: "tier-bronze"
      },
      default: {
        height: "32px",
        color: "#3B82F6", // Default blue color
        barWidth: "60%",
        barClass: "tier-default"
      }
    };
    
    return config[tier] || config.default;
  };

  return (
    <div className="relative w-full bg-gray-50 border-t border-voltaris-neutral-200 pt-4 pb-8 sponsor-bar">
      {/* Header section */}
      <div className="flex items-center justify-between px-6 mb-4">
        <div className="flex items-center">
          <div className="text-voltaris-neutral-600 text-xs uppercase tracking-wide font-medium">
            SPONSORLAR
          </div>
          <div className="ml-2 h-px w-8 bg-gradient-to-r from-voltaris-neutral-400/40 to-transparent"></div>
        </div>
        
        <div className="flex items-center">
          <span className="px-1.5 py-0.5 border border-voltaris-neutral-200 rounded bg-gray-50 hover:border-voltaris-neutral-400 transition-colors">
            <a 
              href="#sponsors" 
              className="text-voltaris-neutral-600 hover:text-voltaris-neutral-800 flex items-center text-[9px] uppercase" 
              title="Tüm Sponsorları Görüntüle"
            >
              DETAYLAR <ExternalLink size={8} className="ml-1" />
            </a>
          </span>
        </div>
      </div>
      
      {/* Sponsors display with simplified tier bars */}
      <div className="flex items-center justify-center px-4 py-1">
        {sponsors.map((sponsor) => {
          const tierConfig = getTierConfig(sponsor.tier);
          
          return (
            <div key={sponsor.id} className="sponsor-container relative mx-6">
              <a 
                href={sponsor.website} 
                target="_blank" 
                rel="noopener noreferrer"
                className="block"
              >
                <img 
                  src={sponsor.logo} 
                  alt={sponsor.name}
                  className="sponsor-logo transition-transform hover:scale-110"
                  style={{
                    height: tierConfig.height,
                    maxHeight: tierConfig.height
                  }}
                />
                
                {/* Fixed tier bar indicator with left-to-right fade effect */}
                <div className="tier-bar-container relative h-2 mt-4">
                  <div 
                    className={`absolute left-1/2 transform -translate-x-1/2 h-1 ${tierConfig.barClass}`}
                    style={{ 
                      width: tierConfig.barWidth,
                      background: `linear-gradient(to right, transparent, ${tierConfig.color} 40%, ${tierConfig.color} 60%, transparent)`
                    }}
                  ></div>
                </div>
              </a>
            </div>
          );
        })}
      </div>
      
      {/* CSS for tier indicator animations */}
      <style>{`
        .sponsor-bar {
          margin-bottom: 10px;
        }
        
        .tier-platinum {
          box-shadow: 0 0 5px #E5D085;
          animation: leftToRightFade 8s infinite;
        }
        
        .tier-gold {
          box-shadow: 0 0 5px #FFC233;
          animation: leftToRightFade 8s infinite;
        }
        
        .tier-silver {
          box-shadow: 0 0 5px #C0C0C0;
          animation: leftToRightFade 8s infinite;
        }
        
        .tier-bronze {
          box-shadow: 0 0 5px #CD7F32;
          animation: leftToRightFade 8s infinite;
        }
        
        .tier-default {
          box-shadow: 0 0 5px #3B82F6;
          animation: leftToRightFade 8s infinite;
        }
        
        @keyframes leftToRightFade {
          0% { opacity: 0; transform: translateX(-50%) scaleX(0); transform-origin: left; }
          20% { opacity: 1; transform: translateX(-50%) scaleX(1); transform-origin: left; }
          80% { opacity: 1; transform: translateX(-50%) scaleX(1); transform-origin: right; }
          100% { opacity: 0; transform: translateX(-50%) scaleX(0); transform-origin: right; }
        }
      `}</style>
    </div>
  );
};

export default EnhancedSponsorsBar;
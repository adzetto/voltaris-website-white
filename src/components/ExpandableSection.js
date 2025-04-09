import React, { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';

const ExpandableSection = ({ title, children, color = "blue", id, defaultOpen = false }) => {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  const colorClasses = {
    red: {
      border: "border-red-900/30 hover:border-red-500/40",
      bg: "from-red-900/30 via-black to-red-900/20",
      text: "text-red-400",
      iconBg: "bg-red-900/30",
      icon: "text-red-500"
    },
    blue: {
      border: "border-blue-900/30 hover:border-blue-500/40",
      bg: "from-blue-900/30 via-black to-blue-900/20",
      text: "text-blue-400",
      iconBg: "bg-blue-900/30",
      icon: "text-blue-500"
    },
    purple: {
      border: "border-purple-900/30 hover:border-purple-500/40", 
      bg: "from-purple-900/30 via-black to-purple-900/20",
      text: "text-purple-400",
      iconBg: "bg-purple-900/30",
      icon: "text-purple-500"
    },
    green: {
      border: "border-green-900/30 hover:border-green-500/40",
      bg: "from-green-900/30 via-black to-green-900/20",
      text: "text-green-400",
      iconBg: "bg-green-900/30",
      icon: "text-green-500"
    }
  };

  const currentColor = colorClasses[color] || colorClasses.blue;

  return (
    <div 
      id={id} 
      className={`bg-gradient-to-br ${currentColor.bg} p-6 rounded-lg ${currentColor.border} transition-all duration-300 shadow-lg`}
    >
      <div 
        className="flex items-center justify-between cursor-pointer"
        onClick={() => setIsOpen(!isOpen)}
      >
        <h3 className={`text-xl font-bold ${currentColor.text}`}>{title}</h3>
        <div className={`${currentColor.iconBg} p-2 rounded-full ${currentColor.icon}`}>
          {isOpen ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
        </div>
      </div>
      
      <div className={`mt-4 transition-all duration-300 overflow-hidden ${isOpen ? 'block' : 'hidden'}`}>
        {children}
      </div>
    </div>
  );
};

export default ExpandableSection;

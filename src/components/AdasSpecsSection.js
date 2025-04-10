import React, { useState } from 'react';
import { AdasSystemsSpecs } from './TechnicalSpecs';
import AdasSystemArchitecture, { LaneDetectionDiagram, TrafficSignDetectionDiagram, CruiseControlSystemDiagram, BlindSpotDetectionDiagram } from '../AdasSvgComponents';
import { ChevronDown } from 'lucide-react';

const AdasSpecsSection = () => {
  const [activeSection, setActiveSection] = useState('');

  return (
    <section id="adas" className="py-16 md:py-20 relative bg-voltaris-soft-bg">
      <div className="container mx-auto px-4 z-10">
        <div className="text-center mb-8 md:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold mb-3 md:mb-4 text-voltaris-text">ADAS Sistemi Planlaması</h2>
          <div className="h-1 w-16 sm:w-20 bg-voltaris-red mx-auto"></div>
          <p className="text-voltaris-secondary mt-4 max-w-2xl mx-auto text-sm sm:text-base px-2">
            Advanced Driver Assistance Systems (ADAS) ile aracımız için planladığımız gelişmiş sürüş destek sistemleri.
          </p>
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6 mb-8 sm:mb-12">
          <AdasSystemsSpecs />
        </div>

        <div className="mt-8 mb-10">
          <div className="p-4 bg-gray-50 shadow-card rounded-lg border border-gray-200 mb-6">
            <div className="flex justify-between items-center cursor-pointer" onClick={() => setActiveSection(activeSection === 'architecture' ? '' : 'architecture')}>
              <h3 className="text-xl font-bold text-voltaris-red">ADAS Sistem Mimarisi</h3>
              <ChevronDown className={`transition-transform duration-300 ${activeSection === 'architecture' ? 'rotate-180' : ''}`} />
            </div>
            {activeSection === 'architecture' && (
              <div className="mt-4 animate-fadeIn">
                <AdasSystemArchitecture />
              </div>
            )}
          </div>

          <div className="p-4 bg-gradient-to-r from-red-900/30 via-black to-red-900/30 rounded-lg border border-red-500/30 mb-6">
            <div className="flex justify-between items-center cursor-pointer" onClick={() => setActiveSection(activeSection === 'laneDetection' ? '' : 'laneDetection')}>
              <h3 className="text-xl font-bold text-red-400">Şerit Takip Sistemi</h3>
              <ChevronDown className={`text-red-400 transition-transform duration-300 ${activeSection === 'laneDetection' ? 'rotate-180' : ''}`} />
            </div>
            {activeSection === 'laneDetection' && (
              <div className="mt-4 animate-fadeIn">
                <LaneDetectionDiagram />
              </div>
            )}
          </div>

          <div className="p-4 bg-gradient-to-r from-blue-900/30 via-black to-blue-900/30 rounded-lg border border-blue-500/30 mb-6">
            <div className="flex justify-between items-center cursor-pointer" onClick={() => setActiveSection(activeSection === 'trafficSign' ? '' : 'trafficSign')}>
              <h3 className="text-xl font-bold text-blue-400">Trafik İşareti Tanıma</h3>
              <ChevronDown className={`text-blue-400 transition-transform duration-300 ${activeSection === 'trafficSign' ? 'rotate-180' : ''}`} />
            </div>
            {activeSection === 'trafficSign' && (
              <div className="mt-4 animate-fadeIn">
                <TrafficSignDetectionDiagram />
              </div>
            )}
          </div>

          <div className="p-4 bg-gradient-to-r from-green-900/30 via-black to-green-900/30 rounded-lg border border-green-500/30 mb-6">
            <div className="flex justify-between items-center cursor-pointer" onClick={() => setActiveSection(activeSection === 'cruiseControl' ? '' : 'cruiseControl')}>
              <h3 className="text-xl font-bold text-green-400">Akıllı Hız Sabitleyici</h3>
              <ChevronDown className={`text-green-400 transition-transform duration-300 ${activeSection === 'cruiseControl' ? 'rotate-180' : ''}`} />
            </div>
            {activeSection === 'cruiseControl' && (
              <div className="mt-4 animate-fadeIn">
                <CruiseControlSystemDiagram />
              </div>
            )}
          </div>

          <div className="p-4 bg-gradient-to-r from-purple-900/30 via-black to-purple-900/30 rounded-lg border border-purple-500/30 mb-6">
            <div className="flex justify-between items-center cursor-pointer" onClick={() => setActiveSection(activeSection === 'blindSpot' ? '' : 'blindSpot')}>
              <h3 className="text-xl font-bold text-purple-400">Kör Nokta Algılama</h3>
              <ChevronDown className={`text-purple-400 transition-transform duration-300 ${activeSection === 'blindSpot' ? 'rotate-180' : ''}`} />
            </div>
            {activeSection === 'blindSpot' && (
              <div className="mt-4 animate-fadeIn">
                <BlindSpotDetectionDiagram />
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};

export default AdasSpecsSection;

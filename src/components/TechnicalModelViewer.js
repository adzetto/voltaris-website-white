import React, { useRef, useState, useEffect } from 'react';
import { useFrame } from '@react-three/fiber';
import { OrbitControls, Html, Text, Environment } from '@react-three/drei';
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import EnhancedModelViewer from './3D/EnhancedModelViewer';

// Enhanced Technical 3D Car Model with academic annotations
const TechnicalCarModel = () => {
  const group = useRef();
  // Use state for hover tracking
  const [isHovered, setIsHovered] = useState(false);
  const [activeAnnotation, setActiveAnnotation] = useState(null);
  const [modelLoaded, setModelLoaded] = useState(false);
  const [loadingProgress, setLoadingProgress] = useState(0);

  // Technical specifications for annotations
  const technicalSpecs = {
    body: {
      title: "Aerodinamik Kabuk",
      specs: [
        "Kompozit Fiber Yapı",
        "Cd: 0.23 Aerodinamik Direnç",
        "Toplam Ağırlık: 15kg",
        "CNC ile Üretilmiş Kalıp"
      ]
    },
    motor: {
      title: "BLDC Hub Motor",
      specs: [
        "Nominal Güç: 5kW",
        "Verimlilik: %92",
        "Nominal Hız: 785 RPM",
        "Tork: 30.39 Nm"
      ]
    },
    battery: {
      title: "Batarya Paketi",
      specs: [
        "Kapasite: 3458 Wh",
        "Nominal Gerilim: 68.97V",
        "Akü Kapasitesi: 50Ah",
        "Menzil: >100 km"
      ]
    },
    electronics: {
      title: "Elektronik Kontrol Sistemi",
      specs: [
        "STM32F407 Mikrodenetleyici",
        "CAN-Bus İletişim",
        "Akıllı BMS Sistemi",
        "Raspberry Pi 5 - Görüntü İşleme"
      ]
    }
  };

  // Annotation positions (will be adjusted based on actual model)
  const annotationPositions = {
    body: [0, 0.5, 2],
    motor: [-1.5, -0.5, 0],
    battery: [0, -0.5, 0],
    electronics: [1.5, 0.5, 0]
  };

  // Load model with progress tracking
  useEffect(() => {
    // Store the ref in a variable to avoid React warnings
    const currentGroup = group.current;
    
    // Use process.env.PUBLIC_URL to ensure correct path resolution
    const modelPath = process.env.PUBLIC_URL + '/models/model_3d.gltf';
    
    try {
      // Create a simple mesh to use as a fallback
      const createFallbackModel = () => {
        // Simple car shape as fallback
        const car = new THREE.Group();
        
        // Body
        const bodyGeometry = new THREE.BoxGeometry(3, 0.6, 1.3);
        const bodyMaterial = new THREE.MeshStandardMaterial({ 
          color: "#0A0A14", 
          metalness: 0.9, 
          roughness: 0.1
        });
        const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
        body.position.set(0, 0.4, 0);
        body.castShadow = true;
        body.userData.annotationType = 'body';
        car.add(body);
        
        // Add wheels
        const wheelGeometry = new THREE.CylinderGeometry(0.3, 0.3, 0.2, 16);
        const wheelMaterial = new THREE.MeshStandardMaterial({ 
          color: "#050505", 
          metalness: 0.5, 
          roughness: 0.7
        });
        
        const wheelPositions = [
          [0.8, 0, 0.7],
          [0.8, 0, -0.7],
          [-0.8, 0, 0.7],
          [-0.8, 0, -0.7]
        ];
        
        wheelPositions.forEach(position => {
          const wheel = new THREE.Mesh(wheelGeometry, wheelMaterial);
          wheel.rotation.z = Math.PI / 2;
          wheel.position.set(...position);
          wheel.castShadow = true;
          wheel.userData.annotationType = 'wheels';
          car.add(wheel);
        });
        
        // Return the car model
        return car;
      };
      
      try {
      // Try to load the model with proper error handling
      const gltfLoader = new GLTFLoader();
      
      // First attempt to fetch to detect any network issues
      fetch(modelPath)
        .then(response => {
          if (!response.ok) {
            throw new Error(`Failed to fetch model: ${response.status} ${response.statusText}`);
          }
          return response;
        })
        .catch(error => {
          console.error('Model fetch error:', error);
          // Create fallback model if fetch fails
          if (currentGroup) {
            const fallbackModel = createFallbackModel();
            currentGroup.add(fallbackModel);
            setModelLoaded(true);
          }
        });
      
      gltfLoader.load(
          modelPath,
          (gltf) => {
            if (currentGroup) {
              // Clear previous children
              while(currentGroup.children.length > 0) {
                currentGroup.remove(currentGroup.children[0]);
              }
              
              // Add and configure the loaded model
              const model = gltf.scene.clone();
              
              // Optimize and prepare model
              model.traverse((child) => {
                if (child.isMesh) {
                  child.castShadow = true;
                  child.receiveShadow = true;
                  
                  // Performance optimization
                  if (child.geometry) {
                    child.geometry.computeVertexNormals();
                  }
                  
                  // Enhance materials
                  if (child.material) {
                    child.material = child.material.clone(); // Prevent shared materials
                    child.material.roughness = 0.7;
                    child.material.metalness = 0.8;
                    
                    // Add custom userData for interactions
                    if (child.name.toLowerCase().includes('body') || 
                        child.name.toLowerCase().includes('shell') || 
                        child.name.toLowerCase().includes('chassis')) {
                      child.userData.annotationType = 'body';
                    } else if (child.name.toLowerCase().includes('motor') ||
                             child.name.toLowerCase().includes('wheel')) {
                      child.userData.annotationType = 'motor';
                    } else if (child.name.toLowerCase().includes('battery') ||
                             child.name.toLowerCase().includes('cell')) {
                      child.userData.annotationType = 'battery';
                    } else if (child.name.toLowerCase().includes('electronic') ||
                             child.name.toLowerCase().includes('pcb') ||
                             child.name.toLowerCase().includes('circuit')) {
                      child.userData.annotationType = 'electronics';
                    }
                  }
                }
              });
              
              // Center and scale the model
              const box = new THREE.Box3().setFromObject(model);
              const center = box.getCenter(new THREE.Vector3());
              const size = box.getSize(new THREE.Vector3());
              
              model.position.set(-center.x, -center.y, -center.z);
              
              // Scale model to fit view
              const maxDim = Math.max(size.x, size.y, size.z);
              const scale = 2 / maxDim;
              model.scale.set(scale, scale, scale);
              
              // Add to group
              currentGroup.add(model);
              setModelLoaded(true);
            }
          },
          // Progress callback
          (xhr) => {
            if (xhr.lengthComputable) {
              const progress = (xhr.loaded / xhr.total) * 100;
              setLoadingProgress(progress);
            }
          },
          // Error callback - fallback to simple model
          (error) => {
            console.error('Error loading 3D model:', error);
            if (currentGroup) {
              const fallbackModel = createFallbackModel();
              currentGroup.add(fallbackModel);
              setModelLoaded(true);
            }
          }
        );
      } catch (error) {
        console.error('Error initializing model load:', error);
        if (currentGroup) {
          const fallbackModel = createFallbackModel();
          currentGroup.add(fallbackModel);
          setModelLoaded(true);
        }
      }
    } catch (error) {
      console.error('General error:', error);
    }
    
    return () => {
      // Cleanup using the stored ref value
      if (currentGroup) {
        while(currentGroup.children.length > 0) {
          currentGroup.remove(currentGroup.children[0]);
        }
      }
    };
  }, []);

  // Handle model interactions
  const handleModelPointerOver = (e) => {
    e.stopPropagation();
    // Fixed: Changed setHovered to setIsHovered
    setIsHovered(true);
    
    // Check if the intersected object has annotation type
    if (e.object.userData && e.object.userData.annotationType) {
      setActiveAnnotation(e.object.userData.annotationType);
      document.body.style.cursor = 'pointer';
    }
  };
  
  const handleModelPointerOut = () => {
    // Fixed: Changed setHovered to setIsHovered
    setIsHovered(false);
    setActiveAnnotation(null);
    document.body.style.cursor = 'auto';
  };
  
  const handleModelClick = (e) => {
    if (e.object.userData && e.object.userData.annotationType) {
      setActiveAnnotation(e.object.userData.annotationType);
    }
  };

  // Sadece hafif sallanma animasyonu, oto dönmeyi kaldırdık
  useFrame((state) => {
    if (group.current) {
      // Sadece hafif sallanma hareketi
      group.current.position.y = Math.sin(state.clock.getElapsedTime() * 0.5) * 0.05;
    }
  });

  // Render annotations only when model is loaded
  const renderAnnotations = () => {
    if (!modelLoaded) return null;
    
    return Object.keys(technicalSpecs).map((key) => {
      const spec = technicalSpecs[key];
      const position = annotationPositions[key];
      const isActive = activeAnnotation === key;
      
      return (
        <group key={key} position={position}>
          {/* Connection line to model */}
          <line>
            <bufferGeometry attach="geometry">
              <float32BufferAttribute 
                attach="attributes-position" 
                args={[new Float32Array([0,0,0, 0.5,0,0.5]), 3]} 
              />
            </bufferGeometry>
            <lineBasicMaterial 
              attach="material" 
              color={isActive ? "#FF4254" : "#666666"} 
              opacity={isActive ? 1 : 0.3}
              transparent
            />
          </line>
          
          {/* HTML annotation */}
          <Html
            position={[0.6, 0, 0.6]}
            distanceFactor={10}
            occlude
            transform
            sprite
            className={`pointer-events-none transition-opacity duration-300 ${isActive ? 'opacity-100' : 'opacity-0'}`}
          >
            <div className="w-48 bg-white/90 backdrop-blur-md p-2 border border-voltaris-blue/30 rounded text-xs shadow-lg">
              <div className="text-voltaris-blue font-bold mb-1">{spec.title}</div>
              <ul className="text-voltaris-text space-y-1">
                {spec.specs.map((item, i) => (
                  <li key={i} className="flex">
                    <span className="text-voltaris-red mr-1">•</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </Html>
        </group>
      );
    });
  };

  return (
    <group 
      ref={group}
      onPointerOver={handleModelPointerOver}
      onPointerOut={handleModelPointerOut}
      onClick={handleModelClick}
    >
      {renderAnnotations()}
      
      {/* Loading indicator */}
      {!modelLoaded && (
        <Html center>
          <div className="text-center">
            <div className="text-blue-500 mb-2 font-mono text-sm">Model Yükleniyor...</div>
            <div className="w-48 h-1 bg-gray-800 rounded-full overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-red-500 to-blue-500"
                style={{width: `${loadingProgress}%`}}
              ></div>
            </div>
            <div className="text-xs mt-1 text-gray-500">%{Math.round(loadingProgress)}</div>
          </div>
        </Html>
      )}
      
      {/* Placeholder model if real model fails to load */}
      {!modelLoaded && (
        <mesh>
          <boxGeometry args={[1, 0.4, 2]} />
          <meshStandardMaterial color="#333333" />
        </mesh>
      )}
    </group>
  );
};

// Inner component only used in this file
const InnerTechnicalScene = () => {
  return (
    <>
      <color attach="background" args={['#F0F7FF']} />
      
      {/* Enhanced lighting setup */}
      <ambientLight intensity={0.6} />
      <spotLight 
        position={[5, 8, 5]} 
        angle={0.25} 
        penumbra={1} 
        intensity={0.8} 
        castShadow 
        color="#FFFFFF"
      />
      <spotLight 
        position={[-5, 5, -5]} 
        angle={0.3} 
        penumbra={1} 
        intensity={0.6} 
        castShadow 
        color="#FFFFFF"
      />
      
      {/* Accent lighting */}
      <pointLight position={[3, 0, 2]} intensity={0.2} color="#FF4254" />
      <pointLight position={[-3, 0, -2]} intensity={0.2} color="#0044FF" />
      
      <TechnicalCarModel />
      
      {/* Technical grid floor */}
      <mesh 
        rotation={[-Math.PI / 2, 0, 0]} 
        position={[0, -0.8, 0]} 
        receiveShadow
      >
        <planeGeometry args={[30, 30, 50, 50]} />
        <meshStandardMaterial 
          color="#D9E6F7" 
          wireframe={true} 
          emissive="#4A90BF"
          emissiveIntensity={0.05}
        />
      </mesh>
      
      {/* Surrounding environment */}
      <Environment preset="city" />
      
      {/* Technical scale measurements */}
      <group position={[0, -0.79, 0]}>
        <Text
          position={[0, 0, 2.5]}
          rotation={[-Math.PI / 2, 0, 0]}
          color="#555555"
          fontSize={0.1}
          font="/fonts/Inter-Regular.woff"
          anchorX="center"
          anchorY="middle"
        >
          3136mm
        </Text>
        <mesh position={[0, 0, 2.5]}>
          <boxGeometry args={[2, 0.01, 0.01]} />
          <meshBasicMaterial color="#555555" />
        </mesh>
      </group>
      
      {/* Controls with constraints */}
      <OrbitControls 
        enableZoom={true}
        minDistance={2.5}
        maxDistance={8}
        minPolarAngle={Math.PI/6}
        maxPolarAngle={Math.PI/2}
        enablePan={false}
        autoRotate={false}
        zoomSpeed={0.7}
        rotateSpeed={0.5}
      />
    </>
  );
};

// Main component with technical UI elements
const TechnicalModelViewer = () => {
  // Create a ref for the EnhancedModelViewer component
  const modelViewerRef = useRef(null);
  
  return (
    <div className="relative w-full h-52 sm:h-64 md:h-96 lg:h-[420px] rounded-lg overflow-hidden border border-voltaris-neutral-300 shadow-lg shadow-voltaris-neutral-300/20 model-viewer-container">
      {/* Professional UI overlay panel */}
      <div className="absolute left-0 right-0 top-0 z-20 bg-gradient-to-b from-voltaris-neutral-100/90 to-transparent">
        <div className="flex flex-col xs:flex-row items-start xs:items-center justify-between px-2 xs:px-3 py-2 border-b border-voltaris-neutral-300/30">
          <div className="flex items-center flex-wrap gap-2 xs:gap-3 mb-1 xs:mb-0">
            <div className="flex items-center px-2 py-1 bg-voltaris-neutral-50 border-l-2 border-voltaris-red/60 rounded-r status-indicator">
              <div className="h-1.5 w-1.5 rounded-full bg-voltaris-red mr-2 animate-pulse"></div>
              <span className="text-xs font-mono tracking-wide text-voltaris-neutral-700 uppercase">
                Model: <span className="text-voltaris-red font-medium">Active</span>
              </span>
            </div>
            
            <div className="hidden sm:flex items-center">
              <span className="text-xs font-mono tracking-wide text-voltaris-neutral-700 uppercase">
                VOL-1 <span className="text-voltaris-red font-medium">ELEKTROMOBİL</span>
              </span>
            </div>
          </div>
        
          <div className="flex space-x-2 xs:space-x-3 text-xs font-mono">
            <div className="flex items-center px-2 py-1 bg-voltaris-neutral-50 border-r-2 border-voltaris-blue/60 rounded-l">
              <div className="h-1.5 w-1.5 rounded-full bg-voltaris-blue mr-1.5"></div>
              <span className="text-voltaris-neutral-700 uppercase text-[10px] xs:text-xs">Render: <span className="text-voltaris-blue">RT</span></span>
            </div>
            <div className="flex items-center px-2 py-1 bg-voltaris-neutral-50 border-r-2 border-green-500/60 rounded-l">
              <div className="h-1.5 w-1.5 rounded-full bg-green-500 mr-1.5"></div>
              <span className="text-voltaris-neutral-700 uppercase text-[10px] xs:text-xs">Ölçek: <span className="text-green-600">1:32</span></span>
            </div>
          </div>
        </div>
      </div>

      {/* Professional UI overlay panel - bottom */}
      <div className="absolute left-0 right-0 bottom-0 z-20 bg-gradient-to-t from-voltaris-neutral-100/90 to-transparent">
        <div className="flex flex-col xs:flex-row justify-between items-start xs:items-center gap-2 px-2 xs:px-3 py-2 border-t border-voltaris-neutral-300/30">
          <div className="flex flex-wrap items-center gap-2 xs:gap-3 text-[10px] xs:text-xs font-mono">
            <div className="flex items-center px-2 py-1 bg-voltaris-neutral-50 border-l-2 border-voltaris-blue/60 rounded-r">
              <div className="h-1.5 w-1.5 rounded-full bg-voltaris-blue mr-1.5"></div>
              <span className="text-voltaris-neutral-700 uppercase">Zoom: <span className="text-voltaris-blue">Aktif</span></span>
            </div>
            <div className="flex items-center px-2 py-1 bg-voltaris-neutral-50 border-l-2 border-voltaris-red/60 rounded-r">
              <div className="h-1.5 w-1.5 rounded-full bg-voltaris-red mr-1.5"></div>
              <span className="text-voltaris-neutral-700 uppercase">Döndür: <span className="text-voltaris-red">Manuel</span></span>
            </div>
          </div>
          
          <div className="flex space-x-2 items-center">
            <button
              className="text-[10px] xs:text-xs font-mono px-2 xs:px-3 py-1 xs:py-1.5 bg-voltaris-red/10 border border-voltaris-red/30 text-voltaris-red rounded hover:bg-voltaris-red/20 transition-all duration-200 flex items-center shadow-sm"
              onClick={() => {
                if (modelViewerRef.current) {
                  modelViewerRef.current.toggleRotation();
                }
              }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3 mr-1.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10" />
                <path d="M12 6v6l4 2" />
              </svg>
              Dönüşü Yönet
            </button>
            
            <button
              className="text-[10px] xs:text-xs font-mono px-2 xs:px-3 py-1 xs:py-1.5 bg-voltaris-blue/10 border border-voltaris-blue/30 text-voltaris-blue rounded hover:bg-voltaris-blue/20 transition-all duration-200 flex items-center shadow-sm"
              onClick={() => {
                if (modelViewerRef.current) {
                  modelViewerRef.current.resetCameraView();
                }
              }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Merkeze Al
            </button>
          </div>
        </div>
      </div>

      <div className="absolute inset-0 pointer-events-none z-0 opacity-3 bg-technical-grid bg-grid-pattern"></div>
      
      {/* Corner accent lines */}
      <div className="absolute top-0 left-0 w-8 sm:w-16 h-px bg-gradient-to-r from-voltaris-red/30 to-transparent"></div>
      <div className="absolute top-0 left-0 h-8 sm:h-16 w-px bg-gradient-to-b from-voltaris-red/30 to-transparent"></div>
      <div className="absolute top-0 right-0 w-8 sm:w-16 h-px bg-gradient-to-l from-voltaris-blue/30 to-transparent"></div>
      <div className="absolute top-0 right-0 h-8 sm:h-16 w-px bg-gradient-to-b from-voltaris-blue/30 to-transparent"></div>
      <div className="absolute bottom-0 left-0 w-8 sm:w-16 h-px bg-gradient-to-r from-voltaris-blue/30 to-transparent"></div>
      <div className="absolute bottom-0 left-0 h-8 sm:h-16 w-px bg-gradient-to-t from-voltaris-blue/30 to-transparent"></div>
      <div className="absolute bottom-0 right-0 w-8 sm:w-16 h-px bg-gradient-to-l from-voltaris-red/30 to-transparent"></div>
      <div className="absolute bottom-0 right-0 h-8 sm:h-16 w-px bg-gradient-to-t from-voltaris-red/30 to-transparent"></div>
      
      <div className="h-full w-full z-10 overflow-hidden">
        <EnhancedModelViewer ref={modelViewerRef} />
      </div>
    </div>
  );
};

export default TechnicalModelViewer;
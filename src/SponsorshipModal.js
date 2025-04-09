import React, { useState, useEffect } from 'react';
import { X, Check, AlertCircle } from 'lucide-react';

// Sponsorship Modal Component
const SponsorshipModal = ({ isOpen, onClose, currentTier }) => {
  // Form data state - must be defined before any conditional returns
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    company: '',
    phone: '',
    message: ''
  });
  
  // Form status state - must be defined before any conditional returns
  const [status, setStatus] = useState({
    submitting: false,
    submitted: false,
    success: false,
    error: null
  });
  
  // Reset form when the modal opens with a different tier
  useEffect(() => {
    if (isOpen) {
      setFormData({
        name: '',
        email: '',
        company: '',
        phone: '',
        message: ''
      });
      
      setStatus({
        submitting: false,
        submitted: false,
        success: false,
        error: null
      });
    }
  }, [isOpen, currentTier]);
  
  // Don't render anything if not open - must be after hooks are defined
  if (!isOpen) return null;
  
  // Handle input changes
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prevData => ({
      ...prevData,
      [name]: value
    }));
  };
  
  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate form data
    if (!formData.name || !formData.email || !formData.message) {
      setStatus({
        submitting: false,
        submitted: true,
        success: false,
        error: 'Lütfen tüm gerekli alanları doldurun.'
      });
      return;
    }
    
    // Set submitting state
    setStatus({
      submitting: true,
      submitted: false,
      success: false,
      error: null
    });
    
    try {
      // EmailJS configuration
      const emailjsPublicKey = 'YVMxyzABCDEFGHIJKLMNOP'; // Replace with a real key
      const emailjsServiceId = 'service_voltaris';
      const emailjsTemplateId = 'template_sponsorship';
      
      // Format the tier name properly
      const tierName = {
        'platinum': 'Platinum',
        'gold': 'Altın',
        'silver': 'Gümüş',
        'bronze': 'Bronz',
        'supporter': 'Destekçi'
      }[currentTier] || 'Belirtilmedi';
      
      // Format date and time
      const now = new Date();
      const formattedDate = `${now.toLocaleDateString()} ${now.toLocaleTimeString()}`;
      
      // Prepare the template parameters
      const templateParams = {
        from_name: formData.name,
        from_email: formData.email,
        company: formData.company || 'Belirtilmedi',
        phone: formData.phone || 'Belirtilmedi',
        package: tierName,
        message: formData.message,
        date_time: formattedDate,
        subject: `Voltaris Sponsorluk: ${tierName} - ${formData.name}`,
        to_email: 'voltaris.official@gmail.com'
      };
      
      // Load EmailJS dynamically
      if (!window.emailjs) {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/@emailjs/browser@3/dist/email.min.js';
        script.async = true;
        document.body.appendChild(script);
        
        await new Promise((resolve) => {
          script.onload = resolve;
        });
        
        window.emailjs.init(emailjsPublicKey);
      } else if (!window.emailjs.init) {
        window.emailjs.init(emailjsPublicKey);
      }
      
      // Send the email
      const response = await window.emailjs.send(emailjsServiceId, emailjsTemplateId, templateParams);
      console.log('Modal sponsorship email sent successfully:', response);
      
      // Success state
      setStatus({
        submitting: false,
        submitted: true,
        success: true,
        error: null
      });
      
      // Close modal after success (with a delay to show success message)
      setTimeout(() => {
        // Reset form
        setFormData({
          name: '',
          email: '',
          company: '',
          phone: '',
          message: ''
        });
        
        // Close modal
        onClose();
        
        // Reset status
        setStatus({
          submitting: false,
          submitted: false,
          success: false,
          error: null
        });
      }, 2500);
      
    } catch (error) {
      console.error('Modal sponsorship email sending failed:', error);
      
      // Error state
      setStatus({
        submitting: false,
        submitted: true,
        success: false,
        error: 'E-posta gönderilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.'
      });
    }
  };
  
  // Format the title based on tier
  const getTierTitle = () => {
    switch(currentTier) {
      case 'platinum': return 'Platinum Sponsorluk';
      case 'gold': return 'Altın Sponsorluk';
      case 'silver': return 'Gümüş Sponsorluk';
      case 'bronze': return 'Bronz Sponsorluk';
      case 'supporter': return 'Destekçi Paketi';
      default: return 'Sponsorluk';
    }
  };
  
  // Get tier-specific color
  const getTierColor = () => {
    switch(currentTier) {
      case 'platinum': return 'text-gray-600 platinum-text';
      case 'gold': return 'text-yellow-600';
      case 'silver': return 'text-gray-500';
      case 'bronze': return 'text-amber-700';
      case 'supporter': return 'text-blue-600';
      default: return 'text-voltaris-red';
    }
  };
  
  return (
    <div className="fixed inset-0 z-50 overflow-auto bg-voltaris-neutral-800/70 backdrop-blur-md flex items-center justify-center p-4">
      <div className="bg-voltaris-neutral-50 w-full max-w-2xl rounded-lg shadow-xl border border-voltaris-neutral-300 relative transition-all duration-300">
        {/* Special effect for platinum tier */}
        {currentTier === 'platinum' && (
          <div className="absolute inset-0 platinum-shimmer opacity-5 overflow-hidden rounded-lg"></div>
        )}
        
        {/* Close button */}
        <button 
          onClick={onClose}
          className="absolute top-4 right-4 text-voltaris-neutral-600 hover:text-voltaris-neutral-800 transition-colors z-10"
          aria-label="Close"
        >
          <X size={24} />
        </button>
        
        <div className="p-6 relative z-5">
          <h2 className={`text-2xl font-bold mb-4 ${getTierColor()}`}>
            {getTierTitle()}
          </h2>
          
          <div className="mb-6 text-voltaris-neutral-700">
            <p>Voltaris projemize verdiğiniz destek için teşekkür ederiz. Sponsorluk detayları için lütfen iletişim formunu doldurunuz.</p>
          </div>
          
          {status.success ? (
            <div className="bg-green-100 border border-green-500 rounded-lg p-4 flex items-center space-x-3 mb-4">
              <Check size={24} className="text-green-600 flex-shrink-0" />
              <p className="text-green-800">Sponsorluk talebiniz başarıyla alındı. En kısa sürede sizinle iletişime geçeceğiz.</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-voltaris-neutral-700 text-sm mb-1">Adınız Soyadınız <span className="text-voltaris-red">*</span></label>
                  <input 
                    type="text" 
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    className="w-full bg-white border border-voltaris-neutral-300 rounded-lg p-2 text-voltaris-neutral-800 focus:outline-none focus:border-voltaris-red transition-colors"
                    required
                  />
                </div>
                <div>
                  <label className="block text-voltaris-neutral-700 text-sm mb-1">Şirket</label>
                  <input 
                    type="text" 
                    name="company"
                    value={formData.company}
                    onChange={handleChange}
                    className="w-full bg-white border border-voltaris-neutral-300 rounded-lg p-2 text-voltaris-neutral-800 focus:outline-none focus:border-voltaris-red transition-colors"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-voltaris-neutral-700 text-sm mb-1">E-posta <span className="text-voltaris-red">*</span></label>
                <input 
                  type="email" 
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full bg-white border border-voltaris-neutral-300 rounded-lg p-2 text-voltaris-neutral-800 focus:outline-none focus:border-voltaris-red transition-colors"
                  required
                />
              </div>
              
              <div>
                <label className="block text-voltaris-neutral-700 text-sm mb-1">Telefon</label>
                <input 
                  type="tel" 
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  className="w-full bg-white border border-voltaris-neutral-300 rounded-lg p-2 text-voltaris-neutral-800 focus:outline-none focus:border-voltaris-red transition-colors"
                />
              </div>
              
              <div>
                <label className="block text-voltaris-neutral-700 text-sm mb-1">Mesajınız <span className="text-voltaris-red">*</span></label>
                <textarea 
                  rows="4" 
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  className="w-full bg-white border border-voltaris-neutral-300 rounded-lg p-2 text-voltaris-neutral-800 focus:outline-none focus:border-voltaris-red transition-colors"
                  required
                ></textarea>
              </div>
              
              {/* Error message */}
              {status.error && (
                <div className="bg-red-100 border border-red-500 rounded-lg p-3 flex items-start space-x-2">
                  <AlertCircle size={18} className="text-red-600 flex-shrink-0 mt-0.5" />
                  <p className="text-red-800 text-sm">{status.error}</p>
                </div>
              )}
              
              <div className="flex justify-end pt-2">
                <button 
                  type="button"
                  onClick={onClose}
                  className="bg-voltaris-neutral-200 text-voltaris-neutral-700 px-4 py-2 rounded-lg mr-2 hover:bg-voltaris-neutral-300 transition-colors"
                  disabled={status.submitting}
                >
                  İptal
                </button>
                <button 
                  type="submit" 
                  className={`bg-gradient-to-r ${currentTier === 'platinum' ? 'from-[#babac0] via-[#e5e4e2] to-[#babac0] text-gray-800' : 
                    currentTier === 'gold' ? 'from-yellow-500 to-yellow-600 text-white' : 
                    currentTier === 'silver' ? 'from-gray-400 to-gray-500 text-white' : 
                    currentTier === 'bronze' ? 'from-amber-600 to-amber-700 text-white' :
                    'from-blue-500 to-blue-600 text-white'} 
                    px-6 py-2 rounded-lg flex items-center justify-center font-medium transition-all shadow-lg 
                    ${status.submitting ? 'opacity-70 cursor-not-allowed' : 'hover:shadow-xl hover:-translate-y-0.5'}`}
                  disabled={status.submitting}
                >
                  {status.submitting ? 'Gönderiliyor...' : 'Gönder'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};

export default SponsorshipModal;
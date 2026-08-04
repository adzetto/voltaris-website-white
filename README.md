# Voltaris Website

<!-- badges -->
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=white) ![CSS](https://img.shields.io/badge/CSS-1572B6?style=for-the-badge&logo=css3&logoColor=white) ![Shell](https://img.shields.io/badge/Shell-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white) ![Dockerfile](https://img.shields.io/badge/Dockerfile-2496ED?style=for-the-badge&logo=docker&logoColor=white) ![HTML](https://img.shields.io/badge/HTML-E34F26?style=for-the-badge&logo=html5&logoColor=white)

![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=white) ![Tailwind](https://img.shields.io/badge/Tailwind-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

![last commit](https://img.shields.io/github/last-commit/adzetto/voltaris-website-white?style=flat-square&color=informational) ![repo size](https://img.shields.io/github/repo-size/adzetto/voltaris-website-white?style=flat-square&color=informational) ![top language](https://img.shields.io/github/languages/top/adzetto/voltaris-website-white?style=flat-square) ![language count](https://img.shields.io/github/languages/count/adzetto/voltaris-website-white?style=flat-square)


<div align="center">
  <img src="public/logo_sadece.svg" alt="Voltaris Logo" width="150"/>
  <h3>İYTE Elektrikli Araç Takımı - Resmi Web Sitesi</h3>
</div>

## 🚀 Proje Hakkında

Bu repo, İzmir Yüksek Teknoloji Enstitüsü Elektrikli Araç Takımı Voltaris'in resmi web sitesinin kaynak kodlarını içerir. Site, React ve modern web teknolojileri kullanılarak geliştirilmiştir.

## 🛠️ Teknolojiler

- **React.js** - Arayüz geliştirme
- **Three.js / React Three Fiber** - 3D modeller ve animasyonlar
- **TailwindCSS** - Stil ve tasarım
- **Lucide-React** - İkonlar

## 📋 Özellikler

- Responsive tasarım
- 3D araç model görüntüleyici
- Ekip yapısı ve istatistikleri
- ADAS sistem görselleştirmesi
- Sponsorluk paketleri
- İletişim formu

## 🏗️ Yapı

```
voltaris-website/
├── public/               # Statik dosyalar
│   ├── models/           # 3D model dosyaları
│   ├── fonts/            # Font dosyaları
│   ├── sponsors/         # Sponsor görselleri
│   └── team/             # Ekip fotoğrafları
├── src/                  # Kaynak kodlar
│   ├── 3D/               # 3D modeller ve bileşenler
│   ├── components/       # React bileşenleri
│   ├── hooks/            # Özel React hooks
│   ├── utils/            # Yardımcı fonksiyonlar
│   ├── team/             # Ekip verileri ve bileşenleri
│   └── App.js            # Ana uygulama bileşeni
└── package.json          # Proje bağımlılıkları
```

## 📊 Proje Akış Diyagramı

```mermaid
graph TD
    A[Kullanıcı Web Sitesine Girer] --> B[App.js Ana Bileşeni]
    B --> C{Sayfa Yükleniyor}
    C -->|Evet| D[Loading Ekranı Göster]
    C -->|Hayır| E[Ana Sayfa Göster]
    D --> E
    E --> F[3D Model Yükle]
    E --> G[Ekip Verilerini Yükle]
    E --> H[Sponsor Verilerini Yükle]
    
    subgraph Sayfa Navigasyonu
    I[Ana Sayfa] --> J[Hakkımızda]
    J --> K[Teknik Detaylar]
    K --> L[Araç Özellikleri]
    L --> M[ADAS Sistemleri]
    M --> N[Sponsorluk]
    N --> O[İletişim]
    end
    
    subgraph 3D Model İşlemleri
    F --> P[Model Yükle]
    P --> Q{Yükleme Başarılı?}
    Q -->|Evet| R[3D Model Göster]
    Q -->|Hayır| S[Fallback Model Göster]
    R --> T[Interactive Model Controls]
    S --> T
    end
    
    subgraph Responsive Davranış
    E --> U{Ekran Boyutu?}
    U -->|Mobil| V[Mobil Menü Göster]
    U -->|Masaüstü| W[Masaüstü Menü Göster]
    V --> X[Mobil Layout Uygula]
    W --> Y[Masaüstü Layout Uygula]
    end
```

## 🚀 Kurulum

1. Repo'yu klonlayın:
```bash
git clone https://github.com/adzetto/voltaris-website-official.git
cd voltaris-website-official
```

2. Bağımlılıkları yükleyin:
```bash
npm install
```

3. Geliştirme sunucusunu başlatın:
```bash
npm start
```

4. Tarayıcıda `http://localhost:3000` adresine gidin.

## 📦 Derleme

Projeyi üretim için derlemek için:

```bash
npm run build
```

## 🚀 Deployment

GitHub Pages üzerinde yayınlamak için:

```bash
npm run deploy
```

## 📝 Notlar

- 3D modeller için `public/models` dizinindeki dosyaları kullanın
- Sponsorluk ve ekip verileri `src/teamData.js` dosyasında yönetilmektedir

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için `LICENSE` dosyasına bakınız.

## 📞 İletişim

- **E-posta:** voltaris.official@gmail.com
- **Instagram:** [@Voltaris.official](https://www.instagram.com/Voltaris.official/)
- **LinkedIn:** [İYTE Voltaris](https://www.linkedin.com/company/i̇yte-voltaris-teknofest-efficiency-challange/)

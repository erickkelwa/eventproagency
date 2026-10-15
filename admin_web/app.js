/**
 * EventPro Admin Web Application Logic
 * Matches EventPro Flutter Application architecture, data, and visual aesthetics
 */

// ── Live Backend Configuration ──────────────────────────────────
// Points the portal at the deployed Laravel API. The static portal has no
// email/password login, so read-only admin data is fetched using the shared
// admin secret (sent as X-Admin-Secret) which the backend validates against
// config('app.admin_secret'). If no secret / the request fails, every view
// gracefully falls back to the built-in sample data below (demo-safe).
const API_BASE_URL = 'https://eventpro-api-709n.onrender.com/api';
const ADMIN_SECRET_STORAGE = 'eventpro_admin_secret';

function getAdminSecret() {
  return sessionStorage.getItem(ADMIN_SECRET_STORAGE) || '';
}

async function fetchLiveData(path, { prompt = false } = {}) {
  let secret = getAdminSecret();
  if (!secret && prompt) {
    secret = window.prompt(
      'Enter Admin Secret to load LIVE backend data.\nLeave blank to keep using sample data.',
      ''
    ) || '';
    if (secret) sessionStorage.setItem(ADMIN_SECRET_STORAGE, secret);
  }
  if (!secret) return null;
  try {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      headers: { 'X-Admin-Secret': secret, 'Accept': 'application/json' },
    });
    if (!res.ok) return null;
    return await res.json();
  } catch (_) {
    return null;
  }
}

// ── Default State (Matches Flutter App EventModel & ServiceModel) ──
const INITIAL_DATA = {
  events: [
    {
      id: "sol-fest-2026",
      title: "Sol Fest Africa 2026: The Grand Reunion",
      description: "East Africa's premier live concert experience returning bigger than ever! Featuring high-energy performances from Sauti Sol, Bien-Aimé, Nyashinski, and surprise international Afrobeats superstars.",
      category: "Music",
      venue: "Uhuru Gardens Arena, Nairobi",
      address: "Langata Rd, Nairobi, Kenya",
      date: "2026-11-20T18:00:00",
      price: 3500,
      capacity: 12000,
      bookedCount: 8400,
      imageUrl: "https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Sol Generation & EventPro",
      organizerId: "sol_generation",
      isFeatured: true,
      guests: ["Sauti Sol", "Bien-Aimé", "Nyashinski", "Tiwa Savage"],
      highlights: ["360° Revolving Main Stage", "VIP Backstage Lounge", "Gourmet Food Village", "Express M-Pesa Gate"]
    },
    {
      id: "blankets-and-wine-fest",
      title: "Blankets & Wine: Afro-Fusion Festival",
      description: "The legendary urban picnic and lifestyle music festival. Bring your picnic mats, trendy sunglasses, and best vibes for an afternoon of live acoustic soul and artisanal pop-up craft shops.",
      category: "Music",
      venue: "Laurens Garden, Karen",
      address: "Karen Rd, Nairobi",
      date: "2026-11-28T14:00:00",
      price: 3000,
      capacity: 6000,
      bookedCount: 4120,
      imageUrl: "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Blankets & Wine Experience",
      organizerId: "muthoni_drummer",
      isFeatured: true,
      guests: ["Muthoni Drummer Queen", "Karun", "Fena Gitu", "Blinky Bill"],
      highlights: ["Sunset Picnic Lawn", "Artisan Craft Fair", "Curated Wine & Sangria Bar"]
    },
    {
      id: "afrobeats-all-night-2026",
      title: "Afrobeats All Night: Lagos Meets Nairobi",
      description: "A cross-continental Afrobeats collision like no other! Nigeria's hottest chart-toppers fly into Nairobi for a night of non-stop amapiano, afrobeats, and Kenyan gengetone fusion.",
      category: "Music",
      venue: "Carnivore Grounds, Nairobi",
      address: "Langata Rd, Nairobi",
      date: "2026-12-05T20:00:00",
      price: 4000,
      capacity: 8000,
      bookedCount: 5500,
      imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Afrobeats East Africa",
      organizerId: "afrobeats_ke",
      isFeatured: true,
      guests: ["Burna Boy (Special Set)", "Rema", "Nadia Mukami", "Khaligraph Jones"],
      highlights: ["3 Live Stages", "Afrobeats Dance Battle", "VIP Sky Lounge", "Nyama Choma Village"]
    },
    {
      id: "safari-rally-rift-valley",
      title: "Great Rift Valley Offroad Rally & Festival",
      description: "Adrenaline-pumping motorsports action! Watch super-tuned 4x4 rally beasts tear through dramatic volcanic hills, mud stages, and dust bowls. Includes open paddock pit walk.",
      category: "Sports",
      venue: "Soysambu Wildlife Conservancy, Naivasha",
      address: "Naivasha - Nakuru Hwy, Kenya",
      date: "2026-12-12T08:00:00",
      price: 2500,
      capacity: 7500,
      bookedCount: 3800,
      imageUrl: "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Kenya Motorsport Federation",
      organizerId: "motorsport_ke",
      isFeatured: false,
      guests: ["Carl Tundo", "Karan Patel", "Maxine Wahome"],
      highlights: ["Spectator Hill Stage View", "Paddock Pit Access", "Sunset Campfire & BBQ"]
    },
    {
      id: "east-african-art-collective",
      title: "Nairobi Contemporary Art Fair & Gallery Night",
      description: "Explore over 200 striking original paintings, avant-garde bronze sculptures, and digital media art installations from East and Central Africa’s visionary contemporary creators.",
      category: "Art",
      venue: "Nairobi National Museum Gallery",
      address: "Museum Hill, Kipande Rd, Nairobi",
      date: "2026-11-15T10:00:00",
      price: 1000,
      capacity: 1200,
      bookedCount: 480,
      imageUrl: "https://images.unsplash.com/photo-1460661419291-866e9845b612?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Kuona Arts Trust",
      organizerId: "art_collective_ke",
      isFeatured: false,
      guests: ["Michael Soi", "Peterson Kamwathi", "Wambui Collymore"],
      highlights: ["Curator-Led Art Walk", "Live Canvas Painting", "Art Auction Benefiting Youth"]
    },
    {
      id: "devfest-nairobi-2026",
      title: "DevFest Nairobi 2026: Build the Future",
      description: "Google Developer Groups Nairobi's flagship conference! Packed with technical talks and workshops covering Flutter, Firebase, Google Cloud, AI, and Android development.",
      category: "Tech",
      venue: "University of Nairobi Towers",
      address: "University Way, Nairobi CBD",
      date: "2026-12-19T09:00:00",
      price: 1200,
      capacity: 3000,
      bookedCount: 2800,
      imageUrl: "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=1200&auto=format&fit=crop",
      organizerName: "Google Developer Groups Nairobi",
      organizerId: "gdg_nairobi",
      isFeatured: true,
      guests: ["Googler Speakers from Mountain View", "Flutter Kenya Lead", "Google Cloud Architects"],
      highlights: ["30+ Technical Sessions", "Hands-On Codelabs", "Swag Bags & Networking"]
    }
  ],

  services: [
    {
      id: "srv-catering-1",
      name: "Elite Catering & Cuisine",
      description: "Premium catering services for all event types. Buffet, plated, cocktail — we do it all with 5-star quality and hygiene standards.",
      category: "Catering",
      basePrice: 3500,
      priceRange: "KES 3,500 – 12,000 per head",
      rating: 4.8,
      reviewCount: 124,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1555244162-803834f70033?q=80&w=800&auto=format&fit=crop",
      vendorName: "Chef Masters KE",
      phone: "+254 712 345 678",
      email: "orders@chefmasters.co.ke"
    },
    {
      id: "srv-photo-2",
      name: "Pro Lens Photography & Cinema",
      description: "Award-winning event photography and 4K cinematography. We capture crisp moments and cinematic highlights that last forever.",
      category: "Photography",
      basePrice: 25000,
      priceRange: "KES 25,000 – 80,000",
      rating: 4.9,
      reviewCount: 89,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1554048612-b6a482bc67e5?q=80&w=800&auto=format&fit=crop",
      vendorName: "Focus Studio KE",
      phone: "+254 722 987 654",
      email: "booking@focusstudio.co.ke"
    },
    {
      id: "srv-security-3",
      name: "Sentinel Security Solutions",
      description: "Professional licensed security personnel for events of all sizes. Crowd control, VIP executive protection, perimeter security and metal detectors.",
      category: "Security",
      basePrice: 8000,
      priceRange: "KES 8,000 – 30,000",
      rating: 4.6,
      reviewCount: 67,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?q=80&w=800&auto=format&fit=crop",
      vendorName: "Sentinel Security East Africa",
      phone: "+254 733 112 233",
      email: "operations@sentinel.co.ke"
    },
    {
      id: "srv-transport-4",
      name: "VVIP Executive Transport",
      description: "Luxury vehicle fleet for high-profile artist transfers, VIP pickups, and coordinated event guest shuttle services across Kenya.",
      category: "Transport",
      basePrice: 5000,
      priceRange: "KES 5,000 – 50,000",
      rating: 4.7,
      reviewCount: 43,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=800&auto=format&fit=crop",
      vendorName: "Prestige Moves KE",
      phone: "+254 711 556 677",
      email: "vip@prestigemoves.co.ke"
    },
    {
      id: "srv-decor-5",
      name: "Dream Décor & Florals",
      description: "Transforming any arena into a breathtaking aesthetic space. Themed stages, floral tunnels, neon lighting and ambient drapery.",
      category: "Decoration",
      basePrice: 15000,
      priceRange: "KES 15,000 – 200,000",
      rating: 4.9,
      reviewCount: 156,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1478146896981-b80fe463b330?q=80&w=800&auto=format&fit=crop",
      vendorName: "Blooms & Beyond KE",
      phone: "+254 700 889 900",
      email: "hello@bloomsbeyond.co.ke"
    },
    {
      id: "srv-sound-6",
      name: "Stellar Sound, LED & Stage Lighting",
      description: "State-of-the-art concert line arrays, high-resolution outdoor LED video walls, beam moving heads, and digital sound engineers.",
      category: "Sound & Lighting",
      basePrice: 20000,
      priceRange: "KES 20,000 – 150,000",
      rating: 4.7,
      reviewCount: 92,
      isAvailable: true,
      imageUrl: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop",
      vendorName: "Stellar Audio Productions",
      phone: "+254 720 445 566",
      email: "hire@stellaraudio.co.ke"
    }
  ],

  bookings: [
    {
      id: "BKG-9841",
      ticketCode: "TKT-SOL-8492",
      eventId: "sol-fest-2026",
      eventName: "Sol Fest Africa 2026: The Grand Reunion",
      customerName: "Erick Kelwa",
      customerEmail: "erickkelwa9@gmail.com",
      customerPhone: "+254 712 900 123",
      quantity: 2,
      totalAmount: 7350,
      paymentMethod: "M-Pesa STK",
      paymentRef: "QKL892MN10",
      status: "Checked In",
      checkInTime: "2026-10-13 17:42:00",
      date: "2026-10-13 14:22:10"
    },
    {
      id: "BKG-9842",
      ticketCode: "TKT-BW-4819",
      eventId: "blankets-and-wine-fest",
      eventName: "Blankets & Wine: Afro-Fusion Festival",
      customerName: "Amina Wanjiku",
      customerEmail: "amina.w@gmail.com",
      customerPhone: "+254 722 411 902",
      quantity: 3,
      totalAmount: 9450,
      paymentMethod: "Airtel Money",
      paymentRef: "AIRT773619",
      status: "Confirmed",
      checkInTime: null,
      date: "2026-10-13 15:10:45"
    },
    {
      id: "BKG-9843",
      ticketCode: "TKT-AFR-3091",
      eventId: "afrobeats-all-night-2026",
      eventName: "Afrobeats All Night: Lagos Meets Nairobi",
      customerName: "David Ochieng",
      customerEmail: "david.ochieng@gmail.com",
      customerPhone: "+254 733 800 551",
      quantity: 1,
      totalAmount: 4200,
      paymentMethod: "Paystack",
      paymentRef: "PSTK992810",
      status: "Confirmed",
      checkInTime: null,
      date: "2026-10-13 16:04:12"
    },
    {
      id: "BKG-9844",
      ticketCode: "TKT-DEV-5510",
      eventId: "devfest-nairobi-2026",
      eventName: "DevFest Nairobi 2026: Build the Future",
      customerName: "Faith Chebet",
      customerEmail: "fchebet@outlook.com",
      customerPhone: "+254 710 334 221",
      quantity: 2,
      totalAmount: 2520,
      paymentMethod: "PayPal",
      paymentRef: "PAYPAL-4410",
      status: "Confirmed",
      checkInTime: null,
      date: "2026-10-13 16:35:00"
    },
    {
      id: "BKG-9845",
      ticketCode: "TKT-RALLY-7712",
      eventId: "safari-rally-rift-valley",
      eventName: "Great Rift Valley Offroad Rally & Festival",
      customerName: "Brian Mutua",
      customerEmail: "brian.m@gmail.com",
      customerPhone: "+254 725 667 889",
      quantity: 4,
      totalAmount: 10500,
      paymentMethod: "M-Pesa STK",
      paymentRef: "QKL9912PA8",
      status: "Pending",
      checkInTime: null,
      date: "2026-10-13 17:15:30"
    }
  ],

  users: [
    { id: "usr-1", name: "Erick Kelwa", email: "erickkelwa9@gmail.com", role: "Super Admin", status: "Active", eventsManaged: 6, joined: "2026-01-10" },
    { id: "usr-2", name: "Sol Generation Staff", email: "events@solgeneration.ke", role: "Organizer", status: "Active", eventsManaged: 2, joined: "2026-03-14" },
    { id: "usr-3", name: "GDG Nairobi Admins", email: "gdgnairobi@gmail.com", role: "Organizer", status: "Active", eventsManaged: 1, joined: "2026-05-20" },
    { id: "usr-4", name: "Amina Wanjiku", email: "amina.w@gmail.com", role: "Customer", status: "Active", eventsManaged: 0, joined: "2026-07-02" },
    { id: "usr-5", name: "David Ochieng", email: "david.ochieng@gmail.com", role: "Customer", status: "Active", eventsManaged: 0, joined: "2026-08-11" }
  ]
};

// ── Application Class ──────────────────────────────────────────────
class EventProAdmin {
  constructor() {
    this.currentView = 'dashboard';
    this.theme = localStorage.getItem('eventpro_theme') || 'dark';
    this.loadState();
    this.initTheme();
    this.initEventListeners();
    this.renderCurrentView();
    this.initCharts();
  }

  loadState() {
    const saved = localStorage.getItem('eventpro_admin_data');
    if (saved) {
      try {
        this.data = JSON.parse(saved);
      } catch (e) {
        this.data = JSON.parse(JSON.stringify(INITIAL_DATA));
      }
    } else {
      this.data = JSON.parse(JSON.stringify(INITIAL_DATA));
      this.saveState();
    }
  }

  saveState() {
    localStorage.setItem('eventpro_admin_data', JSON.stringify(this.data));
  }

  initTheme() {
    document.documentElement.setAttribute('data-theme', this.theme);
    const themeIcon = document.getElementById('theme-toggle-icon');
    if (themeIcon) {
      themeIcon.className = this.theme === 'dark' ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
    }
  }

  toggleTheme() {
    this.theme = this.theme === 'dark' ? 'light' : 'dark';
    localStorage.setItem('eventpro_theme', this.theme);
    this.initTheme();
    this.showToast(`Switched to ${this.theme} mode`, 'info');
    if (this.currentView === 'dashboard' || this.currentView === 'reports') {
      setTimeout(() => this.initCharts(), 100);
    }
  }

  initEventListeners() {
    // Navigation items
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const view = item.getAttribute('data-view');
        if (view) this.navigateTo(view);
      });
    });

    // Theme toggle button
    const themeBtn = document.getElementById('theme-toggle-btn');
    if (themeBtn) themeBtn.addEventListener('click', () => this.toggleTheme());

    // Mobile menu drawer
    const menuBtn = document.getElementById('mobile-menu-btn');
    const sidebar = document.getElementById('sidebar');
    if (menuBtn && sidebar) {
      menuBtn.addEventListener('click', () => sidebar.classList.toggle('open'));
    }

    // Quick Search Input
    const searchInput = document.getElementById('global-search-input');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => this.handleGlobalSearch(e.target.value));
    }

    // Modal background close
    document.querySelectorAll('.modal-backdrop').forEach(modal => {
      modal.addEventListener('click', (e) => {
        if (e.target === modal) this.closeModals();
      });
    });

    // Keyboard shortcuts
    window.addEventListener('keydown', (e) => {
      if (e.key === '/' && document.activeElement !== searchInput) {
        e.preventDefault();
        searchInput?.focus();
      }
      if (e.key === 'Escape') {
        this.closeModals();
      }
    });
  }

  navigateTo(view) {
    this.currentView = view;
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const activeNav = document.querySelector(`.nav-item[data-view="${view}"]`);
    if (activeNav) activeNav.classList.add('active');

    const sidebar = document.getElementById('sidebar');
    if (sidebar) sidebar.classList.remove('open');

    const viewTitle = document.getElementById('page-title-text');
    const viewSubtitle = document.getElementById('page-subtitle-text');

    const titles = {
      dashboard: ['Dashboard Overview', 'Real-time metrics, event sales & recent operations'],
      events: ['Events Management', 'Curate and publish high-impact live events and concerts'],
      services: ['Services & Vendors', 'Manage suppliers for Catering, Security, Sound, Decor & Transport'],
      bookings: ['Bookings & Tickets', 'Audit attendee reservations, digital tickets and payment receipts'],
      checkin: ['QR Check-In Terminal', 'Validate attendee gate passes and verify ticket security status'],
      reports: ['Financial & Sales Reports', 'Audited breakdown by payment gateway, revenue & capacity'],
      users: ['User & Staff Access', 'Manage administrators, event organizers and attendees']
    };

    if (titles[view]) {
      if (viewTitle) viewTitle.textContent = titles[view][0];
      if (viewSubtitle) viewSubtitle.textContent = titles[view][1];
    }

    this.renderCurrentView();
  }

  renderCurrentView() {
    const container = document.getElementById('main-content-view');
    if (!container) return;

    switch (this.currentView) {
      case 'dashboard':
        container.innerHTML = this.getDashboardHTML();
        this.initCharts();
        break;
      case 'events':
        container.innerHTML = this.getEventsHTML();
        break;
      case 'services':
        container.innerHTML = this.getServicesHTML();
        break;
      case 'bookings':
        container.innerHTML = this.getBookingsHTML();
        break;
      case 'checkin':
        container.innerHTML = this.getCheckInHTML();
        this.initQRReader();
        break;
      case 'reports':
        container.innerHTML = this.getReportsHTML();
        this.initReportCharts();
        break;
      case 'users':
        container.innerHTML = this.getUsersHTML();
        break;
    }
  }

  // ── Calculation Helpers ──────────────────────────────────────────
  getStats() {
    const totalRev = this.data.bookings
      .filter(b => b.status !== 'Cancelled')
      .reduce((acc, curr) => acc + curr.totalAmount, 0);

    const totalTicketsSold = this.data.events
      .reduce((acc, curr) => acc + (curr.bookedCount || 0), 0);

    const totalCapacity = this.data.events
      .reduce((acc, curr) => acc + (curr.capacity || 0), 0);

    const checkIns = this.data.bookings.filter(b => b.status === 'Checked In').length;

    return {
      revenue: totalRev,
      ticketsSold: totalTicketsSold,
      capacity: totalCapacity,
      activeEvents: this.data.events.length,
      activeServices: this.data.services.length,
      checkIns: checkIns,
      totalUsers: this.data.users.length
    };
  }

  formatKES(val) {
    return 'KES ' + Number(val).toLocaleString('en-KE');
  }

  // ── HTML Views ──────────────────────────────────────────────────
  getDashboardHTML() {
    const stats = this.getStats();
    return `
      <div class="stats-grid">
        <div class="stat-card" style="--card-accent: var(--primary);">
          <div class="stat-top">
            <div class="stat-icon"><i class="fa-solid fa-coins"></i></div>
            <div class="stat-trend trend-up"><i class="fa-solid fa-arrow-trend-up"></i> +28.4%</div>
          </div>
          <div class="stat-value">${this.formatKES(stats.revenue)}</div>
          <div class="stat-label">Total Platform Revenue</div>
        </div>

        <div class="stat-card" style="--card-accent: #00C853;">
          <div class="stat-top">
            <div class="stat-icon" style="color: #00C853; background: rgba(0,200,83,0.12);"><i class="fa-solid fa-ticket"></i></div>
            <div class="stat-trend trend-up"><i class="fa-solid fa-arrow-trend-up"></i> +19.1%</div>
          </div>
          <div class="stat-value">${stats.ticketsSold.toLocaleString()}</div>
          <div class="stat-label">Tickets Reserved / Sold</div>
        </div>

        <div class="stat-card" style="--card-accent: #2B90FF;">
          <div class="stat-top">
            <div class="stat-icon" style="color: #2B90FF; background: rgba(43,144,255,0.12);"><i class="fa-solid fa-calendar-star"></i></div>
            <div class="stat-trend trend-up"><i class="fa-solid fa-circle-check"></i> Live</div>
          </div>
          <div class="stat-value">${stats.activeEvents}</div>
          <div class="stat-label">Active Published Events</div>
        </div>

        <div class="stat-card" style="--card-accent: #FFD600;">
          <div class="stat-top">
            <div class="stat-icon" style="color: #FFD600; background: rgba(255,214,0,0.12);"><i class="fa-solid fa-handshake-angle"></i></div>
            <div class="stat-trend trend-up"><i class="fa-solid fa-shield-check"></i> Verified</div>
          </div>
          <div class="stat-value">${stats.activeServices}</div>
          <div class="stat-label">Managed Agency Vendors</div>
        </div>
      </div>

      <!-- Dashboard Charts & Operations -->
      <div class="dashboard-row">
        <div class="card-box">
          <div class="card-header">
            <h3><i class="fa-solid fa-chart-line" style="color: var(--primary);"></i> Revenue & Ticket Trajectory</h3>
            <div class="header-actions">
              <span class="status-badge status-confirmed">Live Synced</span>
            </div>
          </div>
          <div style="height: 290px; width: 100%;">
            <canvas id="revenueChart"></canvas>
          </div>
        </div>

        <div class="card-box">
          <div class="card-header">
            <h3><i class="fa-solid fa-chart-pie" style="color: var(--cat-music);"></i> Category Share</h3>
          </div>
          <div style="height: 290px; width: 100%;">
            <canvas id="categoryChart"></canvas>
          </div>
        </div>
      </div>

      <!-- Recent Bookings Table -->
      <div class="card-box" style="margin-top: 1.5rem;">
        <div class="card-header">
          <h3><i class="fa-solid fa-clock-rotate-left" style="color: var(--primary);"></i> Recent Mobile Bookings & Payments</h3>
          <div class="header-actions">
            <button class="btn-secondary" onclick="adminApp.navigateTo('bookings')">View All</button>
            <button class="btn-primary" onclick="adminApp.openCheckInModal()"><i class="fa-solid fa-qrcode"></i> Quick Scan</button>
          </div>
        </div>
        <div class="table-responsive">
          <table class="data-table">
            <thead>
              <tr>
                <th>Booking ID</th>
                <th>Attendee</th>
                <th>Event / Festival</th>
                <th>Gateway</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${this.data.bookings.slice(0, 5).map(b => `
                <tr>
                  <td><strong>${b.id}</strong><br><small style="color:var(--text-muted);">${b.ticketCode}</small></td>
                  <td>${b.customerName}<br><small style="color:var(--text-muted);">${b.customerPhone}</small></td>
                  <td><strong>${b.eventName}</strong> (${b.quantity} tkts)</td>
                  <td><span class="status-badge" style="background:rgba(247,139,93,0.12); color:var(--primary);">${b.paymentMethod}</span></td>
                  <td><strong>${this.formatKES(b.totalAmount)}</strong></td>
                  <td><span class="status-badge status-${b.status.toLowerCase().replace(/\s/g,'')}">${b.status}</span></td>
                  <td>
                    <button class="btn-icon" onclick="adminApp.viewTicketReceipt('${b.id}')" title="View Digital Ticket">
                      <i class="fa-solid fa-receipt"></i>
                    </button>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  getEventsHTML() {
    return `
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
        <div class="filter-tabs" id="event-filter-tabs">
          <button class="filter-pill active" onclick="adminApp.filterEvents('All', this)">All (${this.data.events.length})</button>
          <button class="filter-pill" onclick="adminApp.filterEvents('Music', this)">Music</button>
          <button class="filter-pill" onclick="adminApp.filterEvents('Sports', this)">Sports</button>
          <button class="filter-pill" onclick="adminApp.filterEvents('Tech', this)">Tech</button>
          <button class="filter-pill" onclick="adminApp.filterEvents('Art', this)">Art</button>
          <button class="filter-pill" onclick="adminApp.filterEvents('Featured', this)">⭐ Featured</button>
        </div>
        <button class="btn-primary" onclick="adminApp.openEventModal()"><i class="fa-solid fa-plus"></i> Create New Event</button>
      </div>

      <div class="items-grid" id="events-grid-container">
        ${this.renderEventCards(this.data.events)}
      </div>
    `;
  }

  renderEventCards(eventsList) {
    if (eventsList.length === 0) {
      return `<div style="grid-column: 1/-1; text-align: center; padding: 3rem; color: var(--text-muted);">No events found matching this filter.</div>`;
    }
    return eventsList.map(e => `
      <div class="item-card">
        <div class="item-card-media">
          <img src="${e.imageUrl}" alt="${e.title}" loading="lazy" onerror="this.src='https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop'">
          <span class="category-tag"><i class="fa-solid fa-tag"></i> ${e.category}</span>
          ${e.isFeatured ? '<span class="featured-star"><i class="fa-solid fa-star"></i></span>' : ''}
        </div>
        <div class="item-card-body">
          <h4 class="item-card-title">${e.title}</h4>
          <p class="item-card-desc">${e.description}</p>
          <div class="item-meta-list">
            <div class="meta-row"><i class="fa-solid fa-location-dot"></i> <span>${e.venue}</span></div>
            <div class="meta-row"><i class="fa-solid fa-calendar-day"></i> <span>${new Date(e.date).toLocaleDateString('en-KE', { weekday:'short', month:'short', day:'numeric', year:'numeric'})}</span></div>
            <div class="meta-row"><i class="fa-solid fa-users"></i> <span>${e.bookedCount.toLocaleString()} / ${e.capacity.toLocaleString()} booked (${Math.round(e.bookedCount/e.capacity*100)}%)</span></div>
          </div>
          <div class="item-card-footer">
            <div class="price-box">
              <span class="price-sub">Ticket Price</span>
              <span class="price-main">${e.price === 0 ? 'FREE' : this.formatKES(e.price)}</span>
            </div>
            <div class="card-action-btns">
              <button class="btn-icon" onclick="adminApp.openEventModal('${e.id}')" title="Edit Event"><i class="fa-solid fa-pen"></i></button>
              <button class="btn-icon btn-danger" onclick="adminApp.deleteEvent('${e.id}')" title="Delete Event"><i class="fa-solid fa-trash"></i></button>
            </div>
          </div>
        </div>
      </div>
    `).join('');
  }

  getServicesHTML() {
    return `
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
        <div class="filter-tabs" id="service-filter-tabs">
          <button class="filter-pill active" onclick="adminApp.filterServices('All', this)">All Services (${this.data.services.length})</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Catering', this)">Catering</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Photography', this)">Photography</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Security', this)">Security</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Transport', this)">Transport</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Sound & Lighting', this)">Sound & Light</button>
          <button class="filter-pill" onclick="adminApp.filterServices('Decoration', this)">Decor</button>
        </div>
        <button class="btn-primary" onclick="adminApp.openServiceModal()"><i class="fa-solid fa-plus"></i> Add Vendor Service</button>
      </div>

      <div class="items-grid" id="services-grid-container">
        ${this.renderServiceCards(this.data.services)}
      </div>
    `;
  }

  renderServiceCards(servicesList) {
    return servicesList.map(s => `
      <div class="item-card">
        <div class="item-card-media">
          <img src="${s.imageUrl}" alt="${s.name}" loading="lazy">
          <span class="category-tag"><i class="fa-solid fa-cube"></i> ${s.category}</span>
        </div>
        <div class="item-card-body">
          <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.25rem;">
            <h4 class="item-card-title">${s.name}</h4>
            <span style="font-size:0.85rem; font-weight:700; color:#FFD600; display:flex; align-items:center; gap:0.25rem;">
              <i class="fa-solid fa-star"></i> ${s.rating} (${s.reviewCount})
            </span>
          </div>
          <p class="item-card-desc">${s.description}</p>
          <div class="item-meta-list">
            <div class="meta-row"><i class="fa-solid fa-building-user"></i> <span>Vendor: <strong>${s.vendorName}</strong></span></div>
            <div class="meta-row"><i class="fa-solid fa-phone"></i> <span>${s.phone || '+254 700 000 000'}</span></div>
            <div class="meta-row"><i class="fa-solid fa-tag"></i> <span>${s.priceRange}</span></div>
          </div>
          <div class="item-card-footer">
            <div class="price-box">
              <span class="price-sub">Starting Base</span>
              <span class="price-main">${this.formatKES(s.basePrice)}</span>
            </div>
            <div class="card-action-btns">
              <button class="btn-icon" onclick="adminApp.openServiceModal('${s.id}')" title="Edit Service"><i class="fa-solid fa-pen"></i></button>
              <button class="btn-icon btn-danger" onclick="adminApp.deleteService('${s.id}')" title="Delete Service"><i class="fa-solid fa-trash"></i></button>
            </div>
          </div>
        </div>
      </div>
    `).join('');
  }

  getBookingsHTML() {
    return `
      <div class="card-box">
        <div class="card-header">
          <h3><i class="fa-solid fa-ticket" style="color: var(--primary);"></i> Attendee Bookings & Issued Tickets (${this.data.bookings.length})</h3>
          <div class="header-actions">
            <button class="btn-secondary" onclick="adminApp.exportBookingsCSV()"><i class="fa-solid fa-download"></i> Export CSV</button>
            <button class="btn-primary" onclick="adminApp.navigateTo('checkin')"><i class="fa-solid fa-qrcode"></i> Check-In Terminal</button>
          </div>
        </div>
        <div class="table-responsive">
          <table class="data-table">
            <thead>
              <tr>
                <th>Ticket ID</th>
                <th>Attendee Name</th>
                <th>Contact</th>
                <th>Event Title</th>
                <th>Quantity</th>
                <th>Total Paid</th>
                <th>Payment Gateway</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${this.data.bookings.map(b => `
                <tr>
                  <td><code>${b.ticketCode}</code></td>
                  <td><strong>${b.customerName}</strong></td>
                  <td>${b.customerPhone}<br><small style="color:var(--text-muted);">${b.customerEmail}</small></td>
                  <td>${b.eventName}</td>
                  <td><strong>${b.quantity}</strong></td>
                  <td><strong style="color:var(--primary);">${this.formatKES(b.totalAmount)}</strong></td>
                  <td><span class="status-badge" style="background:rgba(247,139,93,0.12); color:var(--primary);">${b.paymentMethod}</span></td>
                  <td><span class="status-badge status-${b.status.toLowerCase().replace(/\s/g,'')}">${b.status}</span></td>
                  <td>
                    <div style="display:flex; gap:0.35rem;">
                      <button class="btn-icon" onclick="adminApp.viewTicketReceipt('${b.id}')" title="View Ticket Pass"><i class="fa-solid fa-qrcode"></i></button>
                      ${b.status !== 'Checked In' ? `
                        <button class="btn-icon" style="color:var(--success);" onclick="adminApp.directCheckIn('${b.ticketCode}')" title="Confirm Check-In"><i class="fa-solid fa-check"></i></button>
                      ` : ''}
                    </div>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  getCheckInHTML() {
    return `
      <div class="scanner-container">
        <div class="card-box">
          <div class="card-header">
            <h3><i class="fa-solid fa-camera" style="color:var(--primary);"></i> Gate Camera QR Scanner</h3>
            <span class="status-badge status-confirmed">Live Scanner</span>
          </div>
          <div class="scanner-video-box">
            <div id="reader"></div>
            <div class="scan-laser"></div>
          </div>
          <div style="margin-top: 1.5rem;">
            <div class="form-group">
              <label class="form-label">Or Type / Paste Ticket Code Manually:</label>
              <div style="display:flex; gap:0.5rem;">
                <input type="text" id="manual-ticket-input" class="form-control" placeholder="e.g. TKT-SOL-8492" onkeydown="if(event.key==='Enter') adminApp.verifyTicketCode(this.value)">
                <button class="btn-primary" onclick="adminApp.verifyTicketCode(document.getElementById('manual-ticket-input').value)">Verify</button>
              </div>
            </div>
          </div>
        </div>

        <div class="card-box" id="checkin-verification-result">
          <div class="card-header">
            <h3><i class="fa-solid fa-id-card-clip" style="color:var(--primary);"></i> Verification Terminal</h3>
          </div>
          <div class="checkin-result-card">
            <div class="checkin-avatar"><i class="fa-solid fa-shield-halved"></i></div>
            <h4 style="font-size:1.25rem; margin-bottom:0.35rem;">Awaiting Ticket Scan</h4>
            <p style="color:var(--text-muted); font-size:0.88rem; max-width:320px;">Point attendee QR code at camera or type ticket ID to instantly validate pass authenticity.</p>
          </div>
        </div>
      </div>
    `;
  }

  getReportsHTML() {
    const isLive = !!this.liveReports;
    return `
      <div class="card-box" style="margin-bottom:1.5rem; display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:0.75rem;">
        <div>
          <h3 style="margin:0;"><i class="fa-solid fa-database" style="color:var(--primary);"></i> Data Source</h3>
          <span id="rp-source" class="status-badge" style="margin-top:6px; display:inline-block; background:${isLive ? 'rgba(0,200,83,0.15)' : 'rgba(247,139,93,0.15)'}; color:${isLive ? '#00C853' : 'var(--primary)'};">${isLive ? 'LIVE (backend)' : 'Sample data'}</span>
        </div>
        <button class="btn-primary" onclick="adminApp.loadLiveReports()"><i class="fa-solid fa-rotate"></i> Load Live Data</button>
      </div>

      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-value" id="rp-revenue">${this.formatKES(this.getStats().revenue)}</div>
          <div class="stat-label">Gross Processed Volume</div>
        </div>
        <div class="stat-card">
          <div class="stat-value" id="rp-success">${isLive ? this.liveReports.successRate.toFixed(1) + '%' : '94.8%'}</div>
          <div class="stat-label">Payment Success Rate</div>
        </div>
        <div class="stat-card">
          <div class="stat-value" id="rp-aov">${this.formatKES(isLive ? this.liveReports.aov : 3850)}</div>
          <div class="stat-label">Average Order Value (AOV)</div>
        </div>
        <div class="stat-card">
          <div class="stat-value" id="rp-transactions">${isLive ? this.liveReports.completed : this.getStats().checkIns}</div>
          <div class="stat-label">Completed Transactions</div>
        </div>
      </div>

      <div class="dashboard-row" style="margin-top: 1.5rem;">
        <div class="card-box">
          <div class="card-header">
            <h3><i class="fa-solid fa-credit-card" style="color:var(--primary);"></i> Payment Gateway Distribution</h3>
          </div>
          <div style="height: 300px; width:100%;">
            <canvas id="paymentGatewayChart"></canvas>
          </div>
        </div>
        <div class="card-box">
          <div class="card-header">
            <h3><i class="fa-solid fa-chart-column" style="color:var(--primary);"></i> Revenue — Last 7 Days</h3>
          </div>
          <div style="height: 300px; width:100%;">
            <canvas id="bookingVolumeChart"></canvas>
          </div>
        </div>
      </div>
    `;
  }

  getUsersHTML() {
    return `
      <div class="card-box">
        <div class="card-header">
          <h3><i class="fa-solid fa-users" style="color:var(--primary);"></i> Platform Users & Organizers (${this.data.users.length})</h3>
          <button class="btn-primary" onclick="adminApp.openUserModal()"><i class="fa-solid fa-user-plus"></i> Add User / Organizer</button>
        </div>
        <div class="table-responsive">
          <table class="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
                <th>Events Managed</th>
                <th>Member Since</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${this.data.users.map(u => `
                <tr>
                  <td>
                    <div style="display:flex; align-items:center; gap:0.75rem;">
                      <div class="user-avatar" style="width:34px; height:34px; font-size:0.85rem;">${u.name.charAt(0)}</div>
                      <div>
                        <strong>${u.name}</strong><br>
                        <small style="color:var(--text-muted);">${u.email}</small>
                      </div>
                    </div>
                  </td>
                  <td><span class="status-badge" style="background:rgba(247,139,93,0.15); color:var(--primary);">${u.role}</span></td>
                  <td><span class="status-badge status-active">${u.status}</span></td>
                  <td><strong>${u.eventsManaged}</strong></td>
                  <td>${u.joined}</td>
                  <td>
                    <button class="btn-icon" onclick="adminApp.showToast('Permissions updated for ${u.name}', 'success')"><i class="fa-solid fa-key"></i></button>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ── Charts Initialization ─────────────────────────────────────────
  initCharts() {
    const revEl = document.getElementById('revenueChart');
    const catEl = document.getElementById('categoryChart');
    if (!revEl || !catEl) return;

    if (this.revChartInstance) this.revChartInstance.destroy();
    if (this.catChartInstance) this.catChartInstance.destroy();

    const isDark = this.theme === 'dark';
    const textColor = isDark ? '#B3B3B3' : '#5F6368';
    const gridColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)';

    // Revenue Area Chart
    this.revChartInstance = new Chart(revEl, {
      type: 'line',
      data: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [{
          label: 'Revenue (KES)',
          data: [18000, 32000, 24000, 48000, 65000, 92000, 115000],
          borderColor: '#F78B5D',
          backgroundColor: 'rgba(247, 139, 93, 0.15)',
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointRadius: 4,
          pointBackgroundColor: '#F78B5D'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          x: { grid: { color: gridColor }, ticks: { color: textColor } },
          y: { grid: { color: gridColor }, ticks: { color: textColor } }
        }
      }
    });

    // Category Doughnut Chart
    this.catChartInstance = new Chart(catEl, {
      type: 'doughnut',
      data: {
        labels: ['Music', 'Sports', 'Tech', 'Art', 'Services'],
        datasets: [{
          data: [55, 18, 15, 7, 5],
          backgroundColor: ['#F78B5D', '#00C853', '#2B90FF', '#FF46B9', '#FFD600'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: textColor, font: { size: 11 } } }
        },
        cutout: '72%'
      }
    });
  }

  initReportCharts() {
    const gwEl = document.getElementById('paymentGatewayChart');
    const volEl = document.getElementById('bookingVolumeChart');
    if (!gwEl || !volEl) return;

    if (this.rpGatewayChart) this.rpGatewayChart.destroy();
    if (this.rpVolumeChart) this.rpVolumeChart.destroy();

    const isDark = this.theme === 'dark';
    const textColor = isDark ? '#B3B3B3' : '#5F6368';
    const gridColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)';
    const live = this.liveReports;

    // Payment Gateway Distribution
    const gwLabels = live && live.gatewayLabels.length
      ? live.gatewayLabels
      : ['M-Pesa STK Push', 'Airtel Money', 'Paystack Cards', 'PayPal International'];
    const gwData = live && live.gatewayCounts.length
      ? live.gatewayCounts
      : [68, 14, 11, 7];

    this.rpGatewayChart = new Chart(gwEl, {
      type: 'pie',
      data: {
        labels: gwLabels,
        datasets: [{
          data: gwData,
          backgroundColor: ['#00C853', '#DD2C00', '#2B90FF', '#FFD600', '#FF46B9'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: textColor } } }
      }
    });

    // Revenue — Last 7 Days
    const revLabels = live && live.revenueLabels.length
      ? live.revenueLabels
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const revData = live && live.revenueValues.length
      ? live.revenueValues
      : [18000, 32000, 24000, 48000, 65000, 92000, 115000];

    this.rpVolumeChart = new Chart(volEl, {
      type: 'bar',
      data: {
        labels: revLabels,
        datasets: [{
          label: 'Revenue (KES)',
          data: revData,
          backgroundColor: '#F78B5D',
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { grid: { color: gridColor }, ticks: { color: textColor } },
          y: { grid: { color: gridColor }, ticks: { color: textColor } }
        }
      }
    });
  }

  // Fetch real aggregates from the backend and re-render the reports view.
  async loadLiveReports() {
    this.showToast('Loading live data...', 'info');
    const raw = await fetchLiveData('/admin/reports-data', { prompt: true });
    if (!raw) {
      this.showToast('Could not load live data (wrong secret or offline). Keeping sample data.', 'error');
      return;
    }
    const completed = Number(raw.completed_transactions || 0);
    const failed = Number(raw.failed_transactions || 0);
    const totalTx = completed + failed;
    const rev = Number(raw.total_revenue || 0);
    const gw = Array.isArray(raw.gateways) ? raw.gateways : [];
    const methodLabel = (m) => ({
      mpesa: 'M-Pesa', airtel: 'Airtel Money', paypal: 'PayPal',
      equity: 'Equity Bank', paystack: 'Paystack'
    }[m] || (m || 'Other'));

    this.liveReports = {
      completed,
      successRate: totalTx ? (completed / totalTx) * 100 : 0,
      aov: completed ? rev / completed : 0,
      gatewayLabels: gw.map(g => methodLabel(g.payment_method)),
      gatewayCounts: gw.map(g => Number(g.count) || 0),
      revenueLabels: (raw.revenue_chart || []).map(r => r.day),
      revenueValues: (raw.revenue_chart || []).map(r => Number(r.amount) || 0),
    };

    if (this.currentView === 'reports') this.renderCurrentView();
    else this.showToast('Live data ready — open Reports to view it.', 'success');
  }

  // ── QR Scanner & Verification Logic ────────────────────────────────
  initQRReader() {
    if (typeof Html5QrcodeScanner === 'undefined') return;
    try {
      const scanner = new Html5QrcodeScanner("reader", { fps: 10, qrbox: 250 }, false);
      scanner.render((decodedText) => {
        this.verifyTicketCode(decodedText);
      }, (error) => {
        // scan frame fail (quiet)
      });
    } catch (e) {
      console.warn("Camera scanner not started:", e);
    }
  }

  verifyTicketCode(rawCode) {
    const code = (rawCode || '').trim().toUpperCase();
    if (!code) {
      this.showToast('Please provide a valid ticket code', 'error');
      return;
    }

    const booking = this.data.bookings.find(b => 
      b.ticketCode.toUpperCase() === code || b.id.toUpperCase() === code
    );

    const resultBox = document.getElementById('checkin-verification-result');

    if (!booking) {
      this.showToast('Invalid Ticket: No match found', 'error');
      if (resultBox) {
        resultBox.innerHTML = `
          <div class="card-header"><h3><i class="fa-solid fa-triangle-exclamation" style="color:var(--error);"></i> Verification Failed</h3></div>
          <div class="checkin-result-card">
            <div class="checkin-avatar" style="background:var(--error);"><i class="fa-solid fa-xmark"></i></div>
            <h4 style="color:var(--error); font-size:1.35rem;">Ticket Not Found</h4>
            <p style="color:var(--text-muted); margin:0.5rem 0 1.5rem;">Ticket code <code>${code}</code> was not recognized in the system database.</p>
            <button class="btn-secondary" onclick="adminApp.navigateTo('checkin')">Scan Another</button>
          </div>
        `;
      }
      return;
    }

    const alreadyIn = booking.status === 'Checked In';

    if (resultBox) {
      resultBox.innerHTML = `
        <div class="card-header">
          <h3><i class="fa-solid fa-circle-check" style="color:var(--success);"></i> Ticket Verified</h3>
          <span class="status-badge ${alreadyIn ? 'status-pending' : 'status-confirmed'}">
            ${alreadyIn ? 'Already Checked In' : 'Valid Entry'}
          </span>
        </div>
        <div class="checkin-result-card" style="align-items:flex-start; text-align:left; width:100%;">
          <div style="display:flex; align-items:center; gap:1rem; margin-bottom:1.25rem;">
            <div class="checkin-avatar" style="margin-bottom:0; background:${alreadyIn ? 'var(--warning)' : 'var(--gradient-brand)'};">
              <i class="fa-solid fa-${alreadyIn ? 'user-clock' : 'check'}"></i>
            </div>
            <div>
              <h4 style="font-size:1.35rem; line-height:1.2;">${booking.customerName}</h4>
              <p style="color:var(--text-muted); font-size:0.85rem;">Ticket: <code>${booking.ticketCode}</code> (${booking.quantity} Attendee${booking.quantity > 1 ? 's' : ''})</p>
            </div>
          </div>

          <div class="item-meta-list" style="width:100%; margin-bottom:1.5rem;">
            <div class="meta-row"><i class="fa-solid fa-star"></i> <span>Event: <strong>${booking.eventName}</strong></span></div>
            <div class="meta-row"><i class="fa-solid fa-phone"></i> <span>Phone: <strong>${booking.customerPhone}</strong></span></div>
            <div class="meta-row"><i class="fa-solid fa-envelope"></i> <span>Email: <strong>${booking.customerEmail}</strong></span></div>
            <div class="meta-row"><i class="fa-solid fa-money-bill-wave"></i> <span>Paid: <strong>${this.formatKES(booking.totalAmount)} (${booking.paymentMethod})</strong></span></div>
            ${alreadyIn ? `<div class="meta-row"><i class="fa-solid fa-clock"></i> <span>Admitted at: <strong>${booking.checkInTime}</strong></span></div>` : ''}
          </div>

          <div style="display:flex; gap:0.75rem; width:100%;">
            ${!alreadyIn ? `
              <button class="btn-primary" style="flex:1;" onclick="adminApp.confirmCheckIn('${booking.id}')">
                <i class="fa-solid fa-door-open"></i> Admit & Check In Now
              </button>
            ` : `
              <button class="btn-secondary" style="flex:1;" onclick="adminApp.navigateTo('checkin')">Scan Next Attendee</button>
            `}
          </div>
        </div>
      `;
    }
  }

  confirmCheckIn(bookingId) {
    const booking = this.data.bookings.find(b => b.id === bookingId);
    if (!booking) return;

    booking.status = 'Checked In';
    booking.checkInTime = new Date().toLocaleString('en-KE');
    this.saveState();
    this.showToast(`Checked in ${booking.customerName} successfully!`, 'success');
    this.verifyTicketCode(booking.ticketCode);
  }

  directCheckIn(ticketCode) {
    this.verifyTicketCode(ticketCode);
    const booking = this.data.bookings.find(b => b.ticketCode === ticketCode);
    if (booking && booking.status !== 'Checked In') {
      this.confirmCheckIn(booking.id);
    }
  }

  viewTicketReceipt(bookingId) {
    const booking = this.data.bookings.find(b => b.id === bookingId);
    if (!booking) return;

    const modal = document.getElementById('ticket-modal');
    const body = document.getElementById('ticket-modal-body');
    if (!modal || !body) return;

    body.innerHTML = `
      <div style="text-align:center; padding:1rem 0;">
        <div style="display:inline-block; padding:1rem; background:#fff; border-radius:12px; margin-bottom:1rem; box-shadow:0 4px 20px rgba(0,0,0,0.3);">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${booking.ticketCode}" alt="Ticket QR">
        </div>
        <h3 style="font-size:1.35rem; margin-bottom:0.25rem;">${booking.eventName}</h3>
        <p style="color:var(--text-muted); font-size:0.85rem; margin-bottom:1rem;">Official Gate Pass Receipt</p>
        
        <div style="background:var(--bg-surface); padding:1rem; border-radius:var(--radius-md); text-align:left; font-size:0.88rem; display:flex; flex-direction:column; gap:0.5rem; margin-bottom:1.5rem;">
          <div><strong>Ticket Code:</strong> <code>${booking.ticketCode}</code></div>
          <div><strong>Attendee:</strong> ${booking.customerName}</div>
          <div><strong>Admit:</strong> ${booking.quantity} Person(s)</div>
          <div><strong>Total:</strong> ${this.formatKES(booking.totalAmount)}</div>
          <div><strong>Gateway Ref:</strong> ${booking.paymentRef} (${booking.paymentMethod})</div>
          <div><strong>Status:</strong> <span class="status-badge status-${booking.status.toLowerCase().replace(/\s/g,'')}">${booking.status}</span></div>
        </div>

        <button class="btn-primary" onclick="window.print()"><i class="fa-solid fa-print"></i> Print Ticket Pass</button>
      </div>
    `;

    modal.classList.add('open');
  }

  // ── Event Modal & CRUD ─────────────────────────────────────────────
  openEventModal(eventId = null) {
    const modal = document.getElementById('event-modal');
    const title = document.getElementById('event-modal-title');
    const form = document.getElementById('event-form');
    if (!modal || !form) return;

    if (eventId) {
      const event = this.data.events.find(e => e.id === eventId);
      if (!event) return;
      title.textContent = 'Edit Event: ' + event.title;
      document.getElementById('event-id-field').value = event.id;
      document.getElementById('event-title').value = event.title;
      document.getElementById('event-category').value = event.category;
      document.getElementById('event-venue').value = event.venue;
      document.getElementById('event-price').value = event.price;
      document.getElementById('event-capacity').value = event.capacity;
      document.getElementById('event-booked').value = event.bookedCount;
      document.getElementById('event-image').value = event.imageUrl;
      document.getElementById('event-desc').value = event.description;
      document.getElementById('event-featured').checked = !!event.isFeatured;
    } else {
      title.textContent = 'Create New Event';
      form.reset();
      document.getElementById('event-id-field').value = '';
    }

    modal.classList.add('open');
  }

  saveEvent(e) {
    e.preventDefault();
    const idField = document.getElementById('event-id-field').value;
    const title = document.getElementById('event-title').value.trim();
    const category = document.getElementById('event-category').value;
    const venue = document.getElementById('event-venue').value.trim();
    const price = Number(document.getElementById('event-price').value) || 0;
    const capacity = Number(document.getElementById('event-capacity').value) || 1000;
    const booked = Number(document.getElementById('event-booked').value) || 0;
    const image = document.getElementById('event-image').value.trim() || 'https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop';
    const desc = document.getElementById('event-desc').value.trim();
    const isFeatured = document.getElementById('event-featured').checked;

    if (!title || !venue) {
      this.showToast('Please provide event title and venue', 'error');
      return;
    }

    if (idField) {
      // Edit
      const event = this.data.events.find(ev => ev.id === idField);
      if (event) {
        Object.assign(event, { title, category, venue, price, capacity, bookedCount: booked, imageUrl: image, description: desc, isFeatured });
        this.showToast('Event updated successfully', 'success');
      }
    } else {
      // Create
      const newId = 'evt-' + Date.now();
      this.data.events.unshift({
        id: newId,
        title,
        category,
        venue,
        address: venue + ', Nairobi',
        date: new Date(Date.now() + 86400000 * 14).toISOString(),
        price,
        capacity,
        bookedCount: booked,
        imageUrl: image,
        organizerName: "EventPro Agency",
        organizerId: "admin_user",
        isFeatured,
        description: desc,
        guests: ["Main Act", "Supporting Guests"],
        highlights: ["VIP Fast Track", "Main Arena Access"]
      });
      this.showToast('New event created and published!', 'success');
    }

    this.saveState();
    this.closeModals();
    if (this.currentView === 'events') this.renderCurrentView();
  }

  deleteEvent(id) {
    if (!confirm('Are you sure you want to delete this event? This action cannot be undone.')) return;
    this.data.events = this.data.events.filter(e => e.id !== id);
    this.saveState();
    this.showToast('Event removed', 'warning');
    if (this.currentView === 'events') this.renderCurrentView();
  }

  // ── Service Modal & CRUD ───────────────────────────────────────────
  openServiceModal(serviceId = null) {
    const modal = document.getElementById('service-modal');
    const title = document.getElementById('service-modal-title');
    const form = document.getElementById('service-form');
    if (!modal || !form) return;

    if (serviceId) {
      const s = this.data.services.find(srv => srv.id === serviceId);
      if (!s) return;
      title.textContent = 'Edit Vendor: ' + s.name;
      document.getElementById('service-id-field').value = s.id;
      document.getElementById('service-name').value = s.name;
      document.getElementById('service-category').value = s.category;
      document.getElementById('service-vendor').value = s.vendorName;
      document.getElementById('service-baseprice').value = s.basePrice;
      document.getElementById('service-pricerange').value = s.priceRange;
      document.getElementById('service-phone').value = s.phone || '';
      document.getElementById('service-image').value = s.imageUrl;
      document.getElementById('service-desc').value = s.description;
    } else {
      title.textContent = 'Add Agency Service Vendor';
      form.reset();
      document.getElementById('service-id-field').value = '';
    }

    modal.classList.add('open');
  }

  saveService(e) {
    e.preventDefault();
    const idField = document.getElementById('service-id-field').value;
    const name = document.getElementById('service-name').value.trim();
    const category = document.getElementById('service-category').value;
    const vendor = document.getElementById('service-vendor').value.trim();
    const basePrice = Number(document.getElementById('service-baseprice').value) || 0;
    const priceRange = document.getElementById('service-pricerange').value.trim();
    const phone = document.getElementById('service-phone').value.trim();
    const image = document.getElementById('service-image').value.trim() || 'https://images.unsplash.com/photo-1555244162-803834f70033?q=80&w=800&auto=format&fit=crop';
    const desc = document.getElementById('service-desc').value.trim();

    if (!name || !vendor) {
      this.showToast('Please provide service name and vendor name', 'error');
      return;
    }

    if (idField) {
      const s = this.data.services.find(srv => srv.id === idField);
      if (s) {
        Object.assign(s, { name, category, vendorName: vendor, basePrice, priceRange, phone, imageUrl: image, description: desc });
        this.showToast('Vendor service updated', 'success');
      }
    } else {
      const newId = 'srv-' + Date.now();
      this.data.services.push({
        id: newId,
        name,
        category,
        vendorName: vendor,
        basePrice,
        priceRange: priceRange || `From ${this.formatKES(basePrice)}`,
        phone,
        imageUrl: image,
        description: desc,
        rating: 4.8,
        reviewCount: 1,
        isAvailable: true
      });
      this.showToast('New service vendor added', 'success');
    }

    this.saveState();
    this.closeModals();
    if (this.currentView === 'services') this.renderCurrentView();
  }

  deleteService(id) {
    if (!confirm('Are you sure you want to remove this vendor service?')) return;
    this.data.services = this.data.services.filter(s => s.id !== id);
    this.saveState();
    this.showToast('Vendor service removed', 'warning');
    if (this.currentView === 'services') this.renderCurrentView();
  }

  // ── Filters & Search ──────────────────────────────────────────────
  filterEvents(cat, btn) {
    document.querySelectorAll('#event-filter-tabs .filter-pill').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    let filtered = this.data.events;
    if (cat === 'Featured') {
      filtered = filtered.filter(e => e.isFeatured);
    } else if (cat !== 'All') {
      filtered = filtered.filter(e => e.category.toLowerCase() === cat.toLowerCase());
    }

    const container = document.getElementById('events-grid-container');
    if (container) container.innerHTML = this.renderEventCards(filtered);
  }

  filterServices(cat, btn) {
    document.querySelectorAll('#service-filter-tabs .filter-pill').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    let filtered = this.data.services;
    if (cat !== 'All') {
      filtered = filtered.filter(s => s.category.toLowerCase() === cat.toLowerCase());
    }

    const container = document.getElementById('services-grid-container');
    if (container) container.innerHTML = this.renderServiceCards(filtered);
  }

  handleGlobalSearch(query) {
    const q = (query || '').toLowerCase().trim();
    if (!q) {
      this.renderCurrentView();
      return;
    }

    if (this.currentView === 'events') {
      const filtered = this.data.events.filter(e => 
        e.title.toLowerCase().includes(q) || 
        e.venue.toLowerCase().includes(q) ||
        e.category.toLowerCase().includes(q)
      );
      const container = document.getElementById('events-grid-container');
      if (container) container.innerHTML = this.renderEventCards(filtered);
    } else if (this.currentView === 'services') {
      const filtered = this.data.services.filter(s =>
        s.name.toLowerCase().includes(q) ||
        s.vendorName.toLowerCase().includes(q) ||
        s.category.toLowerCase().includes(q)
      );
      const container = document.getElementById('services-grid-container');
      if (container) container.innerHTML = this.renderServiceCards(filtered);
    } else if (this.currentView === 'bookings') {
      const tbody = document.querySelector('.data-table tbody');
      if (tbody) {
        const matches = this.data.bookings.filter(b =>
          b.customerName.toLowerCase().includes(q) ||
          b.ticketCode.toLowerCase().includes(q) ||
          b.eventName.toLowerCase().includes(q)
        );
        tbody.innerHTML = matches.map(b => `
          <tr>
            <td><code>${b.ticketCode}</code></td>
            <td><strong>${b.customerName}</strong></td>
            <td>${b.customerPhone}</td>
            <td>${b.eventName}</td>
            <td><strong>${b.quantity}</strong></td>
            <td><strong style="color:var(--primary);">${this.formatKES(b.totalAmount)}</strong></td>
            <td><span class="status-badge" style="background:rgba(247,139,93,0.12); color:var(--primary);">${b.paymentMethod}</span></td>
            <td><span class="status-badge status-${b.status.toLowerCase().replace(/\s/g,'')}">${b.status}</span></td>
            <td><button class="btn-icon" onclick="adminApp.viewTicketReceipt('${b.id}')"><i class="fa-solid fa-receipt"></i></button></td>
          </tr>
        `).join('');
      }
    }
  }

  exportBookingsCSV() {
    const headers = ['Booking ID,Ticket Code,Attendee Name,Phone,Email,Event,Quantity,Total (KES),Payment Gateway,Status,Date'];
    const rows = this.data.bookings.map(b => 
      `"${b.id}","${b.ticketCode}","${b.customerName}","${b.customerPhone}","${b.customerEmail}","${b.eventName}",${b.quantity},${b.totalAmount},"${b.paymentMethod}","${b.status}","${b.date}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `EventPro_Bookings_Report_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    this.showToast('Bookings CSV exported successfully', 'success');
  }

  closeModals() {
    document.querySelectorAll('.modal-backdrop').forEach(m => m.classList.remove('open'));
  }

  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const icons = {
      success: 'fa-circle-check',
      error: 'fa-triangle-exclamation',
      warning: 'fa-triangle-exclamation',
      info: 'fa-circle-info'
    };
    toast.innerHTML = `<i class="fa-solid ${icons[type] || 'fa-info'}"></i> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(50px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3500);
  }
}

// ── Initialize App Instance ─────────────────────────────────────────
let adminApp;
document.addEventListener('DOMContentLoaded', () => {
  adminApp = new EventProAdmin();
});

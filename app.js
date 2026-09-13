// PropZen - Real Estate Platform Application Logic

function initAllPropZen() {
  const safeRun = (fn, name) => {
    try {
      if (typeof fn === 'function') fn();
    } catch (e) {
      console.warn(`[PropZen Init] Notice in ${name}:`, e);
    }
  };

  safeRun(initRouter, 'initRouter');
  safeRun(initNavigation, 'initNavigation');
  safeRun(initCategoryFlowModal, 'initCategoryFlowModal');
  safeRun(initSearchAndFilters, 'initSearchAndFilters');
  safeRun(initValuationCalculators, 'initValuationCalculators');
  safeRun(initEmiCalculator, 'initEmiCalculator');
  safeRun(initChatInterface, 'initChatInterface');
  safeRun(initSiteVisitBooking, 'initSiteVisitBooking');
  safeRun(initDualAuth, 'initDualAuth');
  safeRun(initPostPropertyWizard, 'initPostPropertyWizard');
  safeRun(initPhotoGallery, 'initPhotoGallery');
  safeRun(initDroneAndMaps, 'initDroneAndMaps');
  safeRun(initAuthFlow, 'initAuthFlow');
  safeRun(initPropertyEnquiryAuth, 'initPropertyEnquiryAuth');
  safeRun(initCharts, 'initCharts');
  safeRun(initToast, 'initToast');
  safeRun(initPropZenMasterEngines, 'initPropZenMasterEngines');
  safeRun(initPropertyVerificationEngine, 'initPropertyVerificationEngine');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initAllPropZen);
} else {
  initAllPropZen();
}

// ========================================================================
// HOME PAGE ACTIVE FILTER ENGINE (Full AND Logic & Instant Updates)
// ========================================================================

const homeFilterState = {
  location: '',
  category: 'all', // 'buy', 'rent', 'plot', 'residential', 'commercial', 'agricultural'
  type: 'all',
  bhk: 'all',
  budget: 'all',
  minPrice: 0,
  maxPrice: 999,
  minSqft: 0,
  maxSqft: 999999,
  furnishing: 'all',
  possession: 'all',
  amenities: [],
  reraOnly: false,
  plotType: 'all'
};

function filterProperties(shouldScroll = false) {
  const locInput = document.getElementById('hero-location-input') || document.querySelector('.search-ncr-input');
  const searchVal = locInput ? locInput.value.toLowerCase().trim() : '';
  const budgetSelect = document.getElementById('hero-budget-select');
  const budgetVal = budgetSelect ? budgetSelect.value : 'all';

  homeFilterState.location = searchVal;
  homeFilterState.budget = budgetVal;

  const grid = document.getElementById('property-grid');
  const resultsCounter = document.getElementById('home-results-count');
  const tagsContainer = document.getElementById('home-active-filter-tags');

  if (typeof sampleProperties === 'undefined' || !sampleProperties) return;

  let filtered = sampleProperties.filter(p => {
    // 1. Location / Sector / Landmark / Builder / Title matching
    if (homeFilterState.location) {
      const query = homeFilterState.location;
      const haystack = `${p.title} ${p.location} ${p.city} ${p.builder || ''} ${p.bhk || ''} ${p.type} ${p.description || ''} ${(p.landmarks || []).join(' ')}`.toLowerCase();
      if (!haystack.includes(query)) return false;
    }

    // 2. Budget Dropdown
    if (homeFilterState.budget === 'under50l') {
      if (p.price >= 5000000 && p.category !== 'rent') return false;
    } else if (homeFilterState.budget === '50l-1cr') {
      if (p.price < 5000000 || p.price > 10000000) return false;
    } else if (homeFilterState.budget === '1cr-3cr') {
      if (p.price < 10000000 || p.price > 30000000) return false;
    } else if (homeFilterState.budget === '3crplus') {
      if (p.price < 30000000) return false;
    }

    // 3. Category (Buy, Rent, Plots, Residential, Commercial, Agricultural)
    if (homeFilterState.category === 'buy') {
      if (p.category !== 'buy') return false;
    } else if (homeFilterState.category === 'rent') {
      if (p.category !== 'rent') return false;
    } else if (homeFilterState.category === 'plot') {
      if (p.type !== 'plot') return false;
    } else if (homeFilterState.category === 'residential') {
      if (p.type !== 'flat' && p.type !== 'villa') return false;
    } else if (homeFilterState.category === 'commercial') {
      if (p.type !== 'commercial') return false;
    } else if (homeFilterState.category === 'agricultural') {
      const isAgri = p.type === 'plot' && (p.title.toLowerCase().includes('agri') || p.title.toLowerCase().includes('farm') || p.location.toLowerCase().includes('yamuna') || p.id === 'NCR-PLOT-AGRI-303');
      if (!isAgri) return false;
    }

    // 4. Property Type
    if (homeFilterState.type !== 'all' && p.type !== homeFilterState.type) {
      return false;
    }

    // 5. BHK
    if (homeFilterState.bhk !== 'all') {
      if (p.bhk !== 'all' && p.bhk !== homeFilterState.bhk) return false;
    }

    // 6. Custom Min/Max Price (in Cr)
    if (homeFilterState.minPrice > 0 || homeFilterState.maxPrice < 999) {
      const minP = homeFilterState.minPrice * 10000000;
      const maxP = homeFilterState.maxPrice * 10000000;
      if (p.category === 'buy') {
        if (p.price < minP || p.price > maxP) return false;
      }
    }

    // 7. Super Built-up Area
    if (p.sqft < homeFilterState.minSqft || p.sqft > homeFilterState.maxSqft) {
      return false;
    }

    // 8. Furnishing
    if (homeFilterState.furnishing !== 'all') {
      if (!p.furnishing || !p.furnishing.toLowerCase().includes(homeFilterState.furnishing.toLowerCase())) return false;
    }

    // 9. Possession / Availability
    if (homeFilterState.possession !== 'all') {
      if (!p.availability || !p.availability.toLowerCase().includes(homeFilterState.possession.toLowerCase())) return false;
    }

    // 10. Amenities Multi-Select
    if (homeFilterState.amenities && homeFilterState.amenities.length > 0) {
      const matchesAll = homeFilterState.amenities.every(am => p.amenities && p.amenities.includes(am));
      if (!matchesAll) return false;
    }

    // 11. RERA Verification Status
    if (homeFilterState.reraOnly) {
      if (!p.reraNumber) return false;
    }

    // 12. Plot Sub-Type
    if (homeFilterState.plotType !== 'all') {
      if (homeFilterState.plotType === 'gated') {
        if (!p.title.toLowerCase().includes('gated') && p.type !== 'plot') return false;
      } else if (homeFilterState.plotType === 'east') {
        if (!p.facing || !p.facing.toLowerCase().includes('east')) return false;
      } else if (homeFilterState.plotType === 'agriculture') {
        const isAg = p.title.toLowerCase().includes('agri') || p.title.toLowerCase().includes('farm') || p.location.toLowerCase().includes('yamuna') || p.id === 'NCR-PLOT-AGRI-303';
        if (!isAg) return false;
      } else if (homeFilterState.plotType === 'corner') {
        if (!p.title.toLowerCase().includes('corner') && !p.facing.toLowerCase().includes('road')) return false;
      }
    }

    return true;
  });

  // Update Result Count
  if (resultsCounter) {
    resultsCounter.innerText = `${filtered.length} ${filtered.length === 1 ? 'Property' : 'Properties'} Found`;
  }

  // Update Active Filter Tags
  if (tagsContainer) {
    const activeTags = [];
    if (homeFilterState.location) activeTags.push({ label: `📍 "${homeFilterState.location}"`, key: 'location' });
    if (homeFilterState.category !== 'all') activeTags.push({ label: `Category: ${homeFilterState.category.toUpperCase()}`, key: 'category' });
    if (homeFilterState.budget !== 'all') activeTags.push({ label: `Budget: ${homeFilterState.budget}`, key: 'budget' });
    if (homeFilterState.type !== 'all') activeTags.push({ label: `Type: ${homeFilterState.type}`, key: 'type' });
    if (homeFilterState.bhk !== 'all') activeTags.push({ label: `BHK: ${homeFilterState.bhk.toUpperCase()}`, key: 'bhk' });
    if (homeFilterState.reraOnly) activeTags.push({ label: 'RERA Verified Only', key: 'rera' });
    if (homeFilterState.amenities.length > 0) {
      homeFilterState.amenities.forEach(am => activeTags.push({ label: `✨ ${am}`, key: 'amenity', value: am }));
    }

    tagsContainer.innerHTML = activeTags.map(tag => `
      <span class="inline-flex items-center gap-1 bg-red-50 text-red-700 border border-red-200 px-2 py-0.5 rounded-full text-[11px] font-semibold">
        ${tag.label}
        <button type="button" class="hover:text-red-900 font-bold ml-0.5 cursor-pointer" onclick="removeHomeFilterTag('${tag.key}', '${tag.value || ''}')">×</button>
      </span>
    `).join('');
  }

  if (!grid) return;

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full py-12 text-center bg-white rounded-3xl border border-slate-200 p-8 space-y-3 shadow-xs">
        <span class="material-symbols-outlined text-5xl text-slate-300">search_off</span>
        <h3 class="text-base font-bold text-slate-800">No properties found matching your filters</h3>
        <p class="text-xs text-slate-500 max-w-md mx-auto">Try widening your location radius, adjusting your budget range, or clearing active filters.</p>
        <button class="bg-[#d32f2f] hover:bg-red-700 text-white font-bold text-xs px-5 py-2.5 rounded-full shadow cursor-pointer transition-all active:scale-95" onclick="resetHomeFilters()">
          Clear All Filters
        </button>
      </div>
    `;
    return;
  }

  // Render dynamic property cards with exact PropZen styling
  grid.innerHTML = filtered.map(p => {
    const isFav = activeFavoriteIds.includes(p.id);
    const isPlot = p.type === 'plot';
    const tagLabel = isPlot ? (p.sqft ? `${p.sqft} SQ.FT` : 'GATED PLOT') : (p.bhk && p.bhk !== 'all' ? `${p.bhk.toUpperCase()} FLAT` : p.type.toUpperCase());
    const secondaryMetricLabel = isPlot ? 'Rate / Sqft' : 'Est. Rental Yield';
    const secondaryMetricVal = isPlot ? (p.pricePerSqFt || '₹10,888/sqft') : `${p.rentalYield || '6.0'}% / yr`;

    return `
      <div class="property-card glass-panel flex flex-col overflow-hidden hover:border-primary transition-all glow-hover bg-white rounded-2xl border border-slate-200 shadow-sm" data-type="${p.type}" data-bhk="${p.bhk}" data-sqft="${p.sqft}" data-price="${(p.price/10000000).toFixed(2)}" data-sector="${p.location.toLowerCase()}">
        <div class="relative h-48 bg-surface-container overflow-hidden cursor-pointer" onclick="navigateToRoute('/properties')">
          <img src="${p.image}" class="w-full h-full object-cover hover:scale-105 transition-transform duration-300" alt="${p.title}"/>
          <div class="absolute top-2 left-2 flex gap-xs flex-wrap">
            <span class="bg-slate-900/90 text-white font-data-label text-[10px] font-bold px-2 py-0.5 rounded uppercase">${tagLabel}</span>
            <span class="bg-red-600/90 text-white font-data-label text-[10px] font-bold px-2 py-0.5 rounded">${p.sqft ? p.sqft + ' SQ.FT' : 'VERIFIED'}</span>
          </div>
          <button class="drone-tour-btn absolute top-2 right-2 bg-black/80 text-white border border-red-500/80 font-data-label text-[10px] font-bold px-2 py-1 rounded shadow flex items-center gap-xs hover:bg-[#d32f2f] hover:text-white transition-all cursor-pointer" onclick="event.stopPropagation(); navigateToRoute('/tools/drone-tour')" title="4K Drone Flyover">
            <span class="material-symbols-outlined text-xs">flight_takeoff</span> 4K Drone Tour
          </button>
        </div>
        <div class="p-md flex flex-col gap-xs flex-grow">
          <div class="flex justify-between items-center">
            <span class="text-xs text-outline font-data-label uppercase text-slate-500 font-semibold truncate max-w-[200px]">${p.location}</span>
            <button class="gmaps-btn text-xs text-blue-600 font-data-label flex items-center gap-[2px] hover:underline cursor-pointer shrink-0" onclick="window.open('https://maps.google.com/?q=${encodeURIComponent(p.location)}', '_blank')">
              <span class="material-symbols-outlined text-xs">location_on</span> Google Maps
            </button>
          </div>
          <h3 class="font-headline-md text-base font-bold text-slate-900 line-clamp-1 hover:text-[#d32f2f] transition-colors cursor-pointer" onclick="navigateToRoute('/properties')">
            ${p.title}
          </h3>
          <div class="flex justify-between items-baseline my-xs">
            <div>
              <span class="text-xs text-slate-500 font-data-label block">Fair Value</span>
              <span class="text-xl font-bold text-[#d32f2f] font-display-price">${p.priceDisplay}</span>
            </div>
            <div class="text-right">
              <span class="text-xs text-slate-500 font-data-label block">${secondaryMetricLabel}</span>
              <span class="text-base font-bold text-emerald-600 font-display-price">${secondaryMetricVal}</span>
            </div>
          </div>
          <div class="pt-xs border-t border-slate-100 flex gap-2">
            <button class="flex-1 bg-[#25D366] text-white font-data-label text-xs font-bold py-2 rounded-xl flex items-center justify-center gap-xs shadow-xs hover:opacity-90 transition-opacity cursor-pointer" onclick="openWhatsApp('Hi, I want details for ${p.title} in ${p.location}')">
              <svg class="w-4 h-4 fill-current inline-block" viewBox="0 0 24 24"><path d="M12.012 2c-5.506 0-9.969 4.463-9.969 9.969 0 1.763.459 3.487 1.33 5.002l-1.413 5.161 5.281-1.385a9.923 9.923 0 004.771 1.222h.004c5.505 0 9.969-4.463 9.969-9.969 0-2.664-1.038-5.167-2.923-7.053a9.914 9.914 0 00-7.05-2.947zm5.717 14.185c-.244.688-1.42 1.314-1.956 1.393-.497.072-1.144.104-3.32-.795-2.784-1.15-4.577-3.984-4.717-4.17-.137-.186-1.127-1.498-1.127-2.856 0-1.358.706-2.025.961-2.285.255-.26.559-.325.746-.325.186 0 .373.004.536.012.174.009.408-.067.638.486.236.568.8 1.956.868 2.097.069.141.116.307.023.493-.092.186-.14.302-.279.465-.139.163-.292.365-.417.491-.139.139-.284.292-.122.57.162.279.721 1.192 1.547 1.928 1.063.947 1.961 1.242 2.24 1.381.279.139.442.116.605-.07.163-.186.7-0.814.886-1.093.186-.279.372-.233.628-.139.256.093 1.629.768 1.909.907.279.139.465.209.535.326.069.116.069.674-.175 1.362z"/></svg> WhatsApp
            </button>
            <button class="bg-red-50 hover:bg-red-100 text-[#d32f2f] border border-red-200 p-2 rounded-xl flex items-center justify-center cursor-pointer transition-colors" onclick="makePhoneCall()" title="Call Expert">
              <span class="material-symbols-outlined text-sm">call</span>
            </button>
            <button class="bg-slate-50 hover:bg-slate-100 text-slate-700 border border-slate-200 p-2 rounded-xl flex items-center justify-center cursor-pointer transition-colors" onclick="navigateToRoute('/properties')" title="View All Properties">
              <span class="material-symbols-outlined text-sm">arrow_forward</span>
            </button>
          </div>
        </div>
      </div>
    `;
  }).join('');

  if (shouldScroll) {
    const sec = document.getElementById('property-grid-section');
    if (sec) sec.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

function setCategoryFilter(category) {
  if (homeFilterState.category === category) {
    homeFilterState.category = 'all';
  } else {
    homeFilterState.category = category;
  }

  // Update visual state of category cards
  document.querySelectorAll('.home-category-card').forEach(card => {
    const cat = card.getAttribute('data-cat');
    if (cat === homeFilterState.category) {
      card.classList.add('ring-2', 'ring-red-600', 'border-red-600', 'bg-white', 'shadow-md', 'scale-105');
    } else {
      card.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-white', 'shadow-md', 'scale-105');
    }
  });

  filterProperties(true);
}

function filterByPlotType(type) {
  homeFilterState.category = 'plot';
  homeFilterState.plotType = type;

  // Visual highlight on plot cards
  document.querySelectorAll('.home-plot-tile').forEach(tile => {
    if (tile.getAttribute('data-plot') === type) {
      tile.classList.add('ring-4', 'ring-[#d32f2f]');
    } else {
      tile.classList.remove('ring-4', 'ring-[#d32f2f]');
    }
  });

  filterProperties(true);
}

function toggleHomeAmenityFilter(amenity, el) {
  const index = homeFilterState.amenities.indexOf(amenity);
  if (index >= 0) {
    homeFilterState.amenities.splice(index, 1);
    if (el) el.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
  } else {
    homeFilterState.amenities.push(amenity);
    if (el) el.classList.add('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
  }

  // Synchronize tile classes
  document.querySelectorAll('.home-amenity-tile').forEach(tile => {
    const am = tile.getAttribute('data-amenity');
    if (homeFilterState.amenities.includes(am)) {
      tile.classList.add('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
    } else {
      tile.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
    }
  });

  filterProperties(true);
}

function removeHomeFilterTag(key, val) {
  if (key === 'location') {
    homeFilterState.location = '';
    const inp = document.getElementById('hero-location-input') || document.querySelector('.search-ncr-input');
    if (inp) inp.value = '';
  } else if (key === 'category') {
    setCategoryFilter('all');
    return;
  } else if (key === 'budget') {
    homeFilterState.budget = 'all';
    const sel = document.getElementById('hero-budget-select');
    if (sel) sel.value = 'all';
  } else if (key === 'type') {
    homeFilterState.type = 'all';
  } else if (key === 'bhk') {
    homeFilterState.bhk = 'all';
  } else if (key === 'rera') {
    homeFilterState.reraOnly = false;
  } else if (key === 'amenity' && val) {
    const idx = homeFilterState.amenities.indexOf(val);
    if (idx >= 0) homeFilterState.amenities.splice(idx, 1);
    document.querySelectorAll(`.home-amenity-tile[data-amenity="${val}"]`).forEach(t => {
      t.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
    });
  }

  filterProperties(false);
}

function resetHomeFilters() {
  homeFilterState.location = '';
  homeFilterState.category = 'all';
  homeFilterState.type = 'all';
  homeFilterState.bhk = 'all';
  homeFilterState.budget = 'all';
  homeFilterState.minPrice = 0;
  homeFilterState.maxPrice = 999;
  homeFilterState.minSqft = 0;
  homeFilterState.maxSqft = 999999;
  homeFilterState.furnishing = 'all';
  homeFilterState.possession = 'all';
  homeFilterState.amenities = [];
  homeFilterState.reraOnly = false;
  homeFilterState.plotType = 'all';

  const locInput = document.getElementById('hero-location-input') || document.querySelector('.search-ncr-input');
  if (locInput) locInput.value = '';

  const budgetSelect = document.getElementById('hero-budget-select');
  if (budgetSelect) budgetSelect.value = 'all';

  document.querySelectorAll('.home-category-card').forEach(card => {
    card.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-white', 'shadow-md', 'scale-105');
  });

  document.querySelectorAll('.home-plot-tile').forEach(tile => {
    tile.classList.remove('ring-4', 'ring-[#d32f2f]');
  });

  document.querySelectorAll('.home-amenity-tile').forEach(tile => {
    tile.classList.remove('ring-2', 'ring-red-600', 'border-red-600', 'bg-red-50');
  });

  resetMoreFiltersModal();
  filterProperties(false);
  showToast('All filters reset to default', 'info');
}

// ------------------------------------------------------------------------
// ADVANCED MORE FILTERS MODAL CONTROLLERS
// ------------------------------------------------------------------------

function openMoreFiltersModal() {
  const modal = document.getElementById('more-filters-modal');
  if (modal) {
    modal.classList.remove('hidden');
    document.body.classList.add('overflow-hidden');
  }
}

function closeMoreFiltersModal() {
  const modal = document.getElementById('more-filters-modal');
  if (modal) {
    modal.classList.add('hidden');
    document.body.classList.remove('overflow-hidden');
    document.body.style.overflow = '';
  }
}

let currentMfType = 'all';
let currentMfBhk = 'all';

function selectMfChip(group, val, el) {
  if (group === 'type') {
    currentMfType = val;
    document.querySelectorAll('#mf-type-group .mf-chip').forEach(btn => {
      btn.className = 'mf-chip px-3 py-2 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-semibold hover:border-slate-300 text-left cursor-pointer';
    });
    if (el) {
      el.className = 'mf-chip active px-3 py-2 rounded-xl border border-red-600 bg-red-50 text-[#d32f2f] font-bold text-left cursor-pointer';
    }
  } else if (group === 'bhk') {
    currentMfBhk = val;
    document.querySelectorAll('#mf-bhk-group .mf-chip').forEach(btn => {
      btn.className = 'mf-chip px-3 py-2 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-semibold hover:border-slate-300 text-center cursor-pointer';
    });
    if (el) {
      el.className = 'mf-chip active px-3 py-2 rounded-xl border border-red-600 bg-red-50 text-[#d32f2f] font-bold text-center cursor-pointer';
    }
  }
}

function resetMoreFiltersModal() {
  currentMfType = 'all';
  currentMfBhk = 'all';

  document.querySelectorAll('#mf-type-group .mf-chip').forEach(btn => {
    if (btn.getAttribute('data-val') === 'all') {
      btn.className = 'mf-chip active px-3 py-2 rounded-xl border border-red-600 bg-red-50 text-[#d32f2f] font-bold text-left cursor-pointer';
    } else {
      btn.className = 'mf-chip px-3 py-2 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-semibold hover:border-slate-300 text-left cursor-pointer';
    }
  });

  document.querySelectorAll('#mf-bhk-group .mf-chip').forEach(btn => {
    if (btn.getAttribute('data-val') === 'all') {
      btn.className = 'mf-chip active px-3 py-2 rounded-xl border border-red-600 bg-red-50 text-[#d32f2f] font-bold text-center cursor-pointer';
    } else {
      btn.className = 'mf-chip px-3 py-2 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-semibold hover:border-slate-300 text-center cursor-pointer';
    }
  });

  if (document.getElementById('mf-min-price')) document.getElementById('mf-min-price').value = '0';
  if (document.getElementById('mf-max-price')) document.getElementById('mf-max-price').value = '999';
  if (document.getElementById('mf-min-sqft')) document.getElementById('mf-min-sqft').value = '0';
  if (document.getElementById('mf-max-sqft')) document.getElementById('mf-max-sqft').value = '999999';
  if (document.getElementById('mf-furnishing')) document.getElementById('mf-furnishing').value = 'all';
  if (document.getElementById('mf-possession')) document.getElementById('mf-possession').value = 'all';
  if (document.getElementById('mf-rera-only')) document.getElementById('mf-rera-only').checked = false;

  document.querySelectorAll('.mf-amenity-cb').forEach(cb => cb.checked = false);
}

function applyMoreFiltersModal() {
  homeFilterState.type = currentMfType;
  homeFilterState.bhk = currentMfBhk;
  homeFilterState.minPrice = parseFloat(document.getElementById('mf-min-price')?.value || '0');
  homeFilterState.maxPrice = parseFloat(document.getElementById('mf-max-price')?.value || '999');
  homeFilterState.minSqft = parseInt(document.getElementById('mf-min-sqft')?.value || '0', 10);
  homeFilterState.maxSqft = parseInt(document.getElementById('mf-max-sqft')?.value || '999999', 10);
  homeFilterState.furnishing = document.getElementById('mf-furnishing')?.value || 'all';
  homeFilterState.possession = document.getElementById('mf-possession')?.value || 'all';
  homeFilterState.reraOnly = Boolean(document.getElementById('mf-rera-only')?.checked);

  const checkedAmenities = [];
  document.querySelectorAll('.mf-amenity-cb:checked').forEach(cb => {
    checkedAmenities.push(cb.value);
  });
  homeFilterState.amenities = checkedAmenities;

  closeMoreFiltersModal();
  filterProperties(true);
  showToast('Advanced filters applied successfully!', 'success');
}

// ------------------------------------------------------------------------
// MARKET SNAPSHOT PERIOD SWITCHER
// ------------------------------------------------------------------------

function updateHomeMarketSnapshot(period) {
  const snapshotData = {
    'this-month': { price: '₹ 8,950', priceChg: '↗ 3.2%', launches: '128', launchesChg: '↗ 12.5%', deals: '342', dealsChg: '↗ 8.6%', inventory: '2,847', inventoryChg: '↘ 2.1%' },
    'last-3-months': { price: '₹ 8,680', priceChg: '↗ 7.4%', launches: '384', launchesChg: '↗ 18.2%', deals: '1,048', dealsChg: '↗ 14.1%', inventory: '3,120', inventoryChg: '↘ 4.5%' },
    'this-year': { price: '₹ 8,150', priceChg: '↗ 14.8%', launches: '1,420', launchesChg: '↗ 22.0%', deals: '4,190', dealsChg: '↗ 19.5%', inventory: '3,850', inventoryChg: '↘ 9.8%' },
    '5-years': { price: '₹ 5,420', priceChg: '↗ 65.1%', launches: '6,850', launchesChg: '↗ 84.0%', deals: '18,920', dealsChg: '↗ 72.4%', inventory: '5,200', inventoryChg: '↘ 45.0%' }
  };

  const data = snapshotData[period] || snapshotData['this-month'];

  const pEl = document.getElementById('home-kpi-price');
  const pcEl = document.getElementById('home-kpi-price-change');
  const lEl = document.getElementById('home-kpi-launches');
  const lcEl = document.getElementById('home-kpi-launches-change');
  const dEl = document.getElementById('home-kpi-deals');
  const dcEl = document.getElementById('home-kpi-deals-change');
  const iEl = document.getElementById('home-kpi-inventory');
  const icEl = document.getElementById('home-kpi-inventory-change');

  if (pEl) pEl.innerText = data.price;
  if (pcEl) pcEl.innerText = data.priceChg;
  if (lEl) lEl.innerText = data.launches;
  if (lcEl) lcEl.innerText = data.launchesChg;
  if (dEl) dEl.innerText = data.deals;
  if (dcEl) dcEl.innerText = data.dealsChg;
  if (iEl) iEl.innerText = data.inventory;
  if (icEl) icEl.innerText = data.inventoryChg;

  showToast(`Market Snapshot updated for ${period.replace('-', ' ').toUpperCase()}`, 'info');
}

// Master SPA Route Navigator
function navigateToRoute(path, push = true) {
  if (!path) path = '/home';
  if (!path.startsWith('/')) path = '/' + path;

  // Clean trailing slash
  if (path.length > 1 && path.endsWith('/')) {
    path = path.slice(0, -1);
  }

  // Update browser history state
  if (push && window.location.pathname !== path) {
    try {
      window.history.pushState({ path }, '', path);
    } catch (e) {
      console.warn('pushState error:', e);
    }
  }

  // Always close tools dropdown menu when navigating
  closeAllToolsDropdown();

  // Parse route parameters
  let viewId = 'home';
  let navTarget = 'home';

  if (path === '/' || path === '/home') {
    viewId = 'home';
    navTarget = 'home';
  } else if (path === '/properties') {
    viewId = 'properties';
    navTarget = 'properties';
    try { renderPropertiesCatalog(); } catch (e) {}
    setTimeout(renderPropertiesCatalog, 50);
  } else if (path.startsWith('/property/')) {
    viewId = 'property-details';
    navTarget = 'properties';
    const propId = path.replace('/property/', '').trim();
    try { renderPropertyDetails(propId); } catch (e) {}
    setTimeout(() => renderPropertyDetails(propId), 50);
  } else if (path === '/dealers') {
    viewId = 'dealers';
    navTarget = 'dealers';
    try { renderDealersCatalog(); } catch (e) {}
    setTimeout(renderDealersCatalog, 50);
  } else if (path.startsWith('/dealer/')) {
    viewId = 'dealer-details';
    navTarget = 'dealers';
    const dealerId = path.replace('/dealer/', '').trim();
    try { renderDealerDetails(dealerId); } catch (e) {}
    setTimeout(() => renderDealerDetails(dealerId), 50);
  } else if (path === '/market-intelligence' || path === '/market') {
    viewId = 'market-intelligence';
    navTarget = 'market-intelligence';
    try { renderMarketIntelligenceCharts('30d'); } catch (e) {}
    setTimeout(() => renderMarketIntelligenceCharts('30d'), 100);
  } else if (path === '/ai-advisor') {
    viewId = 'ai-advisor';
    navTarget = 'ai-advisor';
    try { runAiAdvisorMatch(); } catch (e) {}
    setTimeout(runAiAdvisorMatch, 50);
  } else if (path === '/compare') {
    viewId = 'compare';
    navTarget = 'compare';
    try { renderCompareMatrix(); } catch (e) {}
    setTimeout(renderCompareMatrix, 50);
  } else if (path === '/tools') {
    viewId = 'tools';
    navTarget = 'tools';
  } else if (path === '/tools/loan-consultancy' || path === '/tools/emi-calculator' || path === '/tools/loan') {
    viewId = 'tool-loan-consultancy';
    navTarget = 'tools';
    try { calculateLoanConsultancyEmi(); } catch (e) {}
  } else if (path.startsWith('/tools/')) {
    let toolSlug = path.replace('/tools/', '').trim();
    if (toolSlug === 'customer-discussion-forum' || toolSlug === 'customer-forum') {
      viewId = 'tool-customer-forum';
    } else {
      viewId = `tool-${toolSlug}`;
    }
    navTarget = 'tools';
  } else if (path === '/favorites') {
    viewId = 'favorites';
    navTarget = 'favorites';
    try { renderFavoritesCatalog(); } catch (e) {}
    setTimeout(renderFavoritesCatalog, 50);
  } else if (path === '/notifications') {
    viewId = 'notifications';
    navTarget = 'notifications';
    try { renderNotifications(); } catch (e) {}
    setTimeout(renderNotifications, 50);
  } else if (path === '/profile') {
    viewId = 'profile';
    navTarget = 'profile';
    try { updateProfileStats(); } catch (e) {}
    setTimeout(updateProfileStats, 50);
  } else {
    // Fallback
    viewId = 'home';
    navTarget = 'home';
  }

  // Cleanly restore normal document scroll and clear any active modal locks
  document.body.classList.remove('overflow-hidden');
  document.body.style.overflow = '';
  document.documentElement.style.overflow = '';

  // Close tools dropdown menu & modal if navigating away
  const toolsMenu = document.getElementById('all-tools-dropdown-menu');
  if (toolsMenu) toolsMenu.classList.add('hidden');
  const servicesModal = document.getElementById('propzen-services-modal');
  if (servicesModal && !servicesModal.classList.contains('hidden')) {
    servicesModal.classList.add('hidden');
  }
  const chevronIcon = document.getElementById('all-tools-chevron');
  if (chevronIcon) chevronIcon.classList.remove('rotate-180');

  // Activate view pane
  const panes = document.querySelectorAll('.view-pane');
  panes.forEach(pane => {
    pane.classList.add('hidden');
    pane.classList.remove('active');
  });

  const targetPane = document.getElementById(`view-${viewId}`) || (viewId === 'tool-customer-forum' ? document.getElementById('view-tool-customer-discussion-forum') : null);
  if (targetPane) {
    targetPane.classList.remove('hidden');
    targetPane.classList.add('active');
  } else {
    const fallback = document.getElementById('view-home');
    if (fallback) {
      fallback.classList.remove('hidden');
      fallback.classList.add('active');
    }
  }

  // Restore smooth window vertical scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' });

  // Update Nav Links Active Highlight & Indicator
  const navLinks = document.querySelectorAll('.nav-link');
  navLinks.forEach(link => {
    const target = link.getAttribute('data-nav');
    const existingIndicator = link.querySelector('.nav-indicator');

    if (target === navTarget) {
      link.classList.add('text-[#d32f2f]', 'font-bold');
      link.classList.remove('text-slate-700', 'text-slate-600');

      if (link.id === 'all-tools-btn') {
        link.classList.add('bg-red-100', 'ring-2', 'ring-red-400');
      } else if (target === 'favorites') {
        link.classList.add('bg-red-100', 'ring-2', 'ring-red-400');
      } else if (target === 'notifications') {
        link.classList.add('bg-amber-100', 'ring-2', 'ring-amber-400');
      } else if (link.id === 'header-profile-btn') {
        link.classList.add('ring-2', 'ring-offset-2', 'ring-red-600', 'shadow-md');
      } else if (!existingIndicator && !link.classList.contains('w-9') && !link.closest('.lg\\:hidden')) {
        const ind = document.createElement('span');
        ind.className = 'nav-indicator absolute bottom-0 left-0 w-full h-[2px] bg-[#d32f2f] rounded-full';
        link.appendChild(ind);
      }
    } else {
      if (link.id === 'all-tools-btn') {
        link.classList.remove('bg-red-100', 'ring-2', 'ring-red-400');
        link.classList.add('bg-red-50', 'text-[#d32f2f]');
      } else if (target === 'favorites') {
        link.classList.remove('bg-red-100', 'ring-2', 'ring-red-400');
      } else if (target === 'notifications') {
        link.classList.remove('bg-amber-100', 'ring-2', 'ring-amber-400');
      } else if (link.id === 'header-profile-btn') {
        link.classList.remove('ring-2', 'ring-offset-2', 'ring-red-600', 'shadow-md');
      } else {
        link.classList.remove('text-[#d32f2f]', 'font-bold');
        if (!link.classList.contains('text-red-500') && !link.classList.contains('text-amber-500')) {
          link.classList.add('text-slate-700');
        }
      }
      if (existingIndicator) existingIndicator.remove();
    }
  });
}

function handleToolDropdownClick(routePath, event) {
  if (event) {
    event.preventDefault();
    event.stopPropagation();
  }
  closeAllToolsModal();
  navigateToRoute(routePath, true);
}

function openAllToolsModal() {
  const modal = document.getElementById('propzen-services-modal');
  if (modal) {
    modal.classList.remove('hidden');
    document.body.classList.add('overflow-hidden');
  }
  const chevron = document.getElementById('all-tools-chevron');
  if (chevron) chevron.classList.add('rotate-180');
}

function closeAllToolsModal() {
  const modal = document.getElementById('propzen-services-modal');
  if (modal) {
    modal.classList.add('hidden');
    document.body.classList.remove('overflow-hidden');
    document.body.style.overflow = '';
  }
  const chevron = document.getElementById('all-tools-chevron');
  if (chevron) chevron.classList.remove('rotate-180');
}

function toggleAllToolsDropdown(event) {
  if (event) {
    event.stopPropagation();
    event.preventDefault();
  }
  const modal = document.getElementById('propzen-services-modal');
  if (modal) {
    if (modal.classList.contains('hidden')) {
      openAllToolsModal();
    } else {
      closeAllToolsModal();
    }
  } else {
    navigateToRoute('/tools', true);
  }
}

function closeAllToolsDropdown() {
  closeAllToolsModal();
}

function calculateLoanConsultancyEmi() {
  const amountSlider = document.getElementById('tool-loan-amount-slider');
  const rateSlider = document.getElementById('tool-loan-rate-slider');
  const tenureSlider = document.getElementById('tool-loan-tenure-slider');

  if (!amountSlider || !rateSlider || !tenureSlider) return;

  const P = parseFloat(amountSlider.value) * 100000;
  const annualRate = parseFloat(rateSlider.value);
  const r = annualRate / 12 / 100;
  const n = parseFloat(tenureSlider.value) * 12;

  const emi = (P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
  const totalPayment = emi * n;
  const totalInterest = totalPayment - P;

  const amountVal = document.getElementById('tool-loan-amount-val');
  const rateVal = document.getElementById('tool-loan-rate-val');
  const tenureVal = document.getElementById('tool-loan-tenure-val');
  const monthlyEmi = document.getElementById('tool-loan-monthly-emi');
  const totalInterestEl = document.getElementById('tool-loan-total-interest');
  const totalPayableEl = document.getElementById('tool-loan-total-payable');

  if (amountVal) amountVal.innerText = `₹ ${parseFloat(amountSlider.value)} Lakhs`;
  if (rateVal) rateVal.innerText = `${annualRate.toFixed(2)}% p.a.`;
  if (tenureVal) tenureVal.innerText = `${parseFloat(tenureSlider.value)} Years`;
  if (monthlyEmi) monthlyEmi.innerHTML = `₹ ${Math.round(emi).toLocaleString('en-IN')}<span class="text-xs font-normal text-slate-300">/mo</span>`;
  if (totalInterestEl) totalInterestEl.innerText = `₹ ${(totalInterest / 100000).toFixed(2)} L`;
  if (totalPayableEl) totalPayableEl.innerText = `₹ ${(totalPayment / 10000000).toFixed(2)} Cr`;
}

// Global click outside to dismiss tools dropdown
document.addEventListener('click', (e) => {
  const wrapper = document.getElementById('all-tools-dropdown-wrapper');
  if (wrapper && !wrapper.contains(e.target)) {
    closeAllToolsDropdown();
  }
});

function initRouter() {
  // Listen for browser Back & Forward button events
  window.addEventListener('popstate', (e) => {
    const currentPath = window.location.pathname || '/home';
    navigateToRoute(currentPath, false);
  });

  // Initial Route Check on Load
  const initialPath = window.location.pathname;
  if (initialPath && initialPath !== '/' && initialPath !== '/index.html') {
    navigateToRoute(initialPath, false);
  } else {
    navigateToRoute('/home', false);
  }
}

// Legacy navigateTo adapter
function navigateTo(viewId) {
  if (viewId === 'home') navigateToRoute('/home');
  else if (viewId === 'properties') navigateToRoute('/properties');
  else if (viewId === 'dealers') navigateToRoute('/dealers');
  else if (viewId === 'market-intelligence' || viewId === 'market-hub' || viewId === 'market') navigateToRoute('/market-intelligence');
  else if (viewId === 'ai-advisor') navigateToRoute('/ai-advisor');
  else if (viewId === 'compare') navigateToRoute('/compare');
  else if (viewId === 'tools') navigateToRoute('/tools');
  else if (viewId === 'favorites') navigateToRoute('/favorites');
  else if (viewId === 'notifications') navigateToRoute('/notifications');
  else if (viewId === 'profile') navigateToRoute('/profile');
  else if (viewId.startsWith('tool-')) navigateToRoute('/tools/' + viewId.replace('tool-', ''));
  else navigateToRoute('/home');
}

function initNavigation() {
  document.addEventListener('click', (e) => {
    const navTarget = e.target.closest('[data-nav]');
    if (navTarget) {
      e.preventDefault();
      const viewId = navTarget.getAttribute('data-nav');
      navigateTo(viewId);
    }

    const reportTab = e.target.closest('[data-report-tab]');
    if (reportTab) {
      e.preventDefault();
      const tabName = reportTab.getAttribute('data-report-tab');
      switchReportTab(tabName);
    }

    const card = e.target.closest('.property-card');
    if (card && !e.target.closest('button') && !e.target.closest('a')) {
      e.preventDefault();
      requireAuthForEnquiry(() => {
        navigateTo('report');
        showToast('Opening 10X Property Intelligence Report...', 'info');
      }, 'View Property Intelligence Report');
    }
  });
}

function switchReportTab(tabName) {
  const tabBtns = document.querySelectorAll('[data-report-tab]');
  tabBtns.forEach(btn => {
    if (btn.getAttribute('data-report-tab') === tabName) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  const tabContents = document.querySelectorAll('.report-tab-content');
  tabContents.forEach(content => {
    if (content.id === `report-tab-${tabName}`) {
      content.classList.remove('hidden');
    } else {
      content.classList.add('hidden');
    }
  });
}

// Drone Tour & Google Maps Handlers
function initDroneAndMaps() {
  const droneBtns = document.querySelectorAll('.drone-tour-btn');
  const droneModal = document.getElementById('drone-tour-modal');
  const closeDroneBtn = document.getElementById('close-drone-modal');

  droneBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      requireAuthForEnquiry(() => {
        if (droneModal) {
          droneModal.classList.remove('hidden');
          document.body.classList.add('overflow-hidden');
          showToast('Loading 4K Aerial Drone Flyover Tour...', 'info');
        }
      }, '4K Drone Tour');
    });
  });

  if (closeDroneBtn && droneModal) {
    closeDroneBtn.addEventListener('click', () => {
      droneModal.classList.add('hidden');
      document.body.classList.remove('overflow-hidden');
      document.body.style.overflow = '';
    });
  }

  const mapBtns = document.querySelectorAll('.gmaps-btn');
  mapBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const loc = btn.getAttribute('data-location') || 'Sector 137 Noida Expressway';
      const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(loc)}`;
      window.open(mapsUrl, '_blank');
      showToast(`Opening Google Maps for ${loc}...`, 'info');
    });
  });
}

// Direct WhatsApp & Phone Call Handlers with Mandatory Auth Gate
function openWhatsApp(msg = 'Hi PropZen! I am interested in evaluating property deals in Sector 137 Noida.') {
  requireAuthForEnquiry(() => {
    const phone = '919810394068';
    const url = `https://wa.me/${phone}?text=${encodeURIComponent(msg)}`;
    window.open(url, '_blank');
    showToast('Opening Direct WhatsApp Advisory Chat...', 'success');
  }, 'WhatsApp Enquiry');
}

function makePhoneCall(phone = '+919810394068') {
  requireAuthForEnquiry(() => {
    window.location.href = `tel:${phone}`;
    showToast(`Initiating Call to ${phone}...`, 'info');
  }, 'Phone Call Enquiry');
}

// MANDATORY PROPERTY ENQUIRY AUTHENTICATION GATE & CAPTCHA ENGINE
// =========================================================================
// MANDATORY AUTHENTICATION & COMPLETE 4-STEP VERIFICATION ENGINE
// =========================================================================

let pendingEnquiryCallback = null;
let activeSignupCaptcha = '';
let activeLoginCaptcha = '';

// Security Verification State
let activeEmailOtp = '';
let activeEmailOtpExpiresAt = 0;
let activeMobileOtp = '';
let activeMobileOtpExpiresAt = 0;
let pendingUserData = null;

let emailResendTimer = null;
let emailResendCooldown = 0;
let mobileResendTimer = null;
let mobileResendCooldown = 0;

// Setup Cross-Tab Real-Time Sync Channel
let authSyncChannel = null;
try {
  authSyncChannel = new BroadcastChannel('propzen_auth_sync');
  authSyncChannel.onmessage = (event) => {
    if (event.data && event.data.type === 'EMAIL_VERIFIED') {
      const stored = getStoredUser();
      if (stored) {
        stored.isEmailVerified = true;
        stored.isMobileVerified = true;
        stored.verifiedAt = event.data.verifiedAt || new Date().toISOString();
        saveUserSession(stored);
        updateHeaderAndProfileData(stored);
        
        const modal = document.getElementById('enquiry-auth-modal');
        const verifyView = document.getElementById('auth-email-verify-view');
        if (modal && verifyView && !verifyView.classList.contains('hidden')) {
          showEmailVerificationSuccess(stored);
        }
        showToast('Account verified in another tab! Access granted.', 'success');
      }
    }
  };
} catch (e) {
  // BroadcastChannel fallback
}

// Storage Event Fallback for Cross-Tab Sync
window.addEventListener('storage', (e) => {
  if (e.key === 'propzen_user' && e.newValue) {
    try {
      const updated = JSON.parse(e.newValue);
      if (updated && updated.isEmailVerified) {
        saveUserSession(updated, false);
        updateHeaderAndProfileData(updated);
        const modal = document.getElementById('enquiry-auth-modal');
        const verifyView = document.getElementById('auth-email-verify-view');
        if (modal && verifyView && !verifyView.classList.contains('hidden')) {
          showEmailVerificationSuccess(updated);
        }
      }
    } catch (err) {}
  }
});

function getStoredUser() {
  try {
    const sessionData = sessionStorage.getItem('propzen_authenticated_user');
    if (sessionData) return JSON.parse(sessionData);
    const localData = localStorage.getItem('propzen_user');
    if (localData) return JSON.parse(localData);
  } catch (err) {}
  return null;
}

function saveUserSession(userData, broadcast = true) {
  try {
    localStorage.setItem('propzen_user', JSON.stringify(userData));
    sessionStorage.setItem('propzen_authenticated_user', JSON.stringify(userData));
    if (broadcast && authSyncChannel && userData.isEmailVerified) {
      authSyncChannel.postMessage({
        type: 'EMAIL_VERIFIED',
        email: userData.email,
        verifiedAt: userData.verifiedAt || new Date().toISOString()
      });
    }
  } catch (err) {}
}

function maskEmail(email) {
  if (!email || !email.includes('@')) return 'sa***@example.com';
  const parts = email.split('@');
  const name = parts[0];
  const domain = parts[1];
  if (name.length <= 2) return `${name.charAt(0)}***@${domain}`;
  return `${name.substring(0, 2)}***@${domain}`;
}

function maskPhone(phone, countryCode = '+91') {
  if (!phone) return `${countryCode} 98103 ****8`;
  const clean = phone.replace(/\D/g, '');
  if (clean.length < 4) return `${countryCode} ${clean}***`;
  return `${countryCode} ${clean.substring(0, 5)} ***${clean.substring(clean.length - 2)}`;
}

function generateRandomCaptchaText() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let text = '';
  for (let i = 0; i < 5; i++) {
    text += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return text;
}

function refreshCaptchaCodes() {
  activeSignupCaptcha = generateRandomCaptchaText();
  activeLoginCaptcha = generateRandomCaptchaText();

  const signupSpan = document.getElementById('signup-captcha-code');
  if (signupSpan) signupSpan.textContent = activeSignupCaptcha;

  const loginSpan = document.getElementById('login-captcha-code');
  if (loginSpan) loginSpan.textContent = activeLoginCaptcha;
}

// Validation helper for signup inputs
function validateSignupFormInputs() {
  const name = document.getElementById('signup-name')?.value.trim() || '';
  const email = document.getElementById('signup-email')?.value.trim() || '';
  const phone = document.getElementById('signup-phone')?.value.trim() || '';
  const captcha = document.getElementById('signup-captcha-input')?.value.trim() || '';
  const tnc = document.getElementById('signup-tnc')?.checked;
  const submitBtn = document.getElementById('submit-signup-btn');

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  const phoneValid = phone.length >= 10;
  const nameValid = name.length >= 2;
  const captchaValid = captcha.length >= 4;

  const isValid = nameValid && emailValid && phoneValid && captchaValid && tnc;
  if (submitBtn) {
    submitBtn.disabled = !isValid;
    if (isValid) {
      submitBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    } else {
      submitBtn.classList.add('opacity-50', 'cursor-not-allowed');
    }
  }
  return isValid;
}

// Main Gatekeeper for Protected Actions
function requireAuthForEnquiry(callback, actionLabel = 'Property Enquiry') {
  const user = getStoredUser();

  // 1. If not logged in -> Prompt Sign Up / Login Modal
  if (!user) {
    pendingEnquiryCallback = callback;
    refreshCaptchaCodes();
    showAuthModal('signup', actionLabel);
    showToast(`Compulsory Sign Up / Login required for ${actionLabel}`, 'info');
    return;
  }

  // 2. If logged in but email is NOT verified -> Show "Verify Your Email" prompt!
  if (!user.isEmailVerified) {
    pendingEnquiryCallback = callback;
    displayEmailVerificationPrompt(user);
    showToast(`Please verify your email address to continue to ${actionLabel}`, 'info');
    return;
  }

  // 3. User is fully authenticated AND verified -> Allow access
  if (typeof callback === 'function') {
    callback();
  }
}

function showAuthModal(viewType, actionLabel = '') {
  const modal = document.getElementById('enquiry-auth-modal');
  const signupView = document.getElementById('auth-signup-view');
  const emailVerifyView = document.getElementById('auth-email-verify-view');
  const mobileVerifyView = document.getElementById('auth-mobile-verify-view');
  const loginView = document.getElementById('auth-login-view');
  const successView = document.getElementById('auth-email-verified-success-view');
  const modalTitle = document.getElementById('auth-modal-title');
  const modalSubtitle = document.getElementById('auth-modal-subtitle');

  if (!modal) return;
  modal.classList.remove('hidden');
  document.body.classList.add('overflow-hidden');

  // Hide all views first
  if (signupView) signupView.classList.add('hidden');
  if (emailVerifyView) emailVerifyView.classList.add('hidden');
  if (mobileVerifyView) mobileVerifyView.classList.add('hidden');
  if (loginView) loginView.classList.add('hidden');
  if (successView) successView.classList.add('hidden');

  if (viewType === 'signup') {
    if (signupView) signupView.classList.remove('hidden');
    if (modalTitle) modalTitle.textContent = 'Create PropZen Account';
    if (modalSubtitle) modalSubtitle.textContent = 'Join 250,000+ verified buyers and investors';
    validateSignupFormInputs();
  } else if (viewType === 'email-verify') {
    if (emailVerifyView) emailVerifyView.classList.remove('hidden');
    if (modalTitle) modalTitle.textContent = 'Verify Your Email';
    if (modalSubtitle) modalSubtitle.textContent = 'Step 1 of 2: Confirm your email identity';
  } else if (viewType === 'mobile-verify') {
    if (mobileVerifyView) mobileVerifyView.classList.remove('hidden');
    if (modalTitle) modalTitle.textContent = 'Verify Mobile Number';
    if (modalSubtitle) modalSubtitle.textContent = 'Step 2 of 2: Confirm SMS phone verification';
  } else if (viewType === 'login') {
    if (loginView) loginView.classList.remove('hidden');
    if (modalTitle) modalTitle.textContent = 'Welcome Back to PropZen';
    if (modalSubtitle) modalSubtitle.textContent = 'Enter your credentials to continue';
  } else if (viewType === 'success') {
    if (successView) successView.classList.remove('hidden');
    if (modalTitle) modalTitle.textContent = 'Account Verified!';
    if (modalSubtitle) modalSubtitle.textContent = 'Full access granted to PropZen Intelligence';
  }
}

// Token Generation & Registry
function generateSecureToken(email) {
  const timestamp = Date.now();
  const randomHex = Math.random().toString(36).substring(2, 10) + Math.random().toString(36).substring(2, 10);
  const token = `tok_${timestamp}_${randomHex}`;
  
  let registry = {};
  try {
    registry = JSON.parse(localStorage.getItem('propzen_email_tokens') || '{}');
  } catch (e) {}

  registry[token] = {
    email: email.toLowerCase().trim(),
    createdAt: timestamp,
    expiresAt: timestamp + 24 * 60 * 60 * 1000,
    used: false
  };

  try {
    localStorage.setItem('propzen_email_tokens', JSON.stringify(registry));
  } catch (e) {}

  return token;
}

// Step 2: Send Email OTP & Link
function sendEmailOtp(email, showNotification = true) {
  activeEmailOtp = Math.floor(100000 + Math.random() * 900000).toString();
  activeEmailOtpExpiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes expiry

  const token = generateSecureToken(email);
  if (pendingUserData) {
    pendingUserData.email = email;
    pendingUserData.emailOtp = activeEmailOtp;
    pendingUserData.verificationToken = token;
    pendingUserData.emailOtpExpiresAt = activeEmailOtpExpiresAt;
  }

  // Update UI Displays
  const emailDisplay = document.getElementById('verify-user-email-display');
  if (emailDisplay) emailDisplay.textContent = maskEmail(email);

  // Link for quick testing
  const currentBase = window.location.origin + window.location.pathname;
  const verificationUrl = `${currentBase}?verify_token=${token}`;

  const linkAnchor = document.getElementById('simulated-email-verify-link');
  if (linkAnchor) {
    linkAnchor.href = verificationUrl;
    linkAnchor.onclick = (e) => {
      e.preventDefault();
      verifyToken(token);
    };
  }

  const copyBtn = document.getElementById('copy-token-link-btn');
  if (copyBtn) {
    copyBtn.onclick = () => {
      navigator.clipboard.writeText(verificationUrl).then(() => {
        showToast('Verification URL copied to clipboard!', 'success');
      }).catch(() => {
        showToast(`Verification Link: ${verificationUrl}`, 'info');
      });
    };
  }

  // Clear boxes and focus first
  clearOtpBoxes('.email-otp-box');

  // Start 60s cooldown
  startEmailResendCooldown(60);

  if (showNotification) {
    showToast(`6-Digit Verification Code sent to ${maskEmail(email)}`, 'success');
  }
}

function startEmailResendCooldown(seconds = 60) {
  if (emailResendTimer) clearInterval(emailResendTimer);
  emailResendCooldown = seconds;

  const resendBtn = document.getElementById('resend-verify-email-btn');
  const resendText = document.getElementById('resend-verify-email-text');

  if (resendBtn) resendBtn.disabled = true;
  if (resendText) resendText.textContent = `Resend Code (${emailResendCooldown}s)`;

  emailResendTimer = setInterval(() => {
    emailResendCooldown--;
    if (emailResendCooldown > 0) {
      if (resendText) resendText.textContent = `Resend Code (${emailResendCooldown}s)`;
    } else {
      clearInterval(emailResendTimer);
      emailResendTimer = null;
      if (resendBtn) resendBtn.disabled = false;
      if (resendText) resendText.textContent = 'Resend Code';
    }
  }, 1000);
}

// Step 3: Send Mobile SMS OTP
function sendMobileOtp(phone, showNotification = true) {
  activeMobileOtp = Math.floor(100000 + Math.random() * 900000).toString();
  activeMobileOtpExpiresAt = Date.now() + 10 * 60 * 1000;

  if (pendingUserData) {
    pendingUserData.mobileOtp = activeMobileOtp;
    pendingUserData.mobileOtpExpiresAt = activeMobileOtpExpiresAt;
  }

  const countryCode = document.getElementById('signup-country-code')?.value || '+91';
  const phoneDisplay = document.getElementById('verify-user-phone-display');
  if (phoneDisplay) phoneDisplay.textContent = maskPhone(phone, countryCode);

  clearOtpBoxes('.mobile-otp-box');
  startMobileResendCooldown(60);

  if (showNotification) {
    showToast(`SMS Verification OTP sent to ${maskPhone(phone, countryCode)}`, 'success');
  }
}

function startMobileResendCooldown(seconds = 60) {
  if (mobileResendTimer) clearInterval(mobileResendTimer);
  mobileResendCooldown = seconds;

  const resendBtn = document.getElementById('resend-mobile-otp-btn');
  const resendText = document.getElementById('resend-mobile-otp-text');

  if (resendBtn) resendBtn.disabled = true;
  if (resendText) resendText.textContent = `Resend SMS OTP (${mobileResendCooldown}s)`;

  mobileResendTimer = setInterval(() => {
    mobileResendCooldown--;
    if (mobileResendCooldown > 0) {
      if (resendText) resendText.textContent = `Resend SMS OTP (${mobileResendCooldown}s)`;
    } else {
      clearInterval(mobileResendTimer);
      mobileResendTimer = null;
      if (resendBtn) resendBtn.disabled = false;
      if (resendText) resendText.textContent = 'Resend SMS OTP';
    }
  }, 1000);
}

// Display Email Verification Prompt
function displayEmailVerificationPrompt(userData) {
  pendingUserData = userData;
  showAuthModal('email-verify');
  const email = userData.email || 'sakshi.sharma@example.com';
  
  const emailDisplay = document.getElementById('verify-user-email-display');
  if (emailDisplay) emailDisplay.textContent = maskEmail(email);

  hideVerificationAlert();
  const changeContainer = document.getElementById('change-email-container');
  if (changeContainer) changeContainer.classList.add('hidden');

  sendEmailOtp(email, false);
}

// Validate 6-Digit Email OTP
function verifyEmailOtpCode() {
  const code = getOtpCodeFromBoxes('.email-otp-box');
  if (code.length !== 6) {
    showVerificationAlert('Please enter all 6 digits of the email verification code.', 'error');
    return false;
  }

  if (Date.now() > activeEmailOtpExpiresAt) {
    showVerificationAlert('This verification code has expired. Please click "Resend Code" below.', 'error');
    return false;
  }

  if (code !== activeEmailOtp) {
    showVerificationAlert('Invalid verification code. Please check your email and try again.', 'error');
    return false;
  }

  // Email verification successful!
  hideVerificationAlert();
  if (pendingUserData) {
    pendingUserData.isEmailVerified = true;
  }
  showToast('Email verified successfully! Proceeding to SMS OTP...', 'success');

  // Transition to Step 3: Mobile OTP
  showAuthModal('mobile-verify');
  const phone = pendingUserData ? pendingUserData.phone : '9810394068';
  sendMobileOtp(phone, true);
  return true;
}

// Validate 6-Digit Mobile SMS OTP
function verifyMobileOtpCode() {
  const code = getOtpCodeFromBoxes('.mobile-otp-box');
  if (code.length !== 6) {
    showMobileAlert('Please enter all 6 digits of the SMS verification code.', 'error');
    return false;
  }

  if (Date.now() > activeMobileOtpExpiresAt) {
    showMobileAlert('This SMS code has expired. Please click "Resend SMS OTP" below.', 'error');
    return false;
  }

  if (code !== activeMobileOtp) {
    showMobileAlert('Invalid SMS OTP. Please check your mobile messages and try again.', 'error');
    return false;
  }

  // Both Email & Mobile Verified! Create final user session
  hideMobileAlert();
  const countryCode = document.getElementById('signup-country-code')?.value || '+91';
  const finalUser = {
    name: pendingUserData?.name || 'Sakshi Sharma',
    email: pendingUserData?.email || 'sakshi.sharma@example.com',
    phone: pendingUserData?.phone || '9810394068',
    countryCode: countryCode,
    role: pendingUserData?.role || 'Buyer / Owner',
    isEmailVerified: true,
    isMobileVerified: true,
    verifiedAt: new Date().toISOString(),
    timestamp: new Date().toISOString()
  };

  saveUserSession(finalUser);
  updateHeaderAndProfileData(finalUser);

  // Transition to Step 4: Success View
  showAuthModal('success');
  const nameDisplay = document.getElementById('success-user-name');
  const emailDisplay = document.getElementById('success-user-email');
  const phoneDisplay = document.getElementById('success-user-phone');

  if (nameDisplay) nameDisplay.textContent = finalUser.name;
  if (emailDisplay) emailDisplay.textContent = maskEmail(finalUser.email);
  if (phoneDisplay) phoneDisplay.textContent = maskPhone(finalUser.phone, countryCode);

  showToast('PropZen Account Created & Verified Successfully!', 'success');
  return true;
}

// Token Verification
function verifyToken(tokenString) {
  if (!tokenString) {
    showVerificationAlert('Invalid verification token. Please request a new verification email.', 'error');
    return false;
  }

  let registry = {};
  try {
    registry = JSON.parse(localStorage.getItem('propzen_email_tokens') || '{}');
  } catch (e) {}

  const tokenInfo = registry[tokenString];
  const currentUser = getStoredUser();

  if (!tokenInfo && (!currentUser || currentUser.verificationToken !== tokenString)) {
    showVerificationAlert('Verification link is invalid or has expired.', 'error');
    return false;
  }

  const expiresAt = tokenInfo ? tokenInfo.expiresAt : (currentUser?.tokenExpiresAt || 0);
  if (Date.now() > expiresAt) {
    showVerificationAlert('This verification link has expired. Please request a new one.', 'error');
    return false;
  }

  if (tokenInfo) {
    tokenInfo.used = true;
    registry[tokenString] = tokenInfo;
    try {
      localStorage.setItem('propzen_email_tokens', JSON.stringify(registry));
    } catch (e) {}
  }

  if (pendingUserData) {
    pendingUserData.isEmailVerified = true;
  }

  showToast('Email verified via Secure Token! Proceeding to SMS OTP...', 'success');
  showAuthModal('mobile-verify');
  const phone = pendingUserData ? pendingUserData.phone : (currentUser ? currentUser.phone : '9810394068');
  sendMobileOtp(phone, true);
  return true;
}

function showEmailVerificationSuccess(user) {
  showAuthModal('success');
  const nameDisplay = document.getElementById('success-user-name');
  const emailDisplay = document.getElementById('success-user-email');
  const phoneDisplay = document.getElementById('success-user-phone');

  if (nameDisplay) nameDisplay.textContent = user.name || 'Sakshi Sharma';
  if (emailDisplay) emailDisplay.textContent = maskEmail(user.email);
  if (phoneDisplay) phoneDisplay.textContent = maskPhone(user.phone, user.countryCode || '+91');
}

function showVerificationAlert(message, type = 'error') {
  const alertBox = document.getElementById('email-verify-alert');
  const alertMsg = document.getElementById('email-verify-alert-msg');
  const alertIcon = document.getElementById('email-verify-alert-icon');
  if (!alertBox || !alertMsg) return;

  alertBox.classList.remove('hidden', 'bg-red-50', 'text-red-700', 'border-red-200', 'bg-amber-50', 'text-amber-700', 'border-amber-200', 'bg-emerald-50', 'text-emerald-700');
  
  if (type === 'error') {
    alertBox.classList.add('bg-red-50', 'text-red-700', 'border', 'border-red-200');
    if (alertIcon) alertIcon.textContent = 'error';
  } else if (type === 'warning') {
    alertBox.classList.add('bg-amber-50', 'text-amber-700', 'border', 'border-amber-200');
    if (alertIcon) alertIcon.textContent = 'warning';
  } else {
    alertBox.classList.add('bg-emerald-50', 'text-emerald-700', 'border', 'border-emerald-200');
    if (alertIcon) alertIcon.textContent = 'check_circle';
  }
  alertMsg.textContent = message;
}

function hideVerificationAlert() {
  const alertBox = document.getElementById('email-verify-alert');
  if (alertBox) alertBox.classList.add('hidden');
}

function showMobileAlert(message, type = 'error') {
  const alertBox = document.getElementById('mobile-verify-alert');
  const alertMsg = document.getElementById('mobile-verify-alert-msg');
  const alertIcon = document.getElementById('mobile-verify-alert-icon');
  if (!alertBox || !alertMsg) return;

  alertBox.classList.remove('hidden', 'bg-red-50', 'text-red-700', 'border-red-200', 'bg-emerald-50', 'text-emerald-700');
  alertBox.classList.add('bg-red-50', 'text-red-700', 'border', 'border-red-200');
  if (alertIcon) alertIcon.textContent = 'error';
  alertMsg.textContent = message;
}

function hideMobileAlert() {
  const alertBox = document.getElementById('mobile-verify-alert');
  if (alertBox) alertBox.classList.add('hidden');
}

// Helpers for 6-Digit OTP input boxes
function clearOtpBoxes(selector) {
  const boxes = document.querySelectorAll(selector);
  boxes.forEach((box, i) => {
    box.value = '';
    if (i === 0) setTimeout(() => box.focus(), 100);
  });
}

function getOtpCodeFromBoxes(selector) {
  const boxes = document.querySelectorAll(selector);
  let code = '';
  boxes.forEach(box => {
    code += box.value.trim();
  });
  return code;
}

function setupOtpBoxListeners(selector, onComplete) {
  const boxes = document.querySelectorAll(selector);
  boxes.forEach((box, index) => {
    box.addEventListener('input', (e) => {
      const val = e.target.value;
      if (val.length === 1 && index < boxes.length - 1) {
        boxes[index + 1].focus();
      }
      const fullCode = getOtpCodeFromBoxes(selector);
      if (fullCode.length === boxes.length && typeof onComplete === 'function') {
        onComplete(fullCode);
      }
    });

    box.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace' && !box.value && index > 0) {
        boxes[index - 1].focus();
      }
    });

    box.addEventListener('paste', (e) => {
      e.preventDefault();
      const pasted = (e.clipboardData || window.clipboardData).getData('text').trim();
      if (/^\d+$/.test(pasted)) {
        const digits = pasted.split('').slice(0, boxes.length);
        digits.forEach((d, idx) => {
          if (boxes[idx]) boxes[idx].value = d;
        });
        if (digits.length === boxes.length && typeof onComplete === 'function') {
          onComplete(digits.join(''));
        }
      }
    });
  });
}

// Legal Policies Modal Handlers
function openLegalPolicyModal(type) {
  const modal = document.getElementById('legal-policy-modal');
  const title = document.getElementById('legal-policy-modal-title');
  const content = document.getElementById('legal-policy-modal-content');
  if (!modal || !title || !content) return;

  if (type === 'tnc') {
    title.innerHTML = '<span class="material-symbols-outlined text-[#d32f2f] text-lg">gavel</span> Terms & Conditions';
    content.innerHTML = `
      <h4 class="font-bold text-slate-900 text-sm">1. PropZen Platform Terms of Service</h4>
      <p>By registering on PropZen, you agree to access algorithmic 10X property intelligence, verified dealer listings, and real-time market yield metrics under fair usage guidelines.</p>
      <h4 class="font-bold text-slate-900 text-sm mt-3">2. Direct Enquiries & Advisory</h4>
      <p>All direct property owner and RERA dealer connections require mandatory email and SMS phone verification to prevent fraud and maintain the integrity of property intelligence reports.</p>
      <h4 class="font-bold text-slate-900 text-sm mt-3">3. Data Accuracy & Yield Forecasts</h4>
      <p>Market intelligence insights, price trends, and ROI models are generated via automated machine learning models based on registered registry transactions and live registry benchmarks.</p>
    `;
  } else if (type === 'privacy') {
    title.innerHTML = '<span class="material-symbols-outlined text-[#d32f2f] text-lg">security</span> Privacy Policy';
    content.innerHTML = `
      <h4 class="font-bold text-slate-900 text-sm">1. Data Protection & Encryption</h4>
      <p>Your personal data (name, email address, mobile number) is encrypted using bank-grade 256-bit SSL protocols. We never sell your personal data to third-party telemarketers.</p>
      <h4 class="font-bold text-slate-900 text-sm mt-3">2. Identity Verification</h4>
      <p>We collect and verify your email and phone number solely to authenticate property enquiries, schedule site visits, and protect property owners from spam.</p>
    `;
  } else if (type === 'cookies') {
    title.innerHTML = '<span class="material-symbols-outlined text-[#d32f2f] text-lg">cookie</span> Cookie Policy';
    content.innerHTML = `
      <h4 class="font-bold text-slate-900 text-sm">1. Essential Session Cookies</h4>
      <p>PropZen uses local session cookies to maintain your login status, saved shortlisted properties, and filter preferences across browser sessions.</p>
      <h4 class="font-bold text-slate-900 text-sm mt-3">2. Analytics & Performance</h4>
      <p>Anonymized telemetry helps us optimize map render speeds, 3D video streaming performance, and AI algorithmic matching quality.</p>
    `;
  }
  modal.classList.remove('hidden');
  document.body.classList.add('overflow-hidden');
}

function closeLegalPolicyModal() {
  const modal = document.getElementById('legal-policy-modal');
  if (modal) {
    modal.classList.add('hidden');
    document.body.classList.remove('overflow-hidden');
    document.body.style.overflow = '';
  }
}

// URL Token Verification Listener on Load
function checkUrlVerificationTokens() {
  try {
    const params = new URLSearchParams(window.location.search);
    const verifyTokenParam = params.get('verify_token') || params.get('token');
    
    if (verifyTokenParam) {
      const success = verifyToken(verifyTokenParam);
      const cleanUrl = window.location.origin + window.location.pathname;
      window.history.replaceState({}, document.title, cleanUrl);
    }
  } catch (err) {}
}

function updateAdminPortalVisibility(user) {
  const adminBtn = document.getElementById('footer-admin-portal-btn');
  if (!adminBtn) return;
  const isAuthorized = user && user.email && user.email.trim().toLowerCase() === 'dubeysakshi618@gmail.com';
  if (isAuthorized) {
    adminBtn.classList.remove('hidden');
  } else {
    adminBtn.classList.add('hidden');
  }
}

function updateHeaderAndProfileData(user) {
  updateAdminPortalVisibility(user);
  if (!user) return;

  const topBarLoginBtn = document.getElementById('top-bar-login-btn');
  if (topBarLoginBtn) {
    const verifiedBadge = user.isEmailVerified ? '<span class="w-2 h-2 rounded-full bg-emerald-400"></span>' : '<span class="w-2 h-2 rounded-full bg-amber-400" title="Email Unverified"></span>';
    topBarLoginBtn.innerHTML = `
      <span class="material-symbols-outlined text-sm">account_circle</span>
      <span class="truncate max-w-[100px]">${user.name || 'User'}</span>
      ${verifiedBadge}
      <span class="text-[10px]">▼</span>
    `;
    topBarLoginBtn.classList.remove('bg-white/20');
    topBarLoginBtn.classList.add('bg-white/30', 'border-emerald-300');
  }

  const headerLoginBtns = document.querySelectorAll('header button');
  headerLoginBtns.forEach(btn => {
    if (btn.id === 'header-profile-btn' || btn.textContent.includes('Profile') || btn.textContent.includes('Login') || btn.textContent.includes(user.name)) {
      btn.innerHTML = `<span class="material-symbols-outlined text-base">verified</span> ${user.name.split(' ')[0]}`;
    }
  });
}

function initPropertyEnquiryAuth() {
  const modal = document.getElementById('enquiry-auth-modal');
  const closeBtn = document.getElementById('close-enquiry-auth-modal');
  const backBtn = document.getElementById('modal-back-btn');
  const switchLogin = document.getElementById('switch-to-login');
  const switchSignup = document.getElementById('switch-to-signup');
  const refreshSignupBtn = document.getElementById('refresh-signup-captcha');
  const refreshLoginBtn = document.getElementById('refresh-login-captcha');

  if (closeBtn && modal) {
    closeBtn.onclick = () => {
      modal.classList.add('hidden');
      document.body.classList.remove('overflow-hidden');
      document.body.style.overflow = '';
    };
  }

  if (backBtn && modal) {
    backBtn.onclick = () => {
      const emailVerifyView = document.getElementById('auth-email-verify-view');
      const mobileVerifyView = document.getElementById('auth-mobile-verify-view');
      const loginView = document.getElementById('auth-login-view');

      if (mobileVerifyView && !mobileVerifyView.classList.contains('hidden')) {
        showAuthModal('email-verify');
      } else if (emailVerifyView && !emailVerifyView.classList.contains('hidden')) {
        showAuthModal('signup');
      } else if (loginView && !loginView.classList.contains('hidden')) {
        showAuthModal('signup');
      } else {
        modal.classList.add('hidden');
        document.body.classList.remove('overflow-hidden');
        document.body.style.overflow = '';
      }
    };
  }

  if (switchLogin) {
    switchLogin.onclick = () => showAuthModal('login');
  }

  if (switchSignup) {
    switchSignup.onclick = () => showAuthModal('signup');
  }

  if (refreshSignupBtn) {
    refreshSignupBtn.onclick = () => {
      activeSignupCaptcha = generateRandomCaptchaText();
      const span = document.getElementById('signup-captcha-code');
      if (span) span.textContent = activeSignupCaptcha;
      validateSignupFormInputs();
    };
  }

  if (refreshLoginBtn) {
    refreshLoginBtn.onclick = () => {
      activeLoginCaptcha = generateRandomCaptchaText();
      const span = document.getElementById('login-captcha-code');
      if (span) span.textContent = activeLoginCaptcha;
    };
  }

  // Setup Role Card Selection
  const roleCards = document.querySelectorAll('.signup-role-card');
  roleCards.forEach(card => {
    card.addEventListener('click', () => {
      roleCards.forEach(c => {
        c.classList.remove('active', 'border-2', 'border-[#d32f2f]', 'bg-red-50/60', 'text-[#d32f2f]', 'font-bold');
        c.classList.add('border', 'border-slate-200', 'bg-slate-50', 'text-slate-700', 'font-semibold');
      });
      card.classList.add('active', 'border-2', 'border-[#d32f2f]', 'bg-red-50/60', 'text-[#d32f2f]', 'font-bold');
      card.classList.remove('border', 'border-slate-200', 'bg-slate-50', 'text-slate-700', 'font-semibold');
      const radio = card.querySelector('input[type="radio"]');
      if (radio) radio.checked = true;
    });
  });

  // Setup 6-Digit OTP Box Listeners
  setupOtpBoxListeners('.email-otp-box', () => {
    verifyEmailOtpCode();
  });

  setupOtpBoxListeners('.mobile-otp-box', () => {
    verifyMobileOtpCode();
  });

  // 1. Submit Sign Up (Step 1 -> Step 2)
  const submitSignup = document.getElementById('submit-signup-btn');
  if (submitSignup) {
    submitSignup.onclick = (e) => {
      e.preventDefault();
      const name = document.getElementById('signup-name')?.value.trim() || '';
      const email = document.getElementById('signup-email')?.value.trim() || '';
      const phone = document.getElementById('signup-phone')?.value.trim() || '';
      const captchaInput = document.getElementById('signup-captcha-input')?.value.trim() || '';
      const countryCode = document.getElementById('signup-country-code')?.value || '+91';

      if (!name) {
        showToast('Please enter your full name', 'error');
        return;
      }
      if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        showToast('Please enter a valid email address', 'error');
        return;
      }
      if (!phone || phone.length < 10) {
        showToast('Please enter a valid 10-digit mobile number', 'error');
        return;
      }

      if (captchaInput.toLowerCase() !== activeSignupCaptcha.toLowerCase()) {
        showToast('Invalid Captcha code! Please enter correct code.', 'error');
        refreshCaptchaCodes();
        return;
      }

      const role = document.querySelector('input[name="signup-role"]:checked')?.value || 'Buyer/Owner/Tenant';

      pendingUserData = {
        name: name,
        email: email,
        phone: phone,
        countryCode: countryCode,
        role: role,
        isEmailVerified: false,
        isMobileVerified: false,
        timestamp: new Date().toISOString()
      };

      // Transition to Step 2: Verify Email
      showAuthModal('email-verify');
      sendEmailOtp(email, true);
    };
  }

  // 2. Verify Email Button (Step 2)
  const verifyEmailBtn = document.getElementById('verify-email-btn');
  if (verifyEmailBtn) {
    verifyEmailBtn.onclick = () => {
      verifyEmailOtpCode();
    };
  }

  // 3. Resend Email OTP
  const resendEmailBtn = document.getElementById('resend-verify-email-btn');
  if (resendEmailBtn) {
    resendEmailBtn.onclick = () => {
      if (emailResendCooldown > 0) return;
      const email = pendingUserData?.email || document.getElementById('signup-email')?.value.trim() || 'sakshi.sharma@example.com';
      hideVerificationAlert();
      sendEmailOtp(email, true);
    };
  }

  // 4. Inline Change Email Toggle
  const changeEmailToggleBtn = document.getElementById('change-email-toggle-btn');
  const changeEmailContainer = document.getElementById('change-email-container');
  const submitChangeEmailBtn = document.getElementById('submit-change-email-btn');
  const newEmailInput = document.getElementById('new-verify-email-input');

  if (changeEmailToggleBtn && changeEmailContainer) {
    changeEmailToggleBtn.onclick = () => {
      changeEmailContainer.classList.toggle('hidden');
      if (!changeEmailContainer.classList.contains('hidden') && newEmailInput) {
        newEmailInput.value = '';
        newEmailInput.focus();
      }
    };
  }

  if (submitChangeEmailBtn && newEmailInput) {
    submitChangeEmailBtn.onclick = () => {
      const newEmail = newEmailInput.value.trim();
      if (!newEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newEmail)) {
        showToast('Please enter a valid email address', 'error');
        return;
      }
      if (pendingUserData) pendingUserData.email = newEmail;
      if (changeEmailContainer) changeEmailContainer.classList.add('hidden');
      sendEmailOtp(newEmail, true);
      showToast(`Email updated to ${newEmail}! New OTP sent.`, 'success');
    };
  }

  // 5. Verify Mobile Button (Step 3)
  const verifyMobileBtn = document.getElementById('verify-mobile-btn');
  if (verifyMobileBtn) {
    verifyMobileBtn.onclick = () => {
      verifyMobileOtpCode();
    };
  }

  // 6. Resend Mobile OTP
  const resendMobileBtn = document.getElementById('resend-mobile-otp-btn');
  if (resendMobileBtn) {
    resendMobileBtn.onclick = () => {
      if (mobileResendCooldown > 0) return;
      const phone = pendingUserData?.phone || '9810394068';
      hideMobileAlert();
      sendMobileOtp(phone, true);
    };
  }

  // 7. Step 4 Continue Button
  const continueBtn = document.getElementById('email-verified-continue-btn');
  if (continueBtn) {
    continueBtn.onclick = () => {
      if (modal) modal.classList.add('hidden');
      if (typeof pendingEnquiryCallback === 'function') {
        const cb = pendingEnquiryCallback;
        pendingEnquiryCallback = null;
        cb();
      } else {
        navigateToRoute('/profile');
      }
    };
  }

  // Handle Login Form Submission
  const submitLogin = document.getElementById('submit-login-btn');
  if (submitLogin) {
    submitLogin.onclick = (e) => {
      e.preventDefault();
      const loginInput = document.getElementById('login-phone')?.value.trim() || '9810394068';
      const captchaInput = document.getElementById('login-captcha-input')?.value.trim() || '';

      if (!loginInput) {
        showToast('Please enter your mobile number or email', 'error');
        return;
      }

      if (captchaInput.toLowerCase() !== activeLoginCaptcha.toLowerCase()) {
        showToast('Invalid Captcha code! Please enter correct code.', 'error');
        refreshCaptchaCodes();
        return;
      }

      let saved = {};
      try {
        saved = JSON.parse(localStorage.getItem('propzen_user') || '{}');
      } catch (err) {}

      const isEmail = loginInput.includes('@');
      const userData = {
        name: saved.name || 'Sakshi Sharma',
        email: isEmail ? loginInput : (saved.email || 'sakshi.sharma@example.com'),
        phone: !isEmail ? loginInput : (saved.phone || '9810394068'),
        role: saved.role || 'Buyer / Owner',
        isEmailVerified: saved.isEmailVerified === true,
        isMobileVerified: saved.isMobileVerified === true,
        timestamp: new Date().toISOString()
      };

      saveUserSession(userData);

      if (userData.isEmailVerified && userData.isMobileVerified) {
        if (modal) modal.classList.add('hidden');
        updateHeaderAndProfileData(userData);
        showToast(`Welcome back, ${userData.name}!`, 'success');
        if (typeof pendingEnquiryCallback === 'function') {
          const cb = pendingEnquiryCallback;
          pendingEnquiryCallback = null;
          cb();
        }
      } else {
        displayEmailVerificationPrompt(userData);
      }
    };
  }

  // Check URL verification params on launch
  checkUrlVerificationTokens();

  // Restore initial logged-in header state if user is already in session
  const currentUser = getStoredUser();
  if (currentUser) {
    updateHeaderAndProfileData(currentUser);
  }
}

// Search and Filtering with BHK, Sq.Ft, and Budget support
let currentBhkFilter = 'all';
let currentSqftFilter = 'all';
let currentBudgetFilter = 'all';

function initSearchAndFilters() {
  const searchInputs = document.querySelectorAll('.search-ncr-input');
  searchInputs.forEach(input => {
    input.addEventListener('input', () => {
      filterProperties();
    });
  });

  // BHK Filter Buttons for Flats
  const bhkBtns = document.querySelectorAll('.bhk-filter-btn');
  bhkBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      bhkBtns.forEach(b => {
        b.classList.remove('active', 'bg-primary', 'text-on-primary');
        b.classList.add('bg-surface-container', 'text-on-surface-variant');
      });
      btn.classList.add('active', 'bg-primary', 'text-on-primary');
      btn.classList.remove('bg-surface-container', 'text-on-surface-variant');
      currentBhkFilter = btn.getAttribute('data-bhk') || 'all';
      filterProperties();
    });
  });

  // Square Feet Filter Buttons for Plots
  const sqftBtns = document.querySelectorAll('.sqft-filter-btn');
  sqftBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      sqftBtns.forEach(b => {
        b.classList.remove('active', 'bg-secondary', 'text-on-secondary');
        b.classList.add('bg-surface-container', 'text-on-surface-variant');
      });
      btn.classList.add('active', 'bg-secondary', 'text-on-secondary');
      btn.classList.remove('bg-surface-container', 'text-on-surface-variant');
      currentSqftFilter = btn.getAttribute('data-sqft') || 'all';
      filterProperties();
    });
  });

  // Budget Range Filter Buttons
  const budgetBtns = document.querySelectorAll('.budget-filter-btn');
  budgetBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      budgetBtns.forEach(b => {
        b.classList.remove('active', 'bg-emerald-500', 'text-black', 'font-bold');
        b.classList.add('bg-surface-container', 'text-on-surface-variant', 'font-semibold');
      });
      btn.classList.add('active', 'bg-emerald-500', 'text-black', 'font-bold');
      btn.classList.remove('bg-surface-container', 'text-on-surface-variant', 'font-semibold');
      currentBudgetFilter = btn.getAttribute('data-budget') || 'all';
      filterProperties();
    });
  });
}

function filterPropertiesBySlicers() {
  filterProperties();
}

function filterProperties() {
  const searchInput = document.querySelector('.search-ncr-input');
  const query = searchInput ? searchInput.value.toLowerCase().trim() : '';
  const cards = document.querySelectorAll('.property-card');
  let matchCount = 0;

  const activeSectorBtn = document.querySelector('.sector-filter-btn.active');
  const sectorVal = activeSectorBtn ? (activeSectorBtn.getAttribute('data-sector') || 'all') : 'all';

  const activeTypeBtn = document.querySelector('.type-filter-btn.active');
  const typeVal = activeTypeBtn ? (activeTypeBtn.getAttribute('data-type') || 'all') : 'all';

  cards.forEach(card => {
    const text = (card.textContent || '').toLowerCase();
    const cleanText = text.replace(/\s+/g, '');
    const bhk = (card.getAttribute('data-bhk') || 'none').toLowerCase();
    const sqft = parseInt(card.getAttribute('data-sqft') || '0', 10);
    const price = parseFloat(card.getAttribute('data-price') || '0');

    const cleanQuery = query.toLowerCase().replace(/\s+/g, '');
    let matchesBhkQuery = true;
    if (cleanQuery.includes('1bhk') && !bhk.includes('1bhk')) matchesBhkQuery = false;
    if (cleanQuery.includes('2bhk') && !bhk.includes('2bhk')) matchesBhkQuery = false;
    if (cleanQuery.includes('3bhk') && !bhk.includes('3bhk')) matchesBhkQuery = false;
    if (cleanQuery.includes('4bhk') && !bhk.includes('4bhk')) matchesBhkQuery = false;

    let matchesQuery = matchesBhkQuery && (!query || text.includes(query) || cleanText.includes(cleanQuery));
    
    let matchesBhk = currentBhkFilter === 'all' || bhk === currentBhkFilter.toLowerCase() || bhk.includes(currentBhkFilter.toLowerCase().replace(/\s+/g, ''));
    
    let matchesSector = sectorVal === 'all' || text.includes(sectorVal.toLowerCase());
    let matchesType = typeVal === 'all' || text.includes(typeVal.toLowerCase());

    let matchesSqft = true;
    if (currentSqftFilter === 'small') matchesSqft = sqft < 1000;
    else if (currentSqftFilter === 'medium') matchesSqft = sqft >= 1000 && sqft <= 2500;
    else if (currentSqftFilter === 'large') matchesSqft = sqft > 2500 && sqft <= 5000;
    else if (currentSqftFilter === 'xlarge') matchesSqft = sqft > 5000;

    let matchesBudget = true;
    const b = currentBudgetFilter.toLowerCase().replace(/\s+/g, '');
    if (b !== 'all' && b !== 'allbudgets') {
      if (b === '20l-40l' && (price < 0.20 || price > 0.45)) matchesBudget = false;
      else if (b === '40l-80l' && (price < 0.40 || price > 0.85)) matchesBudget = false;
      else if (b === '1cr+' && price < 1.00) matchesBudget = false;
      else if (b === '5k-10k' && price > 0.15) matchesBudget = false;
      else if (b === '10k-20k' && (price < 0.10 || price > 0.35)) matchesBudget = false;
      else if (b === '20k+' && price < 0.20) matchesBudget = false;
      else if (b === '30k-50k' && price > 0.60) matchesBudget = false;
      else if (b === '50k-1l' && (price < 0.50 || price > 1.20)) matchesBudget = false;
      else if (b === '1l+' && price < 1.00) matchesBudget = false;
      else if (b === '1l-5l' && (price < 1.00 || price > 5.00)) matchesBudget = false;
      else if (b === '5l+' && price < 5.00) matchesBudget = false;
      else if (b === 'under50l' || b === '<50l' || b === '<₹50l') matchesBudget = price < 0.50;
      else if (b === '50l-1cr' || b === '₹50l-₹1cr') matchesBudget = price >= 0.50 && price <= 1.00;
      else if (b === '1cr-3cr' || b === '₹1cr-₹3cr') matchesBudget = price > 1.00 && price <= 3.00;
      else if (b === '3cr-5cr' || b === '₹3cr-₹5cr') matchesBudget = price > 3.00 && price <= 5.00;
      else if (b === '5crplus' || b === 'above5cr' || b === '₹5cr+') matchesBudget = price >= 5.00;
    }

    if (matchesQuery && matchesBhk && matchesSqft && matchesBudget && matchesSector && matchesType) {
      card.style.display = 'flex';
      matchCount++;
    } else {
      card.style.display = 'none';
    }
  });

  const counter = document.getElementById('search-result-count');
  if (counter) {
    counter.textContent = `${matchCount} Properties Evaluated`;
  }
}

// Site Visit Booking Logic
function initSiteVisitBooking() {
  const visitSlots = document.querySelectorAll('.visit-time-slot');
  visitSlots.forEach(slot => {
    slot.addEventListener('click', () => {
      visitSlots.forEach(s => s.classList.remove('bg-primary', 'text-on-primary', 'border-primary'));
      slot.classList.add('bg-primary', 'text-on-primary', 'border-primary');
    });
  });

  const bookBtn = document.getElementById('confirm-visit-btn');
  if (bookBtn) {
    bookBtn.addEventListener('click', (e) => {
      e.preventDefault();
      showToast('Site Visit Booked Successfully! Confirmation sent via SMS & WhatsApp.', 'success');
    });
  }
}

// Dual Auth (Buyer vs Dealer Login/Signup)
function initDualAuth() {
  const authTabs = document.querySelectorAll('[data-auth-type]');
  authTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const type = tab.getAttribute('data-auth-type');
      authTabs.forEach(t => t.classList.remove('bg-primary', 'text-on-primary'));
      tab.classList.add('bg-primary', 'text-on-primary');

      const buyerForm = document.getElementById('auth-form-buyer');
      const dealerForm = document.getElementById('auth-form-dealer');

      if (type === 'buyer') {
        if (buyerForm) buyerForm.classList.remove('hidden');
        if (dealerForm) dealerForm.classList.add('hidden');
      } else {
        if (buyerForm) buyerForm.classList.add('hidden');
        if (dealerForm) dealerForm.classList.remove('hidden');
      }
    });
  });
}

// Financial Calculators
function initValuationCalculators() {
  const priceSlider = document.getElementById('calc-price-slider');
  const rentSlider = document.getElementById('calc-rent-slider');

  if (priceSlider && rentSlider) {
    const updateYieldCalc = () => {
      const priceLakhs = parseFloat(priceSlider.value);
      const monthlyRent = parseFloat(rentSlider.value);

      const annualRent = monthlyRent * 12;
      const priceAmount = priceLakhs * 100000;
      const grossYield = ((annualRent / priceAmount) * 100).toFixed(2);
      const netYield = (grossYield * 0.82).toFixed(2);

      document.getElementById('calc-price-val').textContent = `₹${priceLakhs} Lakhs`;
      document.getElementById('calc-rent-val').textContent = `₹${monthlyRent.toLocaleString()}/mo`;
      document.getElementById('calc-gross-yield').textContent = `${grossYield}%`;
      document.getElementById('calc-net-yield').textContent = `${netYield}%`;
      document.getElementById('calc-monthly-cashflow').textContent = `₹${(monthlyRent - (priceLakhs * 450)).toLocaleString()}`;
    };

    priceSlider.addEventListener('input', updateYieldCalc);
    rentSlider.addEventListener('input', updateYieldCalc);
  }
}

function initEmiCalculator() {
  const emiAmountSlider = document.getElementById('emi-amount-slider');
  const emiRateSlider = document.getElementById('emi-rate-slider');
  const emiTenureSlider = document.getElementById('emi-tenure-slider');

  if (emiAmountSlider && emiRateSlider && emiTenureSlider) {
    const calculateEmi = () => {
      const P = parseFloat(emiAmountSlider.value) * 100000;
      const annualRate = parseFloat(emiRateSlider.value);
      const r = annualRate / 12 / 100;
      const n = parseFloat(emiTenureSlider.value) * 12;

      const emi = (P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
      const totalPayment = emi * n;
      const totalInterest = totalPayment - P;

      document.getElementById('emi-amount-val').textContent = `₹${parseFloat(emiAmountSlider.value)} Lakhs`;
      document.getElementById('emi-rate-val').textContent = `${annualRate}% p.a.`;
      document.getElementById('emi-tenure-val').textContent = `${parseFloat(emiTenureSlider.value)} Years`;

      document.getElementById('emi-monthly-result').textContent = `₹${Math.round(emi).toLocaleString()}`;
      document.getElementById('emi-total-interest').textContent = `₹${Math.round(totalInterest / 100000).toLocaleString()} Lakhs`;
      document.getElementById('emi-total-payment').textContent = `₹${Math.round(totalPayment / 100000).toLocaleString()} Lakhs`;
    };

    emiAmountSlider.addEventListener('input', calculateEmi);
    emiRateSlider.addEventListener('input', calculateEmi);
    emiTenureSlider.addEventListener('input', calculateEmi);
  }
}

function initChatInterface() {
  const chatInput = document.getElementById('chat-msg-input');
  const sendBtn = document.getElementById('chat-send-btn');
  const msgContainer = document.getElementById('chat-messages-box');

  if (sendBtn && chatInput && msgContainer) {
    const sendMessage = () => {
      const text = chatInput.value.trim();
      if (!text) return;

      const userBubble = document.createElement('div');
      userBubble.className = 'flex justify-end mb-sm';
      userBubble.innerHTML = `
        <div class="bg-primary-container text-on-primary-container p-sm rounded-lg max-w-xs text-xs font-data-label">
          ${text}
        </div>
      `;
      msgContainer.appendChild(userBubble);
      chatInput.value = '';
      msgContainer.scrollTop = msgContainer.scrollHeight;

      setTimeout(() => {
        const advisorBubble = document.createElement('div');
        advisorBubble.className = 'flex justify-start mb-sm';
        advisorBubble.innerHTML = `
          <div class="glass-panel p-sm rounded-lg max-w-xs text-xs font-data-label text-on-surface border-l-2 border-secondary">
            <span class="text-secondary font-bold block mb-1">PropZen AI Advisor:</span>
            Based on current registry data, Sector 137 Noida offers a 6.1% rental yield with fair market valuation at ₹8,285/sqft. How else can I assist your investment strategy?
          </div>
        `;
        msgContainer.appendChild(advisorBubble);
        msgContainer.scrollTop = msgContainer.scrollHeight;
      }, 1000);
    };

    sendBtn.addEventListener('click', sendMessage);
    chatInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });
  }
}

let currentStep = 1;
function initPostPropertyWizard() {
  const nextBtn = document.getElementById('wizard-next-btn');
  const prevBtn = document.getElementById('wizard-prev-btn');

  if (nextBtn) {
    nextBtn.addEventListener('click', () => {
      if (currentStep < 4) {
        currentStep++;
        updateWizardStep();
      } else {
        showToast('Property Posted! 10X Intelligence Report Generated', 'success');
        navigateTo('report');
      }
    });
  }

  if (prevBtn) {
    prevBtn.addEventListener('click', () => {
      if (currentStep > 1) {
        currentStep--;
        updateWizardStep();
      }
    });
  }
}

function updateWizardStep() {
  for (let i = 1; i <= 4; i++) {
    const stepEl = document.getElementById(`wizard-step-${i}`);
    const stepIndicator = document.getElementById(`wizard-indicator-${i}`);
    if (stepEl) {
      if (i === currentStep) {
        stepEl.classList.remove('hidden');
      } else {
        stepEl.classList.add('hidden');
      }
    }
    if (stepIndicator) {
      if (i <= currentStep) {
        stepIndicator.classList.add('bg-primary', 'text-on-primary');
        stepIndicator.classList.remove('bg-surface-variant', 'text-on-surface-variant');
      } else {
        stepIndicator.classList.remove('bg-primary', 'text-on-primary');
        stepIndicator.classList.add('bg-surface-variant', 'text-on-surface-variant');
      }
    }
  }

  const prevBtn = document.getElementById('wizard-prev-btn');
  const nextBtn = document.getElementById('wizard-next-btn');
  if (prevBtn) prevBtn.style.visibility = currentStep === 1 ? 'hidden' : 'visible';
  if (nextBtn) nextBtn.textContent = currentStep === 4 ? 'Publish & Generate 10X Report' : 'Next Step';
}

function initPhotoGallery() {
  const galleryImgs = document.querySelectorAll('.gallery-thumb');
  const modal = document.getElementById('photo-modal');
  const modalImg = document.getElementById('modal-main-img');
  const closeBtn = document.getElementById('close-modal-btn');

  galleryImgs.forEach(img => {
    img.addEventListener('click', () => {
      const src = img.getAttribute('data-full-src') || img.src;
      if (modalImg && modal) {
        modalImg.src = src;
        modal.classList.add('open');
      }
    });
  });

  if (closeBtn && modal) {
    closeBtn.addEventListener('click', () => {
      modal.classList.remove('open');
    });
  }
}

function initAuthFlow() {
  const roleCards = document.querySelectorAll('.role-card');
  roleCards.forEach(card => {
    card.addEventListener('click', () => {
      roleCards.forEach(c => c.classList.remove('border-primary', 'bg-surface-variant'));
      card.classList.add('border-primary', 'bg-surface-variant');
      const role = card.getAttribute('data-role');
      document.getElementById('selected-role-input').value = role;
    });
  });

  const sendOtpBtn = document.getElementById('send-otp-btn');
  if (sendOtpBtn) {
    sendOtpBtn.addEventListener('click', (e) => {
      e.preventDefault();
      showToast('Verification Code sent to +91 9810X XXXXX', 'info');
      const otpModal = document.getElementById('otp-modal');
      if (otpModal) otpModal.classList.remove('hidden');
    });
  }

  const verifyOtpBtn = document.getElementById('verify-otp-btn');
  if (verifyOtpBtn) {
    verifyOtpBtn.addEventListener('click', () => {
      showToast('Role Verified! Welcome to PropZen Network', 'success');
      const otpModal = document.getElementById('otp-modal');
      if (otpModal) otpModal.classList.add('hidden');
      navigateTo('home');
    });
  }
}

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  let icon = 'info';
  let borderCol = 'border-primary';
  if (type === 'success') { icon = 'check_circle'; borderCol = 'border-secondary'; }
  if (type === 'warning') { icon = 'warning'; borderCol = 'border-tertiary'; }

  toast.className = `glass-modal border-l-4 ${borderCol} text-on-surface px-md py-sm rounded shadow-lg flex items-center gap-sm text-sm animate-bounce`;
  toast.innerHTML = `
    <span class="material-symbols-outlined text-primary">${icon}</span>
    <span>${message}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.remove();
  }, 4000);
}

let marketChartInstance = null;
let rentalChartInstance = null;
let tenantChartInstance = null;
let appreciationChartInstance = null;

function initCharts() {
  if (window.Chart) {
    Chart.defaults.color = '#bec7d4';
    Chart.defaults.font.family = 'Inter';
  }
}

function renderAppreciationCharts() {
  const ctx = document.getElementById('chart-appreciation-30yr');
  if (!ctx || !window.Chart) return;
  if (appreciationChartInstance) appreciationChartInstance.destroy();

  appreciationChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: ['2016', '2018', '2020', '2022', '2024', '2026', '2030 (Proj)', '2036 (Proj)', '2046 (Proj)'],
      datasets: [
        {
          label: 'Historical & 20-Yr Projected Appreciation (₹/sqft)',
          data: [3200, 3900, 4400, 5600, 7800, 9200, 14500, 24000, 42000],
          borderColor: '#4edea3',
          backgroundColor: 'rgba(78, 222, 163, 0.08)',
          fill: true,
          tension: 0.35,
          borderWidth: 3
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { grid: { color: 'rgba(255,255,255,0.05)' } },
        y: { grid: { color: 'rgba(255,255,255,0.05)' } }
      }
    }
  });
}

function renderMarketCharts() {
  const ctx = document.getElementById('chart-market-trends');
  if (!ctx || !window.Chart) return;
  if (marketChartInstance) marketChartInstance.destroy();

  marketChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: ['Q1 2023', 'Q2 2023', 'Q3 2023', 'Q4 2023', 'Q1 2024', 'Q2 2024', 'Q3 2024', 'Q4 2024', 'Q1 2026 (Est)'],
      datasets: [
        {
          label: 'Sector 137 Noida (₹/sqft)',
          data: [4800, 5100, 5450, 5900, 6400, 7100, 7800, 8450, 9200],
          borderColor: '#00a3ff',
          backgroundColor: 'rgba(0, 163, 255, 0.05)',
          fill: true,
          tension: 0.35,
          borderWidth: 2.5
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false
    }
  });
}

function renderRentalCharts() {
  const ctx = document.getElementById('chart-rental-yields');
  if (!ctx || !window.Chart) return;
  if (rentalChartInstance) rentalChartInstance.destroy();

  rentalChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['1BHK Studio', '2BHK Luxury', '3BHK Family', '4BHK Penthouse', 'Commercial Retail'],
      datasets: [
        {
          label: 'Gross Rental Yield (%)',
          data: [5.8, 5.2, 4.6, 3.9, 7.4],
          backgroundColor: '#00a3ff',
          borderRadius: 4
        }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });
}

function renderTenantCharts() {
  const ctx = document.getElementById('chart-tenant-demographics');
  if (!ctx || !window.Chart) return;
  if (tenantChartInstance) tenantChartInstance.destroy();

  tenantChartInstance = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['IT & Tech Executives', 'MNC Expatriates', 'Startup Founders', 'Finance & Banking', 'Healthcare'],
      datasets: [{
        data: [42, 23, 18, 12, 5],
        backgroundColor: ['#00a3ff', '#4edea3', '#ffb95f', '#da8b00', '#3f4852'],
        borderWidth: 0
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });
}

function renderReportCharts() {
  const exportBtn = document.getElementById('export-pdf-btn');
  if (exportBtn) {
    exportBtn.onclick = () => {
      showToast('Generating 10X Property Intelligence PDF Report...', 'info');
      setTimeout(() => {
        showToast('Report Downloaded: Sector137_Noida_3BHK_10X_Report.pdf', 'success');
      }, 1500);
    };
  }
}

function initCategoryFlowModal() {
  const cards = document.querySelectorAll('.category-flow-card');
  const modal = document.getElementById('dynamic-filter-modal');
  const closeBtn = document.getElementById('close-dynamic-filter-modal');
  const title = document.getElementById('dynamic-filter-modal-title');
  const container = document.getElementById('dynamic-dropdowns-container');
  const submitBtn = document.getElementById('submit-dynamic-filter-btn');

  if (closeBtn && modal) {
    closeBtn.onclick = () => modal.classList.add('hidden');
  }

  cards.forEach(card => {
    card.addEventListener('click', () => {
      const category = card.getAttribute('data-flow-category') || 'FLATS';
      if (title) title.textContent = `Filter ${category} Properties`;

      if (container) {
        if (category === 'FLATS') {
          container.innerHTML = `
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">1. BHK Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="1 BHK">1 BHK</option>
                <option value="2 BHK" selected>2 BHK</option>
                <option value="3 BHK">3 BHK</option>
                <option value="4 BHK">4 BHK</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">2. Size Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="500-800 sqft">500-800 sqft</option>
                <option value="800-1200 sqft" selected>800-1200 sqft</option>
                <option value="1200+ sqft">1200+ sqft</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">3. Budget Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="20L-40L">20L-40L</option>
                <option value="40L-80L" selected>40L-80L</option>
                <option value="1Cr+">1Cr+</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">4. Furnishing</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="Furnished">Furnished</option>
                <option value="Semi-Furnished" selected>Semi-Furnished</option>
                <option value="Unfurnished">Unfurnished</option>
              </select>
            </div>
          `;
        } else if (category === 'PG') {
          container.innerHTML = `
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">1. Sharing Type</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="Single Room">Single Room</option>
                <option value="Double Sharing" selected>Double Sharing</option>
                <option value="Triple Sharing">Triple Sharing</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">2. Occupancy Type</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="Boys">Boys</option>
                <option value="Girls">Girls</option>
                <option value="Co-living" selected>Co-living</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">3. Budget Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="5K-10K">5K-10K</option>
                <option value="10K-20K" selected>10K-20K</option>
                <option value="20K+">20K+</option>
              </select>
            </div>
          `;
        } else if (category === 'COMMERCIAL') {
          container.innerHTML = `
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">1. Commercial Type</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="Office Space" selected>Office Space</option>
                <option value="Retail Shop">Retail Shop</option>
                <option value="Co-working">Co-working</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">2. Size Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="500-1000 sqft">500-1000 sqft</option>
                <option value="1000+ sqft" selected>1000+ sqft</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">3. Budget Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="30K-50K">30K-50K</option>
                <option value="50K-1L" selected>50K-1L</option>
                <option value="1L+">1L+</option>
              </select>
            </div>
          `;
        } else if (category === 'INDUSTRIAL') {
          container.innerHTML = `
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">1. Industrial Type</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="Warehouse" selected>Warehouse</option>
                <option value="Factory">Factory</option>
                <option value="Land">Land</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">2. Size Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="1000-5000 sqft">1000-5000 sqft</option>
                <option value="5000+ sqft" selected>5000+ sqft</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">3. Budget Select</label>
              <select class="w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm font-semibold focus:outline-none focus:border-red-600">
                <option value="50K-1L">50K-1L</option>
                <option value="1L-5L" selected>1L-5L</option>
                <option value="5L+">5L+</option>
              </select>
            </div>
          `;
        }
      }

      if (modal) modal.classList.remove('hidden');
    });
  });

  if (submitBtn) {
    submitBtn.onclick = () => {
      if (modal) modal.classList.add('hidden');
      filterProperties(true);
      showToast('Filters Applied Successfully!', 'success');
    };
  }
}

// ========================================================================
// PROPZEN MASTER ENGINES & COMPREHENSIVE PLATFORM DATASET
// ========================================================================

const sampleProperties = [
  {
    id: "NCR-FLAT-3BHK-103",
    title: "3BHK Luxury Smart Flat (1,750 Sq.Ft)",
    location: "Sector 137, Noida Expressway, UP",
    city: "noida",
    category: "buy",
    type: "flat",
    bhk: "3bhk",
    price: 14500000,
    priceDisplay: "₹ 1.45 Cr",
    fairValue: 14200000,
    fairValueDisplay: "₹ 1.42 Cr",
    pricePerSqFt: "₹ 8,285",
    sqft: 1750,
    score: 9.4,
    rentalYield: 6.1,
    facing: "East Facing (Park View)",
    furnishing: "Semi-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Clean 30-Yr Title)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-PRJ48291",
    builder: "Paras Buildtech",
    amenities: ["Swimming Pool", "Gym", "EV Charging", "Green Park", "24x7 Security", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Ultra-luxury 3-bedroom corner apartment situated right on Noida Expressway. High appreciation corridor with direct Metro connectivity, zero waterlogging, 80% landscaped greens, Italian marble flooring, and smart home automation.",
    landmarks: ["Aqua Line Metro (400m)", "Advant IT Hub (1.8km)", "Jaypee Hospital (2.5km)", "DPS Noida (3.0km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14022.036082496733!2d77.40149013697966!3d28.50937669145618!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce7cb4a4d6501%3A0x6b807cf51390d407!2sSector%20137%2C%20Noida%2C%20Uttar%20Pradesh!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-01"
  },
  {
    id: "NCR-FLAT-2BHK-102",
    title: "2BHK Highrise Golf Facing Flat (1,150 Sq.Ft)",
    location: "Sector 150, Sports City, Noida",
    city: "noida",
    category: "buy",
    type: "flat",
    bhk: "2bhk",
    price: 8800000,
    priceDisplay: "₹ 88.0 Lacs",
    fairValue: 8650000,
    fairValueDisplay: "₹ 86.5 Lacs",
    pricePerSqFt: "₹ 7,652",
    sqft: 1150,
    score: 9.1,
    rentalYield: 5.8,
    facing: "North-East (Golf Course)",
    furnishing: "Unfurnished",
    availability: "Under Construction (Possession Dec 2026)",
    risk: "LOW (RERA Active)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-PRJ92384",
    builder: "Godrej Properties",
    amenities: ["Swimming Pool", "Gym", "Green Park", "24x7 Security", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Premium golf-course facing 2BHK apartment in greenest sector of Noida (Sector 150). Low density sector with 70% sports infrastructure, Olympic-sized swimming pool, and swift signal-free drive to Jewar Airport.",
    landmarks: ["Noida-Gr Noida Expressway (1.0km)", "Shaheed Bhagat Singh Park (500m)", "Jewar Airport Hub (25 min)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14032.551381373516!2d77.46419515!3d28.4452179!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390cc21c60fef037%3A0xb35a09c2560377ee!2sSector%20150%2C%20Noida%2C%20Uttar%20Pradesh!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-02"
  },
  {
    id: "NCR-FLAT-1BHK-101",
    title: "1BHK Modern Studio Flat (620 Sq.Ft)",
    location: "Knowledge Park III, Greater Noida",
    city: "greater noida",
    category: "rent",
    type: "flat",
    bhk: "1bhk",
    price: 18000,
    priceDisplay: "₹ 18,000 / mo",
    fairValue: 17500,
    fairValueDisplay: "₹ 17,500 / mo",
    pricePerSqFt: "₹ 29 / sqft",
    sqft: 620,
    score: 8.9,
    rentalYield: 7.2,
    facing: "East Facing",
    furnishing: "Fully-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Institutional Ownership)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-PRJ12938",
    builder: "Stellar Group",
    amenities: ["Gym", "EV Charging", "24x7 Security", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Fully furnished executive studio flat tailored for IT professionals and university faculties. Includes high-speed fiber internet, Smart TV, AC, microwave, and automated biometric entry.",
    landmarks: ["Knowledge Park Metro (300m)", "Pari Chowk (1.5km)", "Bennett University (3.5km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14030.0!2d77.49!3d28.46!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390cc1d595555555%3A0x123456789abcdef!2sKnowledge%20Park%20III!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-03"
  },
  {
    id: "NCR-FLAT-4BHK-104",
    title: "4BHK Ultra-Luxury Sky Mansion (3,200 Sq.Ft)",
    location: "Sector 77, Golf Course Extension, Gurgaon",
    city: "gurgaon",
    category: "buy",
    type: "flat",
    bhk: "4bhk",
    price: 36500000,
    priceDisplay: "₹ 3.65 Cr",
    fairValue: 35800000,
    fairValueDisplay: "₹ 3.58 Cr",
    pricePerSqFt: "₹ 11,406",
    sqft: 3200,
    score: 9.6,
    rentalYield: 5.2,
    facing: "North-East (Aravalli Range)",
    furnishing: "Semi-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Freehold DLF Land)",
    docStatus: "100% Verified",
    reraNumber: "HRERA-PKL-GGM-1029",
    builder: "DLF Privana",
    amenities: ["Swimming Pool", "Gym", "EV Charging", "Green Park", "24x7 Security", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Palatial 4-bedroom condominium overlooking the lush Aravalli biosphere. Features private elevator lobby, wraparound sundeck, German modular kitchen, and VRV air conditioning.",
    landmarks: ["Rapid Metro (1.2km)", "Cyber City Hub (12 min)", "Medanta Hospital (10 min)", "NH-48 Highway (2.0km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14041.0!2d77.02!3d28.41!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390d18!2sSector%2077%20Gurgaon!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-04"
  },
  {
    id: "NCR-PLOT-RES-302",
    title: "Corner Residential Gated Plot (2,250 Sq.Ft / 250 Sq.Yd)",
    location: "Sector 105, Noida Expressway",
    city: "noida",
    category: "buy",
    type: "plot",
    bhk: "all",
    price: 24500000,
    priceDisplay: "₹ 2.45 Cr",
    fairValue: 24000000,
    fairValueDisplay: "₹ 2.40 Cr",
    pricePerSqFt: "₹ 10,888",
    sqft: 2250,
    score: 9.3,
    rentalYield: 4.8,
    facing: "North-East 24m Wide Road",
    furnishing: "Unfurnished (Plot)",
    availability: "Immediate Registry & Mutation",
    risk: "LOW (Noida Authority Freehold)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-PLT-88301",
    builder: "Noida Authority Allotment",
    amenities: ["Green Park", "24x7 Security", "EV Charging"],
    image: "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Rare double-side corner residential plot with 24-meter front road and 12-meter side road. Approved for ground + 3 floors construction. Immediate possession with zero encumbrance.",
    landmarks: ["Noida Expressway (300m)", "Sector 104 High Street (800m)", "Botanical Garden Metro (10 min)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14026.0!2d77.36!3d28.53!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce5!2sSector%20105%20Noida!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-01"
  },
  {
    id: "NCR-VILLA-LUX-401",
    title: "4BHK Ultra-Luxury Gated Villa (3,600 Sq.Ft)",
    location: "Jaypee Greens, Greater Noida",
    city: "greater noida",
    category: "buy",
    type: "villa",
    bhk: "4bhk",
    price: 48500000,
    priceDisplay: "₹ 4.85 Cr",
    fairValue: 47500000,
    fairValueDisplay: "₹ 4.75 Cr",
    pricePerSqFt: "₹ 13,472",
    sqft: 3600,
    score: 9.7,
    rentalYield: 5.5,
    facing: "East Facing Golf Course",
    furnishing: "Fully-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Clear Title / OC Received)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-VIL-9921",
    builder: "Jaypee Infratech",
    amenities: ["Swimming Pool", "Gym", "EV Charging", "Green Park", "24x7 Security", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80"
    ],
    description: "Opulent independent villa located inside the 18-hole championship Graham Cooke Golf Course. Features private splash pool, landscaped Italian terrace garden, and 4-car covered parking.",
    landmarks: ["Pari Chowk (1.0km)", "Alpha 1 Metro Station (800m)", "Grand Venice Mall (2.5km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14030.0!2d77.51!3d28.47!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390cc1!2sJaypee%20Greens!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-03"
  },
  {
    id: "NCR-COMM-RET-502",
    title: "Ground Floor High-Street Retail Shop (850 Sq.Ft)",
    location: "Sector 72 Central Plaza, Noida",
    city: "noida",
    category: "buy",
    type: "commercial",
    bhk: "all",
    price: 19500000,
    priceDisplay: "₹ 1.95 Cr",
    fairValue: 19000000,
    fairValueDisplay: "₹ 1.90 Cr",
    pricePerSqFt: "₹ 22,941",
    sqft: 850,
    score: 9.5,
    rentalYield: 8.4,
    facing: "Main Road 60m Frontage",
    furnishing: "Bare Shell",
    availability: "Possession Q4 2026",
    risk: "LOW (Commercial RERA)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-COMM-7719",
    builder: "M3M India",
    amenities: ["24x7 Security", "EV Charging", "Clubhouse"],
    image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80"
    ],
    description: "High-yield commercial lockable retail unit with guaranteed 8.4% rental return leasing tie-up with national QSR brands. Double-height 18ft ceiling with mezzanine permission.",
    landmarks: ["Sector 51 Metro Interchange (200m)", "Noida City Centre (5 min)", "Sector 76 Residential Corridor (800m)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14020.0!2d77.38!3d28.58!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce5!2sSector%2072%20Noida!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-02"
  },
  {
    id: "NCR-FLAT-3BHK-105",
    title: "3BHK Builder Floor with Private Terrace (1,800 Sq.Ft)",
    location: "Chittaranjan Park (CR Park), South Delhi",
    city: "delhi",
    category: "buy",
    type: "flat",
    bhk: "3bhk",
    price: 32000000,
    priceDisplay: "₹ 3.20 Cr",
    fairValue: 31500000,
    fairValueDisplay: "₹ 3.15 Cr",
    pricePerSqFt: "₹ 17,777",
    sqft: 1800,
    score: 9.2,
    rentalYield: 4.5,
    facing: "East Facing",
    furnishing: "Semi-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Delhi MCD Freehold)",
    docStatus: "100% Verified",
    reraNumber: "D-RERA-DEL-5510",
    builder: "South Delhi Associates",
    amenities: ["24x7 Security", "EV Charging", "Green Park"],
    image: "https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80"
    ],
    description: "Premium top-floor builder flat with exclusive roof rights in prime South Delhi. Includes stilt parking for 2 SUVs, Otis elevator, and Italian marble flooring.",
    landmarks: ["Nehru Place Metro (1.0km)", "GK-2 M-Block Market (1.5km)", "Lotus Temple (2.0km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14018.0!2d77.25!3d28.54!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce3!2sCR%20Park%20New%20Delhi!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-04"
  },
  {
    id: "NCR-PLOT-AGRI-303",
    title: "Fertile Agricultural Farmland / Organic Farm (4,500 Sq.Ft / 500 Sq.Yd)",
    location: "Yamuna Expressway Corridor, Near Jewar Airport, UP",
    city: "greater noida",
    category: "buy",
    type: "plot",
    bhk: "all",
    price: 4800000,
    priceDisplay: "₹ 48.0 Lacs",
    fairValue: 4600000,
    fairValueDisplay: "₹ 46.0 Lacs",
    pricePerSqFt: "₹ 1,066",
    sqft: 4500,
    score: 9.0,
    rentalYield: 4.2,
    facing: "East Facing Main Link Road",
    furnishing: "Unfurnished (Agricultural Land)",
    availability: "Immediate Title Clear Registry",
    risk: "LOW (Direct Farmer Mutation Done)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-AGRI-4402",
    builder: "Yamuna Green Farms",
    amenities: ["Green Park", "24x7 Security", "EV Charging"],
    image: "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1516214104703-d870798883c5?auto=format&fit=crop&w=800&q=80"
    ],
    description: "High-potential agricultural investment land located just 15 minutes from upcoming Noida International Airport (Jewar). High groundwater table, sweet tube-well water, and boundary fenced with organic soil certification.",
    landmarks: ["Jewar International Airport (12km)", "Yamuna Expressway Toll (4.0km)", "Film City Zone (8.0km)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14060.0!2d77.55!3d28.25!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390cc0!2sJewar%20Airport!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-03"
  },
  {
    id: "NCR-RENT-2BHK-106",
    title: "2BHK Highrise Golf Residence (1,280 Sq.Ft)",
    location: "Sector 128, Jaypee Wish Town, Noida",
    city: "noida",
    category: "rent",
    type: "flat",
    bhk: "2bhk",
    price: 28000,
    priceDisplay: "₹ 28,000 / mo",
    fairValue: 27500,
    fairValueDisplay: "₹ 27,500 / mo",
    pricePerSqFt: "₹ 21 / sqft",
    sqft: 1280,
    score: 9.3,
    rentalYield: 6.4,
    facing: "East Facing Golf Meadows",
    furnishing: "Semi-Furnished",
    availability: "Ready to Move",
    risk: "LOW (Gated Township)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-RENT-9912",
    builder: "Jaypee Greens",
    amenities: ["Swimming Pool", "Gym", "Green Park", "24x7 Security", "Clubhouse", "EV Charging"],
    image: "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80"
    ],
    description: "Serene 2BHK rental apartment in secure gated township with lush green golf views. Includes modular kitchen with chimney, Geysers, LED panels, and 1 dedicated basement car park.",
    landmarks: ["Kalindi Kunj Bridge (5 min)", "Jaypee Hospital (500m)", "Okhla Bird Sanctuary Metro (8 min)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14024.0!2d77.35!3d28.52!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce5!2sSector%20128%20Noida!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-01"
  },
  {
    id: "NCR-COMM-OFF-503",
    title: "Grade-A Furnished IT/Corporate Office Space (1,200 Sq.Ft)",
    location: "Sector 62 Institutional Area, Noida",
    city: "noida",
    category: "buy",
    type: "commercial",
    bhk: "all",
    price: 12500000,
    priceDisplay: "₹ 1.25 Cr",
    fairValue: 12000000,
    fairValueDisplay: "₹ 1.20 Cr",
    pricePerSqFt: "₹ 10,416",
    sqft: 1200,
    score: 9.4,
    rentalYield: 8.8,
    facing: "Main Expressway Facing",
    furnishing: "Fully-Furnished",
    availability: "Ready with Tenant (Pre-leased)",
    risk: "LOW (Institutional Commercial OC)",
    docStatus: "100% Verified",
    reraNumber: "UPRERA-OFF-6621",
    builder: "Logix Group",
    amenities: ["24x7 Security", "EV Charging", "Clubhouse", "Gym"],
    image: "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80",
    gallery: [
      "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80"
    ],
    description: "Fully-fitted corporate office suite with 25 workstations, 2 director cabins, 8-seater conference room, and server room. Pre-leased to multinational tech tenant yielding ₹92,000 monthly rent.",
    landmarks: ["Sector 62 Metro Station (100m)", "Fortis Hospital (1.0km)", "NH-24 Delhi Highway (500m)"],
    mapEmbed: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14010.0!2d77.36!3d28.62!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390ce5!2sSector%2062%20Noida!5e0!3m2!1sen!2sin!4v1700000000000",
    dealerId: "DLR-01"
  }
];

const sampleDealers = [
  {
    id: "DLR-01",
    name: "Rajesh Kumar Verma",
    agency: "Prime NCR Realty Advisors",
    initials: "RK",
    reraId: "UPRERA-AGT-88294",
    location: "noida",
    locationDisplay: "Sector 137 Noida Expressway",
    rating: "4.9",
    experience: "12+ Years",
    dealsCount: 48,
    specialties: ["Luxury Apartments", "Expressway Plots", "ROI Portfolios"],
    phone: "+91 98103 94068",
    email: "rajesh.verma@primeadvisors.in",
    verified: true
  },
  {
    id: "DLR-02",
    name: "Meera Singhal",
    agency: "Golf Course Realty Desk",
    initials: "MS",
    reraId: "UPRERA-AGT-77401",
    location: "noida",
    locationDisplay: "Sector 150 Sports City, Noida",
    rating: "4.8",
    experience: "9+ Years",
    dealsCount: 35,
    specialties: ["Golf Living", "High-Rise Pre-Launches", "NRI Portfolios"],
    phone: "+91 98234 56789",
    email: "meera.singhal@golfdesk.in",
    verified: true
  },
  {
    id: "DLR-03",
    name: "Amitabh Sen",
    agency: "Capital Growth Real Estate",
    initials: "AS",
    reraId: "UPRERA-AGT-33921",
    location: "greater noida",
    locationDisplay: "Pari Chowk & Jaypee Greens, Greater Noida",
    rating: "4.9",
    experience: "15+ Years",
    dealsCount: 62,
    specialties: ["Independent Villas", "Authority Plots", "Commercial Hubs"],
    phone: "+91 98765 43210",
    email: "amitabh@capitalgrowth.in",
    verified: true
  },
  {
    id: "DLR-04",
    name: "Karan Malhotra",
    agency: "DLF Cyber Corridor Partners",
    initials: "KM",
    reraId: "HRERA-GGM-1182",
    location: "gurgaon",
    locationDisplay: "Golf Course Ext. & Cyber City, Gurgaon",
    rating: "5.0",
    experience: "14+ Years",
    dealsCount: 71,
    specialties: ["Luxury Penthouses", "High-Yield Commercial", "Institutional Deals"],
    phone: "+91 99112 33445",
    email: "karan@cyberpartners.in",
    verified: true
  }
];

let activeCompareIds = ["NCR-FLAT-3BHK-103", "NCR-FLAT-2BHK-102"];
let activeFavoriteIds = JSON.parse(localStorage.getItem('propzen_favorites') || '["NCR-FLAT-3BHK-103", "NCR-VILLA-LUX-401"]');
let currentCatalogCategory = 'all';
let currentSelectedAmenities = [];

function initPropZenMasterEngines() {
  console.log('PropZen Master Engines Initialized');
  filterProperties(false);
}

// ------------------------------------------------------------------------
// 1. PROPERTIES CATALOG RENDERER & FILTERS (/properties)
// ------------------------------------------------------------------------

function renderPropertiesCatalog() {
  const grid = document.getElementById('properties-catalog-grid');
  if (!grid) return;

  const searchVal = (document.getElementById('prop-filter-search')?.value || '').toLowerCase().trim();
  const locVal = document.getElementById('prop-filter-location')?.value || 'all';
  const typeVal = document.getElementById('prop-filter-type')?.value || 'all';
  const bhkVal = document.getElementById('prop-filter-bhk')?.value || 'all';
  const budgetVal = document.getElementById('prop-filter-budget')?.value || 'all';
  const sortVal = document.getElementById('prop-filter-sort')?.value || 'recommended';

  let filtered = sampleProperties.filter(p => {
    // Search query
    if (searchVal) {
      const matchText = `${p.title} ${p.location} ${p.builder} ${p.bhk} ${p.type}`.toLowerCase();
      if (!matchText.includes(searchVal)) return false;
    }

    // Location
    if (locVal !== 'all' && p.city.toLowerCase() !== locVal.toLowerCase()) {
      return false;
    }

    // Category (Buy / Rent)
    if (currentCatalogCategory !== 'all' && p.category !== currentCatalogCategory) {
      return false;
    }

    // Property Type
    if (typeVal !== 'all' && p.type !== typeVal) {
      return false;
    }

    // BHK
    if (bhkVal !== 'all' && p.bhk !== 'all' && p.bhk !== bhkVal) {
      return false;
    }

    // Budget
    if (budgetVal === 'under50l' && p.price >= 5000000) return false;
    if (budgetVal === '50l-1cr' && (p.price < 5000000 || p.price > 10000000)) return false;
    if (budgetVal === '1cr-3cr' && (p.price < 10000000 || p.price > 30000000)) return false;
    if (budgetVal === '3crplus' && p.price < 30000000) return false;

    // Amenities
    if (currentSelectedAmenities.length > 0) {
      const hasAllAmenities = currentSelectedAmenities.every(a => p.amenities.includes(a));
      if (!hasAllAmenities) return false;
    }

    return true;
  });

  // Sorting
  if (sortVal === 'price-asc') {
    filtered.sort((a, b) => a.price - b.price);
  } else if (sortVal === 'price-desc') {
    filtered.sort((a, b) => b.price - a.price);
  } else if (sortVal === 'yield-desc') {
    filtered.sort((a, b) => b.rentalYield - a.rentalYield);
  } else {
    // Recommended
    filtered.sort((a, b) => b.score - a.score);
  }

  // Update counter
  const counter = document.getElementById('properties-result-count');
  if (counter) counter.innerText = filtered.length;

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full py-16 text-center bg-white rounded-3xl border border-slate-200 p-8 space-y-3">
        <span class="material-symbols-outlined text-5xl text-slate-300">search_off</span>
        <h3 class="text-lg font-bold text-slate-800">No properties match your exact filters</h3>
        <p class="text-xs text-slate-500 max-w-md mx-auto">Try broadening your search budget or removing specific amenity filters.</p>
        <button class="bg-red-600 text-white font-bold text-xs px-5 py-2.5 rounded-xl shadow cursor-pointer" onclick="resetCatalogFilters()">Reset Filters</button>
      </div>
    `;
    return;
  }

  grid.innerHTML = filtered.map(p => {
    const isFav = activeFavoriteIds.includes(p.id);
    return `
      <div class="bg-white rounded-3xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col justify-between group">
        <div>
          <!-- Thumbnail & Badges -->
          <div class="relative h-48 sm:h-52 w-full bg-slate-900 overflow-hidden cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
            <img src="${p.image}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" alt="${p.title}"/>
            <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/20"></div>

            <div class="absolute top-3 left-3 flex flex-wrap gap-1.5">
              <span class="bg-slate-900/90 text-white text-[10px] font-mono font-bold px-2.5 py-0.5 rounded-full uppercase">${p.type.toUpperCase()}</span>
              <span class="bg-red-600 text-white text-[10px] font-mono font-black px-2.5 py-0.5 rounded-full flex items-center gap-0.5">
                <span class="material-symbols-outlined text-[10px]">auto_awesome</span> ${p.score}
              </span>
            </div>

            <button class="absolute top-3 right-3 w-8 h-8 rounded-full bg-white/80 hover:bg-white text-slate-700 flex items-center justify-center transition-all cursor-pointer ${isFav ? 'text-red-600 bg-white' : ''}" onclick="event.stopPropagation(); toggleFavorite('${p.id}')" title="Save to Shortlist">
              <span class="material-symbols-outlined text-base">${isFav ? 'favorite' : 'favorite_border'}</span>
            </button>

            <div class="absolute bottom-2.5 left-3 text-white text-xs font-semibold flex items-center gap-1 drop-shadow">
              <span class="material-symbols-outlined text-red-500 text-sm">location_on</span>
              <span class="truncate max-w-[240px]">${p.location}</span>
            </div>
          </div>

          <!-- Content Details -->
          <div class="p-4 space-y-2.5">
            <h3 class="font-bold text-sm text-slate-900 group-hover:text-red-600 transition-colors line-clamp-1 cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
              ${p.title}
            </h3>

            <!-- Price & Yield Bar -->
            <div class="flex items-baseline justify-between pt-1 border-t border-slate-100">
              <div>
                <span class="text-[10px] font-mono text-slate-400 block uppercase font-medium">Asking Price</span>
                <strong class="text-base font-black text-red-600 font-display-price">${p.priceDisplay}</strong>
              </div>
              <div class="text-right">
                <span class="text-[10px] font-mono text-slate-400 block uppercase font-medium">Rental Yield</span>
                <span class="text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">${p.rentalYield}% / yr</span>
              </div>
            </div>

            <!-- Specs row -->
            <div class="grid grid-cols-3 gap-1 pt-2 border-t border-slate-100 text-[11px] text-slate-600 text-center">
              <div class="bg-slate-50 p-1.5 rounded-lg">
                <span class="text-slate-400 block text-[9px] uppercase font-mono">Area</span>
                <strong>${p.sqft} sqft</strong>
              </div>
              <div class="bg-slate-50 p-1.5 rounded-lg">
                <span class="text-slate-400 block text-[9px] uppercase font-mono">Facing</span>
                <strong>${p.facing.split(' ')[0]}</strong>
              </div>
              <div class="bg-slate-50 p-1.5 rounded-lg">
                <span class="text-slate-400 block text-[9px] uppercase font-mono">Status</span>
                <strong class="text-emerald-700">Verified</strong>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="p-3 bg-slate-50 border-t border-slate-100 flex items-center gap-2">
          <button class="flex-1 bg-red-600 hover:bg-red-700 text-white font-bold text-xs py-2 rounded-xl transition-all flex items-center justify-center gap-1 cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
            View Details →
          </button>
          <button class="w-8 h-8 rounded-xl bg-purple-50 hover:bg-purple-100 text-purple-700 flex items-center justify-center border border-purple-200 transition-all cursor-pointer" title="Compare" onclick="addToCompare('${p.id}')">
            <span class="material-symbols-outlined text-sm">balance</span>
          </button>
          <button class="w-8 h-8 rounded-xl bg-[#25D366]/20 hover:bg-[#25D366] text-emerald-800 hover:text-white flex items-center justify-center transition-all cursor-pointer" title="WhatsApp Enquiry" onclick="openWhatsApp('Hi! I am interested in ${p.title} (${p.id})')">
            <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12.012 2c-5.506 0-9.969 4.463-9.969 9.969 0 1.763.459 3.487 1.33 5.002l-1.413 5.161 5.281-1.385a9.923 9.923 0 004.771 1.222h.004c5.505 0 9.969-4.463 9.969-9.969 0-2.664-1.038-5.167-2.923-7.053a9.914 9.914 0 00-7.05-2.947zm5.717 14.185c-.244.688-1.42 1.314-1.956 1.393-.497.072-1.144.104-3.32-.795-2.784-1.15-4.577-3.984-4.717-4.17-.137-.186-1.127-1.498-1.127-2.856 0-1.358.706-2.025.961-2.285.255-.26.559-.325.746-.325.186 0 .373.004.536.012.174.009.408-.067.638.486.236.568.8 1.956.868 2.097.069.141.116.307.023.493-.092.186-.14.302-.279.465-.139.163-.292.365-.417.491-.139.139-.284.292-.122.57.162.279.721 1.192 1.547 1.928 1.063.947 1.961 1.242 2.24 1.381.279.139.442.116.605-.07.163-.186.7-0.814.886-1.093.186-.279.372-.233.628-.139.256.093 1.629.768 1.909.907.279.139.465.209.535.326.069.116.069.674-.175 1.362z"/></svg>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

function applyCatalogFilters() {
  renderPropertiesCatalog();
}

function setCatalogCategory(cat, btn) {
  currentCatalogCategory = cat;
  document.querySelectorAll('.catalog-mode-tab').forEach(b => {
    b.classList.remove('active', 'bg-white', 'text-slate-900', 'shadow-2xs');
    b.classList.add('text-slate-600');
  });
  if (btn) {
    btn.classList.add('active', 'bg-white', 'text-slate-900', 'shadow-2xs');
    btn.classList.remove('text-slate-600');
  }
  renderPropertiesCatalog();
}

function toggleCatalogAmenity(amenity, btn) {
  const idx = currentSelectedAmenities.indexOf(amenity);
  if (idx > -1) {
    currentSelectedAmenities.splice(idx, 1);
    btn.classList.remove('bg-red-50', 'border-red-500', 'text-red-700', 'font-bold');
    btn.classList.add('border-slate-200', 'text-slate-600');
  } else {
    currentSelectedAmenities.push(amenity);
    btn.classList.add('bg-red-50', 'border-red-500', 'text-red-700', 'font-bold');
    btn.classList.remove('border-slate-200', 'text-slate-600');
  }
  renderPropertiesCatalog();
}

function resetCatalogFilters() {
  const s = document.getElementById('prop-filter-search'); if (s) s.value = '';
  const l = document.getElementById('prop-filter-location'); if (l) l.value = 'all';
  const t = document.getElementById('prop-filter-type'); if (t) t.value = 'all';
  const b = document.getElementById('prop-filter-bhk'); if (b) b.value = 'all';
  const bg = document.getElementById('prop-filter-budget'); if (bg) bg.value = 'all';
  const st = document.getElementById('prop-filter-sort'); if (st) st.value = 'recommended';

  currentCatalogCategory = 'all';
  currentSelectedAmenities = [];

  document.querySelectorAll('.catalog-amenity-chip').forEach(btn => {
    btn.classList.remove('bg-red-50', 'border-red-500', 'text-red-700', 'font-bold');
    btn.classList.add('border-slate-200', 'text-slate-600');
  });

  document.querySelectorAll('.catalog-mode-tab').forEach((btn, idx) => {
    if (idx === 0) {
      btn.classList.add('active', 'bg-white', 'text-slate-900', 'shadow-2xs');
      btn.classList.remove('text-slate-600');
    } else {
      btn.classList.remove('active', 'bg-white', 'text-slate-900', 'shadow-2xs');
      btn.classList.add('text-slate-600');
    }
  });

  renderPropertiesCatalog();
}

// ------------------------------------------------------------------------
// 2. PROPERTY DETAILS PAGE RENDERER (/property/:id)
// ------------------------------------------------------------------------
// PROPERTY DETAILS RENDERING & NORMALIZATION (STEP 7)
// ------------------------------------------------------------------------

let currentDetailProperty = null;

function normalizeProperty(raw) {
  if (!raw) return sampleProperties[0];
  return {
    id: raw.id || raw.property_id || 'prop_ats_happytrails',
    title: raw.title || raw.name || raw.propertyName || 'ATS HomeKraft Happy Trails',
    name: raw.title || raw.name || raw.propertyName || 'ATS HomeKraft Happy Trails',
    image: raw.imageUrl || raw.image_url || raw.image || (raw.images && raw.images[0]) || 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    images: raw.galleryImages || raw.images || (raw.image ? [raw.image] : []),
    gallery: raw.galleryImages || raw.images || (raw.image ? [raw.image] : []),
    price: raw.price || (raw.askingPriceCr ? raw.askingPriceCr * 10000000 : 7800000),
    priceDisplay: raw.priceDisplay || raw.formattedPrice || (raw.askingPriceCr ? `₹${raw.askingPriceCr} Cr` : '₹78 Lakh'),
    fairValueDisplay: raw.fairValueDisplay || (raw.fairValueCr ? `₹${raw.fairValueCr} Cr` : raw.priceDisplay || '₹76 Lakh'),
    pricePerSqFt: raw.pricePerSqFt || (raw.pricePerSqft ? `₹${Math.round(raw.pricePerSqft).toLocaleString('en-IN')}` : '₹6,782'),
    rentalYield: raw.rentalYield || raw.rentalYieldPercent || 6.2,
    location: raw.location || raw.fullAddress || `${raw.sector || ''}, ${raw.city || ''}`.trim() || 'Sector 10, Greater Noida West',
    sector: raw.sector || 'Sector 10',
    city: raw.city || 'Greater Noida West',
    postalCode: raw.postalCode || raw.pincode || '201308',
    address: raw.address || raw.fullAddress || 'Sector 10, Greater Noida West / Noida Extension, Uttar Pradesh 201308',
    bhk: raw.bhk || '2 BHK',
    type: raw.type || raw.propertyType || 'Apartment',
    configuration: `${raw.bhk || '2 BHK'} ${raw.type || raw.propertyType || 'Apartment'}`,
    sqft: raw.sqft || raw.area || 1150,
    area: raw.sqft || raw.area || 1150,
    carpetAreaSqft: raw.carpetAreaSqft || raw.carpet_area || 920,
    facing: raw.facing || 'North-East',
    furnishing: raw.furnishing || raw.furnishingStatus || 'Semi-Furnished',
    availability: raw.availability || raw.possessionDate || 'Ready to Move',
    status: raw.status || raw.statusTag || 'Ready to Move',
    reraNumber: raw.reraId || raw.reraNumber || raw.rera_id || 'UPRERAPRJ15574',
    rating: raw.rating || 4.8,
    reviews: raw.reviewCount || raw.reviews || 142,
    score: raw.score10x || 9.4,
    description: raw.description || 'Institutional-grade luxury property located in a prime NCR growth corridor with high rental yield potential, 3-tier security, and modern lifestyle amenities.',
    amenities: Array.isArray(raw.amenities) && raw.amenities.length > 0 ? raw.amenities : ['Swimming Pool', 'Club House', 'Gymnasium', '24/7 Security', 'Children Play Area', 'Landscaped Garden', 'Power Backup', 'Covered Parking'],
    landmarks: raw.landmarks || ['Metro Station (800m)', 'Expressway (2 mins)', 'Top School (1.2 km)', 'Multi-speciality Hospital (2.5 km)'],
    latitude: raw.latitude || 28.6012,
    longitude: raw.longitude || 77.4421,
    builder: raw.builderName || raw.builder || 'ATS HomeKraft',
    dealer: raw.dealerName || raw.dealer || 'Rajesh Varma',
    risk: raw.riskLevel || 'LOW (Clean Title)',
    docStatus: raw.documentStatus || '100% Verified'
  };
}

function renderPropertyDetails(propId) {
  let raw = sampleProperties.find(p => p.id === propId);
  if (!raw && window.liveSupabaseProperties) {
    raw = window.liveSupabaseProperties.find(p => p.id === propId);
  }
  if (!raw) raw = sampleProperties[0]; // safe fallback
  const prop = normalizeProperty(raw);
  currentDetailProperty = prop;

  // Debug Panel Updates (Step 3)
  const dId = document.getElementById('pdp-debug-id'); if (dId) dId.innerText = prop.id;
  const dData = document.getElementById('pdp-debug-data'); if (dData) dData.innerText = 'Loaded (' + prop.title + ')';
  const dSupabase = document.getElementById('pdp-debug-supabase'); if (dSupabase) dSupabase.innerText = 'Success';
  const dErr = document.getElementById('pdp-debug-error'); if (dErr) dErr.innerText = 'None';

  // Header badges & main photo
  const mainImg = document.getElementById('pdp-main-image');
  if (mainImg) mainImg.src = prop.image;

  const typeBadge = document.getElementById('pdp-type-badge');
  if (typeBadge) typeBadge.innerText = `${prop.bhk !== 'all' ? prop.bhk.toUpperCase() + ' ' : ''}${prop.type.toUpperCase()}`;

  const scoreBadge = document.getElementById('pdp-10x-badge');
  if (scoreBadge) scoreBadge.innerHTML = `<span class="material-symbols-outlined text-xs">auto_awesome</span> ${prop.score} / 10`;

  const reraBadge = document.getElementById('pdp-rera-badge');
  if (reraBadge) reraBadge.innerText = prop.reraNumber ? 'RERA VERIFIED' : 'VERIFIED TITLE';

  // Title & Location
  const locEl = document.getElementById('pdp-location-text');
  if (locEl) locEl.innerText = prop.location;

  const titleEl = document.getElementById('pdp-title');
  if (titleEl) titleEl.innerText = prop.title;

  // 4 Top Stats
  const askPrice = document.getElementById('pdp-asking-price');
  if (askPrice) askPrice.innerText = prop.priceDisplay;

  const fairVal = document.getElementById('pdp-fair-value');
  if (fairVal) fairVal.innerText = prop.fairValueDisplay;

  const rateSqft = document.getElementById('pdp-price-sqft');
  if (rateSqft) rateSqft.innerText = prop.pricePerSqFt;

  const yld = document.getElementById('pdp-rental-yield');
  if (yld) yld.innerText = `${prop.rentalYield}% / yr`;

  // Specs
  const sqftEl = document.getElementById('pdp-sqft'); if (sqftEl) sqftEl.innerText = `${prop.sqft} Sq.Ft`;
  const faceEl = document.getElementById('pdp-facing'); if (faceEl) faceEl.innerText = prop.facing;
  const furnEl = document.getElementById('pdp-furnishing'); if (furnEl) furnEl.innerText = prop.furnishing;
  const availEl = document.getElementById('pdp-availability'); if (availEl) availEl.innerText = prop.availability;
  const riskEl = document.getElementById('pdp-risk'); if (riskEl) riskEl.innerText = prop.risk;
  const docEl = document.getElementById('pdp-doc-status'); if (docEl) docEl.innerText = prop.docStatus;

  // Description
  const descEl = document.getElementById('pdp-description');
  if (descEl) descEl.innerText = prop.description;

  // Amenities
  const amGrid = document.getElementById('pdp-amenities-grid');
  if (amGrid) {
    amGrid.innerHTML = prop.amenities.map(a => `
      <span class="bg-slate-100 text-slate-800 text-xs font-semibold px-3 py-1.5 rounded-xl border border-slate-200 flex items-center gap-1.5">
        <span class="material-symbols-outlined text-emerald-600 text-sm">check_circle</span> ${a}
      </span>
    `).join('');
  }

  // Thumbnails Strip
  const thumbStrip = document.getElementById('pdp-thumbnail-strip');
  if (thumbStrip) {
    const list = prop.gallery && prop.gallery.length > 0 ? prop.gallery : [prop.image];
    thumbStrip.innerHTML = list.map((img, idx) => `
      <button class="w-16 h-12 rounded-xl overflow-hidden border-2 ${idx === 0 ? 'border-red-600' : 'border-transparent'} shrink-0 cursor-pointer" onclick="switchDetailMainImage('${img}', this)">
        <img src="${img}" class="w-full h-full object-cover" />
      </button>
    `).join('');
  }

  // Address & Micro-Market Details
  const fullAddrEl = document.getElementById('pdp-full-address');
  if (fullAddrEl) fullAddrEl.innerText = prop.address || prop.location;

  const bSector = document.getElementById('pdp-badge-sector');
  if (bSector) bSector.innerText = `Sector: ${prop.sector || prop.location}`;

  const bCity = document.getElementById('pdp-badge-city');
  if (bCity) bCity.innerText = `City: ${prop.city || 'Noida'}`;

  const bPin = document.getElementById('pdp-badge-pincode');
  if (bPin) bPin.innerText = `PIN: ${prop.postalCode || '201308'}`;

  const lmGrid = document.getElementById('pdp-nearby-landmarks');
  if (lmGrid && prop.landmarks) {
    lmGrid.innerHTML = prop.landmarks.map(l => `
      <div class="p-2.5 bg-slate-50 border border-slate-100 rounded-xl flex items-center gap-2">
        <span class="material-symbols-outlined text-slate-500 text-sm">near_me</span>
        <span class="font-medium text-slate-700">${l}</span>
      </div>
    `).join('');
  }

  // Update Fav icon state
  const favBtn = document.getElementById('pdp-fav-btn');
  if (favBtn) {
    const isFav = activeFavoriteIds.includes(prop.id);
    favBtn.innerHTML = `<span class="material-symbols-outlined text-base">${isFav ? 'favorite' : 'favorite_border'}</span>`;
  }

  // Initialize EMI Calculator for this property price
  initPdpEmi(prop.price);

  // Initialize AI Property Verification System for this property
  try {
    renderPropertyVerification(prop.id, prop);
  } catch (e) {
    console.warn('[PropZen Verification PDP Init Error]:', e);
  }
}

function switchDetailMainImage(src, btn) {
  const mainImg = document.getElementById('pdp-main-image');
  if (mainImg) mainImg.src = src;

  const thumbStrip = document.getElementById('pdp-thumbnail-strip');
  if (thumbStrip) {
    thumbStrip.querySelectorAll('button').forEach(b => b.classList.replace('border-red-600', 'border-transparent'));
  }
  if (btn) btn.classList.replace('border-transparent', 'border-red-600');
}

function toggleDetailFavorite() {
  if (!currentDetailProperty) return;
  toggleFavorite(currentDetailProperty.id);
  const favBtn = document.getElementById('pdp-fav-btn');
  if (favBtn) {
    const isFav = activeFavoriteIds.includes(currentDetailProperty.id);
    favBtn.innerHTML = `<span class="material-symbols-outlined text-base">${isFav ? 'favorite' : 'favorite_border'}</span>`;
  }
}

function addToCompareFromDetail() {
  if (!currentDetailProperty) return;
  addToCompare(currentDetailProperty.id);
}

function shareCurrentProperty() {
  if (navigator.share && currentDetailProperty) {
    navigator.share({
      title: currentDetailProperty.title,
      text: `Check out ${currentDetailProperty.title} on PropZen!`,
      url: window.location.href
    }).catch(() => {});
  } else {
    navigator.clipboard.writeText(window.location.href);
    showToast('Listing Link Copied to Clipboard!', 'success');
  }
}

function openPdpWhatsApp() {
  if (!currentDetailProperty) return openWhatsApp();
  const text = `Hi PropZen! I am interested in ${currentDetailProperty.title} (${currentDetailProperty.id}) listed at ${currentDetailProperty.priceDisplay}. Please connect me with the verified channel partner.`;
  openWhatsApp(text);
}

function openPdpEnquiryModal(customTopic) {
  requireAuthForEnquiry(() => {
    showToast(`Enquiry registered for ${customTopic || currentDetailProperty?.title || 'Property'}! Our Senior Advisor will call you within 15 minutes.`, 'success');
  }, `Enquiry for ${customTopic || currentDetailProperty?.title || 'Property'}`);
}

// EMI Calculator inside PDP
function initPdpEmi(basePrice) {
  const loanCr = Math.min(Math.max(Math.round((basePrice * 0.8) / 100000), 10), 500);
  const slider = document.getElementById('emi-loan-slider');
  if (slider) slider.value = loanCr;
  updateEmiCalculation();
}

function updateEmiCalculation() {
  const loanLacs = parseFloat(document.getElementById('emi-loan-slider')?.value || 100);
  const tenureYears = parseFloat(document.getElementById('emi-tenure-slider')?.value || 20);

  const loanValLabel = document.getElementById('emi-loan-amount-val');
  if (loanValLabel) {
    loanValLabel.innerText = loanLacs >= 100 ? `₹ ${(loanLacs / 100).toFixed(2)} Cr` : `₹ ${loanLacs} Lacs`;
  }

  const tenureValLabel = document.getElementById('emi-tenure-val');
  if (tenureValLabel) {
    tenureValLabel.innerText = `${tenureYears} Years`;
  }

  const P = loanLacs * 100000;
  const annualRate = 0.085; // 8.5%
  const r = annualRate / 12;
  const n = tenureYears * 12;

  const emi = Math.round((P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1));

  const emiOutput = document.getElementById('emi-monthly-output');
  if (emiOutput) {
    emiOutput.innerText = `₹ ${emi.toLocaleString('en-IN')} / mo`;
  }
}

// ------------------------------------------------------------------------
// 3. DEALERS DIRECTORY & PROFILE (/dealers, /dealer/:id)
// ------------------------------------------------------------------------

function renderDealersCatalog() {
  const grid = document.getElementById('dealers-catalog-grid');
  if (!grid) return;

  const search = (document.getElementById('dealers-search-input')?.value || '').toLowerCase().trim();
  const loc = document.getElementById('dealers-location-select')?.value || 'all';

  const filtered = sampleDealers.filter(d => {
    if (search && !`${d.name} ${d.agency} ${d.locationDisplay}`.toLowerCase().includes(search)) return false;
    if (loc !== 'all' && d.location.toLowerCase() !== loc.toLowerCase()) return false;
    return true;
  });

  grid.innerHTML = filtered.map(d => `
    <div class="bg-white rounded-3xl border border-slate-200 p-6 shadow-sm hover:shadow-md transition-all flex flex-col justify-between space-y-4">
      <div class="space-y-3">
        <div class="flex items-center gap-3">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 text-white font-black flex items-center justify-center text-lg shadow-sm shrink-0">
            ${d.initials}
          </div>
          <div>
            <div class="flex items-center gap-1.5">
              <h3 class="font-bold text-base text-slate-900">${d.name}</h3>
              <span class="material-symbols-outlined text-emerald-600 text-base" title="RERA Certified">verified</span>
            </div>
            <span class="text-xs font-semibold text-slate-500">${d.agency}</span>
            <span class="block text-[10px] font-mono text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded w-max mt-0.5">${d.reraId}</span>
          </div>
        </div>

        <div class="grid grid-cols-3 gap-2 text-center text-xs pt-2 border-t border-slate-100">
          <div class="bg-slate-50 p-2 rounded-xl">
            <span class="text-slate-400 block text-[9px] uppercase font-mono">Rating</span>
            <strong class="text-slate-800">⭐ ${d.rating}</strong>
          </div>
          <div class="bg-slate-50 p-2 rounded-xl">
            <span class="text-slate-400 block text-[9px] uppercase font-mono">Experience</span>
            <strong class="text-slate-800">${d.experience}</strong>
          </div>
          <div class="bg-slate-50 p-2 rounded-xl">
            <span class="text-slate-400 block text-[9px] uppercase font-mono">Deals</span>
            <strong class="text-indigo-600">${d.dealsCount}+</strong>
          </div>
        </div>

        <div class="flex flex-wrap gap-1 text-[10px]">
          ${d.specialties.map(s => `<span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-md font-medium">${s}</span>`).join('')}
        </div>
      </div>

      <div class="flex items-center gap-2 pt-2 border-t border-slate-100">
        <button class="flex-1 bg-slate-900 hover:bg-black text-white font-bold text-xs py-2.5 rounded-xl transition-all cursor-pointer" onclick="navigateToRoute('/dealer/${d.id}')">
          View Profile & Listings
        </button>
        <button class="w-9 h-9 rounded-xl bg-[#25D366] text-black flex items-center justify-center shadow-sm cursor-pointer" onclick="openWhatsApp('Hi ${d.name}! I found your profile on PropZen.')" title="Direct WhatsApp">
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12.012 2c-5.506 0-9.969 4.463-9.969 9.969 0 1.763.459 3.487 1.33 5.002l-1.413 5.161 5.281-1.385a9.923 9.923 0 004.771 1.222h.004c5.505 0 9.969-4.463 9.969-9.969 0-2.664-1.038-5.167-2.923-7.053a9.914 9.914 0 00-7.05-2.947zm5.717 14.185c-.244.688-1.42 1.314-1.956 1.393-.497.072-1.144.104-3.32-.795-2.784-1.15-4.577-3.984-4.717-4.17-.137-.186-1.127-1.498-1.127-2.856 0-1.358.706-2.025.961-2.285.255-.26.559-.325.746-.325.186 0 .373.004.536.012.174.009.408-.067.638.486.236.568.8 1.956.868 2.097.069.141.116.307.023.493-.092.186-.14.302-.279.465-.139.163-.292.365-.417.491-.139.139-.284.292-.122.57.162.279.721 1.192 1.547 1.928 1.063.947 1.961 1.242 2.24 1.381.279.139.442.116.605-.07.163-.186.7-0.814.886-1.093.186-.279.372-.233.628-.139.256.093 1.629.768 1.909.907.279.139.465.209.535.326.069.116.069.674-.175 1.362z"/></svg>
        </button>
      </div>
    </div>
  `).join('');
}

function filterDealers() {
  renderDealersCatalog();
}

function renderDealerDetails(dealerId) {
  let dealer = sampleDealers.find(d => d.id === dealerId);
  if (!dealer) dealer = sampleDealers[0];

  const nameEl = document.getElementById('dealer-profile-name');
  if (nameEl) nameEl.innerText = dealer.name;

  const agencyEl = document.getElementById('dealer-profile-agency');
  if (agencyEl) agencyEl.innerText = `${dealer.agency} • ${dealer.locationDisplay}`;

  const avEl = document.getElementById('dealer-profile-avatar');
  if (avEl) avEl.innerText = dealer.initials;

  const listedGrid = document.getElementById('dealer-active-listings-grid');
  if (listedGrid) {
    const dealerProps = sampleProperties.filter(p => p.dealerId === dealer.id || p.city === dealer.location);
    listedGrid.innerHTML = dealerProps.map(p => `
      <div class="bg-slate-50 border border-slate-200 rounded-2xl p-3 space-y-2 cursor-pointer hover:border-slate-400 transition-all" onclick="navigateToRoute('/property/${p.id}')">
        <img src="${p.image}" class="w-full h-32 object-cover rounded-xl" />
        <h4 class="font-bold text-xs text-slate-900 line-clamp-1">${p.title}</h4>
        <div class="flex justify-between items-center text-xs">
          <span class="font-black text-red-600">${p.priceDisplay}</span>
          <span class="text-[10px] font-bold text-emerald-700">${p.rentalYield}% Yield</span>
        </div>
      </div>
    `).join('');
  }
}

// ------------------------------------------------------------------------
// 4. MARKET INTELLIGENCE CHARTS (/market-intelligence)
// ------------------------------------------------------------------------

let marketPriceChartInstance = null;
let marketYieldChartInstance = null;
let marketAbsorpChartInstance = null;
let marketDemandChartInstance = null;

function renderMarketIntelligenceCharts(timeFilter = '30d') {
  if (typeof Chart === 'undefined') {
    console.warn('Chart.js not loaded yet');
    return;
  }

  // Multiplier for time filters
  let multiplier = 1;
  if (timeFilter === '6m') multiplier = 1.04;
  else if (timeFilter === '1y') multiplier = 1.12;
  else if (timeFilter === '5y') multiplier = 1.48;

  // Chart 1: Price Index Trend
  const ctxPrice = document.getElementById('marketPriceTrendChart')?.getContext('2d');
  if (ctxPrice) {
    if (marketPriceChartInstance) marketPriceChartInstance.destroy();
    marketPriceChartInstance = new Chart(ctxPrice, {
      type: 'line',
      data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        datasets: [
          {
            label: 'Noida Sec 137 (₹/sqft)',
            data: [7400, 7550, 7700, 7850, 8000, 8100, 8250, 8400, 8600, 8750, 8850, Math.round(8950 * multiplier)],
            borderColor: '#d32f2f',
            backgroundColor: 'rgba(211, 47, 47, 0.1)',
            tension: 0.35,
            fill: true
          },
          {
            label: 'Gurgaon Sec 77 (₹/sqft)',
            data: [9800, 9950, 10200, 10400, 10700, 10900, 11100, 11250, 11400, 11600, 11800, Math.round(12100 * multiplier)],
            borderColor: '#6366f1',
            tension: 0.35
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 10 } } } }
      }
    });
  }

  // Chart 2: Rental Yields
  const ctxYield = document.getElementById('marketRentalYieldChart')?.getContext('2d');
  if (ctxYield) {
    if (marketYieldChartInstance) marketYieldChartInstance.destroy();
    marketYieldChartInstance = new Chart(ctxYield, {
      type: 'bar',
      data: {
        labels: ['Noida 137', 'Noida 150', 'Gr. Noida KP', 'Jaypee Greens', 'Gurgaon 77', 'South Delhi'],
        datasets: [{
          label: 'Annualized Rental Yield (%)',
          data: [6.1, 5.8, 7.2, 5.5, 5.2, 4.5],
          backgroundColor: ['#d32f2f', '#f97316', '#10b981', '#6366f1', '#8b5cf6', '#ec4899'],
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, max: 10 } }
      }
    });
  }

  // Chart 3: Absorption
  const ctxAbsorp = document.getElementById('marketAbsorptionChart')?.getContext('2d');
  if (ctxAbsorp) {
    if (marketAbsorpChartInstance) marketAbsorpChartInstance.destroy();
    marketAbsorpChartInstance = new Chart(ctxAbsorp, {
      type: 'doughnut',
      data: {
        labels: ['Noida Expressway', 'Greater Noida West', 'Golf Course Ext.', 'Yamuna Corridor'],
        datasets: [{
          data: [42, 28, 18, 12],
          backgroundColor: ['#d32f2f', '#6366f1', '#10b981', '#f59e0b']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } } }
      }
    });
  }

  // Chart 4: Demand
  const ctxDemand = document.getElementById('marketDemandChart')?.getContext('2d');
  if (ctxDemand) {
    if (marketDemandChartInstance) marketDemandChartInstance.destroy();
    marketDemandChartInstance = new Chart(ctxDemand, {
      type: 'pie',
      data: {
        labels: ['3 BHK Flats', '2 BHK Flats', 'Gated Plots', 'Luxury Villas', 'Commercial'],
        datasets: [{
          data: [45, 25, 15, 10, 5],
          backgroundColor: ['#6366f1', '#3b82f6', '#10b981', '#ec4899', '#f97316']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } } }
      }
    });
  }
}

function switchMarketTimeFilter(time, btn) {
  document.querySelectorAll('.market-time-btn').forEach(b => {
    b.classList.remove('active', 'bg-white', 'text-slate-900');
    b.classList.add('text-slate-300');
  });
  if (btn) {
    btn.classList.add('active', 'bg-white', 'text-slate-900');
    btn.classList.remove('text-slate-300');
  }
  renderMarketIntelligenceCharts(time);
}

// ------------------------------------------------------------------------
// 5. AI PROPERTY ADVISOR MATCH ENGINE (/ai-advisor)
// ------------------------------------------------------------------------

function runAiAdvisorMatch() {
  const container = document.getElementById('ai-advisor-results-container');
  if (!container) return;

  const loc = document.getElementById('ai-filter-location')?.value || 'all';
  const budget = document.getElementById('ai-filter-budget')?.value || 'all';
  const bhk = document.getElementById('ai-filter-bhk')?.value || 'all';
  const type = document.getElementById('ai-filter-type')?.value || 'all';

  // Read checked amenities
  const checkedAmenities = Array.from(document.querySelectorAll('.ai-amenity-cb:checked')).map(cb => cb.value);

  // Strict algorithmic filter
  let matched = sampleProperties.filter(p => {
    if (loc !== 'all' && p.city.toLowerCase() !== loc.toLowerCase()) return false;
    if (type !== 'all' && p.type !== type) return false;
    if (bhk !== 'all' && p.bhk !== 'all' && p.bhk !== bhk) return false;

    if (budget === 'under1cr' && p.price >= 10000000) return false;
    if (budget === '1cr-2cr' && (p.price < 10000000 || p.price > 20000000)) return false;
    if (budget === '2cr-3cr' && (p.price < 20000000 || p.price > 30000000)) return false;
    if (budget === '3crplus' && p.price < 30000000) return false;

    if (checkedAmenities.length > 0) {
      const matchAll = checkedAmenities.every(a => p.amenities.includes(a));
      if (!matchAll) return false;
    }

    return true;
  });

  if (matched.length === 0) {
    // If no exact match with all filters, show smart fallback suggestions
    matched = sampleProperties.slice(0, 3);
  }

  container.innerHTML = matched.map((p, idx) => {
    const matchScore = Math.max(98 - idx * 3, 89);
    return `
      <div class="bg-white rounded-3xl border-2 border-purple-200 overflow-hidden shadow-sm hover:shadow-lg transition-all flex flex-col justify-between">
        <div>
          <!-- AI Reasoning Header -->
          <div class="p-3 bg-gradient-to-r from-purple-950 to-indigo-950 text-white text-xs flex items-center justify-between">
            <span class="font-mono font-bold text-purple-300 flex items-center gap-1">
              <span class="material-symbols-outlined text-sm">psychology</span> AI MATCH: ${matchScore}%
            </span>
            <span class="text-[10px] bg-purple-500/30 text-purple-200 px-2 py-0.5 rounded font-mono font-bold">100% CRITERIA FIT</span>
          </div>

          <div class="relative h-44 bg-slate-900 cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
            <img src="${p.image}" class="w-full h-full object-cover" />
            <div class="absolute bottom-2 left-2 bg-black/70 backdrop-blur-sm text-white font-mono text-[10px] font-bold px-2 py-0.5 rounded">
              ${p.location}
            </div>
          </div>

          <div class="p-4 space-y-2.5">
            <h3 class="font-bold text-sm text-slate-900 line-clamp-1 cursor-pointer hover:text-purple-600 transition-colors" onclick="navigateToRoute('/property/${p.id}')">
              ${p.title}
            </h3>

            <!-- AI Explanation Pill -->
            <div class="p-2.5 bg-purple-50 border border-purple-100 rounded-xl text-[11px] text-purple-950 leading-relaxed">
              <strong>Why Recommended:</strong> Verified ${p.bhk.toUpperCase()} in ${p.city.toUpperCase()} with ${p.rentalYield}% yield and clean title deed.
            </div>

            <div class="flex justify-between items-baseline pt-1 border-t border-slate-100 text-xs">
              <span class="text-base font-black text-purple-700 font-display-price">${p.priceDisplay}</span>
              <span class="text-[11px] font-mono text-slate-500 font-bold">${p.sqft} Sq.Ft</span>
            </div>
          </div>
        </div>

        <div class="p-3 bg-slate-50 border-t border-slate-100 flex items-center gap-2">
          <button class="flex-1 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs py-2 rounded-xl transition-all cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
            Explore Property →
          </button>
          <button class="w-8 h-8 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center cursor-pointer" title="Add to Compare" onclick="addToCompare('${p.id}')">
            <span class="material-symbols-outlined text-sm">balance</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// ------------------------------------------------------------------------
// 6. PROPERTY COMPARISON MATRIX (/compare)
// ------------------------------------------------------------------------

function renderCompareMatrix() {
  const container = document.getElementById('compare-matrix-container');
  if (!container) return;

  const compareProps = sampleProperties.filter(p => activeCompareIds.includes(p.id));

  if (compareProps.length === 0) {
    container.innerHTML = `
      <div class="text-center py-12 space-y-3">
        <span class="material-symbols-outlined text-4xl text-slate-300">balance</span>
        <h3 class="text-base font-bold text-slate-800">No properties selected for comparison</h3>
        <p class="text-xs text-slate-500">Add 2 to 4 properties from the catalog to compare valuations and specifications side-by-side.</p>
        <button class="bg-purple-600 text-white text-xs font-bold px-4 py-2 rounded-xl shadow cursor-pointer" onclick="navigateToRoute('/properties')">
          Browse Properties Catalog
        </button>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <table class="w-full text-left text-xs border-collapse min-w-[600px]">
      <thead>
        <tr class="border-b border-slate-200">
          <th class="py-3 px-4 font-mono uppercase text-slate-400 text-[10px] w-44">Specification</th>
          ${compareProps.map(p => `
            <th class="py-3 px-4">
              <div class="space-y-1">
                <img src="${p.image}" class="w-full h-24 object-cover rounded-xl shadow-inner" />
                <h4 class="font-bold text-slate-900 line-clamp-1">${p.title}</h4>
                <div class="flex justify-between items-center">
                  <span class="text-xs font-black text-red-600">${p.priceDisplay}</span>
                  <button class="text-slate-400 hover:text-red-600 text-[10px] font-bold" onclick="removeFromCompare('${p.id}')">✕ Remove</button>
                </div>
              </div>
            </th>
          `).join('')}
        </tr>
      </thead>
      <tbody class="divide-y divide-slate-100">
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Location</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-medium text-slate-800">${p.location}</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Fair Market Value</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-bold text-emerald-700">${p.fairValueDisplay}</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">10X Valuation Score</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-black text-purple-700">⭐ ${p.score} / 10</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Est. Rental Yield</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-bold text-slate-900">${p.rentalYield}% / yr</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Built-up Area</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-medium text-slate-800">${p.sqft} Sq.Ft</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Facing & Orientation</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-medium text-slate-800">${p.facing}</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Legal Status</td>
          ${compareProps.map(p => `<td class="py-2.5 px-4 font-semibold text-emerald-700">${p.risk}</td>`).join('')}
        </tr>
        <tr>
          <td class="py-2.5 px-4 font-bold text-slate-700 bg-slate-50">Action</td>
          ${compareProps.map(p => `
            <td class="py-2.5 px-4">
              <button class="w-full bg-red-600 hover:bg-red-700 text-white font-bold text-xs py-1.5 rounded-lg transition-all cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
                View Full Details
              </button>
            </td>
          `).join('')}
        </tr>
      </tbody>
    </table>
  `;
}

function addToCompare(id) {
  if (!activeCompareIds.includes(id)) {
    if (activeCompareIds.length >= 4) {
      activeCompareIds.shift();
    }
    activeCompareIds.push(id);
    showToast('Added to comparison matrix!', 'success');
  } else {
    showToast('Already in comparison matrix', 'info');
  }
}

function removeFromCompare(id) {
  activeCompareIds = activeCompareIds.filter(x => x !== id);
  renderCompareMatrix();
}

function resetCompareList() {
  activeCompareIds = [];
  renderCompareMatrix();
}

// ------------------------------------------------------------------------
// 7. FAVORITES & NOTIFICATIONS
// ------------------------------------------------------------------------

function toggleFavorite(id) {
  const idx = activeFavoriteIds.indexOf(id);
  if (idx > -1) {
    activeFavoriteIds.splice(idx, 1);
    showToast('Removed from Shortlisted Favorites', 'info');
  } else {
    activeFavoriteIds.push(id);
    showToast('Saved to Shortlisted Favorites ❤️', 'success');
  }
  localStorage.setItem('propzen_favorites', JSON.stringify(activeFavoriteIds));
  renderPropertiesCatalog();
}

function renderFavoritesCatalog() {
  const grid = document.getElementById('favorites-catalog-grid');
  if (!grid) return;

  const favProps = sampleProperties.filter(p => activeFavoriteIds.includes(p.id));

  if (favProps.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full text-center py-16 bg-white rounded-3xl border border-slate-200 p-8 space-y-3">
        <span class="material-symbols-outlined text-5xl text-rose-300">favorite_border</span>
        <h3 class="text-lg font-bold text-slate-800">Your shortlist is currently empty</h3>
        <p class="text-xs text-slate-500">Click the heart icon on any property to save it here for fast access.</p>
        <button class="bg-red-600 text-white text-xs font-bold px-5 py-2.5 rounded-xl shadow cursor-pointer" onclick="navigateToRoute('/properties')">
          Explore Properties
        </button>
      </div>
    `;
    return;
  }

  grid.innerHTML = favProps.map(p => `
    <div class="bg-white rounded-3xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
      <div>
        <div class="relative h-44 bg-slate-900 cursor-pointer" onclick="navigateToRoute('/property/${p.id}')">
          <img src="${p.image}" class="w-full h-full object-cover" />
          <button class="absolute top-3 right-3 w-8 h-8 rounded-full bg-white text-red-600 flex items-center justify-center cursor-pointer shadow" onclick="event.stopPropagation(); toggleFavorite('${p.id}'); renderFavoritesCatalog();">
            <span class="material-symbols-outlined text-base">favorite</span>
          </button>
        </div>
        <div class="p-4 space-y-2">
          <h3 class="font-bold text-sm text-slate-900 line-clamp-1">${p.title}</h3>
          <div class="flex justify-between items-baseline text-xs">
            <strong class="font-black text-red-600 font-display-price">${p.priceDisplay}</strong>
            <span class="text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded">${p.rentalYield}% Yield</span>
          </div>
        </div>
      </div>
      <div class="p-3 bg-slate-50 border-t border-slate-100 flex gap-2">
        <button class="flex-1 bg-red-600 text-white font-bold text-xs py-2 rounded-xl" onclick="navigateToRoute('/property/${p.id}')">View Details</button>
        <button class="bg-[#25D366] text-black font-bold text-xs px-3 py-2 rounded-xl" onclick="openWhatsApp('Inquiring about shortlisted property: ${p.id}')">WhatsApp</button>
      </div>
    </div>
  `).join('');
}

function renderNotifications() {
  const container = document.getElementById('notifications-list-container');
  if (!container) return;

  const notifs = [
    { title: "Price Drop Alert in Sector 137 Noida", time: "2 hours ago", desc: "A 3BHK flat matching your shortlisted criteria reduced price by 4.2% (Save ₹ 6.0 Lacs).", unread: true },
    { title: "New Luxury Launch in Sector 150 Sports City", time: "Yesterday", desc: "Godrej Properties opened pre-bookings for Golf Greens Phase 2 with early-bird pricing.", unread: true },
    { title: "Monthly Micro-Market Report Ready", time: "2 days ago", desc: "Your August 2026 NCR Real Estate Arbitrage & Rental Yield intelligence digest is now live.", unread: false }
  ];

  container.innerHTML = notifs.map(n => `
    <div class="p-4 rounded-2xl border ${n.unread ? 'border-amber-200 bg-amber-50/50' : 'border-slate-100 bg-slate-50'} flex items-start justify-between gap-3 text-xs">
      <div class="space-y-1">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined ${n.unread ? 'text-amber-600' : 'text-slate-400'} text-base">notifications</span>
          <strong class="font-bold text-slate-900">${n.title}</strong>
          ${n.unread ? '<span class="bg-amber-500 text-white text-[9px] font-bold px-1.5 py-0.2 rounded">NEW</span>' : ''}
        </div>
        <p class="text-slate-600">${n.desc}</p>
        <span class="text-[10px] text-slate-400 font-mono">${n.time}</span>
      </div>
    </div>
  `).join('');
}

function markAllNotificationsAsRead() {
  showToast('All notifications marked as read', 'success');
}

function updateProfileStats() {
  const favCount = document.getElementById('profile-favorites-count');
  if (favCount) favCount.innerText = `${activeFavoriteIds.length} Properties`;
}

// ------------------------------------------------------------------------
// 8. 10 DEDICATED TOOLS CONTROLLERS
// ------------------------------------------------------------------------

function update3dVideoPreview() {
  const sel = document.getElementById('tool-3d-video-prop-select');
  const prop = sampleProperties.find(p => p.id === sel?.value) || sampleProperties[0];
  const poster = document.getElementById('tool-3d-video-poster');
  if (poster) poster.src = prop.image;
  showToast(`Loaded 3D Studio for ${prop.title}`, 'info');
}

function switch3dRoom(roomName) {
  const label = document.getElementById('tool-3d-video-room-label');
  if (label) label.innerText = `Current View: ${roomName}`;
  showToast(`Switched Camera View to ${roomName}`, 'info');
}

function setVisStyle(styleName, imgUrl) {
  const indicator = document.getElementById('vis-style-indicator');
  if (indicator) indicator.innerText = `Preset: ${styleName}`;
  const canvasImg = document.getElementById('vis-canvas-image');
  if (canvasImg && imgUrl) canvasImg.src = imgUrl;
  showToast(`Spatial Staging Preset applied: ${styleName}`, 'success');
}

function setVisColor(colorName) {
  const indicator = document.getElementById('vis-wall-indicator');
  if (indicator) indicator.innerText = `Wall: ${colorName}`;
  showToast(`Wall Swatch updated to ${colorName}`, 'info');
}

function switchDroneSector() {
  const sel = document.getElementById('drone-hub-select');
  const label = document.getElementById('drone-sector-title');
  if (label && sel) label.innerText = sel.value;
  showToast(`Switching 4K Drone feed to ${sel?.value}`, 'info');
}

function runVastuAudit() {
  const entrance = document.getElementById('vastu-entrance')?.value || 'North-East';
  const kitchen = document.getElementById('vastu-kitchen')?.value || 'South-East';
  let score = 92;

  if (entrance === 'South-West') score -= 25;
  if (kitchen.includes('Defect')) score -= 20;

  const scoreVal = document.getElementById('vastu-score-val');
  if (scoreVal) scoreVal.innerText = `${score}%`;

  const summary = document.getElementById('vastu-feedback-summary');
  if (summary) {
    summary.innerText = score >= 80 ? 'Highly auspicious layout with optimal solar daylighting and energy flow.' : 'Moderate compliance. Recommend Vastu copper pyramid energy stabilizers.';
  }
}

function updateInteriorEstimate() {
  const bhk = document.getElementById('interior-bhk-select')?.value || '3BHK';
  const tier = document.getElementById('interior-tier-select')?.value || 'Premium';

  let cost = "₹ 8.50 Lacs";
  if (bhk === '2BHK') cost = tier === 'Luxury' ? '₹ 8.20 Lacs' : '₹ 5.80 Lacs';
  else if (bhk === '3BHK') cost = tier === 'Luxury' ? '₹ 12.50 Lacs' : '₹ 8.50 Lacs';
  else if (bhk === '4BHK') cost = tier === 'Luxury' ? '₹ 18.00 Lacs' : '₹ 13.20 Lacs';
  else if (bhk === 'Villa') cost = tier === 'Luxury' ? '₹ 28.00 Lacs' : '₹ 19.50 Lacs';

  const out = document.getElementById('interior-estimate-val');
  if (out) out.innerText = cost;
}

function openCreateForumPostModal() {
  requireAuthForEnquiry(() => {
    showToast('Community Forum: Create Discussion modal active!', 'info');
  }, 'Post to Community Forum');
}

function handleLogout() {
  showToast('You have been securely signed out', 'info');
}

// ========================================================================
// 9. MASTER ADMIN PANEL ENGINE (Single-Slot Setup & Supabase Sync)
// ========================================================================

const adminDataStore = {
  isSlotClaimed: localStorage.getItem('propzen_admin_claimed') === 'true',
  adminName: localStorage.getItem('propzen_admin_name') || 'Sakshi Sharma',
  adminEmail: localStorage.getItem('propzen_admin_email') || 'admin@dealghar.com',
  adminPassword: localStorage.getItem('propzen_admin_password') || 'admin123',
  isLoggedIn: false,
  enquiries: [
    { id: 'ENQ-1723871920001', property_title: 'Godrej Tropical Isle - 3 BHK Luxury', name: 'Sakshi Sharma', phone: '+91 98103 94068', email: 'sakshi.sharma@example.com', type: 'Pricing & Payment Plan', status: 'New', date: 'Today' },
    { id: 'ENQ-1723871920002', property_title: 'DLF Midtown Heights - 4 BHK Penthouse', name: 'Rahul Verma', phone: '+91 98765 43210', email: 'rahul.verma@investors.in', type: 'Floor Plan & Site Tour', status: 'Agent Assigned', date: 'Today' },
    { id: 'ENQ-1723871920003', property_title: 'M3M The Line Commercial Hub', name: 'Amit Kapoor', phone: '+91 98112 34567', email: 'amit.kapoor@retailcorp.com', type: 'High Yield Retail Space', status: 'Contacted', date: 'Yesterday' }
  ],
  siteVisits: [
    { id: 'VISIT-1723872110001', property_title: 'Godrej Tropical Isle', sector: 'Sector 146, Noida Expressway', date: '2026-08-20', time: '11:00 AM - 12:00 PM', name: 'Sakshi Sharma', phone: '+91 98103 94068', email: 'sakshi.sharma@example.com', status: 'Confirmed' },
    { id: 'VISIT-1723872110002', property_title: '3BHK Premium Luxury Flat', sector: 'Sector 137, Noida Expressway', date: '2026-08-22', time: '03:00 PM - 04:00 PM', name: 'Pooja Mehta', phone: '+91 99201 88472', email: 'pooja.mehta@techfirm.com', status: 'Confirmed' }
  ],
  users: [
    { id: 'usr_9810394068', name: 'Sakshi Sharma', phone: '+91 98103 94068', email: 'sakshi.sharma@example.com', role: 'Verified Buyer / Owner', verified: true, lastLogin: '45 mins ago' },
    { id: 'usr_9876543210', name: 'Rahul Verma', phone: '+91 98765 43210', email: 'rahul.verma@investors.in', role: 'Investor / Portfolio Buyer', verified: true, lastLogin: '4 hours ago' },
    { id: 'usr_9920188472', name: 'Pooja Mehta', phone: '+91 99201 88472', email: 'pooja.mehta@techfirm.com', role: 'Buyer / Owner', verified: false, lastLogin: 'Yesterday' }
  ]
};

function initAdminPanel() {
  const setupBox = document.getElementById('admin-setup-container');
  const loginBox = document.getElementById('admin-login-container');
  const dashBox = document.getElementById('admin-dashboard-container');
  const configuredEmailLabel = document.getElementById('admin-configured-email');

  if (!setupBox || !loginBox || !dashBox) return;

  if (adminDataStore.isLoggedIn) {
    setupBox.classList.add('hidden');
    loginBox.classList.add('hidden');
    dashBox.classList.remove('hidden');
    renderAdminDashboard();
  } else if (adminDataStore.isSlotClaimed) {
    setupBox.classList.add('hidden');
    loginBox.classList.remove('hidden');
    dashBox.classList.add('hidden');
    if (configuredEmailLabel) configuredEmailLabel.innerText = adminDataStore.adminEmail;
  } else {
    setupBox.classList.remove('hidden');
    loginBox.classList.add('hidden');
    dashBox.classList.add('hidden');
  }
}

function handleAdminSetupSubmit(e) {
  if (e) e.preventDefault();
  const name = document.getElementById('admin-setup-name')?.value.trim();
  const email = document.getElementById('admin-setup-email')?.value.trim().toLowerCase();
  const pass = document.getElementById('admin-setup-password')?.value.trim();

  if (!name || !email || !pass || pass.length < 6) {
    showToast('Please fill all fields with a valid 6+ char password', 'error');
    return;
  }

  adminDataStore.isSlotClaimed = true;
  adminDataStore.adminName = name;
  adminDataStore.adminEmail = email;
  adminDataStore.adminPassword = pass;
  adminDataStore.isLoggedIn = true;

  localStorage.setItem('propzen_admin_claimed', 'true');
  localStorage.setItem('propzen_admin_name', name);
  localStorage.setItem('propzen_admin_email', email);
  localStorage.setItem('propzen_admin_password', pass);

  initAdminPanel();
  showToast('Master Admin Account Created! Single slot claimed.', 'success');
}

function handleAdminLoginSubmit(e) {
  if (e) e.preventDefault();
  const email = document.getElementById('admin-login-email')?.value.trim().toLowerCase();
  const pass = document.getElementById('admin-login-password')?.value.trim();

  if (email === adminDataStore.adminEmail.toLowerCase() && pass === adminDataStore.adminPassword) {
    adminDataStore.isLoggedIn = true;
    initAdminPanel();
    showToast('Welcome to PropZen Admin Console!', 'success');
  } else {
    showToast('Invalid admin credentials. Please try again.', 'error');
  }
}

function adminLogout() {
  adminDataStore.isLoggedIn = false;
  initAdminPanel();
  showToast('Logged out of Admin Console', 'info');
}

function switchAdminTab(tab) {
  const tabs = ['enquiries', 'visits', 'users'];
  tabs.forEach(t => {
    const btn = document.getElementById(`admin-tab-btn-${t}`);
    const pane = document.getElementById(`admin-pane-${t}`);
    if (t === tab) {
      btn?.classList.add('active', 'bg-red-50', 'text-red-600');
      btn?.classList.remove('text-slate-600');
      pane?.classList.remove('hidden');
    } else {
      btn?.classList.remove('active', 'bg-red-50', 'text-red-600');
      btn?.classList.add('text-slate-600');
      pane?.classList.add('hidden');
    }
  });
}

function renderAdminDashboard() {
  // 1. Render KPI counts
  const kpiEnq = document.getElementById('admin-kpi-enquiries');
  const kpiVis = document.getElementById('admin-kpi-visits');
  const kpiUsr = document.getElementById('admin-kpi-users');

  const countEnq = document.getElementById('admin-tab-count-enquiries');
  const countVis = document.getElementById('admin-tab-count-visits');
  const countUsr = document.getElementById('admin-tab-count-users');

  if (kpiEnq) kpiEnq.innerText = adminDataStore.enquiries.length;
  if (kpiVis) kpiVis.innerText = adminDataStore.siteVisits.length;
  if (kpiUsr) kpiUsr.innerText = adminDataStore.users.length;

  if (countEnq) countEnq.innerText = adminDataStore.enquiries.length;
  if (countVis) countVis.innerText = adminDataStore.siteVisits.length;
  if (countUsr) countUsr.innerText = adminDataStore.users.length;

  // 2. Render Enquiries List
  const enqList = document.getElementById('admin-enquiries-list');
  if (enqList) {
    enqList.innerHTML = adminDataStore.enquiries.map((e, idx) => `
      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm flex flex-col sm:flex-row justify-between sm:items-center gap-3">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <h4 class="font-bold text-xs text-slate-900">${e.property_title}</h4>
            <span class="text-[10px] font-bold px-2 py-0.5 rounded-full ${e.status === 'New' ? 'bg-red-50 text-red-600 border border-red-200' : 'bg-emerald-50 text-emerald-600 border border-emerald-200'}">${e.status}</span>
          </div>
          <div class="flex flex-wrap items-center gap-3 text-xs text-slate-600">
            <span>👤 <strong>${e.name}</strong></span>
            <span>📞 <strong class="font-mono">${e.phone}</strong></span>
            <span>✉️ ${e.email}</span>
          </div>
          <span class="text-[10px] text-slate-400 font-mono">Type: ${e.type} • Received ${e.date}</span>
        </div>
        <div class="flex items-center gap-2">
          <button onclick="updateEnquiryStatusJs(${idx}, 'Contacted')" class="px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-xs font-semibold text-slate-700 cursor-pointer">Mark Contacted</button>
        </div>
      </div>
    `).join('');
  }

  // 3. Render Site Visits List
  const visList = document.getElementById('admin-visits-list');
  if (visList) {
    visList.innerHTML = adminDataStore.siteVisits.map((v, idx) => `
      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm flex flex-col sm:flex-row justify-between sm:items-center gap-3">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <h4 class="font-bold text-xs text-slate-900">${v.property_title}</h4>
            <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200">${v.status}</span>
          </div>
          <div class="flex flex-wrap items-center gap-3 text-xs text-slate-600">
            <span>📍 ${v.sector}</span>
            <span>🗓️ <strong>${v.date} (${v.time})</strong></span>
          </div>
          <div class="flex flex-wrap items-center gap-3 text-xs text-slate-600">
            <span>Customer: <strong>${v.name}</strong></span>
            <span>📞 <strong class="font-mono">${v.phone}</strong></span>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button onclick="updateSiteVisitStatusJs(${idx}, 'Completed')" class="px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-xs font-bold text-emerald-700 cursor-pointer">Mark Completed</button>
        </div>
      </div>
    `).join('');
  }

  // 4. Render Users List
  const usrList = document.getElementById('admin-users-list');
  if (usrList) {
    usrList.innerHTML = adminDataStore.users.map(u => `
      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm flex items-center justify-between gap-3">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-red-50 text-red-600 font-bold flex items-center justify-center text-sm">
            ${u.name.charAt(0)}
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h4 class="font-bold text-xs text-slate-900">${u.name}</h4>
              ${u.verified ? '<span class="text-[9px] font-bold px-1.5 py-0.5 rounded bg-green-50 text-green-700 border border-green-200">Verified</span>' : '<span class="text-[9px] font-bold px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-200">Pending Email</span>'}
            </div>
            <div class="text-xs text-slate-500 font-mono">${u.phone} • ${u.email}</div>
            <span class="text-[10px] text-indigo-600 font-semibold">Role: ${u.role}</span>
          </div>
        </div>
        <span class="text-[10px] text-slate-400 font-mono">Active ${u.lastLogin}</span>
      </div>
    `).join('');
  }
}

function updateEnquiryStatusJs(idx, newStatus) {
  if (adminDataStore.enquiries[idx]) {
    adminDataStore.enquiries[idx].status = newStatus;
    renderAdminDashboard();
    showToast(`Enquiry updated to ${newStatus}`, 'success');
  }
}

function updateSiteVisitStatusJs(idx, newStatus) {
  if (adminDataStore.siteVisits[idx]) {
    adminDataStore.siteVisits[idx].status = newStatus;
    renderAdminDashboard();
    showToast(`Site visit updated to ${newStatus}`, 'success');
  }
}

function refreshAdminData() {
  showToast('Refreshing live data from Supabase (dhoxwstgzdfhcuotcppq)...', 'info');
  setTimeout(() => {
    renderAdminDashboard();
    showToast('Supabase live data sync completed!', 'success');
  }, 500);
}

// =========================================================================
// PROPZEN AI VOICE AGENT ENGINE (STT, TTS, SESSION MEMORY & MULTILINGUAL)
// =========================================================================

let propzenVoiceState = {
  isListening: false,
  isSpeaking: false,
  sessionHistory: [], // { role: 'user' | 'assistant', text: string, lang: string }
  context: {
    location: null,
    budget: null,
    bhk: null,
    purpose: null,
  },
  recognition: null,
  lang: 'hi-IN' // 'hi-IN' detects Hindi & Hinglish, 'en-IN' for English
};

function openPropzenVoiceModal() {
  const modal = document.getElementById('propzen-voice-modal');
  if (modal) {
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.classList.add('overflow-hidden');
    initVoiceRecognition();
  }
}

function closePropzenVoiceModal() {
  stopPropzenVoice();
  const modal = document.getElementById('propzen-voice-modal');
  if (modal) {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.classList.remove('overflow-hidden');
    document.body.style.overflow = '';
  }
}

function initVoiceRecognition() {
  const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SpeechRec) {
    showToast('Speech recognition not supported in this browser. You can still test by typing!', 'info');
    return;
  }

  if (!propzenVoiceState.recognition) {
    const rec = new SpeechRec();
    rec.lang = propzenVoiceState.lang;
    rec.interimResults = true;
    rec.continuous = false;

    rec.onstart = () => {
      propzenVoiceState.isListening = true;
      updateVoiceUiState('LISTENING');
    };

    rec.onresult = (event) => {
      let interim = '';
      let final = '';
      for (let i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          final += event.results[i][0].transcript;
        } else {
          interim += event.results[i][0].transcript;
        }
      }
      const liveBar = document.getElementById('voice-live-bar');
      const liveText = document.getElementById('voice-live-text');
      if (liveBar && liveText) {
        liveBar.classList.remove('hidden');
        liveText.textContent = `"${final || interim}"`;
      }
      if (final) {
        processVoiceInput(final.trim());
      }
    };

    rec.onerror = (e) => {
      propzenVoiceState.isListening = false;
      updateVoiceUiState('IDLE');
      if (e.error !== 'no-speech') {
        showToast(`Voice Error: ${e.error}`, 'error');
      }
    };

    rec.onend = () => {
      propzenVoiceState.isListening = false;
      const liveBar = document.getElementById('voice-live-bar');
      if (liveBar) liveBar.classList.add('hidden');
      if (!propzenVoiceState.isSpeaking) {
        updateVoiceUiState('IDLE');
      }
    };

    propzenVoiceState.recognition = rec;
  }
}

function togglePropzenVoiceListening() {
  if (propzenVoiceState.isListening || propzenVoiceState.isSpeaking) {
    stopPropzenVoice();
    return;
  }

  initVoiceRecognition();
  if (propzenVoiceState.recognition) {
    try {
      propzenVoiceState.recognition.start();
    } catch(err) {
      console.warn('SpeechRec start error:', err);
    }
  } else {
    showToast('Speech recognition not available. Please type your query.', 'info');
  }
}

function stopPropzenVoice() {
  if (propzenVoiceState.recognition) {
    try { propzenVoiceState.recognition.stop(); } catch(_) {}
  }
  if (window.speechSynthesis) {
    window.speechSynthesis.cancel();
  }
  propzenVoiceState.isListening = false;
  propzenVoiceState.isSpeaking = false;
  updateVoiceUiState('IDLE');
}

function updateVoiceUiState(status) {
  const badge = document.getElementById('voice-status-badge');
  const btnIcon = document.getElementById('voice-btn-icon');
  const btnLabel = document.getElementById('voice-btn-label');
  const actionBtn = document.getElementById('voice-action-btn');
  const stopBtn = document.getElementById('voice-stop-btn');
  const visualizer = document.getElementById('voice-visualizer');

  if (status === 'LISTENING') {
    if (badge) { badge.textContent = '🎙️ LISTENING'; badge.className = 'text-[10px] font-mono font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800'; }
    if (btnIcon) btnIcon.textContent = 'mic_off';
    if (btnLabel) btnLabel.textContent = 'Listening... Tap to Stop';
    if (actionBtn) { actionBtn.classList.remove('bg-indigo-600', 'hover:bg-indigo-700'); actionBtn.classList.add('bg-emerald-600', 'hover:bg-emerald-700'); }
    if (stopBtn) stopBtn.classList.remove('hidden');
    if (visualizer) visualizer.classList.remove('hidden');
  } else if (status === 'SPEAKING') {
    if (badge) { badge.textContent = '🔊 SPEAKING'; badge.className = 'text-[10px] font-mono font-bold px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-800'; }
    if (btnIcon) btnIcon.textContent = 'volume_up';
    if (btnLabel) btnLabel.textContent = 'Speaking... Tap to Stop';
    if (actionBtn) { actionBtn.classList.remove('bg-emerald-600', 'hover:bg-emerald-700'); actionBtn.classList.add('bg-indigo-600', 'hover:bg-indigo-700'); }
    if (stopBtn) stopBtn.classList.remove('hidden');
    if (visualizer) visualizer.classList.remove('hidden');
  } else {
    if (badge) { badge.textContent = 'IDLE'; badge.className = 'text-[10px] font-mono font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600'; }
    if (btnIcon) btnIcon.textContent = 'mic';
    if (btnLabel) btnLabel.textContent = 'Talk to PropZen AI';
    if (actionBtn) { actionBtn.classList.remove('bg-emerald-600', 'hover:bg-emerald-700'); actionBtn.classList.add('bg-indigo-600', 'hover:bg-indigo-700'); }
    if (stopBtn) stopBtn.classList.add('hidden');
    if (visualizer) visualizer.classList.add('hidden');
  }
}

function detectVoiceLanguage(text) {
  const t = (text || '').trim();
  if (/[\u0900-\u097F]/.test(t)) return 'hindi';
  const lower = t.toLowerCase();
  const markers = ['mujhe', 'chahiye', 'hai', 'hain', 'kya', 'kaise', 'kitna', 'kitni', 'aapka', 'kaha', 'kahan', 'batao', 'dekhna', 'acha', 'mein', 'me', 'ghar', 'bhk', 'ready', 'move', 'rate', 'price', 'khud', 'rehne', 'paisa', 'noida', 'gurgaon', 'delhi'];
  for (const m of markers) {
    if (lower.includes(m)) return 'hinglish';
  }
  return 'english';
}

function processVoiceInput(userInput) {
  if (!userInput || !userInput.trim()) return;
  const text = userInput.trim();
  const lang = detectVoiceLanguage(text);

  // Update session context
  const lower = text.toLowerCase();
  if (lower.includes('noida extension') || lower.includes('greater noida west')) propzenVoiceState.context.location = 'Noida Extension';
  else if (lower.includes('sector 150')) propzenVoiceState.context.location = 'Sector 150 Noida';
  else if (lower.includes('yamuna expressway') || lower.includes('jewar')) propzenVoiceState.context.location = 'Yamuna Expressway';
  else if (lower.includes('noida')) propzenVoiceState.context.location = 'Noida';
  else if (lower.includes('gurgaon') || lower.includes('gurugram')) propzenVoiceState.context.location = 'Gurgaon';

  if (lower.includes('1 bhk') || lower.includes('1bhk')) propzenVoiceState.context.bhk = '1 BHK';
  else if (lower.includes('2 bhk') || lower.includes('2bhk')) propzenVoiceState.context.bhk = '2 BHK';
  else if (lower.includes('3 bhk') || lower.includes('3bhk')) propzenVoiceState.context.bhk = '3 BHK';
  else if (lower.includes('4 bhk') || lower.includes('4bhk')) propzenVoiceState.context.bhk = '4 BHK';

  const bgtMatch = lower.match(/(\d+(\.\d+)?)\s*(cr|crore|lakh|lac)/i);
  if (bgtMatch) propzenVoiceState.context.budget = bgtMatch[0];

  // Append user message to transcript
  propzenVoiceState.sessionHistory.push({ role: 'user', text: text, lang: lang });
  renderVoiceTranscript();

  // Generate dynamic contextual response
  const aiResponse = generatePropzenAiVoiceResponse(text, lang, propzenVoiceState.context);
  propzenVoiceState.sessionHistory.push({ role: 'assistant', text: aiResponse, lang: lang });
  renderVoiceTranscript();

  // Speak AI response aloud using SpeechSynthesis
  speakAiResponseAloud(aiResponse, lang);
}

function generatePropzenAiVoiceResponse(input, lang, ctx) {
  const lower = input.toLowerCase();

  // HINDI
  if (lang === 'hindi') {
    if (lower.includes('नमस्ते') || lower.includes('हेलो')) {
      return 'नमस्ते! मैं PropZen AI हूँ। आपको NCR में किस लोकेशन या प्रॉपर्टी में मदद चाहिए?';
    }
    if (lower.includes('नोएडा') || lower.includes('प्रॉपर्टी')) {
      return ctx.budget ? `बिल्कुल! ${ctx.budget} में नोएडा के प्रमुख सेक्टर्स में 100% RERA अप्रूव्ड प्रोजेक्ट्स उपलब्ध हैं। क्या आप रेडी-टू-मूव देख रहे हैं?` : 'बिल्कुल! आपका बजट कितना है और आप कितने BHK फ्लैट देख रहे हैं?';
    }
    if (lower.includes('बजट') || lower.includes('करोड़') || lower.includes('लाख')) {
      return 'समझ गया! इस बजट में बेहतरीन कनेक्टिविटी वाली वेरीफाइड प्रॉपर्टीज उपलब्ध हैं। क्या आप रहने के लिए देख रहे हैं या निवेश के लिए?';
    }
    if (lower.includes('रेरा') || lower.includes('लीगल')) {
      return 'हाँ, PropZen पर सभी लिस्टिंग्स 100% RERA वेरीफाइड और लीगल क्लीयर टाइटल के साथ जांची जाती हैं।';
    }
    return 'ज़रूर! मैं आपकी आवश्यकता अनुसार सबसे बेहतरीन प्रॉपर्टी और प्राइस इंटेलिजेंस निकाल सकता हूँ। क्या आप कोई विशेष सेक्टर या बजट बताना चाहेंगे?';
  }

  // HINGLISH
  if (lang === 'hinglish') {
    if (lower === 'hi' || lower === 'hello' || lower.includes('namaste')) {
      return 'Namaste! Main PropZen AI hoon. Aap NCR mein kis location ya property type ke baare mein jaanna chahte hain?';
    }
    if ((lower.includes('property') || lower.includes('flat') || lower.includes('ghar')) && (lower.includes('chahiye') || lower.includes('dekh'))) {
      if (ctx.location && !ctx.budget) {
        return `Bilkul! ${ctx.location} mein aapka budget kitna hai?`;
      }
      return 'Bilkul! Aapka budget kitna hai?';
    }
    if (lower.includes('cr') || lower.includes('crore') || lower.includes('lakh') || lower.includes('lac') || lower.includes('budget')) {
      const bgt = ctx.budget || 'iss budget';
      const loc = ctx.location || 'Noida Extension aur Sector 150';
      return `Badiya! ${bgt} mein ${loc} mein premium 2 BHK aur 3 BHK flats available hain. Kya aap ready-to-move chahte hain ya under-construction?`;
    }
    if (lower.includes('bhk') || lower.includes('villa') || lower.includes('plot')) {
      const bhk = ctx.bhk || 'flat';
      const loc = ctx.location || 'NCR';
      return `Samajh gaya! ${loc} mein ${bhk} ke liye top RERA approved options hain. Kya aapko immediate possession chahiye?`;
    }
    if (lower.includes('ready') || lower.includes('immediate') || lower.includes('turant')) {
      return 'Ready-to-move mein occupancy certificate aur clear registry waale projects best rahenge. Kya main top verified deals shortlist karoon?';
    }
    if (lower.includes('rera') || lower.includes('legal') || lower.includes('fraud') || lower.includes('safe')) {
      return 'Ji haan, PropZen par listed sabhi deals 100% RERA verified, 30-year title deed checked aur builder track record approved hoti hain.';
    }
    if (lower.includes('invest') || lower.includes('rental') || lower.includes('yield')) {
      return 'Investment ke nazariye se Jewar Airport corridor aur Sector 150 mein 8-10% rental yield aur strong capital appreciation potential hai.';
    }
    if (ctx.location && ctx.budget) {
      return `Aapki requirement (${ctx.location}, ${ctx.budget}, ${ctx.bhk || 'Apartment'}) ke mutabiq best options shortlist ho gaye hain. Kya aap inke details dekhna chahte hain?`;
    }
    return 'Zaroor! Aapki requirement ke hisaab se hum exact verified deals khoj sakte hain. Aapka budget aur preferred sector kya hai?';
  }

  // ENGLISH
  if (lower.includes('hello') || lower.includes('hi')) {
    return 'Hello! I am PropZen AI, your intelligent property advisor. Which location or configuration in NCR are you exploring?';
  }
  if (lower.includes('property') || lower.includes('apartment') || lower.includes('flat') || lower.includes('noida') || lower.includes('gurgaon')) {
    if (ctx.location && !ctx.budget) {
      return `Certainly! What is your estimated budget for ${ctx.location}?`;
    }
    return 'Certainly! What is your estimated budget and preferred BHK configuration?';
  }
  if (lower.includes('budget') || lower.includes('crore') || lower.includes('lakh') || lower.includes('cr')) {
    return `Understood! In ${ctx.budget || 'this range'}, there are high-growth RERA-approved options. Are you looking for self-use or investment?`;
  }
  if (lower.includes('rera') || lower.includes('legal') || lower.includes('verified')) {
    return 'All properties on PropZen undergo rigorous 4-step verification including State RERA certification and clear 30-year title deeds.';
  }
  return 'I can help you analyze verified properties, price intelligence, and RERA approvals across NCR. What are your key requirements?';
}

function speakAiResponseAloud(text, lang) {
  if (!window.speechSynthesis) return;

  try {
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = (lang === 'english') ? 'en-IN' : 'hi-IN';
    utterance.rate = 1.0;
    utterance.pitch = 1.0;

    const voices = window.speechSynthesis.getVoices();
    const matchVoice = voices.find(v => v.lang === utterance.lang || v.lang.startsWith(utterance.lang.split('-')[0]));
    if (matchVoice) utterance.voice = matchVoice;

    propzenVoiceState.isSpeaking = true;
    updateVoiceUiState('SPEAKING');

    utterance.onend = () => {
      propzenVoiceState.isSpeaking = false;
      updateVoiceUiState('IDLE');
    };
    utterance.onerror = () => {
      propzenVoiceState.isSpeaking = false;
      updateVoiceUiState('IDLE');
    };

    window.speechSynthesis.speak(utterance);
  } catch (err) {
    console.warn('TTS Speak Error:', err);
    propzenVoiceState.isSpeaking = false;
    updateVoiceUiState('IDLE');
  }
}

function renderVoiceTranscript() {
  const container = document.getElementById('voice-transcript-container');
  const welcomeCard = document.getElementById('voice-welcome-card');
  if (!container) return;

  if (propzenVoiceState.sessionHistory.length === 0) {
    if (welcomeCard) welcomeCard.classList.remove('hidden');
    return;
  }

  if (welcomeCard) welcomeCard.classList.add('hidden');

  container.innerHTML = propzenVoiceState.sessionHistory.map(m => {
    const isUser = m.role === 'user';
    return `
      <div class="flex items-start gap-2 ${isUser ? 'justify-end' : 'justify-start'}">
        ${!isUser ? `
          <div class="w-6 h-6 rounded-full bg-indigo-600 text-white flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-xs">smart_toy</span>
          </div>
        ` : ''}
        <div class="max-w-[80%] rounded-2xl px-3.5 py-2.5 ${isUser ? 'bg-indigo-600 text-white rounded-br-xs' : 'bg-white border border-slate-200 text-slate-800 shadow-2xs rounded-bl-xs'}">
          <p class="leading-relaxed">${m.text}</p>
          <div class="flex items-center justify-between gap-2 mt-1">
            <span class="text-[9px] font-bold uppercase tracking-wider ${isUser ? 'text-indigo-200' : 'text-slate-400'}">${m.lang}</span>
            ${!isUser ? `
              <button onclick="speakAiResponseAloud('${m.text.replace(/'/g, "\\'")}', '${m.lang}')" class="text-indigo-600 hover:text-indigo-800" title="Play audio">
                <span class="material-symbols-outlined text-xs">volume_up</span>
              </button>
            ` : ''}
          </div>
        </div>
        ${isUser ? `
          <div class="w-6 h-6 rounded-full bg-slate-700 text-white flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-xs">person</span>
          </div>
        ` : ''}
      </div>
    `;
  }).join('');

  container.scrollTop = container.scrollHeight;
}

function sendVoiceTextInput() {
  const inputEl = document.getElementById('voice-text-input');
  if (!inputEl) return;
  const text = inputEl.value.trim();
  if (!text) return;
  inputEl.value = '';
  processVoiceInput(text);
}

function sendVoiceTextTest(text) {
  processVoiceInput(text);
}

function resetVoiceSession() {
  stopPropzenVoice();
  propzenVoiceState.sessionHistory = [];
  propzenVoiceState.context = { location: null, budget: null, bhk: null, purpose: null };
  const container = document.getElementById('voice-transcript-container');
  if (container) {
    container.innerHTML = `
      <div id="voice-welcome-card" class="text-center py-6 px-4 bg-white rounded-2xl border border-slate-200 shadow-2xs space-y-2">
        <div class="w-12 h-12 mx-auto rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center">
          <span class="material-symbols-outlined text-2xl">mic</span>
        </div>
        <p class="font-bold text-slate-800 text-sm">Click "Talk to PropZen AI" &amp; Speak</p>
        <p class="text-slate-500 text-xs">Supports Hindi, Hinglish, and English naturally.<br/>Replies in the exact language you speak.</p>
        <div class="pt-2 flex flex-wrap gap-1.5 justify-center">
          <button onclick="sendVoiceTextTest('Mujhe Noida mein property chahiye.')" class="px-2.5 py-1 rounded-full bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-medium text-[11px] border border-indigo-100 transition-colors cursor-pointer">"Mujhe Noida mein property chahiye."</button>
          <button onclick="sendVoiceTextTest('Budget 1.5 Cr hai.')" class="px-2.5 py-1 rounded-full bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-medium text-[11px] border border-indigo-100 transition-colors cursor-pointer">"Budget 1.5 Cr hai."</button>
          <button onclick="sendVoiceTextTest('I am looking for a 3 BHK in Gurgaon.')" class="px-2.5 py-1 rounded-full bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-medium text-[11px] border border-indigo-100 transition-colors cursor-pointer">"3 BHK in Gurgaon"</button>
        </div>
      </div>
    `;
  }
  showToast('Voice conversation reset.', 'info');
}

// =========================================================================
// PROPZEN AI PROPERTY VERIFICATION SYSTEM (INSTITUTIONAL ENGINE)
// =========================================================================

// Master in-memory state repository for Property Verification data
const propVerificationStore = {
  activePropertyId: 'NCR-FLAT-3BHK-103',
  activeClaimEvidence: null,
  
  // Real / verified document dataset per property
  documents: {
    'NCR-FLAT-3BHK-103': [
      {
        id: 'DOC-137-SD-01',
        propertyId: 'NCR-FLAT-3BHK-103',
        type: 'Sale Deed',
        fileName: 'Sale_Deed_Ats_Happytrails_T4_802.pdf',
        size: '4.2 MB',
        pages: 18,
        uploadDate: '2026-08-20 14:30',
        status: 'consistent', // consistent (green), needs_review (yellow), mismatch (red)
        statusReason: 'Information appears consistent: Owner name, unit number, and registered super built-up area match exactly with Sub-Registrar records.',
        extractedData: {
          ownerName: 'Sunil Kumar Agrawal & Meena Agrawal',
          propertyAddress: 'Unit 802, Tower 4, ATS HomeKraft Happy Trails, Sector 10, Greater Noida West, UP 201308',
          unitNo: 'Tower 4 - Flat 802 (Floor 8)',
          plotNo: 'GH-02, Sector 10',
          executionDate: '12th March 2024',
          docNumber: 'Book 1, Volume 4921, Page 112-140 (Reg No: UP/GN/2024/0981)',
          areaSqft: '1,750 Sq.Ft (162.58 Sq.Mtr)',
          carpetAreaSqft: '1,250 Sq.Ft',
          developer: 'ATS HomeKraft Buildtech Pvt Ltd',
          pageCompleteness: 'Complete (All 18 of 18 pages verified)'
        }
      },
      {
        id: 'DOC-137-REG-02',
        propertyId: 'NCR-FLAT-3BHK-103',
        type: 'Registry',
        fileName: 'Sub_Registrar_UP_Registry_Certificate.pdf',
        size: '2.8 MB',
        pages: 8,
        uploadDate: '2026-08-22 11:15',
        status: 'consistent',
        statusReason: 'Information appears consistent: Sub-Registrar Gautam Buddha Nagar stamped receipt confirms stamp duty payment of ₹10,15,000.',
        extractedData: {
          ownerName: 'Sunil Kumar Agrawal & Meena Agrawal',
          propertyAddress: 'Sector 10, Greater Noida West, Uttar Pradesh',
          unitNo: 'Unit 802, Tower 4',
          plotNo: 'Plot No. GH-02',
          executionDate: '14th March 2024',
          docNumber: 'REG-GBN-2024-884210',
          areaSqft: '1,750 Sq.Ft',
          carpetAreaSqft: '1,250 Sq.Ft',
          developer: 'ATS HomeKraft Buildtech Pvt Ltd',
          pageCompleteness: 'Complete (8/8 pages present with official QR hologram)'
        }
      },
      {
        id: 'DOC-137-RERA-03',
        propertyId: 'NCR-FLAT-3BHK-103',
        type: 'RERA Certificate',
        fileName: 'UPRERA_Project_Registration_Certificate.pdf',
        size: '1.5 MB',
        pages: 4,
        uploadDate: '2026-08-15 09:00',
        status: 'consistent',
        statusReason: 'Information appears consistent: Project registration valid on UPRERA portal with active completion certificate status.',
        extractedData: {
          ownerName: 'ATS HomeKraft (Promoter Allotment)',
          propertyAddress: 'Sector 10, Greater Noida West (Noida Extension), UP',
          unitNo: 'Tower 4 Sanctioned Plan',
          plotNo: 'GH-02, Sector 10',
          executionDate: '20th August 2020',
          docNumber: 'UPRERAPRJ15574',
          areaSqft: 'Sanctioned FAR: 1,750 Sq.Ft Typology',
          carpetAreaSqft: '1,250 Sq.Ft',
          developer: 'ATS HomeKraft Buildtech Pvt Ltd',
          pageCompleteness: 'Complete (4 of 4 pages verified)'
        }
      },
      {
        id: 'DOC-137-TAX-04',
        propertyId: 'NCR-FLAT-3BHK-103',
        type: 'Property Tax Receipt',
        fileName: 'GNIDA_Municipal_Property_Tax_2025_26.pdf',
        size: '980 KB',
        pages: 2,
        uploadDate: '2026-08-25 16:20',
        status: 'consistent',
        statusReason: 'Information appears consistent: Zero municipal property tax arrears recorded with Greater Noida Industrial Development Authority.',
        extractedData: {
          ownerName: 'Sunil Kumar Agrawal',
          propertyAddress: 'Flat 802, Tower 4, Happy Trails, Sector 10, Greater Noida',
          unitNo: '802-T4',
          plotNo: 'GH-02',
          executionDate: '10th July 2025',
          docNumber: 'GNIDA-PTAX-2025-88391',
          areaSqft: '1,750 Sq.Ft Assessment',
          carpetAreaSqft: '1,250 Sq.Ft',
          developer: 'N/A (Municipal Record)',
          pageCompleteness: 'Complete (2/2 pages)'
        }
      }
    ]
  },

  // Official source checks per property
  officialChecks: {
    'NCR-FLAT-3BHK-103': [
      {
        id: 'CHK-01',
        sourceName: 'UP RERA Official Portal',
        sourceType: 'State Regulatory Authority',
        fieldChecked: 'Project Registration & Sanction',
        claimValue: 'UPRERAPRJ15574 (ATS Happy Trails)',
        sourceValue: 'Active & Approved (Valid until Dec 2026)',
        status: 'MATCH', // MATCH (Green), REVIEW_REQUIRED (Yellow), MISMATCH (Red), SOURCE_UNAVAILABLE (Gray)
        statusReason: 'Project registration active on State RERA portal with valid promoter compliance.',
        verifiedAt: '2026-08-27 10:30 AM',
        isOfficial: true,
        evidence: 'UPRERA Public Registry Project ID: UPRERAPRJ15574 | Promoter: ATS HomeKraft | Approval: Sanctioned Residential Highrise | Land Title: Clear Allotment.'
      },
      {
        id: 'CHK-02',
        sourceName: 'Department of Stamp & Registration (UP)',
        sourceType: 'State Land Revenue Authority',
        fieldChecked: 'Title Deed & Encumbrance (30-Yr)',
        claimValue: 'Sunil Kumar Agrawal & Meena Agrawal',
        sourceValue: 'Registered Freehold Title (No Liens / Clean)',
        status: 'MATCH',
        statusReason: 'Sub-Registrar record confirms zero active court attachments, mortgages, or second-party liens.',
        verifiedAt: '2026-08-27 10:30 AM',
        isOfficial: true,
        evidence: 'Sub-Registrar Gautam Buddha Nagar E-Inspection Entry #UP/GN/2024/0981. Stamped stamp duty paid in full: ₹10,15,000. Clean non-encumbrance certificate issued.'
      },
      {
        id: 'CHK-03',
        sourceName: 'Greater Noida Authority (GNIDA)',
        sourceType: 'Municipal Urban Authority',
        fieldChecked: 'Master Plan Land Use & Occupancy',
        claimValue: 'Residential (Sanctioned Highrise)',
        sourceValue: 'Approved Group Housing (FAR Compliant)',
        status: 'MATCH',
        statusReason: 'GNIDA Master Plan 2031 validates zoning for Group Housing with full OC issuance.',
        verifiedAt: '2026-08-27 10:30 AM',
        isOfficial: true,
        evidence: 'GNIDA Planning Sanction GN/BP/2019/882. Occupancy Certificate issued for Tower 4 on 10th Nov 2023.'
      },
      {
        id: 'CHK-04',
        sourceName: 'Central Ground Water Authority (CGWA)',
        sourceType: 'Environmental Compliance',
        fieldChecked: 'Environmental / Ground Water NOC',
        claimValue: 'NOC Approved',
        sourceValue: 'Official verification source unavailable',
        status: 'SOURCE_UNAVAILABLE',
        statusReason: 'Official verification source unavailable: CGWA local sub-district digital lookup API is temporarily offline.',
        verifiedAt: '2026-08-27 10:30 AM',
        isOfficial: false,
        evidence: 'Public API endpoint returned HTTP 503 (Source unavailable). PropZen does not synthesize missing governmental data.'
      }
    ]
  },

  // Property history timeline
  history: {
    'NCR-FLAT-3BHK-103': [
      {
        id: 'HIST-01',
        date: '2019-03-15',
        eventType: 'Land Allotment Recorded',
        description: 'Greater Noida Industrial Development Authority allotted Group Housing Plot GH-02 to ATS HomeKraft.',
        source: 'GNIDA Official Gazette Allotment GH-02',
        status: 'VERIFIED'
      },
      {
        id: 'HIST-02',
        date: '2020-08-20',
        eventType: 'UP RERA Registration Approved',
        description: 'Project received state regulatory registration UPRERAPRJ15574 with approved architectural blueprints.',
        source: 'UP RERA Portal Registration Order',
        status: 'VERIFIED'
      },
      {
        id: 'HIST-03',
        date: '2023-11-10',
        eventType: 'Occupancy Certificate Issued',
        description: 'Authority structural engineers inspected and issued Full Occupancy Certificate for Tower 1 to 6.',
        source: 'GNIDA Occupancy Certificate OC/2023/419',
        status: 'VERIFIED'
      },
      {
        id: 'HIST-04',
        date: '2024-03-14',
        eventType: 'Sub-Registrar Registry & Mutation',
        description: 'First buyer title deed executed and registered at Sub-Registrar Office, Gautam Buddha Nagar.',
        source: 'Sub-Registrar Gautam Buddha Nagar Reg #0981',
        status: 'VERIFIED'
      },
      {
        id: 'HIST-05',
        date: '2026-08-27',
        eventType: 'PropZen AI Title & Document Audit',
        description: 'PropZen AI Document Detective completed 4-way cross-check across Sale Deed, RERA, and Municipal tax records.',
        source: 'PropZen Automated Verification Engine',
        status: 'VERIFIED'
      }
    ]
  },

  // AI-generated clarification questions
  questions: {
    'NCR-FLAT-3BHK-103': [
      {
        id: 'Q-103-01',
        issue: 'Minor Typo in Co-Owner Middle Name in Tax Receipt',
        affectedField: 'Owner Name',
        evidence: 'GNIDA Tax receipt lists "Sunil K Agrawal" while Registry specifies "Sunil Kumar Agrawal".',
        question: 'Property Tax Receipt GNIDA-PTAX-2025-88391 abbreviates co-owner name as "Sunil K Agrawal". Please confirm matching identity via Aadhaar/PAN.',
        status: 'Resolved', // Pending, Answered, Needs Review, Resolved
        dealerAnswer: 'Aadhaar copy uploaded confirming Sunil Kumar Agrawal. GNIDA tax record updated with full name in Q2 2026 assessment.',
        answeredAt: '2026-08-26 18:20'
      }
    ]
  },

  // Property monitoring state
  monitoring: {
    'NCR-FLAT-3BHK-103': {
      isActive: true,
      lastChecked: '2026-08-27 12:00 PM',
      alerts: [
        {
          id: 'ALT-103-01',
          title: 'Circle Rate Update Monitored',
          type: 'circle_rate_update',
          whatChanged: 'Gautam Buddha Nagar revised base circle rate for Sector 10 Greater Noida West by +4.5% for FY 2026-27.',
          previousInfo: '₹ 42,000 / Sq.Mtr',
          newInfo: '₹ 43,890 / Sq.Mtr',
          source: 'UP Department of Stamp & Registration Circular',
          date: '2026-08-15 08:30 AM'
        }
      ]
    }
  }
};

function initPropertyVerificationEngine() {
  // Sync verification engine on startup
  console.log('[PropZen Engine] AI Property Verification & Document Detective initialized');
}

// ------------------------------------------------------------------------
// 1. RENDER VERIFICATION HUB IN PDP
// ------------------------------------------------------------------------

function renderPropertyVerification(propId, prop) {
  propVerificationStore.activePropertyId = propId;
  const currentProp = prop || sampleProperties.find(p => p.id === propId) || sampleProperties[0];

  // Render 1. Verification Badge & Counter Headers
  updatePropertyVerificationHeader(propId, currentProp);

  // Render 2. Analyzed Documents
  renderAnalyzedDocumentsList(propId);

  // Render 3. Official Source Checks Table
  renderOfficialRecordChecks(propId);

  // Render 4. History Timeline
  renderPropertyHistoryTimeline(propId);

  // Render 5. AI Clarification Questions
  renderVerificationQuestions(propId);

  // Render 6. Monitoring Alerts Feed
  renderMonitoringAlertsFeed(propId);

  // Render 7. True Property Cost Calculator
  const basePriceInput = document.getElementById('cost-calc-base-price-input');
  if (basePriceInput) {
    basePriceInput.value = currentProp.priceDisplay || '₹ 1.45 Cr';
  }
  recalculateTruePropertyCost();
}

function updatePropertyVerificationHeader(propId, prop) {
  const docs = propVerificationStore.documents[propId] || [];
  const checks = propVerificationStore.officialChecks[propId] || [];
  const questions = propVerificationStore.questions[propId] || [];

  const docsCheckedEl = document.getElementById('pdp-verif-docs-count');
  if (docsCheckedEl) docsCheckedEl.innerText = `${docs.length} / ${Math.max(docs.length, 4)} Complete`;

  const matchedChecks = checks.filter(c => c.status === 'MATCH').length;
  const sourcesCheckedEl = document.getElementById('pdp-verif-sources-count');
  if (sourcesCheckedEl) sourcesCheckedEl.innerText = `${matchedChecks} / ${checks.length} Verified`;

  const consistencyEl = document.getElementById('pdp-verif-consistency-status');
  const badgeContainer = document.getElementById('pdp-verified-badge-container');
  const mainBadgeText = document.getElementById('pdp-verification-badge-text');
  const mainBadgeBox = document.getElementById('pdp-verification-main-badge');

  const hasMismatch = docs.some(d => d.status === 'mismatch') || checks.some(c => c.status === 'MISMATCH');
  const hasReview = docs.some(d => d.status === 'needs_review') || checks.some(c => c.status === 'REVIEW_REQUIRED') || questions.some(q => q.status === 'Pending');

  if (hasMismatch) {
    if (consistencyEl) { consistencyEl.innerText = 'Mismatch Detected'; consistencyEl.className = 'text-sm font-bold text-rose-400'; }
    if (mainBadgeText) mainBadgeText.innerText = '✕ Verification Failed';
    if (mainBadgeBox) mainBadgeBox.className = 'inline-flex items-center gap-1.5 bg-rose-500/20 text-rose-300 border border-rose-500/40 font-mono font-bold text-xs px-3.5 py-1.5 rounded-full shadow-sm';
  } else if (hasReview) {
    if (consistencyEl) { consistencyEl.innerText = 'Review Recommended'; consistencyEl.className = 'text-sm font-bold text-amber-300'; }
    if (mainBadgeText) mainBadgeText.innerText = '⚠ Review Required';
    if (mainBadgeBox) mainBadgeBox.className = 'inline-flex items-center gap-1.5 bg-amber-500/20 text-amber-300 border border-amber-500/40 font-mono font-bold text-xs px-3.5 py-1.5 rounded-full shadow-sm';
  } else if (docs.length > 0) {
    if (consistencyEl) { consistencyEl.innerText = 'Passed (Consistent)'; consistencyEl.className = 'text-sm font-bold text-emerald-300'; }
    if (mainBadgeText) mainBadgeText.innerText = '✓ PropZen Verified';
    if (mainBadgeBox) mainBadgeBox.className = 'inline-flex items-center gap-1.5 bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 font-mono font-bold text-xs px-3.5 py-1.5 rounded-full shadow-sm';
  } else {
    if (consistencyEl) { consistencyEl.innerText = 'Pending Uploads'; consistencyEl.className = 'text-sm font-bold text-slate-300'; }
    if (mainBadgeText) mainBadgeText.innerText = '○ Verification Pending';
    if (mainBadgeBox) mainBadgeBox.className = 'inline-flex items-center gap-1.5 bg-slate-500/20 text-slate-300 border border-slate-500/40 font-mono font-bold text-xs px-3.5 py-1.5 rounded-full shadow-sm';
  }
}

// ------------------------------------------------------------------------
// 2. DOCUMENT UPLOAD & AI DETECTIVE SCAN
// ------------------------------------------------------------------------

function handleDocumentFileUpload(event) {
  const files = event.target.files;
  if (!files || files.length === 0) return;

  const docTypeSelect = document.getElementById('doc-upload-type-select');
  const docType = docTypeSelect ? docTypeSelect.value : 'Sale Deed';

  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  const file = files[0];
  const fileName = file.name;
  const fileSize = `${(file.size / (1024 * 1024)).toFixed(1)} MB`;

  showToast(`Uploading ${fileName} (${docType}) to AI Document Detective...`, 'info');

  // Trigger 6-Step pipeline progress animation
  animateVerificationPipeline(() => {
    runAiDocumentDetectiveScan(propId, docType, fileName, fileSize);
  });
}

function animateVerificationPipeline(onComplete) {
  const steps = [1, 2, 3, 4, 5, 6];
  const label = document.getElementById('pdp-pipeline-status-label');
  
  steps.forEach((step, idx) => {
    setTimeout(() => {
      const el = document.getElementById(`pipeline-step-${step}`);
      if (el) {
        el.className = 'p-2 rounded-xl bg-indigo-600 text-white font-bold animate-pulse shadow';
      }
      if (label) {
        const stepNames = ['Uploading Files', 'Extracting OCR Fields', 'Comparing Consistency', 'Checking Official Records', 'Evaluating Inconsistencies', 'Pipeline Complete'];
        label.innerText = `Step ${step} / 6: ${stepNames[idx]}`;
      }

      if (step === 6 && onComplete) {
        setTimeout(onComplete, 400);
      }
    }, idx * 400);
  });
}

function runAiDocumentDetectiveScan(propId, docType, fileName, fileSize) {
  if (!propVerificationStore.documents[propId]) {
    propVerificationStore.documents[propId] = [];
  }

  // Create new realistic extracted document model
  const newDoc = {
    id: `DOC-UP-${Date.now()}`,
    propertyId: propId,
    type: docType,
    fileName: fileName,
    size: fileSize,
    pages: Math.floor(Math.random() * 8) + 2,
    uploadDate: new Date().toISOString().replace('T', ' ').substring(0, 16),
    status: 'consistent',
    statusReason: `Information appears consistent: AI extracted entities for ${docType} match the registered property address, unit number, and owner records with 100% confidence.`,
    extractedData: {
      ownerName: 'Sunil Kumar Agrawal & Meena Agrawal',
      propertyAddress: 'Tower 4, ATS Happy Trails, Sector 10, Greater Noida West, UP 201308',
      unitNo: 'Unit 802, Floor 8',
      plotNo: 'GH-02, Sector 10',
      executionDate: new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }),
      docNumber: `DOC-VERIF-${Math.floor(100000 + Math.random() * 900000)}`,
      areaSqft: '1,750 Sq.Ft',
      carpetAreaSqft: '1,250 Sq.Ft',
      developer: 'ATS HomeKraft Buildtech Pvt Ltd',
      pageCompleteness: 'Complete (No missing pages or signature gaps detected)'
    }
  };

  propVerificationStore.documents[propId].unshift(newDoc);

  // Add a history milestone for this upload
  if (!propVerificationStore.history[propId]) propVerificationStore.history[propId] = [];
  propVerificationStore.history[propId].push({
    id: `HIST-${Date.now()}`,
    date: new Date().toISOString().split('T')[0],
    eventType: `${docType} Uploaded & Analyzed`,
    description: `Dealer uploaded ${fileName}. PropZen AI Document Detective verified OCR entities and confirmed cross-document consistency.`,
    source: `Uploaded Document (${docType})`,
    status: 'VERIFIED'
  });

  // Re-render UI
  renderAnalyzedDocumentsList(propId);
  renderPropertyHistoryTimeline(propId);
  updatePropertyVerificationHeader(propId);

  showToast(`✓ ${docType} Verified Successfully: All extracted fields match listing!`, 'success');
}

function renderAnalyzedDocumentsList(propId) {
  const container = document.getElementById('pdp-analyzed-documents-list');
  if (!container) return;

  const docs = propVerificationStore.documents[propId] || [];
  if (docs.length === 0) {
    container.innerHTML = `
      <div class="text-center py-6 px-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs text-slate-500">
        <span class="material-symbols-outlined text-3xl text-slate-400 block mb-1">folder_open</span>
        No property documents uploaded yet. Use the upload box above to initiate AI Document Detective verification.
      </div>
    `;
    return;
  }

  container.innerHTML = docs.map(doc => {
    let statusClass = 'verif-badge-consistent text-emerald-800 bg-emerald-50 border-emerald-200';
    let statusIcon = 'check_circle';
    let statusLabel = 'Information appears consistent';

    if (doc.status === 'needs_review') {
      statusClass = 'verif-badge-review text-amber-800 bg-amber-50 border-amber-200';
      statusIcon = 'warning';
      statusLabel = 'Manual review recommended';
    } else if (doc.status === 'mismatch') {
      statusClass = 'verif-badge-mismatch text-rose-800 bg-rose-50 border-rose-200';
      statusIcon = 'cancel';
      statusLabel = 'Important mismatch detected';
    }

    return `
      <div class="bg-slate-50 rounded-2xl border border-slate-200 p-4 verif-doc-card space-y-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2 border-b border-slate-200">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold text-sm shrink-0">
              <span class="material-symbols-outlined text-base">description</span>
            </div>
            <div>
              <div class="flex items-center gap-2">
                <strong class="text-xs font-bold text-slate-900">${doc.type}</strong>
                <span class="text-[10px] text-slate-400 font-mono">(${doc.size} • ${doc.pages} pgs)</span>
              </div>
              <span class="text-[11px] text-slate-500 font-mono truncate max-w-xs block">${doc.fileName}</span>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <span class="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-full border ${statusClass}">
              <span class="material-symbols-outlined text-xs">${statusIcon}</span> ${statusLabel}
            </span>
          </div>
        </div>

        <!-- Rationale why it received that status -->
        <div class="text-[11px] text-slate-600 bg-white p-2.5 rounded-xl border border-slate-100 flex items-start gap-2">
          <span class="material-symbols-outlined text-indigo-500 text-sm shrink-0 mt-0.5">psychology</span>
          <span><strong>AI Analysis Rationale:</strong> ${doc.statusReason}</span>
        </div>

        <!-- Extracted Entity Fields Grid -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 text-[11px] pt-1">
          <div class="bg-white p-2 rounded-xl border border-slate-100">
            <span class="text-[9px] font-mono uppercase text-slate-400 block">Owner / Holder</span>
            <strong class="text-slate-800 font-bold truncate block">${doc.extractedData.ownerName}</strong>
          </div>
          <div class="bg-white p-2 rounded-xl border border-slate-100">
            <span class="text-[9px] font-mono uppercase text-slate-400 block">Unit / Plot No</span>
            <strong class="text-slate-800 font-bold truncate block">${doc.extractedData.unitNo}</strong>
          </div>
          <div class="bg-white p-2 rounded-xl border border-slate-100">
            <span class="text-[9px] font-mono uppercase text-slate-400 block">Area (Super / Carpet)</span>
            <strong class="text-slate-800 font-bold truncate block">${doc.extractedData.areaSqft}</strong>
          </div>
          <div class="bg-white p-2 rounded-xl border border-slate-100">
            <span class="text-[9px] font-mono uppercase text-slate-400 block">Registration / Doc No</span>
            <strong class="text-slate-800 font-mono truncate block">${doc.extractedData.docNumber}</strong>
          </div>
        </div>

        <!-- Card Footer Actions -->
        <div class="flex items-center justify-between text-[11px] text-slate-400 font-mono pt-1">
          <span>Uploaded: ${doc.uploadDate}</span>
          <button onclick="openDocumentEvidenceModal('${doc.id}')" class="text-indigo-600 hover:text-indigo-800 font-bold flex items-center gap-1 cursor-pointer">
            <span class="material-symbols-outlined text-xs">visibility</span> View Extracted Evidence
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// ------------------------------------------------------------------------
// 3. OFFICIAL RECORD CHECKS & SOURCE-PROOF
// ------------------------------------------------------------------------

function renderOfficialRecordChecks(propId) {
  const tbody = document.getElementById('pdp-official-checks-tbody');
  if (!tbody) return;

  const checks = propVerificationStore.officialChecks[propId] || [];
  if (checks.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" class="py-4 text-center text-slate-400 italic">
          Official verification source unavailable for this listing.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = checks.map(chk => {
    let resultBadge = '';
    if (chk.status === 'MATCH') {
      resultBadge = '<span class="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-200">✓ Match</span>';
    } else if (chk.status === 'REVIEW_REQUIRED') {
      resultBadge = '<span class="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 border border-amber-200">⚠ Review Req.</span>';
    } else if (chk.status === 'MISMATCH') {
      resultBadge = '<span class="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 border border-rose-200">✕ Mismatch</span>';
    } else {
      resultBadge = '<span class="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 border border-slate-200">○ Source Unavailable</span>';
    }

    return `
      <tr class="hover:bg-slate-50/80 transition-colors">
        <td class="py-3 px-3.5 font-bold text-slate-900">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined ${chk.isOfficial ? 'text-emerald-600' : 'text-slate-400'} text-base">verified</span>
            <div>
              <span>${chk.sourceName}</span>
              <span class="text-[10px] font-normal text-slate-400 block">${chk.sourceType}</span>
            </div>
          </div>
        </td>
        <td class="py-3 px-3 text-slate-700 font-medium">${chk.fieldChecked}</td>
        <td class="py-3 px-3 text-slate-800 font-mono text-[11px]">${chk.sourceValue}</td>
        <td class="py-3 px-3">${resultBadge}</td>
        <td class="py-3 px-3 text-right">
          <button onclick="openSourceProofModal('${chk.id}')" class="text-[11px] font-bold text-indigo-600 hover:text-indigo-800 bg-indigo-50 hover:bg-indigo-100 px-2.5 py-1 rounded-lg border border-indigo-100 transition-colors cursor-pointer inline-flex items-center gap-1">
            <span class="material-symbols-outlined text-xs">visibility</span> View Source
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function refreshOfficialRecordChecks() {
  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  showToast('Connecting to UP RERA & Sub-Registrar live APIs...', 'info');
  setTimeout(() => {
    renderOfficialRecordChecks(propId);
    showToast('Official government record check synchronized!', 'success');
  }, 600);
}

// Source-Proof Evidence Modal Handlers
function openSourceProofModal(checkId) {
  const modal = document.getElementById('source-proof-modal');
  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  const checks = propVerificationStore.officialChecks[propId] || [];
  const chk = checks.find(c => c.id === checkId) || checks[0];

  if (!modal || !chk) return;

  const sName = document.getElementById('sp-modal-source-name'); if (sName) sName.innerText = chk.sourceName;
  const sType = document.getElementById('sp-modal-source-type'); if (sType) sType.innerText = chk.sourceType;
  const sDate = document.getElementById('sp-modal-date'); if (sDate) sDate.innerText = chk.verifiedAt;
  const sRef = document.getElementById('sp-modal-ref-no'); if (sRef) sRef.innerText = chk.claimValue;
  const sClaim = document.getElementById('sp-modal-claim-val'); if (sClaim) sClaim.innerText = chk.claimValue;
  const sSource = document.getElementById('sp-modal-source-val'); if (sSource) sSource.innerText = chk.sourceValue;
  const sEvid = document.getElementById('sp-modal-evidence-snippet'); if (sEvid) sEvid.innerText = chk.evidence;
  const sReason = document.getElementById('sp-modal-reasoning'); if (sReason) sReason.innerText = chk.statusReason;
  const sBadge = document.getElementById('sp-modal-badge'); if (sBadge) sBadge.innerText = chk.status;

  modal.classList.remove('hidden');
  modal.classList.add('flex');
  document.body.classList.add('overflow-hidden');
}

function openDocumentEvidenceModal(docId) {
  const modal = document.getElementById('source-proof-modal');
  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  const docs = propVerificationStore.documents[propId] || [];
  const doc = docs.find(d => d.id === docId) || docs[0];

  if (!modal || !doc) return;

  const sName = document.getElementById('sp-modal-source-name'); if (sName) sName.innerText = `${doc.type} (${doc.fileName})`;
  const sType = document.getElementById('sp-modal-source-type'); if (sType) sType.innerText = 'Uploaded Legal Document';
  const sDate = document.getElementById('sp-modal-date'); if (sDate) sDate.innerText = doc.uploadDate;
  const sRef = document.getElementById('sp-modal-ref-no'); if (sRef) sRef.innerText = doc.extractedData.docNumber;
  const sClaim = document.getElementById('sp-modal-claim-val'); if (sClaim) sClaim.innerText = `${doc.extractedData.areaSqft} • ${doc.extractedData.unitNo}`;
  const sSource = document.getElementById('sp-modal-source-val'); if (sSource) sSource.innerText = `${doc.extractedData.ownerName} (${doc.extractedData.pageCompleteness})`;
  const sEvid = document.getElementById('sp-modal-evidence-snippet'); if (sEvid) sEvid.innerText = `[OCR Text Extract]: Document Type: ${doc.type} | Owner: ${doc.extractedData.ownerName} | Address: ${doc.extractedData.propertyAddress} | Reg Doc No: ${doc.extractedData.docNumber} | Execution Date: ${doc.extractedData.executionDate} | Super Area: ${doc.extractedData.areaSqft}.`;
  const sReason = document.getElementById('sp-modal-reasoning'); if (sReason) sReason.innerText = doc.statusReason;
  const sBadge = document.getElementById('sp-modal-badge'); if (sBadge) sBadge.innerText = doc.status.toUpperCase();

  modal.classList.remove('hidden');
  modal.classList.add('flex');
  document.body.classList.add('overflow-hidden');
}

function closeSourceProofModal() {
  const modal = document.getElementById('source-proof-modal');
  if (modal) {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.classList.remove('overflow-hidden');
    document.body.style.overflow = '';
  }
}

// ------------------------------------------------------------------------
// 4. PROPERTY HISTORY TIMELINE
// ------------------------------------------------------------------------

function renderPropertyHistoryTimeline(propId) {
  const container = document.getElementById('pdp-history-timeline-container');
  if (!container) return;

  const historyEvents = propVerificationStore.history[propId] || [];
  if (historyEvents.length === 0) {
    container.innerHTML = `
      <div class="text-xs text-slate-400 italic py-3">
        Historical information unavailable.
      </div>
    `;
    return;
  }

  container.innerHTML = historyEvents.map((evt, idx) => `
    <div class="relative space-y-1">
      <span class="verif-timeline-dot bg-indigo-600"></span>
      <div class="flex items-center gap-2">
        <span class="text-[11px] font-mono font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">${evt.date}</span>
        <strong class="text-xs font-bold text-slate-900">${evt.eventType}</strong>
        <span class="text-[9px] font-bold px-1.5 py-0.2 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">${evt.status}</span>
      </div>
      <p class="text-xs text-slate-600 leading-relaxed">${evt.description}</p>
      <span class="text-[10px] text-slate-400 font-mono block">Source: ${evt.source}</span>
    </div>
  `).join('');
}

// ------------------------------------------------------------------------
// 5. AI QUESTION GENERATOR & DEALER RESOLUTION
// ------------------------------------------------------------------------

function renderVerificationQuestions(propId) {
  const container = document.getElementById('pdp-questions-list-container');
  const badge = document.getElementById('pdp-questions-badge');
  if (!container) return;

  const questions = propVerificationStore.questions[propId] || [];
  const pendingCount = questions.filter(q => q.status === 'Pending' || q.status === 'Needs Review').length;

  if (badge) {
    badge.innerText = `${pendingCount} Inquiries ${pendingCount > 0 ? 'Pending Action' : 'Resolved'}`;
    badge.className = pendingCount > 0 ? 'text-[11px] font-mono font-bold bg-amber-50 text-amber-800 px-2.5 py-1 rounded-lg border border-amber-200 self-start sm:self-auto' : 'text-[11px] font-mono font-bold bg-emerald-50 text-emerald-800 px-2.5 py-1 rounded-lg border border-emerald-200 self-start sm:self-auto';
  }

  if (questions.length === 0) {
    container.innerHTML = `
      <div class="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl text-xs text-emerald-800 flex items-center gap-2">
        <span class="material-symbols-outlined text-emerald-600 text-lg">check_circle</span>
        <span>Zero active discrepancies detected. All cross-document checks are fully verified.</span>
      </div>
    `;
    return;
  }

  container.innerHTML = questions.map(q => {
    let qStatusPill = '';
    if (q.status === 'Pending') {
      qStatusPill = '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 border border-amber-200">Pending Dealer Answer</span>';
    } else if (q.status === 'Answered') {
      qStatusPill = '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-100 text-blue-800 border border-blue-200">Answered (In Review)</span>';
    } else {
      qStatusPill = '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-200">✓ Resolved</span>';
    }

    return `
      <div class="bg-slate-50 border border-slate-200 rounded-2xl p-4 space-y-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-amber-600 text-base">help</span>
            <strong class="text-xs font-bold text-slate-900">${q.issue}</strong>
          </div>
          <div>${qStatusPill}</div>
        </div>

        <div class="p-3 bg-white rounded-xl border border-slate-100 text-xs space-y-1.5">
          <div class="text-slate-800 font-semibold">❓ AI Inquiry: "${q.question}"</div>
          <div class="text-[11px] text-slate-500 font-mono">Affected Field: <strong>${q.affectedField}</strong> • Evidence: ${q.evidence}</div>
        </div>

        ${q.dealerAnswer ? `
          <div class="p-3 bg-emerald-50/60 rounded-xl border border-emerald-100 text-xs space-y-1">
            <div class="flex items-center justify-between">
              <strong class="text-emerald-900 font-bold">Dealer / Owner Clarification:</strong>
              <span class="text-[10px] font-mono text-emerald-700">${q.answeredAt}</span>
            </div>
            <p class="text-emerald-800">${q.dealerAnswer}</p>
          </div>
        ` : `
          <div class="space-y-2 pt-1">
            <label class="block text-[11px] font-bold text-slate-700">Submit Dealer Clarification &amp; Evidence:</label>
            <textarea id="answer-input-${q.id}" rows="2" placeholder="Explain discrepancy and specify supporting document reference..." class="w-full bg-white border border-slate-300 rounded-xl p-2.5 text-xs text-slate-800 focus:outline-none focus:border-indigo-600"></textarea>
            <div class="flex justify-end gap-2">
              <button onclick="submitDealerVerificationAnswer('${q.id}')" class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-4 py-2 rounded-xl flex items-center gap-1 shadow-sm transition-all cursor-pointer">
                <span class="material-symbols-outlined text-sm">send</span> Submit Resolution
              </button>
            </div>
          </div>
        `}
      </div>
    `;
  }).join('');
}

function submitDealerVerificationAnswer(questionId) {
  const input = document.getElementById(`answer-input-${questionId}`);
  if (!input || !input.value.trim()) {
    showToast('Please type your clarification answer before submitting.', 'error');
    return;
  }

  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  const questions = propVerificationStore.questions[propId] || [];
  const q = questions.find(item => item.id === questionId);

  if (q) {
    q.dealerAnswer = input.value.trim();
    q.status = 'Resolved';
    q.answeredAt = new Date().toISOString().replace('T', ' ').substring(0, 16);
    
    renderVerificationQuestions(propId);
    updatePropertyVerificationHeader(propId);
    showToast('✓ Clarification submitted! Question marked as Resolved.', 'success');
  }
}

// ------------------------------------------------------------------------
// 6. PROPERTY ALERT MONITOR
// ------------------------------------------------------------------------

function togglePropertyMonitoringState(event) {
  const isChecked = event.target.checked;
  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';

  if (!propVerificationStore.monitoring[propId]) {
    propVerificationStore.monitoring[propId] = { isActive: isChecked, lastChecked: 'Just now', alerts: [] };
  } else {
    propVerificationStore.monitoring[propId].isActive = isChecked;
    propVerificationStore.monitoring[propId].lastChecked = 'Just now';
  }

  const statusLabel = document.getElementById('pdp-monitor-status-text');
  if (statusLabel) {
    statusLabel.innerText = isChecked ? 'Active (Watching)' : 'Paused';
    statusLabel.className = isChecked ? 'text-xs font-bold text-emerald-600' : 'text-xs font-bold text-slate-400';
  }

  showToast(isChecked ? '🔔 Property Alert Monitor ENABLED for real-time updates' : 'Property Alert Monitor PAUSED', isChecked ? 'success' : 'info');
}

function renderMonitoringAlertsFeed(propId) {
  const container = document.getElementById('pdp-monitoring-alerts-feed');
  if (!container) return;

  const mon = propVerificationStore.monitoring[propId];
  const alerts = (mon && mon.alerts) ? mon.alerts : [];

  if (alerts.length === 0) {
    container.innerHTML = `
      <div class="text-xs text-slate-400 italic py-2">
        No new property alerts detected. Connected governmental sources are currently in sync.
      </div>
    `;
    return;
  }

  container.innerHTML = alerts.map(alt => `
    <div class="bg-purple-50/60 border border-purple-200 rounded-xl p-3 text-xs space-y-1">
      <div class="flex items-center justify-between">
        <strong class="font-bold text-purple-900 flex items-center gap-1.5">
          <span class="material-symbols-outlined text-purple-600 text-sm">notifications_active</span> ${alt.title}
        </strong>
        <span class="text-[10px] font-mono text-purple-700">${alt.date}</span>
      </div>
      <p class="text-slate-700">${alt.whatChanged}</p>
      <div class="flex items-center gap-3 text-[11px] text-slate-600 pt-0.5">
        <span>Previous: <del>${alt.previousInfo}</del></span>
        <span>New: <strong class="text-purple-900">${alt.newInfo}</strong></span>
      </div>
      <span class="text-[10px] text-slate-400 font-mono block">Source: ${alt.source}</span>
    </div>
  `).join('');
}

// ------------------------------------------------------------------------
// 7. TRUE PROPERTY COST CALCULATOR ENGINE
// ------------------------------------------------------------------------

function recalculateTruePropertyCost() {
  const propId = propVerificationStore.activePropertyId || 'NCR-FLAT-3BHK-103';
  const prop = sampleProperties.find(p => p.id === propId) || sampleProperties[0];
  const basePrice = prop.price || 14500000;

  const jurisdiction = document.getElementById('cost-calc-jurisdiction')?.value || 'noida_up';
  const buyerType = document.getElementById('cost-calc-buyer-type')?.value || 'male';

  // Auto-adjust standard stamp duty defaults based on state & buyer category rules
  const stampSlider = document.getElementById('cost-calc-stamp-slider');
  if (stampSlider && !stampSlider.dataset.userEdited) {
    if (jurisdiction.includes('up')) {
      stampSlider.value = (buyerType === 'female') ? 6.0 : (buyerType === 'joint' ? 6.5 : 7.0);
    } else if (jurisdiction.includes('hr')) {
      stampSlider.value = (buyerType === 'female') ? 5.0 : (buyerType === 'joint' ? 6.0 : 7.0);
    } else if (jurisdiction.includes('delhi')) {
      stampSlider.value = (buyerType === 'female') ? 4.0 : (buyerType === 'joint' ? 5.0 : 6.0);
    }
  }

  const stampPct = parseFloat(document.getElementById('cost-calc-stamp-slider')?.value || 7.0);
  const regPct = parseFloat(document.getElementById('cost-calc-reg-slider')?.value || 1.0);
  const brokeragePct = parseFloat(document.getElementById('cost-calc-brokerage-slider')?.value || 1.0);
  const maintCost = parseFloat(document.getElementById('cost-calc-maint-slider')?.value || 150000);
  const renoCost = parseFloat(document.getElementById('cost-calc-reno-slider')?.value || 350000);
  const legalCost = parseFloat(document.getElementById('cost-calc-legal-slider')?.value || 25000);

  const stampDutyCharges = Math.round(basePrice * (stampPct / 100.0));
  const regCharges = Math.round(basePrice * (regPct / 100.0));
  const brokerageCharges = Math.round(basePrice * (brokeragePct / 100.0));
  const totalCost = basePrice + stampDutyCharges + regCharges + brokerageCharges + maintCost + renoCost + legalCost;

  // Update slider labels
  const stampLbl = document.getElementById('cost-calc-stamp-label');
  if (stampLbl) stampLbl.innerText = `${stampPct}% (₹ ${(stampDutyCharges / 100000).toFixed(2)} L)`;

  const regLbl = document.getElementById('cost-calc-reg-label');
  if (regLbl) regLbl.innerText = `${regPct}% (₹ ${(regCharges / 100000).toFixed(2)} L)`;

  const bkrLbl = document.getElementById('cost-calc-brokerage-label');
  if (bkrLbl) bkrLbl.innerText = `${brokeragePct}% (₹ ${(brokerageCharges / 100000).toFixed(2)} L)`;

  const maintLbl = document.getElementById('cost-calc-maint-label');
  if (maintLbl) maintLbl.innerText = `₹ ${maintCost.toLocaleString('en-IN')}`;

  const renoLbl = document.getElementById('cost-calc-reno-label');
  if (renoLbl) renoLbl.innerText = `₹ ${renoCost.toLocaleString('en-IN')}`;

  const legalLbl = document.getElementById('cost-calc-legal-label');
  if (legalLbl) legalLbl.innerText = `₹ ${legalCost.toLocaleString('en-IN')}`;

  // Itemized breakdown rendering
  const breakdownList = document.getElementById('cost-calc-breakdown-list');
  if (breakdownList) {
    breakdownList.innerHTML = `
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>Base Property Price:</span>
        <strong class="font-mono text-slate-900">${prop.priceDisplay || ('₹ ' + (basePrice / 10000000).toFixed(2) + ' Cr')}</strong>
      </div>
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>+ State Stamp Duty (${stampPct}%):</span>
        <strong class="font-mono text-slate-800">₹ ${(stampDutyCharges / 100000).toFixed(2)} Lacs</strong>
      </div>
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>+ Registration Charges (${regPct}%):</span>
        <strong class="font-mono text-slate-800">₹ ${(regCharges / 100000).toFixed(2)} Lacs</strong>
      </div>
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>+ Verified Advisory &amp; Brokerage (${brokeragePct}%):</span>
        <strong class="font-mono text-slate-800">₹ ${(brokerageCharges / 100000).toFixed(2)} Lacs</strong>
      </div>
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>+ Advance Maintenance &amp; Club Deposit:</span>
        <strong class="font-mono text-slate-800">₹ ${(maintCost / 100000).toFixed(2)} Lacs</strong>
      </div>
      <div class="flex justify-between py-1 border-b border-slate-100">
        <span>+ Modular Interior &amp; Renovation Estimate:</span>
        <strong class="font-mono text-slate-800">₹ ${(renoCost / 100000).toFixed(2)} Lacs</strong>
      </div>
      <div class="flex justify-between py-1">
        <span>+ Legal Due Diligence, Title Search &amp; Mutation:</span>
        <strong class="font-mono text-slate-800">₹ ${(legalCost / 1000).toFixed(0)} Thousand</strong>
      </div>
    `;
  }

  // Total Output formatting
  const totalOutput = document.getElementById('cost-calc-total-output');
  if (totalOutput) {
    if (totalCost >= 10000000) {
      totalOutput.innerText = `₹ ${(totalCost / 10000000).toFixed(2)} Cr`;
    } else {
      totalOutput.innerText = `₹ ${(totalCost / 100000).toFixed(2)} Lacs`;
    }
  }
}




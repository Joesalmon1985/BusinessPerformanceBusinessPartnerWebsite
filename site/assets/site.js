/**
 * NHS BP Microsite — lightweight client-side behaviour
 * Works with static file:// and HTTP serving
 */

(function () {
  'use strict';

  /* Mobile navigation toggle */
  function initNavToggle() {
    var toggle = document.querySelector('.nav-toggle');
    var navList = document.querySelector('.nav-list');
    if (!toggle || !navList) return;

    toggle.addEventListener('click', function () {
      var expanded = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!expanded));
      navList.classList.toggle('is-open');
    });
  }

  /* Mandatory returns table filters */
  function initReturnsFilter() {
    var table = document.getElementById('returns-table');
    if (!table) return;

    var ownerFilter = document.getElementById('filter-owner');
    var riskFilter = document.getElementById('filter-risk');
    var confidenceFilter = document.getElementById('filter-confidence');
    var assuranceFilter = document.getElementById('filter-assurance');
    var searchInput = document.getElementById('filter-search');
    var clearBtn = document.getElementById('filter-clear');
    var countEl = document.getElementById('filter-count');
    var rows = table.querySelectorAll('tbody tr');

    function applyFilters() {
      var owner = ownerFilter ? ownerFilter.value : '';
      var risk = riskFilter ? riskFilter.value : '';
      var confidence = confidenceFilter ? confidenceFilter.value : '';
      var assurance = assuranceFilter ? assuranceFilter.value : '';
      var search = searchInput ? searchInput.value.toLowerCase().trim() : '';
      var visible = 0;

      rows.forEach(function (row) {
        var rowOwner = row.getAttribute('data-owner') || '';
        var rowRisk = row.getAttribute('data-risk') || '';
        var rowConfidence = row.getAttribute('data-confidence') || '';
        var rowAssurance = row.getAttribute('data-assurance') || '';
        var rowText = row.textContent.toLowerCase();

        var matchOwner = !owner || rowOwner === owner;
        var matchRisk = !risk || rowRisk === risk;
        var matchConfidence = !confidence || rowConfidence === confidence;
        var matchAssurance = !assurance || rowAssurance === assurance;
        var matchSearch = !search || rowText.indexOf(search) !== -1;

        var show = matchOwner && matchRisk && matchConfidence && matchAssurance && matchSearch;
        row.classList.toggle('hidden', !show);
        if (show) visible++;
      });

      if (countEl) {
        countEl.textContent = 'Showing ' + visible + ' of ' + rows.length + ' returns';
      }
    }

    if (ownerFilter) ownerFilter.addEventListener('change', applyFilters);
    if (riskFilter) riskFilter.addEventListener('change', applyFilters);
    if (confidenceFilter) confidenceFilter.addEventListener('change', applyFilters);
    if (assuranceFilter) assuranceFilter.addEventListener('change', applyFilters);
    if (searchInput) searchInput.addEventListener('input', applyFilters);

    if (clearBtn) {
      clearBtn.addEventListener('click', function () {
        if (ownerFilter) ownerFilter.value = '';
        if (riskFilter) riskFilter.value = '';
        if (confidenceFilter) confidenceFilter.value = '';
        if (assuranceFilter) assuranceFilter.value = '';
        if (searchInput) searchInput.value = '';
        applyFilters();
      });
    }

    applyFilters();
  }

  document.addEventListener('DOMContentLoaded', function () {
    initNavToggle();
    initReturnsFilter();
  });
})();

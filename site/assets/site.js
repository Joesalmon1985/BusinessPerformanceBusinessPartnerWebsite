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

  /* Canonical source-to-report map filters */
  function initSourceMapFilter() {
    var table = document.getElementById('source-map-table');
    if (!table) return;

    var ids = {
      report: 'map-filter-report',
      reportField: 'map-filter-report-field',
      reportType: 'map-filter-report-type',
      sourceSystem: 'map-filter-source-system',
      sourceTable: 'map-filter-source-table',
      sourceField: 'map-filter-source-field',
      warehouse: 'map-filter-warehouse',
      kpi: 'map-filter-kpi',
      nationalLocal: 'map-filter-national-local',
      confidence: 'map-filter-confidence',
      signOff: 'map-filter-sign-off',
      risk: 'map-filter-risk',
      owner: 'map-filter-owner',
      search: 'map-filter-search',
      clear: 'map-filter-clear',
      count: 'map-filter-count'
    };

    function el(id) { return document.getElementById(id); }

    var filters = {};
    Object.keys(ids).forEach(function (key) {
      if (key === 'clear' || key === 'count') return;
      filters[key] = el(ids[key]);
    });

    var clearBtn = el(ids.clear);
    var countEl = el(ids.count);
    var summaryRows = table.querySelectorAll('tbody tr.map-summary-row');

    var presets = {
      mhsds: { report: 'MHSDS-like monthly submission' },
      'local-demand': { report: 'Local demand and access performance pack' },
      'senior-brief': { report: 'Senior performance brief' },
      'pathway-risk': { report: 'Waiting list and pathway risk report' },
      pathwayone: { sourceTable: 'pathwayone_actions' },
      'low-confidence': { confidence: 'Low' },
      'migration-risks': { risk: 'High' },
      'awaiting-signoff': { signOffPartial: true },
      'referral-received': { search: 'referral' },
      'central-fact': { warehouse: 'fact_mh_referral_episode' }
    };

    function val(key) {
      return filters[key] ? filters[key].value : '';
    }

    function signOffMatches(rowSignOff, filterVal) {
      if (!filterVal) return true;
      return (rowSignOff || '') === filterVal;
    }

    function applyFilters(options) {
      options = options || {};
      var search = val('search').toLowerCase().trim();
      var signOffPartial = options.signOffPartial || false;
      var visible = 0;

      summaryRows.forEach(function (row) {
        var detailId = row.getAttribute('data-row-id');
        var detailRow = detailId ? document.getElementById('details-' + detailId) : null;
        var rowSignOff = row.getAttribute('data-sign-off') || '';
        var matchSignOff = signOffPartial
          ? /pending|workshop|withheld|draft|review/i.test(rowSignOff)
          : signOffMatches(rowSignOff, val('signOff'));

        var match = (
          (!val('report') || row.getAttribute('data-report') === val('report')) &&
          (!val('reportField') || row.getAttribute('data-report-field') === val('reportField')) &&
          (!val('reportType') || row.getAttribute('data-report-type') === val('reportType')) &&
          (!val('sourceSystem') || row.getAttribute('data-source-system') === val('sourceSystem')) &&
          (!val('sourceTable') || row.getAttribute('data-source-table') === val('sourceTable')) &&
          (!val('sourceField') || row.getAttribute('data-source-field') === val('sourceField')) &&
          (!val('warehouse') || row.getAttribute('data-warehouse') === val('warehouse')) &&
          (!val('kpi') || row.getAttribute('data-kpi') === val('kpi')) &&
          (!val('nationalLocal') || row.getAttribute('data-national-local') === val('nationalLocal')) &&
          (!val('confidence') || row.getAttribute('data-confidence') === val('confidence')) &&
          matchSignOff &&
          (!val('risk') || row.getAttribute('data-risk') === val('risk')) &&
          (!val('owner') || row.getAttribute('data-owner') === val('owner')) &&
          (!search || row.textContent.toLowerCase().indexOf(search) !== -1)
        );

        row.classList.toggle('hidden', !match);
        if (detailRow) {
          if (!match) {
            detailRow.classList.add('hidden');
            var btn = row.querySelector('.map-details-toggle');
            if (btn) btn.setAttribute('aria-expanded', 'false');
          }
        }
        if (match) visible++;
      });

      if (countEl) {
        countEl.textContent = 'Showing ' + visible + ' of ' + summaryRows.length + ' map rows';
      }
    }

    function clearFilters() {
      Object.keys(filters).forEach(function (key) {
        if (filters[key]) filters[key].value = '';
      });
      applyFilters();
    }

    function setFromObject(obj) {
      clearFilters();
      if (obj.report && filters.report) filters.report.value = obj.report;
      if (obj.reportField && filters.reportField) filters.reportField.value = obj.reportField;
      if (obj.reportType && filters.reportType) filters.reportType.value = obj.reportType;
      if (obj.sourceSystem && filters.sourceSystem) filters.sourceSystem.value = obj.sourceSystem;
      if (obj.sourceTable && filters.sourceTable) filters.sourceTable.value = obj.sourceTable;
      if (obj.sourceField && filters.sourceField) filters.sourceField.value = obj.sourceField;
      if (obj.warehouse && filters.warehouse) filters.warehouse.value = obj.warehouse;
      if (obj.kpi && filters.kpi) filters.kpi.value = obj.kpi;
      if (obj.nationalLocal && filters.nationalLocal) filters.nationalLocal.value = obj.nationalLocal;
      if (obj.confidence && filters.confidence) filters.confidence.value = obj.confidence;
      if (obj.signOff && filters.signOff) filters.signOff.value = obj.signOff;
      if (obj.risk && filters.risk) filters.risk.value = obj.risk;
      if (obj.owner && filters.owner) filters.owner.value = obj.owner;
      if (obj.search && filters.search) filters.search.value = obj.search;
      applyFilters({ signOffPartial: !!obj.signOffPartial });
    }

    Object.keys(filters).forEach(function (key) {
      if (!filters[key]) return;
      var evt = key === 'search' ? 'input' : 'change';
      filters[key].addEventListener(evt, function () { applyFilters(); });
    });

    if (clearBtn) {
      clearBtn.addEventListener('click', clearFilters);
    }

    document.querySelectorAll('.map-preset-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var name = btn.getAttribute('data-preset');
        if (presets[name]) setFromObject(presets[name]);
      });
    });

    table.addEventListener('click', function (e) {
      var btn = e.target.closest('.map-details-toggle');
      if (!btn) return;
      var targetId = btn.getAttribute('data-target');
      var detailRow = targetId ? document.getElementById(targetId) : null;
      if (!detailRow) return;
      var open = !detailRow.classList.contains('hidden');
      table.querySelectorAll('.map-details-row').forEach(function (r) { r.classList.add('hidden'); });
      table.querySelectorAll('.map-details-toggle').forEach(function (b) { b.setAttribute('aria-expanded', 'false'); });
      if (!open) {
        detailRow.classList.remove('hidden');
        btn.setAttribute('aria-expanded', 'true');
      }
    });

    var params = new URLSearchParams(window.location.search);
    if (params.get('preset') && presets[params.get('preset')]) {
      setFromObject(presets[params.get('preset')]);
    } else {
      var fromQuery = {};
      if (params.get('report')) fromQuery.report = params.get('report');
      if (params.get('report_field')) fromQuery.reportField = params.get('report_field');
      if (params.get('source_table')) fromQuery.sourceTable = params.get('source_table');
      if (params.get('source_field')) fromQuery.sourceField = params.get('source_field');
      if (params.get('warehouse')) fromQuery.warehouse = params.get('warehouse');
      if (params.get('kpi')) fromQuery.kpi = params.get('kpi');
      if (params.get('confidence')) fromQuery.confidence = params.get('confidence');
      if (params.get('sign_off')) fromQuery.signOff = params.get('sign_off');
      if (params.get('risk')) fromQuery.risk = params.get('risk');
      if (params.get('owner')) fromQuery.owner = params.get('owner');
      if (params.get('q')) fromQuery.search = params.get('q');
      if (Object.keys(fromQuery).length) {
        setFromObject(fromQuery);
      } else {
        applyFilters();
      }
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    initNavToggle();
    initReturnsFilter();
    initSourceMapFilter();
  });
})();

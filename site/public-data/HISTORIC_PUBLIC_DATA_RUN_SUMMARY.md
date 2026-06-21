# Historic public data run summary

Generated: 2026-06-21 21:09:55

> Public aggregate data only. Not official Dorset HealthCare reporting.
> Human review and local owner confirmation required.

## Sources

### csds_monthly
- Historic download attempted: yes
- Periods downloaded: march-2026; february-2026; january-2026; december-2025; november-2025; october-2025; september-2025; august-2025
- Trend file: trend_csds_activity_rdy.csv
- Trend available: yes
- Trend periods (distinct): 8
- RDY rows stacked: 72
- Manual download needed: no
- Caveats: Provisional CSDS; single ActivityType slice; definition changes possible between months.

### ae_monthly
- Historic download attempted: yes
- Periods downloaded: MSitAE-MAY-2026; MSitAE-APRIL-2026; MSitAE-MARCH-2026; MSitAE-FEBRUARY-2026; MSitAE-JANUARY-2026; MSitAE-DECEMBER-2025; MSitAE-NOVEMBER-2025; MSitAE-OCTOBER-2025; MSitAE-SEPTEMBER-2025; MSitAE-AUGUST-2025; MSitAE-JULY-2025; MSitAE-JUNE-2025
- Trend file: trend_ae_rdy.csv
- Trend available: yes
- Trend periods (distinct): 12
- RDY rows stacked: 36
- Manual download needed: no
- Caveats: Source validation only; zero ED attendances at RDY expected.

### dm01_monthly
- Historic download attempted: yes
- Periods downloaded: DM01-MARCH-2026; DM01-DECEMBER-2024; DM01-FEBRUARY-2025; DM01-JANUARY-2025; DM01-MARCH-2025; DM01-NOVEMBER-2024; DM01-OCTOBER-2024
- Trend file: trend_dm01_rdy.csv
- Trend available: yes
- Trend periods (distinct): 7
- RDY rows stacked: 112
- Manual download needed: no
- Caveats: Provisional DM01; audiology may dominate activity counts.

### kh03_quarterly
- Historic download attempted: yes
- Periods downloaded: 2024-06; 2024-03; 2023-12; 2023-09; 2023-06; 2023-03
- Trend file: trend_kh03_beds_rdy.csv; latest_kh03_beds_rdy.csv
- Trend available: yes
- Trend periods (distinct): 6
- RDY rows stacked: 9078
- Manual download needed: no
- Caveats: Quarterly snapshots; raw file mixes historic dates — trend uses recent quarters only.

### fft_monthly
- Historic download attempted: yes
- Periods downloaded: 
- Trend file: none
- Trend available: no
- Trend periods (distinct): 0
- RDY rows stacked: 0
- Manual download needed: yes
- Caveats: No org-level RDY rows in downloaded FFT summary files.

### mhsds_monthly
- Historic download attempted: yes
- Periods downloaded: performance-april-2026; performance-march-2026; performance-february-2026; performance-january-2026; performance-december-2025; performance-november-2025; performance-october-2025; performance-september-2025
- Trend file: trend_mhsds_access_rdy.csv; trend_mhs23_rdy.csv
- Trend available: yes
- Trend periods (distinct): 8
- RDY rows stacked: 32
- Manual download needed: no
- Caveats: Primary: trend_mhsds_access_rdy.csv (MHS23/MHS01/MHS29/MHS69). MHS23: 8 consecutive month(s), 8 numeric, 0 suppressed, 0 missing — PASS | MHS01: 8 consecutive month(s), 8 numeric, 0 suppressed, 0 missing — PASS | MHS29: 8 consecutive month(s), 8 numeric, 0 suppressed, 0 missing — PASS | MHS69: 8 consecutive month(s), 8 numeric, 0 suppressed, 0 missing — PASS

## Rerun

```bash
Rscript site/public-data/05_download_historic_public_data.R
Rscript site/R/03_render_public_reports.R
```


# Lab: Charts & Dashboard Widgets (React)

## Objectives

- Build a dashboard of chart widgets (line, bar, pie) bound to live/mock API data
- Implement responsive chart resizing without layout thrash
- Add interactive filtering (date range) that updates all widgets together
- Handle empty/loading/error states per widget independently

## Key Concepts

`Recharts/Chart.js` · `responsive container` · `shared date-range filter state` · `per-widget async state` · `tooltip/legend customization`

## Tasks

- [ ] Build a dashboard grid with a line chart (trend), bar chart (comparison), and pie chart (breakdown)
- [ ] Wire all widgets to a shared date-range filter that re-fetches/re-derives their data together
- [ ] Make charts responsive using the library's responsive container without causing resize loops
- [ ] Customize tooltips and legends to match the app's design system
- [ ] Handle each widget's loading/error/empty state independently (one failing widget shouldn't blank the dashboard)
- [ ] Add a 'refresh' action and an auto-refresh interval with cleanup on unmount

## Expected Output

A responsive multi-widget dashboard where changing one date-range filter updates all charts, and one widget's API failure doesn't break the others.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_

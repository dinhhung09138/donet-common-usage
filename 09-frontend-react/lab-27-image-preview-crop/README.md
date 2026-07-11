# Lab: Image Preview, Resize & Crop (React)

## Objectives

- Preview a selected image client-side before upload using object URLs
- Implement client-side image crop/resize before sending bytes to the server
- Compress images client-side to respect an upload size budget
- Build an image gallery with lazy-loaded thumbnails and a lightbox viewer

## Key Concepts

`URL.createObjectURL` · `canvas-based crop/resize` · `client-side compression` · `lazy-loaded <img>` · `lightbox pattern`

## Tasks

- [ ] Show an instant preview of a selected image using `URL.createObjectURL`, revoking it on unmount
- [ ] Implement a crop tool (draggable/resizable crop box) rendering the cropped result to a `<canvas>`
- [ ] Resize/compress the canvas output to fit under a max byte budget before upload
- [ ] Build a thumbnail gallery with `loading="lazy"` and an `IntersectionObserver` fallback
- [ ] Implement a lightbox that opens the full-size image with keyboard (arrow keys, Escape) navigation
- [ ] Verify no memory leak: object URLs are revoked when no longer needed

## Expected Output

An image picker that previews, crops, and compresses an image entirely client-side, feeding a lazy-loaded gallery with a keyboard-navigable lightbox.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_

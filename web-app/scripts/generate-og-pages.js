// Post-build script: generates route-specific HTML files with custom OG tags.
// Run automatically after `vite build` via the build script in package.json.
import { readFileSync, writeFileSync } from 'fs';

const portals = [
  {
    output: 'dist/portal-93.html',
    title: 'Capital HS',
    description: '20yr Reunion!',
    image: 'https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/93_d16d340de3ec4f5594267a55b33a8656_portal_image_0.jpg',
    url: 'https://www.repsomething.com/portal/93',
  },
];

const base = readFileSync('dist/index.html', 'utf-8');

for (const p of portals) {
  const html = base
    .replace(/(<meta property="og:title" content=")[^"]*(")/,       `$1${p.title}$2`)
    .replace(/(<meta property="og:image" content=")[^"]*(")/,       `$1${p.image}$2`)
    .replace(/(<meta property="og:description" content=")[^"]*(")/,  `$1${p.description}$2`)
    .replace(/(<meta property="og:url" content=")[^"]*(")/,         `$1${p.url}$2`)
    .replace(/(<meta name="twitter:title" content=")[^"]*(")/,       `$1${p.title}$2`)
    .replace(/(<meta name="twitter:image" content=")[^"]*(")/,       `$1${p.image}$2`)
    .replace(/(<meta name="twitter:description" content=")[^"]*(")/,  `$1${p.description}$2`)
    .replace(/(<title>)[^<]*(<\/title>)/,                            `$1${p.title}$2`);

  writeFileSync(p.output, html);
  console.log(`Generated ${p.output}`);
}

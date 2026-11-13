#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'build', 'offline');
const OUT_FILE = path.join(OUT_DIR, '大创新手教程.html');
const MARKED = path.join(ROOT, 'build', 'tools', 'marked.min.js');

if (!fs.existsSync(MARKED)) {
  console.error(`缺少 ${path.relative(ROOT, MARKED)}`);
  console.error('请先执行（PowerShell）:');
  console.error('  New-Item -ItemType Directory -Force build\\tools | Out-Null');
  console.error('  Invoke-WebRequest https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js -OutFile build\\tools\\marked.min.js');
  process.exit(1);
}

const require = createRequire(import.meta.url);
const markedLib = require(MARKED);
const marked = markedLib.parse ? markedLib : markedLib.marked;

const GROUPS = [
  {
    title: '开始',
    files: ['README.md', 'plan.md', 'AGENTS.md'],
  },
  {
    title: '新手必读',
    files: [
      'docs/00_新队友阅读顺序.md',
      'docs/workflow.md',
      'docs/16_基础补齐清单.md',
      'docs/04_GitHub与Git一天上手指南.md',
      'docs/07_新手使用Agent教程.md',
    ],
  },
  {
    title: '方向与技术路线',
    files: [
      'docs/01_田静老师资料与研究方向.md',
      'docs/08_HQC技术路线.md',
      'docs/09_工程约束与验证规范.md',
      'docs/10_团队分工与国家级指标.md',
      'docs/11_组内基线与差异表.md',
      'docs/12_FPGA_ASIC路线.md',
      'docs/13_开工清单与近期任务.md',
      'docs/14_总体工作计划.md',
      'docs/17_IP工程化交付清单.md',
      'docs/18_两周开工计划_2026-11-13.md',
      'docs/03_前置知识与学习路线.md',
      'docs/05_前置知识补全_从数电到Verilog实战.md',
    ],
  },
  {
    title: '接口契约',
    files: [
      'docs/contracts/README.md',
      'docs/contracts/hqc_kem_v0.md',
      'docs/contracts/poly_mult_v0.md',
      'docs/contracts/sha3_v0.md',
      'docs/contracts/rs_codec_v0.md',
      'docs/contracts/sparse_qc_mult_v0.md',
      'docs/contracts/rm_decoder_v0.md',
      'docs/contracts/axi_mmio_v0.md',
    ],
  },
  {
    title: '协作与纪录',
    files: [
      'docs/06_协作纪录与技能提炼规范.md',
      'report/llm_log/RECORDS-README.md',
      'report/llm_log/TEMPLATE.md',
      'report/llm_log/EXAMPLE-record.md',
    ],
  },
];

const allFiles = GROUPS.flatMap((g) => g.files);
for (const rel of allFiles) {
  if (!fs.existsSync(path.join(ROOT, rel))) {
    console.error(`找不到文件: ${rel}`);
    process.exit(1);
  }
}

const relToId = new Map(allFiles.map((rel, i) => [rel, `sec-${i}`]));

function rewriteLinksOutsideCode(md, transform) {
  const parts = md.split(/(```[\s\S]*?```)/);
  return parts.map((part, i) => (i % 2 === 1 ? part : transform(part))).join('');
}

function resolveMdLinks(md, curRel) {
  return rewriteLinksOutsideCode(md, (text) =>
    text.replace(/\]\(([^)\s]+)\)/g, (whole, href) => {
      if (/^(https?:|mailto:|#)/i.test(href)) return whole;
      const hash = href.indexOf('#');
      const raw = hash >= 0 ? href.slice(0, hash) : href;
      const frag = hash >= 0 ? href.slice(hash) : '';
      if (!raw) return whole;
      const target = path.posix.normalize(
        path.posix.join(path.posix.dirname(curRel), raw)
      );
      const id = relToId.get(target);
      if (!id) return whole;
      const keepFrag = target === curRel ? frag : '';
      return `](#${id}${keepFrag})`;
    })
  );
}

const esc = (s) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const navItems = [];
const sections = [];
const stats = [];
let index = 0;

for (const group of GROUPS) {
  const items = [];
  for (const rel of group.files) {
    const id = relToId.get(rel);
    const raw = fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/^\uFEFF/, '');
    const title = (raw.match(/^#\s+(.+)$/m) || [, path.basename(rel, '.md')])[1].trim();
    const body = resolveMdLinks(raw, rel);
    let html = marked.parse(body, { gfm: true, breaks: false });
    html = html.replace(
      /<a href="(https?:[^"]+)"/g,
      '<a href="$1" target="_blank" rel="noopener noreferrer"'
    );
    sections.push(
      `<section class="doc" id="${id}" data-title="${esc(title)}">\n` +
        `<div class="doc-meta">${esc(rel)}</div>\n${html}\n</section>`
    );
    items.push({ id, title, rel });
    stats.push({ rel, bytes: Buffer.byteLength(raw) });
    index += 1;
  }
  navItems.push({ title: group.title, items });
}

const totalBytes = stats.reduce((n, s) => n + s.bytes, 0);
const builtAt = new Date().toLocaleString('zh-CN', { hour12: false });

const navHtml = navItems
  .map(
    (g) =>
      `<div class="group-title">${esc(g.title)}</div>\n` +
      g.items
        .map(
          (it) =>
            `<a class="nav-link" href="#${it.id}" data-title="${esc(it.title)}">${esc(
              it.title
            )}</a>`
        )
        .join('\n')
  )
  .join('\n');

const html = `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>大创新手教程（离线版）</title>
<style>
  :root {
    --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --line: #d1d9e0;
    --accent: #0969da; --code-bg: #f6f8fa; --side-bg: #f6f8fa; --mark: #fff8c5;
  }
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    margin: 0; color: var(--fg); background: var(--bg);
    font: 16px/1.75 -apple-system, "Segoe UI", "Microsoft YaHei", "PingFang SC", sans-serif;
  }
  #layout { display: flex; align-items: flex-start; }
  #sidebar {
    position: sticky; top: 0; height: 100vh; width: 300px; flex: none;
    overflow-y: auto; background: var(--side-bg); border-right: 1px solid var(--line);
    padding: 18px 14px 40px;
  }
  .brand { font-weight: 700; font-size: 17px; line-height: 1.35; }
  .brand span { display: block; font-weight: 400; font-size: 12px; color: var(--muted); margin-top: 4px; }
  #filter {
    width: 100%; margin: 14px 0 10px; padding: 7px 10px; font: inherit; font-size: 14px;
    border: 1px solid var(--line); border-radius: 6px; background: #fff; color: var(--fg);
  }
  #filter:focus { outline: 2px solid var(--accent); outline-offset: -1px; }
  .group-title {
    margin: 18px 6px 6px; font-size: 12px; font-weight: 700; letter-spacing: .06em;
    color: var(--muted); text-transform: uppercase;
  }
  .nav-link {
    display: block; padding: 6px 10px; margin: 1px 0; border-radius: 6px;
    color: var(--fg); text-decoration: none; font-size: 14px; line-height: 1.45;
  }
  .nav-link:hover { background: #eaeef2; }
  .nav-link.active { background: #ddf4ff; color: var(--accent); font-weight: 600; }
  .nav-link.hidden { display: none; }
  .group-title.hidden { display: none; }
  .side-foot { margin: 22px 6px 0; font-size: 12px; color: var(--muted); line-height: 1.6; }
  main { flex: 1; min-width: 0; padding: 30px 48px 90px; }
  .doc { max-width: 900px; margin: 0 auto 70px; padding-bottom: 30px; border-bottom: 1px solid var(--line); scroll-margin-top: 16px; }
  .doc:last-child { border-bottom: none; }
  .doc-meta { font-size: 12px; color: var(--muted); font-family: ui-monospace, Consolas, monospace; margin-bottom: 8px; }
  h1, h2, h3, h4 { line-height: 1.35; margin: 1.4em 0 .6em; }
  h1 { font-size: 1.9em; margin-top: .2em; }
  h2 { font-size: 1.45em; padding-bottom: .3em; border-bottom: 1px solid var(--line); }
  h3 { font-size: 1.18em; }
  p, ul, ol, table, pre, blockquote { margin: .8em 0; }
  a { color: var(--accent); }
  code { background: var(--code-bg); padding: .15em .35em; border-radius: 4px; font-size: .9em;
    font-family: ui-monospace, SFMono-Regular, Consolas, "Liberation Mono", monospace; }
  pre { background: var(--code-bg); padding: 14px 16px; border-radius: 8px; overflow-x: auto; line-height: 1.55; }
  pre code { background: none; padding: 0; font-size: .88em; }
  blockquote { margin-left: 0; padding: .2em 1em; color: var(--muted); border-left: 4px solid var(--line); }
  table { border-collapse: collapse; display: block; overflow-x: auto; max-width: 100%; }
  th, td { border: 1px solid var(--line); padding: 6px 12px; text-align: left; vertical-align: top; }
  th { background: var(--code-bg); }
  tr:nth-child(2n) td { background: #fbfcfd; }
  hr { border: 0; border-top: 1px solid var(--line); margin: 2em 0; }
  img { max-width: 100%; }
  input[type="checkbox"] { margin-right: .4em; }
  #top {
    position: fixed; right: 22px; bottom: 22px; z-index: 10;
    border: 1px solid var(--line); background: #fff; color: var(--fg);
    border-radius: 999px; padding: 8px 14px; cursor: pointer; font: inherit; font-size: 13px;
    box-shadow: 0 4px 14px rgba(0,0,0,.08);
  }
  #top:hover { background: var(--side-bg); }
  .mark { background: var(--mark); }
  @media (max-width: 900px) {
    #sidebar { position: static; width: 100%; height: auto; max-height: 45vh; border-right: 0; border-bottom: 1px solid var(--line); }
    #layout { display: block; }
    main { padding: 20px 18px 70px; }
  }
  @media print {
    #sidebar, #top, #filter { display: none !important; }
    main { padding: 0; }
    .doc { max-width: none; break-after: page; border-bottom: none; }
    .doc:last-child { break-after: auto; }
  }
</style>
</head>
<body>
<div id="layout">
  <aside id="sidebar">
    <div class="brand">大创 · 新手教程<span>离线版 · 无需 GitHub 账号 · 双击即可阅读</span></div>
    <input id="filter" type="search" placeholder="搜索标题…">
    <nav id="nav">
${navHtml}
    </nav>
    <div class="side-foot">
      共 ${allFiles.length} 篇文档，${(totalBytes / 1024).toFixed(1)} KB<br>
      生成时间：${esc(builtAt)}<br>
      来源：dachuang 仓库 docs/
    </div>
  </aside>
  <main id="main">
${sections.join('\n')}
  </main>
</div>
<button id="top" type="button">回到顶部</button>
<script>
(function () {
  var input = document.getElementById('filter');
  var links = Array.prototype.slice.call(document.querySelectorAll('.nav-link'));
  var groups = Array.prototype.slice.call(document.querySelectorAll('.group-title'));
  function applyFilter() {
    var q = input.value.trim().toLowerCase();
    links.forEach(function (a) {
      a.classList.toggle('hidden', q !== '' && a.textContent.toLowerCase().indexOf(q) === -1);
    });
    groups.forEach(function (g) {
      var any = false, n = g.nextElementSibling;
      while (n && n.classList.contains('nav-link')) {
        if (!n.classList.contains('hidden')) { any = true; break; }
        n = n.nextElementSibling;
      }
      g.classList.toggle('hidden', !any);
    });
  }
  input.addEventListener('input', applyFilter);

  var byId = {};
  links.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      links.forEach(function (a) { a.classList.remove('active'); });
      var a = byId[e.target.id];
      if (a) a.classList.add('active');
    });
  }, { rootMargin: '0px 0px -70% 0px', threshold: 0 });
  document.querySelectorAll('section.doc').forEach(function (s) { observer.observe(s); });

  document.getElementById('top').addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault(); input.focus(); input.select();
    }
  });
})();
</script>
</body>
</html>
`;

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(OUT_FILE, html, 'utf8');
console.log(`OK  ${path.relative(ROOT, OUT_FILE)}`);
console.log(`    ${allFiles.length} 篇文档, ${(Buffer.byteLength(html) / 1024).toFixed(1)} KB`);

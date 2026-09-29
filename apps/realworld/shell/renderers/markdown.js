// Pure Tier 2 Markdown Renderer for Realworld (authored in Jessie)
// Takes markdown text source and outputs JsonML DOM node structure.

const INLINE = new RegExp(
  [
    "(?<ticks>`+)(?<code>[\\s\\S]*?)\\k<ticks>",
    "(?<bang>!?)\\[(?<label>[^\\]\\n]*)\\]\\((?<url>[^()\\[\\]\\s]{0,2048})\\)",
    "\\*\\*(?<strong>[\\s\\S]+?)\\*\\*",
    "\\*(?<em>[^*\\n]+?)\\*",
    "_(?<under>[^_\\n]+?)_",
  ].join("|"),
  "g"
);

const MAX_NEST = 32;

// A compartment endows nothing (jessie.js ROLES.renderer), and URL is a host
// global rather than an ECMAScript intrinsic — so the scheme is read off the
// text. RFC 3986's grammar, anchored: anything that does not match one is a
// relative reference, which the page's own origin already bounds.
const SCHEME = /^([a-z][a-z0-9+.\-]*):/i;
const SAFE = ["http", "https", "mailto"];

function safeUrl(raw) {
  if (!raw) return null;
  const str = String(raw).trim();
  if (str.startsWith("/") || str.startsWith("#") || str.startsWith("//")) return str;
  const scheme = SCHEME.exec(str);
  if (scheme === null) return str;
  return SAFE.includes(scheme[1].toLowerCase()) ? str : null;
}

function pushText(out, text) {
  if (text === "") return;
  const lines = text.split("\n");
  for (let i = 0; i < lines.length; i++) {
    if (i > 0) out.push({ tag: "br" });
    if (lines[i] !== "") out.push(lines[i]);
  }
}

const wrap = (tag, content, depth) => ({ tag, children: inline(content, depth + 1) });

function inline(text, depth = 0) {
  const out = [];
  if (depth >= MAX_NEST) {
    pushText(out, text);
    return out;
  }
  let last = 0;
  for (const m of text.matchAll(INLINE)) {
    const g = m.groups;
    if (g.under !== undefined && m.index > 0 && /\w/.test(text[m.index - 1])) continue;
    pushText(out, text.slice(last, m.index));
    last = m.index + m[0].length;
    if (g.code !== undefined) {
      out.push({ tag: "code", children: [g.code.trim()] });
    } else if (g.label !== undefined) {
      const url = safeUrl(g.url);
      if (url === null) pushText(out, m[0]);
      else if (g.bang === "!") out.push({ tag: "img", attrs: { src: url, alt: g.label } });
      else out.push({ tag: "a", attrs: { href: url }, children: inline(g.label, depth + 1) });
    } else if (g.strong !== undefined) out.push(wrap("strong", g.strong, depth));
    else out.push(wrap("em", g.em ?? g.under, depth));
  }
  pushText(out, text.slice(last));
  return out;
}

const FENCE = /^ {0,3}```/;
const RULE = /^ {0,3}([-*_])(?: *\1){2,} *$/;
const HEADING = /^ {0,3}(#{1,6}) +(.*)$/;
const QUOTE = /^ {0,3}>/;
const BULLET = /^ {0,3}[-*] +(.*)$/;
const NUMBER = /^ {0,3}\d+\. +(.*)$/;

const startsBlock = (line) =>
  FENCE.test(line) || RULE.test(line) || HEADING.test(line) || QUOTE.test(line) ||
  BULLET.test(line) || NUMBER.test(line);

function parseBlocks(lines, depth = 0) {
  const out = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === "") {
      i++;
    } else if (FENCE.test(line)) {
      i++;
      const body = [];
      while (i < lines.length && !FENCE.test(lines[i])) body.push(lines[i++]);
      i++;
      out.push({ tag: "pre", children: [{ tag: "code", children: [body.join("\n")] }] });
    } else if (RULE.test(line)) {
      out.push({ tag: "hr" });
      i++;
    } else if (HEADING.test(line)) {
      const [, hashes, content] = HEADING.exec(line);
      out.push(wrap(`h${hashes.length}`, content.replace(/ +#+ *$/, "").trim(), depth));
      i++;
    } else if (QUOTE.test(line)) {
      const body = [];
      while (i < lines.length && QUOTE.test(lines[i])) body.push(lines[i++].replace(/^ {0,3}> ?/, ""));
      out.push({ tag: "blockquote", children: depth >= MAX_NEST ? [body.join("\n")] : parseBlocks(body, depth + 1) });
    } else if (BULLET.test(line) || NUMBER.test(line)) {
      const item = BULLET.test(line) ? BULLET : NUMBER;
      const children = [];
      while (i < lines.length && item.test(lines[i])) {
        const body = [item.exec(lines[i++])[1]];
        while (i < lines.length && lines[i].trim() !== "" && !startsBlock(lines[i])) {
          body.push(lines[i++].trim());
        }
        children.push(wrap("li", body.join("\n"), depth));
      }
      out.push({ tag: item === NUMBER ? "ol" : "ul", children });
    } else {
      const body = [];
      while (i < lines.length && lines[i].trim() !== "" && !startsBlock(lines[i])) body.push(lines[i++]);
      out.push(wrap("p", body.join("\n").trim(), depth));
    }
  }
  return out;
}

// The compartment evaluates this file as a script and takes its completion
// value as the render function, so nothing here may be an ES module.
function parseMarkdown(source) {
  const text = source == null ? "" : String(source);
  return parseBlocks(text.replace(/\r\n?/g, "\n").split("\n"));
}

parseMarkdown;

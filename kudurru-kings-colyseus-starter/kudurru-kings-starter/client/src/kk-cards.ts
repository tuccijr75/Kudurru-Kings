/* Kudurru Kings — Card Upgrader
   - Wraps any existing card node and renders a 3D flip (front stats / back rules)
   - Click = flip, Double-click = "PLAY_CARD" event + room.send("action",…)
   - Non-destructive: keeps layout, measures current node box
   - Works off data-* attributes that already exist on your DOM
*/

type KkAspects = { stone?: number; wind?: number; veil?: number; oath?: number; eye?: number };
type KkCardData = {
  id?: string;
  name?: string;
  type?: string;
  rank?: string;
  rarity?: string;
  faction?: string;
  rules?: string;
  weight?: number;
  sigil?: number;
  sinew?: number;
  oath?: number;
  upkeep?: number;
  aspects?: KkAspects;
  art?: string;
};

const W:any = window as any;
const onceFlag = 'kkUpgraded';
const selectors = '[data-card],[data-card-id],.card,.kk-card';

function readInt(v?: string | null): number | undefined {
  if (v == null) return undefined;
  const n = parseInt(String(v), 10);
  return Number.isFinite(n) ? n : undefined;
}

function readAspects(el: HTMLElement): KkAspects {
  const d = el.dataset;
  try {
    if (d.aspects) {
      const j = JSON.parse(d.aspects);
      return {
        stone: Number(j.stone ?? j.Stone ?? j.S ?? j.s),
        wind:  Number(j.wind  ?? j.Wind  ?? j.W ?? j.w),
        veil:  Number(j.veil  ?? j.Veil  ?? j.V ?? j.v),
        oath:  Number(j.oath  ?? j.Oath  ?? j.O ?? j.o),
        eye:   Number(j.eye   ?? j.Eye   ?? j.E ?? j.e),
      };
    }
  } catch {}
  return {
    stone: readInt(d.asStone ?? d.stone),
    wind:  readInt(d.asWind  ?? d.wind),
    veil:  readInt(d.asVeil  ?? d.veil),
    oath:  readInt(d.asOath  ?? d.oath),
    eye:   readInt(d.asEye   ?? d.eye),
  };
}

function readCardData(el: HTMLElement): KkCardData {
  const d = el.dataset;
  return {
    id:      d.cardId ?? d.id ?? el.getAttribute('data-id') ?? undefined,
    name:    d.cardName ?? d.name ?? el.getAttribute('data-name') ?? 'Card',
    type:    d.cardType ?? d.type ?? el.getAttribute('data-type') ?? 'Character',
    rank:    d.rank ?? d.rarity ?? undefined,
    rarity:  d.rarity ?? d.rank ?? undefined,
    faction: d.faction ?? undefined,
    rules:   d.rules ?? d.text ?? undefined,
    weight:  readInt(d.weight) ?? readInt(d.sinewWeight) ?? undefined,
    sigil:   readInt(d.sigil) ?? undefined,
    sinew:   readInt(d.sinew) ?? undefined,
    oath:    readInt(d.oath)  ?? undefined,
    upkeep:  readInt(d.upkeep ?? d.oathUpkeep) ?? undefined,
    aspects: readAspects(el),
    art:     d.art ?? undefined,
  };
}

function injectCssOnce() {
  if (document.getElementById('kk-card-css')) return;
  const css = `
  .kk3d { position: relative; width:100%; height:100%; perspective: 1200px; }
  .kk3d-inner{ position:absolute; inset:0; transform-style:preserve-3d; transition: transform .45s ease; }
  .kk3d.flipped .kk3d-inner{ transform: rotateY(180deg); }
  .kkface{ position:absolute; inset:0; backface-visibility:hidden; border-radius:.9rem; overflow:hidden;
           background: radial-gradient(120% 85% at 50% 15%, rgba(255,232,168,.12), rgba(22,18,6,.6)),
                       linear-gradient(#182028,#0d0f12);
           box-shadow: 0 1px 0 rgba(255,214,101,.25) inset, 0 0 0 2px rgba(214,180,98,.18), 0 10px 35px rgba(0,0,0,.45);
           color:#d7cab0; font: 13px/1.25 ui-sans-serif, system-ui, Segoe UI, Roboto, Helvetica, Arial;
  }
  .kkface.back{ transform: rotateY(180deg); }
  .kkart{ position:absolute; left:10%; right:10%; top:9%; bottom:38%; border-radius:999px; background: #0b0b0c center/cover no-repeat; }
  .kkhdr{ position:absolute; left:8%; right:8%; top:4.5%; text-align:center; font-weight:700; letter-spacing:.3px; }
  .kkname{ font-size: 1.05rem; text-shadow: 0 1px 0 #000; }
  .kkstrap{ position:absolute; left:8%; right:8%; bottom:37%; text-align:center; font-weight:700; padding:.25rem 0;
            background: linear-gradient(180deg,rgba(38,33,18,.85),rgba(22,18,6,.85));
            border:1px solid rgba(214,180,98,.45); border-radius:.5rem; }
  .kksub{ opacity:.85; font-size:.78rem; margin-top:.15rem }
  .kkpips{ position:absolute; left:8%; right:8%; bottom:29%; display:flex; gap:.4rem; justify-content:center; }
  .kkpip{ display:inline-flex; align-items:center; gap:.18rem; padding:.15rem .4rem; border-radius:.5rem;
          background: rgba(18,16,10,.6); border:1px solid rgba(214,180,98,.25); font-size:.76rem; }
  .kkpip em{ font-style:normal; opacity:.8 }
  .kkbox{ position:absolute; left:7%; right:7%; bottom:7%; top:62%; padding:.6rem .75rem; overflow:auto;
          background: rgba(12,10,6,.42); border:1px solid rgba(214,180,98,.25); border-radius:.65rem; }
  .kkbox b{ color:#ffe2a8 }
  .kkfooter{ position:absolute; right:7%; bottom:8%; font-size:.75rem; opacity:.8 }
  .kktype{ position:absolute; left:7%; bottom:8%; font-size:.75rem; opacity:.9 }
  .kkhint{ position:absolute; right:10px; top:8px; font-size:.72rem; opacity:.55 }
  .kk3d:focus-within, .kk3d:hover{ box-shadow: 0 1px 0 rgba(255,214,101,.3) inset, 0 0 0 2px rgba(214,180,98,.35), 0 12px 38px rgba(0,0,0,.55); }
  `;
  const st = document.createElement('style');
  st.id = 'kk-card-css';
  st.textContent = css;
  document.head.appendChild(st);
}

function makeFaceFront(data: KkCardData): HTMLElement {
  const f = document.createElement('div'); f.className = 'kkface front';
  const name = data.name ?? 'Card';
  const type = data.type ?? 'Character';
  const rank = (data.rarity ?? data.rank ?? '').trim();
  const aspects = data.aspects ?? {};
  const artUrl = data.art ? `url("${data.art}")` : '';

  f.innerHTML = `
    <div class="kkhdr"><div class="kkname">${name}</div></div>
    <div class="kkart" style="${artUrl ? `background-image:${artUrl};` : ''}"></div>
    <div class="kkstrap">${type}${rank ? ` — <span class="kksub">${rank}</span>` : ''}</div>
    <div class="kkpips">
      ${['stone','wind','veil','oath','eye'].map(k => {
        const v = Number((aspects as any)[k] ?? 0);
        if (!v) return '';
        const label = k[0].toUpperCase() + k.slice(1);
        return `<span class="kkpip"><b>${v}</b> <em>${label}</em></span>`;
      }).join('')}
    </div>
    <div class="kkhint">click = flip · dbl-click = play</div>
  `;
  return f;
}

function makeFaceBack(data: KkCardData): HTMLElement {
  const b = document.createElement('div'); b.className = 'kkface back';
  const upkeep = (data.upkeep ?? 0) > 0 ? `<br/><b>Oath Upkeep ${data.upkeep}</b>` : '';
  const costBits: string[] = [];
  if (data.weight) costBits.push(`Sinew ${data.weight}`);
  if (data.sigil)  costBits.push(`Sigil ${data.sigil}`);
  if (data.oath)   costBits.push(`Oath ${data.oath}`);
  const costs = costBits.length ? `<b>Costs:</b> ${costBits.join(' · ')}<br/>` : '';
  b.innerHTML = `
    <div class="kkbox">
      ${costs}
      ${data.rules ? data.rules : '<em>No rules text.</em>'}
      ${upkeep}
    </div>
    <div class="kktype">${data.type ?? ''}${data.faction ? ` · ${data.faction}` : ''}</div>
    <div class="kkfooter">${(data.rarity ?? data.rank) ?? ''}</div>
  `;
  return b;
}

function buildShell(el: HTMLElement, data: KkCardData) {
  const w = el.clientWidth || 220;
  const h = el.clientHeight || 320;
  if (!getComputedStyle(el).position || getComputedStyle(el).position === 'static') {
    el.style.position = 'relative';
  }
  el.style.minWidth = w + 'px';
  el.style.minHeight = h + 'px';

  const root = document.createElement('div'); root.className = 'kk3d'; root.tabIndex = 0;
  root.style.width = '100%'; root.style.height = '100%';
  const inner = document.createElement('div'); inner.className = 'kk3d-inner';

  inner.appendChild(makeFaceFront(data));
  inner.appendChild(makeFaceBack(data));
  root.appendChild(inner);
  el.appendChild(root);

  root.addEventListener('click', (ev) => {
    if ((ev.target as HTMLElement).closest('a,button,input,textarea,select')) return;
    root.classList.toggle('flipped');
  });

  root.addEventListener('dblclick', (ev) => {
    ev.preventDefault();
    const payload = { type: 'PLAY_CARD', id: data.id, meta: { cardType: data.type, weight: data.weight, sigil: data.sigil, oath: data.oath } };
    el.dispatchEvent(new CustomEvent('kk:play-card', { bubbles: true, detail: payload }));
    try { (W.KK?.room as any)?.send?.('action', payload); } catch {}
  });
}

function upgradeOne(el: HTMLElement) {
  if ((el as any)[onceFlag]) return;
  (el as any)[onceFlag] = true;
  injectCssOnce();
  buildShell(el, readCardData(el));
}

function scanAll() {
  document.querySelectorAll<HTMLElement>(selectors).forEach(upgradeOne);
}

function watchMutations() {
  const mo = new MutationObserver((muts) => {
    for (const m of muts) {
      m.addedNodes.forEach(n => {
        if (!(n instanceof HTMLElement)) return;
        if (n.matches?.(selectors)) upgradeOne(n);
        n.querySelectorAll?.(selectors)?.forEach((c) => upgradeOne(c as HTMLElement));
      });
    }
  });
  mo.observe(document.documentElement, { childList: true, subtree: true });
}

(W as any).KK = W.KK || {};
(W as any).KK.upgradeCards = scanAll;

requestAnimationFrame(() => { scanAll(); watchMutations(); });

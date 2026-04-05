/* Kudurru Kings — seat label updater (non-intrusive) */
(() => {
  if ((window as any).__KK_UI_SEATS__) return; (window as any).__KK_UI_SEATS__ = true;
  const W:any = window as any;
  const getRoom = () => W.KK?.room || null;

  function renameSeats(names?: string[]) {
    if (!names?.length) return;
    const nodes = Array.from(document.querySelectorAll<HTMLElement>("*"));
    ["P1","P2","P3","P4"].forEach((tag, i) => {
      const seat = nodes.find(n => (n.textContent || "").trim() === tag);
      if (seat) seat.textContent = names[i] || tag;
    });
  }

  function bind() {
    const r = getRoom(); if (!r) return;
    r.onMessage("ui", (p:any) => renameSeats(p?.names));
  }

  const iv = setInterval(() => { if (getRoom()) { clearInterval(iv); bind(); } }, 250);
})();

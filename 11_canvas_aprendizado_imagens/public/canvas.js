(() => {
  const canvas = document.getElementById('sketch');
  const context = canvas.getContext('2d', { willReadFrequently: true });
  const brush = document.getElementById('brush');
  const identify = document.getElementById('identify');
  const teach = document.getElementById('teach');
  const clear = document.getElementById('clear');
  const undo = document.getElementById('undo');
  const label = document.getElementById('label');
  const feedback = document.getElementById('feedback');
  const hint = document.getElementById('canvas-hint');
  const result = document.getElementById('result');
  const resultPanel = document.querySelector('.result-panel');
  const fileInput = document.getElementById('image-file');
  const downloadPng = document.getElementById('download-png');
  const downloadSvg = document.getElementById('download-svg');
  const paper = document.querySelector('.paper');
  const pretrain = document.getElementById('pretrain');
  const resetTraining = document.getElementById('reset-training');
  const trainingProgress = document.getElementById('training-progress');
  let busy = false, drawing = false, hasInk = false, lastPoint = null, activePointer = null;
  const snapshots = [];

  const tabs = [...document.querySelectorAll('.workspace-tabs [role="tab"]')];
  function selectTab(selected) {
    if (drawing) return;
    tabs.forEach(tab => {
      const active = tab === selected;
      tab.setAttribute('aria-selected', String(active));
      tab.tabIndex = active ? 0 : -1;
      document.getElementById(tab.getAttribute('aria-controls')).hidden = !active;
    });
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => selectTab(tab));
    tab.addEventListener('keydown', event => {
      let next;
      if (event.key === 'ArrowRight') next = tabs[(index + 1) % tabs.length];
      if (event.key === 'ArrowLeft') next = tabs[(index + tabs.length - 1) % tabs.length];
      if (event.key === 'Home') next = tabs[0];
      if (event.key === 'End') next = tabs[tabs.length - 1];
      if (!next || drawing) return;
      event.preventDefault();
      selectTab(next); next.focus();
    });
  });

  function whiteboard() { context.fillStyle = '#fff'; context.fillRect(0, 0, canvas.width, canvas.height); }
  whiteboard();
  function controls() {
    identify.disabled = teach.disabled = clear.disabled = busy || !hasInk || drawing;
    undo.disabled = busy || drawing || snapshots.length === 0;
    brush.disabled = label.disabled = busy || drawing;
    fileInput.disabled = busy || drawing;
    downloadPng.disabled = downloadSvg.disabled = busy || drawing || !hasInk;
    document.querySelectorAll('.label-chip').forEach(button => button.disabled = busy || drawing);
    pretrain.disabled = resetTraining.disabled = busy || drawing;
    canvas.classList.toggle('busy', busy);
    hint.hidden = hasInk;
    identify.textContent = busy ? 'Processando…' : 'Identificar meu desenho ↗';
  }
  function showError(message) { feedback.textContent = message; feedback.hidden = false; }
  function showResult(title, text, kind = '', symbol = '?') {
    resultPanel.className = `result-panel ${kind}`;
    result.replaceChildren();
    const icon = document.createElement('div'); icon.className = 'result-symbol'; icon.textContent = symbol;
    const heading = document.createElement('h2'); heading.id = 'result-title'; heading.textContent = title;
    const description = document.createElement('p'); description.textContent = text;
    result.append(icon, heading, description);
    document.getElementById('matches').replaceChildren();
  }
  function changed() {
    feedback.hidden = true;
    showResult('Desenho atualizado', 'Clique em identificar para comparar esta imagem com os exemplos aprendidos.');
  }
  function idle() {
    feedback.hidden = true;
    showResult('Vamos aprender juntos?', 'Ainda não vi este desenho. Faça uma forma no quadro e peça para identificar.');
  }
  function point(event) {
    const rect = canvas.getBoundingClientRect();
    return { x: (event.clientX - rect.left) * canvas.width / rect.width, y: (event.clientY - rect.top) * canvas.height / rect.height };
  }
  canvas.addEventListener('pointerdown', event => {
    if (busy || drawing || (event.pointerType === 'mouse' && event.button !== 0)) return;
    event.preventDefault();
    canvas.focus({ preventScroll: true });
    snapshots.push({ data: context.getImageData(0, 0, canvas.width, canvas.height), hasInk });
    if (snapshots.length > 20) snapshots.shift();
    canvas.setPointerCapture(event.pointerId);
    drawing = true; activePointer = event.pointerId; hasInk = true; lastPoint = point(event);
    context.fillStyle = '#292d3d'; context.beginPath(); context.arc(lastPoint.x, lastPoint.y, Number(brush.value) / 2, 0, Math.PI * 2); context.fill();
    changed(); controls();
  });
  canvas.addEventListener('pointermove', event => {
    if (!drawing || event.pointerId !== activePointer) return;
    const next = point(event);
    context.strokeStyle = '#292d3d'; context.lineWidth = Number(brush.value); context.lineCap = 'round'; context.lineJoin = 'round';
    context.beginPath(); context.moveTo(lastPoint.x, lastPoint.y); context.lineTo(next.x, next.y); context.stroke(); lastPoint = next;
  });
  function endStroke(event) { if (drawing && event.pointerId === activePointer) { drawing = false; activePointer = null; lastPoint = null; controls(); } }
  canvas.addEventListener('pointerup', endStroke);
  canvas.addEventListener('pointercancel', endStroke);
  canvas.addEventListener('lostpointercapture', endStroke);
  brush.addEventListener('input', () => document.getElementById('brush-size').textContent = brush.value);
  clear.addEventListener('click', () => {
    if (busy || drawing) return;
    snapshots.push({ data: context.getImageData(0, 0, canvas.width, canvas.height), hasInk });
    if (snapshots.length > 20) snapshots.shift();
    whiteboard(); hasInk = false; idle(); controls();
  });
  undo.addEventListener('click', () => {
    if (busy || drawing || !snapshots.length) return;
    const snapshot = snapshots.pop(); context.putImageData(snapshot.data, 0, 0); hasInk = snapshot.hasInk; changed(); controls();
  });
  document.querySelectorAll('.label-chip').forEach(button => button.addEventListener('click', () => { label.value = button.dataset.label; label.focus(); }));

  async function importFile(file) {
    if (busy || drawing || !file) return;
    busy = true; controls(); feedback.hidden = true;
    try {
      const image = await SketchImageIO.load(file);
      // Prepara fora do canvas atual. Uma falha não apaga o desenho anterior.
      const staging = document.createElement('canvas'); staging.width = canvas.width; staging.height = canvas.height;
      const staged = staging.getContext('2d'); staged.fillStyle = '#fff'; staged.fillRect(0, 0, staging.width, staging.height);
      const scale = Math.min((staging.width - 64) / image.naturalWidth, (staging.height - 64) / image.naturalHeight);
      const width = image.naturalWidth * scale, height = image.naturalHeight * scale;
      staged.drawImage(image, (staging.width - width) / 2, (staging.height - height) / 2, width, height);
      // Verifica se os pixels podem ser lidos antes de substituir o quadro.
      staged.getImageData(0, 0, 1, 1);
      snapshots.push({ data: context.getImageData(0, 0, canvas.width, canvas.height), hasInk });
      if (snapshots.length > 20) snapshots.shift();
      context.drawImage(staging, 0, 0);
      hasInk = true;
      changed();
      showResult('Imagem carregada', 'Peça para identificar ou informe o nome e ensine esta imagem. Você também pode desenhar sobre ela.');
    } catch (error) { showError(error.message || 'Não foi possível carregar a imagem.'); }
    finally { busy = false; fileInput.value = ''; controls(); }
  }
  fileInput.addEventListener('change', () => importFile(fileInput.files[0]));
  let dragDepth = 0;
  paper.addEventListener('dragenter', event => {
    if (!event.dataTransfer.types.includes('Files')) return;
    event.preventDefault(); dragDepth++; paper.classList.add('dragging');
  });
  paper.addEventListener('dragover', event => { if (event.dataTransfer.types.includes('Files')) event.preventDefault(); });
  paper.addEventListener('dragleave', () => { if (--dragDepth <= 0) { dragDepth = 0; paper.classList.remove('dragging'); } });
  paper.addEventListener('drop', event => {
    if (!event.dataTransfer.files.length) return;
    event.preventDefault(); dragDepth = 0; paper.classList.remove('dragging');
    if (event.dataTransfer.files.length !== 1) { showError('Carregue uma imagem por vez.'); return; }
    importFile(event.dataTransfer.files[0]);
  });
  canvas.addEventListener('paste', event => {
    const file = [...event.clipboardData.items].find(item => item.kind === 'file')?.getAsFile();
    if (file) { event.preventDefault(); importFile(file); }
  });
  async function exportImage(format) {
    if (busy || drawing || !hasInk) return;
    busy = true; controls(); feedback.hidden = true;
    try { await SketchImageIO.download(canvas, format); }
    catch (error) { showError(error.message || 'Não foi possível baixar a imagem.'); }
    finally { busy = false; controls(); }
  }
  downloadPng.addEventListener('click', () => exportImage('png'));
  downloadSvg.addEventListener('click', () => exportImage('svg'));

  function pixels() {
    const thumbnail = document.createElement('canvas'); thumbnail.width = thumbnail.height = 64;
    const ctx = thumbnail.getContext('2d'); ctx.drawImage(canvas, 0, 0, 64, 64);
    const rgba = ctx.getImageData(0, 0, 64, 64).data;
    return Array.from({ length: 4096 }, (_, i) => Math.round(0.2126 * rgba[i * 4] + 0.7152 * rgba[i * 4 + 1] + 0.0722 * rgba[i * 4 + 2]));
  }
  function updateMemory(summary) {
    document.getElementById('training-state').textContent = summary.count > 0 ? 'Treinamento salvo em uso' : 'Sem treinamento ativo';
    document.getElementById('sample-count').textContent = summary.count;
    document.getElementById('class-count').textContent = summary.classes.length;
    document.getElementById('memory-empty').hidden = summary.count > 0;
    const classes = document.getElementById('classes'); classes.replaceChildren();
    summary.classes.forEach(group => {
      const chip = document.createElement('span'); chip.textContent = group.label;
      const count = document.createElement('b'); count.textContent = group.count; chip.append(count); classes.append(chip);
    });
    const examples = document.getElementById('examples'); examples.replaceChildren();
    summary.examples.forEach(sample => {
      const figure = document.createElement('figure');
      const img = document.createElement('img'); img.src = sample.url; img.alt = `Exemplo ensinado como ${sample.label}`; img.width = img.height = 64;
      const caption = document.createElement('figcaption'); caption.textContent = sample.label;
      const download = document.createElement('a'); download.className = 'example-download'; download.href = sample.url; download.download = `${sample.label}.png`; download.textContent = 'Baixar PNG ↓';
      figure.append(img, caption, download); examples.append(figure);
    });
  }
  async function manageTraining(path, pending, title) {
    if (busy || drawing) return;
    busy = true; controls(); feedback.hidden = true;
    trainingProgress.textContent = pending; trainingProgress.hidden = false;
    try {
      const response = await fetch(path, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
        body: '{}' });
      if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('O servidor não respondeu como esperado. Atualize a página e tente novamente.');
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Não foi possível atualizar o treinamento.');
      updateMemory(data.summary);
      trainingProgress.textContent = data.message;
      showResult(title, data.message, 'learned', '✳');
    } catch (error) {
      trainingProgress.textContent = error.message || 'A operação não foi concluída.';
      showError(error.message || 'Não consegui conectar ao servidor.');
    } finally { busy = false; controls(); }
  }
  pretrain.addEventListener('click', () => manageTraining('/treinamento/inicial', 'Treinando a CNN com as formas da base inicial… Aguarde nesta página.', 'Base inicial aprendida!'));
  resetTraining.addEventListener('click', () => {
    if (busy || drawing) return;
    if (!window.confirm('Limpar os pesos e exemplos do modelo ativo?')) return;
    manageTraining('/treinamento/zerar', 'Guardando uma cópia e zerando o aprendizado…', 'Vamos começar do zero!');
  });
  async function send(path, payload) {
    if (busy || drawing || !hasInk) return;
    busy = true; controls(); feedback.hidden = true;
    try {
      const response = await fetch(path, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
        body: JSON.stringify(payload) });
      if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('O servidor não respondeu como esperado. Atualize a página e tente novamente.');
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Não foi possível concluir.');
      updateMemory(data.summary);
      if (data.status === 'learned') {
        showResult(data.corrected ? 'Nome corrigido!' : 'Mais um desenho aprendido!', data.message, 'learned', '✳');
      } else {
        showResult(data.status === 'recognized' ? `Parece ${data.label}!` : 'Ainda não sei…', data.reason, data.status === 'recognized' ? 'recognized' : '', data.status === 'recognized' ? '✓' : '?');
        const matches = document.getElementById('matches');
        data.matches.forEach(match => {
          const item = document.createElement('div'); item.className = 'match';
          const text = document.createElement('div'); const name = document.createElement('strong'); name.textContent = match.label;
          const score = document.createElement('span'); score.textContent = `${(match.score * 100).toFixed(1)}% de confiança`;
          text.append(name, score);
          if (match.id) {
            const img = document.createElement('img'); img.src = `/exemplos/${match.id}`; img.alt = `Exemplo de ${match.label}`;
            item.append(img, text);
          } else { item.append(text); }
          matches.append(item);
        });
      }
    } catch (error) { showError(error.message || 'Não consegui conectar ao servidor.'); }
    finally { busy = false; controls(); }
  }
  identify.addEventListener('click', () => send('/identificar', { pixels: pixels() }));
  document.getElementById('teach-form').addEventListener('submit', event => {
    event.preventDefault(); if (!label.value.trim()) { label.focus(); return; }
    send('/ensinar', { pixels: pixels(), label: label.value.trim() });
  });
  controls();
})();

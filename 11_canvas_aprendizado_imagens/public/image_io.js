// Leitura local: SVG é validado e rasterizado como imagem, nunca inserido no HTML.
window.SketchImageIO = (() => {
  const MAX_BYTES = 5 * 1024 * 1024;
  const elements = new Set(['svg', 'g', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'path', 'title', 'desc', 'defs', 'clipPath', 'mask', 'linearGradient', 'radialGradient', 'stop', 'use', 'image']);
  const internalUrl = /^#[a-z_][\w:.-]*$/i;

  function safeSvg(text) {
    if (/<!DOCTYPE|<!ENTITY/i.test(text)) throw new Error('Use um SVG sem declarações externas ou entidades XML.');
    const document = new DOMParser().parseFromString(text, 'image/svg+xml');
    if (document.querySelector('parsererror') || document.documentElement.localName !== 'svg') throw new Error('O arquivo SVG não é válido.');
    const root = document.documentElement;
    if (root.namespaceURI !== 'http://www.w3.org/2000/svg') throw new Error('O SVG precisa usar o namespace padrão.');
    const nodes = [root, ...root.querySelectorAll('*')];
    if (nodes.length > 2000) throw new Error('Este SVG é complexo demais. Use uma versão PNG.');
    for (const node of nodes) {
      if (!elements.has(node.localName) || node.namespaceURI !== root.namespaceURI) throw new Error('Use um SVG de formas simples, sem scripts, estilos ou conteúdo HTML.');
      for (const attribute of [...node.attributes]) {
        const name = attribute.localName.toLowerCase();
        const value = attribute.value.trim();
        if (name.startsWith('on') || name === 'base' || name === 'src' || /javascript\s*:|@import|expression\s*\(/i.test(value)) throw new Error('O SVG contém conteúdo ativo que não pode ser importado.');
        if (name === 'href') {
          const png = node.localName === 'image' && /^data:image\/png;base64,[a-z0-9+/=\s]+$/i.test(value);
          if (!internalUrl.test(value) && !png) throw new Error('O SVG deve ser independente, sem imagens ou links externos.');
        }
        const urls = [...value.matchAll(/url\s*\(([^)]*)\)/gi)];
        if (urls.some(match => !internalUrl.test(match[1].trim().replace(/^['"]|['"]$/g, '')))) throw new Error('O SVG contém referências externas. Use uma versão PNG.');
        // CSS escapado ou namespaces adicionais podem esconder referências.
        if (name === 'style' && /[\\@]/.test(value)) throw new Error('Este estilo SVG não é compatível. Use uma versão PNG.');
      }
    }
    return new Blob([new XMLSerializer().serializeToString(root)], { type: 'image/svg+xml' });
  }

  async function load(file) {
    if (!file || file.size === 0 || file.size > MAX_BYTES) throw new Error('Escolha uma imagem de até 5 MB.');
    const extension = file.name.toLowerCase().split('.').pop();
    const svg = file.type === 'image/svg+xml' || extension === 'svg';
    if (!svg && !['image/png', 'image/jpeg', 'image/webp'].includes(file.type) && !['png', 'jpg', 'jpeg', 'webp'].includes(extension)) throw new Error('Use PNG, JPG, WebP ou SVG.');
    const blob = svg ? safeSvg(await file.text()) : file;
    const url = URL.createObjectURL(blob);
    try {
      const image = new Image();
      image.decoding = 'async';
      await new Promise((resolve, reject) => {
        image.onload = resolve;
        image.onerror = () => reject(new Error('Não foi possível abrir esta imagem. Tente exportá-la como PNG.'));
        image.src = url;
      });
      if (!image.naturalWidth || !image.naturalHeight || Math.max(image.naturalWidth, image.naturalHeight) > 8192) throw new Error('Use uma imagem com até 8192 pixels por lado.');
      return image;
    } finally { URL.revokeObjectURL(url); }
  }

  async function download(canvas, format) {
    let blob;
    if (format === 'svg') {
      // O SVG incorpora o PNG do canvas: não é uma vetorização dos traços.
      const png = canvas.toDataURL('image/png');
      blob = new Blob([`<svg xmlns="http://www.w3.org/2000/svg" width="${canvas.width}" height="${canvas.height}" viewBox="0 0 ${canvas.width} ${canvas.height}"><title>Meu desenho</title><image width="${canvas.width}" height="${canvas.height}" href="${png}"/></svg>`], { type: 'image/svg+xml' });
    } else {
      blob = await new Promise((resolve, reject) => canvas.toBlob(value => value ? resolve(value) : reject(new Error('Não consegui gerar o PNG.')), 'image/png'));
    }
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url; link.download = `meu-desenho.${format}`;
    document.body.append(link); link.click(); link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  return { load, download, safeSvg };
})();

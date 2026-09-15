# Otimiza??o das imagens do cat?logo

## Resultado

- 20 fotos de produtos: PNG ? WebP (qualidade 92); vers?es de 480, 960 e 1536 px de largura.
- Logo: PNG 1421 ? 703 ? WebP sem perdas 570 ? 282, com canal alpha preservado. Resolu??o suficiente para o maior uso (190 px) em tela de densidade 3?.
- Impressora: JPEG 853 ? 1280 preservado. O teste WebP ficou maior e foi descartado.
- Um exemplar de cada imagem usada, considerando as vers?es maiores: 45.95 MB ? 5.08 MB. Economia de 40.87 MB (88.94%).
- Com fotos de 960 px: conjunto de 2.53 MB (94.50% menor). O navegador escolhe conforme tela e densidade.
- Valores em MB decimais (1 MB = 1.000.000 bytes). N?o representam tempo medido nem download inicial: lazy loading, cache, viewport e fichas abertas determinam a transfer?ncia real.
- Os originais permanecem nos caminhos existentes; portanto a redu??o ? no conte?do servido, n?o no tamanho total da pasta de trabalho.

## Tamanho de cada arquivo

Todos os tamanhos abaixo s?o em bytes. Os nomes e dimens?es exatos de cada vers?o est?o em `optimized/manifest.json`.

| Original | Formato final | Original | 480 px | 960 px | Maior vers?o / arquivo final |
|---|---|---:|---:|---:|---:|
| imagens flexiveis/adesivo automotivo.png | WebP | 1895714 | 25062 | 59708 | 119224 |
| imagens flexiveis/adesivo blackout e fosco.png | WebP | 1808643 | 21864 | 49350 | 86704 |
| imagens flexiveis/adesivo brilho ou fosco.png | WebP | 1971530 | 19620 | 59166 | 123614 |
| imagens flexiveis/adesivo jateado.png | WebP | 2355211 | 22360 | 85484 | 223250 |
| imagens flexiveis/adesivo perfurado.png | WebP | 3542801 | 89370 | 320954 | 639248 |
| imagens flexiveis/adesivo transparente.png | WebP | 1915089 | 23640 | 61102 | 113196 |
| imagens flexiveis/adesivos recorte.png | WebP | 2076449 | 30868 | 80798 | 155492 |
| imagens flexiveis/backlightfilm.png | WebP | 1944732 | 23810 | 58476 | 121228 |
| imagens flexiveis/lona back.png | WebP | 2052998 | 26592 | 81214 | 187806 |
| imagens flexiveis/lona front certa.png | WebP | 2529384 | 41466 | 139318 | 331262 |
| imagens flexiveis/ímã.png | WebP | 1920988 | 20556 | 51410 | 112046 |
| rigidos/Acrilico 3mm.png | WebP | 2336866 | 49500 | 146236 | 287312 |
| rigidos/acrilico 2mm.png | WebP | 2603485 | 52386 | 167952 | 356872 |
| rigidos/acrilico 4mm.png | WebP | 2270097 | 51526 | 146476 | 278568 |
| rigidos/capacho.png | WebP | 2879910 | 57228 | 201418 | 434070 |
| rigidos/polionda.png | WebP | 2293518 | 46604 | 137080 | 257748 |
| rigidos/ps 1mm.png | WebP | 2509845 | 51906 | 166848 | 346944 |
| rigidos/ps 2mm.png | WebP | 2448148 | 50100 | 156728 | 323786 |
| rigidos/pvc 3mm.png | WebP | 2263817 | 41958 | 127104 | 242352 |
| rigidos/pvc 5mm.png | WebP | 2198314 | 42628 | 124546 | 237500 |
| logo-acnatural-web.png | WebP | 61620 | ? | ? | 33598 |
| maquina.jpeg | JPEG (mantido) | 71148 | ? | ? | 71148 |

## Altera??es no c?digo

- `index.html`: caminhos do logo, lazy loading no rodap?, decoding async, prioridade alta na impressora e remo??o do src vazio do modal. Logo do topo e impressora continuam sem lazy loading.
- Seis arquivos app*.js com imagens locais: caminhos WebP, srcset/sizes para cards, decoding async e promo??o para eager dos cards que intersectam a primeira tela ap?s renderiza??o. Detalhes carregam a foto de 1536 px somente ao abrir a ficha. As medidas responsivas consideram tamb?m o recorte object-fit: cover.
- Os CSS n?o foram modificados: layout, propor??es, cores, fontes, recortes e filtros preservados.
- `build-single-file.ps1`: reconhece WebP, incorpora o logo otimizado e remove candidatos responsivos externos ao embutir fotos. O exportador antigo n?o ? necess?rio para publicar o index.html.
- `optimize-images.py`: reprodu??o offline dos arquivos com Pillow; n?o h? processamento de imagem no navegador.

## Invent?rio e duplicatas

- 26 imagens raster originais inventariadas; 22 usadas pelo index.html (20 produtos, logo e impressora). Nenhuma duplicata bin?ria entre os originais (SHA-256). O logo repetido no cabe?alho/rodap? utiliza a mesma URL para aproveitar cache.
- N?o utilizados pela p?gina atual: `preview.png`, `logo-acnatural.png`, `rigidos/acrilico 5mm.png` e `imagens flexiveis/lona front.png`. Preservados sem gerar downloads ou convers?es desnecess?rias.
- O PDF do logo ? refer?ncia e n?o ? carregado pela p?gina. O fundo granulado ? SVG embutido no CSS, sem download separado; preservado.
- `app.js` e parte de `app-teste.js` cont?m refer?ncias antigas ao Unsplash. Esses arquivos n?o s?o carregados pelo index.html; as imagens externas foram preservadas para n?o mudar vers?es antigas.

## Valida??o

- Chromium em viewport mobile 390 ? 844: todos os 20 cards decodificados; 20 fichas abertas com imagens v?lidas; nenhuma imagem quebrada ou overflow horizontal.
- Desktop 1440 ? 900: 20 fichas carregadas; filtros retornam 9 r?gidos e 11 flex?veis; pesquisa PS 1mm retorna um resultado; sem overflow horizontal.
- Confer?ncia visual no navegador; CSS intacto. N?o foi executado teste em aparelho f?sico nem medi??o sob rede m?vel limitada.
- Sintaxe de todos os JavaScripts validada com node --check; git diff --check passou; refer?ncias locais e todos os candidatos do manifesto existem; hashes dos originais conferidos.

## Limita??es e pontos ainda relevantes

- Google Fonts e Font Awesome permanecem externos e podem atrasar em conex?es lentas. Mantidos para preservar exatamente tipografia e ?cones.
- Textura SVG com filtro, efeitos CSS e anima??es podem consumir processamento em celulares mais fracos; n?o foram alterados para preservar o design.
- O exportador single-file j? apontava por padr?o para index-final.html inexistente e para um JavaScript antigo; n?o ? o fluxo de publica??o atual. Arquivos ?nicos com base64 eliminam a economia de rede do lazy loading e n?o s?o recomendados para esta publica??o.

## Testar e publicar

- Abra `index.html` ou execute `python -m http.server 8765 --bind 127.0.0.1` nesta pasta e acesse http://127.0.0.1:8765. Se j? havia aberto o cat?logo, fa?a recarregamento for?ado para descartar JavaScript antigo em cache.
- Envie os arquivos alterados e toda a pasta `optimized/` ao GitHub. Publique a raiz como site est?tico na Vercel, sem etapa obrigat?ria de build.
- `backup-antes-otimizacao.zip` cont?m os HTML/JS/CSS/PowerShell anteriores. As imagens originais continuam intactas; nenhum original foi exclu?do.
- `.vercelignore` exclui da implanta??o apenas backups, relat?rio, ferramenta e imagens de refer?ncia sem uso. Os originais continuam dispon?veis localmente e no reposit?rio se inclu?dos no commit.

# 11 — Traço: desenhar, corrigir e aprender com imagens

Um projeto Ruby + Rails com canvas, independente do exemplo 10. Você desenha com mouse, caneta ou toque, pede uma identificação e ensina o nome correto quando necessário. A próxima identificação considera esse exemplo. Não utiliza LLM, API externa, reconhecimento de texto ou regras prontas para nomes de formas.

## Rodar

Com Ruby 3.2 ou superior compatível com Rails 8.1 e ferramentas de compilação de gems:

```sh
cd 11_canvas_aprendizado_imagens
bundle install
bundle exec rails s
```

Abra **http://localhost:3001**. A porta padrão do exemplo 11 é 3001 para permitir usar o exemplo 10 em 3000. Você pode escolher outra com `bundle exec rails s -p 3002`. No Windows, use RubyInstaller com Devkit ou o ambiente Ruby do WSL.

Alternativa com Docker:

```sh
docker compose up --build
```

Também abre em localhost:3001. Pare com Ctrl+C. Os exemplos e o modelo persistem na pasta `storage/`.

## Base inicial e controles de treinamento

A interface tem duas abas: **Canvas de aprendizado**, com o quadro e o formulário para ensinar desenhos, e **Exemplos treinados**, com o caderno, nomes, imagens já ensinados e os botões para treinar os exemplos de teste e limpar o modelo. Trocar de aba mantém o desenho atual. Também é possível navegar pelas abas usando as setas do teclado.

O painel **Treinamento da CNN** tem apenas dois botões. As imagens de **estrela, quadrado, bola, triângulo e retângulo** são geradas internamente e não aparecem em uma galeria.

A aba **Exemplos treinados** mostra todos os exemplos salvos, incluindo os mais antigos.

- **Treinar com exemplos de teste**: treina 25 imagens (cinco por forma: duas preenchidas e três contornos levemente irregulares semelhantes ao desenho manual), com 6 versões modificadas de cada uma durante 35 épocas, sem rotação ou espelhamento. Inclui estrela de cinco pontas, quadrado, bola, triângulo e retângulo. O botão adiciona os exemplos à base existente e revisa as classes salvas. Repetir não duplica imagens nem substitui nomes que você já ensinou para a mesma silhueta. O processamento pode levar alguns segundos; aguarde a mensagem de conclusão.
- **Limpar modelo**: limpa pesos, filtros e exemplos do modelo ativo e guarda o treino anterior em `storage/model.before-reset.json`. Os PNGs são preservados no armazenamento. Repetir a limpeza quando o modelo já está vazio mantém o backup anterior.

Ao reabrir a aplicação, o treinamento ativo é carregado automaticamente. Nenhuma forma é treinada só por abrir a página. As geometrias da galeria servem apenas para gerar dados rotulados: a identificação continua sendo feita pela CNN.

## Experimento inicial

1. Desenhe um quadrado grande no quadro, com contorno fechado.
2. Clique em **Identificar meu desenho**. No início, o classificador responde que ainda não aprendeu nenhum desenho.
3. Em **Nome do desenho**, escreva `quadrado` e clique em **Treinar com este desenho**.
4. Clique em **Limpar quadro** e desenhe outro quadrado. Peça para identificar novamente.
5. Faça um triângulo. Se não reconhecer ou errar, escreva `triângulo` e ensine essa nova imagem.
6. Repita com diferentes desenhos de cada forma. Os exemplos ficam visíveis no caderno e são carregados quando você reabre a aplicação.

O nome vem de você. Se desenhar um quadrado e ensinar como `triângulo`, ele aprenderá essa associação: **a geometria do nome não vem programada**. Isso permite observar o efeito de rótulos incorretos. Para corrigir, ensine o mesmo desenho com o nome certo antes de apagar o quadro. Imagens com a mesma silhueta atualizam o próprio rótulo e reajustam os pesos, sem criar exemplos conflitantes.

O campo aceita `isso é um triângulo` ou apenas `triângulo`. As grafias `triangulo` e `trinagulo` são normalizadas para `triângulo`. Os nomes sugeridos na tela são atalhos para preencher o campo; não treinam nada sozinhos. Outros nomes também funcionam. O texto do rótulo não é usado para identificar uma imagem.

## Carregar e baixar imagens

Use **＋ Carregar imagem**, arraste um arquivo para o quadro ou cole uma imagem com o canvas em foco. Aceita **PNG, JPG, WebP e SVG**, com até 5 MB. As formas SVG baixadas no exemplo 10 podem ser carregadas diretamente. A imagem é ajustada ao quadro com margem e proporção preservada; depois você pode identificar, desenhar sobre ela ou ensinar o nome. **Desfazer** restaura o desenho que estava no quadro antes da importação.

**Baixar PNG** salva o canvas completo, em 512 × 512 pixels. **Baixar SVG** salva um SVG com esse PNG incorporado; preserva a aparência, mas não vetoriza os traços. Ambos podem ser carregados novamente no 11. Os exemplos do caderno também têm um link para baixar seu PNG de treinamento, em 64 × 64.

SVGs são validados e abertos como imagens, sem inserir seu conteúdo no HTML. O importador aceita elementos geométricos comuns, caminhos, grupos, gradientes e imagens PNG incorporadas; rejeita scripts, HTML, folhas de estilo e referências externas. SVGs complexos podem precisar ser exportados como PNG primeiro.

Carregar não treina nem salva automaticamente. Para treinar, informe o nome e clique em **Treinar com este desenho**: o Ruby gera variações, ajusta os pesos e guarda o exemplo em `storage/`. As URLs `/exemplos/<id>` servem os PNGs salvos pela aplicação local; elas não publicam a imagem na internet.

## Como aprende

Usamos uma **CNN pequena treinada localmente em Ruby**. Os filtros convolucionais e a camada de classificação aprendem por backpropagation e SGD, sem API externa.

```text
Canvas 512 × 512
  → navegador reduz para 64 × 64 pixels em tons de cinza
  → Ruby separa traço e fundo e preenche contorno fechado
  → silhueta 32 × 32 (posição no quadro é preservada)
  → centralização e ajuste proporcional dentro de 24 × 24, sem rotação
  → convolução: 6 filtros 3 × 3, stride 2 → ReLU
  → average pooling 3 × 3 → 150 características
  → classificação: sigmoide por nome
  → retorna o nome ou “ainda não sei”
```

Cada solicitação treina **6 versões modificadas por 35 épocas: 210 apresentações da imagem solicitada**, além da revisão de exemplos anteriores e negativos vazios. As versões são: maior, menor, esquerda, direita, cima e baixo. O original continua salvo para identificação e referência, sem contar como uma sétima versão de treino. **Sem rotação ou espelhamento.** As 6 apresentações são mantidas mesmo quando a resolução produz versões iguais. A normalização reduz diferenças de posição e tamanho: versões normalizadas podem coincidir e não equivalem a desenhos independentes. São revisados até cinco exemplos de cada classe.

A CNN aprende 6 filtros com 9 pesos e um bias cada, mais 150 pesos e um bias por classe. Só devolve um nome se a confiança atingir **0,78**, superar a segunda classe por **0,12** e os padrões forem próximos aos exemplos ensinados. Para isso, compara as características aprendidas aos últimos três exemplos da classe, exigindo distância quadrática relativa de no máximo 0,20. Esse limite é didático e ainda precisa ser avaliado com uma base separada. Confiança não é probabilidade de acerto.

## Código separado para estudo

| Arquivo | Responsabilidade |
| --- | --- |
| `public/canvas.js` | Traços, toque, desfazer, limpeza e envio dos pixels |
| `public/image_io.js` | Importação de PNG/JPG/WebP/SVG e downloads do canvas |
| `public/canvas.css` | Interface responsiva |
| `lib/sketch/preprocessor.rb` | Validação, silhueta e variações de treino |
| `lib/sketch/starter_images.rb` | Geração dos PNGs e dados rotulados da base inicial |
| `lib/sketch/classifier.rb` | CNN, convolução, pooling, backpropagation e decisão de desconhecimento |
| `lib/sketch/repository.rb` | Exemplos, pesos, correção, persistência e bloqueio de escrita |
| `app/controllers/canvas_controller.rb` | Rotas HTTP para identificar e ensinar |
| `app/views/canvas/index.html.erb` | Quadro, resultado, correção e caderno de exemplos |

## Onde salva

- `storage/model.json`: filtros da CNN, pesos de saída, bias, nomes e exemplos rotulados (máscara 32 × 32).
- `storage/images/<id>.png`: versões 64 × 64 dos desenhos ensinados.
- `storage/model.lock`: bloqueio para que requisições simultâneas não sobrescrevam exemplos.

O treino de novos exemplos acontece ao clicar em **Treinar com este desenho**. Limpar o canvas não apaga o modelo. Exemplos antigos entram de novo no SGD para reduzir o esquecimento de classes anteriores. O laboratório aceita até 500 silhuetas distintas. O JSON guarda os filtros e um vetor de 150 pesos por nome.

Modelos lineares antigos são migrados na primeira leitura: os exemplos são reapresentados à CNN e o JSON original fica em `storage/model.json.before-cnn.bak`. Essa primeira leitura pode demorar enquanto a migração treina a rede. Depois da migração, identificar não altera os pesos.

## Limitações e próximos experimentos

Use uma figura por vez, contornos fechados, com espaço nas bordas. O treino cobre escala e posição, mas não rotação. Traços abertos, figuras muito pequenas, formatos quase iguais ou desenhos muito diferentes dos exemplos podem retornar desconhecimento ou uma identificação errada. Um treino ajusta os pesos; não garante reconhecer todas as variações da categoria. Treine vários exemplos e avalie com desenhos novos.

O preenchimento da silhueta faz figuras com contorno fechado e preenchidas parecerem semelhantes; não distingue detalhes internos. Arquivos de imagem podem ser carregados, mas fotos com fundo complexo não são adequadas a este classificador. Não utiliza câmera nesta versão. O modelo é compartilhado entre todas as abas e sessões deste laboratório local, sem contas ou banco de dados. Não foi preparado para publicação na internet.

Próximos experimentos: separar validação, medir acurácia em desenhos novos e comparar arquiteturas da CNN, mantendo o mesmo canvas.

## Verificar

```sh
bundle exec rails test
bundle exec rails zeitwerk:check
```

Os testes cobrem o ciclo desconhecer → treinar → reconhecer, persistência dos pesos, novas classes, correção de rótulo, contornos, variações de escala e posição, entradas inválidas, escrita concorrente, rotas e PNGs salvos.

Testes opcionais do importador/exportador JavaScript (Node apenas para testes, sem mudar os requisitos da aplicação):

```sh
npm install --prefix tmp/js-test --no-save jsdom
node --test test/image_io_test.cjs
node --test test/training_controls_test.cjs
```

Verificam a estrutura SVG das formas do exemplo 10, validação de conteúdo/referências externas, limites de arquivos, exportação PNG/SVG e compatibilidade estrutural do SVG exportado com a reimportação.

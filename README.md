# Estudo de Deep Learning

Repositório de estudo de **deep learning (aprendizado profundo)**, com exemplos práticos em **Ruby e Python** para explorar os fundamentos do aprendizado de máquina e das redes neurais: entradas numéricas, pesos, viés, erro, treinamento e previsão.

A proposta é aprender de forma progressiva, acompanhando os cálculos no código. Os exercícios começam com entradas simples e avançam para matrizes, imagens, áudio e texto.

**Estágio atual:** os exemplos 01 a 06 implementam classificadores lineares didáticos. Os exemplos 07 a 09 usam redes profundas já treinadas com Transformers e PyTorch para análise de sentimentos, extração de respostas e conversa generativa.

## Sumário

- [Objetivos](#objetivos)
- [Exemplos disponíveis](#exemplos-disponíveis)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Tecnologias e requisitos](#tecnologias-e-requisitos)
- [Como executar](#como-executar)
- [Como o aprendizado funciona](#como-o-aprendizado-funciona)
- [Como ampliar os experimentos](#como-ampliar-os-experimentos)
- [Limitações](#limitações)
- [Próximos estudos](#próximos-estudos)

## Objetivos

- Entender como dados se tornam entradas numéricas para um modelo.
- Implementar os cálculos de treinamento e previsão de forma explícita.
- Observar o papel dos pesos, do viés, da taxa de aprendizado e das épocas.
- Comparar implementações em Ruby e Python.
- Aplicar o mesmo algoritmo a diferentes tipos de dados.
- Salvar e carregar modelos para reutilizar o treinamento.
- Construir uma base para estudar redes com múltiplas camadas.

## Exemplos disponíveis

| Etapa | Tema | Conceitos explorados | Linguagens |
| --- | --- | --- | --- |
| [01 — Gatos e cachorros](01_classificador_gatos_cachorros/) | Classificação de vetores numéricos, sem fotos de animais | Pesos, soma ponderada, erro e atualização dos pesos | Ruby e Python |
| [02 — Formas geométricas](02_formas_geometricas_matrizes/README.md) | Quadrado, triângulo e bola em matrizes 5 × 5 | Conversão de matrizes em vetores, viés e repetição do treino | Ruby e Python |
| [03 — Imagens](03_reconhecimento_imagens/README.md) | Classificação de formas em PNG ou JPG | Tons de cinza, redimensionamento para 16 × 16 e normalização de pixels | Ruby e Python |
| [04 — Áudio](04_reconhecimento_audio/README.md) | Reconhecimento das palavras quadrado, triângulo e bola | Características de frequência e tempo extraídas de arquivos WAV | Ruby e Python |
| [05 — Perguntas e respostas](05_perguntas_respostas/README.md) | Seleção de respostas cadastradas | Vocabulário, presença de palavras e persistência em JSON | Ruby |
| [06 — Desenhos por texto](06_desenhos_por_texto/README.md) | Pedidos de figuras no terminal | Integração de classificadores de texto e imagem e exportação em SVG | Ruby |
| [07 — Análise de sentimentos](07_analise_sentimentos/README.md) | Notas de 1 a 5 para textos | Inferência com BERT multilíngue e DataFrame pandas | Python |
| [08 — Perguntas e respostas com Transformers](08_perguntas_respostas_transformers/README.md) | Extração de respostas de um texto em português | Modelo BERT pré-treinado e pipeline de perguntas e respostas | Python |
| [09 — Chat generativo](09_chat_generativo/README.md) | Conversa em português sem contexto cadastrado | Qwen3-0.6B, geração de texto e histórico da sessão | Python |

## Estrutura do projeto

```text
.
├── README.md
├── 01_classificador_gatos_cachorros/
│   ├── exemplo.rb
│   └── exemplo.py
├── 02_formas_geometricas_matrizes/
│   ├── exemplo.rb
│   ├── exemplo.py
│   └── README.md
├── 03_reconhecimento_imagens/
│   ├── exemplo.rb / exemplo.py
│   ├── imagem.py
│   ├── imagens/
│   ├── requirements.txt
│   └── README.md
├── 04_reconhecimento_audio/
│   ├── exemplo.rb / exemplo.py
│   ├── audio.py / gravar.py
│   ├── sons/ / testes/
│   ├── requirements.txt
│   └── README.md
├── 05_perguntas_respostas/
│   ├── exemplo.rb
│   ├── classes.json
│   ├── perguntas_respostas.txt
│   └── README.md
└── 06_desenhos_por_texto/
    ├── exemplo.rb
    ├── pedidos.txt
    ├── imagens/ / imagens.json
    └── README.md
```

Os exemplos 05 e 06 salvam seus modelos em `classificador.json`, dentro das respectivas pastas. O exemplo 06 também salva os SVGs em `desenhos/`.

## Tecnologias e requisitos

| Recurso | Uso |
| --- | --- |
| Ruby | Execução dos arquivos `.rb`; cálculos dos modelos e bibliotecas padrão |
| Python 3 | Execução dos arquivos `.py` e preparação de imagens e áudio nas versões Ruby dos exemplos 03 e 04 |
| Pillow | Leitura e transformação de imagens no exemplo 03 |
| NumPy | Processamento numérico do áudio no exemplo 04 |
| sounddevice | Gravação opcional pelo microfone no exemplo 04 |

Os exemplos 01 e 02 não precisam de bibliotecas externas. Os exemplos 05 e 06 rodam apenas com Ruby; o 06 já inclui os pixels das imagens em JSON. Não são necessárias gems para as implementações Ruby.

Nos exemplos 01 a 06, os modelos são implementados diretamente. Os exemplos 07 e 08 usam Transformers e PyTorch e baixam modelos do Hugging Face na primeira execução. Não é necessário gravar áudio para começar: há arquivos de treino e teste incluídos.

## Como executar

Execute os comandos na raiz do repositório, exceto quando houver uma mudança explícita de pasta. A ordem numérica dos exemplos acompanha a evolução dos conceitos.

### 1. Exemplos básicos

Com Ruby:

```sh
ruby 01_classificador_gatos_cachorros/exemplo.rb
ruby 02_formas_geometricas_matrizes/exemplo.rb
```

Com Python no Windows:

```powershell
py 01_classificador_gatos_cachorros/exemplo.py
py 02_formas_geometricas_matrizes/exemplo.py
```

No Linux/macOS, use `python3` no lugar de `py`.

### 2. Reconhecimento de imagens

No Windows (PowerShell):

```powershell
py -m venv 03_reconhecimento_imagens/.venv
03_reconhecimento_imagens/.venv/Scripts/python.exe -m pip install -r 03_reconhecimento_imagens/requirements.txt
03_reconhecimento_imagens/.venv/Scripts/python.exe 03_reconhecimento_imagens/exemplo.py
```

Para testar uma imagem própria:

```powershell
03_reconhecimento_imagens/.venv/Scripts/python.exe 03_reconhecimento_imagens/exemplo.py caminho/minha_imagem.png
```

Para usar Ruby, indique o Python com Pillow instalado:

```powershell
$env:PYTHON = "$PWD/03_reconhecimento_imagens/.venv/Scripts/python.exe"
ruby 03_reconhecimento_imagens/exemplo.rb
```

No Linux/macOS:

```bash
python3 -m venv 03_reconhecimento_imagens/.venv
03_reconhecimento_imagens/.venv/bin/python -m pip install -r 03_reconhecimento_imagens/requirements.txt
03_reconhecimento_imagens/.venv/bin/python 03_reconhecimento_imagens/exemplo.py
```

Use figuras escuras sobre fundo claro, centralizadas e com enquadramento semelhante ao dos exemplos. Consulte o [README de imagens](03_reconhecimento_imagens/README.md) para mais detalhes.

### 3. Reconhecimento de áudio

No Windows (PowerShell):

```powershell
py -m venv 04_reconhecimento_audio/.venv
04_reconhecimento_audio/.venv/Scripts/python.exe -m pip install -r 04_reconhecimento_audio/requirements.txt
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/exemplo.py 04_reconhecimento_audio/testes/bola.wav
```

Com Ruby, indique o ambiente do áudio:

```powershell
$env:PYTHON = "$PWD/04_reconhecimento_audio/.venv/Scripts/python.exe"
ruby 04_reconhecimento_audio/exemplo.rb 04_reconhecimento_audio/testes/bola.wav
```

No Linux/macOS, crie o ambiente com `python3 -m venv 04_reconhecimento_audio/.venv` e use `.venv/bin/python` no lugar de `.venv/Scripts/python.exe` nos comandos Python.

A pasta `sons/` contém cinco áudios de treinamento por palavra. A pasta `testes/` contém um arquivo separado por palavra. Sem um argumento WAV, o programa mostra os resultados nos arquivos de treino.

Consulte o [README de áudio](04_reconhecimento_audio/README.md) para gravar sua voz, conhecer os formatos aceitos e configurar um ambiente separado no WSL.

### 4. Perguntas e respostas

A partir da raiz, entre na pasta do exemplo:

```sh
cd 05_perguntas_respostas
ruby exemplo.rb --treinar
ruby exemplo.rb "quantos lados tem um triângulo?"
ruby exemplo.rb
```

O último comando abre a conversa no terminal. Digite `/sair` para encerrar.

Edite `perguntas_respostas.txt` no formato `pergunta: resposta` e execute `ruby exemplo.rb --treinar` novamente para atualizar o modelo. Se já houver um modelo salvo, a execução normal apenas o carrega. Sem modelo salvo, a primeira execução faz o treinamento.

Veja o [README de perguntas e respostas](05_perguntas_respostas/README.md) para conhecer as configurações e regras da base.

### 5. Desenhos por texto

A partir da raiz, entre na pasta do exemplo:

```sh
cd 06_desenhos_por_texto
ruby exemplo.rb --treinar
ruby exemplo.rb "desenhe um triângulo"
ruby exemplo.rb
```

O desenho aparece no terminal e é salvo em SVG, por exemplo, `desenhos/triangulo.svg`. Abra esse arquivo em um navegador. Pedir a mesma figura novamente atualiza o SVG correspondente. Na conversa, use `/sair` para encerrar.

O modelo é treinado na primeira execução ou com `--treinar`; nas demais, o JSON existente é carregado. Consulte o [README de desenhos por texto](06_desenhos_por_texto/README.md) para alterar os pedidos e as referências.

### 6. Perguntas e respostas com Transformers

Na raiz do projeto:

```powershell
python -m pip install -r 08_perguntas_respostas_transformers/requirements.txt
python 08_perguntas_respostas_transformers/exemplo.py
```

Edite `08_perguntas_respostas_transformers/contexto.txt` para mudar o texto usado nas respostas. Digite `/sair` para encerrar. Veja o [README do exemplo 08](08_perguntas_respostas_transformers/README.md) para mais detalhes.

## Como o aprendizado funciona

Cada classe possui seus próprios pesos. A partir do exemplo 02, também possui um viés. Para cada entrada, o modelo calcula uma pontuação por classe e ajusta seus parâmetros:

```text
pontuação = soma(entrada[i] × peso[i]) + viés
alvo = 1 para a classe correta; 0 para as outras classes
erro = pontuação - alvo
peso[i] = peso[i] - taxa × erro × entrada[i]
viés = viés - taxa × erro
```

No exemplo 01, não há o termo de viés. Na previsão, a classe com a maior pontuação é escolhida.

| Conceito | Papel no estudo |
| --- | --- |
| Entrada | Representação numérica dos dados: características, pixels, áudio ou palavras |
| Peso | Parâmetro aprendido que controla a contribuição de uma entrada |
| Viés | Parâmetro que desloca a pontuação mesmo quando as entradas são zero |
| Taxa de aprendizado | Controla o tamanho de cada ajuste |
| Época | Uma passagem pelos exemplos de treinamento |
| Classe | Categoria que o modelo tenta prever |
| Inferência | Uso dos parâmetros aprendidos para classificar uma entrada |

A preparação dos dados muda entre os exercícios, enquanto o princípio de soma, erro e ajuste permanece. Nas versões Ruby dos exemplos 03 e 04, Python prepara os dados; os pesos, o treinamento e a previsão são calculados em Ruby.

Ruby e Python podem produzir pesos e resultados diferentes porque seus geradores de números aleatórios são diferentes, mesmo com a mesma semente.

## Como ampliar os experimentos

- **Entradas e matrizes:** altere os vetores, as formas, a taxa de aprendizado e as repetições nos exemplos 01 e 02. Observe os pesos e as previsões.
- **Imagens:** teste arquivos novos e compare o efeito do enquadramento, tamanho e contraste. Para ampliar o treino, adapte os dados carregados no exemplo 03.
- **Áudio:** acrescente WAVs nas pastas de cada classe, usando nomes novos como `06.wav`. Mantenha gravações separadas para testar.
- **Perguntas e respostas:** acrescente pares ao TXT do exemplo 05. Respostas idênticas compartilham a mesma classe. Treine novamente após editar a base ou a configuração.
- **Desenhos por texto:** acrescente variações em `pedidos.txt` e treine novamente. O treinamento usa `imagens.json`; alterar apenas os PNGs não atualiza os pixels usados pelo modelo.

Avalie as mudanças também com entradas que não participaram do treinamento. Acertar os próprios exemplos de treino não demonstra capacidade de generalização.

## Limitações

- Os modelos dos exemplos 01 a 06 são lineares e não aprendem relações como XOR na representação original das entradas.
- A maior pontuação escolhe uma classe, mas não representa uma probabilidade ou confiança calibrada.
- As bases são pequenas e didáticas; os resultados não constituem uma avaliação para uso real.
- As imagens são sensíveis a mudanças de posição, escala, estilo e fundo.
- Os áudios incluídos são sintetizados com a mesma voz. Eles não medem o reconhecimento de pessoas diferentes ou ambientes com ruído.
- O exemplo 05 seleciona respostas prontas e ignora a ordem das palavras. Não gera texto novo.
- O exemplo 06 seleciona e reproduz referências conhecidas. Não implementa uma rede geradora de imagens.
- Entradas fora do assunto podem receber uma classe conhecida. No exemplo 05, a resposta de desconhecimento é usada quando nenhuma palavra está no vocabulário.

## Próximos estudos

Possibilidades para continuar o aprendizado — ainda não implementadas:

- Separar sistematicamente dados de treino, validação e teste.
- Acompanhar a evolução do erro e calcular métricas por classe.
- Implementar funções de ativação, camadas ocultas e retropropagação.
- Comparar os modelos atuais com um perceptron multicamadas.
- Estudar redes convolucionais para imagens e modelos mais adequados a áudio e texto.
- Reproduzir os exercícios em um framework de deep learning e comparar os cálculos.

O foco deste repositório é registrar o estudo e tornar os fundamentos visíveis em implementações pequenas e experimentáveis.

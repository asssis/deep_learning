# Exemplo 04: reconhecer palavras pelo som

O som é a entrada. Os áudios incluídos falam **quadrado**, **triângulo** ou **bola**; a rede tenta reconhecer qual dessas três palavras foi dita. Não usa transcrição pronta nem um serviço de reconhecimento de voz.

A classe `RedeNeural` é a mesma do 03: soma ponderada com viés, erro `soma - alvo`, ajuste `peso -= taxa * erro * entrada` e `vies -= taxa * erro`. A maior soma escolhe a classe. Só muda a preparação dos dados: `audio.py` transforma o WAV em 256 números (16 faixas de frequência × 16 posições no tempo), em vez de pixels. O treinamento repete os exemplos 500 vezes com taxa 0.005.

## Preparar no Windows (PowerShell), na raiz do projeto

```powershell
py -m venv 04_reconhecimento_audio/.venv
04_reconhecimento_audio/.venv/Scripts/python.exe -m pip install -r 04_reconhecimento_audio/requirements.txt
```

No Linux/macOS, crie o ambiente com `python3 -m venv 04_reconhecimento_audio/.venv` e use `04_reconhecimento_audio/.venv/bin/python` nos comandos abaixo.

## Executar com os áudios incluídos

Não é necessário gravar. A pasta `sons/` contém cinco WAVs por palavra, usados no treinamento. A pasta `testes/` contém um WAV separado por palavra, em outra velocidade, para testar.

```powershell
ruby 04_reconhecimento_audio/exemplo.rb 04_reconhecimento_audio/testes/quadrado.wav
ruby 04_reconhecimento_audio/exemplo.rb 04_reconhecimento_audio/testes/triangulo.wav
ruby 04_reconhecimento_audio/exemplo.rb 04_reconhecimento_audio/testes/bola.wav
```

Também é possível executar em Python:

```powershell
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/exemplo.py 04_reconhecimento_audio/testes/bola.wav
```

Os 18 áudios foram sintetizados localmente com a voz Microsoft Maria Desktop (`pt-BR`), em WAV PCM de 16 bits, mono, a 16000 Hz. Os cinco exemplos de cada palavra usam velocidades de -2 a 2; os testes usam velocidade 3. Isso demonstra a classificação de som com o mesmo algoritmo, mas não mede reconhecimento de vozes humanas diferentes.

## Opcional: gravar outros exemplos

Execute cada comando, pressione Enter e fale a palavra quando aparecer `GRAVANDO`. Cada gravação dura dois segundos. Use o microfone padrão do computador.

```powershell
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/gravar.py 04_reconhecimento_audio/sons/quadrado/06.wav
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/gravar.py 04_reconhecimento_audio/sons/triangulo/06.wav
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/gravar.py 04_reconhecimento_audio/sons/bola/06.wav
```

Os arquivos `01.wav` a `05.wav` já estão incluídos. Se desejar acrescentar gravações próprias, comece com `06.wav` e repita usando `07.wav`, `08.wav` etc. Cada arquivo deve conter uma única palavra. Os nomes das pastas são os rótulos usados no treinamento. O gravador não sobrescreve arquivos existentes.

Também é possível copiar gravações existentes para essas pastas: use WAV PCM de 16 bits, mono ou estéreo, com taxa de pelo menos 8000 Hz. MP3 não é aceito.

## Treinar e reconhecer outra gravação

```powershell
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/gravar.py 04_reconhecimento_audio/teste.wav
04_reconhecimento_audio/.venv/Scripts/python.exe 04_reconhecimento_audio/exemplo.py 04_reconhecimento_audio/teste.wav
```

Escolha uma das três palavras para o teste. O programa treina novamente a cada execução e mostra a previsão. Sem o argumento de áudio, mostra apenas os resultados nos arquivos de treinamento. Para gravar outro teste, escolha outro nome de arquivo; o gravador não sobrescreve arquivos existentes.

Os acertos no treino não medem a capacidade de reconhecer gravações novas. Teste com arquivos separados. O modelo continua linear e simples: pode errar com outra pessoa, ruído ou pronúncia diferente. Sempre escolhe uma das três classes, inclusive para sons desconhecidos; a pontuação não é uma probabilidade. Não faz reconhecimento contínuo pelo microfone: grava primeiro e classifica o arquivo depois.

## Executar em Ruby

A versão `exemplo.rb` preserva a classe `RedeNeural` do Ruby do exemplo 03. Os pesos, o viés, o treinamento e a previsão são calculados em Ruby. Como no 03, Python apenas prepara a entrada: agora `audio.py` lê WAV e entrega uma lista de 256 números. A gravação continua sendo feita com `gravar.py`.

Depois de instalar as dependências, execute na raiz do projeto:

```powershell
ruby 04_reconhecimento_audio/exemplo.rb
ruby 04_reconhecimento_audio/exemplo.rb 04_reconhecimento_audio/teste.wav
```

O programa encontra automaticamente o Python do ambiente `.venv` do 04 correspondente ao sistema. No Linux/WSL, procura primeiro `.venv-wsl/bin/python`, depois `.venv/bin/python`, e por último `python3`. Não seleciona o `.exe` do Windows ao executar no WSL. Para escolher outro Python no PowerShell, defina `$env:PYTHON = 'C:/caminho/python.exe'`. Esse Python precisa ter NumPy instalado. Ruby precisa estar instalado e disponível no terminal. Ruby e Python podem produzir previsões diferentes, pois geram pesos aleatórios diferentes.

### Executar no WSL

Na pasta `04_reconhecimento_audio`, crie um ambiente Linux separado do ambiente Windows:

```bash
python3 -m venv .venv-wsl
.venv-wsl/bin/python -m pip install -r requirements.txt
ruby exemplo.rb
ruby exemplo.rb testes/bola.wav
```

Caso `PYTHON` esteja definido para um executável Windows, use `unset PYTHON` antes dos comandos. Para selecionar explicitamente o ambiente Linux, use `PYTHON="$PWD/.venv-wsl/bin/python" ruby exemplo.rb`.

# Exemplo 03: imagens reais como entrada

Mantemos o algoritmo do exemplo 02: soma ponderada, erro e ajuste de pesos e viés. Agora a entrada vem de arquivos PNG ou JPG.

1. Abre a imagem e coloca transparência sobre fundo branco.
2. Converte para tons de cinza e redimensiona para 16×16.
3. Transforma os pixels em uma lista de 256 valores: branco é 0, preto é 1 e cinza fica entre eles.
4. Envia a lista para `treinar`, sem mudar as funções da rede.

Use desenhos escuros sobre fundo claro, com a figura centralizada e enquadramento parecido com as imagens de exemplo. O redimensionamento usa toda a imagem.

## Executar na raiz do projeto

```sh
python3 -m venv 03_reconhecimento_imagens/.venv
source 03_reconhecimento_imagens/.venv/bin/activate
python3 -m pip install -r 03_reconhecimento_imagens/requirements.txt
python3 03_reconhecimento_imagens/exemplo.py
ruby 03_reconhecimento_imagens/exemplo.rb
```

A versão Ruby chama `imagem.py` apenas para converter as imagens, usando Python com Pillow. Os cálculos de treinamento continuam em Ruby. Usa automaticamente `.venv/bin/python` da pasta do exemplo quando disponível; caso contrário, usa `python3`. A variável `PYTHON` permite escolher outro executável.

Para prever uma imagem própria depois de treinar:

```sh
python3 03_reconhecimento_imagens/exemplo.py caminho/minha_imagem.png
ruby 03_reconhecimento_imagens/exemplo.rb caminho/minha_imagem.png
```

Incluímos três imagens em `imagens/`: quadrado, triângulo e bola. O exemplo repete o treinamento 300 vezes, com taxa 0.001, porque agora há 256 entradas. Cada classe tem 256 pesos e um viés.

As previsões iniciais usam as mesmas imagens do treino. Isso demonstra o funcionamento, mas não garante reconhecimento de novas imagens. O modelo continua linear; aprender variações de tamanho, posição e estilo exige mais exemplos. A maior soma determina a classe e não representa uma probabilidade.

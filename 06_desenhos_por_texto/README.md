# Exemplo 06: desenhos a partir de pedidos em texto

Todo o código está em `exemplo.rb`, usando apenas bibliotecas padrão de Ruby. Mantém o algoritmo linear dos exemplos anteriores: soma ponderada com viés, erro em relação ao alvo e ajuste dos pesos e do viés.

## Executar

Na pasta deste exemplo:

```bash
ruby exemplo.rb --treinar
ruby exemplo.rb
```

No console, escreva `desenhe um triângulo`, `faça um quadrado` ou `quero um desenho de bola`. Digite `/sair` para encerrar. Também pode pedir diretamente:

```bash
ruby exemplo.rb "desenhe um triângulo"
```

O desenho aparece no terminal e é salvo em `desenhos/triangulo.svg`. Abra o SVG em um navegador. Um novo pedido da mesma figura atualiza o arquivo correspondente.

Se o classificador já existir, apenas carrega o JSON. Só treina com `--treinar` ou na primeira execução, quando o modelo ainda não existe.

## Dois treinamentos

1. A rede de texto aprende a classificar os pedidos de `pedidos.txt` como quadrado, triângulo ou bola, usando presença de palavras como no 05.
2. A rede de imagens aprende a reconhecer as três figuras, usando os 256 pixels normalizados de cada imagem, como no 03.
3. O pedido seleciona uma figura; a rede de imagens confirma a referência selecionada; o programa redesenha seus pixels no terminal e no SVG.

Isso seleciona e reproduz uma referência reconhecida. Não é uma rede geradora de imagens e não inventa figuras novas. A ordem das palavras é ignorada, pedidos com várias figuras são ambíguos e pedidos fora do assunto podem ser classificados incorretamente.

## Dados incluídos

- `pedidos.txt`: pedidos de exemplo e suas classes, no formato `pedido: figura`.
- `imagens/`: cópias dos PNGs do exemplo 03.
- `imagens.json`: esses mesmos PNGs convertidos para 16 × 16, com valores entre 0 e 1. Incluído pronto para não precisar de Python ao executar o 06.
- `classificador.json`: os pesos e vieses das duas redes, o vocabulário e as referências de desenho.

Para acrescentar pedidos, edite o TXT e execute `ruby exemplo.rb --treinar`. Alterar os PNGs sozinho não altera o treinamento: os dados usados são os pixels em `imagens.json`. Para preparar novos pixels, a função `carregar_imagem` de `03_reconhecimento_imagens/imagem.py` faz a mesma conversão; essa etapa opcional requer Python com Pillow. O desenho tem resolução de 16 × 16, ampliada para 320 × 320 no SVG, para acompanhar o tamanho da entrada do 03.

# deep_learning

Exemplo educativo de aprendizado linear em Ruby e Python, sem bibliotecas externas.

## Exemplos

- `01_classificador_gatos_cachorros`: classificação básica com entradas numéricas.
- `02_formas_geometricas_matrizes`: quadrado, triângulo e bola representados por matrizes, com viés.
- `03_reconhecimento_imagens`: classificação de formas em arquivos de imagem.
- `04_reconhecimento_audio`: classificação das palavras faladas em arquivos WAV.
- `05_perguntas_respostas`: classificação de perguntas e seleção de respostas, com base TXT e modelo JSON.
- `06_desenhos_por_texto`: pedidos em texto selecionam desenhos reconhecidos pela rede de imagens.

## Executar

```sh
ruby 01_classificador_gatos_cachorros/exemplo.rb
python3 01_classificador_gatos_cachorros/exemplo.py
```

## Como funciona

Cada classe (gato ou cachorro) tem uma lista de pesos, criada aleatoriamente quando aparece pela primeira vez.

1. Multiplica cada entrada pelo peso correspondente e soma.
2. Compara a soma com o alvo: 1 para a classe correta e 0 para as outras.
3. Calcula o erro: `soma - alvo`.
4. Ajusta cada peso: `peso -= taxa * erro * entrada`.
5. Na previsao, escolhe a classe com a maior soma.

O exemplo treina `[1, 0]` como gato e `[0, 1]` como cachorro. Ao final, imprime os nomes previstos e os pesos decimais.

Os numeros 1 e 2 identificam as classes. Entradas e pesos podem ser decimais. A taxa 1 funciona neste exemplo; outros dados podem precisar de taxa menor e treinamento repetido.

Nao ha vieses, camadas ocultas ou funcoes de ativacao. Este modelo linear simplificado nao aprende XOR. As previsoes do exemplo usam os mesmos dados do treinamento.

Ruby e Python podem gerar pesos aleatorios diferentes, mesmo com a mesma semente.

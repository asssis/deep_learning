# Exemplo 02: pesos e viés

Este exemplo acrescenta um viés por classe ao algoritmo linear do exemplo 01.

```text
soma = soma das entradas multiplicadas pelos pesos + vies
erro = soma - alvo
peso -= taxa * erro * entrada
vies -= taxa * erro
```

O viés começa em zero. Ele permite mudar a soma mesmo quando as entradas são zero, caso em que os pesos não recebem ajuste. A previsão e o treinamento usam o mesmo viés.

Execute a partir da raiz do projeto:

```sh
ruby 02_formas_geometricas_matrizes/exemplo.rb
python3 02_formas_geometricas_matrizes/exemplo.py
```

Quadrado, triangulo e bola sao desenhados em matrizes 5 x 5: 1 representa a forma e 0 o fundo. Antes de chamar `treinar`, cada matriz vira uma lista de 25 valores, linha por linha (`flatten` em Ruby e compreensao de lista em Python). Cada classe tem 25 pesos e um vies.

O treinamento recebe apenas listas, como antes. Os tres exemplos sao apresentados 100 vezes, com taxa 0.01. A repeticao fica fora da classe. Ao final, sao impressas as previsoes, os pesos em uma grade 5 x 5 e os vieses, com quatro casas decimais apenas na impressao. Os calculos preservam os valores completos. As previsoes usam os mesmos desenhos do treino; isso nao demonstra reconhecimento de outras variacoes das formas.

O modelo continua linear, sem camadas ocultas ou funções de ativação, e não aprende XOR. A soma é uma pontuação, não uma probabilidade.

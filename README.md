# deep_learning

Exemplo educativo de aprendizado linear em Ruby e Python, sem bibliotecas externas.

## Executar

```sh
ruby exemplo.rb
python3 exemplo.py
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

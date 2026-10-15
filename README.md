# Deep learning com Ruby: exemplo educativo

Uma rede neural em Ruby puro, sem gems, com treinamento e previsão. Use Ruby 3 ou superior.

## Problema: XOR

A entrada é um array de dois números e a classificação é um inteiro:

| Entrada | Classe |
| --- | --- |
| `[0, 0]` | `0` |
| `[0, 1]` | `1` |
| `[1, 0]` | `1` |
| `[1, 1]` | `0` |

Valores iguais têm classe **0**; diferentes têm classe **1**. Essa regra descreve o XOR binário: o exemplo foi feito para entradas com valores 0 e 1, não para comparar quaisquer números.

## Executar

```sh
ruby exemplo.rb
```

O programa primeiro treina a rede, mostrando o progresso das épocas, e depois mostra as previsões. Após aprender, a saída esperada é:

```text
[0, 0] => classe 0
[0, 1] => classe 1
[1, 0] => classe 1
[1, 1] => classe 0
```

O programa também imprime a probabilidade estimada da classe 1. Ela não é uma garantia de confiança calibrada.

## Usar no seu código

```ruby
require_relative 'exemplo'

itens = [
  { dado: [0, 0], resultado: 0 },
  { dado: [0, 1], resultado: 1 },
  { dado: [1, 0], resultado: 1 },
  { dado: [1, 1], resultado: 0 }
]

rede = RedeNeural.new
10_000.times do
  itens.each do |item|
    rede.treinar(item[:dado], item[:resultado])
  end
end

classe = rede.prever([1, 0]) # Integer: esperado 1
p classe
p rede.probabilidade([1, 0]) # Float entre 0 e 1
```

Cada hash representa um exemplo de treinamento: `dado` contém os dois números de entrada e `resultado` contém a classe correta. Durante o treinamento, a rede usa os dois campos para aprender. Na previsão, você fornece apenas o array de entrada, pois o resultado será calculado pela rede.

Cada chamada a `treinar(dado, resultado)` faz um ajuste nos pesos. O `each` apresenta todos os exemplos, e o `10_000.times` repete esse processo por 10.000 épocas. Uma única passagem geralmente não basta para aprender. A rede é criada uma vez, antes dos laços, para preservar o aprendizado.

## Como a rede aprende

Os cálculos estão dentro de `treinar`. Para acompanhar, comece por um único peso:

```ruby
# Entrada = 1, peso = 0.5, viés = 0:
soma = 1 * 0.5 + 0

# Suponha que a saída após a ativação seja 0.8 e a resposta correta seja 1:
erro = 0.8 - 1 # -0.2

# No neurônio de saída deste modelo, delta = erro:
ajuste = 0.1 * erro * 1 # -0.02
peso_novo = 0.5 - ajuste # 0.52
```

Esse é um exemplo numérico isolado: o peso aumenta para ajudar a aproximar a saída de 1. A rede repete o cálculo para todos os pesos. Nas camadas ocultas, o delta também considera os pesos da camada seguinte e a derivada da ativação. `treinar` retorna a diferença assinada `previsão - resultado`, medida antes do ajuste; essa diferença não é a perda de entropia cruzada.

1. **Entrada:** recebe dois números.
2. **Camadas ocultas:** duas camadas de quatro neurônios combinam as entradas com pesos e vieses, usando `tanh` para aprender relações não lineares.
3. **Saída:** um neurônio usa a função sigmoide para estimar a probabilidade da classe 1.
4. **Erro:** a entropia cruzada compara essa estimativa com a classe correta.
5. **Treinamento:** a retropropagação calcula como cada peso contribui para o erro; o gradiente descendente ajusta os pesos. Cada época percorre os quatro exemplos.
6. **Previsão:** se a probabilidade for maior ou igual a `0.5`, retorna o inteiro `1`; caso contrário, retorna `0`.

A taxa de aprendizado controla o tamanho dos ajustes. A semente fixa torna a inicialização reproduzível. Duas camadas ocultas fazem desta uma pequena rede profunda; uma camada oculta já seria suficiente para o XOR, mas aqui usamos duas para ilustrar deep learning.

Não existe um `if` com a regra do XOR dentro da rede: ela aprende a partir dos rótulos fornecidos. O limiar `0.5` apenas converte a saída numérica em classe.

Este é um exercício didático. As previsões finais usam os mesmos quatro exemplos do treinamento e demonstram aprendizado da tabela, não avaliação de generalização. Em aplicações reais, separe dados de treino e teste e avalie o modelo em dados que ele não viu.

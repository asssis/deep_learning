# Exemplo 05: palavras, perguntas e respostas em Ruby

Todo o código está em `exemplo.rb`: rede, leitura do texto, treinamento, gravação do JSON e conversa. Mantém o aprendizado linear do exemplo 03, com os cálculos reunidos em métodos menores. A entrada é uma lista numérica de presença de palavras. Tudo roda em Ruby, sem Python, gems ou serviços externos.

A rede pula posições com entrada zero, pois elas não contribuem para a soma nem para o ajuste dos pesos. Isso acelera o treino da base maior, mantendo as mesmas fórmulas de aprendizado. A configuração usa 300 épocas.

## Arquivos para editar

- `classes.json`: épocas, taxa de aprendizado e resposta para perguntas sem palavras conhecidas. As classes são criadas automaticamente a partir das respostas do TXT.
- `perguntas_respostas.txt`: uma pergunta e sua resposta por linha, no formato `pergunta: resposta`.
- `classificador.json`: modelo gerado pelo treinamento, com vocabulário, pesos, vieses e respostas. Não precisa editar este arquivo manualmente.

## Executar

A base incluída tem 185 perguntas, com variações sobre saudações, geometria, palavras, JSON, Ruby, aprendizado da rede e uso do programa. Perguntas com a mesma resposta são agrupadas automaticamente. Você pode ampliar o TXT no mesmo formato.

Na pasta `05_perguntas_respostas`, no WSL ou em um terminal com Ruby:

```bash
ruby exemplo.rb --treinar
ruby exemplo.rb "quantos lados tem um triângulo?"
ruby exemplo.rb
```

O último comando abre uma conversa no terminal. Digite `/sair` para encerrar. Se `classificador.json` existir, o programa apenas carrega o modelo e responde, mesmo se o TXT ou a configuração tiverem mudado. Para atualizar o modelo, execute explicitamente `ruby exemplo.rb --treinar`: ele treina com a base atual, salva o JSON e encerra. Se o modelo ainda não existir, a primeira execução faz o treinamento e abre a conversa.

## Editar perguntas e respostas

Escreva uma pergunta e sua resposta por linha no TXT:

```text
oi: Olá! Você pode perguntar sobre quadrado, triângulo, bola ou sobre como a rede aprende.
olá: oi
qual é o horário de atendimento: Atendemos das 8h às 18h.
que horas vocês abrem: Atendemos das 8h às 18h.
```

Esse horário é apenas um exemplo: escreva sua resposta real. Execute `ruby exemplo.rb --treinar` após editar para incorporar as alterações; iniciar normalmente mantém o modelo salvo. Não precisa cadastrar classes manualmente: respostas idênticas compartilham uma classe; respostas diferentes recebem classes diferentes. Assim, `oi` e `olá` podem ter respostas distintas.

Use uma linha por par; não separe os pares por vírgula. Só o primeiro `:` é separador, então a resposta pode conter dois-pontos e vírgulas. Linhas vazias e comentários começando com `#` são ignorados. Não cadastre perguntas que tenham as mesmas palavras normalizadas com respostas diferentes, pois a rede não consegue distinguir essas entradas.

## Como funciona

Remove acentos, converte para minúsculas e separa as palavras. Monta o vocabulário com as perguntas de treino. Cada posição da entrada vale 1 se a palavra aparece e 0 se não aparece. A rede calcula a soma ponderada com viés, calcula `erro = soma - alvo` e ajusta os pesos e o viés exatamente como no 03. A classe com maior soma seleciona a resposta do TXT, salva junto do modelo.

É um classificador didático que seleciona respostas prontas. Não gera texto novo nem compreende linguagem como um modelo grande. A ordem das palavras é ignorada; negações, ambiguidades e perguntas com vários assuntos podem causar erros. Quando nenhuma palavra está no vocabulário, usa a resposta desconhecida; nos demais casos sempre escolhe uma classe, mesmo que a pergunta esteja fora do assunto. As somas não são probabilidades.

Acertos no treino não medem generalização. Teste perguntas novas e acrescente variações reais ao TXT. Evite rotular a mesma pergunta com respostas diferentes.

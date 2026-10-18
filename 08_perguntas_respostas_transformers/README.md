# 08 — Perguntas e respostas com Transformers

Usa um modelo BERT treinado para perguntas e respostas em português. Você faz
uma pergunta, e o modelo seleciona um trecho de `contexto.txt` como resposta.
O exemplo usa Transformers e PyTorch, com execução local na CPU.
O modelo utilizado é `pierreguillou/bert-base-cased-squad-v1.1-portuguese`.
A função `carregar_modelo` carrega explicitamente seu tokenizador e seus pesos
com `AutoTokenizer` e `AutoModelForQuestionAnswering`.

## Como rodar

Na raiz do projeto:

```powershell
python -m pip install -r 08_perguntas_respostas_transformers/requirements.txt
python 08_perguntas_respostas_transformers/exemplo.py
```

Para instalar em um ambiente separado no Windows:

```powershell
python -m venv 08_perguntas_respostas_transformers/.venv
08_perguntas_respostas_transformers/.venv/Scripts/python.exe -m pip install -r 08_perguntas_respostas_transformers/requirements.txt
08_perguntas_respostas_transformers/.venv/Scripts/python.exe 08_perguntas_respostas_transformers/exemplo.py
```

Digite uma pergunta e pressione Enter. Use `/sair` para encerrar.
Também é possível passar uma pergunta entre aspas:

```powershell
python 08_perguntas_respostas_transformers/exemplo.py "Quantos lados tem um triângulo?"
```

Outras perguntas para experimentar:

- Quantos lados tem o quadrado?
- Qual linguagem de programação é usada neste exemplo?
- Qual biblioteca permite carregar modelos já treinados?
- Onde o modelo procura a resposta?

A primeira execução baixa o modelo do Hugging Face e pode demorar. É necessário
acesso à internet e espaço para os pesos do modelo. Depois, os arquivos ficam
no cache local. Não precisa de chave de API nem de GPU.

## Como personalizar

Edite `contexto.txt`, salve em UTF-8 e execute novamente. O arquivo é localizado
em relação ao script, independentemente da pasta atual do terminal.
Escreva um texto com os fatos sobre os quais você deseja perguntar.
Não precisa cadastrar pares de perguntas e respostas nem treinar novamente.

A função `buscar_resposta` envia a pergunta e o contexto diretamente ao BERT,
sem depender da pipeline `question-answering`, removida no Transformers 5.
Funciona com Transformers 4 e 5. O código considera apenas tokens do contexto
e seleciona um trecho com até 30 tokens. Textos longos são divididos em janelas
com sobreposição. O modelo é carregado uma vez e reutilizado nas perguntas.

## Limitações e referências

Este é um modelo de extração de respostas: ele seleciona palavras do contexto,
sem gerar uma conversa livre. Se a resposta não estiver no texto, ainda pode
selecionar um trecho incorreto. A pontuação não garante acerto. Cada pergunta
é independente; não há memória da conversa nem treinamento durante o uso.

- [Modelo BERT para perguntas em português](https://huggingface.co/pierreguillou/bert-base-cased-squad-v1.1-portuguese)
- [Documentação de perguntas e respostas](https://huggingface.co/docs/transformers/tasks/question_answering)

# 09 — Chat generativo com Qwen3-0.6B

Conversa em linguagem natural usando `Qwen/Qwen3-0.6B` pelo Transformers.
O modelo já vem treinado e gera respostas em português sem precisar de
`contexto.txt`. O programa mantém o histórico enquanto está aberto.

## Rodar no WSL/Linux

Partindo da raiz do projeto:

```bash
cd 09_chat_generativo
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python exemplo.py
```

Se já estiver na pasta e com um ambiente Python ativo, execute apenas:

```bash
python -m pip install -r requirements.txt
python exemplo.py
```

No Windows, crie o ambiente com `python -m venv .venv` e ative com
`.venv\Scripts\Activate.ps1`, dentro da pasta do exemplo.
Use ambientes separados para WSL e Windows; não reutilize o mesmo `.venv`
entre os dois sistemas.

Faça perguntas como `oi`, `o que você sabe fazer?` ou `o que é uma função?`.
O modelo é carregado uma vez e continua disponível para as próximas perguntas.

- `/sair`, `exit` ou `quit`: encerra o programa.
- `/limpar`: apaga o histórico da sessão.
- Ctrl+C: interrompe a geração e encerra.

Pergunta única ou respostas com outro limite de tamanho:

```bash
python exemplo.py "O que é uma função em Python?"
python exemplo.py --max-tokens 128
```

## Como funciona

`AutoTokenizer` transforma as mensagens em tokens usando o formato de chat do
Qwen. `AutoModelForCausalLM` carrega seus pesos. `generate` produz novos tokens,
que são convertidos em texto. O modo de raciocínio do Qwen é desativado com
`enable_thinking=False` para respostas diretas.

O programa roda na CPU e não exige GPU, chave de API ou serviço pago.
A primeira execução baixa os arquivos do Hugging Face; os pesos ocupam
aproximadamente 1,2 GB no formato publicado. A memória utilizada durante a
execução é maior e depende do formato carregado e do histórico. Na CPU, uma
resposta pode demorar. Os arquivos ficam no cache para os próximos usos.

O histórico fica apenas na memória e desaparece ao sair. Quando a entrada
ultrapassa 2048 tokens, os pares mais antigos são removidos. Uma pergunta
individual grande demais é recusada. As respostas têm limite de 256 tokens
por padrão e podem terminar antes de completar uma explicação longa.

Conversar não faz treinamento nem atualiza os pesos. O modelo é pequeno e pode
inventar informações, errar ou repetir frases. O texto gerado é apenas exibido;
o programa não executa comandos sugeridos pelo modelo.

Referência: [modelo e instruções oficiais do Qwen3-0.6B](https://huggingface.co/Qwen/Qwen3-0.6B).

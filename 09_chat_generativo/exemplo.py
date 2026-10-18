# Como rodar no WSL/Linux, a partir da raiz do projeto:
#    cd 09_chat_generativo
#    python -m pip install -r requirements.txt
#    python exemplo.py
# Se já estiver nesta pasta, use apenas os dois últimos comandos.
# Opcional: crie um ambiente próprio antes de instalar:
#    python3 -m venv .venv
#    source .venv/bin/activate
# No Windows, ative com .venv\Scripts\Activate.ps1.
# Pergunta única: python exemplo.py "O que é uma função em Python?"
# Comandos do chat: /sair, exit ou quit para sair; /limpar para apagar o histórico.
# O primeiro uso baixa o Qwen3-0.6B; os próximos usam o cache local.
# O modelo já vem treinado. Conversar não modifica seus pesos.

"""Conversa em português com Qwen3-0.6B, usando Transformers e PyTorch."""

import argparse


MODELO = "Qwen/Qwen3-0.6B"
INSTRUCAO = (
    "Você é um assistente prestativo. Responda em português brasileiro, "
    "de forma clara e direta. Quando não souber, diga que não sabe."
)
LIMITE_ENTRADA = 2048


def carregar_modelo():
    from transformers import AutoModelForCausalLM, AutoTokenizer

    tokenizador = AutoTokenizer.from_pretrained(MODELO)
    # CPU por padrão: não exige GPU, CUDA ou accelerate.
    modelo = AutoModelForCausalLM.from_pretrained(MODELO)
    modelo.eval()
    return tokenizador, modelo


def gerar_resposta(tokenizador, modelo, historico, pergunta, max_tokens):
    import torch

    mensagens = historico + [{"role": "user", "content": pergunta}]
    while True:
        texto = tokenizador.apply_chat_template(
            mensagens,
            tokenize=False,
            add_generation_prompt=True,
            enable_thinking=False,  # Responde diretamente, sem modo de raciocínio.
        )
        entradas = tokenizador(texto, add_special_tokens=False, return_tensors="pt")
        if entradas["input_ids"].shape[1] <= LIMITE_ENTRADA:
            break
        if len(mensagens) <= 2:
            raise ValueError("Pergunta muito longa. Envie um texto menor.")
        # Preserva a instrução e a pergunta atual, removendo o par mais antigo.
        del mensagens[1:3]

    with torch.inference_mode():
        saida = modelo.generate(
            **entradas,
            max_new_tokens=max_tokens,
            do_sample=True,
            temperature=0.7,
            top_p=0.8,
            top_k=20,
            repetition_penalty=1.1,
            pad_token_id=tokenizador.eos_token_id,
        )
    # Mostra apenas os tokens novos, sem repetir a pergunta e o histórico.
    novos_tokens = saida[0, entradas["input_ids"].shape[1]:]
    resposta = tokenizador.decode(novos_tokens, skip_special_tokens=True).strip()
    mensagens.append({"role": "assistant", "content": resposta})
    return resposta, mensagens


def main():
    argumentos = argparse.ArgumentParser(description=__doc__)
    argumentos.add_argument("pergunta", nargs="?", help="Pergunta única entre aspas.")
    argumentos.add_argument("--max-tokens", type=int, default=256,
                            help="Limite de tokens por resposta (padrão: 256).")
    args = argumentos.parse_args()
    if not 1 <= args.max_tokens <= 2048:
        argumentos.error("--max-tokens deve estar entre 1 e 2048.")
    if args.pergunta is not None and not args.pergunta.strip():
        argumentos.error("A pergunta não pode estar vazia.")

    print(f"Carregando {MODELO} na CPU...", flush=True)
    tokenizador, modelo = carregar_modelo()
    historico = [{"role": "system", "content": INSTRUCAO}]

    if args.pergunta is not None:
        try:
            resposta, _ = gerar_resposta(
                tokenizador, modelo, historico, args.pergunta, args.max_tokens
            )
        except ValueError as erro:
            argumentos.error(str(erro))
        print(f"Assistente: {resposta}")
        return

    print("Chat em português. /sair para encerrar; /limpar para reiniciar.")
    while True:
        try:
            pergunta = input("Você: ").strip()
            if pergunta.lower() in {"/sair", "exit", "quit", "sair"}:
                break
            if pergunta.lower() == "/limpar":
                historico = [{"role": "system", "content": INSTRUCAO}]
                print("Histórico apagado.")
                continue
            if not pergunta:
                continue
            print("Gerando resposta...", flush=True)
            resposta, historico = gerar_resposta(
                tokenizador, modelo, historico, pergunta, args.max_tokens
            )
            print(f"Assistente: {resposta}\n")
        except ValueError as erro:
            print(erro)
        except (EOFError, KeyboardInterrupt):
            print("\nConversa encerrada.")
            break


if __name__ == "__main__":
    main()

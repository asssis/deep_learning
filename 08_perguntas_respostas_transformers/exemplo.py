# Como rodar (execute os comandos na raiz do projeto):
# 1. Instale as dependências:
#    python -m pip install -r 08_perguntas_respostas_transformers/requirements.txt
# 2. Abra as perguntas interativas:
#    python 08_perguntas_respostas_transformers/exemplo.py
# Ou faça uma pergunta diretamente:
#    python 08_perguntas_respostas_transformers/exemplo.py "Quantos lados tem um triângulo?"
# Edite contexto.txt nesta pasta para mudar o texto usado nas respostas.
# A primeira execução precisa de internet para baixar o modelo do Hugging Face.
# Depois do download, o modelo roda localmente na CPU e usa o cache.
# Se usar o ambiente separado do exemplo no Windows, execute:
#    08_perguntas_respostas_transformers/.venv/Scripts/python.exe 08_perguntas_respostas_transformers/exemplo.py
# O BERT já foi treinado em português; este script executa as previsões.

"""Extrai respostas de um texto em português usando Transformers e PyTorch."""

import argparse
from pathlib import Path


MODELO = "pierreguillou/bert-base-cased-squad-v1.1-portuguese"
ARQUIVO_CONTEXTO = Path(__file__).with_name("contexto.txt")


def carregar_modelo():
    """Carrega o tokenizador e os pesos do BERT treinado em português."""
    from transformers import AutoModelForQuestionAnswering, AutoTokenizer

    tokenizador = AutoTokenizer.from_pretrained(MODELO, use_fast=True)
    modelo = AutoModelForQuestionAnswering.from_pretrained(MODELO)
    modelo.eval()
    return tokenizador, modelo


def buscar_resposta(analisador, pergunta, contexto):
    """Seleciona um trecho do contexto diretamente com os resultados do BERT."""
    import torch

    tokenizador, modelo = analisador
    # Limita a pergunta para deixar espaço para o contexto em cada janela.
    pergunta = tokenizador.decode(
        tokenizador.encode(pergunta, add_special_tokens=False)[:64],
        skip_special_tokens=True,
    )
    entradas = tokenizador(
        pergunta,
        contexto,
        max_length=384,
        truncation="only_second",
        stride=128,
        return_overflowing_tokens=True,
        return_offsets_mapping=True,
        padding=True,
        return_tensors="pt",
    )
    deslocamentos = entradas.pop("offset_mapping")
    entradas.pop("overflow_to_sample_mapping")
    melhor = {"answer": "", "score": -1.0}

    # Processa uma janela de cada vez para limitar o uso de memória na CPU.
    with torch.inference_mode():
        for janela in range(entradas["input_ids"].shape[0]):
            saida = modelo(**{nome: valor[janela:janela + 1]
                              for nome, valor in entradas.items()})
            validos = torch.tensor([
                origem == 1 and fim > inicio
                for origem, (inicio, fim) in zip(
                    entradas.sequence_ids(janela), deslocamentos[janela].tolist()
                )
            ])
            if not validos.any():
                continue
            inicios = saida.start_logits[0].masked_fill(~validos, -float("inf"))
            finais = saida.end_logits[0].masked_fill(~validos, -float("inf"))
            pontuacoes = inicios.softmax(dim=0)[:, None] * finais.softmax(dim=0)[None, :]
            # A resposta deve terminar após o início e ter no máximo 30 tokens.
            pontuacoes = pontuacoes.triu().tril(diagonal=29)
            indice = int(pontuacoes.argmax())
            inicio, fim = divmod(indice, pontuacoes.shape[1])
            nota = float(pontuacoes[inicio, fim])
            if nota > melhor["score"]:
                primeiro = int(deslocamentos[janela, inicio, 0])
                ultimo = int(deslocamentos[janela, fim, 1])
                melhor = {"answer": contexto[primeiro:ultimo], "score": nota}
    return melhor


def responder(analisador, pergunta, contexto):
    """Mostra o trecho que o modelo selecionou como resposta."""
    resultado = buscar_resposta(analisador, pergunta, contexto)
    print(f"Resposta: {resultado['answer']}")
    # A pontuação ajuda a comparar previsões; não garante uma resposta correta.
    print(f"Pontuação do modelo: {resultado['score']:.4f}\n")


def main():
    argumentos = argparse.ArgumentParser(description=__doc__)
    argumentos.add_argument("pergunta", nargs="?", help="Pergunta entre aspas.")
    args = argumentos.parse_args()

    try:
        contexto = ARQUIVO_CONTEXTO.read_text(encoding="utf-8").strip()
    except OSError as erro:
        argumentos.error(f"Não foi possível ler {ARQUIVO_CONTEXTO}: {erro}")
    if not contexto:
        argumentos.error("Preencha contexto.txt antes de fazer perguntas.")
    if args.pergunta is not None and not args.pergunta.strip():
        argumentos.error("A pergunta não pode estar vazia.")

    print("Carregando o modelo de perguntas e respostas...")
    analisador = carregar_modelo()

    if args.pergunta is not None:
        responder(analisador, args.pergunta, contexto)
        return

    print(f"\nContexto usado nas respostas:\n{contexto}\n")
    print("Faça perguntas sobre esse texto. Digite /sair para encerrar.")
    while True:
        try:
            pergunta = input("Pergunta: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if pergunta.lower() == "/sair":
            break
        if pergunta:
            responder(analisador, pergunta, contexto)


if __name__ == "__main__":
    main()

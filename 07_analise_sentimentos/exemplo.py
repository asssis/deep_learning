# Como rodar (execute os comandos na raiz do projeto):
# 1. Instale as dependências:
#    python -m pip install -r 07_analise_sentimentos/requirements.txt
# 2. Execute o exemplo:
#    python 07_analise_sentimentos/exemplo.py
# Na primeira execução, é necessário acesso à internet para baixar o modelo.
# O resultado aparece no terminal com as colunas Texto e Nota (de 1 a 5).

"""Analisa sentimentos e atribui notas de 1 a 5 aos textos."""

import pandas as pd
from transformers import pipeline


# Simula o DataFrame chamado dataset que o Power BI fornece ao script Python.
dataset = pd.DataFrame({"Texto": [
    "Este produto é excelente, superou minhas expectativas!",
    "Achei muito ruim, não compraria novamente.",
    "O atendimento foi mediano, nada especial.",
    "Estou muito satisfeito com a qualidade.",
    "Terrível experiência, totalmente decepcionante!",
    "Estou muito pouco satisfeito com a qualidade.",
]})


def analisar_sentimentos(dataset):
    """Retorna uma cópia do DataFrame com a coluna Nota."""
    analisador = pipeline(
        "sentiment-analysis",
        model="nlptown/bert-base-multilingual-uncased-sentiment",
        framework="pt",  # Executa o modelo com PyTorch.
    )

    # Extrai os textos do DataFrame e gera as avaliações.
    resultados = analisador(dataset["Texto"].tolist(), truncation=True)
    notas = []

    for resultado in resultados:
        # Os rótulos são "1 star", "2 stars", ..., "5 stars".
        notas.append(int(resultado["label"].split()[0]))

    dataset = dataset.copy()
    dataset["Nota"] = notas
    return dataset


if __name__ == "__main__":
    dataset = analisar_sentimentos(dataset)
    print(dataset.to_string(index=False))

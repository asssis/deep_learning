# 07 — Análise de sentimentos em Python

Reproduz o exemplo das imagens: cria um DataFrame pandas com seis avaliações,
analisa os textos com um modelo BERT multilíngue e adiciona a coluna `Nota`,
com valores de 1 (avaliação mais negativa) a 5 (mais positiva).
As notas são previsões do modelo, não avaliações garantidas.

## Como executar

Na raiz do projeto:

```powershell
python -m pip install -r 07_analise_sentimentos/requirements.txt
python 07_analise_sentimentos/exemplo.py
```

Na primeira execução, a biblioteca baixa o modelo do Hugging Face, o que requer
internet e pode demorar. Nas execuções seguintes, usa o cache local.
O resultado é exibido no terminal com as colunas `Texto` e `Nota`.

## Usar no Power BI (Power Query)

Configure o Power BI para usar o ambiente Python no qual as dependências foram
instaladas. A tabela de entrada deve conter uma coluna `Texto` com textos
preenchidos.

No editor de scripts Python, copie os imports e a função
`analisar_sentimentos` de `exemplo.py` e adicione ao final:

```python
dataset = analisar_sentimentos(dataset)
```

O Power Query fornece o DataFrame `dataset`. Nesse caso, não copie o trecho
`dataset = pd.DataFrame(...)`, pois ele serve apenas para simular a entrada
na execução local. Selecione o DataFrame resultante para obter a coluna `Nota`.


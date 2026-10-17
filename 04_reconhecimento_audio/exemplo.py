# Aprendizado linear didático em Python puro.
# Execute: python exemplo.py caminho/voz.wav

import random


class RedeNeural:
    def __init__(self, quantidade_entradas=2, seed=42):
        self.quantidade_entradas = quantidade_entradas
        self.random = random.Random(seed)
        self.pesos = {}
        self.vieses = {}

    # Cada resultado tem sua própria lista de pesos.
    def validar_peso(self, resultado):
        if resultado in self.pesos:
            return

        self.pesos[resultado] = [
            self.random.uniform(-0.5, 0.5)
            for _ in range(self.quantidade_entradas)
        ]

        self.vieses[resultado] = 0.0

    def treinar(self, entrada, resultado, taxa=0.1):
        self.validar_peso(resultado)
        erros = {}

        for classe, pesos in self.pesos.items():
            soma = self.calcular_peso(entrada, pesos, self.vieses[classe])
            alvo = 1 if classe == resultado else 0
            erro = self.calcular_erro_peso(soma, alvo)
            self.ajustar_pesos(entrada, pesos, erro, taxa)
            self.ajustar_vies(classe, erro, taxa)
            erros[classe] = erro

        return erros

    # Retorna o resultado com a maior soma.
    def prever(self, entrada):
        if not self.pesos:
            return None

        return max(
            self.pesos,
            key=lambda resultado: self.calcular_peso(entrada, self.pesos[resultado], self.vieses[resultado]),
        )

    # Soma cada entrada multiplicada pelo peso correspondente, mais o vies.
    def calcular_peso(self, entrada, pesos, vies):
        if len(entrada) != len(pesos):
            raise ValueError(f"A entrada deve ter {len(pesos)} valores.")

        soma = vies # Soma inicial, mesmo quando todas as entradas sao zero.
        for indice in range(len(pesos)):
            soma += entrada[indice] * pesos[indice]
        return soma

    # O vies aprende sem multiplicar pela entrada.
    def ajustar_vies(self, classe, erro, taxa):
        self.vieses[classe] -= taxa * erro

    def calcular_erro_peso(self, soma, alvo):
        return soma - alvo

    def calcular_diferenca_peso(self, entrada, erro, taxa):
        return taxa * erro * entrada

    def ajustar_pesos(self, entrada, pesos, erro, taxa):
        for indice in range(len(pesos)):
            ajuste = self.calcular_diferenca_peso(entrada[indice], erro, taxa)
            pesos[indice] -= ajuste


if __name__ == "__main__":
    import argparse
    from pathlib import Path
    from audio import carregar_audio, QUANTIDADE_ENTRADAS

    parser = argparse.ArgumentParser(description="Reconhece quadrado, triangulo ou bola em WAV.")
    parser.add_argument("audio", nargs="?", help="Gravação nova para reconhecer após o treino")
    args = parser.parse_args()
    pasta = Path(__file__).parent / "sons"
    classes = {"quadrado": 1, "triangulo": 2, "bola": 3}
    nomes = {numero: nome for nome, numero in classes.items()}
    exemplos = []
    for nome, classe in classes.items():
        arquivos = sorted((pasta / nome).glob("*.wav"))
        if not arquivos:
            parser.error(f"Grave exemplos em {pasta / nome}. Veja o README.md.")
        for arquivo in arquivos:
            exemplos.append((arquivo, carregar_audio(arquivo), classe))

    rede = RedeNeural(quantidade_entradas=QUANTIDADE_ENTRADAS)
    for classe in classes.values():
        rede.validar_peso(classe)
    ordem = random.Random(42)
    for _ in range(500):
        ordem.shuffle(exemplos)
        for _, entrada, classe in exemplos:
            rede.treinar(entrada, classe, taxa=0.005)

    print("Conferência com os próprios áudios de treinamento:")
    acertos = 0
    for arquivo, entrada, classe in exemplos:
        previsto = rede.prever(entrada)
        acertos += previsto == classe
        print(f"{arquivo.name} ({nomes[classe]}) => {nomes[previsto]}")
    print(f"Acertos no treino: {acertos}/{len(exemplos)}")
    if args.audio:
        print(f"Áudio novo: {args.audio} => {nomes[rede.prever(carregar_audio(args.audio))]}")




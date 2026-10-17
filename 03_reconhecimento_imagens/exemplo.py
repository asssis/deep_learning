# Aprendizado linear didático em Python puro.
# Execute: python3 exemplo.py

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
    import sys
    from pathlib import Path
    from imagem import carregar_imagem

    pasta = Path(__file__).parent / "imagens"
    classe = {"quadrado": 1, "triangulo": 2, "bola": 3}
    nomes = {numero: nome for nome, numero in classe.items()}
    rede = RedeNeural(quantidade_entradas=16 * 16)

    # A imagem vira uma lista antes de chegar ao treinamento.
    exemplos = {}
    for nome in classe:
        exemplos[nome] = carregar_imagem(pasta / f"{nome}.png")

    for _ in range(300):
        for nome, entrada in exemplos.items():
            rede.treinar(entrada, classe[nome], taxa=0.001)

    for nome, entrada in exemplos.items():
        print(f"{nome}.png => {nomes[rede.prever(entrada)]}")

    # Opcional: prever uma imagem informada no terminal.
    if len(sys.argv) > 1:
        entrada = carregar_imagem(sys.argv[1])
        print(f"{sys.argv[1]} => {nomes[rede.prever(entrada)]}")

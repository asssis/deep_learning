# Aprendizado linear didático em Python puro.
# Execute: python3 exemplo.py

import random


class RedeNeural:
    def __init__(self, quantidade_entradas=2, seed=42):
        self.quantidade_entradas = quantidade_entradas
        self.random = random.Random(seed)
        self.pesos = {}

    # Cada resultado tem sua própria lista de pesos.
    def validar_peso(self, resultado):
        if resultado in self.pesos:
            return

        self.pesos[resultado] = [
            self.random.uniform(-0.5, 0.5)
            for _ in range(self.quantidade_entradas)
        ]

    def treinar(self, entrada, resultado, taxa=0.1):
        self.validar_peso(resultado)
        erros = {}

        for classe, pesos in self.pesos.items():
            soma = self.calcular_peso(entrada, pesos)
            alvo = 1 if classe == resultado else 0
            erro = self.calcular_erro_peso(soma, alvo)
            self.ajustar_pesos(entrada, pesos, erro, taxa)
            erros[classe] = erro

        return erros

    # Retorna o resultado com a maior soma.
    def prever(self, entrada):
        if not self.pesos:
            return None

        return max(
            self.pesos,
            key=lambda resultado: self.calcular_peso(entrada, self.pesos[resultado]),
        )

    # Soma: entrada[0] * peso[0] + entrada[1] * peso[1].
    def calcular_peso(self, entrada, pesos):
        if len(entrada) != len(pesos):
            raise ValueError(f"A entrada deve ter {len(pesos)} valores.")

        soma = 0.0
        for indice in range(len(pesos)):
            soma += entrada[indice] * pesos[indice]
        return soma

    def calcular_erro_peso(self, soma, alvo):
        return soma - alvo

    def calcular_diferenca_peso(self, entrada, erro, taxa):
        return taxa * erro * entrada

    def ajustar_pesos(self, entrada, pesos, erro, taxa):
        for indice in range(len(pesos)):
            ajuste = self.calcular_diferenca_peso(entrada[indice], erro, taxa)
            pesos[indice] -= ajuste


if __name__ == "__main__":
    rede = RedeNeural()
    classe = {"gato": 1, "cachorro": 2}
    nomes = {numero: nome for nome, numero in classe.items()}

    # Taxa 1 funciona neste exemplo simples com entradas 0 e 1.
    # Para outros dados, pode ser necessário usar uma taxa menor e repetir o treino.
    rede.treinar([1, 0], classe["gato"], taxa=1.0)
    rede.treinar([0, 1], classe["cachorro"], taxa=1.0)

    print(f"[1, 0] => {nomes[rede.prever([1, 0])]}")
    print(f"[0, 1] => {nomes[rede.prever([0, 1])]}")

    print("\nPesos depois do treinamento:")
    for resultado, pesos in rede.pesos.items():
        print(f"{nomes[resultado]}: {pesos}")

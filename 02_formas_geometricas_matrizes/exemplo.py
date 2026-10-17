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
    rede = RedeNeural(quantidade_entradas=25)
    classe = {"quadrado": 1, "triangulo": 2, "bola": 3}
    nomes = {numero: nome for nome, numero in classe.items()}

    # 1 desenha a forma; 0 representa o fundo.
    quadrado = [
        [1, 1, 1, 1, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 1, 1, 1, 1],
    ]

    triangulo = [
        [0, 0, 1, 0, 0],
        [0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 1, 1, 1, 1],
    ]

    bola = [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ]

    # Transformamos cada matriz em uma lista, linha por linha.
    quadrado_linear = [valor for linha in quadrado for valor in linha]
    triangulo_linear = [valor for linha in triangulo for valor in linha]
    bola_linear = [valor for linha in bola for valor in linha]

    # Mais entradas pedem uma taxa menor. A repeticao fica fora de treinar.
    for _ in range(100):
        rede.treinar(quadrado_linear, classe["quadrado"], taxa=0.01)
        rede.treinar(triangulo_linear, classe["triangulo"], taxa=0.01)
        rede.treinar(bola_linear, classe["bola"], taxa=0.01)

    print(f"Quadrado => {nomes[rede.prever(quadrado_linear)]}")
    for linha in quadrado:
        print("".join("██" if valor == 1 else "  " for valor in linha))
    print()
    print(f"Triangulo => {nomes[rede.prever(triangulo_linear)]}")
    for linha in triangulo:
        print("".join("██" if valor == 1 else "  " for valor in linha))
    print()
    print(f"Bola => {nomes[rede.prever(bola_linear)]}")
    for linha in bola:
        print("".join("██" if valor == 1 else "  " for valor in linha))

    print("\nPesos depois do treinamento:")
    for resultado, pesos in rede.pesos.items():
        print(f"\n{nomes[resultado].upper()}")
        print("Pesos (mesmas posicoes da matriz):")
        for inicio in range(0, len(pesos), 5):
            linha = pesos[inicio:inicio + 5]
            print(" ".join(f"{peso:8.4f}" for peso in linha))
        print(f"Vies: {rede.vieses[resultado]:.4f}")

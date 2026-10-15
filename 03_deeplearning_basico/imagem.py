"""Converte uma imagem em uma lista de 256 números."""

import json
import sys

from PIL import Image


def carregar_imagem(caminho):
    with Image.open(caminho) as original:
        # Transparência vira fundo branco.
        imagem = original.convert("RGBA")
        fundo = Image.new("RGBA", imagem.size, "white")
        fundo.alpha_composite(imagem)
        imagem = fundo.convert("L")
        imagem = imagem.resize((16, 16), Image.Resampling.LANCZOS)

        # Fundo branco vira 0; desenho preto vira 1.
        # Tons de cinza ficam entre 0 e 1.
        return [1.0 - pixel / 255.0 for pixel in imagem.get_flattened_data()]


if __name__ == "__main__":
    print(json.dumps(carregar_imagem(sys.argv[1])))

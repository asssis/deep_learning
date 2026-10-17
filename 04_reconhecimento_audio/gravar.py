"""Grava um exemplo de voz ou um áudio para testar."""

import argparse
from pathlib import Path
import wave

import sounddevice as sd


def gravar(caminho, segundos=2.0):
    if not 0 < segundos <= 30:
        raise ValueError("A duração deve ser maior que zero e no máximo 30 segundos.")
    caminho = Path(caminho)
    if caminho.exists():
        raise FileExistsError(f"O arquivo já existe: {caminho}. Escolha outro nome.")
    input("Pressione Enter e fale uma palavra quando aparecer GRAVANDO...")
    print("GRAVANDO...", flush=True)
    dados = sd.rec(round(segundos * 16000), samplerate=16000, channels=1, dtype="int16")
    sd.wait()
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(caminho), "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(16000)
        arquivo.writeframes(dados.tobytes())
    print(f"Salvo: {caminho}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("caminho", help="Arquivo WAV de destino")
    parser.add_argument("--segundos", type=float, default=2.0)
    args = parser.parse_args()
    gravar(args.caminho, args.segundos)
